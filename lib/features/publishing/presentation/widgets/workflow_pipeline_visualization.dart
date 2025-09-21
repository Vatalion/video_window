import 'package:flutter/material.dart';

import '../../domain/entities/publishing_workflow.dart';
import '../../domain/enums/publishing_status.dart';

class WorkflowPipelineVisualization extends StatelessWidget {
  final PublishingWorkflow workflow;
  final Function(PublishingStatus) onStageTap;

  const WorkflowPipelineVisualization({
    super.key,
    required this.workflow,
    required this.onStageTap,
  });

  // Define the workflow stages in order
  static const List<PublishingStatus> workflowStages = [
    PublishingStatus.draft,
    PublishingStatus.review,
    PublishingStatus.scheduled,
    PublishingStatus.published,
    PublishingStatus.archived,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publishing Workflow Pipeline',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildPipeline(context),
        ],
      ),
    );
  }

  Widget _buildPipeline(BuildContext context) {
    return Row(
      children: workflowStages.map((stage) {
        final isCurrentStage = workflow.currentStatus == stage;
        final isCompletedStage = _isStageCompleted(stage);
        
        return Expanded(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => onStageTap(stage),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrentStage 
                        ? _getStatusColor(stage) 
                        : (isCompletedStage ? _getStatusColor(stage).withOpacity(0.7) : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrentStage 
                        ? Border.all(color: Theme.of(context).primaryColor, width: 2) 
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      stage.label,
                      style: TextStyle(
                        color: isCurrentStage || isCompletedStage 
                            ? Colors.white 
                            : Colors.grey[600],
                        fontWeight: isCurrentStage ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Show stage completion icon
              if (isCompletedStage)
                const Icon(Icons.check_circle, color: Colors.green, size: 16)
              else if (isCurrentStage)
                const Icon(Icons.circle, color: Colors.orange, size: 16)
              else
                const Icon(Icons.circle_outlined, color: Colors.grey, size: 16),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Check if a stage has been completed in the workflow
  bool _isStageCompleted(PublishingStatus stage) {
    // If the current stage is the same as or after the given stage, it's completed
    final currentIndex = workflowStages.indexOf(workflow.currentStatus);
    final stageIndex = workflowStages.indexOf(stage);
    
    return stageIndex < currentIndex;
  }

  /// Get color for a status
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