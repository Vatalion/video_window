import 'package:flutter/material.dart';

import '../../domain/entities/publishing_workflow.dart';
import '../../domain/enums/publishing_status.dart';

class WorkflowStatusCard extends StatelessWidget {
  final PublishingWorkflow workflow;
  final VoidCallback onTap;

  const WorkflowStatusCard({
    super.key,
    required this.workflow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Content ID: ${workflow.contentId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(workflow.currentStatus),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      workflow.currentStatus.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Workflow ID: ${workflow.id}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Created: ${workflow.statusHistory.first.timestamp}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (workflow.scheduledPublishTime != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Scheduled: ${workflow.scheduledPublishTime}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (workflow.approvalRequired) ...[
                const SizedBox(height: 4),
                Text(
                  'Approval Required',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PublishingStatus status) {
    switch (status) {
      case PublishingStatus.draft:
        return Colors.grey;
      case PublishingStatus.review:
        return Colors.orange;
      case PublishingStatus.scheduled:
        return Colors.blue;
      case PublishingStatus.published:
        return Colors.green;
      case PublishingStatus.archived:
        return Colors.purple;
      case PublishingStatus.removed:
        return Colors.red;
    }
  }
}