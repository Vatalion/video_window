import 'package:flutter/foundation.dart';

import '../entities/publishing_workflow.dart';
import '../enums/publishing_status.dart';

abstract class PublishingWorkflowRepository {
  /// Get a publishing workflow by ID
  Future<PublishingWorkflow?> getWorkflow(String id);

  /// Get all workflows for a specific content ID
  Future<List<PublishingWorkflow>> getWorkflowsForContent(String contentId);

  /// Get all workflows with a specific status
  Future<List<PublishingWorkflow>> getWorkflowsByStatus(PublishingStatus status);

  /// Create a new publishing workflow
  Future<PublishingWorkflow> createWorkflow(PublishingWorkflow workflow);

  /// Update an existing publishing workflow
  Future<PublishingWorkflow> updateWorkflow(PublishingWorkflow workflow);

  /// Delete a publishing workflow
  Future<bool> deleteWorkflow(String id);

  /// Transition a workflow to a new status
  Future<PublishingWorkflow> transitionStatus(
    String workflowId,
    PublishingStatus newStatus,
    String userId,
    {String notes = ''},
  );

  /// Get workflow status history
  Future<List<StatusChange>> getStatusHistory(String workflowId);
}