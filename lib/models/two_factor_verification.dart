class TwoFactorVerification {
  final String verificationId;
  final String userId;
  final String verificationType; // 'sms', 'totp', 'backup_code'
  final String code;
  final DateTime expiresAt;
  final bool used;
  final DateTime? usedAt;
  final String? deviceId;
  final String? ipAddress;

  TwoFactorVerification({
    required this.verificationId,
    required this.userId,
    required this.verificationType,
    required this.code,
    required this.expiresAt,
    this.used = false,
    this.usedAt,
    this.deviceId,
    this.ipAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'verificationId': verificationId,
      'userId': userId,
      'verificationType': verificationType,
      'code': code,
      'expiresAt': expiresAt.toIso8601String(),
      'used': used,
      'usedAt': usedAt?.toIso8601String(),
      'deviceId': deviceId,
      'ipAddress': ipAddress,
    };
  }

  factory TwoFactorVerification.fromJson(Map<String, dynamic> json) {
    return TwoFactorVerification(
      verificationId: json['verificationId'],
      userId: json['userId'],
      verificationType: json['verificationType'],
      code: json['code'],
      expiresAt: DateTime.parse(json['expiresAt']),
      used: json['used'] ?? false,
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
      deviceId: json['deviceId'],
      ipAddress: json['ipAddress'],
    );
  }

  bool get isValid {
    return !used && DateTime.now().isBefore(expiresAt);
  }

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }
}