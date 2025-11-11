import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gesture handler for TikTok-style feed interactions
/// AC1, AC7: Swipe gestures and tap interactions
class FeedGestureHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FeedGestureHandler({
    super.key,
    required this.child,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress?.call();
      },
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          // AC1: Swipe-up for story detail, swipe-down for refresh
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -500) {
              // Swipe up
              HapticFeedback.lightImpact();
              onSwipeUp?.call();
            } else if (details.primaryVelocity! > 500) {
              // Swipe down
              HapticFeedback.lightImpact();
              onSwipeDown?.call();
            }
          }
        },
        child: child,
      ),
    );
  }
}
