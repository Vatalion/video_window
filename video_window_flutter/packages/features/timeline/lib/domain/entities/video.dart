le/equatable.dart';

/// Video entity representing a story/video in the feed
class Video extends Equatable {
  final String id;
  final String makerId;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final Duration duration;
  final int viewCount;
  final int likeCount;
  final List<String> tags;
  final VideoQuality quality;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final VideoMetadata metadata;

  const Video({
    required this.id,
    required this.makerId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.viewCount,
    required this.likeCount,
    required this.tags,
    required this.quality,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        makerId,
        title,
        description,
        videoUrl,
        thumbnailUrl,
        duration,
        viewCount,
        likeCount,
        tags,
        quality,
        createdAt,
        updatedAt,
        isActive,
        metadata,
      ];

  /// Create Video from JSON
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as String,
      makerId: json['makerId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      videoUrl: json['videoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      duration: Duration(seconds: json['durationSeconds'] as int),
      viewCount: json['viewCount'] as int,
      likeCount: json['likeCount'] as int,
      tags: List<String>.from(json['tags'] as List),
      quality: VideoQuality.values.firstWhere(
        (q) => q.name == json['quality'],
        orElse: () => VideoQuality.hd,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool,
      metadata:
          VideoMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }

  /// Convert Video to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'makerId': makerId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': duration.inSeconds,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'tags': tags,
      'quality': quality.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata.toJson(),
    };
  }
}

class VideoMetadata extends Equatable {
  final int width;
  final int height;
  final String format;
  final double aspectRatio;
  final List<VideoQuality> availableQualities;
  final bool hasCaptions;
  final Duration? thumbnailTime;

  const VideoMetadata({
    required this.width,
    required this.height,
    required this.format,
    required this.aspectRatio,
    required this.availableQualities,
    required this.hasCaptions,
    this.thumbnailTime,
  });

  @override
  List<Object?> get props => [
        width,
        height,
        format,
        aspectRatio,
        availableQualities,
        hasCaptions,
        thumbnailTime,
      ];

  /// Create VideoMetadata from JSON
  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      width: json['width'] as int,
      height: json['height'] as int,
      format: json['format'] as String,
      aspectRatio: json['aspectRatio'] as double,
      availableQualities: (json['availableQualities'] as List)
          .map((q) => VideoQuality.values.firstWhere(
                (vq) => vq.name == q,
                orElse: () => VideoQuality.hd,
              ))
          .toList(),
      hasCaptions: json['hasCaptions'] as bool,
      thumbnailTime: json['thumbnailTime'] != null
          ? Duration(seconds: json['thumbnailTime'] as int)
          : null,
    );
  }

  /// Convert VideoMetadata to JSON
  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'format': format,
      'aspectRatio': aspectRatio,
      'availableQualities': availableQualities.map((q) => q.name).toList(),
      'hasCaptions': hasCaptions,
      'thumbnailTime': thumbnailTime?.inSeconds,
    };
  }
}

enum VideoQuality {
  sd(360),
  hd(720),
  fhd(1080);

  const VideoQuality(this.height);
  final int height;
}
