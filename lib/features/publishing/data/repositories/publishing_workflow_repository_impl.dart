import 'package:flutter/foundation.dart';

import '../../domain/entities/publishing_workflow.dart';
import '../../domain/entities/status_change.dart';
import '../../domain/enums/publishing_status.dart';
import '../../domain/repositories/publishing_workflow_repository.dart';
import '../services/publishing_workflow_service.dart';
import '../services/content_processing_service.dart';

class PublishingWorkflowRepositoryImpl implements PublishingWorkflowRepository {
  final PublishingWorkflowService _workflowService;
  final ContentProcessingService _processingService;

  PublishingWorkflowRepositoryImpl({
    required PublishingWorkflowService workflowService,
    required ContentProcessingService processingService,
  })  : _workflowService = workflowService,
        _processingService = processingService;

  @override
  Future<PublishingWorkflow?> getWorkflow(String id) async {
    return _workflowService.getWorkflow(id);
  }

  @override
  Future<List<PublishingWorkflow>> getWorkflowsForContent(String contentId) async {
    return _workflowService.getWorkflowsForContent(contentId);
  }

  @override
  Future<List<PublishingWorkflow>> getWorkflowsByStatus(PublishingStatus status) async {
    return _workflowService.getWorkflowsByStatus(status);
  }

  @override
  Future<PublishingWorkflow> createWorkflow(PublishingWorkflow workflow) async {
    return _workflowService.createWorkflow(workflow);
  }

  @override
  Future<PublishingWorkflow> updateWorkflow(PublishingWorkflow workflow) async {
    return _workflowService.updateWorkflow(workflow);
  }

  @override
  Future<bool> deleteWorkflow(String id) async {
    return _workflowService.deleteWorkflow(id);
  }

  @override
  Future<PublishingWorkflow> transitionStatus(
    String workflowId,
    PublishingStatus newStatus,
    String userId, {
    String notes = '',
  }) async {
    // If transitioning to published, process content first
    if (newStatus == PublishingStatus.published) {
      final workflow = await _workflowService.getWorkflow(workflowId);
      if (workflow != null) {
        final result = await _processingService.processContent(workflow);
        if (!result.isSuccess) {
          throw Exception('Content processing failed: ${result.errorMessage}');
        }
      }
    }

    return _workflowService.transitionStatus(
      workflowId,
      newStatus,
      userId,
      notes: notes,
    );
  }

  @override
  Future<List<StatusChange>> getStatusHistory(String workflowId) async {
    return _workflowService.getStatusHistory(workflowId);
  }
}