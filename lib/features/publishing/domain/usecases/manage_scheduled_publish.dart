import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/publishing_workflow.dart';
import '../../domain/entities/scheduled_publish.dart';
import '../../domain/enums/publishing_status.dart';
import '../../domain/repositories/publishing_workflow_repository.dart';
import '../../domain/repositories/scheduled_publish_repository.dart';
import '../entities/status_change.dart';

class ManageScheduledPublish {
  final PublishingWorkflowRepository _workflowRepository;
  final ScheduledPublishRepository _scheduledRepository;
  final ManageNotifications _notificationsManager;

  ManageScheduledPublish({
    required PublishingWorkflowRepository workflowRepository,
    required ScheduledPublishRepository scheduledRepository,
    required ManageNotifications notificationsManager,
  })  : _workflowRepository = workflowRepository,
        _scheduledRepository = scheduledRepository,
        _notificationsManager = notificationsManager;

  /// Schedule content for publishing at a specific time
  Future<ScheduledPublish> scheduleContent({
    required String workflowId,
    required DateTime scheduledTime,
    required String timezone,
    required String userId,
    bool isRecurring = false,
    RecurrencePattern? recurrencePattern,
  }) async {
    final workflow = await _workflowRepository.getWorkflow(workflowId);
    if (workflow == null) {
      throw Exception('Workflow not found: $workflowId');
    }

    // Check if workflow is in a valid state for scheduling
    if (workflow.currentStatus != PublishingStatus.review &&
        workflow.currentStatus != PublishingStatus.draft) {
      throw Exception(
          'Content must be in draft or review status to be scheduled');
    }

    // Create scheduled publish entity
    final scheduledPublish = ScheduledPublish(
      id: '${workflowId}_${DateTime.now().millisecondsSinceEpoch}',
      workflowId: workflowId,
      scheduledTime: scheduledTime,
      timezone: timezone,
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
    );

    // Save scheduled publish
    final savedScheduledPublish =
        await _scheduledRepository.createScheduledPublish(scheduledPublish);

    // Update workflow with scheduled time
    final statusChange = StatusChange(
      fromStatus: workflow.currentStatus,
      toStatus: PublishingStatus.scheduled,
      timestamp: DateTime.now(),
      userId: userId,
      notes: 'Content scheduled for publishing',
    );

    final updatedWorkflow = workflow.copyWith(
      scheduledPublishTime: scheduledTime,
      currentStatus: PublishingStatus.scheduled,
      statusHistory: [...workflow.statusHistory, statusChange],
    );

    await _workflowRepository.updateWorkflow(updatedWorkflow);

    // Send notification about scheduled publish
    await _notificationsManager.sendScheduledPublishNotification(
      workflowId: workflowId,
      scheduledTime: scheduledTime,
    );

    return savedScheduledPublish;
  }

  /// Update an existing scheduled publish
  Future<ScheduledPublish> updateScheduledContent({
    required String scheduledPublishId,
    DateTime? scheduledTime,
    String? timezone,
    bool? isRecurring,
    RecurrencePattern? recurrencePattern,
  }) async {
    final scheduledPublish =
        await _scheduledRepository.getScheduledPublish(scheduledPublishId);
    if (scheduledPublish == null) {
      throw Exception('Scheduled publish not found: $scheduledPublishId');
    }

    final updatedScheduledPublish = scheduledPublish.copyWith(
      scheduledTime: scheduledTime,
      timezone: timezone,
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
    );

    return _scheduledRepository.updateScheduledPublish(updatedScheduledPublish);
  }

  /// Cancel a scheduled publish
  Future<void> cancelScheduledContent({
    required String workflowId,
    required String userId,
  }) async {
    final workflow = await _workflowRepository.getWorkflow(workflowId);
    if (workflow == null) {
      throw Exception('Workflow not found: $workflowId');
    }

    // Get all scheduled publishes for this workflow
    final scheduledPublishes =
        await _scheduledRepository.getScheduledPublishesForWorkflow(workflowId);

    // Delete all scheduled publishes for this workflow
    for (final scheduledPublish in scheduledPublishes) {
      await _scheduledRepository.deleteScheduledPublish(scheduledPublish.id);
    }

    // Update workflow status back to draft
    final statusChange = StatusChange(
      fromStatus: workflow.currentStatus,
      toStatus: PublishingStatus.draft,
      timestamp: DateTime.now(),
      userId: userId,
      notes: 'Scheduled publish cancelled',
    );

    final updatedWorkflow = workflow.copyWith(
      scheduledPublishTime: null,
      currentStatus: PublishingStatus.draft,
      statusHistory: [...workflow.statusHistory, statusChange],
    );

    await _workflowRepository.updateWorkflow(updatedWorkflow);
  }

  /// Get all scheduled publishes for a workflow
  Future<List<ScheduledPublish>> getScheduledPublishesForWorkflow(
      String workflowId) async {
    return _scheduledRepository.getScheduledPublishesForWorkflow(workflowId);
  }

  /// Get scheduled publishes within a date range
  Future<List<ScheduledPublish>> getScheduledPublishesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _scheduledRepository.getScheduledPublishesByDateRange(
      startDate,
      endDate,
    );
  }
}