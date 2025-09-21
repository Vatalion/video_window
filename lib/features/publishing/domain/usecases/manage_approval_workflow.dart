import 'package:flutter/foundation.dart';

import '../../domain/entities/publishing_workflow.dart';
import '../../domain/entities/status_change.dart';
import '../../domain/enums/publishing_status.dart';
import '../../domain/repositories/publishing_workflow_repository.dart';

class ManageApprovalWorkflow {
  final PublishingWorkflowRepository repository;

  ManageApprovalWorkflow({required this.repository});

  /// Submit content for approval and route to appropriate reviewers
  Future<PublishingWorkflow> submitForApproval({
    required String workflowId,
    required String userId,
    required List<String> approvers,
    String notes = '',
  }) async {
    final workflow = await repository.getWorkflow(workflowId);
    if (workflow == null) {
      throw Exception('Workflow not found: $workflowId');
    }

    // Add status change record
    final statusChange = StatusChange(
      fromStatus: workflow.currentStatus,
      toStatus: PublishingStatus.review,
      timestamp: DateTime.now(),
      userId: userId,
      notes: notes,
    );

    // Update workflow with approvers and transition to review status
    final updatedWorkflow = workflow.copyWith(
      approvalRequired: true,
      approvers: approvers,
      currentStatus: PublishingStatus.review,
      statusHistory: [...workflow.statusHistory, statusChange],
    );

    // Send notifications to approvers
    await _notifyApprovers(workflowId, approvers);

    return repository.updateWorkflow(updatedWorkflow);
  }

  /// Approve content in workflow
  Future<PublishingWorkflow> approveContent({
    required String workflowId,
    required String approverId,
    String notes = '',
  }) async {
    final workflow = await repository.getWorkflow(workflowId);
    if (workflow == null) {
      throw Exception('Workflow not found: $workflowId');
    }

    // Check if user is authorized to approve
    if (!workflow.approvers.contains(approverId)) {
      throw Exception('User $approverId is not authorized to approve this content');
    }

    // Check if workflow is in review status
    if (workflow.currentStatus != PublishingStatus.review) {
      throw Exception('Content is not in review status');
    }

    // Transition to next status (scheduled or published based on workflow settings)
    final nextStatus = workflow.scheduledPublishTime != null 
        ? PublishingStatus.scheduled 
        : PublishingStatus.published;

    final statusChange = StatusChange(
      fromStatus: PublishingStatus.review,
      toStatus: nextStatus,
      timestamp: DateTime.now(),
      userId: approverId,
      notes: notes,
    );

    final updatedWorkflow = workflow.copyWith(
      currentStatus: nextStatus,
      statusHistory: [...workflow.statusHistory, statusChange],
    );

    // Send notification to content creator
    await _notifyCreator(workflowId, 'Content approved', notes);

    return repository.updateWorkflow(updatedWorkflow);
  }

  /// Reject content in workflow and return to draft status
  Future<PublishingWorkflow> rejectContent({
    required String workflowId,
    required String approverId,
    String notes = '',
  }) async {
    final workflow = await repository.getWorkflow(workflowId);
    if (workflow == null) {
      throw Exception('Workflow not found: $workflowId');
    }

    // Check if user is authorized to reject
    if (!workflow.approvers.contains(approverId)) {
      throw Exception('User $approverId is not authorized to reject this content');
    }

    // Check if workflow is in review status
    if (workflow.currentStatus != PublishingStatus.review) {
      throw Exception('Content is not in review status');
    }

    final statusChange = StatusChange(
      fromStatus: PublishingStatus.review,
      toStatus: PublishingStatus.draft,
      timestamp: DateTime.now(),
      userId: approverId,
      notes: notes,
    );

    final updatedWorkflow = workflow.copyWith(
      currentStatus: PublishingStatus.draft,
      statusHistory: [...workflow.statusHistory, statusChange],
    );

    // Send notification to content creator
    await _notifyCreator(workflowId, 'Content rejected', notes);

    return repository.updateWorkflow(updatedWorkflow);
  }

  /// Request changes to content in workflow and return to draft status
  Future<PublishingWorkflow> requestChanges({
    required String workflowId,
    required String approverId,
    String notes = '',
  }) async {
    final workflow = await repository.getWorkflow(workflowId);
    if (workflow == null) {
      throw Exception('Workflow not found: $workflowId');
    }

    // Check if user is authorized to request changes
    if (!workflow.approvers.contains(approverId)) {
      throw Exception('User $approverId is not authorized to request changes for this content');
    }

    // Check if workflow is in review status
    if (workflow.currentStatus != PublishingStatus.review) {
      throw Exception('Content is not in review status');
    }

    final statusChange = StatusChange(
      fromStatus: PublishingStatus.review,
      toStatus: PublishingStatus.draft,
      timestamp: DateTime.now(),
      userId: approverId,
      notes: notes,
    );

    final updatedWorkflow = workflow.copyWith(
      currentStatus: PublishingStatus.draft,
      statusHistory: [...workflow.statusHistory, statusChange],
    );

    // Send notification to content creator
    await _notifyCreator(workflowId, 'Changes requested', notes);

    return repository.updateWorkflow(updatedWorkflow);
  }

  /// Send notifications to approvers
  Future<void> _notifyApprovers(String workflowId, List<String> approvers) async {
    // In a real implementation, this would send push notifications or emails
    // to the approvers letting them know they have content to review
    debugPrint('Notifying approvers: $approvers for workflow: $workflowId');
  }

  /// Send notification to content creator
  Future<void> _notifyCreator(String workflowId, String title, String message) async {
    // In a real implementation, this would send a push notification or email
    // to the content creator about the status change
    debugPrint('Notifying creator about workflow: $workflowId - $title: $message');
  }
}