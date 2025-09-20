import 'package:equatable/equatable.dart';

class LoginAttemptModel extends Equatable {
  final String id;
  final String? email;
  final String? phone;
  final String ipAddress;
  final String userAgent;
  final bool wasSuccessful;
  final DateTime attemptTime;
  final String? failureReason;
  final String? userId;

  const LoginAttemptModel({
    required this.id,
    this.email,
    this.phone,
    required this.ipAddress,
    required this.userAgent,
    required this.wasSuccessful,
    required this.attemptTime,
    this.failureReason,
    this.userId,
  });

  factory LoginAttemptModel.fromJson(Map<String, dynamic> json) {
    return LoginAttemptModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String,
      wasSuccessful: json['was_successful'] as bool,
      attemptTime: DateTime.parse(json['attempt_time'] as String),
      failureReason: json['failure_reason'] as String?,
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'was_successful': wasSuccessful,
      'attempt_time': attemptTime.toIso8601String(),
      'failure_reason': failureReason,
      'user_id': userId,
    };
  }

  LoginAttemptModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? ipAddress,
    String? userAgent,
    bool? wasSuccessful,
    DateTime? attemptTime,
    String? failureReason,
    String? userId,
  }) {
    return LoginAttemptModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      wasSuccessful: wasSuccessful ?? this.wasSuccessful,
      attemptTime: attemptTime ?? this.attemptTime,
      failureReason: failureReason ?? this.failureReason,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object> get props => [
    id,
    email ?? '',
    phone ?? '',
    ipAddress,
    userAgent,
    wasSuccessful,
    attemptTime,
    failureReason ?? '',
    userId ?? '',
  ];
}
