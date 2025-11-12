import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'story_event.dart';
import 'story_state.dart';
import '../../use_cases/load_story_detail_use_case.dart';
import '../../use_cases/prepare_accessibility_assets_use_case.dart';
import '../../use_cases/generate_story_deep_link_use_case.dart';
import '../../use_cases/toggle_story_save_use_case.dart';

/// BLoC for managing story detail page state
/// AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8: Comprehensive story state management
class StoryBloc extends Bloc<StoryEvent, StoryState> {
  final LoadStoryDetailUseCase _loadStoryUseCase;
  final PrepareAccessibilityAssetsUseCase _accessibilityUseCase;
  final GenerateStoryDeepLinkUseCase _shareUseCase;
  final ToggleStorySaveUseCase _saveUseCase;

  StoryBloc({
    required LoadStoryDetailUseCase loadStoryUseCase,
    required PrepareAccessibilityAssetsUseCase accessibilityUseCase,
    required GenerateStoryDeepLinkUseCase shareUseCase,
    required ToggleStorySaveUseCase saveUseCase,
  })  : _loadStoryUseCase = loadStoryUseCase,
        _accessibilityUseCase = accessibilityUseCase,
        _shareUseCase = shareUseCase,
        _saveUseCase = saveUseCase,
        super(const StoryInitial()) {
    on<StoryLoadRequested>(_onLoadRequested);
    on<VideoPlayRequested>(_onVideoPlayRequested);
    on<SectionNavigated>(_onSectionNavigated);
    on<StoryShareRequested>(_onShareRequested);
    on<StoryToggleLike>(_onToggleLike);
    on<StoryToggleSave>(_onToggleSave);
    on<StoryFollowMaker>(_onFollowMaker);
  }

  Future<void> _onLoadRequested(
    StoryLoadRequested event,
    Emitter<StoryState> emit,
  ) async {
    emit(const StoryLoading());
    try {
      final story = await _loadStoryUseCase.execute(event.storyId);

      // Prepare accessibility assets
      await _accessibilityUseCase.execute(event.storyId);

      emit(StoryLoaded(
        story: story,
        activeSection: 'overview',
      ));
    } catch (e) {
      emit(StoryError(
        message: 'Failed to load story: ${e.toString()}',
        type: StoryErrorType.notFound,
      ));
    }
  }

  Future<void> _onVideoPlayRequested(
    VideoPlayRequested event,
    Emitter<StoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! StoryLoaded) return;

    // Video playback logic would be handled by VideoPlayerBloc
    // This is a placeholder for the event handling
    emit(currentState);
  }

  void _onSectionNavigated(
    SectionNavigated event,
    Emitter<StoryState> emit,
  ) {
    final currentState = state;
    if (currentState is! StoryLoaded) return;

    emit(currentState.copyWith(activeSection: event.sectionId));
  }

  Future<void> _onShareRequested(
    StoryShareRequested event,
    Emitter<StoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! StoryLoaded) return;

    try {
      final shareResponse = await _shareUseCase.execute(
        storyId: currentState.story.id,
        channel: event.channel,
        customMessage: event.customMessage,
      );
      emit(StoryShareReady(shareResponse));
    } catch (e) {
      emit(StoryError(
        message: 'Failed to share story: ${e.toString()}',
        type: StoryErrorType.network,
      ));
    }
  }

  void _onToggleLike(
    StoryToggleLike event,
    Emitter<StoryState> emit,
  ) {
    final currentState = state;
    if (currentState is! StoryLoaded) return;

    emit(currentState.copyWith(isLiked: !currentState.isLiked));
  }

  Future<void> _onToggleSave(
    StoryToggleSave event,
    Emitter<StoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! StoryLoaded) return;

    final newSaveState = !currentState.isSaved;

    // Emit optimistic state
    final optimisticState = currentState.copyWith(
      isSaved: newSaveState,
      // Keep wishlistId while unsaving for potential rollback, it will be cleared on success
    );
    emit(optimisticState);

    try {
      final wishlistId = await _saveUseCase.execute(
        storyId: currentState.story.id,
        makerId: currentState.story.makerId,
        saveState: newSaveState,
        ctaSurface: event.ctaSurface,
      );
      // On success, emit the final state
      emit(optimisticState.copyWith(wishlistId: wishlistId));
    } catch (e) {
      // On failure, roll back to the original state
      emit(currentState);
      // Optionally, emit an error state or handle the error in the UI
      // For now, we just revert the state. A dedicated error field in StoryLoaded would be better.
    }
  }

  void _onFollowMaker(
    StoryFollowMaker event,
    Emitter<StoryState> emit,
  ) {
    final currentState = state;
    if (currentState is! StoryLoaded) return;

    emit(currentState.copyWith(
        isFollowingMaker: !currentState.isFollowingMaker));
  }
}
