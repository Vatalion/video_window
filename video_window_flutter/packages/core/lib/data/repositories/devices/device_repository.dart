t' show Client;

/// Repository for device trust management
/// Implements data layer for Epic 2 Story 2-4
class DeviceRepository {
  final Client _client;

  DeviceRepository(this._client);

  /// Register or update device telemetry
  /// AC1: Device registration occurs on app launch
  Future<dynamic> registerDevice({
    required int userId,
    required String deviceId,
    required String deviceType,
    required String platform,
    required Map<String, dynamic> telemetry,
  }) async {
    try {
      // TODO: Replace with generated client call after Serverpod generation
      // final device = await _client.devices.registerDevice(
      //   userId,
      //   deviceId,
      //   deviceType,
      //   platform,
      //   telemetry,
      // );
      // return device;

      throw UnimplementedError('Waiting for Serverpod client generation. '
          'Run: cd video_window_server && serverpod generate');
    } catch (e) {
      throw DeviceRepositoryException(
        'Failed to register device: $e',
      );
    }
  }

  /// Get all active devices for user
  /// AC3: Device management screen lists registered devices
  Future<List<dynamic>> getDevices(int userId) async {
    try {
      // TODO: Replace with generated client call
      // final devices = await _client.devices.getDevices(userId);
      // return devices;

      throw UnimplementedError('Waiting for Serverpod client generation');
    } catch (e) {
      throw DeviceRepositoryException(
        'Failed to get devices: $e',
      );
    }
  }

  /// Revoke device trust
  /// AC3: Revocation lowers capability state appropriately
  Future<void> revokeDevice({
    required int userId,
    required int deviceId,
    String? reason,
  }) async {
    try {
      // TODO: Replace with generated client call
      // await _client.devices.revokeDevice(userId, deviceId, reason);

      throw UnimplementedError('Waiting for Serverpod client generation');
    } catch (e) {
      throw DeviceRepositoryException(
        'Failed to revoke device: $e',
      );
    }
  }
}

/// Exception thrown by device repository
class DeviceRepositoryException implements Exception {
  final String message;

  DeviceRepositoryException(this.message);

  @override
  String toString() => 'DeviceRepositoryException: $message';
}
