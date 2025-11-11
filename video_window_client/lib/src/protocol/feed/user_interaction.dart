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

abstract class UserInteraction implements _i1.SerializableModel {
  UserInteraction._({
    this.id,
    required this.userId,
    required this.videoId,
    required this.interactionType,
    this.watchTimeSeconds,
    this.metadata,
    required this.createdAt,
  });

  factory UserInteraction({
    int? id,
    required int userId,
    required String videoId,
    required String interactionType,
    int? watchTimeSeconds,
    String? metadata,
    required DateTime createdAt,
  }) = _UserInteractionImpl;

  factory UserInteraction.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserInteraction(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      videoId: jsonSerialization['videoId'] as String,
      interactionType: jsonSerialization['interactionType'] as String,
      watchTimeSeconds: jsonSerialization['watchTimeSeconds'] as int?,
      metadata: jsonSerialization['metadata'] as String?,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  String videoId;

  String interactionType;

  int? watchTimeSeconds;

  String? metadata;

  DateTime createdAt;

  /// Returns a shallow copy of this [UserInteraction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserInteraction copyWith({
    int? id,
    int? userId,
    String? videoId,
    String? interactionType,
    int? watchTimeSeconds,
    String? metadata,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'videoId': videoId,
      'interactionType': interactionType,
      if (watchTimeSeconds != null) 'watchTimeSeconds': watchTimeSeconds,
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserInteractionImpl extends UserInteraction {
  _UserInteractionImpl({
    int? id,
    required int userId,
    required String videoId,
    required String interactionType,
    int? watchTimeSeconds,
    String? metadata,
    required DateTime createdAt,
  }) : super._(
          id: id,
          userId: userId,
          videoId: videoId,
          interactionType: interactionType,
          watchTimeSeconds: watchTimeSeconds,
          metadata: metadata,
          createdAt: createdAt,
        );

  /// Returns a shallow copy of this [UserInteraction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserInteraction copyWith({
    Object? id = _Undefined,
    int? userId,
    String? videoId,
    String? interactionType,
    Object? watchTimeSeconds = _Undefined,
    Object? metadata = _Undefined,
    DateTime? createdAt,
  }) {
    return UserInteraction(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      videoId: videoId ?? this.videoId,
      interactionType: interactionType ?? this.interactionType,
      watchTimeSeconds:
          watchTimeSeconds is int? ? watchTimeSeconds : this.watchTimeSeconds,
      metadata: metadata is String? ? metadata : this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
