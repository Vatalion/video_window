import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt/jwt.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/session_model.dart';
import '../../../core/errors/exceptions.dart';

class SessionTokenManager {
  final FlutterSecureStorage _secureStorage;
  static const String _accessTokenKey = 'session_access_token';
  static const String _refreshTokenKey = 'session_refresh_token';
  static const String _tokenMetadataKey = 'session_token_metadata';
  static const Duration _accessTokenExpiration = Duration(minutes: 30);
  static const Duration _refreshTokenExpiration = Duration(days: 7);
  static const String _encryptionKey = 'session_encryption_key';

  SessionTokenManager(this._secureStorage);

  Future<SessionTokenResult> generateTokens({
    required String userId,
    required String deviceId,
    Map<String, dynamic>? claims,
  }) async {
    final now = DateTime.now();
    final accessToken = await _generateAccessToken(userId, deviceId, claims);
    final refreshToken = await _generateRefreshToken(userId, deviceId);

    final metadata = SessionTokenMetadata(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      deviceId: deviceId,
      issuedAt: now,
      expiresAt: now.add(_accessTokenExpiration),
      refreshExpiresAt: now.add(_refreshTokenExpiration),
    );

    await _storeTokens(metadata);
    await _logTokenActivity(userId, 'token_generated', deviceId);

    return SessionTokenResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: metadata.expiresAt,
      refreshExpiresAt: metadata.refreshExpiresAt,
    );
  }

  Future<String> refreshAccessToken(String refreshToken) async {
    try {
      final metadata = await _getTokenMetadata();
      if (metadata == null || metadata.refreshToken != refreshToken) {
        throw SessionException('Invalid refresh token');
      }

      if (DateTime.now().isAfter(metadata.refreshExpiresAt)) {
        throw SessionException('Refresh token expired');
      }

      final newAccessToken = await _generateAccessToken(
        metadata.userId,
        metadata.deviceId,
        metadata.additionalClaims,
      );

      final updatedMetadata = metadata.copyWith(
        accessToken: newAccessToken,
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(_accessTokenExpiration),
      );

      await _storeTokens(updatedMetadata);
      await _logTokenActivity(
        metadata.userId,
        'token_refreshed',
        metadata.deviceId,
      );

      return newAccessToken;
    } catch (e) {
      throw SessionException('Failed to refresh access token: ${e.toString()}');
    }
  }

  Future<bool> validateToken(String token) async {
    try {
      final decodedToken = Jwt.parseJwt(token);
      final exp = decodedToken['exp'] as int?;

      if (exp == null) return false;

      final expiration = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isBefore(expiration);
    } catch (e) {
      return false;
    }
  }

  Future<String?> getCurrentAccessToken() async {
    final metadata = await _getTokenMetadata();
    return metadata?.accessToken;
  }

  Future<String?> getCurrentRefreshToken() async {
    final metadata = await _getTokenMetadata();
    return metadata?.refreshToken;
  }

  Future<bool> isTokenExpired() async {
    final metadata = await _getTokenMetadata();
    if (metadata == null) return true;

    return DateTime.now().isAfter(metadata.expiresAt);
  }

  Future<bool> isRefreshTokenExpired() async {
    final metadata = await _getTokenMetadata();
    if (metadata == null) return true;

    return DateTime.now().isAfter(metadata.refreshExpiresAt);
  }

  Future<bool> needsRefresh() async {
    final metadata = await _getTokenMetadata();
    if (metadata == null) return true;

    final timeUntilExpiration = metadata.expiresAt.difference(DateTime.now());
    return timeUntilExpiration.inMinutes < 5;
  }

  Future<void> revokeTokens() async {
    final metadata = await _getTokenMetadata();
    if (metadata != null) {
      await _logTokenActivity(
        metadata.userId,
        'tokens_revoked',
        metadata.deviceId,
      );
    }

    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _tokenMetadataKey);
    await _secureStorage.delete(key: _encryptionKey);
  }

  Future<SessionTokenMetadata?> _getTokenMetadata() async {
    try {
      final metadataJson = await _secureStorage.read(key: _tokenMetadataKey);
      if (metadataJson == null) return null;

      final decrypted = await _decryptData(metadataJson);
      return SessionTokenMetadata.fromJson(json.decode(decrypted));
    } catch (e) {
      return null;
    }
  }

  Future<void> _storeTokens(SessionTokenMetadata metadata) async {
    final metadataJson = json.encode(metadata.toJson());
    final encrypted = await _encryptData(metadataJson);

    await _secureStorage.write(
      key: _accessTokenKey,
      value: metadata.accessToken,
    );
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: metadata.refreshToken,
    );
    await _secureStorage.write(key: _tokenMetadataKey, value: encrypted);
  }

  Future<String> _generateAccessToken(
    String userId,
    String deviceId,
    Map<String, dynamic>? claims,
  ) async {
    final now = DateTime.now();
    final expiration = now.add(_accessTokenExpiration);

    final payload = {
      'sub': userId,
      'deviceId': deviceId,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiration.millisecondsSinceEpoch ~/ 1000,
      'type': 'access',
      'jti': const Uuid().v4(),
      ...?claims,
    };

    return _signToken(payload);
  }

  Future<String> _generateRefreshToken(String userId, String deviceId) async {
    final now = DateTime.now();
    final expiration = now.add(_refreshTokenExpiration);

    final payload = {
      'sub': userId,
      'deviceId': deviceId,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiration.millisecondsSinceEpoch ~/ 1000,
      'type': 'refresh',
      'jti': const Uuid().v4(),
    };

    return _signToken(payload);
  }

  String _signToken(Map<String, dynamic> payload) {
    final header = {'alg': 'RS256', 'typ': 'JWT'};

    final encodedHeader = base64Url.encode(utf8.encode(json.encode(header)));
    final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));

    final signingInput = '$encodedHeader.$encodedPayload';
    final signature = _signRS256(signingInput);

    return '$signingInput.$signature';
  }

  String _signRS256(String data) {
    final key = _getPrivateKey();
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(utf8.encode(data));
    return base64Url.encode(digest.bytes);
  }

  List<int> _getPrivateKey() {
    final key = utf8.encode('video_window_session_private_key_2024');
    return sha256.convert(key).bytes;
  }

  Future<String> _encryptData(String data) async {
    final encryptionKey = await _getEncryptionKey();
    final key = Key.fromUtf8(encryptionKey);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));

    final encrypted = encrypter.encrypt(data, iv: iv);
    return '${iv.base64}.${encrypted.base64}';
  }

  Future<String> _decryptData(String encryptedData) async {
    try {
      final parts = encryptedData.split('.');
      if (parts.length != 2) throw Exception('Invalid encrypted data format');

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      final encryptionKey = await _getEncryptionKey();
      final key = Key.fromUtf8(encryptionKey);
      final encrypter = Encrypter(AES(key));

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Failed to decrypt data');
    }
  }

  Future<String> _getEncryptionKey() async {
    String? key = await _secureStorage.read(key: _encryptionKey);
    if (key == null) {
      key = _generateEncryptionKey();
      await _secureStorage.write(key: _encryptionKey, value: key);
    }
    return key;
  }

  String _generateEncryptionKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  Future<void> _logTokenActivity(
    String userId,
    String activity,
    String deviceId,
  ) async {
    final activityLog = {
      'userId': userId,
      'activity': activity,
      'deviceId': deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final logKey = 'token_activity_${const Uuid().v4()}';
    await _secureStorage.write(key: logKey, value: json.encode(activityLog));
  }
}

class SessionTokenResult {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime refreshExpiresAt;

  SessionTokenResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.refreshExpiresAt,
  });
}

class SessionTokenMetadata {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String deviceId;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DateTime refreshExpiresAt;
  final Map<String, dynamic> additionalClaims;

  SessionTokenMetadata({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.deviceId,
    required this.issuedAt,
    required this.expiresAt,
    required this.refreshExpiresAt,
    this.additionalClaims = const {},
  });

  factory SessionTokenMetadata.fromJson(Map<String, dynamic> json) {
    return SessionTokenMetadata(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      userId: json['userId'] as String,
      deviceId: json['deviceId'] as String,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      refreshExpiresAt: DateTime.parse(json['refreshExpiresAt'] as String),
      additionalClaims: Map<String, dynamic>.from(
        json['additionalClaims'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'userId': userId,
      'deviceId': deviceId,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'refreshExpiresAt': refreshExpiresAt.toIso8601String(),
      'additionalClaims': additionalClaims,
    };
  }

  SessionTokenMetadata copyWith({
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? deviceId,
    DateTime? issuedAt,
    DateTime? expiresAt,
    DateTime? refreshExpiresAt,
    Map<String, dynamic>? additionalClaims,
  }) {
    return SessionTokenMetadata(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
      additionalClaims: additionalClaims ?? this.additionalClaims,
    );
  }
}
