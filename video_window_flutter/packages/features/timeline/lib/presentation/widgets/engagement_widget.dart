import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/video_interaction.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';

/// Engagement widget with reactions, wishlist, and share
/// AC7, AC8: Engagement features with optimistic UI updates
class EngagementWidget extends StatefulWidget {
  final Video video;
  final bool isLiked;
  final bool isInWishlist;
  final Function(InteractionType type) onInteraction;

  const EngagementWidget({
    super.key,
    required this.video,
    this.isLiked = false,
    this.isInWishlist = false,
    required this.onInteraction,
  });

  @override
  State<EngagementWidget> createState() => _EngagementWidgetState();
}

class _EngagementWidgetState extends State<EngagementWidget> {
  bool _optimisticLiked = false;
  bool _optimisticWishlist = false;

  @override
  void initState() {
    super.initState();
    _optimisticLiked = widget.isLiked;
    _optimisticWishlist = widget.isInWishlist;
  }

  void _handleLike() {
    setState(() {
      _optimisticLiked = !_optimisticLiked;
    });
    HapticFeedback.mediumImpact();

    // Update BLoC state (handles rollback on failure)
    final context = this.context;
    if (context.mounted) {
      context.read<FeedBloc>().add(FeedToggleLike(
            videoId: widget.video.id,
            isLiked: _optimisticLiked,
          ));
    }

    widget.onInteraction(InteractionType.like);
  }

  void _handleWishlist() {
    setState(() {
      _optimisticWishlist = !_optimisticWishlist;
    });
    HapticFeedback.lightImpact();

    // Update BLoC state (handles rollback on failure)
    final context = this.context;
    if (context.mounted) {
      context.read<FeedBloc>().add(FeedToggleWishlist(
            videoId: widget.video.id,
            isInWishlist: _optimisticWishlist,
          ));
    }

    widget.onInteraction(InteractionType.follow);
  }

  void _handleShare() {
    HapticFeedback.mediumImpact();
    widget.onInteraction(InteractionType.share);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EngagementButton(
            icon: _optimisticLiked ? Icons.favorite : Icons.favorite_border,
            label: '${widget.video.likeCount + (_optimisticLiked ? 1 : 0)}',
            color: _optimisticLiked ? Colors.red : Colors.white,
            onTap: _handleLike,
          ),
          const SizedBox(height: 16),
          _EngagementButton(
            icon: _optimisticWishlist ? Icons.bookmark : Icons.bookmark_border,
            label: 'Save',
            color: _optimisticWishlist ? Colors.amber : Colors.white,
            onTap: _handleWishlist,
          ),
          const SizedBox(height: 16),
          _EngagementButton(
            icon: Icons.share,
            label: 'Share',
            onTap: _handleShare,
          ),
        ],
      ),
    );
  }
}

class _EngagementButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _EngagementButton({
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
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
