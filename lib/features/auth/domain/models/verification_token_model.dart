import 'package:equatable/equatable.dart';

class VerificationTokenModel extends Equatable {
  final String id;
  final String userId;
  final TokenType tokenType;
  final String tokenValue;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime createdAt;

  const VerificationTokenModel({
    required this.id,
    required this.userId,
    required this.tokenType,
    required this.tokenValue,
    required this.expiresAt,
    required this.isUsed,
    required this.createdAt,
  });

  factory VerificationTokenModel.fromJson(Map<String, dynamic> json) {
    return VerificationTokenModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tokenType: TokenType.values.firstWhere(
        (e) => e.name == json['token_type'],
        orElse: () => TokenType.email,
      ),
      tokenValue: json['token_value'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isUsed: json['is_used'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'token_type': tokenType.name,
      'token_value': tokenValue,
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  VerificationTokenModel copyWith({
    String? id,
    String? userId,
    TokenType? tokenType,
    String? tokenValue,
    DateTime? expiresAt,
    bool? isUsed,
    DateTime? createdAt,
  }) {
    return VerificationTokenModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tokenType: tokenType ?? this.tokenType,
      tokenValue: tokenValue ?? this.tokenValue,
      expiresAt: expiresAt ?? this.expiresAt,
      isUsed: isUsed ?? this.isUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    userId,
    tokenType,
    tokenValue,
    expiresAt,
    isUsed,
    createdAt,
  ];
}

enum TokenType { email, phone }
