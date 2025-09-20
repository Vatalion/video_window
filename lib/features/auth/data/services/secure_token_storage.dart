import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';

class SecureTokenStorage {
  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  static const String _keyPrefix = 'social_auth_';
  static const String _csrfKeyPrefix = 'csrf_state_';
  static const String _codeVerifierPrefix = 'code_verifier_';

  SecureTokenStorage({FlutterSecureStorage? secureStorage, Logger? logger})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility:
                  KeychainItemAccessibility.when_unlocked_this_device_only,
            ),
          ),
      _logger = logger ?? Logger();

  Future<void> storeSocialAccessToken({
    required String userId,
    required SocialProvider provider,
    required String accessToken,
    DateTime? expiryDate,
  }) async {
    try {
      final key = '${_keyPrefix}${userId}_${provider.name}_access_token';
      await _secureStorage.write(
        key: key,
        value: accessToken,
        iOptions: IOSOptions(
          accessibility:
              KeychainItemAccessibility.when_unlocked_this_device_only,
        ),
      );

      if (expiryDate != null) {
        final expiryKey = '${_keyPrefix}${userId}_${provider.name}_expiry';
        await _secureStorage.write(
          key: expiryKey,
          value: expiryDate.toIso8601String(),
          iOptions: IOSOptions(
            accessibility:
                KeychainItemAccessibility.when_unlocked_this_device_only,
          ),
        );
      }

      _logger.i('Stored secure access token for ${provider.name} provider');
    } catch (e) {
      _logger.e('Failed to store secure access token: $e');
      throw SecureStorageException(
        'Failed to store access token: ${e.toString()}',
      );
    }
  }

  Future<String?> getSocialAccessToken({
    required String userId,
    required SocialProvider provider,
  }) async {
    try {
      final key = '${_keyPrefix}${userId}_${provider.name}_access_token';
      final token = await _secureStorage.read(
        key: key,
        iOptions: IOSOptions(
          accessibility:
              KeychainItemAccessibility.when_unlocked_this_device_only,
        ),
      );

      if (token != null) {
        // Check if token is expired
        final expiryKey = '${_keyPrefix}${userId}_${provider.name}_expiry';
        final expiryString = await _secureStorage.read(
          key: expiryKey,
          iOptions: IOSOptions(
            accessibility:
                KeychainItemAccessibility.when_unlocked_this_device_only,
          ),
        );

        if (expiryString != null) {
          final expiryDate = DateTime.parse(expiryString);
          if (DateTime.now().isAfter(expiryDate)) {
            await deleteSocialAccessToken(userId: userId, provider: provider);
            return null;
          }
        }
      }

      return token;
    } catch (e) {
      _logger.e('Failed to retrieve secure access token: $e');
      return null;
    }
  }

  Future<void> deleteSocialAccessToken({
    required String userId,
    required SocialProvider provider,
  }) async {
    try {
      final tokenKey = '${_keyPrefix}${userId}_${provider.name}_access_token';
      final expiryKey = '${_keyPrefix}${userId}_${provider.name}_expiry';

      await _secureStorage.delete(key: tokenKey);
      await _secureStorage.delete(key: expiryKey);

      _logger.i('Deleted secure access token for ${provider.name} provider');
    } catch (e) {
      _logger.e('Failed to delete secure access token: $e');
      throw SecureStorageException(
        'Failed to delete access token: ${e.toString()}',
      );
    }
  }

  Future<void> storeCSRFState({
    required String state,
    required SocialProvider provider,
  }) async {
    try {
      final key = '${_csrfKeyPrefix}${provider.name}_$state';
      await _secureStorage.write(
        key: key,
        value: DateTime.now().toIso8601String(),
        iOptions: IOSOptions(
          accessibility:
              KeychainItemAccessibility.when_unlocked_this_device_only,
        ),
      );

      _logger.i('Stored CSRF state for ${provider.name} provider');
    } catch (e) {
      _logger.e('Failed to store CSRF state: $e');
      throw SecureStorageException(
        'Failed to store CSRF state: ${e.toString()}',
      );
    }
  }

  Future<bool> validateCSRFState({
    required String state,
    required SocialProvider provider,
    Duration maxAge = const Duration(minutes: 10),
  }) async {
    try {
      final key = '${_csrfKeyPrefix}${provider.name}_$state';
      final storedTimeString = await _secureStorage.read(
        key: key,
        iOptions: IOSOptions(
          accessibility:
              KeychainItemAccessibility.when_unlocked_this_device_only,
        ),
      );

      if (storedTimeString == null) {
        return false;
      }

      final storedTime = DateTime.parse(storedTimeString);
      final isValid = DateTime.now().difference(storedTime) <= maxAge;

      if (isValid) {
        await _secureStorage.delete(key: key);
      }

      return isValid;
    } catch (e) {
      _logger.e('Failed to validate CSRF state: $e');
      return false;
    }
  }

  Future<void> storePKCECodeVerifier({
    required String state,
    required String codeVerifier,
  }) async {
    try {
      final key = '${_codeVerifierPrefix}$state';
      await _secureStorage.write(
        key: key,
        value: codeVerifier,
        iOptions: IOSOptions(
          accessibility:
              KeychainItemAccessibility.when_unlocked_this_device_only,
        ),
      );

      _logger.i('Stored PKCE code verifier');
    } catch (e) {
      _logger.e('Failed to store PKCE code verifier: $e');
      throw SecureStorageException(
        'Failed to store PKCE code verifier: ${e.toString()}',
      );
    }
  }

  Future<String?> getPKCECodeVerifier({required String state}) async {
    try {
      final key = '${_codeVerifierPrefix}$state';
      final codeVerifier = await _secureStorage.read(
        key: key,
        iOptions: IOSOptions(
          accessibility:
              KeychainItemAccessibility.when_unlocked_this_device_only,
        ),
      );

      if (codeVerifier != null) {
        await _secureStorage.delete(key: key);
      }

      return codeVerifier;
    } catch (e) {
      _logger.e('Failed to retrieve PKCE code verifier: $e');
      return null;
    }
  }

  Future<void> clearAllSocialAuthData() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final socialAuthKeys = allKeys.keys.where(
        (key) =>
            key.startsWith(_keyPrefix) ||
            key.startsWith(_csrfKeyPrefix) ||
            key.startsWith(_codeVerifierPrefix),
      );

      for (final key in socialAuthKeys) {
        await _secureStorage.delete(key: key);
      }

      _logger.i('Cleared all social authentication data');
    } catch (e) {
      _logger.e('Failed to clear social authentication data: $e');
      throw SecureStorageException(
        'Failed to clear auth data: ${e.toString()}',
      );
    }
  }
}

class SecureStorageException implements Exception {
  final String message;

  SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}
