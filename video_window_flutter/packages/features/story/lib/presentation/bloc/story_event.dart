import 'package:equatable/equatable.dart';
import '../../domain/entities/video_player_state.dart';

/// Base class for story events
abstract class StoryEvent extends Equatable {
  const StoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load story details
class StoryLoadRequested extends StoryEvent {
  final String storyId;
  final String source;

  const StoryLoadRequested({
    required this.storyId,
    required this.source,
  });

  @override
  List<Object?> get props => [storyId, source];
}

/// Event to request video playback
class VideoPlayRequested extends StoryEvent {
  final String mediaId;
  final VideoQuality quality;

  const VideoPlayRequested({
    required this.mediaId,
    required this.quality,
  });

  @override
  List<Object?> get props => [mediaId, quality];
}

/// Event for section navigation
class SectionNavigated extends StoryEvent {
  final String sectionId;

  const SectionNavigated(this.sectionId);

  @override
  List<Object?> get props => [sectionId];
}

/// Event to share story
class StoryShareRequested extends StoryEvent {
  final String channel;
  final String? customMessage;

  const StoryShareRequested({
    required this.channel,
    this.customMessage,
  });

  @override
  List<Object?> get props => [channel, customMessage];
}

/// Event to toggle like
class StoryToggleLike extends StoryEvent {
  const StoryToggleLike();
}

/// Event to toggle save/wishlist
class StoryToggleSave extends StoryEvent {
  final String ctaSurface;

  const StoryToggleSave({required this.ctaSurface});

  @override
  List<Object?> get props => [ctaSurface];
}

/// Event to follow maker
class StoryFollowMaker extends StoryEvent {
  const StoryFollowMaker();
}
