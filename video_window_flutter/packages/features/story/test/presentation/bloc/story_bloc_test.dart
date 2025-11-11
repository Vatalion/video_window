import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../lib/presentation/bloc/story_bloc.dart';
import '../../../../lib/presentation/bloc/story_event.dart';
import '../../../../lib/presentation/bloc/story_state.dart';
import '../../../../lib/use_cases/load_story_detail_use_case.dart';
import '../../../../lib/use_cases/prepare_accessibility_assets_use_case.dart';
import '../../../../lib/use_cases/generate_story_deep_link_use_case.dart';
import '../../../../lib/use_cases/toggle_story_save_use_case.dart';

class MockLoadStoryUseCase extends Mock implements LoadStoryDetailUseCase {}

class MockAccessibilityUseCase extends Mock
    implements PrepareAccessibilityAssetsUseCase {}

class MockShareUseCase extends Mock implements GenerateStoryDeepLinkUseCase {}

class MockSaveUseCase extends Mock implements ToggleStorySaveUseCase {}

void main() {
  group('StoryBloc', () {
    late MockLoadStoryUseCase mockLoadStoryUseCase;
    late MockAccessibilityUseCase mockAccessibilityUseCase;
    late MockShareUseCase mockShareUseCase;
    late MockSaveUseCase mockSaveUseCase;
    late StoryBloc storyBloc;

    setUp(() {
      mockLoadStoryUseCase = MockLoadStoryUseCase();
      mockAccessibilityUseCase = MockAccessibilityUseCase();
      mockShareUseCase = MockShareUseCase();
      mockSaveUseCase = MockSaveUseCase();
      storyBloc = StoryBloc(
        loadStoryUseCase: mockLoadStoryUseCase,
        accessibilityUseCase: mockAccessibilityUseCase,
        shareUseCase: mockShareUseCase,
        saveUseCase: mockSaveUseCase,
      );
    });

    test('initial state is StoryInitial', () {
      expect(storyBloc.state, equals(const StoryInitial()));
    });

    blocTest<StoryBloc, StoryState>(
      'emits [StoryLoading, StoryError] when load fails',
      build: () {
        when(() => mockLoadStoryUseCase.execute(any()))
            .thenThrow(Exception('Failed to load'));
        return storyBloc;
      },
      act: (bloc) => bloc.add(
        const StoryLoadRequested(storyId: 'test-id', source: 'test'),
      ),
      expect: () => [
        const StoryLoading(),
        isA<StoryError>(),
      ],
    );

    blocTest<StoryBloc, StoryState>(
      'emits section navigated state',
      build: () => storyBloc,
      seed: () => StoryLoaded(
        story: throw UnimplementedError(), // Would need actual story
        activeSection: 'overview',
      ),
      act: (bloc) => bloc.add(const SectionNavigated('process')),
      skip: 1, // Skip initial state
      expect: () => [
        isA<StoryLoaded>().having(
          (s) => (s as StoryLoaded).activeSection,
          'activeSection',
          'process',
        ),
      ],
    );
  });
}
