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

abstract class UserSession implements _i1.SerializableModel {
  UserSession._({
    this.id,
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.deviceId,
    this.deviceInfo,
    required this.accessTokenExpiry,
    required this.refreshTokenExpiry,
    this.ipAddress,
    required this.isRevoked,
    this.revokedAt,
    required this.createdAt,
    required this.lastUsedAt,
  });

  factory UserSession({
    int? id,
    required int userId,
    required String accessToken,
    required String refreshToken,
    required String deviceId,
    String? deviceInfo,
    required DateTime accessTokenExpiry,
    required DateTime refreshTokenExpiry,
    String? ipAddress,
    required bool isRevoked,
    DateTime? revokedAt,
    required DateTime createdAt,
    required DateTime lastUsedAt,
  }) = _UserSessionImpl;

  factory UserSession.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserSession(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      accessToken: jsonSerialization['accessToken'] as String,
      refreshToken: jsonSerialization['refreshToken'] as String,
      deviceId: jsonSerialization['deviceId'] as String,
      deviceInfo: jsonSerialization['deviceInfo'] as String?,
      accessTokenExpiry: _i1.DateTimeJsonExtension.fromJson(
          jsonSerialization['accessTokenExpiry']),
      refreshTokenExpiry: _i1.DateTimeJsonExtension.fromJson(
          jsonSerialization['refreshTokenExpiry']),
      ipAddress: jsonSerialization['ipAddress'] as String?,
      isRevoked: jsonSerialization['isRevoked'] as bool,
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      lastUsedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastUsedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  String accessToken;

  String refreshToken;

  String deviceId;

  String? deviceInfo;

  DateTime accessTokenExpiry;

  DateTime refreshTokenExpiry;

  String? ipAddress;

  bool isRevoked;

  DateTime? revokedAt;

  DateTime createdAt;

  DateTime lastUsedAt;

  /// Returns a shallow copy of this [UserSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserSession copyWith({
    int? id,
    int? userId,
    String? accessToken,
    String? refreshToken,
    String? deviceId,
    String? deviceInfo,
    DateTime? accessTokenExpiry,
    DateTime? refreshTokenExpiry,
    String? ipAddress,
    bool? isRevoked,
    DateTime? revokedAt,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'deviceId': deviceId,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      'accessTokenExpiry': accessTokenExpiry.toJson(),
      'refreshTokenExpiry': refreshTokenExpiry.toJson(),
      if (ipAddress != null) 'ipAddress': ipAddress,
      'isRevoked': isRevoked,
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'lastUsedAt': lastUsedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserSessionImpl extends UserSession {
  _UserSessionImpl({
    int? id,
    required int userId,
    required String accessToken,
    required String refreshToken,
    required String deviceId,
    String? deviceInfo,
    required DateTime accessTokenExpiry,
    required DateTime refreshTokenExpiry,
    String? ipAddress,
    required bool isRevoked,
    DateTime? revokedAt,
    required DateTime createdAt,
    required DateTime lastUsedAt,
  }) : super._(
          id: id,
          userId: userId,
          accessToken: accessToken,
          refreshToken: refreshToken,
          deviceId: deviceId,
          deviceInfo: deviceInfo,
          accessTokenExpiry: accessTokenExpiry,
          refreshTokenExpiry: refreshTokenExpiry,
          ipAddress: ipAddress,
          isRevoked: isRevoked,
          revokedAt: revokedAt,
          createdAt: createdAt,
          lastUsedAt: lastUsedAt,
        );

  /// Returns a shallow copy of this [UserSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserSession copyWith({
    Object? id = _Undefined,
    int? userId,
    String? accessToken,
    String? refreshToken,
    String? deviceId,
    Object? deviceInfo = _Undefined,
    DateTime? accessTokenExpiry,
    DateTime? refreshTokenExpiry,
    Object? ipAddress = _Undefined,
    bool? isRevoked,
    Object? revokedAt = _Undefined,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return UserSession(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      deviceId: deviceId ?? this.deviceId,
      deviceInfo: deviceInfo is String? ? deviceInfo : this.deviceInfo,
      accessTokenExpiry: accessTokenExpiry ?? this.accessTokenExpiry,
      refreshTokenExpiry: refreshTokenExpiry ?? this.refreshTokenExpiry,
      ipAddress: ipAddress is String? ? ipAddress : this.ipAddress,
      isRevoked: isRevoked ?? this.isRevoked,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
