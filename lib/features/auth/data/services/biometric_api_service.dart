import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/exceptions.dart';
import '../../domain/models/biometric_models.dart';
import '../datasources/biometric_remote_data_source.dart';
import '../../../core/utils/constants.dart';

class BiometricApiService implements BiometricRemoteDataSource {
  final Dio _dio;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  BiometricApiService(this._dio) {
    _dio.options.baseUrl =
        '${AppConstants.baseUrl}/api/${AppConstants.apiVersion}';
    _dio.options.connectTimeout = const Duration(
      seconds: AppConstants.networkTimeoutSeconds,
    );
    _dio.options.receiveTimeout = const Duration(
      seconds: AppConstants.networkTimeoutSeconds,
    );
  }

  @override
  Future<BiometricDeviceRegistrationResult> registerBiometricDevice({
    required String userId,
    required BiometricType biometricType,
    required String deviceInfo,
    String? deviceName,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/biometric/register',
        data: {
          'userId': userId,
          'biometricType': biometricType.name,
          'deviceInfo': deviceInfo,
          'deviceName': deviceName ?? 'Unknown Device',
          'registrationId': _uuid.v4(),
        },
      );

      final data = response.data;
      return BiometricDeviceRegistrationResult(
        success: data['success'] ?? false,
        deviceId: data['deviceId'] ?? '',
        registeredAt: DateTime.parse(
          data['registeredAt'] ?? DateTime.now().toIso8601String(),
        ),
        errorMessage: data['errorMessage'],
        metadata: BiometricDeviceRegistrationMetadata(
          deviceSignature: data['metadata']['deviceSignature'] ?? '',
          challengeId: data['metadata']['challengeId'] ?? '',
          expiresAt: DateTime.parse(
            data['metadata']['expiresAt'] ??
                DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          ),
          maxAttempts: data['metadata']['maxAttempts'] ?? 5,
          remainingAttempts: data['metadata']['remainingAttempts'] ?? 5,
        ),
      );
    } on DioException catch (e) {
      _logger.e('Error registering biometric device: ${e.message}');
      throw BiometricException(
        'Failed to register biometric device: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      _logger.e('Unexpected error registering biometric device: $e');
      throw BiometricException(
        'Unexpected error during biometric device registration',
      );
    }
  }

  @override
  Future<BiometricAuthResponse> authenticateWithBiometrics({
    required String userId,
    required BiometricType biometricType,
    required String deviceSignature,
    required String biometricChallengeResponse,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/biometric/authenticate',
        data: {
          'userId': userId,
          'biometricType': biometricType.name,
          'deviceSignature': deviceSignature,
          'challengeResponse': biometricChallengeResponse,
          'sessionId': _uuid.v4(),
        },
      );

      final data = response.data;
      return BiometricAuthResponse(
        success: data['success'] ?? false,
        authToken: data['authToken'],
        refreshToken: data['refreshToken'],
        expiresAt: data['expiresAt'] != null
            ? DateTime.parse(data['expiresAt'])
            : null,
        errorMessage: data['errorMessage'],
        metadata: BiometricAuthMetadata(
          sessionId: data['metadata']['sessionId'] ?? '',
          deviceId: data['metadata']['deviceId'] ?? '',
          biometricType: BiometricType.values.firstWhere(
            (type) => type.name == data['metadata']['biometricType'],
            orElse: () => BiometricType.none,
          ),
          authenticatedAt: DateTime.parse(
            data['metadata']['authenticatedAt'] ??
                DateTime.now().toIso8601String(),
          ),
          remainingAttempts: data['metadata']['remainingAttempts'] ?? 5,
        ),
      );
    } on DioException catch (e) {
      _logger.e('Error authenticating with biometrics: ${e.message}');
      return BiometricAuthResponse(
        success: false,
        errorMessage: e.response?.data['message'] ?? e.message,
        metadata: BiometricAuthMetadata(
          sessionId: '',
          deviceId: '',
          biometricType: biometricType,
          authenticatedAt: DateTime.now(),
          remainingAttempts: 0,
        ),
      );
    } catch (e) {
      _logger.e('Unexpected error authenticating with biometrics: $e');
      return BiometricAuthResponse(
        success: false,
        errorMessage: 'Unexpected error during biometric authentication',
        metadata: BiometricAuthMetadata(
          sessionId: '',
          deviceId: '',
          biometricType: biometricType,
          authenticatedAt: DateTime.now(),
          remainingAttempts: 0,
        ),
      );
    }
  }

  @override
  Future<bool> disableBiometricAuth({
    required String userId,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/biometric/disable',
        data: {'userId': userId, 'deviceId': deviceId},
      );

      return response.data['success'] ?? false;
    } on DioException catch (e) {
      _logger.e('Error disabling biometric auth: ${e.message}');
      throw BiometricException(
        'Failed to disable biometric authentication: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      _logger.e('Unexpected error disabling biometric auth: $e');
      throw BiometricException(
        'Unexpected error during biometric authentication disabling',
      );
    }
  }

  @override
  Future<BiometricAuthStatusResponse> getBiometricAuthStatus({
    required String userId,
  }) async {
    try {
      final response = await _dio.get(
        '/auth/biometric/status',
        queryParameters: {'userId': userId},
      );

      final data = response.data;
      return BiometricAuthStatusResponse(
        isEnabled: data['isEnabled'] ?? false,
        availableBiometrics:
            (data['availableBiometrics'] as List<dynamic>?)
                ?.map(
                  (type) => BiometricType.values.firstWhere(
                    (t) => t.name == type,
                    orElse: () => BiometricType.none,
                  ),
                )
                .toList() ??
            [],
        registeredDevices:
            (data['registeredDevices'] as List<dynamic>?)
                ?.map(
                  (device) => BiometricDeviceRecord(
                    deviceId: device['deviceId'] ?? '',
                    deviceName: device['deviceName'] ?? 'Unknown Device',
                    biometricType: BiometricType.values.firstWhere(
                      (t) => t.name == device['biometricType'],
                      orElse: () => BiometricType.none,
                    ),
                    registeredAt: DateTime.parse(
                      device['registeredAt'] ??
                          DateTime.now().toIso8601String(),
                    ),
                    lastUsed: device['lastUsed'] != null
                        ? DateTime.parse(device['lastUsed'])
                        : null,
                    isActive: device['isActive'] ?? false,
                    deviceSignature: device['deviceSignature'] ?? '',
                  ),
                )
                .toList() ??
            [],
        lastAuthAttempt: data['lastAuthAttempt'] != null
            ? DateTime.parse(data['lastAuthAttempt'])
            : null,
        failedAttempts: data['failedAttempts'] ?? 0,
        lockoutUntil: data['lockoutUntil'] != null
            ? DateTime.parse(data['lockoutUntil'])
            : null,
      );
    } on DioException catch (e) {
      _logger.e('Error getting biometric auth status: ${e.message}');
      throw BiometricException(
        'Failed to get biometric authentication status: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      _logger.e('Unexpected error getting biometric auth status: $e');
      throw BiometricException(
        'Unexpected error getting biometric authentication status',
      );
    }
  }

  @override
  Future<List<BiometricDeviceRecord>> getRegisteredBiometricDevices({
    required String userId,
  }) async {
    try {
      final response = await _dio.get(
        '/auth/biometric/devices',
        queryParameters: {'userId': userId},
      );

      return (response.data['devices'] as List<dynamic>?)
              ?.map(
                (device) => BiometricDeviceRecord(
                  deviceId: device['deviceId'] ?? '',
                  deviceName: device['deviceName'] ?? 'Unknown Device',
                  biometricType: BiometricType.values.firstWhere(
                    (t) => t.name == device['biometricType'],
                    orElse: () => BiometricType.none,
                  ),
                  registeredAt: DateTime.parse(
                    device['registeredAt'] ?? DateTime.now().toIso8601String(),
                  ),
                  lastUsed: device['lastUsed'] != null
                      ? DateTime.parse(device['lastUsed'])
                      : null,
                  isActive: device['isActive'] ?? false,
                  deviceSignature: device['deviceSignature'] ?? '',
                ),
              )
              .toList() ??
          [];
    } on DioException catch (e) {
      _logger.e('Error getting registered biometric devices: ${e.message}');
      throw BiometricException(
        'Failed to get registered biometric devices: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      _logger.e('Unexpected error getting registered biometric devices: $e');
      throw BiometricException(
        'Unexpected error getting registered biometric devices',
      );
    }
  }

  @override
  Future<bool> removeBiometricDevice({
    required String userId,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.delete(
        '/auth/biometric/devices/$deviceId',
        queryParameters: {'userId': userId},
      );

      return response.data['success'] ?? false;
    } on DioException catch (e) {
      _logger.e('Error removing biometric device: ${e.message}');
      throw BiometricException(
        'Failed to remove biometric device: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      _logger.e('Unexpected error removing biometric device: $e');
      throw BiometricException('Unexpected error removing biometric device');
    }
  }

  @override
  Future<void> logBiometricAuthAttempt({
    required String userId,
    required BiometricType biometricType,
    required bool success,
    String? errorMessage,
    String? deviceId,
  }) async {
    try {
      await _dio.post(
        '/auth/biometric/log',
        data: {
          'userId': userId,
          'biometricType': biometricType.name,
          'success': success,
          'errorMessage': errorMessage,
          'deviceId': deviceId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } on DioException catch (e) {
      _logger.w('Failed to log biometric auth attempt: ${e.message}');
      // Don't throw exception for logging failures
    } catch (e) {
      _logger.w('Unexpected error logging biometric auth attempt: $e');
    }
  }

  @override
  Future<bool> updateBiometricDevice({
    required String userId,
    required String deviceId,
    String? deviceName,
    bool? isActive,
  }) async {
    try {
      final response = await _dio.put(
        '/auth/biometric/devices/$deviceId',
        data: {
          'userId': userId,
          'deviceName': deviceName,
          'isActive': isActive,
        },
      );

      return response.data['success'] ?? false;
    } on DioException catch (e) {
      _logger.e('Error updating biometric device: ${e.message}');
      throw BiometricException(
        'Failed to update biometric device: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      _logger.e('Unexpected error updating biometric device: $e');
      throw BiometricException('Unexpected error updating biometric device');
    }
  }

  @override
  Future<bool> validateBiometricChallenge({
    required String userId,
    required String challenge,
    required String response,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/biometric/validate-challenge',
        data: {'userId': userId, 'challenge': challenge, 'response': response},
      );

      return response.data['valid'] ?? false;
    } on DioException catch (e) {
      _logger.e('Error validating biometric challenge: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Unexpected error validating biometric challenge: $e');
      return false;
    }
  }

  @override
  Future<BiometricSessionResponse> refreshBiometricSession({
    required String userId,
    required String deviceId,
    required String refreshToken,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/biometric/refresh-session',
        data: {
          'userId': userId,
          'deviceId': deviceId,
          'refreshToken': refreshToken,
        },
      );

      final data = response.data;
      return BiometricSessionResponse(
        success: data['success'] ?? false,
        newAuthToken: data['newAuthToken'],
        newRefreshToken: data['newRefreshToken'],
        newExpiresAt: data['newExpiresAt'] != null
            ? DateTime.parse(data['newExpiresAt'])
            : null,
        errorMessage: data['errorMessage'],
      );
    } on DioException catch (e) {
      _logger.e('Error refreshing biometric session: ${e.message}');
      return BiometricSessionResponse(
        success: false,
        errorMessage: e.response?.data['message'] ?? e.message,
      );
    } catch (e) {
      _logger.e('Unexpected error refreshing biometric session: $e');
      return BiometricSessionResponse(
        success: false,
        errorMessage: 'Unexpected error refreshing biometric session',
      );
    }
  }
}
