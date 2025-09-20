import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/exceptions.dart';
import '../../domain/models/biometric_models.dart';
import '../datasources/biometric_remote_data_source.dart';
import 'biometric_auth_service.dart';
import '../../../core/utils/constants.dart';

class BiometricAuthMiddleware {
  final BiometricAuthService _localAuthService;
  final BiometricRemoteDataSource _remoteDataSource;
  final DeviceInfoPlugin _deviceInfoPlugin;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  BiometricAuthMiddleware({
    required BiometricAuthService localAuthService,
    required BiometricRemoteDataSource remoteDataSource,
    DeviceInfoPlugin? deviceInfoPlugin,
  }) : _localAuthService = localAuthService,
       _remoteDataSource = remoteDataSource,
       _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  /// Initialize biometric authentication middleware
  Future<BiometricMiddlewareInitResult> initialize() async {
    try {
      final capability = await _localAuthService.checkBiometricCapability();
      final preferences = await _localAuthService.getBiometricPreferences();
      final deviceInfo = await _getDeviceInfo();

      return BiometricMiddlewareInitResult(
        isAvailable: capability.isAvailable,
        isEnabled: preferences.isEnabled,
        biometricType: capability.type,
        deviceInfo: deviceInfo,
        isLockedOut: preferences.isLockedOut,
        remainingLockoutTime: await _localAuthService.getRemainingLockoutTime(),
      );
    } catch (e) {
      _logger.e('Error initializing biometric middleware: $e');
      return BiometricMiddlewareInitResult(
        isAvailable: false,
        isEnabled: false,
        biometricType: BiometricType.none,
        deviceInfo: await _getDeviceInfo(),
        errorMessage: 'Failed to initialize biometric authentication',
      );
    }
  }

  /// Register device for biometric authentication
  Future<BiometricRegistrationResult> registerDevice({
    required String userId,
    String? deviceName,
  }) async {
    try {
      // Check local biometric capability
      final capability = await _localAuthService.checkBiometricCapability();
      if (!capability.isAvailable) {
        return BiometricRegistrationResult.failure(
          errorMessage:
              'Biometric authentication is not available on this device',
        );
      }

      // Test local biometric authentication
      final testResult = await _localAuthService.authenticate(
        reason: 'Enable biometric authentication',
      );
      if (!testResult.success) {
        return BiometricRegistrationResult.failure(
          errorMessage:
              testResult.errorMessage ?? 'Biometric authentication test failed',
        );
      }

      // Get device information
      final deviceInfo = await _getDeviceInfo();

      // Register with backend
      final registrationResult = await _remoteDataSource
          .registerBiometricDevice(
            userId: userId,
            biometricType: capability.type,
            deviceInfo: deviceInfo,
            deviceName: deviceName,
          );

      if (registrationResult.success) {
        // Enable local biometric authentication
        await _localAuthService.enableBiometricAuth();

        return BiometricRegistrationResult.success(
          deviceId: registrationResult.deviceId,
          biometricType: capability.type,
          registeredAt: registrationResult.registeredAt,
        );
      } else {
        return BiometricRegistrationResult.failure(
          errorMessage:
              registrationResult.errorMessage ??
              'Failed to register device with backend',
        );
      }
    } catch (e) {
      _logger.e('Error registering biometric device: $e');
      return BiometricRegistrationResult.failure(
        errorMessage: 'Failed to register biometric device: $e',
      );
    }
  }

  /// Authenticate using biometrics
  Future<BiometricMiddlewareAuthResult> authenticate({
    required String userId,
    String? deviceId,
  }) async {
    try {
      // Check local biometric availability
      final isAvailable = await _localAuthService.isBiometricAuthAvailable();
      if (!isAvailable) {
        return BiometricMiddlewareAuthResult.failure(
          errorMessage: 'Biometric authentication is not available',
        );
      }

      // Perform local biometric authentication
      final localResult = await _localAuthService.authenticate(
        reason: 'Sign in with biometrics',
      );

      if (!localResult.success) {
        return BiometricMiddlewareAuthResult.failure(
          errorMessage:
              localResult.errorMessage ?? 'Biometric authentication failed',
          biometricType: localResult.biometricType,
        );
      }

      // Get device information
      final deviceInfo = await _getDeviceInfo();

      // Generate challenge response (in a real implementation, this would involve cryptography)
      final challengeResponse = _generateChallengeResponse();

      // Authenticate with backend
      final remoteResult = await _remoteDataSource.authenticateWithBiometrics(
        userId: userId,
        biometricType: localResult.biometricType,
        deviceSignature: deviceInfo['signature'] ?? '',
        biometricChallengeResponse: challengeResponse,
      );

      if (remoteResult.success) {
        return BiometricMiddlewareAuthResult.success(
          authToken: remoteResult.authToken,
          refreshToken: remoteResult.refreshToken,
          expiresAt: remoteResult.expiresAt,
          biometricType: localResult.biometricType,
          sessionId: remoteResult.metadata.sessionId,
        );
      } else {
        return BiometricMiddlewareAuthResult.failure(
          errorMessage:
              remoteResult.errorMessage ?? 'Backend authentication failed',
          biometricType: localResult.biometricType,
        );
      }
    } catch (e) {
      _logger.e('Error during biometric authentication: $e');
      return BiometricMiddlewareAuthResult.failure(
        errorMessage: 'Unexpected error during biometric authentication',
      );
    }
  }

  /// Disable biometric authentication
  Future<BiometricDisableResult> disableBiometricAuth({
    required String userId,
    required String deviceId,
  }) async {
    try {
      // Disable local biometric authentication
      await _localAuthService.disableBiometricAuth();

      // Disable backend biometric authentication
      final remoteResult = await _remoteDataSource.disableBiometricAuth(
        userId: userId,
        deviceId: deviceId,
      );

      return BiometricDisableResult(
        success: remoteResult,
        message: remoteResult
            ? 'Biometric authentication disabled successfully'
            : 'Failed to disable biometric authentication',
      );
    } catch (e) {
      _logger.e('Error disabling biometric authentication: $e');
      return BiometricDisableResult(
        success: false,
        message: 'Failed to disable biometric authentication: $e',
      );
    }
  }

  /// Get biometric authentication status
  Future<BiometricMiddlewareStatusResult> getStatus({
    required String userId,
  }) async {
    try {
      final localCapability = await _localAuthService
          .checkBiometricCapability();
      final localPreferences = await _localAuthService
          .getBiometricPreferences();
      final remoteStatus = await _remoteDataSource.getBiometricAuthStatus(
        userId: userId,
      );

      return BiometricMiddlewareStatusResult(
        isLocallyAvailable: localCapability.isAvailable,
        isRemotelyEnabled: remoteStatus.isEnabled,
        localBiometricType: localCapability.type,
        registeredDevices: remoteStatus.registeredDevices,
        failedAttempts: localPreferences.failedAttempts,
        isLockedOut: localPreferences.isLockedOut,
        remainingLockoutTime: await _localAuthService.getRemainingLockoutTime(),
        lastAuthAttempt: remoteStatus.lastAuthAttempt,
      );
    } catch (e) {
      _logger.e('Error getting biometric status: $e');
      return BiometricMiddlewareStatusResult(
        isLocallyAvailable: false,
        isRemotelyEnabled: false,
        localBiometricType: BiometricType.none,
        registeredDevices: [],
        failedAttempts: 0,
        isLockedOut: false,
        errorMessage: 'Failed to get biometric authentication status',
      );
    }
  }

  /// Refresh biometric authentication session
  Future<BiometricSessionRefreshResult> refreshSession({
    required String userId,
    required String deviceId,
    required String refreshToken,
  }) async {
    try {
      final result = await _remoteDataSource.refreshBiometricSession(
        userId: userId,
        deviceId: deviceId,
        refreshToken: refreshToken,
      );

      if (result.success) {
        return BiometricSessionRefreshResult.success(
          newAuthToken: result.newAuthToken,
          newRefreshToken: result.newRefreshToken,
          newExpiresAt: result.newExpiresAt,
        );
      } else {
        return BiometricSessionRefreshResult.failure(
          errorMessage: result.errorMessage ?? 'Failed to refresh session',
        );
      }
    } catch (e) {
      _logger.e('Error refreshing biometric session: $e');
      return BiometricSessionRefreshResult.failure(
        errorMessage: 'Failed to refresh biometric session',
      );
    }
  }

  /// Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final deviceInfo = await _deviceInfoPlugin.deviceInfo;
      final deviceId = _uuid.v4();

      return {
        'deviceId': deviceId,
        'deviceName': deviceInfo.data['name']?.toString() ?? 'Unknown Device',
        'deviceModel': deviceInfo.data['model']?.toString() ?? 'Unknown Model',
        'deviceType': deviceInfo.data['system']?.toString() ?? 'Unknown System',
        'signature': _generateDeviceSignature(deviceId),
      };
    } catch (e) {
      _logger.e('Error getting device info: $e');
      return {
        'deviceId': _uuid.v4(),
        'deviceName': 'Unknown Device',
        'deviceModel': 'Unknown Model',
        'deviceType': 'Unknown System',
        'signature': _generateDeviceSignature(_uuid.v4()),
      };
    }
  }

  /// Generate device signature
  String _generateDeviceSignature(String deviceId) {
    // In a real implementation, this would involve proper cryptography
    return 'sig_${deviceId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate challenge response
  String _generateChallengeResponse() {
    // In a real implementation, this would involve proper cryptographic challenge-response
    return 'challenge_response_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Middleware initialization result
class BiometricMiddlewareInitResult {
  final bool isAvailable;
  final bool isEnabled;
  final BiometricType biometricType;
  final Map<String, String> deviceInfo;
  final bool isLockedOut;
  final Duration? remainingLockoutTime;
  final String? errorMessage;

  BiometricMiddlewareInitResult({
    required this.isAvailable,
    required this.isEnabled,
    required this.biometricType,
    required this.deviceInfo,
    required this.isLockedOut,
    this.remainingLockoutTime,
    this.errorMessage,
  });
}

/// Biometric registration result
class BiometricRegistrationResult {
  final bool success;
  final String? deviceId;
  final BiometricType? biometricType;
  final DateTime? registeredAt;
  final String? errorMessage;

  BiometricRegistrationResult.success({
    required this.deviceId,
    required this.biometricType,
    required this.registeredAt,
  }) : success = true,
       errorMessage = null;

  BiometricRegistrationResult.failure({required this.errorMessage})
    : success = false,
      deviceId = null,
      biometricType = null,
      registeredAt = null;
}

/// Biometric middleware authentication result
class BiometricMiddlewareAuthResult {
  final bool success;
  final String? authToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final BiometricType? biometricType;
  final String? sessionId;
  final String? errorMessage;

  BiometricMiddlewareAuthResult.success({
    required this.authToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.biometricType,
    required this.sessionId,
  }) : success = true,
       errorMessage = null;

  BiometricMiddlewareAuthResult.failure({
    required this.errorMessage,
    this.biometricType,
  }) : success = false,
       authToken = null,
       refreshToken = null,
       expiresAt = null,
       sessionId = null;
}

/// Biometric disable result
class BiometricDisableResult {
  final bool success;
  final String message;

  BiometricDisableResult({required this.success, required this.message});
}

/// Biometric middleware status result
class BiometricMiddlewareStatusResult {
  final bool isLocallyAvailable;
  final bool isRemotelyEnabled;
  final BiometricType localBiometricType;
  final List<dynamic> registeredDevices;
  final int failedAttempts;
  final bool isLockedOut;
  final Duration? remainingLockoutTime;
  final DateTime? lastAuthAttempt;
  final String? errorMessage;

  BiometricMiddlewareStatusResult({
    required this.isLocallyAvailable,
    required this.isRemotelyEnabled,
    required this.localBiometricType,
    required this.registeredDevices,
    required this.failedAttempts,
    required this.isLockedOut,
    this.remainingLockoutTime,
    this.lastAuthAttempt,
    this.errorMessage,
  });
}

/// Biometric session refresh result
class BiometricSessionRefreshResult {
  final bool success;
  final String? newAuthToken;
  final String? newRefreshToken;
  final DateTime? newExpiresAt;
  final String? errorMessage;

  BiometricSessionRefreshResult.success({
    required this.newAuthToken,
    required this.newRefreshToken,
    required this.newExpiresAt,
  }) : success = true,
       errorMessage = null;

  BiometricSessionRefreshResult.failure({required this.errorMessage})
    : success = false,
      newAuthToken = null,
      newRefreshToken = null,
      newExpiresAt = null;
}
