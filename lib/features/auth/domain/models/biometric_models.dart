import 'package:equatable/equatable.dart';

enum BiometricType {
  faceId,
  touchId,
  fingerprint,
  iris,
  none,
}

enum BiometricAuthStatus {
  available,
  notAvailable,
  notEnrolled,
  lockedOut,
  temporarilyLocked,
  error,
}

class BiometricDeviceCapability extends Equatable {
  final BiometricType type;
  final bool isAvailable;
  final BiometricAuthStatus status;
  final String errorMessage;

  const BiometricDeviceCapability({
    required this.type,
    required this.isAvailable,
    required this.status,
    this.errorMessage = '',
  });

  BiometricDeviceCapability copyWith({
    BiometricType? type,
    bool? isAvailable,
    BiometricAuthStatus? status,
    String? errorMessage,
  }) {
    return BiometricDeviceCapability(
      type: type ?? this.type,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object> get props => [type, isAvailable, status, errorMessage];
}

class BiometricAuthResult extends Equatable {
  final bool success;
  final String? errorMessage;
  final BiometricType biometricType;
  final DateTime timestamp;

  const BiometricAuthResult({
    required this.success,
    this.errorMessage,
    required this.biometricType,
    required this.timestamp,
  });

  BiometricAuthResult.success({
    required this.biometricType,
  }) : success = true,
       errorMessage = null,
       timestamp = DateTime.now();

  BiometricAuthResult.failure({
    required this.errorMessage,
    required this.biometricType,
  }) : success = false,
       timestamp = DateTime.now();

  @override
  List<Object?> get props => [success, errorMessage, biometricType, timestamp];
}

class BiometricPreferences extends Equatable {
  final bool isEnabled;
  final BiometricType preferredBiometricType;
  final DateTime? lastSuccessfulAuth;
  final int failedAttempts;
  final DateTime? lockoutUntil;

  const BiometricPreferences({
    this.isEnabled = false,
    this.preferredBiometricType = BiometricType.none,
    this.lastSuccessfulAuth,
    this.failedAttempts = 0,
    this.lockoutUntil,
  });

  BiometricPreferences copyWith({
    bool? isEnabled,
    BiometricType? preferredBiometricType,
    DateTime? lastSuccessfulAuth,
    int? failedAttempts,
    DateTime? lockoutUntil,
  }) {
    return BiometricPreferences(
      isEnabled: isEnabled ?? this.isEnabled,
      preferredBiometricType: preferredBiometricType ?? this.preferredBiometricType,
      lastSuccessfulAuth: lastSuccessfulAuth ?? this.lastSuccessfulAuth,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: lockoutUntil ?? this.lockoutUntil,
    );
  }

  bool get isLockedOut => lockoutUntil != null && lockoutUntil!.isAfter(DateTime.now());

  @override
  List<Object?> get props => [
    isEnabled,
    preferredBiometricType,
    lastSuccessfulAuth,
    failedAttempts,
    lockoutUntil,
  ];
}

/// Biometric device registration result
class BiometricDeviceRegistrationResult extends Equatable {
  final bool success;
  final String deviceId;
  final DateTime registeredAt;
  final String? errorMessage;
  final BiometricDeviceRegistrationMetadata metadata;

  const BiometricDeviceRegistrationResult({
    required this.success,
    required this.deviceId,
    required this.registeredAt,
    this.errorMessage,
    required this.metadata,
  });

  @override
  List<Object?> get props => [success, deviceId, registeredAt, errorMessage, metadata];
}

/// Biometric device registration metadata
class BiometricDeviceRegistrationMetadata extends Equatable {
  final String deviceSignature;
  final String challengeId;
  final DateTime expiresAt;
  final int maxAttempts;
  final int remainingAttempts;

  const BiometricDeviceRegistrationMetadata({
    required this.deviceSignature,
    required this.challengeId,
    required this.expiresAt,
    required this.maxAttempts,
    required this.remainingAttempts,
  });

  @override
  List<Object> get props => [deviceSignature, challengeId, expiresAt, maxAttempts, remainingAttempts];
}

/// Biometric authentication response
class BiometricAuthResponse extends Equatable {
  final bool success;
  final String? authToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? errorMessage;
  final BiometricAuthMetadata metadata;

  const BiometricAuthResponse({
    required this.success,
    this.authToken,
    this.refreshToken,
    this.expiresAt,
    this.errorMessage,
    required this.metadata,
  });

  @override
  List<Object?> get props => [success, authToken, refreshToken, expiresAt, errorMessage, metadata];
}

/// Biometric authentication metadata
class BiometricAuthMetadata extends Equatable {
  final String sessionId;
  final String deviceId;
  final BiometricType biometricType;
  final DateTime authenticatedAt;
  final int remainingAttempts;

  const BiometricAuthMetadata({
    required this.sessionId,
    required this.deviceId,
    required this.biometricType,
    required this.authenticatedAt,
    required this.remainingAttempts,
  });

  @override
  List<Object> get props => [sessionId, deviceId, biometricType, authenticatedAt, remainingAttempts];
}

/// Biometric authentication status response
class BiometricAuthStatusResponse extends Equatable {
  final bool isEnabled;
  final List<BiometricType> availableBiometrics;
  final List<BiometricDeviceRecord> registeredDevices;
  final DateTime? lastAuthAttempt;
  final int failedAttempts;
  final DateTime? lockoutUntil;

  const BiometricAuthStatusResponse({
    required this.isEnabled,
    required this.availableBiometrics,
    required this.registeredDevices,
    this.lastAuthAttempt,
    required this.failedAttempts,
    this.lockoutUntil,
  });

  @override
  List<Object?> get props => [
    isEnabled,
    availableBiometrics,
    registeredDevices,
    lastAuthAttempt,
    failedAttempts,
    lockoutUntil,
  ];
}

/// Biometric device record
class BiometricDeviceRecord extends Equatable {
  final String deviceId;
  final String deviceName;
  final BiometricType biometricType;
  final DateTime registeredAt;
  final DateTime? lastUsed;
  final bool isActive;
  final String deviceSignature;

  const BiometricDeviceRecord({
    required this.deviceId,
    required this.deviceName,
    required this.biometricType,
    required this.registeredAt,
    this.lastUsed,
    required this.isActive,
    required this.deviceSignature,
  });

  @override
  List<Object?> get props => [
    deviceId,
    deviceName,
    biometricType,
    registeredAt,
    lastUsed,
    isActive,
    deviceSignature,
  ];
}

/// Biometric session response
class BiometricSessionResponse extends Equatable {
  final bool success;
  final String? newAuthToken;
  final String? newRefreshToken;
  final DateTime? newExpiresAt;
  final String? errorMessage;

  const BiometricSessionResponse({
    required this.success,
    this.newAuthToken,
    this.newRefreshToken,
    this.newExpiresAt,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [success, newAuthToken, newRefreshToken, newExpiresAt, errorMessage];
}

/// Biometric authentication state
class BiometricAuthState extends Equatable {
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;
  final BiometricDeviceCapability? deviceCapability;
  final BiometricPreferences? preferences;
  final BiometricAuthResult? lastAuthResult;

  const BiometricAuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
    this.deviceCapability,
    this.preferences,
    this.lastAuthResult,
  });

  BiometricAuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
    BiometricDeviceCapability? deviceCapability,
    BiometricPreferences? preferences,
    BiometricAuthResult? lastAuthResult,
  }) {
    return BiometricAuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage,
      deviceCapability: deviceCapability ?? this.deviceCapability,
      preferences: preferences ?? this.preferences,
      lastAuthResult: lastAuthResult ?? this.lastAuthResult,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isAuthenticated,
    errorMessage,
    deviceCapability,
    preferences,
    lastAuthResult,
  ];
}

/// Biometric authentication events
abstract class BiometricAuthEvent extends Equatable {
  const BiometricAuthEvent();

  @override
  List<Object> get props => [];
}

class CheckBiometricCapability extends BiometricAuthEvent {}

class GetBiometricPreferences extends BiometricAuthEvent {}

class EnableBiometricAuth extends BiometricAuthEvent {}

class DisableBiometricAuth extends BiometricAuthEvent {}

class AuthenticateWithBiometrics extends BiometricAuthEvent {
  final String reason;

  const AuthenticateWithBiometrics({this.reason = 'Authenticate with biometrics'});

  @override
  List<Object> get props => [reason];
}

class ResetBiometricAuth extends BiometricAuthEvent {}

class ClearBiometricError extends BiometricAuthEvent {}

/// Biometric authentication exceptions
class BiometricException implements Exception {
  final String message;

  const BiometricException(this.message);

  @override
  String toString() => 'BiometricException: $message';
}