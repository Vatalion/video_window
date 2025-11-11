import 'package:flutter/material.dart';
import '../../domain/entities/story.dart';

/// Overview section widget
/// AC1: Overview section with title, category, description, and metadata
class StoryOverviewSection extends StatelessWidget {
  final ArtifactStory story;

  const StoryOverviewSection({
    super.key,
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (story.categoryId != null) ...[
            const SizedBox(height: 8),
            Chip(
              label: Text(story.categoryId!),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            story.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
