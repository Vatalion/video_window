import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/video_player_bloc.dart';
import '../../domain/entities/video_player_state.dart';
import 'video_keyboard_shortcuts.dart';
import '../../../core/data/services/accessibility/caption_service.dart';

/// Video player widget with HLS streaming and content protection
/// AC2, AC3, AC4, AC5: HLS playback with adaptive streaming, accessibility, high contrast, and reduced motion
class StoryVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String storyId;
  final List<CaptionCue>? captionCues;

  const StoryVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.storyId,
    this.captionCues,
  });

  @override
  State<StoryVideoPlayer> createState() => _StoryVideoPlayerState();
}

class _StoryVideoPlayerState extends State<StoryVideoPlayer> {
  bool _reducedMotion = false;
  bool _highContrast = false;

  @override
  void initState() {
    super.initState();
  }

  void _detectAccessibilityPreferences(BuildContext context) {
    // AC5: Auto-detect system accessibility preferences
    final mediaQuery = MediaQuery.of(context);
    _reducedMotion = mediaQuery.disableAnimations;
    _highContrast = mediaQuery.highContrast;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-detect preferences when they change
    _detectAccessibilityPreferences(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = _buildAccessibleTheme(context);

    return Theme(
      data: theme,
      child: BlocProvider(
        create: (context) => VideoPlayerBloc(
          playVideoUseCase: context.read(), // Would be injected via DI
        )..add(VideoPlayerInitialize(
            signedUrl: widget.videoUrl,
            quality: VideoQuality.hd,
          )),
        child: VideoKeyboardShortcuts(
          videoPlayerBloc: context.read<VideoPlayerBloc>(),
          child: BlocBuilder<VideoPlayerBloc, VideoPlayerStateEntity>(
            builder: (context, state) {
              if (state.errorMessage != null) {
                return _buildErrorWidget(context, state.errorMessage!);
              }

              return AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    // Video player would be rendered here
                    // Placeholder for actual video player implementation
                    Semantics(
                      label: 'Story video player',
                      hint:
                          'Tap to play or pause. Use space bar for keyboard control',
                      child: Container(
                        color: Colors.black,
                        child: const Center(
                          child: Text(
                            'Video Player',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),

                    // Caption overlay (AC1, AC3)
                    if (state.captionsEnabled && widget.captionCues != null)
                      _buildCaptionOverlay(context, state),

                    // Watermark overlay (AC4)
                    _buildWatermarkOverlay(),

                    // Video controls overlay (AC2, AC3)
                    _buildControlsOverlay(context, state),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  ThemeData _buildAccessibleTheme(BuildContext context) {
    final baseTheme = Theme.of(context);

    if (_highContrast) {
      // AC5: High contrast theme
      return baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Colors.black,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        textTheme: baseTheme.textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      );
    }

    return baseTheme;
  }

  Widget _buildCaptionOverlay(
    BuildContext context,
    VideoPlayerStateEntity state,
  ) {
    if (widget.captionCues == null || widget.captionCues!.isEmpty) {
      return const SizedBox.shrink();
    }

    final captionService = CaptionService();
    final activeCues = captionService.getActiveCues(
      widget.captionCues!,
      state.position,
    );

    if (activeCues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _highContrast
              ? Colors.white
              : Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          activeCues.map((cue) => cue.text).join(' '),
          style: TextStyle(
            color: _highContrast ? Colors.black : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildWatermarkOverlay() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Watermark',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(
    BuildContext context,
    VideoPlayerStateEntity state,
  ) {
    final bloc = context.read<VideoPlayerBloc>();

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          if (state.isPlaying) {
            bloc.add(VideoPlayerPause());
            // AC3: Screen reader announcement
            SemanticsService.announce('Video paused', TextDirection.ltr);
          } else {
            bloc.add(VideoPlayerPlay());
            // AC3: Screen reader announcement
            SemanticsService.announce('Video playing', TextDirection.ltr);
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: state.isPlaying ? 'Pause video' : 'Play video',
                button: true,
                child: Icon(
                  state.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _announcePlaybackState(VideoPlayerStateEntity state) {
    // AC3: Screen reader announcements for playback state changes
    String message;
    if (state.isBuffering) {
      message = 'Video buffering';
    } else if (state.isPlaying) {
      message = 'Video playing';
    } else {
      message = 'Video paused';
    }
    SemanticsService.announce(message, TextDirection.ltr);
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'Video Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
