import 'package:equatable/equatable.dart';

class DeviceModel extends Equatable {
  final String id;
  final String userId;
  final String deviceName;
  final String deviceType;
  final String platform;
  final String? manufacturer;
  final String? model;
  final String osVersion;
  final String? appVersion;
  final String deviceId;
  final String? installationId;
  final String ipAddress;
  final String? location;
  final bool isTrusted;
  final int trustScore;
  final bool isActive;
  final DateTime lastActivity;
  final DateTime firstLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeviceModel({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.deviceType,
    required this.platform,
    this.manufacturer,
    this.model,
    required this.osVersion,
    this.appVersion,
    required this.deviceId,
    this.installationId,
    required this.ipAddress,
    this.location,
    this.isTrusted = false,
    this.trustScore = 50,
    this.isActive = true,
    required this.lastActivity,
    required this.firstLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      deviceName: json['device_name'] as String,
      deviceType: json['device_type'] as String,
      platform: json['platform'] as String,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      osVersion: json['os_version'] as String,
      appVersion: json['app_version'] as String?,
      deviceId: json['device_id'] as String,
      installationId: json['installation_id'] as String?,
      ipAddress: json['ip_address'] as String,
      location: json['location'] as String?,
      isTrusted: json['is_trusted'] as bool,
      trustScore: json['trust_score'] as int,
      isActive: json['is_active'] as bool,
      lastActivity: DateTime.parse(json['last_activity'] as String),
      firstLogin: DateTime.parse(json['first_login'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_name': deviceName,
      'device_type': deviceType,
      'platform': platform,
      'manufacturer': manufacturer,
      'model': model,
      'os_version': osVersion,
      'app_version': appVersion,
      'device_id': deviceId,
      'installation_id': installationId,
      'ip_address': ipAddress,
      'location': location,
      'is_trusted': isTrusted,
      'trust_score': trustScore,
      'is_active': isActive,
      'last_activity': lastActivity.toIso8601String(),
      'first_login': firstLogin.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DeviceModel copyWith({
    String? id,
    String? userId,
    String? deviceName,
    String? deviceType,
    String? platform,
    String? manufacturer,
    String? model,
    String? osVersion,
    String? appVersion,
    String? deviceId,
    String? installationId,
    String? ipAddress,
    String? location,
    bool? isTrusted,
    int? trustScore,
    bool? isActive,
    DateTime? lastActivity,
    DateTime? firstLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      platform: platform ?? this.platform,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      deviceId: deviceId ?? this.deviceId,
      installationId: installationId ?? this.installationId,
      ipAddress: ipAddress ?? this.ipAddress,
      location: location ?? this.location,
      isTrusted: isTrusted ?? this.isTrusted,
      trustScore: trustScore ?? this.trustScore,
      isActive: isActive ?? this.isActive,
      lastActivity: lastActivity ?? this.lastActivity,
      firstLogin: firstLogin ?? this.firstLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCurrentDevice => isActive;
  bool get isExpired => DateTime.now().difference(lastActivity).inDays > 30;
  String get trustLevel => _getTrustLevel(trustScore);
  String get activityStatus => _getActivityStatus();

  String _getTrustLevel(int score) {
    if (score >= 80) return 'High';
    if (score >= 60) return 'Medium';
    if (score >= 40) return 'Low';
    return 'Very Low';
  }

  String _getActivityStatus() {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inMinutes < 5) return 'Online';
    if (difference.inHours < 1) return 'Recently Active';
    if (difference.inDays < 1) return 'Active Today';
    if (difference.inDays < 7) return 'Active This Week';
    return 'Inactive';
  }

  @override
  List<Object> get props => [
    id,
    userId,
    deviceName,
    deviceType,
    platform,
    manufacturer ?? '',
    model ?? '',
    osVersion,
    appVersion ?? '',
    deviceId,
    installationId ?? '',
    ipAddress,
    location ?? '',
    isTrusted,
    trustScore,
    isActive,
    lastActivity,
    firstLogin,
    createdAt,
    updatedAt,
  ];
}

class DeviceSession extends Equatable {
  final String id;
  final String deviceId;
  final String userId;
  final String sessionToken;
  final String ipAddress;
  final String? userAgent;
  final DateTime loginTime;
  final DateTime? logoutTime;
  final bool isActive;
  final DateTime createdAt;

  const DeviceSession({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.sessionToken,
    required this.ipAddress,
    this.userAgent,
    required this.loginTime,
    this.logoutTime,
    required this.isActive,
    required this.createdAt,
  });

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      userId: json['user_id'] as String,
      sessionToken: json['session_token'] as String,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String?,
      loginTime: DateTime.parse(json['login_time'] as String),
      logoutTime: json['logout_time'] != null
          ? DateTime.parse(json['logout_time'] as String)
          : null,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'user_id': userId,
      'session_token': sessionToken,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'login_time': loginTime.toIso8601String(),
      'logout_time': logoutTime?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [
    id,
    deviceId,
    userId,
    sessionToken,
    ipAddress,
    userAgent ?? '',
    loginTime,
    logoutTime ?? '',
    isActive,
    createdAt,
  ];
}
