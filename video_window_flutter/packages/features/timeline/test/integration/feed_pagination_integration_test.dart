import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timeline/presentation/pages/feed_page.dart';
import 'package:timeline/presentation/bloc/feed_bloc.dart';
import 'package:timeline/presentation/bloc/feed_state.dart';
import 'package:timeline/presentation/bloc/feed_event.dart';
import 'package:timeline/data/repositories/feed_repository.dart';
import 'package:timeline/data/repositories/feed_cache_repository.dart';
import 'package:timeline/use_cases/fetch_feed_page_use_case.dart';
import 'package:timeline/domain/entities/video.dart';
import 'package:flutter/material.dart';

/// Integration tests for feed pagination
/// AC1, AC5: Cursor flow, offline replay, and error retries
class MockFeedRepository extends Mock implements FeedRepository {}

class MockFeedCacheRepository extends Mock implements FeedCacheRepository {}

void main() {
  group('Feed Pagination Integration Tests', () {
    late MockFeedRepository mockRepository;
    late MockFeedCacheRepository mockCacheRepository;
    late FetchFeedPageUseCase useCase;

    setUp(() {
      mockRepository = MockFeedRepository();
      mockCacheRepository = MockFeedCacheRepository();
      useCase = FetchFeedPageUseCase(
        repository: mockRepository,
        cacheRepository: mockCacheRepository,
      );
    });

    group('Cursor Flow', () {
      test('AC1: Cursor-based pagination retrieves 20-item pages', () async {
        final videos = List.generate(
            20,
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
                  tags: const [],
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

        when(() => mockRepository.fetchFeedPage(
              userId: any(named: 'userId'),
              limit: 20,
              cursor: null,
            )).thenAnswer((_) async => FeedPageResult(
              videos: videos,
              nextCursor: 'cursor_1',
              hasMore: true,
              feedId: 'session_1',
            ));

        final result = await useCase.execute(limit: 20);

        expect(result.videos.length, 20);
        expect(result.nextCursor, 'cursor_1');
        expect(result.hasMore, true);
      });

      test('AC1: Handles backfill when returning to previous videos', () async {
        // Test that cursor can be reused to get previous pages
        when(() => mockCacheRepository.getCachedVideos('cursor_prev'))
            .thenAnswer((_) async => [
                  Video(
                    id: 'prev_video',
                    makerId: 'maker',
                    title: 'Previous Video',
                    description: 'Description',
                    videoUrl: 'https://example.com/video.mp4',
                    thumbnailUrl: 'https://example.com/thumb.jpg',
                    duration: const Duration(seconds: 60),
                    viewCount: 0,
                    likeCount: 0,
                    tags: const [],
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
                  ),
                ]);

        final result = await useCase.execute(
          cursor: 'cursor_prev',
          useCache: true,
        );

        expect(result.videos.isNotEmpty, true);
        expect(result.feedId, 'cached');
      });
    });

    group('Offline Replay', () {
      test('AC5: Replays cached videos when network unavailable', () async {
        final cachedVideos = [
          Video(
            id: 'cached_video',
            makerId: 'maker',
            title: 'Cached Video',
            description: 'Description',
            videoUrl: 'https://example.com/video.mp4',
            thumbnailUrl: 'https://example.com/thumb.jpg',
            duration: const Duration(seconds: 60),
            viewCount: 0,
            likeCount: 0,
            tags: const [],
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
          ),
        ];

        when(() => mockRepository.fetchFeedPage(
              cursor: 'cursor_offline',
            )).thenThrow(Exception('Network error'));

        when(() => mockCacheRepository.getCachedVideos('cursor_offline'))
            .thenAnswer((_) async => cachedVideos);

        final result = await useCase.execute(
          cursor: 'cursor_offline',
          useCache: true,
        );

        expect(result.videos, cachedVideos);
        expect(result.feedId, 'cache_fallback');
      });
    });

    group('Error Retries', () {
      testWidgets('AC3: Retry capability works after pagination error',
          (tester) async {
        final mockRepository = MockFeedRepository();
        final feedBloc = FeedBloc(
          repository: mockRepository,
          userId: 'test_user',
        );

        // First call fails
        when(() => mockRepository.fetchFeedPage(
              userId: any(named: 'userId'),
              limit: 20,
              cursor: 'cursor_error',
            )).thenThrow(Exception('Network error'));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<FeedBloc>.value(
              value: feedBloc,
              child: const FeedPage(),
            ),
          ),
        );

        // Set up loaded state with error
        feedBloc.emit(const FeedLoaded(
          videos: [],
          nextCursor: 'cursor_error',
          hasMore: true,
          paginationError: 'Failed to load more videos',
        ));

        await tester.pumpAndSettle();

        // Verify error footer is shown
        expect(find.text('Failed to load more videos'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Retry should clear error
        feedBloc.add(const FeedRetryPagination());
        await tester.pump();

        // Error should be cleared
        final state = feedBloc.state;
        if (state is FeedLoaded) {
          expect(state.paginationError, isNull);
        }

        feedBloc.close();
      });
    });
  });
}
