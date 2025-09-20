import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/session_token_model.dart';
import '../../../core/errors/exceptions.dart';

class JwtTokenService {
  final FlutterSecureStorage _secureStorage;
  final String _encryptionKey;
  final Encrypter _encrypter;

  JwtTokenService(this._secureStorage, this._encryptionKey)
      : _encrypter = Encrypter(AES(Key.fromUtf8(_encryptionKey.padRight(32, '0').substring(0, 32))));

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _tokenExpiryKey = 'auth_token_expiry';
  static const String _refreshTokenExpiryKey = 'auth_refresh_expiry';
  static const String _deviceIdKey = 'auth_device_id';
  static const String _sessionDataKey = 'auth_session_data';

  Future<String> generateAccessToken({
    required String userId,
    required String deviceId,
    Duration expiresIn = const Duration(minutes: 30),
    Map<String, dynamic> payload = const {},
  }) async {
    final now = DateTime.now();
    final expiryTime = now.add(expiresIn);

    final header = {
      'alg': 'RS256',
      'typ': 'JWT',
    };

    final finalPayload = {
      'sub': userId,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiryTime.millisecondsSinceEpoch ~/ 1000,
      'jti': const Uuid().v4(),
      'device_id': deviceId,
      'type': 'access',
      ...payload,
    };

    final unsignedToken = '${base64Url.encode(utf8.encode(json.encode(header)))}.${base64Url.encode(utf8.encode(json.encode(finalPayload)))}';
    final signature = await _signToken(unsignedToken);

    return '$unsignedToken.$signature';
  }

  Future<String> generateRefreshToken({
    required String userId,
    required String deviceId,
    Duration expiresIn = const Duration(days: 7),
    Map<String, dynamic> payload = const {},
  }) async {
    final now = DateTime.now();
    final expiryTime = now.add(expiresIn);

    final header = {
      'alg': 'RS256',
      'typ': 'JWT',
    };

    final finalPayload = {
      'sub': userId,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiryTime.millisecondsSinceEpoch ~/ 1000,
      'jti': const Uuid().v4(),
      'device_id': deviceId,
      'type': 'refresh',
      'rotation_count': 0,
      ...payload,
    };

    final unsignedToken = '${base64Url.encode(utf8.encode(json.encode(header)))}.${base64Url.encode(utf8.encode(json.encode(finalPayload)))}';
    final signature = await _signToken(unsignedToken);

    return '$unsignedToken.$signature';
  }

  Future<String> _signToken(String unsignedToken) async {
    final keyBytes = utf8.encode(_encryptionKey);
    final tokenBytes = utf8.encode(unsignedToken);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(tokenBytes);
    return base64Url.encode(digest.bytes);
  }

  Future<bool> validateToken(String token) async {
    try {
      if (!Jwt.isExpired(token)) {
        final payload = Jwt.parseJwt(token);
        final deviceId = payload['device_id'] as String?;
        final storedDeviceId = await _secureStorage.read(key: _deviceIdKey);

        return deviceId != null && deviceId == storedDeviceId;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> decodeToken(String token) async {
    try {
      return Jwt.parseJwt(token);
    } catch (e) {
      throw TokenException('Failed to decode token: ${e.toString()}');
    }
  }

  Future<bool> isTokenExpired(String token) async {
    try {
      return Jwt.isExpired(token);
    } catch (e) {
      return true;
    }
  }

  Future<Duration> getTokenTimeRemaining(String token) async {
    try {
      final payload = Jwt.parseJwt(token);
      final exp = payload['exp'] as int;
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      if (expiryTime.isBefore(now)) {
        return Duration.zero;
      }

      return expiryTime.difference(now);
    } catch (e) {
      return Duration.zero;
    }
  }

  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    required String deviceId,
    required DateTime accessTokenExpiry,
    required DateTime refreshTokenExpiry,
  }) async {
    try {
      await _secureStorage.write(key: _accessTokenKey, value: _encryptValue(accessToken));
      await _secureStorage.write(key: _refreshTokenKey, value: _encryptValue(refreshToken));
      await _secureStorage.write(key: _tokenExpiryKey, value: accessTokenExpiry.toIso8601String());
      await _secureStorage.write(key: _refreshTokenExpiryKey, value: refreshTokenExpiry.toIso8601String());
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    } catch (e) {
      throw StorageException('Failed to store tokens: ${e.toString()}');
    }
  }

  Future<SessionTokenModel?> getStoredTokens() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      final accessTokenExpiry = await _secureStorage.read(key: _tokenExpiryKey);
      final refreshTokenExpiry = await _secureStorage.read(key: _refreshTokenExpiryKey);
      final deviceId = await _secureStorage.read(key: _deviceIdKey);

      if (accessToken == null || refreshToken == null || deviceId == null) {
        return null;
      }

      final accessTokenPayload = Jwt.parseJwt(_decryptValue(accessToken));
      final refreshTokenPayload = Jwt.parseJwt(_decryptValue(refreshToken));

      return SessionTokenModel(
        id: accessTokenPayload['jti'] as String,
        userId: accessTokenPayload['sub'] as String,
        deviceId: deviceId,
        accessToken: _decryptValue(accessToken),
        refreshToken: _decryptValue(refreshToken),
        accessTokenExpiresAt: DateTime.parse(accessTokenExpiry!),
        refreshTokenExpiresAt: DateTime.parse(refreshTokenExpiry!),
        issuedAt: DateTime.fromMillisecondsSinceEpoch(accessTokenPayload['iat'] as int * 1000),
        tokenVersion: accessTokenPayload['version'] as int? ?? 1,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _tokenExpiryKey);
      await _secureStorage.delete(key: _refreshTokenExpiryKey);
      await _secureStorage.delete(key: _deviceIdKey);
      await _secureStorage.delete(key: _sessionDataKey);
    } catch (e) {
      throw StorageException('Failed to clear tokens: ${e.toString()}');
    }
  }

  Future<bool> hasValidTokens() async {
    final tokens = await getStoredTokens();
    return tokens != null && tokens.isValid;
  }

  Future<bool> needsTokenRefresh() async {
    final tokens = await getStoredTokens();
    return tokens != null && tokens.needsRefresh;
  }

  String _encryptValue(String value) {
    final iv = IV.fromLength(16);
    final encrypted = _encrypter.encrypt(value, iv: iv);
    return base64Url.encode(iv.bytes + encrypted.bytes);
  }

  String _decryptValue(String encryptedValue) {
    final decoded = base64Url.decode(encryptedValue);
    final iv = IV(decoded.sublist(0, 16));
    final encrypted = decoded.sublist(16);
    return _encrypter.decrypt64(base64Url.encode(encrypted), iv: iv);
  }

  Future<void> rotateRefreshToken(String newRefreshToken, DateTime newExpiry) async {
    await _secureStorage.write(key: _refreshTokenKey, value: _encryptValue(newRefreshToken));
    await _secureStorage.write(key: _refreshTokenExpiryKey, value: newExpiry.toIso8601String());
  }

  Future<String?> getAccessToken() async {
    final encrypted = await _secureStorage.read(key: _accessTokenKey);
    return encrypted != null ? _decryptValue(encrypted) : null;
  }

  Future<String?> getRefreshToken() async {
    final encrypted = await _secureStorage.read(key: _refreshTokenKey);
    return encrypted != null ? _decryptValue(encrypted) : null;
  }

  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: _deviceIdKey);
  }

  Future<void> updateAccessToken(String newAccessToken, DateTime newExpiry) async {
    await _secureStorage.write(key: _accessTokenKey, value: _encryptValue(newAccessToken));
    await _secureStorage.write(key: _tokenExpiryKey, value: newExpiry.toIso8601String());
  }
}