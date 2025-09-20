class DeviceTrust {
  final String deviceId;
  final int trustScore;
  final TrustLevel level;
  final DateTime lastUpdated;
  final Map<String, dynamic> factors;
  final List<TrustEvent> trustEvents;

  DeviceTrust({
    required this.deviceId,
    required this.trustScore,
    required this.level,
    required this.lastUpdated,
    required this.factors,
    required this.trustEvents,
  });

  DeviceTrust copyWith({
    String? deviceId,
    int? trustScore,
    TrustLevel? level,
    DateTime? lastUpdated,
    Map<String, dynamic>? factors,
    List<TrustEvent>? trustEvents,
  }) {
    return DeviceTrust(
      deviceId: deviceId ?? this.deviceId,
      trustScore: trustScore ?? this.trustScore,
      level: level ?? this.level,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      factors: factors ?? this.factors,
      trustEvents: trustEvents ?? this.trustEvents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'trustScore': trustScore,
      'level': level.toString(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'factors': factors,
      'trustEvents': trustEvents.map((e) => e.toJson()).toList(),
    };
  }

  factory DeviceTrust.fromJson(Map<String, dynamic> json) {
    return DeviceTrust(
      deviceId: json['deviceId'],
      trustScore: json['trustScore'],
      level: TrustLevel.values.firstWhere((e) => e.toString() == json['level']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      factors: json['factors'],
      trustEvents: (json['trustEvents'] as List).map((e) => TrustEvent.fromJson(e)).toList(),
    );
  }
}

class TrustEvent {
  final String id;
  final String deviceId;
  final TrustEventType type;
  final int scoreChange;
  final String description;
  final DateTime occurredAt;
  final Map<String, dynamic> metadata;

  TrustEvent({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.scoreChange,
    required this.description,
    required this.occurredAt,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'type': type.toString(),
      'scoreChange': scoreChange,
      'description': description,
      'occurredAt': occurredAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory TrustEvent.fromJson(Map<String, dynamic> json) {
    return TrustEvent(
      id: json['id'],
      deviceId: json['deviceId'],
      type: TrustEventType.values.firstWhere((e) => e.toString() == json['type']),
      scoreChange: json['scoreChange'],
      description: json['description'],
      occurredAt: DateTime.parse(json['occurredAt']),
      metadata: json['metadata'],
    );
  }
}

enum TrustEventType {
  loginSuccess,
  loginFailure,
  locationChange,
  ipAddressChange,
  suspiciousActivity,
  verifiedAction,
  longInactivity,
  securityScan,
}

class TrustFactors {
  final int usageFrequency;
  final int locationConsistency;
  final int behavioralConsistency;
  final int securityCompliance;
  final int ageOfDevice;
  final int verificationLevel;
  final int networkTrust;

  TrustFactors({
    required this.usageFrequency,
    required this.locationConsistency,
    required this.behavioralConsistency,
    required this.securityCompliance,
    required this.ageOfDevice,
    required this.verificationLevel,
    required this.networkTrust,
  });

  int calculateTrustScore() {
    return (usageFrequency * 0.25 +
            locationConsistency * 0.20 +
            behavioralConsistency * 0.20 +
            securityCompliance * 0.15 +
            ageOfDevice * 0.10 +
            verificationLevel * 0.05 +
            networkTrust * 0.05)
        .round();
  }

  Map<String, dynamic> toJson() {
    return {
      'usageFrequency': usageFrequency,
      'locationConsistency': locationConsistency,
      'behavioralConsistency': behavioralConsistency,
      'securityCompliance': securityCompliance,
      'ageOfDevice': ageOfDevice,
      'verificationLevel': verificationLevel,
      'networkTrust': networkTrust,
    };
  }

  factory TrustFactors.fromJson(Map<String, dynamic> json) {
    return TrustFactors(
      usageFrequency: json['usageFrequency'],
      locationConsistency: json['locationConsistency'],
      behavioralConsistency: json['behavioralConsistency'],
      securityCompliance: json['securityCompliance'],
      ageOfDevice: json['ageOfDevice'],
      verificationLevel: json['verificationLevel'],
      networkTrust: json['networkTrust'],
    );
  }
}