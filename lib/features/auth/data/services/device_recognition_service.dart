import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/device_model.dart';
import '../../domain/models/session_model.dart';
import '../../../core/errors/exceptions.dart';

class DeviceRecognitionService {
  final DeviceInfoPlugin _deviceInfoPlugin;
  final FlutterSecureStorage _secureStorage;
  final PackageInfo _packageInfo;

  DeviceRecognitionService(
    this._deviceInfoPlugin,
    this._secureStorage,
    this._packageInfo,
  );

  static const String _deviceIdKey = 'device_id';
  static const String _deviceFingerprintKey = 'device_fingerprint';
  static const String _deviceTrustKey = 'device_trust_';

  Future<DeviceModel> getCurrentDeviceInfo({ui.Size? screenSize}) async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      final deviceInfo = await _collectDeviceInfo(screenSize);
      final fingerprint = await _generateDeviceFingerprint();
      final ipAddress = await _getCurrentIpAddress();

      return DeviceModel(
        id: const Uuid().v4(),
        userId: '',
        deviceName: deviceInfo['device_name'] ?? 'Unknown Device',
        deviceType: deviceInfo['device_type'] ?? 'Unknown',
        platform: deviceInfo['platform'] ?? 'Unknown',
        manufacturer: deviceInfo['manufacturer'],
        model: deviceInfo['model'],
        osVersion: deviceInfo['os_version'] ?? 'Unknown',
        appVersion: _packageInfo.version,
        deviceId: deviceId,
        installationId: await _getInstallationId(),
        ipAddress: ipAddress,
        isTrusted: await _isDeviceTrusted(deviceId),
        trustScore: await _calculateTrustScore(deviceId),
        isActive: true,
        lastActivity: DateTime.now(),
        firstLogin: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw DeviceException('Failed to get device info: ${e.toString()}');
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    String? deviceId = await _secureStorage.read(key: _deviceIdKey);

    if (deviceId == null) {
      deviceId = _generateDeviceId();
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    }

    return deviceId;
  }

  Future<String> _getInstallationId() async {
    final installationKey = 'installation_id';
    String? installationId = await _secureStorage.read(key: installationKey);

    if (installationId == null) {
      installationId = const Uuid().v4();
      await _secureStorage.write(key: installationKey, value: installationId);
    }

    return installationId;
  }

  Future<String> _generateDeviceFingerprint() async {
    final deviceInfo = await _collectDeviceInfo(null);
    final fingerprintData = {
      'device_id': deviceInfo['device_id'],
      'platform': deviceInfo['platform'],
      'os_version': deviceInfo['os_version'],
      'manufacturer': deviceInfo['manufacturer'],
      'model': deviceInfo['model'],
      'screen_resolution': deviceInfo['screen_resolution'],
      'app_version': _packageInfo.version,
      'build_number': _packageInfo.buildNumber,
    };

    final fingerprintString = json.encode(fingerprintData);
    final bytes = utf8.encode(fingerprintString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>> _collectDeviceInfo(ui.Size? screenSize) async {
    final deviceInfo = <String, dynamic>{};

    try {
      final deviceData = await _deviceInfoPlugin.deviceInfo;

      if (deviceData is AndroidDeviceInfo) {
        final androidInfo = deviceData;
        deviceInfo.addAll({
          'device_id': androidInfo.androidId,
          'platform': 'Android',
          'os_version': androidInfo.version.release,
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'device_type': _getAndroidDeviceType(androidInfo),
          'device_name': '${androidInfo.manufacturer} ${androidInfo.model}',
          'screen_resolution': screenSize != null
              ? '${screenSize.width}x${screenSize.height}'
              : 'Unknown',
        });
      } else if (deviceData is IosDeviceInfo) {
        final iosInfo = deviceData;
        deviceInfo.addAll({
          'device_id': iosInfo.identifierForVendor,
          'platform': 'iOS',
          'os_version': iosInfo.systemVersion,
          'manufacturer': 'Apple',
          'model': iosInfo.model,
          'device_type': _getIOSDeviceType(iosInfo),
          'device_name': iosInfo.name,
          'screen_resolution': screenSize != null
              ? '${screenSize.width}x${screenSize.height}'
              : 'Unknown',
        });
      } else {
        deviceInfo.addAll({
          'device_id': 'unknown',
          'platform': 'Unknown',
          'os_version': 'Unknown',
          'manufacturer': 'Unknown',
          'model': 'Unknown',
          'device_type': 'Unknown',
          'device_name': 'Unknown Device',
          'screen_resolution': 'Unknown',
        });
      }
    } catch (e) {
      deviceInfo.addAll({
        'device_id': 'error',
        'platform': 'Unknown',
        'os_version': 'Unknown',
        'manufacturer': 'Unknown',
        'model': 'Unknown',
        'device_type': 'Unknown',
        'device_name': 'Unknown Device',
        'screen_resolution': 'Unknown',
      });
    }

    return deviceInfo;
  }

  String _getAndroidDeviceType(AndroidDeviceInfo info) {
    final model = info.model.toLowerCase();
    if (model.contains('tablet') || model.contains('pad')) return 'Tablet';
    if (model.contains('tv')) return 'TV';
    return 'Smartphone';
  }

  String _getIOSDeviceType(IosDeviceInfo info) {
    final model = info.model.toLowerCase();
    if (model.contains('ipad')) return 'Tablet';
    if (model.contains('iphone')) return 'Smartphone';
    if (model.contains('ipod')) return 'iPod';
    if (model.contains('tv')) return 'TV';
    return 'Unknown';
  }

  Future<String> _getCurrentIpAddress() async {
    return '192.168.1.1';
  }

  Future<bool> _isDeviceTrusted(String deviceId) async {
    final trustData = await _secureStorage.read(
      key: _deviceTrustKey + deviceId,
    );
    if (trustData == null) return false;

    try {
      final trustInfo = json.decode(trustData);
      return trustInfo['is_trusted'] as bool;
    } catch (e) {
      return false;
    }
  }

  Future<int> _calculateTrustScore(String deviceId) async {
    int score = 50;

    final trustData = await _secureStorage.read(
      key: _deviceTrustKey + deviceId,
    );
    if (trustData != null) {
      try {
        final trustInfo = json.decode(trustData);
        score = trustInfo['trust_score'] as int;
      } catch (e) {
        return 50;
      }
    }

    return score;
  }

  Future<void> markDeviceAsTrusted(
    String deviceId, {
    int trustScore = 80,
  }) async {
    final trustData = {
      'is_trusted': true,
      'trust_score': trustScore,
      'trusted_at': DateTime.now().toIso8601String(),
      'last_seen': DateTime.now().toIso8601String(),
    };

    await _secureStorage.write(
      key: _deviceTrustKey + deviceId,
      value: json.encode(trustData),
    );
  }

  Future<void> updateDeviceTrustScore(String deviceId, int newScore) async {
    final trustData = await _secureStorage.read(
      key: _deviceTrustKey + deviceId,
    );
    Map<String, dynamic> trustInfo;

    if (trustData != null) {
      trustInfo = json.decode(trustData);
    } else {
      trustInfo = {'is_trusted': false, 'trusted_at': null};
    }

    trustInfo['trust_score'] = newScore;
    trustInfo['last_seen'] = DateTime.now().toIso8601String();

    if (newScore >= 80) {
      trustInfo['is_trusted'] = true;
      trustInfo['trusted_at'] = DateTime.now().toIso8601String();
    }

    await _secureStorage.write(
      key: _deviceTrustKey + deviceId,
      value: json.encode(trustInfo),
    );
  }

  Future<bool> verifyDeviceFingerprint(String expectedFingerprint) async {
    try {
      final currentFingerprint = await _generateDeviceFingerprint();
      return currentFingerprint == expectedFingerprint;
    } catch (e) {
      return false;
    }
  }

  Future<void> recordDeviceActivity(
    String deviceId,
    bool successfulAuth,
  ) async {
    final activityKey = 'device_activity_$deviceId';
    String? activityData = await _secureStorage.read(key: activityKey);

    List<Map<String, dynamic>> activities;
    if (activityData != null) {
      activities = List<Map<String, dynamic>>.from(json.decode(activityData));
    } else {
      activities = [];
    }

    activities.add({
      'timestamp': DateTime.now().toIso8601String(),
      'successful': successfulAuth,
    });

    if (activities.length > 100) {
      activities.removeAt(0);
    }

    await _secureStorage.write(
      key: activityKey,
      value: json.encode(activities),
    );

    await _updateTrustScoreBasedOnActivity(deviceId, activities);
  }

  Future<void> _updateTrustScoreBasedOnActivity(
    String deviceId,
    List<Map<String, dynamic>> activities,
  ) async {
    if (activities.isEmpty) return;

    final recentActivities = activities.take(10).toList();
    final successRate =
        recentActivities.where((a) => a['successful'] as bool).length /
        recentActivities.length;

    int currentScore = await _calculateTrustScore(deviceId);
    int newScore = currentScore;

    if (successRate >= 0.8) {
      newScore = min(100, currentScore + 5);
    } else if (successRate < 0.5) {
      newScore = max(0, currentScore - 10);
    }

    if (newScore != currentScore) {
      await updateDeviceTrustScore(deviceId, newScore);
    }
  }

  Future<List<Map<String, dynamic>>> getDeviceActivityHistory(
    String deviceId,
  ) async {
    final activityKey = 'device_activity_$deviceId';
    final activityData = await _secureStorage.read(key: activityKey);

    if (activityData != null) {
      return List<Map<String, dynamic>>.from(json.decode(activityData));
    }

    return [];
  }

  Future<void> clearDeviceData(String deviceId) async {
    await _secureStorage.delete(key: _deviceTrustKey + deviceId);
    await _secureStorage.delete(key: 'device_activity_$deviceId');
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  Future<List<String>> getTrustedDevices() async {
    final allKeys = await _secureStorage.readAll();
    final trustedDevices = <String>[];

    for (final key in allKeys.keys) {
      if (key.startsWith(_deviceTrustKey)) {
        try {
          final trustData = allKeys[key];
          if (trustData != null) {
            final trustInfo = json.decode(trustData);
            if (trustInfo['is_trusted'] as bool) {
              final deviceId = key.substring(_deviceTrustKey.length);
              trustedDevices.add(deviceId);
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return trustedDevices;
  }

  Future<void> revokeDeviceTrust(String deviceId) async {
    final trustData = {
      'is_trusted': false,
      'trust_score': 0,
      'trusted_at': null,
      'last_seen': DateTime.now().toIso8601String(),
    };

    await _secureStorage.write(
      key: _deviceTrustKey + deviceId,
      value: json.encode(trustData),
    );
  }

  Future<bool> isDeviceSuspicious(String deviceId) async {
    final activities = await getDeviceActivityHistory(deviceId);
    if (activities.length < 5) return false;

    final recentActivities = activities.take(10).toList();
    final failureRate =
        recentActivities.where((a) => !(a['successful'] as bool)).length /
        recentActivities.length;

    return failureRate > 0.7;
  }
}
