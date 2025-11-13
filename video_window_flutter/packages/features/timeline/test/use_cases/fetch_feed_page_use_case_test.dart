import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timeline/use_cases/fetch_feed_page_use_case.dart';
import 'package:timeline/data/repositories/feed_repository.dart';
import 'package:timeline/data/repositories/feed_cache_repository.dart';
import 'package:timeline/domain/entities/video.dart';
import 'package:timeline/domain/entities/feed_configuration.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

class MockFeedCacheRepository extends Mock implements FeedCacheRepository {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('FetchFeedPageUseCase', () {
    late MockFeedRepository mockRepository;
    late MockFeedCacheRepository mockCacheRepository;
    late MockSecureStorage mockSecureStorage;
    late FetchFeedPageUseCase useCase;

    setUp(() {
      mockRepository = MockFeedRepository();
      mockCacheRepository = MockFeedCacheRepository();
      mockSecureStorage = MockSecureStorage();
      useCase = FetchFeedPageUseCase(
        repository: mockRepository,
        cacheRepository: mockCacheRepository,
        secureStorage: mockSecureStorage,
      );
    });

    group('Cursor Persistence', () {
      test('AC5: saveLastCursor persists cursor to secure storage', () async {
        const cursor = 'test_cursor_123';

        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async => {});

        await useCase.saveLastCursor(cursor);

        verify(() => mockSecureStorage.write(
              key: 'feed_last_cursor',
              value: cursor,
            )).called(1);
      });

      test('AC5: getLastCursor retrieves cursor from secure storage', () async {
        const cursor = 'test_cursor_123';

        when(() => mockSecureStorage.read(key: 'feed_last_cursor'))
            .thenAnswer((_) async => cursor);

        final result = await useCase.getLastCursor();

        expect(result, cursor);
        verify(() => mockSecureStorage.read(key: 'feed_last_cursor')).called(1);
      });

      test('AC5: getLastCursor returns null when cursor not found', () async {
        when(() => mockSecureStorage.read(key: 'feed_last_cursor'))
            .thenAnswer((_) async => null);

        final result = await useCase.getLastCursor();

        expect(result, isNull);
      });

      test('AC2: saveLastFeedSessionId persists session ID to secure storage',
          () async {
        const sessionId = 'feed_session_user_123';

        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async => {});

        await useCase.saveLastFeedSessionId(sessionId);

        verify(() => mockSecureStorage.write(
              key: 'feed_last_session_id',
              value: sessionId,
            )).called(1);
      });

      test('AC2: getLastFeedSessionId retrieves session ID from secure storage',
          () async {
        const sessionId = 'feed_session_user_123';

        when(() => mockSecureStorage.read(key: 'feed_last_session_id'))
            .thenAnswer((_) async => sessionId);

        final result = await useCase.getLastFeedSessionId();

        expect(result, sessionId);
        verify(() => mockSecureStorage.read(key: 'feed_last_session_id'))
            .called(1);
      });

      test('AC5: clearPersistedState removes both cursor and session ID',
          () async {
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async => {});

        await useCase.clearPersistedState();

        verify(() => mockSecureStorage.delete(key: 'feed_last_cursor'))
            .called(1);
        verify(() => mockSecureStorage.delete(key: 'feed_last_session_id'))
            .called(1);
      });
    });

    group('Cursor Restoration', () {
      test(
          'AC5: restoreLastCursor parameter restores cursor when cursor is null',
          () async {
        const restoredCursor = 'restored_cursor';
        final videos = List.generate(
            20,
            (i) => Video(
                  id: 'video_$i',
                  makerId: 'maker',
                  title: 'Video $i',
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
                ));

        when(() => mockSecureStorage.read(key: 'feed_last_cursor'))
            .thenAnswer((_) async => restoredCursor);
        when(() => mockRepository.fetchFeedPage(
              cursor: restoredCursor,
              limit: 20,
            )).thenAnswer((_) async => FeedPageResult(
              videos: videos,
              nextCursor: 'next_cursor',
              hasMore: true,
              feedId: 'session_1',
            ));

        final result = await useCase.execute(
          restoreLastCursor: true,
          useCache: false,
        );

        expect(result.nextCursor, 'next_cursor');
        verify(() => mockRepository.fetchFeedPage(
              cursor: restoredCursor,
              limit: 20,
            )).called(1);
      });
    });
  });
}
