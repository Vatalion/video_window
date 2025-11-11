import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/video_player_state.dart';
import '../../use_cases/play_video_use_case.dart';
import '../../../core/services/analytics_service.dart';
import '../analytics/story_analytics_events.dart';

/// Events for video player
abstract class VideoPlayerEvent {}

class VideoPlayerInitialize extends VideoPlayerEvent {
  final String signedUrl;
  final VideoQuality quality;

  VideoPlayerInitialize({
    required this.signedUrl,
    required this.quality,
  });
}

class VideoPlayerPlay extends VideoPlayerEvent {}

class VideoPlayerPause extends VideoPlayerEvent {}

class VideoPlayerSeek extends VideoPlayerEvent {
  final Duration position;
  VideoPlayerSeek(this.position);
}

class VideoPlayerToggleCaptions extends VideoPlayerEvent {}

class VideoPlayerToggleFullscreen extends VideoPlayerEvent {}

class VideoPlayerQualityChanged extends VideoPlayerEvent {
  final VideoQuality quality;
  VideoPlayerQualityChanged(this.quality);
}

/// BLoC for video player state management
/// AC2, AC3, AC4, AC6, AC7: Video playback with controls, accessibility, content protection, and analytics
class VideoPlayerBloc extends Bloc<VideoPlayerEvent, VideoPlayerStateEntity> {
  final PlayVideoUseCase _playVideoUseCase;
  final AnalyticsService? _analyticsService;
  final String? _storyId;
  final String _currentLanguage;
  VideoPlayerController? _controller;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _stateSubscription;

  VideoPlayerBloc({
    required PlayVideoUseCase playVideoUseCase,
    AnalyticsService? analyticsService,
    String? storyId,
    String currentLanguage = 'en',
  })  : _playVideoUseCase = playVideoUseCase,
        _analyticsService = analyticsService,
        _storyId = storyId,
        _currentLanguage = currentLanguage,
        super(const VideoPlayerStateEntity(
          position: Duration.zero,
          duration: Duration.zero,
          isPlaying: false,
          isBuffering: false,
          isFullscreen: false,
          captionsEnabled: false,
          quality: VideoQuality.hd,
        )) {
    on<VideoPlayerInitialize>(_onInitialize);
    on<VideoPlayerPlay>(_onPlay);
    on<VideoPlayerPause>(_onPause);
    on<VideoPlayerSeek>(_onSeek);
    on<VideoPlayerToggleCaptions>(_onToggleCaptions);
    on<VideoPlayerToggleFullscreen>(_onToggleFullscreen);
    on<VideoPlayerQualityChanged>(_onQualityChanged);
  }

  Future<void> _onInitialize(
    VideoPlayerInitialize event,
    Emitter<VideoPlayerStateEntity> emit,
  ) async {
    try {
      _controller?.dispose();
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(event.signedUrl));
      await _controller!.initialize();

      _positionSubscription?.cancel();
      _positionSubscription = _controller!.positionStream.listen((position) {
        add(VideoPlayerSeek(position));
      });

      _stateSubscription?.cancel();
      _stateSubscription = _controller!.stateStream.listen((playerState) {
        emit(state.copyWith(
          isPlaying: playerState == VideoPlayerState.playing,
          isBuffering: playerState == VideoPlayerState.buffering,
        ));
      });

      emit(state.copyWith(
        duration: _controller!.value.duration,
        quality: event.quality,
      ));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Failed to initialize video: ${e.toString()}'));
    }
  }

  void _onPlay(
    VideoPlayerPlay event,
    Emitter<VideoPlayerStateEntity> emit,
  ) {
    _controller?.play();
    emit(state.copyWith(isPlaying: true));
  }

  void _onPause(
    VideoPlayerPause event,
    Emitter<VideoPlayerStateEntity> emit,
  ) {
    _controller?.pause();
    emit(state.copyWith(isPlaying: false));
  }

  void _onSeek(
    VideoPlayerSeek event,
    Emitter<VideoPlayerStateEntity> emit,
  ) {
    _controller?.seekTo(event.position);
    emit(state.copyWith(position: event.position));
  }

  void _onToggleCaptions(
    VideoPlayerToggleCaptions event,
    Emitter<VideoPlayerStateEntity> emit,
  ) {
    final wasEnabled = state.captionsEnabled;
    emit(state.copyWith(captionsEnabled: !wasEnabled));

    // AC7: Emit analytics event for caption toggle
    if (_analyticsService != null && _storyId != null) {
      final event = StoryCaptionToggledEvent(
        storyId: _storyId!,
        language: _currentLanguage,
        wasEnabled: wasEnabled,
      );
      _analyticsService!.trackEvent(event);
    }
  }

  void _onToggleFullscreen(
    VideoPlayerToggleFullscreen event,
    Emitter<VideoPlayerStateEntity> emit,
  ) {
    emit(state.copyWith(isFullscreen: !state.isFullscreen));
  }

  void _onQualityChanged(
    VideoPlayerQualityChanged event,
    Emitter<VideoPlayerStateEntity> emit,
  ) {
    emit(state.copyWith(quality: event.quality));
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    _controller?.dispose();
    return super.close();
  }
}
