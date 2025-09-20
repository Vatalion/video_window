import 'package:equatable/equatable.dart';

import '../enums/timeline_track_type.dart';
import 'timeline_segment.dart';

class TimelineTrack extends Equatable {
  const TimelineTrack({
    required this.type,
    required this.segments,
    this.isLocked = false,
    this.isVisible = true,
  });

  final TimelineTrackType type;
  final List<TimelineSegment> segments;
  final bool isLocked;
  final bool isVisible;

  TimelineTrack copyWith({
    List<TimelineSegment>? segments,
    bool? isLocked,
    bool? isVisible,
  }) {
    return TimelineTrack(
      type: type,
      segments: segments ?? this.segments,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Duration get totalDuration => segments.fold(
    Duration.zero,
    (total, segment) => total + segment.totalDuration,
  );

  @override
  List<Object?> get props => [type, segments, isLocked, isVisible];
}
