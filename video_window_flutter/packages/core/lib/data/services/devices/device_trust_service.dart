import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../repositories/devices/device_repository.dart';

/// Service for device trust management on Flutter client
/// Implements Epic 2 Story 2-4: Device Trust & Risk Monitoring
class DeviceTrustService {
  final DeviceRepository _repository;
  final FlutterSecureStorage _secureStorage;
  Timer? _backgroundRefreshTimer;

  static const String _keyDeviceId = 'video_window_device_id';

  DeviceTrustService(
    this._repository, {
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initialize device trust on app launch
  /// AC1: Device registration occurs on app launch, capturing device ID, platform, attestation result, and telemetry
  Future<void> initialize({required int userId}) async {
    try {
      // Get or generate device ID
      String? deviceId = await _secureStorage.read(key: _keyDeviceId);
      if (deviceId == null) {
        deviceId = _generateDeviceId();
        await _secureStorage.write(key: _keyDeviceId, value: deviceId);
      }

      // Collect device telemetry
      final telemetry = await _collectTelemetry();

      // Register device
      await _repository.registerDevice(
        userId: userId,
        deviceId: deviceId,
        deviceType: _getDeviceType(),
        platform: _getPlatform(),
        telemetry: telemetry,
      );

      // Start background refresh (AC2: Background refresh updates last seen timestamp)
      _startBackgroundRefresh(userId, deviceId);
    } catch (e) {
      debugPrint('Failed to initialize device trust: $e');
      // Don't throw - device trust failure shouldn't block app launch
    }
  }

  /// Collect device telemetry
  Map<String, dynamic> _collectTelemetry() {
    final telemetry = <String, dynamic>{
      'platform': _getPlatform(),
      'deviceType': _getDeviceType(),
      'osVersion': _getOsVersion(),
      'appVersion': _getAppVersion(),
      'isJailbroken': false, // TODO: Integrate with jailbreak detection library
      'isRooted': false, // TODO: Integrate with root detection library
      'isEmulator': false, // TODO: Detect emulator
      'attestationResult':
          'pending', // TODO: Integrate with Apple DeviceCheck / Google Play Integrity
      'timestamp': DateTime.now().toIso8601String(),
    };

    return telemetry;
  }

  /// Generate unique device ID
  String _generateDeviceId() {
    // Generate a UUID-like identifier
    // In production, this should use a more secure method
    return 'device_${DateTime.now().millisecondsSinceEpoch}_${_getPlatform()}';
  }

  /// Get platform name
  String _getPlatform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Get device type
  String _getDeviceType() {
    if (Platform.isIOS) return 'iphone';
    if (Platform.isAndroid) return 'android_phone';
    if (Platform.isMacOS) return 'mac';
    if (Platform.isWindows) return 'windows_pc';
    if (Platform.isLinux) return 'linux_pc';
    return 'unknown';
  }

  /// Get OS version
  String _getOsVersion() {
    // TODO: Use device_info_plus package to get actual OS version
    return Platform.operatingSystemVersion;
  }

  /// Get app version
  String _getAppVersion() {
    // TODO: Use package_info_plus to get actual app version
    return '1.0.0';
  }

  /// Start background refresh to update last seen timestamp
  /// AC2: Background refresh updates last seen timestamp without exhaustive polling
  void _startBackgroundRefresh(int userId, String deviceId) {
    // Refresh every 5 minutes when app is active
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) async {
        try {
          final telemetry = await _collectTelemetry();
          await _repository.registerDevice(
            userId: userId,
            deviceId: deviceId,
            deviceType: _getDeviceType(),
            platform: _getPlatform(),
            telemetry: telemetry,
          );
        } catch (e) {
          debugPrint('Background device refresh failed: $e');
        }
      },
    );
  }

  /// Get user devices
  /// AC3: Device management screen lists registered devices
  Future<List<dynamic>> getUserDevices(int userId) async {
    return await _repository.getDevices(userId);
  }

  /// Revoke device trust
  /// AC3: Revocation lowers capability state appropriately
  Future<void> revokeDevice({
    required int userId,
    required int deviceId,
    String? reason,
  }) async {
    await _repository.revokeDevice(
      userId: userId,
      deviceId: deviceId,
      reason: reason,
    );
  }

  /// Dispose resources
  void dispose() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = null;
  }
}
