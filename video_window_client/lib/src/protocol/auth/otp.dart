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

abstract class Otp implements _i1.SerializableModel {
  Otp._({
    this.id,
    required this.identifier,
    required this.otpHash,
    required this.salt,
    required this.attempts,
    required this.used,
    required this.expiresAt,
    required this.createdAt,
    this.usedAt,
  });

  factory Otp({
    int? id,
    required String identifier,
    required String otpHash,
    required String salt,
    required int attempts,
    required bool used,
    required DateTime expiresAt,
    required DateTime createdAt,
    DateTime? usedAt,
  }) = _OtpImpl;

  factory Otp.fromJson(Map<String, dynamic> jsonSerialization) {
    return Otp(
      id: jsonSerialization['id'] as int?,
      identifier: jsonSerialization['identifier'] as String,
      otpHash: jsonSerialization['otpHash'] as String,
      salt: jsonSerialization['salt'] as String,
      attempts: jsonSerialization['attempts'] as int,
      used: jsonSerialization['used'] as bool,
      expiresAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      usedAt: jsonSerialization['usedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['usedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String identifier;

  String otpHash;

  String salt;

  int attempts;

  bool used;

  DateTime expiresAt;

  DateTime createdAt;

  DateTime? usedAt;

  /// Returns a shallow copy of this [Otp]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Otp copyWith({
    int? id,
    String? identifier,
    String? otpHash,
    String? salt,
    int? attempts,
    bool? used,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? usedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'identifier': identifier,
      'otpHash': otpHash,
      'salt': salt,
      'attempts': attempts,
      'used': used,
      'expiresAt': expiresAt.toJson(),
      'createdAt': createdAt.toJson(),
      if (usedAt != null) 'usedAt': usedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OtpImpl extends Otp {
  _OtpImpl({
    int? id,
    required String identifier,
    required String otpHash,
    required String salt,
    required int attempts,
    required bool used,
    required DateTime expiresAt,
    required DateTime createdAt,
    DateTime? usedAt,
  }) : super._(
          id: id,
          identifier: identifier,
          otpHash: otpHash,
          salt: salt,
          attempts: attempts,
          used: used,
          expiresAt: expiresAt,
          createdAt: createdAt,
          usedAt: usedAt,
        );

  /// Returns a shallow copy of this [Otp]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Otp copyWith({
    Object? id = _Undefined,
    String? identifier,
    String? otpHash,
    String? salt,
    int? attempts,
    bool? used,
    DateTime? expiresAt,
    DateTime? createdAt,
    Object? usedAt = _Undefined,
  }) {
    return Otp(
      id: id is int? ? id : this.id,
      identifier: identifier ?? this.identifier,
      otpHash: otpHash ?? this.otpHash,
      salt: salt ?? this.salt,
      attempts: attempts ?? this.attempts,
      used: used ?? this.used,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      usedAt: usedAt is DateTime? ? usedAt : this.usedAt,
    );
  }
}
