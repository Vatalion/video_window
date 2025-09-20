import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/text_overlay_settings.dart';
import '../../domain/entities/timeline_segment.dart';
import '../../domain/entities/timeline_track.dart';
import '../../domain/enums/segment_transition_type.dart';
import '../../domain/enums/timeline_track_type.dart';
import 'timeline_editor_state.dart';

class TimelineEditorCubit extends Cubit<TimelineEditorState> {
  TimelineEditorCubit()
    : super(
        TimelineEditorState(tracks: _createInitialTracks(), zoomLevel: 1.0),
      );

  static List<TimelineTrack> _createInitialTracks() {
    final introCaptions = [
      CaptionBlock(
        id: 'caption-intro-1',
        start: const Duration(seconds: 0),
        end: const Duration(seconds: 6),
        text: 'Welcome to your craft timeline! Let\'s outline your steps.',
      ),
    ];

    final stepOneOverlay = TextOverlaySettings(
      content: 'Step 1: Gather materials',
      fontSize: 20,
      alignment: OverlayTextAlignment.left,
      animation: OverlayTextAnimation.fadeIn,
      isBold: true,
    );

    final introSegment = TimelineSegment(
      id: 'segment-intro',
      title: 'Introduction',
      description: 'Set the stage for the tutorial and overview the project.',
      duration: const Duration(seconds: 15),
      trackType: TimelineTrackType.video,
      overlaySettings: stepOneOverlay,
      captions: introCaptions,
      transition: SegmentTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 600),
    );

    final prepSegment = TimelineSegment(
      id: 'segment-prep',
      title: 'Preparation',
      description: 'Showcase tools and materials with guided narration.',
      duration: const Duration(seconds: 20),
      trackType: TimelineTrackType.video,
      overlaySettings: const TextOverlaySettings(
        content: 'Step 2: Prepare your workspace',
        fontSize: 18,
        alignment: OverlayTextAlignment.center,
        animation: OverlayTextAnimation.slideUp,
      ),
      captions: [
        CaptionBlock(
          id: 'caption-prep-1',
          start: const Duration(seconds: 0),
          end: const Duration(seconds: 8),
          text: 'Lay out materials in frame and ensure good lighting.',
        ),
      ],
      transition: SegmentTransitionType.crossFade,
      transitionDuration: const Duration(milliseconds: 500),
    );

    final demoSegment = TimelineSegment(
      id: 'segment-demo',
      title: 'Demonstration',
      description: 'Record the main crafting process with close-up shots.',
      duration: const Duration(seconds: 35),
      trackType: TimelineTrackType.video,
      overlaySettings: const TextOverlaySettings(
        content: 'Step 3: Follow along',
        fontSize: 18,
        isItalic: true,
        alignment: OverlayTextAlignment.center,
      ),
      captions: [
        CaptionBlock(
          id: 'caption-demo-1',
          start: const Duration(seconds: 0),
          end: const Duration(seconds: 10),
          text: 'Keep steady hands and emphasize critical movements.',
        ),
        CaptionBlock(
          id: 'caption-demo-2',
          start: const Duration(seconds: 12),
          end: const Duration(seconds: 24),
          text: 'Explain why each step matters to the final result.',
        ),
      ],
      transition: SegmentTransitionType.slide,
      transitionDuration: const Duration(milliseconds: 400),
    );

    final outroSegment = TimelineSegment(
      id: 'segment-outro',
      title: 'Wrap-up',
      description: 'Summarize learnings and prompt next steps.',
      duration: const Duration(seconds: 12),
      trackType: TimelineTrackType.video,
      overlaySettings: const TextOverlaySettings(
        content: 'Final Step: Recap & share',
        fontSize: 18,
        alignment: OverlayTextAlignment.right,
        animation: OverlayTextAnimation.typewriter,
      ),
      captions: [
        CaptionBlock(
          id: 'caption-outro-1',
          start: const Duration(seconds: 0),
          end: const Duration(seconds: 6),
          text: 'Highlight the finished craft and encourage sharing.',
        ),
      ],
      transition: SegmentTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 500),
    );

    final audioTrack = TimelineTrack(
      type: TimelineTrackType.audio,
      segments: [
        TimelineSegment(
          id: 'audio-theme',
          title: 'Theme music',
          description: 'Light background loop for the tutorial.',
          duration: const Duration(seconds: 45),
          trackType: TimelineTrackType.audio,
          transition: SegmentTransitionType.crossFade,
          transitionDuration: const Duration(milliseconds: 400),
        ),
        TimelineSegment(
          id: 'audio-outro',
          title: 'Outro sting',
          description: 'Punchy finish to reinforce the brand.',
          duration: const Duration(seconds: 8),
          trackType: TimelineTrackType.audio,
          transition: SegmentTransitionType.fade,
          transitionDuration: const Duration(milliseconds: 250),
        ),
      ],
    );

    final textTrack = TimelineTrack(
      type: TimelineTrackType.text,
      segments: [
        TimelineSegment(
          id: 'text-intro',
          title: 'Introduction overlay',
          description: 'Display the project name and creator handle.',
          duration: const Duration(seconds: 10),
          trackType: TimelineTrackType.text,
          overlaySettings: const TextOverlaySettings(
            content: 'Craft Tutorial: Hand-stitched leather wallet',
            fontSize: 22,
            isBold: true,
          ),
        ),
        TimelineSegment(
          id: 'text-cta',
          title: 'Call to action',
          description: 'Encourage sharing and subscriptions.',
          duration: const Duration(seconds: 12),
          trackType: TimelineTrackType.text,
          overlaySettings: const TextOverlaySettings(
            content: 'Share your creation with #VideoWindowCrafts',
            fontSize: 18,
            isBold: true,
            isUnderline: true,
          ),
        ),
      ],
    );

    final videoTrack = TimelineTrack(
      type: TimelineTrackType.video,
      segments: [introSegment, prepSegment, demoSegment, outroSegment],
    );

    return [videoTrack, audioTrack, textTrack];
  }

  void selectSegment(String? segmentId) {
    emit(state.copyWith(selectedSegmentId: segmentId));
  }

  void reorderSegment(TimelineTrackType trackType, int oldIndex, int newIndex) {
    final track = state.getTrack(trackType);
    if (track.isLocked || track.segments.length < 2) {
      return;
    }

    final segments = List<TimelineSegment>.from(track.segments);
    final segment = segments.removeAt(oldIndex);
    final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    segments.insert(adjustedIndex, segment);

    final updatedTrack = track.copyWith(segments: segments);
    emit(state.copyWith(tracks: _replaceTrack(trackType, updatedTrack)));
  }

  void updateSegmentDuration(String segmentId, Duration duration) {
    _updateSegment(
      segmentId,
      (segment) => segment.copyWith(duration: duration),
    );
  }

  void updateSegmentTitle(String segmentId, String title) {
    if (title.trim().isEmpty) {
      return;
    }
    _updateSegment(
      segmentId,
      (segment) => segment.copyWith(title: title.trim()),
    );
  }

  void updateSegmentDescription(String segmentId, String description) {
    _updateSegment(
      segmentId,
      (segment) => segment.copyWith(description: description.trim()),
    );
  }

  void updateTransition(String segmentId, SegmentTransitionType transition) {
    _updateSegment(
      segmentId,
      (segment) => segment.copyWith(transition: transition),
    );
  }

  void updateTransitionDuration(String segmentId, Duration duration) {
    _updateSegment(
      segmentId,
      (segment) => segment.copyWith(transitionDuration: duration),
    );
  }

  void updateOverlaySettings(String segmentId, TextOverlaySettings settings) {
    _updateSegment(
      segmentId,
      (segment) => segment.copyWith(overlaySettings: settings),
    );
  }

  void toggleOverlayStyle(
    String segmentId, {
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
  }) {
    _updateSegment(
      segmentId,
      (segment) => segment.copyWith(
        overlaySettings: segment.overlaySettings.copyWith(
          isBold: isBold ?? segment.overlaySettings.isBold,
          isItalic: isItalic ?? segment.overlaySettings.isItalic,
          isUnderline: isUnderline ?? segment.overlaySettings.isUnderline,
        ),
      ),
    );
  }

  void updateOverlayFontSize(String segmentId, double fontSize) {
    _updateSegment(
      segmentId,
      (segment) => segment.copyWith(
        overlaySettings: segment.overlaySettings.copyWith(fontSize: fontSize),
      ),
    );
  }

  void updateOverlayAlignment(
    String segmentId,
    OverlayTextAlignment alignment,
  ) {
    _updateSegment(
      segmentId,
      (segment) => segment.copyWith(
        overlaySettings: segment.overlaySettings.copyWith(alignment: alignment),
      ),
    );
  }

  void updateOverlayAnimation(
    String segmentId,
    OverlayTextAnimation animation,
  ) {
    _updateSegment(
      segmentId,
      (segment) => segment.copyWith(
        overlaySettings: segment.overlaySettings.copyWith(animation: animation),
      ),
    );
  }

  void addCaption(String segmentId) {
    _updateSegment(segmentId, (segment) {
      final captions = List<CaptionBlock>.from(segment.captions);
      final start = captions.isEmpty ? Duration.zero : captions.last.end;
      final end = start + const Duration(seconds: 4);
      captions.add(
        CaptionBlock(
          id: 'caption-${segment.id}-${captions.length + 1}',
          start: start,
          end: end,
          text: 'New caption',
        ),
      );
      return segment.copyWith(captions: captions);
    });
  }

  void updateCaption(
    String segmentId,
    String captionId, {
    Duration? start,
    Duration? end,
    String? text,
  }) {
    _updateSegment(segmentId, (segment) {
      final captions = segment.captions.map((caption) {
        if (caption.id != captionId) {
          return caption;
        }
        final updatedStart = start ?? caption.start;
        final updatedEnd = end ?? caption.end;
        final normalisedEnd = updatedEnd < updatedStart
            ? updatedStart
            : updatedEnd;
        return caption.copyWith(
          start: updatedStart,
          end: normalisedEnd,
          text: text ?? caption.text,
        );
      }).toList();
      return segment.copyWith(captions: captions);
    });
  }

  void removeCaption(String segmentId, String captionId) {
    _updateSegment(segmentId, (segment) {
      final captions = segment.captions
          .where((caption) => caption.id != captionId)
          .toList();
      return segment.copyWith(captions: captions);
    });
  }

  void toggleTrackVisibility(TimelineTrackType trackType) {
    final track = state.getTrack(trackType);
    final updatedTrack = track.copyWith(isVisible: !track.isVisible);
    emit(state.copyWith(tracks: _replaceTrack(trackType, updatedTrack)));
  }

  void toggleTrackLock(TimelineTrackType trackType) {
    final track = state.getTrack(trackType);
    final updatedTrack = track.copyWith(isLocked: !track.isLocked);
    emit(state.copyWith(tracks: _replaceTrack(trackType, updatedTrack)));
  }

  void updateZoomLevel(double zoomLevel) {
    final clamped = zoomLevel.clamp(0.5, 3.0);
    emit(state.copyWith(zoomLevel: clamped.toDouble()));
  }

  void updatePlaybackStatus(TimelinePlaybackStatus status) {
    emit(state.copyWith(playbackStatus: status));
  }

  void updateCurrentPosition(Duration position) {
    final clamped = position < Duration.zero
        ? Duration.zero
        : position > state.totalTimelineDuration
        ? state.totalTimelineDuration
        : position;
    emit(state.copyWith(currentPosition: clamped));
  }

  void _updateSegment(
    String segmentId,
    TimelineSegment Function(TimelineSegment segment) update,
  ) {
    final tracks = <TimelineTrack>[];
    for (final track in state.tracks) {
      final segments = <TimelineSegment>[];
      var modified = false;
      for (final segment in track.segments) {
        if (segment.id == segmentId) {
          segments.add(update(segment));
          modified = true;
        } else {
          segments.add(segment);
        }
      }
      tracks.add(modified ? track.copyWith(segments: segments) : track);
    }
    emit(state.copyWith(tracks: tracks));
  }

  List<TimelineTrack> _replaceTrack(
    TimelineTrackType targetType,
    TimelineTrack updatedTrack,
  ) {
    return state.tracks
        .map((track) => track.type == targetType ? updatedTrack : track)
        .toList(growable: false);
  }
}
