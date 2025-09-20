class TwoFactorConfiguration {
  final String userId;
  final bool smsEnabled;
  final bool totpEnabled;
  final String? phoneNumber;
  final String? totpSecret;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? backupCodes;
  final bool gracePeriodActive;
  final DateTime? gracePeriodEnds;

  TwoFactorConfiguration({
    required this.userId,
    this.smsEnabled = false,
    this.totpEnabled = false,
    this.phoneNumber,
    this.totpSecret,
    this.createdAt,
    this.updatedAt,
    this.backupCodes,
    this.gracePeriodActive = false,
    this.gracePeriodEnds,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'smsEnabled': smsEnabled,
      'totpEnabled': totpEnabled,
      'phoneNumber': phoneNumber,
      'totpSecret': totpSecret,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'backupCodes': backupCodes,
      'gracePeriodActive': gracePeriodActive,
      'gracePeriodEnds': gracePeriodEnds?.toIso8601String(),
    };
  }

  factory TwoFactorConfiguration.fromJson(Map<String, dynamic> json) {
    return TwoFactorConfiguration(
      userId: json['userId'],
      smsEnabled: json['smsEnabled'] ?? false,
      totpEnabled: json['totpEnabled'] ?? false,
      phoneNumber: json['phoneNumber'],
      totpSecret: json['totpSecret'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      backupCodes: json['backupCodes']?.cast<String>(),
      gracePeriodActive: json['gracePeriodActive'] ?? false,
      gracePeriodEnds: json['gracePeriodEnds'] != null ? DateTime.parse(json['gracePeriodEnds']) : null,
    );
  }

  TwoFactorConfiguration copyWith({
    String? userId,
    bool? smsEnabled,
    bool? totpEnabled,
    String? phoneNumber,
    String? totpSecret,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? backupCodes,
    bool? gracePeriodActive,
    DateTime? gracePeriodEnds,
  }) {
    return TwoFactorConfiguration(
      userId: userId ?? this.userId,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      totpEnabled: totpEnabled ?? this.totpEnabled,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      totpSecret: totpSecret ?? this.totpSecret,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      backupCodes: backupCodes ?? this.backupCodes,
      gracePeriodActive: gracePeriodActive ?? this.gracePeriodActive,
      gracePeriodEnds: gracePeriodEnds ?? this.gracePeriodEnds,
    );
  }
}