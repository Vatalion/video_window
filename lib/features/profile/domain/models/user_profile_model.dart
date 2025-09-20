import 'package:equatable/equatable.dart';

class UserProfileModel extends Equatable {
  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String? website;
  final String? location;
  final DateTime? birthDate;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final ProfileVisibility visibility;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfileModel({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.website,
    this.location,
    this.birthDate,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    this.visibility = ProfileVisibility.public,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      bio: json['bio'] as String?,
      website: json['website'] as String?,
      location: json['location'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      visibility: ProfileVisibility.values.firstWhere(
        (e) => e.name == json['visibility'],
        orElse: () => ProfileVisibility.public,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'bio': bio,
      'website': website,
      'location': location,
      'birth_date': birthDate?.toIso8601String(),
      'profile_photo_url': profilePhotoUrl,
      'cover_photo_url': coverPhotoUrl,
      'visibility': visibility.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? bio,
    String? website,
    String? location,
    DateTime? birthDate,
    String? profilePhotoUrl,
    String? coverPhotoUrl,
    ProfileVisibility? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      location: location ?? this.location,
      birthDate: birthDate ?? this.birthDate,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
        id,
        userId,
        displayName,
        bio ?? '',
        website ?? '',
        location ?? '',
        birthDate ?? '',
        profilePhotoUrl ?? '',
        coverPhotoUrl ?? '',
        visibility,
        createdAt,
        updatedAt,
      ];
}

enum ProfileVisibility {
  public,
  private,
  friendsOnly,
}

class ProfileMediaModel extends Equatable {
  final String id;
  final String userId;
  final ProfileMediaType type;
  final String mediaUrl;
  final int fileSize;
  final String? mimeType;
  final int? width;
  final int? height;
  final DateTime uploadedAt;

  const ProfileMediaModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.mediaUrl,
    required this.fileSize,
    this.mimeType,
    this.width,
    this.height,
    required this.uploadedAt,
  });

  factory ProfileMediaModel.fromJson(Map<String, dynamic> json) {
    return ProfileMediaModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: ProfileMediaType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ProfileMediaType.profilePhoto,
      ),
      mediaUrl: json['media_url'] as String,
      fileSize: json['file_size'] as int,
      mimeType: json['mime_type'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'media_url': mediaUrl,
      'file_size': fileSize,
      'mime_type': mimeType,
      'width': width,
      'height': height,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [
        id,
        userId,
        type,
        mediaUrl,
        fileSize,
        mimeType ?? '',
        width ?? '',
        height ?? '',
        uploadedAt,
      ];
}

enum ProfileMediaType {
  profilePhoto,
  coverPhoto,
}