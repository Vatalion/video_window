import '../entities/device_entity.dart';
import '../entities/device_session_entity.dart';

class TrustCalculationService {
  static const int _baseTrustScore = 50;
  static const int _maxTrustScore = 100;
  static const int _minTrustScore = 0;
  static const Duration _trustedDeviceAge = Duration(days: 30);
  static const Duration _suspiciousInactivity = Duration(days: 30);

  int calculateTrustScore({
    required DeviceEntity device,
    required List<DeviceSessionEntity> sessions,
    required Map<String, dynamic> behavioralData,
  }) {
    int score = _baseTrustScore;

    score += _calculateAgeScore(device.registeredAt);
    score += _calculateUsageScore(sessions);
    score += _calculateLocationScore(device, behavioralData);
    score += _calculateBehaviorScore(behavioralData);
    score += _calculateSecurityScore(device, behavioralData);
    score += _calculateConsistencyScore(device, behavioralData);

    return _clampScore(score);
  }

  int _calculateAgeScore(DateTime registeredAt) {
    final age = DateTime.now().difference(registeredAt);

    if (age.inDays >= 365) return 15;
    if (age.inDays >= 180) return 10;
    if (age.inDays >= 90) return 8;
    if (age.inDays >= 30) return 5;
    if (age.inDays >= 7) return 3;

    return 0;
  }

  int _calculateUsageScore(List<DeviceSessionEntity> sessions) {
    if (sessions.isEmpty) return -10;

    final totalSessions = sessions.length;
    final recentSessions = sessions.where((session) =>
      DateTime.now().difference(session.startedAt).inDays <= 30
    ).length;

    if (totalSessions >= 100) return 20;
    if (totalSessions >= 50) return 15;
    if (totalSessions >= 20) return 10;
    if (totalSessions >= 10) return 8;
    if (totalSessions >= 5) return 5;

    return totalSessions > 0 ? 2 : 0;
  }

  int _calculateLocationScore(DeviceEntity device, Map<String, dynamic> behavioralData) {
    if (device.location == null) return 0;

    final locations = behavioralData['locations'] as List<dynamic>? ?? [];
    if (locations.isEmpty) return 0;

    final consistentLocations = locations.where((loc) =>
      _isLocationClose(device.location!, loc)
    ).length;

    final consistencyRatio = consistentLocations / locations.length;

    if (consistencyRatio >= 0.9) return 15;
    if (consistencyRatio >= 0.7) return 10;
    if (consistencyRatio >= 0.5) return 5;
    if (consistencyRatio >= 0.3) return 2;

    return 0;
  }

  int _calculateBehaviorScore(Map<String, dynamic> behavioralData) {
    int score = 0;

    final loginSuccessRate = behavioralData['loginSuccessRate'] as double? ?? 0.0;
    if (loginSuccessRate >= 0.95) score += 15;
    else if (loginSuccessRate >= 0.8) score += 10;
    else if (loginSuccessRate >= 0.6) score += 5;
    else if (loginSuccessRate < 0.5) score -= 10;

    final avgSessionDuration = behavioralData['avgSessionDuration'] as Duration? ?? Duration.zero;
    if (avgSessionDuration.inMinutes >= 30) score += 10;
    else if (avgSessionDuration.inMinutes >= 15) score += 5;

    final suspiciousActivities = behavioralData['suspiciousActivities'] as int? ?? 0;
    score -= suspiciousActivities * 5;

    return score;
  }

  int _calculateSecurityScore(DeviceEntity device, Map<String, dynamic> behavioralData) {
    int score = 0;

    if (device.trustScore >= 80) score += 10;
    else if (device.trustScore >= 50) score += 5;

    final hasBiometricAuth = behavioralData['hasBiometricAuth'] as bool? ?? false;
    if (hasBiometricAuth) score += 10;

    final twoFactorEnabled = behavioralData['twoFactorEnabled'] as bool? ?? false;
    if (twoFactorEnabled) score += 15;

    final securitySettingsEnabled = behavioralData['securitySettingsEnabled'] as bool? ?? false;
    if (securitySettingsEnabled) score += 5;

    final failedLoginAttempts = behavioralData['failedLoginAttempts'] as int? ?? 0;
    if (failedLoginAttempts > 5) score -= 15;
    else if (failedLoginAttempts > 2) score -= 5;

    return score;
  }

  int _calculateConsistencyScore(DeviceEntity device, Map<String, dynamic> behavioralData) {
    int score = 0;

    final ipAddresses = behavioralData['ipAddresses'] as List<dynamic>? ?? [];
    if (ipAddresses.length <= 2) score += 10;
    else if (ipAddresses.length <= 5) score += 5;
    else score -= 5;

    final userAgents = behavioralData['userAgents'] as List<dynamic>? ?? [];
    if (userAgents.length <= 2) score += 5;
    else if (userAgents.length <= 5) score += 2;
    else score -= 2;

    final locationChanges = behavioralData['locationChanges'] as int? ?? 0;
    if (locationChanges == 0) score += 10;
    else if (locationChanges <= 2) score += 5;
    else if (locationChanges > 5) score -= 10;

    return score;
  }

  bool _isLocationClose(dynamic location1, dynamic location2) {
    // Implementation would compare lat/lng with radius
    // For now, assume they're close if country is the same
    return location1['country'] == location2['country'];
  }

  int _clampScore(int score) {
    return score.clamp(_minTrustScore, _maxTrustScore);
  }

  TrustLevel getTrustLevel(int score) {
    if (score >= 80) return TrustLevel.high;
    if (score >= 50) return TrustLevel.medium;
    return TrustLevel.low;
  }

  bool shouldTriggerAdditionalAuth(int trustScore) {
    return trustScore < 50;
  }

  bool isSuspiciousDevice(DeviceEntity device, Map<String, dynamic> behavioralData) {
    if (device.trustScore < 30) return true;

    final recentFailedLogins = behavioralData['recentFailedLogins'] as int? ?? 0;
    if (recentFailedLogins > 5) return true;

    final rapidLoginAttempts = behavioralData['rapidLoginAttempts'] as int? ?? 0;
    if (rapidLoginAttempts > 3) return true;

    final unusualLocations = behavioralData['unusualLocations'] as int? ?? 0;
    if (unusualLocations > 0) return true;

    return false;
  }

  Map<String, dynamic> generateTrustFactors(int score) {
    return {
      'score': score,
      'level': getTrustLevel(score).toString(),
      'requiresAdditionalAuth': shouldTriggerAdditionalAuth(score),
      'isSuspicious': score < 30,
      'lastCalculated': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> collectBehavioralData({
    required String deviceId,
    required List<DeviceSessionEntity> sessions,
  }) async {
    // This would typically involve querying a database or analytics service
    // For now, we'll return mock data
    return {
      'loginSuccessRate': 0.95,
      'avgSessionDuration': const Duration(minutes: 45),
      'suspiciousActivities': 0,
      'hasBiometricAuth': true,
      'twoFactorEnabled': true,
      'securitySettingsEnabled': true,
      'failedLoginAttempts': 0,
      'recentFailedLogins': 0,
      'rapidLoginAttempts': 0,
      'unusualLocations': 0,
      'locations': [],
      'ipAddresses': [],
      'userAgents': [],
      'locationChanges': 0,
    };
  }
}