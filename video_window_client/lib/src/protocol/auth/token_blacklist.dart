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

abstract class TokenBlacklist implements _i1.SerializableModel {
  TokenBlacklist._({
    this.id,
    required this.tokenId,
    required this.tokenType,
    required this.userId,
    this.reason,
    required this.expiresAt,
    required this.blacklistedAt,
  });

  factory TokenBlacklist({
    int? id,
    required String tokenId,
    required String tokenType,
    required int userId,
    String? reason,
    required DateTime expiresAt,
    required DateTime blacklistedAt,
  }) = _TokenBlacklistImpl;

  factory TokenBlacklist.fromJson(Map<String, dynamic> jsonSerialization) {
    return TokenBlacklist(
      id: jsonSerialization['id'] as int?,
      tokenId: jsonSerialization['tokenId'] as String,
      tokenType: jsonSerialization['tokenType'] as String,
      userId: jsonSerialization['userId'] as int,
      reason: jsonSerialization['reason'] as String?,
      expiresAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      blacklistedAt: _i1.DateTimeJsonExtension.fromJson(
          jsonSerialization['blacklistedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String tokenId;

  String tokenType;

  int userId;

  String? reason;

  DateTime expiresAt;

  DateTime blacklistedAt;

  /// Returns a shallow copy of this [TokenBlacklist]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TokenBlacklist copyWith({
    int? id,
    String? tokenId,
    String? tokenType,
    int? userId,
    String? reason,
    DateTime? expiresAt,
    DateTime? blacklistedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tokenId': tokenId,
      'tokenType': tokenType,
      'userId': userId,
      if (reason != null) 'reason': reason,
      'expiresAt': expiresAt.toJson(),
      'blacklistedAt': blacklistedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TokenBlacklistImpl extends TokenBlacklist {
  _TokenBlacklistImpl({
    int? id,
    required String tokenId,
    required String tokenType,
    required int userId,
    String? reason,
    required DateTime expiresAt,
    required DateTime blacklistedAt,
  }) : super._(
          id: id,
          tokenId: tokenId,
          tokenType: tokenType,
          userId: userId,
          reason: reason,
          expiresAt: expiresAt,
          blacklistedAt: blacklistedAt,
        );

  /// Returns a shallow copy of this [TokenBlacklist]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TokenBlacklist copyWith({
    Object? id = _Undefined,
    String? tokenId,
    String? tokenType,
    int? userId,
    Object? reason = _Undefined,
    DateTime? expiresAt,
    DateTime? blacklistedAt,
  }) {
    return TokenBlacklist(
      id: id is int? ? id : this.id,
      tokenId: tokenId ?? this.tokenId,
      tokenType: tokenType ?? this.tokenType,
      userId: userId ?? this.userId,
      reason: reason is String? ? reason : this.reason,
      expiresAt: expiresAt ?? this.expiresAt,
      blacklistedAt: blacklistedAt ?? this.blacklistedAt,
    );
  }
}
