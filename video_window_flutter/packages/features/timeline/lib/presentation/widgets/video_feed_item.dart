import 'dart:async';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/video_interaction.dart';
import 'video_player_widget.dart';
import 'video_overlay_controls.dart';
import 'engagement_widget.dart';

/// Video feed item widget
/// PERF-001, PERF-002: Optimized video item with auto-play
/// AC1, AC5: Video playback with visibility detection
class VideoFeedItem extends StatefulWidget {
  final Video video;
  final bool isPlaying;
  final Function(bool isVisible, double percentage) onVisibilityChanged;
  final Function(InteractionType type, Duration? watchTime,
      Map<String, dynamic>? metadata) onInteraction;

  const VideoFeedItem({
    super.key,
    required this.video,
    required this.isPlaying,
    required this.onVisibilityChanged,
    required this.onInteraction,
  });

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  Timer? _debounceTimer;

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
                onPlaybackStateChanged: (isPlaying) {
                  widget.onInteraction(
                    InteractionType.view,
                    null,
                    {'playing': isPlaying},
                  );
                },
              ),
              // Overlay controls
              VideoOverlayControls(
                video: widget.video,
                isLiked: false, // TODO: Get from state
                onLike: () {
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
              ),
              // Engagement widget (AC7, AC8)
              EngagementWidget(
                video: widget.video,
                isLiked: false, // TODO: Get from state
                isInWishlist: false, // TODO: Get from state
                onInteraction: (type) {
                  widget.onInteraction(type, null, {});
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
