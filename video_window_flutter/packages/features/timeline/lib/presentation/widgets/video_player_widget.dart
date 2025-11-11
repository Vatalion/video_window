import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus';
import '../../domain/entities/video.dart';
import 'error_boundary.dart';

/// Video player widget with performance optimizations
/// PERF-002: Video auto-play with proper resource management
/// AC1, AC2, AC5: Video playback with preloaded controllers and lifecycle management
class VideoPlayerWidget extends StatefulWidget {
  final Video video;
  final bool isPlaying;
  final Function(bool isPlaying) onPlaybackStateChanged;
  final VideoPlayerController?
      preloadedController; // AC1: Optional preloaded controller

  const VideoPlayerWidget({
    super.key,
    required this.video,
    required this.isPlaying,
    required this.onPlaybackStateChanged,
    this.preloadedController, // AC1: Use preloaded controller if available
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // AC1: Use preloaded controller if available, otherwise create new one
      if (widget.preloadedController != null) {
        _controller = widget.preloadedController;
        // Preloaded controller is already initialized
        if (_controller!.value.isInitialized) {
          _isInitialized = true;
        } else {
          await _controller!.initialize();
          _isInitialized = true;
        }
      } else {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.video.videoUrl),
        );
        await _controller!.initialize();
        _isInitialized = true;
      }

      // PERF-002: Set looping for feed videos
      _controller!.setLooping(true);

      // PERF-002: Keep screen awake during playback
      await WakelockPlus.enable();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Auto-play if requested
        if (widget.isPlaying) {
          await _controller!.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // PERF-002: Handle play/pause based on visibility
    if (widget.isPlaying != oldWidget.isPlaying && _isInitialized) {
      if (widget.isPlaying) {
        _controller?.play();
      } else {
        _controller?.pause();
      }
    }
  }

  @override
  void dispose() {
    // PERF-005: Proper disposal of VideoPlayerController
    // AC1: Only dispose if we created it (not preloaded)
    if (widget.preloadedController == null) {
      _controller?.dispose();
    }
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorBuilder: (error, stackTrace) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Video playback error',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                    });
                    _initializePlayer();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
      child: _buildPlayer(),
    );
  }

  Widget _buildPlayer() {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 48,
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Toggle play/pause on tap
        if (_controller!.value.isPlaying) {
          _controller!.pause();
          widget.onPlaybackStateChanged(false);
        } else {
          _controller!.play();
          widget.onPlaybackStateChanged(true);
        }
      },
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
