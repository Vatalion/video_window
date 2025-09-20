import 'package:test/test.dart';
import 'package:video_window/features/timeline/domain/entities/text_overlay_settings.dart';
import 'package:video_window/features/timeline/domain/enums/segment_transition_type.dart';
import 'package:video_window/features/timeline/domain/enums/timeline_track_type.dart';
import 'package:video_window/features/timeline/presentation/bloc/timeline_editor_cubit.dart';

void main() {
  group('TimelineEditorCubit', () {
    late TimelineEditorCubit cubit;

    setUp(() {
      cubit = TimelineEditorCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state exposes default tracks', () {
      expect(cubit.state.tracks.length, 3);
      expect(
        cubit.state.tracks.map((track) => track.type),
        containsAll(TimelineTrackType.values),
      );
    });

    test('selectSegment updates selectedSegmentId', () {
      final firstSegmentId = cubit.state.tracks.first.segments.first.id;

      cubit.selectSegment(firstSegmentId);

      expect(cubit.state.selectedSegmentId, firstSegmentId);
      expect(cubit.state.selectedSegment?.id, firstSegmentId);
    });

    test('reorderSegment reorders segments when unlocked', () {
      final track = cubit.state.tracks.firstWhere(
        (t) => t.type == TimelineTrackType.video,
      );
      final originalOrder = track.segments
          .map((segment) => segment.id)
          .toList();

      cubit.reorderSegment(TimelineTrackType.video, 0, 2);

      final updatedTrack = cubit.state.tracks.firstWhere(
        (t) => t.type == TimelineTrackType.video,
      );
      expect(updatedTrack.segments.first.id, originalOrder[1]);
    });

    test('updateSegmentDuration adjusts duration', () {
      final segment = cubit.state.tracks.first.segments.first;
      const newDuration = Duration(seconds: 42);

      cubit.updateSegmentDuration(segment.id, newDuration);

      expect(cubit.state.selectedSegment, isNull);
      final updatedSegment = cubit.state.tracks
          .firstWhere((t) => t.type == segment.trackType)
          .segments
          .firstWhere((s) => s.id == segment.id);
      expect(updatedSegment.duration, newDuration);
    });

    test('updateOverlaySettings updates overlay preferences', () {
      final segment = cubit.state.tracks.first.segments.first;
      const settings = TextOverlaySettings(content: 'Updated', isBold: true);

      cubit.updateOverlaySettings(segment.id, settings);

      final updatedSegment = cubit.state.tracks
          .firstWhere((t) => t.type == segment.trackType)
          .segments
          .firstWhere((s) => s.id == segment.id);
      expect(updatedSegment.overlaySettings, settings);
    });

    test('updateTransition and duration mutate segment transition', () {
      final segment = cubit.state.tracks.first.segments.first;

      cubit.updateTransition(segment.id, SegmentTransitionType.slide);
      cubit.updateTransitionDuration(
        segment.id,
        const Duration(milliseconds: 750),
      );

      final updatedSegment = cubit.state.tracks
          .firstWhere((t) => t.type == segment.trackType)
          .segments
          .firstWhere((s) => s.id == segment.id);
      expect(updatedSegment.transition, SegmentTransitionType.slide);
      expect(
        updatedSegment.transitionDuration,
        const Duration(milliseconds: 750),
      );
    });

    test('addCaption appends caption blocks', () {
      final segment = cubit.state.tracks.first.segments.first;
      final existingCount = segment.captions.length;

      cubit.addCaption(segment.id);

      final updatedSegment = cubit.state.tracks
          .firstWhere((t) => t.type == segment.trackType)
          .segments
          .firstWhere((s) => s.id == segment.id);
      expect(updatedSegment.captions.length, existingCount + 1);
    });

    test('updateCaption normalises overlapping duration', () {
      final segment = cubit.state.tracks.first.segments.first;
      cubit.addCaption(segment.id);
      final updatedSegment = cubit.state.tracks
          .firstWhere((t) => t.type == segment.trackType)
          .segments
          .firstWhere((s) => s.id == segment.id);
      final caption = updatedSegment.captions.last;

      cubit.updateCaption(
        segment.id,
        caption.id,
        start: const Duration(seconds: 10),
        end: const Duration(seconds: 5),
        text: 'Adjusted',
      );

      final latestSegment = cubit.state.tracks
          .firstWhere((t) => t.type == segment.trackType)
          .segments
          .firstWhere((s) => s.id == segment.id);
      final updatedCaption = latestSegment.captions.last;

      expect(updatedCaption.start, const Duration(seconds: 10));
      expect(updatedCaption.end, const Duration(seconds: 10));
      expect(updatedCaption.text, 'Adjusted');
    });

    test('toggleTrackVisibility flips visibility flag', () {
      final trackType = TimelineTrackType.audio;
      final initial = cubit.state.getTrack(trackType);

      cubit.toggleTrackVisibility(trackType);

      expect(cubit.state.getTrack(trackType).isVisible, !initial.isVisible);
    });

    test('updateZoomLevel clamps values', () {
      cubit.updateZoomLevel(4);
      expect(cubit.state.zoomLevel, 3);

      cubit.updateZoomLevel(0.1);
      expect(cubit.state.zoomLevel, 0.5);
    });

    test('updateSegmentTitle trims and updates title', () {
      final segment = cubit.state.tracks.first.segments.first;
      cubit.updateSegmentTitle(segment.id, '  New Title  ');

      final updatedSegment = cubit.state.tracks
          .firstWhere((t) => t.type == segment.trackType)
          .segments
          .firstWhere((s) => s.id == segment.id);
      expect(updatedSegment.title, 'New Title');
    });

    test('updateSegmentDescription updates description text', () {
      final segment = cubit.state.tracks.first.segments.first;
      const description = 'Detailed walkthrough';

      cubit.updateSegmentDescription(segment.id, description);

      final updatedSegment = cubit.state.tracks
          .firstWhere((t) => t.type == segment.trackType)
          .segments
          .firstWhere((s) => s.id == segment.id);
      expect(updatedSegment.description, description);
    });

    test('updateCurrentPosition clamps to timeline bounds', () {
      cubit.updateCurrentPosition(const Duration(seconds: -5));
      expect(cubit.state.currentPosition, Duration.zero);

      cubit.updateCurrentPosition(const Duration(hours: 1));
      expect(cubit.state.currentPosition, cubit.state.totalTimelineDuration);
    });
  });
}
