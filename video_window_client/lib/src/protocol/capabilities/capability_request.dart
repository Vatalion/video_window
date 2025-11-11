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
import '../capabilities/capability_type.dart' as _i2;
import '../capabilities/capability_request_status.dart' as _i3;

abstract class CapabilityRequest implements _i1.SerializableModel {
  CapabilityRequest._({
    this.id,
    required this.userId,
    required this.capability,
    required this.status,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  factory CapabilityRequest({
    int? id,
    required int userId,
    required _i2.CapabilityType capability,
    required _i3.CapabilityRequestStatus status,
    required String metadata,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? resolvedAt,
  }) = _CapabilityRequestImpl;

  factory CapabilityRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return CapabilityRequest(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      capability:
          _i2.CapabilityType.fromJson((jsonSerialization['capability'] as int)),
      status: _i3.CapabilityRequestStatus.fromJson(
          (jsonSerialization['status'] as int)),
      metadata: jsonSerialization['metadata'] as String,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  _i2.CapabilityType capability;

  _i3.CapabilityRequestStatus status;

  String metadata;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? resolvedAt;

  /// Returns a shallow copy of this [CapabilityRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CapabilityRequest copyWith({
    int? id,
    int? userId,
    _i2.CapabilityType? capability,
    _i3.CapabilityRequestStatus? status,
    String? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'capability': capability.toJson(),
      'status': status.toJson(),
      'metadata': metadata,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CapabilityRequestImpl extends CapabilityRequest {
  _CapabilityRequestImpl({
    int? id,
    required int userId,
    required _i2.CapabilityType capability,
    required _i3.CapabilityRequestStatus status,
    required String metadata,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? resolvedAt,
  }) : super._(
          id: id,
          userId: userId,
          capability: capability,
          status: status,
          metadata: metadata,
          createdAt: createdAt,
          updatedAt: updatedAt,
          resolvedAt: resolvedAt,
        );

  /// Returns a shallow copy of this [CapabilityRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CapabilityRequest copyWith({
    Object? id = _Undefined,
    int? userId,
    _i2.CapabilityType? capability,
    _i3.CapabilityRequestStatus? status,
    String? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? resolvedAt = _Undefined,
  }) {
    return CapabilityRequest(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      capability: capability ?? this.capability,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
    );
  }
}
