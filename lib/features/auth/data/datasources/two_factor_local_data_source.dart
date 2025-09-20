import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../domain/models/two_factor_config_model.dart';
import '../../domain/models/two_factor_verification_model.dart';
import '../../domain/models/two_factor_audit_model.dart';
import '../../../../core/error/exceptions.dart';

abstract class TwoFactorLocalDataSource {
  Future<void> cacheTwoFactorConfig(TwoFactorConfig config);
  Future<TwoFactorConfig?> getCachedTwoFactorConfig(String userId);
  Future<void> clearCachedTwoFactorConfig(String userId);

  Future<void> cacheVerificationSession(TwoFactorVerification verification);
  Future<TwoFactorVerification?> getCachedVerificationSession(String sessionId);
  Future<void> clearVerificationSession(String sessionId);

  Future<void> storeBackupCodes(String userId, List<String> backupCodes);
  Future<List<String>> getBackupCodes(String userId);
  Future<void> removeBackupCode(String userId, String code);

  Future<void> storeRateLimitData(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getRateLimitData(String key);
  Future<void> clearRateLimitData(String key);
}

class TwoFactorLocalDataSourceImpl implements TwoFactorLocalDataSource {
  final FlutterSecureStorage secureStorage;
  final Encrypter encrypter;

  TwoFactorLocalDataSourceImpl({
    required this.secureStorage,
    required this.encrypter,
  });

  String _encrypt(String plainText) {
    final iv = IV.fromLength(16);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return json.encode({'data': encrypted.base64, 'iv': iv.base64});
  }

  String _decrypt(String encryptedData) {
    try {
      final map = json.decode(encryptedData) as Map<String, dynamic>;
      final encrypted = Encrypted.fromBase64(map['data'] as String);
      final iv = IV.fromBase64(map['iv'] as String);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw CacheException('Failed to decrypt data');
    }
  }

  @override
  Future<void> cacheTwoFactorConfig(TwoFactorConfig config) async {
    try {
      final key = 'two_factor_config_${config.userId}';
      final configJson = json.encode(config.toJson());
      final encryptedConfig = _encrypt(configJson);
      await secureStorage.write(key: key, value: encryptedConfig);
    } catch (e) {
      throw CacheException('Failed to cache 2FA config: ${e.toString()}');
    }
  }

  @override
  Future<TwoFactorConfig?> getCachedTwoFactorConfig(String userId) async {
    try {
      final key = 'two_factor_config_$userId';
      final encryptedConfig = await secureStorage.read(key: key);

      if (encryptedConfig == null) return null;

      final configJson = _decrypt(encryptedConfig);
      final configMap = json.decode(configJson) as Map<String, dynamic>;
      return TwoFactorConfig.fromJson(configMap);
    } catch (e) {
      throw CacheException('Failed to get cached 2FA config: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCachedTwoFactorConfig(String userId) async {
    try {
      final key = 'two_factor_config_$userId';
      await secureStorage.delete(key: key);
    } catch (e) {
      throw CacheException(
        'Failed to clear cached 2FA config: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheVerificationSession(
    TwoFactorVerification verification,
  ) async {
    try {
      final key = 'verification_session_${verification.sessionId}';
      final verificationJson = json.encode(verification.toJson());
      final encryptedVerification = _encrypt(verificationJson);
      await secureStorage.write(key: key, value: encryptedVerification);
    } catch (e) {
      throw CacheException(
        'Failed to cache verification session: ${e.toString()}',
      );
    }
  }

  @override
  Future<TwoFactorVerification?> getCachedVerificationSession(
    String sessionId,
  ) async {
    try {
      final key = 'verification_session_$sessionId';
      final encryptedVerification = await secureStorage.read(key: key);

      if (encryptedVerification == null) return null;

      final verificationJson = _decrypt(encryptedVerification);
      final verificationMap =
          json.decode(verificationJson) as Map<String, dynamic>;
      return TwoFactorVerification.fromJson(verificationMap);
    } catch (e) {
      throw CacheException(
        'Failed to get cached verification session: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> clearVerificationSession(String sessionId) async {
    try {
      final key = 'verification_session_$sessionId';
      await secureStorage.delete(key: key);
    } catch (e) {
      throw CacheException(
        'Failed to clear verification session: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> storeBackupCodes(String userId, List<String> backupCodes) async {
    try {
      final key = 'backup_codes_$userId';
      final codesJson = json.encode(backupCodes);
      final encryptedCodes = _encrypt(codesJson);
      await secureStorage.write(key: key, value: encryptedCodes);
    } catch (e) {
      throw CacheException('Failed to store backup codes: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getBackupCodes(String userId) async {
    try {
      final key = 'backup_codes_$userId';
      final encryptedCodes = await secureStorage.read(key: key);

      if (encryptedCodes == null) return [];

      final codesJson = _decrypt(encryptedCodes);
      final codesList = json.decode(codesJson) as List;
      return List<String>.from(codesList);
    } catch (e) {
      throw CacheException('Failed to get backup codes: ${e.toString()}');
    }
  }

  @override
  Future<void> removeBackupCode(String userId, String code) async {
    try {
      final currentCodes = await getBackupCodes(userId);
      final updatedCodes = currentCodes.where((c) => c != code).toList();
      await storeBackupCodes(userId, updatedCodes);
    } catch (e) {
      throw CacheException('Failed to remove backup code: ${e.toString()}');
    }
  }

  @override
  Future<void> storeRateLimitData(String key, Map<String, dynamic> data) async {
    try {
      final fullKey = 'rate_limit_$key';
      final dataJson = json.encode(data);
      await secureStorage.write(key: fullKey, value: dataJson);
    } catch (e) {
      throw CacheException('Failed to store rate limit data: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getRateLimitData(String key) async {
    try {
      final fullKey = 'rate_limit_$key';
      final dataJson = await secureStorage.read(key: fullKey);

      if (dataJson == null) return null;

      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      throw CacheException('Failed to get rate limit data: ${e.toString()}');
    }
  }

  @override
  Future<void> clearRateLimitData(String key) async {
    try {
      final fullKey = 'rate_limit_$key';
      await secureStorage.delete(key: fullKey);
    } catch (e) {
      throw CacheException('Failed to clear rate limit data: ${e.toString()}');
    }
  }
}
