import 'package:flutter/material.dart';
import '../../domain/entities/story.dart';

/// Materials & Tools section widget
/// AC1: Materials & Tools section with expandable item details
class MaterialsSection extends StatelessWidget {
  final StorySection section;

  const MaterialsSection({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          // Materials list would be rendered here
          // Placeholder for actual materials implementation
          Text(
            'Materials content',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
