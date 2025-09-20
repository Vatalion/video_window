import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../../core/errors/exceptions.dart';
import '../../domain/models/biometric_models.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainItemAccessibility.first_unlock_this_device,
    ),
  );
  final Logger _logger = Logger();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricTypeKey = 'biometric_type';
  static const String _lastAuthKey = 'last_biometric_auth';
  static const String _failedAttemptsKey = 'biometric_failed_attempts';
  static const String _lockoutUntilKey = 'biometric_lockout_until';
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = const Duration(minutes: 5);

  /// Check if biometric authentication is available on the device
  Future<BiometricDeviceCapability> checkBiometricCapability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        return BiometricDeviceCapability(
          type: BiometricType.none,
          isAvailable: false,
          status: BiometricAuthStatus.notAvailable,
        );
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      BiometricType biometricType = BiometricType.none;
      for (final type in availableBiometrics) {
        if (type == BiometricType.face) {
          biometricType = BiometricType.faceId;
        } else if (type == BiometricType.fingerprint) {
          biometricType = BiometricType.touchId;
        }
      }

      if (biometricType == BiometricType.none) {
        return BiometricDeviceCapability(
          type: BiometricType.none,
          isAvailable: false,
          status: BiometricAuthStatus.notAvailable,
        );
      }

      return BiometricDeviceCapability(
        type: biometricType,
        isAvailable: true,
        status: BiometricAuthStatus.available,
      );
    } on PlatformException catch (e) {
      _logger.e('Error checking biometric capability: ${e.message}');
      return BiometricDeviceCapability(
        type: BiometricType.none,
        isAvailable: false,
        status: BiometricAuthStatus.error,
        errorMessage: e.message ?? 'Unknown error checking biometrics',
      );
    } catch (e) {
      _logger.e('Unexpected error checking biometric capability: $e');
      return BiometricDeviceCapability(
        type: BiometricType.none,
        isAvailable: false,
        status: BiometricAuthStatus.error,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  /// Authenticate user using biometrics
  Future<BiometricAuthResult> authenticate({
    String reason = 'Authenticate with biometrics',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      // Check if biometric is enabled
      final preferences = await getBiometricPreferences();
      if (!preferences.isEnabled || preferences.isLockedOut) {
        return BiometricAuthResult.failure(
          errorMessage: preferences.isLockedOut
              ? 'Biometric authentication is temporarily locked'
              : 'Biometric authentication is not enabled',
          biometricType: preferences.preferredBiometricType,
        );
      }

      // Perform biometric authentication
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await _recordSuccessfulAuth();
        final capability = await checkBiometricCapability();
        return BiometricAuthResult.success(biometricType: capability.type);
      } else {
        await _recordFailedAttempt();
        final currentPrefs = await getBiometricPreferences();
        return BiometricAuthResult.failure(
          errorMessage: 'Biometric authentication failed',
          biometricType: currentPrefs.preferredBiometricType,
        );
      }
    } on PlatformException catch (e) {
      await _recordFailedAttempt();
      _logger.e('Biometric authentication error: ${e.message}');

      String errorMessage = 'Biometric authentication failed';
      switch (e.code) {
        case 'NotAvailable':
          errorMessage =
              'Biometric authentication is not available on this device';
          break;
        case 'NotEnrolled':
          errorMessage = 'No biometrics enrolled on this device';
          break;
        case 'LockedOut':
          errorMessage =
              'Biometric authentication is locked out due to too many failed attempts';
          await _handleLockout();
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Biometric authentication is permanently locked out';
          break;
      }

      final currentPrefs = await getBiometricPreferences();
      return BiometricAuthResult.failure(
        errorMessage: errorMessage,
        biometricType: currentPrefs.preferredBiometricType,
      );
    } catch (e) {
      await _recordFailedAttempt();
      _logger.e('Unexpected biometric authentication error: $e');
      final currentPrefs = await getBiometricPreferences();
      return BiometricAuthResult.failure(
        errorMessage: 'Unexpected error during biometric authentication',
        biometricType: currentPrefs.preferredBiometricType,
      );
    }
  }

  /// Enable biometric authentication for the user
  Future<bool> enableBiometricAuth() async {
    try {
      final capability = await checkBiometricCapability();
      if (!capability.isAvailable ||
          capability.status != BiometricAuthStatus.available) {
        throw BiometricException(
          'Biometric authentication is not available: ${capability.errorMessage}',
        );
      }

      // Test authentication first
      final testResult = await authenticate(
        reason: 'Enable biometric authentication',
      );

      if (!testResult.success) {
        throw BiometricException(
          'Failed to authenticate during setup: ${testResult.errorMessage}',
        );
      }

      // Save preferences
      await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
      await _secureStorage.write(
        key: _biometricTypeKey,
        value: capability.type.name,
      );

      return true;
    } catch (e) {
      _logger.e('Error enabling biometric authentication: $e');
      rethrow;
    }
  }

  /// Disable biometric authentication for the user
  Future<bool> disableBiometricAuth() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _biometricTypeKey);
      await _secureStorage.delete(key: _lastAuthKey);
      await _secureStorage.delete(key: _failedAttemptsKey);
      await _secureStorage.delete(key: _lockoutUntilKey);

      return true;
    } catch (e) {
      _logger.e('Error disabling biometric authentication: $e');
      rethrow;
    }
  }

  /// Get current biometric preferences
  Future<BiometricPreferences> getBiometricPreferences() async {
    try {
      final isEnabled =
          await _secureStorage.read(key: _biometricEnabledKey) == 'true';
      final biometricTypeStr = await _secureStorage.read(
        key: _biometricTypeKey,
      );
      final lastAuthStr = await _secureStorage.read(key: _lastAuthKey);
      final failedAttemptsStr = await _secureStorage.read(
        key: _failedAttemptsKey,
      );
      final lockoutUntilStr = await _secureStorage.read(key: _lockoutUntilKey);

      BiometricType biometricType = BiometricType.none;
      if (biometricTypeStr != null) {
        biometricType = BiometricType.values.firstWhere(
          (type) => type.name == biometricTypeStr,
          orElse: () => BiometricType.none,
        );
      }

      DateTime? lastAuth;
      if (lastAuthStr != null) {
        lastAuth = DateTime.tryParse(lastAuthStr);
      }

      int failedAttempts = 0;
      if (failedAttemptsStr != null) {
        failedAttempts = int.tryParse(failedAttemptsStr) ?? 0;
      }

      DateTime? lockoutUntil;
      if (lockoutUntilStr != null) {
        lockoutUntil = DateTime.tryParse(lockoutUntilStr);
      }

      return BiometricPreferences(
        isEnabled: isEnabled,
        preferredBiometricType: biometricType,
        lastSuccessfulAuth: lastAuth,
        failedAttempts: failedAttempts,
        lockoutUntil: lockoutUntil,
      );
    } catch (e) {
      _logger.e('Error getting biometric preferences: $e');
      return const BiometricPreferences();
    }
  }

  /// Reset failed attempts counter
  Future<void> resetFailedAttempts() async {
    try {
      await _secureStorage.delete(key: _failedAttemptsKey);
      await _secureStorage.delete(key: _lockoutUntilKey);
    } catch (e) {
      _logger.e('Error resetting failed attempts: $e');
    }
  }

  Future<void> _recordSuccessfulAuth() async {
    try {
      await _secureStorage.write(
        key: _lastAuthKey,
        value: DateTime.now().toIso8601String(),
      );
      await _secureStorage.write(key: _failedAttemptsKey, value: '0');
      await _secureStorage.delete(key: _lockoutUntilKey);
    } catch (e) {
      _logger.e('Error recording successful auth: $e');
    }
  }

  Future<void> _recordFailedAttempt() async {
    try {
      final currentPrefs = await getBiometricPreferences();
      final newFailedAttempts = currentPrefs.failedAttempts + 1;

      await _secureStorage.write(
        key: _failedAttemptsKey,
        value: newFailedAttempts.toString(),
      );

      // Lockout if max attempts reached
      if (newFailedAttempts >= _maxFailedAttempts) {
        await _handleLockout();
      }
    } catch (e) {
      _logger.e('Error recording failed attempt: $e');
    }
  }

  Future<void> _handleLockout() async {
    try {
      final lockoutUntil = DateTime.now().add(_lockoutDuration);
      await _secureStorage.write(
        key: _lockoutUntilKey,
        value: lockoutUntil.toIso8601String(),
      );
    } catch (e) {
      _logger.e('Error handling lockout: $e');
    }
  }

  /// Check if biometric authentication should be available
  Future<bool> isBiometricAuthAvailable() async {
    try {
      final capability = await checkBiometricCapability();
      final preferences = await getBiometricPreferences();

      return capability.isAvailable &&
          capability.status == BiometricAuthStatus.available &&
          preferences.isEnabled &&
          !preferences.isLockedOut;
    } catch (e) {
      _logger.e('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get remaining lockout time
  Future<Duration?> getRemainingLockoutTime() async {
    try {
      final preferences = await getBiometricPreferences();
      if (!preferences.isLockedOut || preferences.lockoutUntil == null) {
        return null;
      }

      final remaining = preferences.lockoutUntil!.difference(DateTime.now());
      return remaining.isNegative ? null : remaining;
    } catch (e) {
      _logger.e('Error getting remaining lockout time: $e');
      return null;
    }
  }
}
