import 'package:equatable/equatable.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/video_interaction.dart';

/// Events for feed BLoC
abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

/// Load initial feed
class FeedLoadInitial extends FeedEvent {
  const FeedLoadInitial();
}

/// Load next page of feed
class FeedLoadNextPage extends FeedEvent {
  const FeedLoadNextPage();
}

/// Refresh feed
class FeedRefresh extends FeedEvent {
  const FeedRefresh();
}

/// Video interaction event
class FeedVideoInteraction extends FeedEvent {
  final String videoId;
  final InteractionType type;
  final Duration? watchTime;
  final Map<String, dynamic>? metadata;

  const FeedVideoInteraction({
    required this.videoId,
    required this.type,
    this.watchTime,
    this.metadata,
  });

  @override
  List<Object?> get props => [videoId, type, watchTime, metadata];
}

/// Video visibility changed (for auto-play)
class FeedVideoVisibilityChanged extends FeedEvent {
  final String videoId;
  final bool isVisible;
  final double visibilityPercentage;

  const FeedVideoVisibilityChanged({
    required this.videoId,
    required this.isVisible,
    required this.visibilityPercentage,
  });

  @override
  List<Object?> get props => [videoId, isVisible, visibilityPercentage];
}

/// Video playback state changed
class FeedVideoPlaybackStateChanged extends FeedEvent {
  final String videoId;
  final bool isPlaying;

  const FeedVideoPlaybackStateChanged({
    required this.videoId,
    required this.isPlaying,
  });

  @override
  List<Object?> get props => [videoId, isPlaying];
}

/// Toggle like status for a video
class FeedToggleLike extends FeedEvent {
  final String videoId;
  final bool isLiked;

  const FeedToggleLike({
    required this.videoId,
    required this.isLiked,
  });

  @override
  List<Object?> get props => [videoId, isLiked];
}

/// Toggle wishlist status for a video
class FeedToggleWishlist extends FeedEvent {
  final String videoId;
  final bool isInWishlist;

  const FeedToggleWishlist({
    required this.videoId,
    required this.isInWishlist,
  });

  @override
  List<Object?> get props => [videoId, isInWishlist];
}
