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
  final String? paginationError; // AC3: Error message for pagination failures
  final Map<String, bool> videoPlaybackStates; // videoId -> isPlaying
  final String? currentVisibleVideoId;
  final Map<String, bool> likedVideos; // videoId -> isLiked
  final Map<String, bool> wishlistedVideos; // videoId -> isInWishlist
  final bool isBatterySaverMode; // AC5: Battery saver mode state

  const FeedLoaded({
    required this.videos,
    this.nextCursor,
    required this.hasMore,
    this.isLoadingMore = false,
    this.paginationError,
    this.videoPlaybackStates = const {},
    this.currentVisibleVideoId,
    this.likedVideos = const {},
    this.wishlistedVideos = const {},
    this.isBatterySaverMode = false, // AC5: Default to false
  });

  FeedLoaded copyWith({
    List<Video>? videos,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
    String? paginationError,
    Map<String, bool>? videoPlaybackStates,
    String? currentVisibleVideoId,
    Map<String, bool>? likedVideos,
    Map<String, bool>? wishlistedVideos,
    bool? isBatterySaverMode,
  }) {
    return FeedLoaded(
      videos: videos ?? this.videos,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationError: paginationError ?? this.paginationError,
      videoPlaybackStates: videoPlaybackStates ?? this.videoPlaybackStates,
      currentVisibleVideoId:
          currentVisibleVideoId ?? this.currentVisibleVideoId,
      likedVideos: likedVideos ?? this.likedVideos,
      wishlistedVideos: wishlistedVideos ?? this.wishlistedVideos,
      isBatterySaverMode: isBatterySaverMode ?? this.isBatterySaverMode,
    );
  }

  bool isLiked(String videoId) => likedVideos[videoId] ?? false;
  bool isWishlisted(String videoId) => wishlistedVideos[videoId] ?? false;

  @override
  List<Object?> get props => [
        videos,
        nextCursor,
        hasMore,
        isLoadingMore,
        paginationError,
        videoPlaybackStates,
        currentVisibleVideoId,
        likedVideos,
        wishlistedVideos,
        isBatterySaverMode,
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
