import 'package:equatable/equatable.dart';
import '../../domain/entities/share_response.dart';
import '../../domain/entities/story.dart';
import '../../domain/entities/video_player_state.dart';

/// Base class for story states
abstract class StoryState extends Equatable {
  const StoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class StoryInitial extends StoryState {
  const StoryInitial();
}

/// Loading state
class StoryLoading extends StoryState {
  const StoryLoading();
}

/// Loaded state with story data
class StoryLoaded extends StoryState {
  final ArtifactStory story;
  final VideoPlayerStateEntity? videoState;
  final String activeSection;
  final bool isLiked;
  final bool isSaved;
  final String? wishlistId;
  final bool isFollowingMaker;

  const StoryLoaded({
    required this.story,
    this.videoState,
    this.activeSection = 'overview',
    this.isLiked = false,
    this.isSaved = false,
    this.wishlistId,
    this.isFollowingMaker = false,
  });

  StoryLoaded copyWith({
    ArtifactStory? story,
    VideoPlayerStateEntity? videoState,
    String? activeSection,
    bool? isLiked,
    bool? isSaved,
    String? wishlistId,
    bool? isFollowingMaker,
  }) {
    return StoryLoaded(
      story: story ?? this.story,
      videoState: videoState ?? this.videoState,
      activeSection: activeSection ?? this.activeSection,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      wishlistId: wishlistId ?? this.wishlistId,
      isFollowingMaker: isFollowingMaker ?? this.isFollowingMaker,
    );
  }

  @override
  List<Object?> get props => [
        story,
        videoState,
        activeSection,
        isLiked,
        isSaved,
        wishlistId,
        isFollowingMaker,
      ];
}

/// Error state
class StoryError extends StoryState {
  final String message;
  final StoryErrorType type;

  const StoryError({
    required this.message,
    required this.type,
  });

  @override
  List<Object?> get props => [message, type];
}

/// State indicating that a shareable deep link is ready
class StoryShareReady extends StoryState {
  final ShareResponse shareResponse;

  const StoryShareReady(this.shareResponse);

  @override
  List<Object?> get props => [shareResponse];
}

/// Story error types
enum StoryErrorType {
  videoLoad,
  network,
  contentProtection,
  authentication,
  notFound,
}
