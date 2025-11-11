import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/video_interaction.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import 'video_player_widget.dart';
import 'video_overlay_controls.dart';
import 'engagement_widget.dart';
import 'preload_debug_overlay.dart';
import '../../data/services/feed_performance_service.dart';
import '../../data/services/video_preloader_service.dart';
import '../../data/repositories/feed_cache_repository.dart';

/// Video feed item widget
/// PERF-001, PERF-002: Optimized video item with auto-play
/// AC1, AC5: Video playback with preloaded controllers, visibility detection, and debug overlay
class VideoFeedItem extends StatefulWidget {
  final Video video;
  final bool isPlaying;
  final Function(bool isVisible, double percentage) onVisibilityChanged;
  final Function(InteractionType type, Duration? watchTime,
      Map<String, dynamic>? metadata) onInteraction;
  final VideoPlayerController?
      preloadedController; // AC1: Optional preloaded controller
  final FeedPerformanceService? performanceService; // AC5: For debug overlay
  final VideoPreloaderService? preloaderService; // AC5: For debug overlay
  final FeedCacheRepository? cacheRepository; // AC5: For debug overlay

  const VideoFeedItem({
    super.key,
    required this.video,
    required this.isPlaying,
    required this.onVisibilityChanged,
    required this.onInteraction,
    this.preloadedController, // AC1: Use preloaded controller if available
    this.performanceService, // AC5: Optional performance service for debug overlay
    this.preloaderService, // AC5: Optional preloader service for debug overlay
    this.cacheRepository, // AC5: Optional cache repository for debug overlay
  });

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  Timer? _debounceTimer;
  bool _showDebugOverlay = false; // AC1, AC5: Debug overlay toggle

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video_${widget.video.id}'),
      onVisibilityChanged: (info) {
        // PERF-002: Debounce visibility changes (200ms)
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 200), () {
          final percentage = info.visibleFraction;
          widget.onVisibilityChanged(percentage > 0.5, percentage);
        });
      },
      child: GestureDetector(
        onTap: () {
          // AC1: Tap to pause/play
          widget.onInteraction(
            InteractionType.view,
            null,
            {'action': 'tap'},
          );
        },
        onLongPress: () {
          // AC1, AC5: Toggle debug overlay on long-press
          setState(() {
            _showDebugOverlay = !_showDebugOverlay;
          });
        },
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video player
              VideoPlayerWidget(
                video: widget.video,
                isPlaying: widget.isPlaying,
                preloadedController:
                    widget.preloadedController, // AC1: Use preloaded controller
                onPlaybackStateChanged: (isPlaying) {
                  widget.onInteraction(
                    InteractionType.view,
                    null,
                    {'playing': isPlaying},
                  );
                },
              ),
              // AC1, AC5: Debug overlay (toggleable via long-press)
              PreloadDebugOverlay(
                isVisible: _showDebugOverlay,
                performanceService: widget.performanceService,
                preloaderService: widget.preloaderService,
                cacheRepository: widget.cacheRepository,
              ),
              // Overlay controls
              BlocBuilder<FeedBloc, FeedState>(
                builder: (context, state) {
                  final isLiked = state is FeedLoaded
                      ? state.isLiked(widget.video.id)
                      : false;
                  return VideoOverlayControls(
                    video: widget.video,
                    isLiked: isLiked,
                    onLike: () {
                      if (state is FeedLoaded) {
                        context.read<FeedBloc>().add(FeedToggleLike(
                              videoId: widget.video.id,
                              isLiked: !isLiked,
                            ));
                      }
                      widget.onInteraction(
                        InteractionType.like,
                        null,
                        {},
                      );
                    },
                    onViewStory: () {
                      widget.onInteraction(
                        InteractionType.view,
                        null,
                        {'action': 'view_story'},
                      );
                    },
                    onShare: () {
                      widget.onInteraction(
                        InteractionType.share,
                        null,
                        {},
                      );
                    },
                    onLongPress: () {
                      // Show action menu
                    },
                  );
                },
              ),
              // Engagement widget (AC7, AC8)
              BlocBuilder<FeedBloc, FeedState>(
                builder: (context, state) {
                  final isLiked = state is FeedLoaded
                      ? state.isLiked(widget.video.id)
                      : false;
                  final isInWishlist = state is FeedLoaded
                      ? state.isWishlisted(widget.video.id)
                      : false;
                  return EngagementWidget(
                    video: widget.video,
                    isLiked: isLiked,
                    isInWishlist: isInWishlist,
                    onInteraction: (type) {
                      widget.onInteraction(type, null, {});
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
