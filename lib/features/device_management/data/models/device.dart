class Device {
  final String id;
  final String name;
  final String type;
  final String hardwareId;
  final String ipAddress;
  final String browserFingerprint;
  final String installationId;
  final DeviceLocation? location;
  final int trustScore;
  final DateTime lastActivity;
  final DateTime registeredAt;
  final String status;
  final bool isCurrentDevice;
  final DeviceSession? currentSession;

  Device({
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

  Device copyWith({
    String? id,
    String? name,
    String? type,
    String? hardwareId,
    String? ipAddress,
    String? browserFingerprint,
    String? installationId,
    DeviceLocation? location,
    int? trustScore,
    DateTime? lastActivity,
    DateTime? registeredAt,
    String? status,
    bool? isCurrentDevice,
    DeviceSession? currentSession,
  }) {
    return Device(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'hardwareId': hardwareId,
      'ipAddress': ipAddress,
      'browserFingerprint': browserFingerprint,
      'installationId': installationId,
      'location': location?.toJson(),
      'trustScore': trustScore,
      'lastActivity': lastActivity.toIso8601String(),
      'registeredAt': registeredAt.toIso8601String(),
      'status': status,
      'isCurrentDevice': isCurrentDevice,
      'currentSession': currentSession?.toJson(),
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      hardwareId: json['hardwareId'],
      ipAddress: json['ipAddress'],
      browserFingerprint: json['browserFingerprint'],
      installationId: json['installationId'],
      location: json['location'] != null ? DeviceLocation.fromJson(json['location']) : null,
      trustScore: json['trustScore'],
      lastActivity: DateTime.parse(json['lastActivity']),
      registeredAt: DateTime.parse(json['registeredAt']),
      status: json['status'],
      isCurrentDevice: json['isCurrentDevice'],
      currentSession: json['currentSession'] != null ? DeviceSession.fromJson(json['currentSession']) : null,
    );
  }

  TrustLevel get trustLevel {
    if (trustScore >= 80) return TrustLevel.high;
    if (trustScore >= 50) return TrustLevel.medium;
    return TrustLevel.low;
  }
}

enum TrustLevel { high, medium, low }

enum DeviceType { mobile, desktop, tablet, web, unknown }