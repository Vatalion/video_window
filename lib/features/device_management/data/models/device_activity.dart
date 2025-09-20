class DeviceActivity {
  final String id;
  final String deviceId;
  final String userId;
  final ActivityType type;
  final String description;
  final DateTime occurredAt;
  final String ipAddress;
  final DeviceLocation? location;
  final Map<String, dynamic> metadata;
  final SecurityLevel securityLevel;

  DeviceActivity({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.type,
    required this.description,
    required this.occurredAt,
    required this.ipAddress,
    this.location,
    required this.metadata,
    required this.securityLevel,
  });

  DeviceActivity copyWith({
    String? id,
    String? deviceId,
    String? userId,
    ActivityType? type,
    String? description,
    DateTime? occurredAt,
    String? ipAddress,
    DeviceLocation? location,
    Map<String, dynamic>? metadata,
    SecurityLevel? securityLevel,
  }) {
    return DeviceActivity(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      ipAddress: ipAddress ?? this.ipAddress,
      location: location ?? this.location,
      metadata: metadata ?? this.metadata,
      securityLevel: securityLevel ?? this.securityLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'userId': userId,
      'type': type.toString(),
      'description': description,
      'occurredAt': occurredAt.toIso8601String(),
      'ipAddress': ipAddress,
      'location': location?.toJson(),
      'metadata': metadata,
      'securityLevel': securityLevel.toString(),
    };
  }

  factory DeviceActivity.fromJson(Map<String, dynamic> json) {
    return DeviceActivity(
      id: json['id'],
      deviceId: json['deviceId'],
      userId: json['userId'],
      type: ActivityType.values.firstWhere((e) => e.toString() == json['type']),
      description: json['description'],
      occurredAt: DateTime.parse(json['occurredAt']),
      ipAddress: json['ipAddress'],
      location: json['location'] != null ? DeviceLocation.fromJson(json['location']) : null,
      metadata: json['metadata'],
      securityLevel: SecurityLevel.values.firstWhere((e) => e.toString() == json['securityLevel']),
    );
  }
}

enum ActivityType {
  login,
  logout,
  registration,
  trustScoreUpdate,
  suspiciousActivity,
  verification,
  settingsUpdate,
  remoteLogout,
  locationUpdate,
  sessionRenewal,
}

enum SecurityLevel {
  low,
  medium,
  high,
  critical,
}

class DeviceLocation {
  final double latitude;
  final double longitude;
  final String country;
  final String? region;
  final String? city;
  final DateTime timestamp;

  DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.country,
    this.region,
    this.city,
    required this.timestamp,
  });

  DeviceLocation copyWith({
    double? latitude,
    double? longitude,
    String? country,
    String? region,
    String? city,
    DateTime? timestamp,
  }) {
    return DeviceLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      country: country ?? this.country,
      region: region ?? this.region,
      city: city ?? this.city,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'region': region,
      'city': city,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DeviceLocation.fromJson(Map<String, dynamic> json) {
    return DeviceLocation(
      latitude: json['latitude'],
      longitude: json['longitude'],
      country: json['country'],
      region: json['region'],
      city: json['city'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  bool isWithinRadius(DeviceLocation other, double radiusKm) {
    const double earthRadius = 6371.0;
    double dLat = _toRadians(other.latitude - latitude);
    double dLon = _toRadians(other.longitude - longitude);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
        cos(_toRadians(other.latitude)) *
        sin(dLon / 2) *
        sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;
    return distance <= radiusKm;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
}