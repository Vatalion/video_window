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

abstract class UserProfile implements _i1.SerializableModel {
  UserProfile._({
    this.id,
    required this.userId,
    this.username,
    this.fullName,
    this.bio,
    this.avatarUrl,
    this.profileData,
    required this.visibility,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile({
    int? id,
    required int userId,
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? profileData,
    required String visibility,
    required bool isVerified,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfileImpl;

  factory UserProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserProfile(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      username: jsonSerialization['username'] as String?,
      fullName: jsonSerialization['fullName'] as String?,
      bio: jsonSerialization['bio'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      profileData: jsonSerialization['profileData'] as String?,
      visibility: jsonSerialization['visibility'] as String,
      isVerified: jsonSerialization['isVerified'] as bool,
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

  String? username;

  String? fullName;

  String? bio;

  String? avatarUrl;

  String? profileData;

  String visibility;

  bool isVerified;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [UserProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserProfile copyWith({
    int? id,
    int? userId,
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? profileData,
    String? visibility,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      if (username != null) 'username': username,
      if (fullName != null) 'fullName': fullName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (profileData != null) 'profileData': profileData,
      'visibility': visibility,
      'isVerified': isVerified,
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

class _UserProfileImpl extends UserProfile {
  _UserProfileImpl({
    int? id,
    required int userId,
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? profileData,
    required String visibility,
    required bool isVerified,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
          id: id,
          userId: userId,
          username: username,
          fullName: fullName,
          bio: bio,
          avatarUrl: avatarUrl,
          profileData: profileData,
          visibility: visibility,
          isVerified: isVerified,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Returns a shallow copy of this [UserProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserProfile copyWith({
    Object? id = _Undefined,
    int? userId,
    Object? username = _Undefined,
    Object? fullName = _Undefined,
    Object? bio = _Undefined,
    Object? avatarUrl = _Undefined,
    Object? profileData = _Undefined,
    String? visibility,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      username: username is String? ? username : this.username,
      fullName: fullName is String? ? fullName : this.fullName,
      bio: bio is String? ? bio : this.bio,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      profileData: profileData is String? ? profileData : this.profileData,
      visibility: visibility ?? this.visibility,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
