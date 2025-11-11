import 'package:serverpod/serverpod.dart';
import '../../services/device_trust_service.dart';
import '../../generated/capabilities/trusted_device.dart';

/// Device trust endpoint for managing device registration and trust
/// Implements Epic 2 Story 2-4: Device Trust & Risk Monitoring
class DeviceEndpoint extends Endpoint {
  @override
  String get name => 'devices';

  /// Register or update device telemetry
  /// AC1: Device registration occurs on app launch, capturing device ID, platform, attestation result, and telemetry
  ///
  /// POST /devices/register
  Future<TrustedDevice> registerDevice(
    Session session,
    int userId,
    String deviceId,
    String deviceType,
    String platform,
    Map<String, dynamic> telemetry,
  ) async {
    try {
      final deviceTrustService = DeviceTrustService(session);

      final device = await deviceTrustService.registerDevice(
        userId: userId,
        deviceId: deviceId,
        deviceType: deviceType,
        platform: platform,
        telemetry: telemetry,
      );

      session.log(
        'Device registered for user $userId: $deviceId',
        level: LogLevel.info,
      );

      return device;
    } catch (e, stackTrace) {
      session.log(
        'Failed to register device for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all active devices for the current user
  /// AC3: Device management screen lists registered devices with trust score, last seen timestamp
  ///
  /// GET /devices
  Future<List<TrustedDevice>> getDevices(
    Session session,
    int userId,
  ) async {
    try {
      final deviceTrustService = DeviceTrustService(session);
      final devices = await deviceTrustService.getUserDevices(userId);

      session.log(
        'Devices fetched for user $userId: ${devices.length} devices',
        level: LogLevel.info,
      );

      return devices;
    } catch (e, stackTrace) {
      session.log(
        'Failed to get devices for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Revoke device trust
  /// AC3: Revocation lowers capability state appropriately
  ///
  /// POST /devices/{id}/revoke
  Future<void> revokeDevice(
    Session session,
    int userId,
    int deviceId,
    String? reason,
  ) async {
    try {
      final deviceTrustService = DeviceTrustService(session);

      await deviceTrustService.revokeDevice(
        userId: userId,
        deviceId: deviceId,
        reason: reason,
      );

      session.log(
        'Device revoked for user $userId: device $deviceId',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to revoke device for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
