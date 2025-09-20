import 'package:equatable/equatable.dart';

class RecoveryAttemptModel extends Equatable {
  final String id;
  final String userId;
  final RecoveryAttemptType type;
  final String? identifier; // email or phone
  final bool wasSuccessful;
  final String? failureReason;
  final String ipAddress;
  final String userAgent;
  final String? deviceId;
  final bool wasSuspicious;
  final String? suspicionReason;
  final DateTime createdAt;

  const RecoveryAttemptModel({
    required this.id,
    required this.userId,
    required this.type,
    this.identifier,
    required this.wasSuccessful,
    this.failureReason,
    required this.ipAddress,
    required this.userAgent,
    this.deviceId,
    required this.wasSuspicious,
    this.suspicionReason,
    required this.createdAt,
  });

  factory RecoveryAttemptModel.fromJson(Map<String, dynamic> json) {
    return RecoveryAttemptModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: RecoveryAttemptType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecoveryAttemptType.email,
      ),
      identifier: json['identifier'] as String?,
      wasSuccessful: json['was_successful'] as bool,
      failureReason: json['failure_reason'] as String?,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String,
      deviceId: json['device_id'] as String?,
      wasSuspicious: json['was_suspicious'] as bool,
      suspicionReason: json['suspicion_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'identifier': identifier,
      'was_successful': wasSuccessful,
      'failure_reason': failureReason,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'device_id': deviceId,
      'was_suspicious': wasSuspicious,
      'suspicion_reason': suspicionReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [
    id,
    userId,
    type,
    identifier ?? '',
    wasSuccessful,
    failureReason ?? '',
    ipAddress,
    userAgent,
    deviceId ?? '',
    wasSuspicious,
    suspicionReason ?? '',
    createdAt,
  ];
}

enum RecoveryAttemptType {
  email,
  phone,
  backupEmail,
  backupPhone,
  securityQuestion,
  accountLockout,
}
