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
import '../capabilities/verification_task_type.dart' as _i3;
import '../capabilities/verification_task_status.dart' as _i4;

abstract class VerificationTask implements _i1.SerializableModel {
  VerificationTask._({
    this.id,
    required this.userId,
    required this.capability,
    required this.taskType,
    required this.status,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory VerificationTask({
    int? id,
    required int userId,
    required _i2.CapabilityType capability,
    required _i3.VerificationTaskType taskType,
    required _i4.VerificationTaskStatus status,
    required String payload,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
  }) = _VerificationTaskImpl;

  factory VerificationTask.fromJson(Map<String, dynamic> jsonSerialization) {
    return VerificationTask(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      capability:
          _i2.CapabilityType.fromJson((jsonSerialization['capability'] as int)),
      taskType: _i3.VerificationTaskType.fromJson(
          (jsonSerialization['taskType'] as int)),
      status: _i4.VerificationTaskStatus.fromJson(
          (jsonSerialization['status'] as int)),
      payload: jsonSerialization['payload'] as String,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  _i2.CapabilityType capability;

  _i3.VerificationTaskType taskType;

  _i4.VerificationTaskStatus status;

  String payload;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? completedAt;

  /// Returns a shallow copy of this [VerificationTask]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  VerificationTask copyWith({
    int? id,
    int? userId,
    _i2.CapabilityType? capability,
    _i3.VerificationTaskType? taskType,
    _i4.VerificationTaskStatus? status,
    String? payload,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'capability': capability.toJson(),
      'taskType': taskType.toJson(),
      'status': status.toJson(),
      'payload': payload,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VerificationTaskImpl extends VerificationTask {
  _VerificationTaskImpl({
    int? id,
    required int userId,
    required _i2.CapabilityType capability,
    required _i3.VerificationTaskType taskType,
    required _i4.VerificationTaskStatus status,
    required String payload,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
  }) : super._(
          id: id,
          userId: userId,
          capability: capability,
          taskType: taskType,
          status: status,
          payload: payload,
          createdAt: createdAt,
          updatedAt: updatedAt,
          completedAt: completedAt,
        );

  /// Returns a shallow copy of this [VerificationTask]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  VerificationTask copyWith({
    Object? id = _Undefined,
    int? userId,
    _i2.CapabilityType? capability,
    _i3.VerificationTaskType? taskType,
    _i4.VerificationTaskStatus? status,
    String? payload,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? completedAt = _Undefined,
  }) {
    return VerificationTask(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      capability: capability ?? this.capability,
      taskType: taskType ?? this.taskType,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
    );
  }
}
