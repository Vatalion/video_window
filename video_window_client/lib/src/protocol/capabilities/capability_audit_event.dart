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

abstract class CapabilityAuditEvent implements _i1.SerializableModel {
  CapabilityAuditEvent._({
    this.id,
    required this.userId,
    required this.eventType,
    this.capability,
    this.entryPoint,
    this.deviceFingerprint,
    required this.metadata,
    required this.createdAt,
  });

  factory CapabilityAuditEvent({
    int? id,
    required int userId,
    required String eventType,
    _i2.CapabilityType? capability,
    String? entryPoint,
    String? deviceFingerprint,
    required String metadata,
    required DateTime createdAt,
  }) = _CapabilityAuditEventImpl;

  factory CapabilityAuditEvent.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return CapabilityAuditEvent(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      eventType: jsonSerialization['eventType'] as String,
      capability: jsonSerialization['capability'] == null
          ? null
          : _i2.CapabilityType.fromJson(
              (jsonSerialization['capability'] as int)),
      entryPoint: jsonSerialization['entryPoint'] as String?,
      deviceFingerprint: jsonSerialization['deviceFingerprint'] as String?,
      metadata: jsonSerialization['metadata'] as String,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  String eventType;

  _i2.CapabilityType? capability;

  String? entryPoint;

  String? deviceFingerprint;

  String metadata;

  DateTime createdAt;

  /// Returns a shallow copy of this [CapabilityAuditEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CapabilityAuditEvent copyWith({
    int? id,
    int? userId,
    String? eventType,
    _i2.CapabilityType? capability,
    String? entryPoint,
    String? deviceFingerprint,
    String? metadata,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'eventType': eventType,
      if (capability != null) 'capability': capability?.toJson(),
      if (entryPoint != null) 'entryPoint': entryPoint,
      if (deviceFingerprint != null) 'deviceFingerprint': deviceFingerprint,
      'metadata': metadata,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CapabilityAuditEventImpl extends CapabilityAuditEvent {
  _CapabilityAuditEventImpl({
    int? id,
    required int userId,
    required String eventType,
    _i2.CapabilityType? capability,
    String? entryPoint,
    String? deviceFingerprint,
    required String metadata,
    required DateTime createdAt,
  }) : super._(
          id: id,
          userId: userId,
          eventType: eventType,
          capability: capability,
          entryPoint: entryPoint,
          deviceFingerprint: deviceFingerprint,
          metadata: metadata,
          createdAt: createdAt,
        );

  /// Returns a shallow copy of this [CapabilityAuditEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CapabilityAuditEvent copyWith({
    Object? id = _Undefined,
    int? userId,
    String? eventType,
    Object? capability = _Undefined,
    Object? entryPoint = _Undefined,
    Object? deviceFingerprint = _Undefined,
    String? metadata,
    DateTime? createdAt,
  }) {
    return CapabilityAuditEvent(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      eventType: eventType ?? this.eventType,
      capability:
          capability is _i2.CapabilityType? ? capability : this.capability,
      entryPoint: entryPoint is String? ? entryPoint : this.entryPoint,
      deviceFingerprint: deviceFingerprint is String?
          ? deviceFingerprint
          : this.deviceFingerprint,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
