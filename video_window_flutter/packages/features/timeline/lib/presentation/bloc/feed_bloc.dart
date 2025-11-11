import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/feed_repository.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/video_interaction.dart';
import 'feed_event.dart';
import 'feed_state.dart';

/// BLoC for managing feed state
/// AC1, AC2: State management for feed pagination and video playback
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepository _repository;
  final String? _userId;

  // PERF-005: Stream subscription management
  final List<StreamSubscription> _subscriptions = [];

  FeedBloc({
    required FeedRepository repository,
    String? userId,
  })  : _repository = repository,
        _userId = userId,
        super(const FeedInitial()) {
    on<FeedLoadInitial>(_onLoadInitial);
    on<FeedLoadNextPage>(_onLoadNextPage);
    on<FeedRefresh>(_onRefresh);
    on<FeedRetryPagination>(_onRetryPagination);
    on<FeedVideoInteraction>(_onVideoInteraction);
    on<FeedVideoVisibilityChanged>(_onVideoVisibilityChanged);
    on<FeedVideoPlaybackStateChanged>(_onVideoPlaybackStateChanged);
    on<FeedToggleLike>(_onToggleLike);
    on<FeedToggleWishlist>(_onToggleWishlist);
  }

  @override
  Future<void> close() {
    // PERF-005: Cancel all stream subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    return super.close();
  }

  Future<void> _onLoadInitial(
    FeedLoadInitial event,
    Emitter<FeedState> emit,
  ) async {
    emit(const FeedLoading());
    try {
      final result = await _repository.fetchFeedPage(
        userId: _userId,
        limit: 20,
      );

      emit(FeedLoaded(
        videos: result.videos,
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(FeedError(
        message: 'Failed to load feed: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  Future<void> _onLoadNextPage(
    FeedLoadNextPage event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FeedLoaded ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(
      isLoadingMore: true,
      paginationError: null, // Clear previous error
    ));

    try {
      final result = await _repository.fetchFeedPage(
        userId: _userId,
        limit: 20,
        cursor: currentState.nextCursor,
        excludeVideoIds: currentState.videos.map((v) => v.id).toList(),
      );

      emit(currentState.copyWith(
        videos: [...currentState.videos, ...result.videos],
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
        isLoadingMore: false,
        paginationError: null,
      ));
    } catch (e) {
      // AC3: Set error state for retry capability
      emit(currentState.copyWith(
        isLoadingMore: false,
        paginationError: 'Failed to load more videos: ${e.toString()}',
      ));
    }
  }

  /// AC3: Retry pagination after error
  Future<void> _onRetryPagination(
    FeedRetryPagination event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    // Clear error and retry loading next page
    emit(currentState.copyWith(paginationError: null));
    add(const FeedLoadNextPage());
  }

  Future<void> _onRefresh(
    FeedRefresh event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is FeedLoaded) {
      emit(currentState.copyWith(isLoadingMore: true));
    } else {
      emit(const FeedLoading());
    }

    try {
      final result = await _repository.fetchFeedPage(
        userId: _userId,
        limit: 20,
      );

      emit(FeedLoaded(
        videos: result.videos,
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(FeedError(
        message: 'Failed to refresh feed: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  Future<void> _onVideoInteraction(
    FeedVideoInteraction event,
    Emitter<FeedState> emit,
  ) async {
    // Record interaction asynchronously
    _repository
        .recordInteraction(
      userId: _userId ?? 'anonymous',
      videoId: event.videoId,
      type: event.type,
      watchTime: event.watchTime,
      metadata: event.metadata,
    )
        .catchError((e) {
      // Log error but don't block UI
    });
  }

  void _onVideoVisibilityChanged(
    FeedVideoVisibilityChanged event,
    Emitter<FeedState> emit,
  ) {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    // AC5: Auto-play when video becomes visible (>50% visible)
    final shouldPlay = event.isVisible && event.visibilityPercentage > 0.5;
    final newVisibleVideoId = shouldPlay ? event.videoId : null;

    emit(currentState.copyWith(
      currentVisibleVideoId: newVisibleVideoId,
    ));
  }

  void _onVideoPlaybackStateChanged(
    FeedVideoPlaybackStateChanged event,
    Emitter<FeedState> emit,
  ) {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    final newPlaybackStates = Map<String, bool>.from(
      currentState.videoPlaybackStates,
    );
    newPlaybackStates[event.videoId] = event.isPlaying;

    emit(currentState.copyWith(
      videoPlaybackStates: newPlaybackStates,
    ));
  }

  Future<void> _onToggleLike(
    FeedToggleLike event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    // Optimistic update
    final newLikedVideos = Map<String, bool>.from(currentState.likedVideos);
    newLikedVideos[event.videoId] = event.isLiked;

    emit(currentState.copyWith(likedVideos: newLikedVideos));

    // Record interaction asynchronously
    try {
      await _repository.recordInteraction(
        userId: _userId ?? 'anonymous',
        videoId: event.videoId,
        type: event.isLiked
            ? InteractionType.like
            : InteractionType.skip, // Use skip as unlike
      );
    } catch (e) {
      // Rollback on failure
      final rollbackLikedVideos =
          Map<String, bool>.from(currentState.likedVideos);
      rollbackLikedVideos[event.videoId] = !event.isLiked;
      emit(currentState.copyWith(likedVideos: rollbackLikedVideos));
    }
  }

  Future<void> _onToggleWishlist(
    FeedToggleWishlist event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    // Optimistic update
    final newWishlistedVideos =
        Map<String, bool>.from(currentState.wishlistedVideos);
    newWishlistedVideos[event.videoId] = event.isInWishlist;

    emit(currentState.copyWith(wishlistedVideos: newWishlistedVideos));

    // Record interaction asynchronously
    try {
      await _repository.recordInteraction(
        userId: _userId ?? 'anonymous',
        videoId: event.videoId,
        type: InteractionType.follow, // Use follow for wishlist
      );
    } catch (e) {
      // Rollback on failure
      final rollbackWishlistedVideos =
          Map<String, bool>.from(currentState.wishlistedVideos);
      rollbackWishlistedVideos[event.videoId] = !event.isInWishlist;
      emit(currentState.copyWith(wishlistedVideos: rollbackWishlistedVideos));
    }
  }
}
