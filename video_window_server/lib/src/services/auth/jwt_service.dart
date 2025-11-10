import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:serverpod/serverpod.dart';
import 'package:redis/redis.dart';

/// JWT Token Service with RS256 asymmetric encryption
/// Implements SEC-003 requirement: RS256 signing, key rotation, token blacklisting
class JwtService {
  final Session session;
  pc.RSAPrivateKey? _privateKey;
  pc.RSAPublicKey? _publicKey;
  RedisConnection? _redisConn;
  Command? _redis;

  // Token configuration
  static const accessTokenDuration = Duration(minutes: 15);
  static const refreshTokenDuration = Duration(days: 30);
  static const issuer = 'video_window';
  static const audience = 'video_window_client';

  JwtService(this.session);

  /// Initialize RS256 key pair and Redis
  Future<void> initialize() async {
    await _initKeys();
    await _initRedis();
  }

  /// Initialize or load RSA keys
  Future<void> _initKeys() async {
    try {
      // Try to load existing keys from config/secure storage
      // For now, generate ephemeral keys (TODO: persist keys securely)
      final keyPair = _generateRSAKeyPair();
      _privateKey = keyPair.privateKey;
      _publicKey = keyPair.publicKey;

      session.log('JWT keys initialized', level: LogLevel.info);
    } catch (e) {
      session.log('Failed to initialize JWT keys: $e',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Generate RSA 2048-bit key pair
  pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>
      _generateRSAKeyPair() {
    final keyParams =
        pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);
    final secureRandom = _getSecureRandom();

    final rngParams = pc.ParametersWithRandom(keyParams, secureRandom);
    final keyGenerator = pc.RSAKeyGenerator();
    keyGenerator.init(rngParams);

    return keyGenerator.generateKeyPair();
  }

  /// Get cryptographically secure random generator
  pc.SecureRandom _getSecureRandom() {
    final random = pc.FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (var i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    random.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return random;
  }

  /// Initialize Redis connection for token blacklist
  Future<void> _initRedis() async {
    if (_redis != null) return;

    try {
      _redisConn = RedisConnection();
      _redis = await _redisConn!.connect('localhost', 8091);

      // Authenticate with Redis
      final password =
          session.passwords['redis'] ?? 'JLLDNS1puOSFsmtR7AePtBQt9huXBltb';
      if (password.isNotEmpty) {
        await _redis!.send_object(['AUTH', password]);
      }

      session.log('Redis connected for JWT service', level: LogLevel.debug);
    } catch (e) {
      session.log('Failed to connect to Redis: $e',
          level: LogLevel.error, exception: e);
      _redis = null;
    }
  }

  /// Generate access token (15-minute expiry)
  Future<String> generateAccessToken({
    required int userId,
    required String email,
    String? deviceId,
    String? sessionId,
  }) async {
    if (_privateKey == null) {
      throw Exception('JWT keys not initialized');
    }

    final jti = _generateJti();
    final now = DateTime.now();

    final jwt = JWT(
      {
        'sub': userId.toString(),
        'email': email,
        'type': 'access',
        'jti': jti,
        'device_id': deviceId,
        'session_id': sessionId,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
      },
      issuer: issuer,
      audience: Audience([audience]),
    );

    final privateKeyPem = _convertPrivateKeyToPem(_privateKey!);
    final token = jwt.sign(
      RSAPrivateKey(privateKeyPem),
      algorithm: JWTAlgorithm.RS256,
      expiresIn: accessTokenDuration,
    );

    session.log('Generated access token for user $userId',
        level: LogLevel.debug);
    return token;
  }

  /// Generate refresh token (30-day expiry)
  Future<String> generateRefreshToken({
    required int userId,
    required String email,
    String? deviceId,
    String? sessionId,
  }) async {
    if (_privateKey == null) {
      throw Exception('JWT keys not initialized');
    }

    final jti = _generateJti();
    final now = DateTime.now();

    final jwt = JWT(
      {
        'sub': userId.toString(),
        'email': email,
        'type': 'refresh',
        'jti': jti,
        'device_id': deviceId,
        'session_id': sessionId,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'rotation_count': 0,
      },
      issuer: issuer,
      audience: Audience([audience]),
    );

    final privateKeyPem = _convertPrivateKeyToPem(_privateKey!);
    final token = jwt.sign(
      RSAPrivateKey(privateKeyPem),
      algorithm: JWTAlgorithm.RS256,
      expiresIn: refreshTokenDuration,
    );

    // Store refresh token in Redis for tracking/rotation
    await _storeRefreshToken(jti, userId, deviceId, sessionId);

    session.log('Generated refresh token for user $userId',
        level: LogLevel.debug);
    return token;
  }

  /// Verify and decode access token
  Future<TokenClaims?> verifyAccessToken(String token) async {
    return _verifyToken(token, expectedType: 'access');
  }

  /// Verify and decode refresh token
  Future<TokenClaims?> verifyRefreshToken(String token) async {
    return _verifyToken(token, expectedType: 'refresh');
  }

  /// Generic token verification
  Future<TokenClaims?> _verifyToken(String token,
      {String? expectedType}) async {
    if (_publicKey == null) {
      session.log('JWT keys not initialized', level: LogLevel.error);
      return null;
    }

    try {
      // Check if blacklisted
      if (await _isBlacklisted(token)) {
        session.log('Token is blacklisted', level: LogLevel.warning);
        return null;
      }

      // Verify signature and decode
      final publicKeyPem = _convertPublicKeyToPem(_publicKey!);
      final jwt = JWT.verify(
        token,
        RSAPublicKey(publicKeyPem),
        issuer: issuer,
        audience: Audience([audience]),
      );

      final payload = jwt.payload as Map<String, dynamic>;

      // Validate token type
      if (expectedType != null && payload['type'] != expectedType) {
        session.log(
            'Invalid token type: expected $expectedType, got ${payload['type']}',
            level: LogLevel.warning);
        return null;
      }

      // Calculate expiry from exp claim
      final expClaim = payload['exp'] as int?;
      final expiresAt = expClaim != null
          ? DateTime.fromMillisecondsSinceEpoch(expClaim * 1000)
          : null;

      return TokenClaims(
        userId: int.parse(payload['sub'] as String),
        email: payload['email'] as String,
        jti: payload['jti'] as String,
        type: payload['type'] as String,
        deviceId: payload['device_id'] as String?,
        sessionId: payload['session_id'] as String?,
        issuedAt:
            DateTime.fromMillisecondsSinceEpoch((payload['iat'] as int) * 1000),
        expiresAt: expiresAt,
        rotationCount: payload['rotation_count'] as int?,
      );
    } on JWTExpiredException {
      session.log('Token expired', level: LogLevel.debug);
      return null;
    } on JWTException catch (e) {
      session.log('JWT verification failed: $e', level: LogLevel.warning);
      return null;
    } catch (e) {
      session.log('Token verification error: $e',
          level: LogLevel.error, exception: e);
      return null;
    }
  }

  /// Rotate refresh token (implements reuse detection)
  Future<RefreshTokenRotationResult?> rotateRefreshToken(
      String oldToken) async {
    // Verify old token
    final claims = await verifyRefreshToken(oldToken);
    if (claims == null) {
      session.log('Cannot rotate invalid refresh token',
          level: LogLevel.warning);
      return null;
    }

    // Check for token reuse (already rotated)
    if (await _wasTokenRotated(claims.jti)) {
      session.log(
          'SECURITY ALERT: Refresh token reuse detected for user ${claims.userId}',
          level: LogLevel.warning);

      // Revoke all tokens for this session/user
      await revokeAllTokensForSession(
          claims.sessionId ?? claims.userId.toString());

      return RefreshTokenRotationResult.reuseDetected(
        userId: claims.userId,
        sessionId: claims.sessionId,
      );
    }

    // Mark old token as rotated
    await _markTokenRotated(claims.jti);

    // Blacklist old token
    await blacklistToken(
        oldToken, claims.expiresAt ?? DateTime.now().add(refreshTokenDuration));

    // Generate new access + refresh tokens
    final newAccessToken = await generateAccessToken(
      userId: claims.userId,
      email: claims.email,
      deviceId: claims.deviceId,
      sessionId: claims.sessionId,
    );

    final newRefreshToken = await generateRefreshToken(
      userId: claims.userId,
      email: claims.email,
      deviceId: claims.deviceId,
      sessionId: claims.sessionId,
    );

    session.log('Rotated refresh token for user ${claims.userId}',
        level: LogLevel.info);

    return RefreshTokenRotationResult.success(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      userId: claims.userId,
    );
  }

  /// Blacklist a token (for logout or revocation)
  Future<void> blacklistToken(String token, DateTime expiresAt) async {
    try {
      await _initRedis();
      if (_redis == null) {
        session.log('Cannot blacklist - Redis not available',
            level: LogLevel.warning);
        return;
      }

      final jti = _extractJti(token);
      if (jti == null) {
        session.log('Cannot blacklist - JTI extraction failed',
            level: LogLevel.warning);
        return;
      }

      final key = 'jwt:blacklist:$jti';
      final ttl = expiresAt.difference(DateTime.now()).inSeconds;

      if (ttl > 0) {
        final response =
            await _redis!.send_object(['SETEX', key, ttl.toString(), '1']);
        session.log(
            'Blacklisted token: $jti (key=$key, ttl=$ttl, response=$response)',
            level: LogLevel.info);
      } else {
        session.log('Cannot blacklist - TTL is negative: $ttl',
            level: LogLevel.warning);
      }
    } catch (e) {
      session.log('Failed to blacklist token: $e',
          level: LogLevel.error, exception: e);
    }
  }

  /// Check if token is blacklisted
  Future<bool> _isBlacklisted(String token) async {
    try {
      await _initRedis();
      if (_redis == null) {
        session.log('Cannot check blacklist - Redis not available',
            level: LogLevel.debug);
        return false;
      }

      final jti = _extractJti(token);
      if (jti == null) {
        session.log('Cannot check blacklist - JTI extraction failed',
            level: LogLevel.debug);
        return false;
      }

      final key = 'jwt:blacklist:$jti';
      final result = await _redis!.send_object(['GET', key]);
      final isBlacklisted = result != null;

      session.log('Blacklist check for $jti: $isBlacklisted (result=$result)',
          level: LogLevel.info);
      return isBlacklisted;
    } catch (e) {
      session.log('Failed to check blacklist: $e',
          level: LogLevel.error, exception: e);
      return false;
    }
  }

  /// Store refresh token metadata for rotation tracking
  Future<void> _storeRefreshToken(
      String jti, int userId, String? deviceId, String? sessionId) async {
    try {
      await _initRedis();
      if (_redis == null) return;

      final key = 'jwt:refresh:$jti';
      final data = json.encode({
        'user_id': userId,
        'device_id': deviceId,
        'session_id': sessionId,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _redis!.send_object(
          ['SETEX', key, refreshTokenDuration.inSeconds.toString(), data]);
    } catch (e) {
      session.log('Failed to store refresh token: $e',
          level: LogLevel.error, exception: e);
    }
  }

  /// Check if token was already rotated
  Future<bool> _wasTokenRotated(String jti) async {
    try {
      await _initRedis();
      if (_redis == null) return false;

      final key = 'jwt:rotated:$jti';
      final result = await _redis!.send_object(['GET', key]);
      return result != null;
    } catch (e) {
      session.log('Failed to check rotation status: $e',
          level: LogLevel.error, exception: e);
      return false;
    }
  }

  /// Mark token as rotated (for reuse detection)
  Future<void> _markTokenRotated(String jti) async {
    try {
      await _initRedis();
      if (_redis == null) return;

      final key = 'jwt:rotated:$jti';
      await _redis!.send_object(
          ['SETEX', key, refreshTokenDuration.inSeconds.toString(), '1']);
    } catch (e) {
      session.log('Failed to mark token as rotated: $e',
          level: LogLevel.error, exception: e);
    }
  }

  /// Revoke all tokens for a session (on security breach)
  Future<void> revokeAllTokensForSession(String sessionId) async {
    try {
      await _initRedis();
      if (_redis == null) return;

      // Find all refresh tokens for this session
      final pattern = 'jwt:refresh:*';
      final keys =
          await _redis!.send_object(['KEYS', pattern]) as List<dynamic>?;

      if (keys == null || keys.isEmpty) return;

      for (final key in keys) {
        final data = await _redis!.send_object(['GET', key]);
        if (data != null) {
          final metadata = json.decode(data.toString()) as Map<String, dynamic>;
          if (metadata['session_id'] == sessionId) {
            // Blacklist this refresh token
            final jti = (key.toString()).split(':').last;
            await _redis!.send_object(['DEL', key]);
            await _redis!.send_object([
              'SETEX',
              'jwt:blacklist:$jti',
              refreshTokenDuration.inSeconds.toString(),
              '1'
            ]);
          }
        }
      }

      session.log('Revoked all tokens for session: $sessionId',
          level: LogLevel.warning);
    } catch (e) {
      session.log('Failed to revoke session tokens: $e',
          level: LogLevel.error, exception: e);
    }
  }

  /// Extract JTI from token without full verification
  String? _extractJti(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;

      return payload['jti'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Generate unique JWT ID
  String _generateJti() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return sha256.convert(values).toString();
  }

  /// Convert pointycastle RSA private key to PEM format
  String _convertPrivateKeyToPem(pc.RSAPrivateKey privateKey) {
    // Encode in PKCS#1 format
    final topLevel = ASN1Sequence();

    topLevel.add(ASN1Integer(BigInt.zero)); // version
    topLevel.add(ASN1Integer(privateKey.n!)); // modulus
    topLevel.add(ASN1Integer(privateKey.exponent!)); // publicExponent
    topLevel.add(ASN1Integer(privateKey.d!)); // privateExponent
    topLevel.add(ASN1Integer(privateKey.p!)); // prime1
    topLevel.add(ASN1Integer(privateKey.q!)); // prime2
    topLevel.add(
        ASN1Integer(privateKey.d! % (privateKey.p! - BigInt.one))); // exponent1
    topLevel.add(
        ASN1Integer(privateKey.d! % (privateKey.q! - BigInt.one))); // exponent2
    topLevel.add(
        ASN1Integer(privateKey.q!.modInverse(privateKey.p!))); // coefficient

    final dataBase64 = base64.encode(topLevel.encodedBytes);

    return '''-----BEGIN RSA PRIVATE KEY-----
${_chunk(dataBase64, 64)}
-----END RSA PRIVATE KEY-----''';
  }

  /// Convert pointycastle RSA public key to PEM format
  String _convertPublicKeyToPem(pc.RSAPublicKey publicKey) {
    // Encode in PKCS#1 format
    final topLevel = ASN1Sequence();
    topLevel.add(ASN1Integer(publicKey.modulus!));
    topLevel.add(ASN1Integer(publicKey.exponent!));

    final dataBase64 = base64.encode(topLevel.encodedBytes);

    return '''-----BEGIN RSA PUBLIC KEY-----
${_chunk(dataBase64, 64)}
-----END RSA PUBLIC KEY-----''';
  }

  /// Chunk string into lines of specified length
  String _chunk(String str, int chunkSize) {
    final chunks = <String>[];
    for (var i = 0; i < str.length; i += chunkSize) {
      final end = (i + chunkSize < str.length) ? i + chunkSize : str.length;
      chunks.add(str.substring(i, end));
    }
    return chunks.join('\n');
  }

  /// Close Redis connection
  Future<void> close() async {
    await _redisConn?.close();
    _redis = null;
    _redisConn = null;
  }
}

/// Token claims data structure
class TokenClaims {
  final int userId;
  final String email;
  final String jti;
  final String type;
  final String? deviceId;
  final String? sessionId;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final int? rotationCount;

  TokenClaims({
    required this.userId,
    required this.email,
    required this.jti,
    required this.type,
    this.deviceId,
    this.sessionId,
    required this.issuedAt,
    this.expiresAt,
    this.rotationCount,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Refresh token rotation result
class RefreshTokenRotationResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final int userId;
  final String? sessionId;
  final bool reuseDetected;

  RefreshTokenRotationResult._({
    required this.success,
    this.accessToken,
    this.refreshToken,
    required this.userId,
    this.sessionId,
    this.reuseDetected = false,
  });

  factory RefreshTokenRotationResult.success({
    required String accessToken,
    required String refreshToken,
    required int userId,
  }) {
    return RefreshTokenRotationResult._(
      success: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
  }

  factory RefreshTokenRotationResult.reuseDetected({
    required int userId,
    String? sessionId,
  }) {
    return RefreshTokenRotationResult._(
      success: false,
      userId: userId,
      sessionId: sessionId,
      reuseDetected: true,
    );
  }
}
