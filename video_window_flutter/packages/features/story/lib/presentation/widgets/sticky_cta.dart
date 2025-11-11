import 'package:flutter/material.dart';

/// Sticky CTA widget with "I want this" button
/// AC1: Sticky CTA section with smooth scroll-to-offers functionality
class StickyCTA extends StatelessWidget {
  final String storyId;
  final VoidCallback onCTAPressed;

  const StickyCTA({
    super.key,
    required this.storyId,
    required this.onCTAPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onCTAPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('I want this'),
          ),
        ),
      ),
    );
  }
}
