import 'package:equatable/equatable.dart';
import '../../domain/entities/video.dart';

/// States for feed BLoC
abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FeedInitial extends FeedState {
  const FeedInitial();
}

/// Loading state
class FeedLoading extends FeedState {
  const FeedLoading();
}

/// Loaded state with videos
class FeedLoaded extends FeedState {
  final List<Video> videos;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final Map<String, bool> videoPlaybackStates; // videoId -> isPlaying
  final String? currentVisibleVideoId;

  const FeedLoaded({
    required this.videos,
    this.nextCursor,
    required this.hasMore,
    this.isLoadingMore = false,
    this.videoPlaybackStates = const {},
    this.currentVisibleVideoId,
  });

  FeedLoaded copyWith({
    List<Video>? videos,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
    Map<String, bool>? videoPlaybackStates,
    String? currentVisibleVideoId,
  }) {
    return FeedLoaded(
      videos: videos ?? this.videos,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      videoPlaybackStates: videoPlaybackStates ?? this.videoPlaybackStates,
      currentVisibleVideoId:
          currentVisibleVideoId ?? this.currentVisibleVideoId,
    );
  }

  @override
  List<Object?> get props => [
        videos,
        nextCursor,
        hasMore,
        isLoadingMore,
        videoPlaybackStates,
        currentVisibleVideoId,
      ];
}

/// Error state
class FeedError extends FeedState {
  final String message;
  final Exception? exception;

  const FeedError({
    required this.message,
    this.exception,
  });

  @override
  List<Object?> get props => [message, exception];
}
