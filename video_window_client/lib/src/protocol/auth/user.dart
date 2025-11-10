/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class User implements _i1.SerializableModel {
  User._({
    this.id,
    this.email,
    this.phone,
    required this.role,
    required this.authProvider,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isActive,
    required this.failedAttempts,
    this.lockedUntil,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  factory User({
    int? id,
    String? email,
    String? phone,
    required String role,
    required String authProvider,
    required bool isEmailVerified,
    required bool isPhoneVerified,
    required bool isActive,
    required int failedAttempts,
    DateTime? lockedUntil,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastLoginAt,
  }) = _UserImpl;

  factory User.fromJson(Map<String, dynamic> jsonSerialization) {
    return User(
      id: jsonSerialization['id'] as int?,
      email: jsonSerialization['email'] as String?,
      phone: jsonSerialization['phone'] as String?,
      role: jsonSerialization['role'] as String,
      authProvider: jsonSerialization['authProvider'] as String,
      isEmailVerified: jsonSerialization['isEmailVerified'] as bool,
      isPhoneVerified: jsonSerialization['isPhoneVerified'] as bool,
      isActive: jsonSerialization['isActive'] as bool,
      failedAttempts: jsonSerialization['failedAttempts'] as int,
      lockedUntil: jsonSerialization['lockedUntil'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lockedUntil']),
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      lastLoginAt: jsonSerialization['lastLoginAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastLoginAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String? email;

  String? phone;

  String role;

  String authProvider;

  bool isEmailVerified;

  bool isPhoneVerified;

  bool isActive;

  int failedAttempts;

  DateTime? lockedUntil;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? lastLoginAt;

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  User copyWith({
    int? id,
    String? email,
    String? phone,
    String? role,
    String? authProvider,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isActive,
    int? failedAttempts,
    DateTime? lockedUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'role': role,
      'authProvider': authProvider,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isActive': isActive,
      'failedAttempts': failedAttempts,
      if (lockedUntil != null) 'lockedUntil': lockedUntil?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserImpl extends User {
  _UserImpl({
    int? id,
    String? email,
    String? phone,
    required String role,
    required String authProvider,
    required bool isEmailVerified,
    required bool isPhoneVerified,
    required bool isActive,
    required int failedAttempts,
    DateTime? lockedUntil,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastLoginAt,
  }) : super._(
          id: id,
          email: email,
          phone: phone,
          role: role,
          authProvider: authProvider,
          isEmailVerified: isEmailVerified,
          isPhoneVerified: isPhoneVerified,
          isActive: isActive,
          failedAttempts: failedAttempts,
          lockedUntil: lockedUntil,
          createdAt: createdAt,
          updatedAt: updatedAt,
          lastLoginAt: lastLoginAt,
        );

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  User copyWith({
    Object? id = _Undefined,
    Object? email = _Undefined,
    Object? phone = _Undefined,
    String? role,
    String? authProvider,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isActive,
    int? failedAttempts,
    Object? lockedUntil = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? lastLoginAt = _Undefined,
  }) {
    return User(
      id: id is int? ? id : this.id,
      email: email is String? ? email : this.email,
      phone: phone is String? ? phone : this.phone,
      role: role ?? this.role,
      authProvider: authProvider ?? this.authProvider,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isActive: isActive ?? this.isActive,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil is DateTime? ? lockedUntil : this.lockedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt is DateTime? ? lastLoginAt : this.lastLoginAt,
    );
  }
}
