import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/video.dart';
ay with like button, view story CTA, and long-press menu
class VideoOverlayControls extends StatelessWidget {
  final Video video;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onViewStory;
  final VoidCallback onShare;
  final VoidCallback onLongPress;

  const VideoOverlayControls({
    super.key,
    required this.video,
    this.isLiked = false,
    required this.onLike,
    required this.onViewStory,
    required this.onShare,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Video info
            Text(
              video.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '@${video.makerId}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${video.likeCount}',
                  color: isLiked ? Colors.red : Colors.white,
                  onTap: () {
                    HapticFeedback.mediumImpact(); // AC7: Haptic feedback
                    onLike();
                  },
                ),
                _ActionButton(
                  icon: Icons.visibility,
                  label: '${video.viewCount}',
                  onTap: onViewStory,
                ),
                _ActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: onShare,
                ),
                GestureDetector(
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    onLongPress();
                  },
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
