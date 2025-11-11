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

abstract class DsarRequest implements _i1.SerializableModel {
  DsarRequest._({
    this.id,
    required this.userId,
    required this.requestType,
    required this.status,
    required this.requestedAt,
    this.completedAt,
    this.requestData,
    this.auditLog,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DsarRequest({
    int? id,
    required int userId,
    required String requestType,
    required String status,
    required DateTime requestedAt,
    DateTime? completedAt,
    String? requestData,
    String? auditLog,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DsarRequestImpl;

  factory DsarRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return DsarRequest(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      requestType: jsonSerialization['requestType'] as String,
      status: jsonSerialization['status'] as String,
      requestedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['requestedAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt']),
      requestData: jsonSerialization['requestData'] as String?,
      auditLog: jsonSerialization['auditLog'] as String?,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  String requestType;

  String status;

  DateTime requestedAt;

  DateTime? completedAt;

  String? requestData;

  String? auditLog;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [DsarRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DsarRequest copyWith({
    int? id,
    int? userId,
    String? requestType,
    String? status,
    DateTime? requestedAt,
    DateTime? completedAt,
    String? requestData,
    String? auditLog,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'requestType': requestType,
      'status': status,
      'requestedAt': requestedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (requestData != null) 'requestData': requestData,
      if (auditLog != null) 'auditLog': auditLog,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DsarRequestImpl extends DsarRequest {
  _DsarRequestImpl({
    int? id,
    required int userId,
    required String requestType,
    required String status,
    required DateTime requestedAt,
    DateTime? completedAt,
    String? requestData,
    String? auditLog,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
          id: id,
          userId: userId,
          requestType: requestType,
          status: status,
          requestedAt: requestedAt,
          completedAt: completedAt,
          requestData: requestData,
          auditLog: auditLog,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Returns a shallow copy of this [DsarRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DsarRequest copyWith({
    Object? id = _Undefined,
    int? userId,
    String? requestType,
    String? status,
    DateTime? requestedAt,
    Object? completedAt = _Undefined,
    Object? requestData = _Undefined,
    Object? auditLog = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DsarRequest(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      requestType: requestType ?? this.requestType,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      requestData: requestData is String? ? requestData : this.requestData,
      auditLog: auditLog is String? ? auditLog : this.auditLog,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
