import 'package:equatable/equatable.dart';

class RecoveryTokenModel extends Equatable {
  final String id;
  final String userId;
  final RecoveryTokenType type;
  final String token;
  final String? phoneNumber;
  final String? email;
  final DateTime expiresAt;
  final bool isUsed;
  final int attemptsRemaining;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  const RecoveryTokenModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.token,
    this.phoneNumber,
    this.email,
    required this.expiresAt,
    required this.isUsed,
    required this.attemptsRemaining,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory RecoveryTokenModel.fromJson(Map<String, dynamic> json) {
    return RecoveryTokenModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: RecoveryTokenType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecoveryTokenType.email,
      ),
      token: json['token'] as String,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isUsed: json['is_used'] as bool,
      attemptsRemaining: json['attempts_remaining'] as int,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'token': token,
      'phone_number': phoneNumber,
      'email': email,
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
      'attempts_remaining': attemptsRemaining,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired && attemptsRemaining > 0;

  @override
  List<Object> get props => [
    id,
    userId,
    type,
    token,
    phoneNumber ?? '',
    email ?? '',
    expiresAt,
    isUsed,
    attemptsRemaining,
    ipAddress ?? '',
    userAgent ?? '',
    createdAt,
  ];
}

enum RecoveryTokenType {
  email,
  phone,
  backupEmail,
  backupPhone,
  securityQuestion,
}
