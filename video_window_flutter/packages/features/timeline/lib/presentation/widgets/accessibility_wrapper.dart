import 'package:flutter/material.dart';

/// AC7: Accessibility compliance with semantic labels and screen reader support
class AccessibilityWrapper extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final bool isVideo;
  final VoidCallback? onTap;

  const AccessibilityWrapper({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.isVideo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      image: isVideo,
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}
