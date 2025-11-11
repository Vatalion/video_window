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

abstract class PrivacyAuditLog implements _i1.SerializableModel {
  PrivacyAuditLog._({
    this.id,
    required this.userId,
    required this.actorId,
    required this.settingName,
    required this.oldValue,
    required this.newValue,
    required this.changeSummary,
    this.auditContext,
    required this.createdAt,
  });

  factory PrivacyAuditLog({
    int? id,
    required int userId,
    required int actorId,
    required String settingName,
    required String oldValue,
    required String newValue,
    required String changeSummary,
    String? auditContext,
    required DateTime createdAt,
  }) = _PrivacyAuditLogImpl;

  factory PrivacyAuditLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return PrivacyAuditLog(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      actorId: jsonSerialization['actorId'] as int,
      settingName: jsonSerialization['settingName'] as String,
      oldValue: jsonSerialization['oldValue'] as String,
      newValue: jsonSerialization['newValue'] as String,
      changeSummary: jsonSerialization['changeSummary'] as String,
      auditContext: jsonSerialization['auditContext'] as String?,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  int actorId;

  String settingName;

  String oldValue;

  String newValue;

  String changeSummary;

  String? auditContext;

  DateTime createdAt;

  /// Returns a shallow copy of this [PrivacyAuditLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PrivacyAuditLog copyWith({
    int? id,
    int? userId,
    int? actorId,
    String? settingName,
    String? oldValue,
    String? newValue,
    String? changeSummary,
    String? auditContext,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'actorId': actorId,
      'settingName': settingName,
      'oldValue': oldValue,
      'newValue': newValue,
      'changeSummary': changeSummary,
      if (auditContext != null) 'auditContext': auditContext,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrivacyAuditLogImpl extends PrivacyAuditLog {
  _PrivacyAuditLogImpl({
    int? id,
    required int userId,
    required int actorId,
    required String settingName,
    required String oldValue,
    required String newValue,
    required String changeSummary,
    String? auditContext,
    required DateTime createdAt,
  }) : super._(
          id: id,
          userId: userId,
          actorId: actorId,
          settingName: settingName,
          oldValue: oldValue,
          newValue: newValue,
          changeSummary: changeSummary,
          auditContext: auditContext,
          createdAt: createdAt,
        );

  /// Returns a shallow copy of this [PrivacyAuditLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PrivacyAuditLog copyWith({
    Object? id = _Undefined,
    int? userId,
    int? actorId,
    String? settingName,
    String? oldValue,
    String? newValue,
    String? changeSummary,
    Object? auditContext = _Undefined,
    DateTime? createdAt,
  }) {
    return PrivacyAuditLog(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      settingName: settingName ?? this.settingName,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      changeSummary: changeSummary ?? this.changeSummary,
      auditContext: auditContext is String? ? auditContext : this.auditContext,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
