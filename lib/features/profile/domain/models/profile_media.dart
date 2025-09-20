enum ProfileMediaType { photo, cover }

class ProfileMedia {
  final String userId;
  final ProfileMediaType mediaType;
  final String mediaUrl;
  final DateTime uploadedAt;

  ProfileMedia({
    required this.userId,
    required this.mediaType,
    required this.mediaUrl,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'mediaType': mediaType.name,
      'mediaUrl': mediaUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory ProfileMedia.fromJson(Map<String, dynamic> json) {
    return ProfileMedia(
      userId: json['userId'] as String,
      mediaType: ProfileMediaType.values.firstWhere(
        (e) => e.name == json['mediaType'],
        orElse: () => ProfileMediaType.photo,
      ),
      mediaUrl: json['mediaUrl'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
}