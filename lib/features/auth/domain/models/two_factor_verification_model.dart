import 'package:equatable/equatable.dart';

enum TwoFactorVerificationType { setup, login, sensitiveAction, recovery }

class TwoFactorVerification extends Equatable {
  final String id;
  final String userId;
  final TwoFactorVerificationType type;
  final String sessionId;
  final String code;
  final DateTime expiresAt;
  final int attemptCount;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? deviceId;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TwoFactorVerification({
    required this.id,
    required this.userId,
    required this.type,
    required this.sessionId,
    required this.code,
    required this.expiresAt,
    this.attemptCount = 0,
    this.isVerified = false,
    this.verifiedAt,
    this.deviceId,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
    required this.updatedAt,
  });

  TwoFactorVerification copyWith({
    String? id,
    String? userId,
    TwoFactorVerificationType? type,
    String? sessionId,
    String? code,
    DateTime? expiresAt,
    int? attemptCount,
    bool? isVerified,
    DateTime? verifiedAt,
    String? deviceId,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TwoFactorVerification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      sessionId: sessionId ?? this.sessionId,
      code: code ?? this.code,
      expiresAt: expiresAt ?? this.expiresAt,
      attemptCount: attemptCount ?? this.attemptCount,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      deviceId: deviceId ?? this.deviceId,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    sessionId,
    code,
    expiresAt,
    attemptCount,
    isVerified,
    verifiedAt,
    deviceId,
    ipAddress,
    userAgent,
    createdAt,
    updatedAt,
  ];

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canAttempt => attemptCount < 10 && !isExpired && !isVerified;
  bool get isMaxAttemptsReached => attemptCount >= 10;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'sessionId': sessionId,
      'code': code,
      'expiresAt': expiresAt.toIso8601String(),
      'attemptCount': attemptCount,
      'isVerified': isVerified,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'deviceId': deviceId,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TwoFactorVerification.fromJson(Map<String, dynamic> json) {
    return TwoFactorVerification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: TwoFactorVerificationType.values.byName(json['type'] as String),
      sessionId: json['sessionId'] as String,
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      attemptCount: json['attemptCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      deviceId: json['deviceId'] as String?,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
