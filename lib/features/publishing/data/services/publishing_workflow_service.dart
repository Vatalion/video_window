import 'package:flutter/foundation.dart';

import '../../../domain/entities/publishing_workflow.dart';
import '../../../domain/entities/status_change.dart';
import '../../../domain/enums/publishing_status.dart';
import '../../../domain/repositories/publishing_workflow_repository.dart';

class PublishingWorkflowService implements PublishingWorkflowRepository {
  // In-memory storage for workflows (in a real app, this would be a database or API)
  final Map<String, PublishingWorkflow> _workflows = {};
  
  // In-memory storage for content workflows
  final Map<String, List<String>> _contentWorkflows = {};

  @override
  Future<PublishingWorkflow?> getWorkflow(String id) async {
    return _workflows[id];
  }

  @override
  Future<List<PublishingWorkflow>> getWorkflowsForContent(String contentId) async {
    final workflowIds = _contentWorkflows[contentId] ?? [];
    return workflowIds.map((id) => _workflows[id]!).toList();
  }

  @override
  Future<List<PublishingWorkflow>> getWorkflowsByStatus(PublishingStatus status) async {
    return _workflows.values
        .where((workflow) => workflow.currentStatus == status)
        .toList();
  }

  @override
  Future<PublishingWorkflow> createWorkflow(PublishingWorkflow workflow) async {
    _workflows[workflow.id] = workflow;
    
    // Add to content workflows mapping
    if (_contentWorkflows.containsKey(workflow.contentId)) {
      _contentWorkflows[workflow.contentId]!.add(workflow.id);
    } else {
      _contentWorkflows[workflow.contentId] = [workflow.id];
    }
    
    return workflow;
  }

  @override
  Future<PublishingWorkflow> updateWorkflow(PublishingWorkflow workflow) async {
    _workflows[workflow.id] = workflow;
    return workflow;
  }

  @override
  Future<bool> deleteWorkflow(String id) async {
    if (_workflows.containsKey(id)) {
      final workflow = _workflows[id]!;
      _workflows.remove(id);
      
      // Remove from content workflows mapping
      if (_contentWorkflows.containsKey(workflow.contentId)) {
        _contentWorkflows[workflow.contentId]!.remove(id);
        if (_contentWorkflows[workflow.contentId]!.isEmpty) {
          _contentWorkflows.remove(workflow.contentId);
        }
      }
      
      return true;
    }
    return false;
  }

  @override
  Future<PublishingWorkflow> transitionStatus(
    String workflowId,
    PublishingStatus newStatus,
    String userId, {
    String notes = '',
  }) async {
    final workflow = _workflows[workflowId];
    if (workflow == null) {
      throw Exception('Workflow not found: $workflowId');
    }

    // Validate status transition
    if (!_isValidTransition(workflow.currentStatus, newStatus)) {
      throw Exception(
          'Invalid status transition from ${workflow.currentStatus} to $newStatus');
    }

    // Create status change record
    final statusChange = StatusChange(
      fromStatus: workflow.currentStatus,
      toStatus: newStatus,
      timestamp: DateTime.now(),
      userId: userId,
      notes: notes,
    );

    // Update workflow
    final updatedWorkflow = workflow.copyWith(
      currentStatus: newStatus,
      statusHistory: [...workflow.statusHistory, statusChange],
    );

    _workflows[workflowId] = updatedWorkflow;
    return updatedWorkflow;
  }

  @override
  Future<List<StatusChange>> getStatusHistory(String workflowId) async {
    final workflow = _workflows[workflowId];
    if (workflow == null) {
      throw Exception('Workflow not found: $workflowId');
    }
    return workflow.statusHistory;
  }

  /// Validate if a status transition is allowed
  bool _isValidTransition(PublishingStatus from, PublishingStatus to) {
    // Define valid transitions
    switch (from) {
      case PublishingStatus.draft:
        return to == PublishingStatus.review || to == PublishingStatus.removed;
      case PublishingStatus.review:
        return to == PublishingStatus.draft || 
               to == PublishingStatus.scheduled || 
               to == PublishingStatus.published || 
               to == PublishingStatus.removed;
      case PublishingStatus.scheduled:
        return to == PublishingStatus.published || 
               to == PublishingStatus.draft || 
               to == PublishingStatus.review || 
               to == PublishingStatus.removed;
      case PublishingStatus.published:
        return to == PublishingStatus.archived || 
               to == PublishingStatus.removed;
      case PublishingStatus.archived:
        return to == PublishingStatus.published || 
               to == PublishingStatus.removed;
      case PublishingStatus.removed:
        // Once removed, content cannot transition to other states
        return false;
    }
  }
  
  /// Add distribution information to a workflow
  Future<void> addDistributionInfo(String workflowId, String channelId) async {
    final workflow = _workflows[workflowId];
    if (workflow == null) {
      throw Exception('Workflow not found: $workflowId');
    }

    // Add distribution channel to the workflow's distribution list
    final updatedDistributionChannels = List<String>.from(workflow.distributionChannels);
    if (!updatedDistributionChannels.contains(channelId)) {
      updatedDistributionChannels.add(channelId);
    }

    // Update workflow
    final updatedWorkflow = workflow.copyWith(
      distributionChannels: updatedDistributionChannels,
    );

    _workflows[workflowId] = updatedWorkflow;
  }
  
  /// Add distribution error information to a workflow
  Future<void> addDistributionError(String workflowId, String channelId, String error) async {
    final workflow = _workflows[workflowId];
    if (workflow == null) {
      throw Exception('Workflow not found: $workflowId');
    }

    // Add error to the workflow's distribution errors
    final updatedDistributionErrors = Map<String, String>.from(workflow.distributionErrors);
    updatedDistributionErrors[channelId] = error;

    // Update workflow
    final updatedWorkflow = workflow.copyWith(
      distributionErrors: updatedDistributionErrors,
    );

    _workflows[workflowId] = updatedWorkflow;
  }
}