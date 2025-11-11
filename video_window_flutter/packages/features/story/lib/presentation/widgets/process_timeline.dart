import 'package:flutter/material.dart';
import '../../domain/entities/story.dart';

/// Process timeline section as vertical-scroll development journal
/// AC1: Process Timeline component with chronological entries
class ProcessTimelineSection extends StatelessWidget {
  final StorySection section;

  const ProcessTimelineSection({
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
          // Process timeline entries would be rendered here
          // Placeholder for actual timeline implementation
          Text(
            'Process timeline content',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
