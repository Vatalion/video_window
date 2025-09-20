class DeviceSession {
  final String id;
  final String deviceId;
  final String userId;
  final String accessToken;
  final String refreshToken;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final DateTime lastActivity;
  final String ipAddress;
  final String? userAgent;
  final bool isActive;
  final DeviceSessionMetadata metadata;

  DeviceSession({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.startedAt,
    this.expiresAt,
    required this.lastActivity,
    required this.ipAddress,
    this.userAgent,
    required this.isActive,
    required this.metadata,
  });

  DeviceSession copyWith({
    String? id,
    String? deviceId,
    String? userId,
    String? accessToken,
    String? refreshToken,
    DateTime? startedAt,
    DateTime? expiresAt,
    DateTime? lastActivity,
    String? ipAddress,
    String? userAgent,
    bool? isActive,
    DeviceSessionMetadata? metadata,
  }) {
    return DeviceSession(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastActivity: lastActivity ?? this.lastActivity,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'userId': userId,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'startedAt': startedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'isActive': isActive,
      'metadata': metadata.toJson(),
    };
  }

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      id: json['id'],
      deviceId: json['deviceId'],
      userId: json['userId'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      startedAt: DateTime.parse(json['startedAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      lastActivity: DateTime.parse(json['lastActivity']),
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      isActive: json['isActive'],
      metadata: DeviceSessionMetadata.fromJson(json['metadata']),
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isInactive {
    return DateTime.now().difference(lastActivity).inDays >= 30;
  }
}

class DeviceSessionMetadata {
  final String deviceId;
  final String appVersion;
  final String osVersion;
  final String deviceModel;
  final String? location;
  final DateTime createdAt;
  final Map<String, dynamic> additionalData;

  DeviceSessionMetadata({
    required this.deviceId,
    required this.appVersion,
    required this.osVersion,
    required this.deviceModel,
    this.location,
    required this.createdAt,
    required this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'appVersion': appVersion,
      'osVersion': osVersion,
      'deviceModel': deviceModel,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  factory DeviceSessionMetadata.fromJson(Map<String, dynamic> json) {
    return DeviceSessionMetadata(
      deviceId: json['deviceId'],
      appVersion: json['appVersion'],
      osVersion: json['osVersion'],
      deviceModel: json['deviceModel'],
      location: json['location'],
      createdAt: DateTime.parse(json['createdAt']),
      additionalData: json['additionalData'],
    );
  }
}