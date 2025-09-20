import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../enums/segment_transition_type.dart';
import '../enums/timeline_track_type.dart';
import 'text_overlay_settings.dart';

class TimelineSegment extends Equatable {
  TimelineSegment({
    String? id,
    required this.title,
    required this.description,
    required this.duration,
    required this.trackType,
    this.overlaySettings = const TextOverlaySettings(),
    this.captions = const [],
    this.transition = SegmentTransitionType.none,
    this.transitionDuration = const Duration(milliseconds: 400),
  }) : assert(!duration.isNegative && duration > Duration.zero),
       id = id ?? const Uuid().v4();

  final String id;
  final String title;
  final String description;
  final Duration duration;
  final TimelineTrackType trackType;
  final TextOverlaySettings overlaySettings;
  final List<CaptionBlock> captions;
  final SegmentTransitionType transition;
  final Duration transitionDuration;

  TimelineSegment copyWith({
    String? id,
    String? title,
    String? description,
    Duration? duration,
    TimelineTrackType? trackType,
    TextOverlaySettings? overlaySettings,
    List<CaptionBlock>? captions,
    SegmentTransitionType? transition,
    Duration? transitionDuration,
  }) {
    return TimelineSegment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      trackType: trackType ?? this.trackType,
      overlaySettings: overlaySettings ?? this.overlaySettings,
      captions: captions ?? this.captions,
      transition: transition ?? this.transition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    duration,
    trackType,
    overlaySettings,
    captions,
    transition,
    transitionDuration,
  ];

  Duration get totalDuration => duration + transitionDuration;
}
