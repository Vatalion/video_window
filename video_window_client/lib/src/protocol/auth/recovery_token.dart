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

abstract class RecoveryToken implements _i1.SerializableModel {
  RecoveryToken._({
    this.id,
    required this.userId,
    required this.email,
    required this.tokenHash,
    required this.salt,
    this.deviceInfo,
    required this.ipAddress,
    this.userAgent,
    this.location,
    required this.attempts,
    required this.used,
    required this.revoked,
    required this.expiresAt,
    required this.createdAt,
    this.usedAt,
    this.revokedAt,
  });

  factory RecoveryToken({
    int? id,
    required int userId,
    required String email,
    required String tokenHash,
    required String salt,
    String? deviceInfo,
    required String ipAddress,
    String? userAgent,
    String? location,
    required int attempts,
    required bool used,
    required bool revoked,
    required DateTime expiresAt,
    required DateTime createdAt,
    DateTime? usedAt,
    DateTime? revokedAt,
  }) = _RecoveryTokenImpl;

  factory RecoveryToken.fromJson(Map<String, dynamic> jsonSerialization) {
    return RecoveryToken(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      email: jsonSerialization['email'] as String,
      tokenHash: jsonSerialization['tokenHash'] as String,
      salt: jsonSerialization['salt'] as String,
      deviceInfo: jsonSerialization['deviceInfo'] as String?,
      ipAddress: jsonSerialization['ipAddress'] as String,
      userAgent: jsonSerialization['userAgent'] as String?,
      location: jsonSerialization['location'] as String?,
      attempts: jsonSerialization['attempts'] as int,
      used: jsonSerialization['used'] as bool,
      revoked: jsonSerialization['revoked'] as bool,
      expiresAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      usedAt: jsonSerialization['usedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['usedAt']),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  String email;

  String tokenHash;

  String salt;

  String? deviceInfo;

  String ipAddress;

  String? userAgent;

  String? location;

  int attempts;

  bool used;

  bool revoked;

  DateTime expiresAt;

  DateTime createdAt;

  DateTime? usedAt;

  DateTime? revokedAt;

  /// Returns a shallow copy of this [RecoveryToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RecoveryToken copyWith({
    int? id,
    int? userId,
    String? email,
    String? tokenHash,
    String? salt,
    String? deviceInfo,
    String? ipAddress,
    String? userAgent,
    String? location,
    int? attempts,
    bool? used,
    bool? revoked,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? usedAt,
    DateTime? revokedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'email': email,
      'tokenHash': tokenHash,
      'salt': salt,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
      if (userAgent != null) 'userAgent': userAgent,
      if (location != null) 'location': location,
      'attempts': attempts,
      'used': used,
      'revoked': revoked,
      'expiresAt': expiresAt.toJson(),
      'createdAt': createdAt.toJson(),
      if (usedAt != null) 'usedAt': usedAt?.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RecoveryTokenImpl extends RecoveryToken {
  _RecoveryTokenImpl({
    int? id,
    required int userId,
    required String email,
    required String tokenHash,
    required String salt,
    String? deviceInfo,
    required String ipAddress,
    String? userAgent,
    String? location,
    required int attempts,
    required bool used,
    required bool revoked,
    required DateTime expiresAt,
    required DateTime createdAt,
    DateTime? usedAt,
    DateTime? revokedAt,
  }) : super._(
          id: id,
          userId: userId,
          email: email,
          tokenHash: tokenHash,
          salt: salt,
          deviceInfo: deviceInfo,
          ipAddress: ipAddress,
          userAgent: userAgent,
          location: location,
          attempts: attempts,
          used: used,
          revoked: revoked,
          expiresAt: expiresAt,
          createdAt: createdAt,
          usedAt: usedAt,
          revokedAt: revokedAt,
        );

  /// Returns a shallow copy of this [RecoveryToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RecoveryToken copyWith({
    Object? id = _Undefined,
    int? userId,
    String? email,
    String? tokenHash,
    String? salt,
    Object? deviceInfo = _Undefined,
    String? ipAddress,
    Object? userAgent = _Undefined,
    Object? location = _Undefined,
    int? attempts,
    bool? used,
    bool? revoked,
    DateTime? expiresAt,
    DateTime? createdAt,
    Object? usedAt = _Undefined,
    Object? revokedAt = _Undefined,
  }) {
    return RecoveryToken(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      tokenHash: tokenHash ?? this.tokenHash,
      salt: salt ?? this.salt,
      deviceInfo: deviceInfo is String? ? deviceInfo : this.deviceInfo,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent is String? ? userAgent : this.userAgent,
      location: location is String? ? location : this.location,
      attempts: attempts ?? this.attempts,
      used: used ?? this.used,
      revoked: revoked ?? this.revoked,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      usedAt: usedAt is DateTime? ? usedAt : this.usedAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
    );
  }
}
