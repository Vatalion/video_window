import 'package:flutter/material.dart';
import '../models/device_model.dart';

class DeviceManagementService {
  final String _apiBaseUrl;
  final String _encryptionKey;

  DeviceManagementService({
    required String apiBaseUrl,
    required String encryptionKey,
  }) : _apiBaseUrl = apiBaseUrl,
       _encryptionKey = encryptionKey;

  Future<DeviceModel> registerDevice({
    required String userId,
    required String deviceName,
    required String deviceType,
    required String platform,
    required String osVersion,
    required String deviceId,
    required String ipAddress,
    String? userAgent,
    String? manufacturer,
    String? model,
    String? appVersion,
    String? location,
  }) async {
    // Generate installation ID if not provided
    final installationId = _generateInstallationId();

    // Create device fingerprint
    final fingerprint = _generateDeviceFingerprint(
      deviceId: deviceId,
      platform: platform,
      manufacturer: manufacturer,
      model: model,
      osVersion: osVersion,
    );

    // Calculate initial trust score
    final trustScore = _calculateInitialTrustScore(ipAddress, userAgent);

    final device = DeviceModel(
      id: 'device_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      deviceName: deviceName,
      deviceType: deviceType,
      platform: platform,
      manufacturer: manufacturer,
      model: model,
      osVersion: osVersion,
      appVersion: appVersion,
      deviceId: deviceId,
      installationId: installationId,
      ipAddress: ipAddress,
      location: location,
      isTrusted: false,
      trustScore: trustScore,
      isActive: true,
      lastActivity: DateTime.now(),
      firstLogin: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Store device information (mock implementation)
    await _storeDevice(device);

    // Send notification for new device
    await _sendNewDeviceNotification(device);

    debugPrint('Device registered: ${device.toJson()}');

    return device;
  }

  Future<List<DeviceModel>> getUserDevices(String userId) async {
    // Mock implementation - return sample devices
    return [
      DeviceModel(
        id: 'device_1',
        userId: userId,
        deviceName: 'iPhone 13 Pro',
        deviceType: 'mobile',
        platform: 'iOS',
        manufacturer: 'Apple',
        model: 'iPhone13,3',
        osVersion: '17.0',
        appVersion: '1.0.0',
        deviceId: 'ios_device_123',
        installationId: 'install_123',
        ipAddress: '192.168.1.100',
        location: 'San Francisco, CA',
        isTrusted: true,
        trustScore: 85,
        isActive: true,
        lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
        firstLogin: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      DeviceModel(
        id: 'device_2',
        userId: userId,
        deviceName: 'MacBook Pro',
        deviceType: 'desktop',
        platform: 'macOS',
        manufacturer: 'Apple',
        model: 'MacBookPro18,1',
        osVersion: '13.0',
        appVersion: '1.0.0',
        deviceId: 'mac_device_456',
        installationId: 'install_456',
        ipAddress: '192.168.1.101',
        location: 'San Francisco, CA',
        isTrusted: true,
        trustScore: 90,
        isActive: false,
        lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
        firstLogin: DateTime.now().subtract(const Duration(days: 15)),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  Future<bool> updateDeviceTrust({
    required String deviceId,
    required String userId,
    required bool isTrusted,
  }) async {
    debugPrint('Updating device trust: $deviceId, trusted: $isTrusted');
    return true;
  }

  Future<bool> logoutDevice({
    required String deviceId,
    required String userId,
    required String sessionToken,
  }) async {
    debugPrint('Logging out device: $deviceId for user: $userId');

    // Invalidate all sessions for this device
    await _invalidateDeviceSessions(deviceId);

    // Send notification
    await _sendDeviceLogoutNotification(deviceId, userId);

    return true;
  }

  Future<bool> logoutAllDevices({
    required String userId,
    required String currentDeviceId,
  }) async {
    debugPrint(
      'Logging out all devices for user: $userId except current: $currentDeviceId',
    );

    // Get all user devices
    final devices = await getUserDevices(userId);

    // Logout all devices except current
    for (final device in devices) {
      if (device.id != currentDeviceId) {
        await logoutDevice(
          deviceId: device.id,
          userId: userId,
          sessionToken: '', // Will be retrieved from sessions
        );
      }
    }

    return true;
  }

  Future<DeviceModel> updateDeviceActivity({
    required String deviceId,
    required String ipAddress,
    String? userAgent,
    String? location,
  }) async {
    // Get current device
    final device = await _getDevice(deviceId);

    // Update trust score based on activity
    final newTrustScore = _updateTrustScore(device, ipAddress, userAgent);

    // Update device with new activity
    final updatedDevice = device.copyWith(
      ipAddress: ipAddress,
      location: location,
      lastActivity: DateTime.now(),
      trustScore: newTrustScore,
      updatedAt: DateTime.now(),
    );

    await _storeDevice(updatedDevice);

    return updatedDevice;
  }

  Future<bool> checkSuspiciousActivity({
    required String userId,
    required String deviceId,
    required String ipAddress,
    String? userAgent,
  }) async {
    // Get recent device activities
    final recentActivities = await _getRecentDeviceActivities(
      deviceId,
      const Duration(hours: 24),
    );

    // Check for suspicious patterns
    final isSuspicious = _detectSuspiciousPattern(
      recentActivities,
      ipAddress,
      userAgent,
    );

    if (isSuspicious) {
      await _flagSuspiciousDevice(deviceId, userId);
      await _sendSecurityAlert(userId, deviceId, ipAddress);
    }

    return isSuspicious;
  }

  Future<List<DeviceSession>> getDeviceSessions(String deviceId) async {
    // Mock implementation
    return [
      DeviceSession(
        id: 'session_1',
        deviceId: deviceId,
        userId: 'user_123',
        sessionToken: 'token_123',
        ipAddress: '192.168.1.100',
        userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
        loginTime: DateTime.now().subtract(const Duration(hours: 2)),
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  Future<bool> cleanupInactiveDevices() async {
    // Remove devices inactive for more than 30 days
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    debugPrint('Cleaning up devices inactive since: $cutoffDate');
    return true;
  }

  Future<Map<String, dynamic>> getDeviceAnalytics(String userId) async {
    // Mock implementation
    return {
      'total_devices': 3,
      'active_devices': 2,
      'trusted_devices': 2,
      'average_trust_score': 75,
      'last_device_login': DateTime.now()
          .subtract(const Duration(minutes: 30))
          .toIso8601String(),
      'devices_by_type': {'mobile': 2, 'desktop': 1, 'tablet': 0},
      'security_events_last_30_days': 1,
    };
  }

  // Helper methods
  String _generateInstallationId() {
    return 'install_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  String _generateDeviceFingerprint({
    required String deviceId,
    required String platform,
    String? manufacturer,
    String? model,
    required String osVersion,
  }) {
    final fingerprintData = [
      deviceId,
      platform,
      manufacturer ?? '',
      model ?? '',
      osVersion,
    ].join('|');

    return fingerprintData.hashCode.toString();
  }

  int _calculateInitialTrustScore(String ipAddress, String? userAgent) {
    int score = 50; // Base score

    // Check if IP is in trusted range (mock implementation)
    if (ipAddress.startsWith('192.168.')) {
      score += 20;
    }

    // Check user agent for known browsers (mock implementation)
    if (userAgent?.contains('Chrome') == true ||
        userAgent?.contains('Safari') == true ||
        userAgent?.contains('Firefox') == true) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  int _updateTrustScore(
    DeviceModel device,
    String ipAddress,
    String? userAgent,
  ) {
    int newScore = device.trustScore;

    // Increase score for consistent IP
    if (device.ipAddress == ipAddress) {
      newScore += 2;
    }

    // Increase score for regular activity
    final daysSinceLastActivity = DateTime.now()
        .difference(device.lastActivity)
        .inDays;
    if (daysSinceLastActivity < 1) {
      newScore += 1;
    }

    // Decrease score for suspicious activity (mock)
    if (await _isSuspiciousIpAddress(ipAddress)) {
      newScore -= 10;
    }

    return newScore.clamp(0, 100);
  }

  bool _detectSuspiciousPattern(
    List<dynamic> recentActivities,
    String currentIp,
    String? currentUserAgent,
  ) {
    if (recentActivities.isEmpty) return false;

    // Check for multiple IPs in short time
    final uniqueIps = recentActivities
        .map((a) => a['ip_address'] as String)
        .toSet();
    if (uniqueIps.length > 3) {
      return true;
    }

    // Check for geographic anomalies (mock implementation)
    if (uniqueIps.length > 1 && !uniqueIps.contains(currentIp)) {
      return true;
    }

    return false;
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final randomGenerator = Random(random);
    return List.generate(
      length,
      (index) => chars[randomGenerator.nextInt(chars.length)],
    ).join('');
  }

  Future<void> _storeDevice(DeviceModel device) async {
    // Mock implementation - store device in database
    debugPrint('Storing device: ${device.toJson()}');
  }

  Future<DeviceModel> _getDevice(String deviceId) async {
    // Mock implementation - retrieve device from database
    debugPrint('Retrieving device: $deviceId');
    throw UnimplementedError();
  }

  Future<void> _invalidateDeviceSessions(String deviceId) async {
    debugPrint('Invalidating sessions for device: $deviceId');
  }

  Future<void> _sendNewDeviceNotification(DeviceModel device) async {
    debugPrint('Sending new device notification for: ${device.deviceName}');
  }

  Future<void> _sendDeviceLogoutNotification(
    String deviceId,
    String userId,
  ) async {
    debugPrint('Sending device logout notification for: $deviceId');
  }

  Future<void> _flagSuspiciousDevice(String deviceId, String userId) async {
    debugPrint('Flagging suspicious device: $deviceId');
  }

  Future<void> _sendSecurityAlert(
    String userId,
    String deviceId,
    String ipAddress,
  ) async {
    debugPrint('Sending security alert for device: $deviceId, IP: $ipAddress');
  }

  Future<List<dynamic>> _getRecentDeviceActivities(
    String deviceId,
    Duration duration,
  ) async {
    // Mock implementation - get recent activities
    debugPrint('Getting recent activities for device: $deviceId');
    return [];
  }

  Future<bool> _isSuspiciousIpAddress(String ipAddress) async {
    // Mock implementation - check IP against known malicious databases
    return false;
  }
}
