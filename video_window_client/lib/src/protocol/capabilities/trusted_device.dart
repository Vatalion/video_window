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

abstract class TrustedDevice implements _i1.SerializableModel {
  TrustedDevice._({
    this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceType,
    required this.platform,
    required this.trustScore,
    required this.telemetry,
    required this.lastSeenAt,
    required this.createdAt,
    this.revokedAt,
  });

  factory TrustedDevice({
    int? id,
    required int userId,
    required String deviceId,
    required String deviceType,
    required String platform,
    required double trustScore,
    required String telemetry,
    required DateTime lastSeenAt,
    required DateTime createdAt,
    DateTime? revokedAt,
  }) = _TrustedDeviceImpl;

  factory TrustedDevice.fromJson(Map<String, dynamic> jsonSerialization) {
    return TrustedDevice(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      deviceId: jsonSerialization['deviceId'] as String,
      deviceType: jsonSerialization['deviceType'] as String,
      platform: jsonSerialization['platform'] as String,
      trustScore: (jsonSerialization['trustScore'] as num).toDouble(),
      telemetry: jsonSerialization['telemetry'] as String,
      lastSeenAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastSeenAt']),
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
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

  String deviceId;

  String deviceType;

  String platform;

  double trustScore;

  String telemetry;

  DateTime lastSeenAt;

  DateTime createdAt;

  DateTime? revokedAt;

  /// Returns a shallow copy of this [TrustedDevice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TrustedDevice copyWith({
    int? id,
    int? userId,
    String? deviceId,
    String? deviceType,
    String? platform,
    double? trustScore,
    String? telemetry,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    DateTime? revokedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'deviceId': deviceId,
      'deviceType': deviceType,
      'platform': platform,
      'trustScore': trustScore,
      'telemetry': telemetry,
      'lastSeenAt': lastSeenAt.toJson(),
      'createdAt': createdAt.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TrustedDeviceImpl extends TrustedDevice {
  _TrustedDeviceImpl({
    int? id,
    required int userId,
    required String deviceId,
    required String deviceType,
    required String platform,
    required double trustScore,
    required String telemetry,
    required DateTime lastSeenAt,
    required DateTime createdAt,
    DateTime? revokedAt,
  }) : super._(
          id: id,
          userId: userId,
          deviceId: deviceId,
          deviceType: deviceType,
          platform: platform,
          trustScore: trustScore,
          telemetry: telemetry,
          lastSeenAt: lastSeenAt,
          createdAt: createdAt,
          revokedAt: revokedAt,
        );

  /// Returns a shallow copy of this [TrustedDevice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TrustedDevice copyWith({
    Object? id = _Undefined,
    int? userId,
    String? deviceId,
    String? deviceType,
    String? platform,
    double? trustScore,
    String? telemetry,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    Object? revokedAt = _Undefined,
  }) {
    return TrustedDevice(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      platform: platform ?? this.platform,
      trustScore: trustScore ?? this.trustScore,
      telemetry: telemetry ?? this.telemetry,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
    );
  }
}
