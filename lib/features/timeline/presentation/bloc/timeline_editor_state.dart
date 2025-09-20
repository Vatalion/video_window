import 'package:equatable/equatable.dart';

import '../../domain/entities/timeline_segment.dart';
import '../../domain/entities/timeline_track.dart';
import '../../domain/enums/timeline_track_type.dart';

enum TimelinePlaybackStatus { stopped, playing, paused }

class TimelineEditorState extends Equatable {
  const TimelineEditorState({
    required this.tracks,
    this.currentPosition = Duration.zero,
    this.playbackStatus = TimelinePlaybackStatus.stopped,
    this.zoomLevel = 1.0,
    this.selectedSegmentId,
  });

  final List<TimelineTrack> tracks;
  final Duration currentPosition;
  final TimelinePlaybackStatus playbackStatus;
  final double zoomLevel;
  final String? selectedSegmentId;

  TimelineEditorState copyWith({
    List<TimelineTrack>? tracks,
    Duration? currentPosition,
    TimelinePlaybackStatus? playbackStatus,
    double? zoomLevel,
    String? selectedSegmentId,
  }) {
    return TimelineEditorState(
      tracks: tracks ?? this.tracks,
      currentPosition: currentPosition ?? this.currentPosition,
      playbackStatus: playbackStatus ?? this.playbackStatus,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      selectedSegmentId: selectedSegmentId ?? this.selectedSegmentId,
    );
  }

  TimelineTrack getTrack(TimelineTrackType type) {
    return tracks.firstWhere((track) => track.type == type);
  }

  Duration get totalTimelineDuration {
    final videoTrack = tracks.firstWhere(
      (t) => t.type == TimelineTrackType.video,
      orElse: () =>
          const TimelineTrack(type: TimelineTrackType.video, segments: []),
    );
    return videoTrack.totalDuration;
  }

  TimelineSegment? get selectedSegment {
    if (selectedSegmentId == null) {
      return null;
    }

    for (final track in tracks) {
      for (final segment in track.segments) {
        if (segment.id == selectedSegmentId) {
          return segment;
        }
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
    tracks,
    currentPosition,
    playbackStatus,
    zoomLevel,
    selectedSegmentId,
  ];
}
