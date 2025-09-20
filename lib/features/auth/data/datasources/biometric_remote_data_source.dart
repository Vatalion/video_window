import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:video_window/features/auth/domain/models/auth_enums.dart';

abstract class BiometricRemoteDataSource {
  /// Register a device for biometric authentication
  Future<BiometricDeviceRegistrationResult> registerBiometricDevice({
    required String userId,
    required BiometricType biometricType,
    required String deviceInfo,
    String? deviceName,
  });

  /// Authenticate using biometric credentials
  Future<BiometricAuthResponse> authenticateWithBiometrics({
    required String userId,
    required BiometricType biometricType,
    required String deviceSignature,
    required String biometricChallengeResponse,
  });

  /// Disable biometric authentication for a device
  Future<bool> disableBiometricAuth({
    required String userId,
    required String deviceId,
  });

  /// Get biometric authentication status for a user
  Future<BiometricAuthStatusResponse> getBiometricAuthStatus({
    required String userId,
  });

  /// Get registered biometric devices for a user
  Future<List<BiometricDeviceRecord>> getRegisteredBiometricDevices({
    required String userId,
  });

  /// Remove a specific biometric device
  Future<bool> removeBiometricDevice({
    required String userId,
    required String deviceId,
  });

  /// Log biometric authentication attempt
  Future<void> logBiometricAuthAttempt({
    required String userId,
    required BiometricType biometricType,
    required bool success,
    String? errorMessage,
    String? deviceId,
  });

  /// Update biometric device information
  Future<bool> updateBiometricDevice({
    required String userId,
    required String deviceId,
    String? deviceName,
    bool? isActive,
  });

  /// Validate biometric challenge
  Future<bool> validateBiometricChallenge({
    required String userId,
    required String challenge,
    required String response,
  });

  /// Refresh biometric authentication session
  Future<BiometricSessionResponse> refreshBiometricSession({
    required String userId,
    required String deviceId,
    required String refreshToken,
  });
}

/// Biometric device registration result
class BiometricDeviceRegistrationResult {
  final bool success;
  final String deviceId;
  final DateTime registeredAt;
  final String? errorMessage;
  final BiometricDeviceRegistrationMetadata metadata;

  BiometricDeviceRegistrationResult({
    required this.success,
    required this.deviceId,
    required this.registeredAt,
    this.errorMessage,
    required this.metadata,
  });
}

/// Biometric device registration metadata
class BiometricDeviceRegistrationMetadata {
  final String deviceSignature;
  final String challengeId;
  final DateTime expiresAt;
  final int maxAttempts;
  final int remainingAttempts;

  BiometricDeviceRegistrationMetadata({
    required this.deviceSignature,
    required this.challengeId,
    required this.expiresAt,
    required this.maxAttempts,
    required this.remainingAttempts,
  });
}

/// Biometric authentication response
class BiometricAuthResponse {
  final bool success;
  final String? authToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? errorMessage;
  final BiometricAuthMetadata metadata;

  BiometricAuthResponse({
    required this.success,
    this.authToken,
    this.refreshToken,
    this.expiresAt,
    this.errorMessage,
    required this.metadata,
  });
}

/// Biometric authentication metadata
class BiometricAuthMetadata {
  final String sessionId;
  final String deviceId;
  final BiometricType biometricType;
  final DateTime authenticatedAt;
  final int remainingAttempts;

  BiometricAuthMetadata({
    required this.sessionId,
    required this.deviceId,
    required this.biometricType,
    required this.authenticatedAt,
    required this.remainingAttempts,
  });
}

/// Biometric authentication status response
class BiometricAuthStatusResponse {
  final bool isEnabled;
  final List<BiometricType> availableBiometrics;
  final List<BiometricDeviceRecord> registeredDevices;
  final DateTime? lastAuthAttempt;
  final int failedAttempts;
  final DateTime? lockoutUntil;

  BiometricAuthStatusResponse({
    required this.isEnabled,
    required this.availableBiometrics,
    required this.registeredDevices,
    this.lastAuthAttempt,
    required this.failedAttempts,
    this.lockoutUntil,
  });
}

/// Biometric device record
class BiometricDeviceRecord {
  final String deviceId;
  final String deviceName;
  final BiometricType biometricType;
  final DateTime registeredAt;
  final DateTime? lastUsed;
  final bool isActive;
  final String deviceSignature;

  BiometricDeviceRecord({
    required this.deviceId,
    required this.deviceName,
    required this.biometricType,
    required this.registeredAt,
    this.lastUsed,
    required this.isActive,
    required this.deviceSignature,
  });
}

/// Biometric session response
class BiometricSessionResponse {
  final bool success;
  final String? newAuthToken;
  final String? newRefreshToken;
  final DateTime? newExpiresAt;
  final String? errorMessage;

  BiometricSessionResponse({
    required this.success,
    this.newAuthToken,
    this.newRefreshToken,
    this.newExpiresAt,
    this.errorMessage,
  });
}
