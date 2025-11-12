import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window_flutter/packages/core/lib/data/services/analytics/story_analytics_service.dart';
import 'package:video_window_flutter/packages/features/story/lib/domain/repositories/share_repository.dart';
import 'package:video_window_flutter/packages/features/story/lib/use_cases/toggle_story_save_use_case.dart';

class MockShareRepository extends Mock implements ShareRepository {}

class MockStoryAnalyticsService extends Mock implements StoryAnalyticsService {}

void main() {
  late ToggleStorySaveUseCase useCase;
  late MockShareRepository mockShareRepository;
  late MockStoryAnalyticsService mockAnalyticsService;

  setUp(() {
    mockShareRepository = MockShareRepository();
    mockAnalyticsService = MockStoryAnalyticsService();
    useCase = ToggleStorySaveUseCase(mockShareRepository, mockAnalyticsService);
  });

  const storyId = 'story-1';
  const makerId = 'maker-1';
  const ctaSurface = 'story_detail_page';

  test('should call repository and analytics when saving a story', () async {
    // arrange
    when(() => mockShareRepository.toggleStorySave(
            storyId: any(named: 'storyId'), isSaved: any(named: 'isSaved')))
        .thenAnswer((_) async => 'wishlist-123');
    when(() => mockAnalyticsService.storySaved(
          storyId: any(named: 'storyId'),
          makerId: any(named: 'makerId'),
          saveState: any(named: 'saveState'),
          ctaSurface: any(named: 'ctaSurface'),
        )).thenReturn(null);

    // act
    final result = await useCase.execute(
      storyId: storyId,
      makerId: makerId,
      saveState: true,
      ctaSurface: ctaSurface,
    );

    // assert
    expect(result, 'wishlist-123');
    verify(() => mockShareRepository.toggleStorySave(
        storyId: storyId, isSaved: true)).called(1);
    verify(() => mockAnalyticsService.storySaved(
          storyId: storyId,
          makerId: makerId,
          saveState: true,
          ctaSurface: ctaSurface,
        )).called(1);
    verifyNoMoreInteractions(mockShareRepository);
    verifyNoMoreInteractions(mockAnalyticsService);
  });
}
