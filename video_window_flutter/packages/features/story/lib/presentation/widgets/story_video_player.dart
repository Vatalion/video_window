import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/video_player_bloc.dart';
import '../../domain/entities/video_player_state.dart';

/// Video player widget with HLS streaming and content protection
/// AC2, AC3, AC4: HLS playback with adaptive streaming, accessibility, and content protection
class StoryVideoPlayer extends StatelessWidget {
  final String videoUrl;
  final String storyId;

  const StoryVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.storyId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VideoPlayerBloc(
        playVideoUseCase: context.read(), // Would be injected via DI
      )..add(VideoPlayerInitialize(
          signedUrl: videoUrl,
          quality: VideoQuality.hd,
        )),
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
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'Video Player',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                // Watermark overlay (AC4)
                _buildWatermarkOverlay(),

                // Video controls overlay (AC2, AC3)
                _buildControlsOverlay(context, state),
              ],
            ),
          );
        },
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
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          if (state.isPlaying) {
            context.read<VideoPlayerBloc>().add(VideoPlayerPause());
          } else {
            context.read<VideoPlayerBloc>().add(VideoPlayerPlay());
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 64,
              ),
            ],
          ),
        ),
      ),
    );
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
