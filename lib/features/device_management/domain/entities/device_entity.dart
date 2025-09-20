import 'package:meta/meta.dart';

class DeviceEntity {
  final String id;
  final String name;
  final String type;
  final String hardwareId;
  final String ipAddress;
  final String browserFingerprint;
  final String installationId;
  final DeviceLocationEntity? location;
  final int trustScore;
  final DateTime lastActivity;
  final DateTime registeredAt;
  final String status;
  final bool isCurrentDevice;
  final DeviceSessionEntity? currentSession;

  DeviceEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.hardwareId,
    required this.ipAddress,
    required this.browserFingerprint,
    required this.installationId,
    this.location,
    required this.trustScore,
    required this.lastActivity,
    required this.registeredAt,
    required this.status,
    required this.isCurrentDevice,
    this.currentSession,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          hardwareId == other.hardwareId &&
          ipAddress == other.ipAddress &&
          browserFingerprint == other.browserFingerprint &&
          installationId == other.installationId &&
          location == other.location &&
          trustScore == other.trustScore &&
          lastActivity == other.lastActivity &&
          registeredAt == other.registeredAt &&
          status == other.status &&
          isCurrentDevice == other.isCurrentDevice &&
          currentSession == other.currentSession;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      hardwareId.hashCode ^
      ipAddress.hashCode ^
      browserFingerprint.hashCode ^
      installationId.hashCode ^
      location.hashCode ^
      trustScore.hashCode ^
      lastActivity.hashCode ^
      registeredAt.hashCode ^
      status.hashCode ^
      isCurrentDevice.hashCode ^
      currentSession.hashCode;

  DeviceEntity copyWith({
    String? id,
    String? name,
    String? type,
    String? hardwareId,
    String? ipAddress,
    String? browserFingerprint,
    String? installationId,
    DeviceLocationEntity? location,
    int? trustScore,
    DateTime? lastActivity,
    DateTime? registeredAt,
    String? status,
    bool? isCurrentDevice,
    DeviceSessionEntity? currentSession,
  }) {
    return DeviceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      hardwareId: hardwareId ?? this.hardwareId,
      ipAddress: ipAddress ?? this.ipAddress,
      browserFingerprint: browserFingerprint ?? this.browserFingerprint,
      installationId: installationId ?? this.installationId,
      location: location ?? this.location,
      trustScore: trustScore ?? this.trustScore,
      lastActivity: lastActivity ?? this.lastActivity,
      registeredAt: registeredAt ?? this.registeredAt,
      status: status ?? this.status,
      isCurrentDevice: isCurrentDevice ?? this.isCurrentDevice,
      currentSession: currentSession ?? this.currentSession,
    );
  }

  TrustLevel get trustLevel {
    if (trustScore >= 80) return TrustLevel.high;
    if (trustScore >= 50) return TrustLevel.medium;
    return TrustLevel.low;
  }

  bool get isTrusted => trustLevel != TrustLevel.low;
  bool get isSuspicious => trustScore < 30;
  bool get needsVerification => trustLevel == TrustLevel.low;
}

enum TrustLevel { high, medium, low }

enum DeviceType { mobile, desktop, tablet, web, unknown }

class DeviceLocationEntity {
  final double latitude;
  final double longitude;
  final String country;
  final String? region;
  final String? city;
  final DateTime timestamp;

  DeviceLocationEntity({
    required this.latitude,
    required this.longitude,
    required this.country,
    this.region,
    this.city,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceLocationEntity &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          country == other.country &&
          region == other.region &&
          city == other.city &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      country.hashCode ^
      region.hashCode ^
      city.hashCode ^
      timestamp.hashCode;
}