import 'package:dartz/dartz.dart';
import '../entities/device_entity.dart';
import '../entities/device_session_entity.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

abstract class DeviceRepository {
  Future<Either<Failure, DeviceEntity>> registerDevice({
    required String name,
    required String type,
    required String hardwareId,
    required String ipAddress,
    required String browserFingerprint,
    required String installationId,
    DeviceLocationEntity? location,
  });

  Future<Either<Failure, DeviceEntity>> getDeviceById(String deviceId);

  Future<Either<Failure, List<DeviceEntity>>> getUserDevices(String userId);

  Future<Either<Failure, DeviceEntity>> updateDevice({
    required String deviceId,
    String? name,
    DeviceLocationEntity? location,
  });

  Future<Either<Failure, Unit>> logoutDevice(String deviceId);

  Future<Either<Failure, Unit>> revokeAllDevices(String userId);

  Future<Either<Failure, DeviceSessionEntity>> createSession({
    required String deviceId,
    required String userId,
    required String ipAddress,
    String? userAgent,
  });

  Future<Either<Failure, Unit>> endSession(String sessionId);

  Future<Either<Failure, List<DeviceSessionEntity>>> getDeviceSessions(String deviceId);

  Future<Either<Failure, bool>> isDeviceTrusted(String deviceId);

  Future<Either<Failure, int>> getDeviceTrustScore(String deviceId);

  Future<Either<Failure, Unit>> updateDeviceTrust({
    required String deviceId,
    required int trustScore,
    String? reason,
  });

  Future<Either<Failure, Unit>> recordDeviceActivity({
    required String deviceId,
    required String userId,
    required String activityType,
    required String description,
    required String ipAddress,
    DeviceLocationEntity? location,
    Map<String, dynamic>? metadata,
  });

  Future<Either<Failure, List<DeviceEntity>>> getTrustedDevices(String userId);

  Future<Either<Failure, List<DeviceEntity>>> getSuspiciousDevices(String userId);

  Future<Either<Failure, bool>> isSuspiciousActivity({
    required String deviceId,
    required String ipAddress,
    required String userAgent,
  });
}