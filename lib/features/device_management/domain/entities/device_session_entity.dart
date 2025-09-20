import 'package:meta/meta.dart';

class DeviceSessionEntity {
  final String id;
  final String deviceId;
  final String userId;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final DateTime lastActivity;
  final String ipAddress;
  final String? userAgent;
  final bool isActive;
  final DeviceSessionMetadataEntity metadata;

  DeviceSessionEntity({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.startedAt,
    this.expiresAt,
    required this.lastActivity,
    required this.ipAddress,
    this.userAgent,
    required this.isActive,
    required this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceSessionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          deviceId == other.deviceId &&
          userId == other.userId &&
          startedAt == other.startedAt &&
          expiresAt == other.expiresAt &&
          lastActivity == other.lastActivity &&
          ipAddress == other.ipAddress &&
          userAgent == other.userAgent &&
          isActive == other.isActive &&
          metadata == other.metadata;

  @override
  int get hashCode =>
      id.hashCode ^
      deviceId.hashCode ^
      userId.hashCode ^
      startedAt.hashCode ^
      expiresAt.hashCode ^
      lastActivity.hashCode ^
      ipAddress.hashCode ^
      userAgent.hashCode ^
      isActive.hashCode ^
      metadata.hashCode;

  DeviceSessionEntity copyWith({
    String? id,
    String? deviceId,
    String? userId,
    DateTime? startedAt,
    DateTime? expiresAt,
    DateTime? lastActivity,
    String? ipAddress,
    String? userAgent,
    bool? isActive,
    DeviceSessionMetadataEntity? metadata,
  }) {
    return DeviceSessionEntity(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastActivity: lastActivity ?? this.lastActivity,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isInactive {
    return DateTime.now().difference(lastActivity).inDays >= 30;
  }

  bool get isValid => !isExpired && !isInactive;
}

class DeviceSessionMetadataEntity {
  final String deviceId;
  final String appVersion;
  final String osVersion;
  final String deviceModel;
  final String? location;
  final DateTime createdAt;
  final Map<String, dynamic> additionalData;

  DeviceSessionMetadataEntity({
    required this.deviceId,
    required this.appVersion,
    required this.osVersion,
    required this.deviceModel,
    this.location,
    required this.createdAt,
    required this.additionalData,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceSessionMetadataEntity &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          appVersion == other.appVersion &&
          osVersion == other.osVersion &&
          deviceModel == other.deviceModel &&
          location == other.location &&
          createdAt == other.createdAt &&
          additionalData == other.additionalData;

  @override
  int get hashCode =>
      deviceId.hashCode ^
      appVersion.hashCode ^
      osVersion.hashCode ^
      deviceModel.hashCode ^
      location.hashCode ^
      createdAt.hashCode ^
      additionalData.hashCode;
}