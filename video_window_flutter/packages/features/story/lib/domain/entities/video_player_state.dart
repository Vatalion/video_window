import 'package:equatable/equatable.dart';

/// Video player state entity
class VideoPlayerStateEntity extends Equatable {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;
  final bool isFullscreen;
  final bool captionsEnabled;
  final VideoQuality quality;
  final String? errorMessage;

  const VideoPlayerStateEntity({
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.isBuffering,
    required this.isFullscreen,
    required this.captionsEnabled,
    required this.quality,
    this.errorMessage,
  });

  VideoPlayerStateEntity copyWith({
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isBuffering,
    bool? isFullscreen,
    bool? captionsEnabled,
    VideoQuality? quality,
    String? errorMessage,
  }) {
    return VideoPlayerStateEntity(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      captionsEnabled: captionsEnabled ?? this.captionsEnabled,
      quality: quality ?? this.quality,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        position,
        duration,
        isPlaying,
        isBuffering,
        isFullscreen,
        captionsEnabled,
        quality,
        errorMessage,
      ];
}

/// Video quality enum
enum VideoQuality {
  sd, // 360p
  hd, // 720p
  fhd, // 1080p
  uhd, // 4K
}
