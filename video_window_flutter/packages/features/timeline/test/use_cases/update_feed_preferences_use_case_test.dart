import 'package:flutter_test/flutter_test.dart';
import 'package:timeline/use_cases/update_feed_preferences_use_case.dart';
import 'package:timeline/domain/entities/feed_configuration.dart';
import 'package:timeline/domain/entities/video.dart';
import 'package:timeline/data/repositories/feed_repository.dart';
import 'package:core/services/analytics_service.dart';

class MockFeedRepository extends FeedRepository {
  FeedConfiguration? savedConfiguration;
  bool shouldThrow = false;

  MockFeedRepository() : super(client: null as dynamic);

  @override
  Future<FeedConfiguration> updatePreferences({
    required String userId,
    required FeedConfiguration configuration,
  }) async {
    if (shouldThrow) {
      throw FeedRepositoryException('Update failed');
    }
    savedConfiguration = configuration;
    return configuration;
  }
}

class MockAnalyticsService extends AnalyticsService {
  final List<AnalyticsEvent> trackedEvents = [];

  MockAnalyticsService() : super(null as dynamic);

  @override
  Future<void> trackEvent(AnalyticsEvent event) async {
    trackedEvents.add(event);
  }
}

void main() {
  group('UpdateFeedPreferencesUseCase', () {
    late MockFeedRepository mockRepository;
    late MockAnalyticsService mockAnalytics;
    late UpdateFeedPreferencesUseCase useCase;

    setUp(() {
      mockRepository = MockFeedRepository();
      mockAnalytics = MockAnalyticsService();
      useCase = UpdateFeedPreferencesUseCase(
        repository: mockRepository,
        analyticsService: mockAnalytics,
      );
    });

    test('successfully updates preferences', () async {
      final configuration = FeedConfiguration(
        id: 'config_1',
        userId: 'user_1',
        preferredTags: const ['tag1'],
        blockedMakers: const [],
        preferredQuality: VideoQuality.hd,
        autoPlay: true,
        showCaptions: false,
        playbackSpeed: 1.0,
        algorithm: FeedAlgorithm.personalized,
        lastUpdated: DateTime.now(),
      );

      final result = await useCase.execute(
        userId: 'user_1',
        configuration: configuration,
      );

      expect(result, isNotNull);
      expect(mockRepository.savedConfiguration, equals(configuration));
    });

    test('validates blocked makers limit', () async {
      final configuration = FeedConfiguration(
        id: 'config_1',
        userId: 'user_1',
        preferredTags: const [],
        blockedMakers: List.generate(201, (i) => 'maker_$i'),
        preferredQuality: VideoQuality.hd,
        autoPlay: true,
        showCaptions: false,
        playbackSpeed: 1.0,
        algorithm: FeedAlgorithm.personalized,
        lastUpdated: DateTime.now(),
      );

      expect(
        () => useCase.execute(
          userId: 'user_1',
          configuration: configuration,
        ),
        throwsException,
      );
    });

    test('emits analytics event on update', () async {
      final configuration = FeedConfiguration(
        id: 'config_1',
        userId: 'user_1',
        preferredTags: const [],
        blockedMakers: const [],
        preferredQuality: VideoQuality.hd,
        autoPlay: true,
        showCaptions: false,
        playbackSpeed: 1.0,
        algorithm: FeedAlgorithm.personalized,
        lastUpdated: DateTime.now(),
      );

      await useCase.execute(
        userId: 'user_1',
        configuration: configuration,
      );

      expect(mockAnalytics.trackedEvents.length, greaterThan(0));
      expect(
        mockAnalytics.trackedEvents.any(
          (e) => e.name == 'feed_preferences_updated',
        ),
        isTrue,
      );
    });

    test('calculates changed fields correctly', () async {
      final previous = FeedConfiguration(
        id: 'config_1',
        userId: 'user_1',
        preferredTags: const [],
        blockedMakers: const [],
        preferredQuality: VideoQuality.hd,
        autoPlay: true,
        showCaptions: false,
        playbackSpeed: 1.0,
        algorithm: FeedAlgorithm.personalized,
        lastUpdated: DateTime.now(),
      );

      final updated = FeedConfiguration(
        id: 'config_1',
        userId: 'user_1',
        preferredTags: const [],
        blockedMakers: const [],
        preferredQuality: VideoQuality.hd,
        autoPlay: false, // Changed
        showCaptions: true, // Changed
        playbackSpeed: 1.5, // Changed
        algorithm: FeedAlgorithm.trending, // Changed
        lastUpdated: DateTime.now(),
      );

      final useCaseWithPrevious = UpdateFeedPreferencesUseCase(
        repository: mockRepository,
        analyticsService: mockAnalytics,
        previousConfiguration: previous,
      );

      await useCaseWithPrevious.execute(
        userId: 'user_1',
        configuration: updated,
      );

      final preferencesEvent = mockAnalytics.trackedEvents.firstWhere(
        (e) => e.name == 'feed_preferences_updated',
      ) as dynamic;

      expect(preferencesEvent.changedFields, contains('autoPlay'));
      expect(preferencesEvent.changedFields, contains('showCaptions'));
      expect(preferencesEvent.changedFields, contains('playbackSpeed'));
      expect(preferencesEvent.changedFields, contains('algorithm'));
    });

    test('emits accessibility event when accessibility toggles change',
        () async {
      final previous = FeedConfiguration(
        id: 'config_1',
        userId: 'user_1',
        preferredTags: const [],
        blockedMakers: const [],
        preferredQuality: VideoQuality.hd,
        autoPlay: true,
        showCaptions: false,
        playbackSpeed: 1.0,
        algorithm: FeedAlgorithm.personalized,
        lastUpdated: DateTime.now(),
      );

      final updated = FeedConfiguration(
        id: 'config_1',
        userId: 'user_1',
        preferredTags: const [],
        blockedMakers: const [],
        preferredQuality: VideoQuality.hd,
        autoPlay: true,
        showCaptions: true, // Changed
        playbackSpeed: 1.0,
        algorithm: FeedAlgorithm.personalized,
        lastUpdated: DateTime.now(),
      );

      final useCaseWithPrevious = UpdateFeedPreferencesUseCase(
        repository: mockRepository,
        analyticsService: mockAnalytics,
        previousConfiguration: previous,
      );

      await useCaseWithPrevious.execute(
        userId: 'user_1',
        configuration: updated,
      );

      expect(
        mockAnalytics.trackedEvents.any(
          (e) => e.name == 'feed_accessibility_toggled',
        ),
        isTrue,
      );
    });
  });
}
