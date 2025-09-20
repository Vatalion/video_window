import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart' as pkg;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DeviceFingerprintingService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final pkg.PackageInfo _fallbackInfo = pkg.PackageInfo(
    appName: 'Video Window',
    packageName: 'com.example.video_window',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
    installerStore: null,
  );
  final Uuid _uuid = const Uuid();

  Future<DeviceFingerprint> generateFingerprint() async {
    String hardwareId = await _getHardwareId();
    String browserFingerprint = await _generateBrowserFingerprint();
    String installationId = await _getInstallationId();
    String ipAddress = await _getIpAddress();
    String deviceType = await _getDeviceType();

    return DeviceFingerprint(
      hardwareId: hardwareId,
      browserFingerprint: browserFingerprint,
      installationId: installationId,
      ipAddress: ipAddress,
      deviceType: deviceType,
      generatedAt: DateTime.now(),
    );
  }

  Future<String> _getHardwareId() async {
    try {
      final deviceInfo = await _deviceInfo.deviceInfo;

      if (deviceInfo is AndroidDeviceInfo) {
        // androidId moved under AndroidId on newer versions; use asString where available
        try {
          final id = deviceInfo.id as String?;
          return id ?? _uuid.v4();
        } catch (_) {
          return _uuid.v4();
        }
      } else if (deviceInfo is IosDeviceInfo) {
        return deviceInfo.identifierForVendor ?? _uuid.v4();
      } else if (deviceInfo is WebBrowserInfo) {
        return deviceInfo.userAgent ?? _uuid.v4();
      } else {
        return _uuid.v4();
      }
    } catch (e) {
      return _uuid.v4();
    }
  }

  Future<String> _generateBrowserFingerprint() async {
    try {
      final deviceInfo = await _deviceInfo.deviceInfo;
  final packageInfo = await pkg.PackageInfo.fromPlatform().catchError((_) => _fallbackInfo);

      String fingerprint = '';

      if (deviceInfo is AndroidDeviceInfo) {
        fingerprint = '${deviceInfo.brand}:${deviceInfo.model}:${deviceInfo.version.release}:${deviceInfo.version.sdkInt}';
      } else if (deviceInfo is IosDeviceInfo) {
        fingerprint = '${deviceInfo.systemName}:${deviceInfo.systemVersion}:${deviceInfo.model}:${deviceInfo.localizedModel}';
      } else if (deviceInfo is WebBrowserInfo) {
        fingerprint = deviceInfo.userAgent ?? 'unknown';
      } else {
        fingerprint = 'unknown_device';
      }

      fingerprint += ':${packageInfo.packageName}:${packageInfo.version}:${packageInfo.buildNumber}';

      return _generateHash(fingerprint);
    } catch (e) {
      return _generateHash('default_fingerprint');
    }
  }

  Future<String> _getInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    String? installationId = prefs.getString('installation_id');

    if (installationId == null) {
      installationId = _uuid.v4();
      await prefs.setString('installation_id', installationId);
    }

    return installationId;
  }

  Future<String> _getIpAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      return response.body;
    } catch (e) {
      return '127.0.0.1';
    }
  }

  Future<String> _getDeviceType() async {
    try {
      final deviceInfo = await _deviceInfo.deviceInfo;

      if (deviceInfo is AndroidDeviceInfo) {
        return 'android';
      } else if (deviceInfo is IosDeviceInfo) {
        return 'ios';
      } else if (deviceInfo is WebBrowserInfo) {
        return 'web';
      } else {
        return 'unknown';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  String _generateHash(String input) {
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> isSuspiciousDevice(DeviceFingerprint fingerprint) async {
    try {
      final deviceInfo = await _deviceInfo.deviceInfo;

      if (deviceInfo is AndroidDeviceInfo) {
        return deviceInfo.isPhysicalDevice == false;
      } else if (deviceInfo is IosDeviceInfo) {
        return deviceInfo.isPhysicalDevice == false;
      }

      return false;
    } catch (e) {
      return true;
    }
  }

  Future<DeviceMetadata> getDeviceMetadata() async {
    try {
      final deviceInfo = await _deviceInfo.deviceInfo;
  final packageInfo = await pkg.PackageInfo.fromPlatform().catchError((_) => _fallbackInfo);

      String deviceModel = 'Unknown';
      String osVersion = 'Unknown';

      if (deviceInfo is AndroidDeviceInfo) {
        deviceModel = deviceInfo.model;
        osVersion = deviceInfo.version.release;
      } else if (deviceInfo is IosDeviceInfo) {
        deviceModel = deviceInfo.model;
        osVersion = deviceInfo.systemVersion;
      } else if (deviceInfo is WebBrowserInfo) {
        deviceModel = deviceInfo.userAgent ?? 'Web Browser';
        osVersion = 'Web';
      }

      return DeviceMetadata(
        deviceModel: deviceModel,
        osVersion: osVersion,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        packageName: packageInfo.packageName,
      );
    } catch (e) {
      return DeviceMetadata(
        deviceModel: 'Unknown',
        osVersion: 'Unknown',
        appVersion: '1.0.0',
        buildNumber: '1',
        packageName: 'unknown',
      );
    }
  }
}

class DeviceFingerprint {
  final String hardwareId;
  final String browserFingerprint;
  final String installationId;
  final String ipAddress;
  final String deviceType;
  final DateTime generatedAt;

  DeviceFingerprint({
    required this.hardwareId,
    required this.browserFingerprint,
    required this.installationId,
    required this.ipAddress,
    required this.deviceType,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'hardwareId': hardwareId,
      'browserFingerprint': browserFingerprint,
      'installationId': installationId,
      'ipAddress': ipAddress,
      'deviceType': deviceType,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceFingerprint &&
          runtimeType == other.runtimeType &&
          hardwareId == other.hardwareId &&
          browserFingerprint == other.browserFingerprint &&
          installationId == other.installationId &&
          ipAddress == other.ipAddress &&
          deviceType == other.deviceType &&
          generatedAt == other.generatedAt;

  @override
  int get hashCode =>
      hardwareId.hashCode ^
      browserFingerprint.hashCode ^
      installationId.hashCode ^
      ipAddress.hashCode ^
      deviceType.hashCode ^
      generatedAt.hashCode;
}

class DeviceMetadata {
  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final String buildNumber;
  final String packageName;

  DeviceMetadata({
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
    required this.buildNumber,
    required this.packageName,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'packageName': packageName,
    };
  }
}