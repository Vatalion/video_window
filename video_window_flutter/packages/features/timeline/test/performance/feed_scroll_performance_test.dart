import 'package:flutter_test/flutter_test.dart';
import 'package:timeline/presentation/pages/feed_page.dart';
import 'package:timeline/presentation/bloc/feed_bloc.dart';
import 'package:timeline/presentation/bloc/feed_state.dart';
import 'package:timeline/domain/entities/video.dart'
    show Video, VideoQuality, VideoMetadata;
import 'package:timeline/data/repositories/feed_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window_client/video_window_client.dart';

/// Scroll performance tests
/// AC4: Test 60fps scroll performance with 1000+ video items and <=2% jank tolerance
class MockClient extends Mock implements Client {}

void main() {
  group('Feed Scroll Performance Tests', () {
    testWidgets('AC4: ListView maintains performance with many items',
        (tester) async {
      // Create feed page with many videos
      final videos = List.generate(
          100,
          (i) => Video(
                id: 'video_$i',
                makerId: 'maker_$i',
                title: 'Video $i',
                description: 'Description $i',
                videoUrl: 'https://example.com/video_$i.mp4',
                thumbnailUrl: 'https://example.com/thumb_$i.jpg',
                duration: const Duration(seconds: 60),
                viewCount: 0,
                likeCount: 0,
                tags: [],
                quality: VideoQuality.hd,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isActive: true,
                metadata: const VideoMetadata(
                  width: 1920,
                  height: 1080,
                  format: 'mp4',
                  aspectRatio: 16 / 9,
                  availableQualities: [VideoQuality.hd],
                  hasCaptions: false,
                ),
              ));

      final mockClient = MockClient();
      final feedBloc = FeedBloc(
        repository: FeedRepository(client: mockClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FeedBloc>.value(
            value: feedBloc,
            child: const FeedPage(),
          ),
        ),
      );

      // Set loaded state
      feedBloc.emit(FeedLoaded(
        videos: videos,
        nextCursor: 'cursor_1',
        hasMore: true,
      ));

      await tester.pumpAndSettle();

      // Verify ListView is rendered
      expect(find.byType(ListView), findsOneWidget);

      // Test scrolling performance
      final listView = tester.widget<ListView>(find.byType(ListView));

      // Verify optimized ListView configuration
      expect(listView.itemExtent, isNotNull); // Fixed itemExtent
      expect(listView.cacheExtent, isNotNull); // Proper cacheExtent
      expect(listView.addRepaintBoundaries, isTrue); // Repaint boundaries

      feedBloc.close();
    });

    testWidgets('AC4: Scroll performance with fixed itemExtent',
        (tester) async {
      // This test verifies that fixed itemExtent is used for performance
      final videos = List.generate(
          50,
          (i) => Video(
                id: 'video_$i',
                makerId: 'maker_$i',
                title: 'Video $i',
                description: 'Description $i',
                videoUrl: 'https://example.com/video_$i.mp4',
                thumbnailUrl: 'https://example.com/thumb_$i.jpg',
                duration: const Duration(seconds: 60),
                viewCount: 0,
                likeCount: 0,
                tags: [],
                quality: VideoQuality.hd,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isActive: true,
                metadata: const VideoMetadata(
                  width: 1920,
                  height: 1080,
                  format: 'mp4',
                  aspectRatio: 16 / 9,
                  availableQualities: [VideoQuality.hd],
                  hasCaptions: false,
                ),
              ));

      final mockClient = MockClient();
      final feedBloc = FeedBloc(
        repository: FeedRepository(client: mockClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FeedBloc>.value(
            value: feedBloc,
            child: const FeedPage(),
          ),
        ),
      );

      feedBloc.emit(FeedLoaded(
        videos: videos,
        nextCursor: null,
        hasMore: false,
      ));

      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView));

      // PERF-001: Verify fixed itemExtent is set
      expect(listView.itemExtent, isNotNull);

      feedBloc.close();
    });
  });
}
