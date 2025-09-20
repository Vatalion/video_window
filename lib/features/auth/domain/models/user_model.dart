import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? phone;
  final String passwordHash;
  final VerificationStatus verificationStatus;
  final bool ageVerified;
  final String? displayName;
  final String? photoUrl;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.passwordHash,
    required this.verificationStatus,
    required this.ageVerified,
    this.displayName,
    this.photoUrl,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      passwordHash: json['password_hash'] as String,
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == json['verification_status'],
        orElse: () => VerificationStatus.pending,
      ),
      ageVerified: json['age_verified'] as bool,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'verification_status': verificationStatus.name,
      'age_verified': ageVerified,
      'display_name': displayName,
      'photo_url': photoUrl,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? passwordHash,
    VerificationStatus? verificationStatus,
    bool? ageVerified,
    String? displayName,
    String? photoUrl,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      ageVerified: ageVerified ?? this.ageVerified,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    email,
    phone ?? '',
    passwordHash,
    verificationStatus,
    ageVerified,
    displayName ?? '',
    photoUrl ?? '',
    lastLoginAt ?? DateTime.now(),
    createdAt,
    updatedAt,
  ];

  factory UserModel.empty() {
    return UserModel(
      id: '',
      email: '',
      phone: null,
      passwordHash: '',
      verificationStatus: VerificationStatus.pending,
      ageVerified: false,
      displayName: null,
      photoUrl: null,
      lastLoginAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

enum VerificationStatus { pending, emailVerified, phoneVerified, fullyVerified }
