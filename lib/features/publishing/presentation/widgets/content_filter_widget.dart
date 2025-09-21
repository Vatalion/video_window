import 'package:flutter/material.dart';

import '../../domain/enums/publishing_status.dart';

class ContentFilterWidget extends StatelessWidget {
  final PublishingStatus selectedStatus;
  final Function(PublishingStatus) onStatusChanged;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const ContentFilterWidget({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search content...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 16),
        
        // Status filter chips
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: PublishingStatus.values.map((status) {
            return FilterChip(
              label: Text(status.label),
              selected: selectedStatus == status,
              onSelected: (selected) {
                if (selected) {
                  onStatusChanged(status);
                }
              },
              selectedColor: _getStatusColor(status),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getStatusColor(PublishingStatus status) {
    switch (status) {
      case PublishingStatus.draft:
        return Colors.grey.withOpacity(0.3);
      case PublishingStatus.review:
        return Colors.orange.withOpacity(0.3);
      case PublishingStatus.scheduled:
        return Colors.blue.withOpacity(0.3);
      case PublishingStatus.published:
        return Colors.green.withOpacity(0.3);
      case PublishingStatus.archived:
        return Colors.purple.withOpacity(0.3);
      case PublishingStatus.removed:
        return Colors.red.withOpacity(0.3);
    }
  }
}