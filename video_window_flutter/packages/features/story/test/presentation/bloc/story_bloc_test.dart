import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window_flutter/packages/features/story/lib/domain/entities/story.dart';
import 'package:video_window_flutter/packages/features/story/lib/presentation/bloc/story_bloc.dart';
import 'package:video_window_flutter/packages/features/story/lib/presentation/bloc/story_event.dart';
import 'package:video_window_flutter/packages/features/story/lib/presentation/bloc/story_state.dart';
import 'package:video_window_flutter/packages/features/story/lib/use_cases/generate_story_deep_link_use_case.dart';
import 'package:video_window_flutter/packages/features/story/lib/use_cases/load_story_detail_use_case.dart';
import 'package:video_window_flutter/packages/features/story/lib/use_cases/prepare_accessibility_assets_use_case.dart';
import 'package:video_window_flutter/packages/features/story/lib/use_cases/toggle_story_save_use_case.dart';

class MockLoadStoryDetailUseCase extends Mock
    implements LoadStoryDetailUseCase {}

class MockPrepareAccessibilityAssetsUseCase extends Mock
    implements PrepareAccessibilityAssetsUseCase {}

class MockGenerateStoryDeepLinkUseCase extends Mock
    implements GenerateStoryDeepLinkUseCase {}

class MockToggleStorySaveUseCase extends Mock
    implements ToggleStorySaveUseCase {}

class MockArtifactStory extends Mock implements ArtifactStory {}

void main() {
  late StoryBloc storyBloc;
  late MockLoadStoryDetailUseCase mockLoadStoryDetailUseCase;
  late MockPrepareAccessibilityAssetsUseCase
      mockPrepareAccessibilityAssetsUseCase;
  late MockGenerateStoryDeepLinkUseCase mockGenerateStoryDeepLinkUseCase;
  late MockToggleStorySaveUseCase mockToggleStorySaveUseCase;
  late MockArtifactStory mockArtifactStory;

  setUp(() {
    mockLoadStoryDetailUseCase = MockLoadStoryDetailUseCase();
    mockPrepareAccessibilityAssetsUseCase =
        MockPrepareAccessibilityAssetsUseCase();
    mockGenerateStoryDeepLinkUseCase = MockGenerateStoryDeepLinkUseCase();
    mockToggleStorySaveUseCase = MockToggleStorySaveUseCase();
    mockArtifactStory = MockArtifactStory();

    when(() => mockArtifactStory.id).thenReturn('story-1');
    when(() => mockArtifactStory.makerId).thenReturn('maker-1');

    storyBloc = StoryBloc(
      loadStoryUseCase: mockLoadStoryDetailUseCase,
      accessibilityUseCase: mockPrepareAccessibilityAssetsUseCase,
      shareUseCase: mockGenerateStoryDeepLinkUseCase,
      saveUseCase: mockToggleStorySaveUseCase,
    );
  });

  final tStory = mockArtifactStory;
  const tStoryLoadedState = StoryLoaded(story: mockArtifactStory);

  group('StoryToggleSave', () {
    blocTest<StoryBloc, StoryState>(
      'emits [optimistic, success] states when save is successful',
      build: () {
        when(() => mockToggleStorySaveUseCase.execute(
              storyId: any(named: 'storyId'),
              makerId: any(named: 'makerId'),
              saveState: any(named: 'saveState'),
              ctaSurface: any(named: 'ctaSurface'),
            )).thenAnswer((_) async => 'wishlist-123');
        return storyBloc;
      },
      seed: () => tStoryLoadedState,
      act: (bloc) => bloc.add(const StoryToggleSave(ctaSurface: 'test')),
      expect: () => [
        tStoryLoadedState.copyWith(isSaved: true),
        tStoryLoadedState.copyWith(isSaved: true, wishlistId: 'wishlist-123'),
      ],
      verify: (_) {
        verify(() => mockToggleStorySaveUseCase.execute(
              storyId: tStory.id,
              makerId: tStory.makerId,
              saveState: true,
              ctaSurface: 'test',
            )).called(1);
      },
    );

    blocTest<StoryBloc, StoryState>(
      'emits [optimistic, original] states when save fails',
      build: () {
        when(() => mockToggleStorySaveUseCase.execute(
              storyId: any(named: 'storyId'),
              makerId: any(named: 'makerId'),
              saveState: any(named: 'saveState'),
              ctaSurface: any(named: 'ctaSurface'),
            )).thenThrow(Exception('Failed to save'));
        return storyBloc;
      },
      seed: () => tStoryLoadedState,
      act: (bloc) => bloc.add(const StoryToggleSave(ctaSurface: 'test')),
      expect: () => [
        tStoryLoadedState.copyWith(isSaved: true),
        tStoryLoadedState, // Rollback to original state
      ],
    );
  });
}
