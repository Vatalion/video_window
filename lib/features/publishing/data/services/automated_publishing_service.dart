import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/entities/scheduled_publish.dart';
import '../../domain/enums/publishing_status.dart';
import '../../domain/repositories/scheduled_publish_repository.dart';
import '../../domain/repositories/publishing_workflow_repository.dart';
import '../services/content_processing_service.dart';
import 'package:uuid/uuid.dart';
import '../../domain/usecases/manage_notifications.dart';

class AutomatedPublishingService {
  final ScheduledPublishRepository _scheduledPublishRepository;
  final PublishingWorkflowRepository _workflowRepository;
  final ContentProcessingService _contentProcessingService;
  final ManageNotifications _notificationsManager;
  
  Timer? _publishingTimer;
  Timer? _reminderTimer;
  final Duration _checkInterval;
  final Duration _reminderInterval;

  AutomatedPublishingService({
    required ScheduledPublishRepository scheduledPublishRepository,
    required PublishingWorkflowRepository workflowRepository,
    required ContentProcessingService contentProcessingService,
    required ManageNotifications notificationsManager,
    Duration checkInterval = const Duration(minutes: 1),
    Duration reminderInterval = const Duration(minutes: 10),
  })  : _scheduledPublishRepository = scheduledPublishRepository,
        _workflowRepository = workflowRepository,
        _contentProcessingService = contentProcessingService,
        _notificationsManager = notificationsManager,
        _checkInterval = checkInterval,
        _reminderInterval = reminderInterval;

  /// Start the automated publishing service
  void start() {
    // Timer for checking scheduled publishes
    _publishingTimer = Timer.periodic(_checkInterval, (timer) {
      _checkAndPublishScheduledContent();
    });
    
    // Timer for sending reminders
    _reminderTimer = Timer.periodic(_reminderInterval, (timer) {
      _sendPublishingReminders();
    });
    
    debugPrint('Automated publishing service started');
  }

  /// Stop the automated publishing service
  void stop() {
    _publishingTimer?.cancel();
    _reminderTimer?.cancel();
    _publishingTimer = null;
    _reminderTimer = null;
  }

  /// Check for scheduled publishes that are due and trigger publishing
  Future<void> _checkAndPublishScheduledContent() async {
    try {
      // Get all scheduled publishes (we might want to limit this to a reasonable date range)
      final now = DateTime.now();
      final future = now.add(const Duration(days: 1));
      
      final scheduledPublishes = await _scheduledPublishRepository.getScheduledPublishesByDateRange(now, future);
      
      // Check each scheduled publish
      for (final scheduledPublish in scheduledPublishes) {
        // Check if it's time to publish
        if (_isTimeToPublish(scheduledPublish, now)) {
          // Trigger the publishing workflow
          await _triggerPublishingWorkflow(scheduledPublish);
        }
      }
    } catch (e) {
      // In a real implementation, we would log this error
      debugPrint('Error in automated publishing service: $e');
    }
  }

  /// Check if it's time to publish a scheduled item
  bool _isTimeToPublish(ScheduledPublish scheduledPublish, DateTime now) {
    // For non-recurring publishes, check if the scheduled time has passed
    if (!scheduledPublish.isRecurring) {
      return scheduledPublish.scheduledTime.isBefore(now) || 
             scheduledPublish.scheduledTime.isAtSameMomentAs(now);
    }
    
    // For recurring publishes, we need to check if any occurrence is due
    // This is a simplified implementation - a full implementation would need to:
    // 1. Calculate all occurrences based on the recurrence pattern
    // 2. Check if any of them are due now
    // 3. Handle timezone conversions properly
    
    if (scheduledPublish.recurrencePattern != null) {
      // For now, we'll just check if the initial scheduled time is due
      // and if it's within a reasonable window (e.g., 1 minute)
      final timeDiff = now.difference(scheduledPublish.scheduledTime);
      return timeDiff.inMinutes >= 0 && timeDiff.inMinutes <= 1;
    }
    
    return false;
  }

  /// Trigger the publishing workflow for a scheduled item
  Future<void> _triggerPublishingWorkflow(ScheduledPublish scheduledPublish) async {
    try {
      // Get the current workflow
      final workflow = await _workflowRepository.getWorkflow(scheduledPublish.workflowId);
      
      if (workflow != null) {
        // Transition the workflow to published status
        // Using "system" as userId since this is an automated process
        await _workflowRepository.transitionStatus(
          scheduledPublish.workflowId,
          PublishingStatus.published,
          'system',
          notes: 'Automatically published by scheduling system',
        );
        
        // Send notification that content has been published
        await _notificationsManager.sendContentPublishedNotification(
          workflowId: scheduledPublish.workflowId,
        );
        
        // If this was a one-time publish, we might want to delete the scheduled publish
        // If it's recurring, we would update it to the next occurrence
        if (!scheduledPublish.isRecurring) {
          await _scheduledPublishRepository.deleteScheduledPublish(scheduledPublish.id);
        } else {
          // For recurring publishes, calculate the next occurrence
          final nextOccurrence = _calculateNextOccurrence(scheduledPublish);
          if (nextOccurrence != null) {
            final updatedScheduledPublish = scheduledPublish.copyWith(
              scheduledTime: nextOccurrence,
            );
            await _scheduledPublishRepository.updateScheduledPublish(updatedScheduledPublish);
          } else {
            // If there's no next occurrence (e.g., we've reached the end date), delete it
            await _scheduledPublishRepository.deleteScheduledPublish(scheduledPublish.id);
          }
        }
      }
    } catch (e) {
      // In a real implementation, we would log this error and possibly notify the user
      debugPrint('Error triggering publishing workflow: $e');
    }
  }

  /// Calculate the next occurrence of a recurring publish
  DateTime? _calculateNextOccurrence(ScheduledPublish scheduledPublish) {
    if (!scheduledPublish.isRecurring || scheduledPublish.recurrencePattern == null) {
      return null;
    }
    
    final pattern = scheduledPublish.recurrencePattern!;
    final currentDateTime = scheduledPublish.scheduledTime;
    
    // Check if we've reached the end date
    if (pattern.endDate != null && currentDateTime.isAfter(pattern.endDate!)) {
      return null;
    }
    
    DateTime nextDateTime;
    
    switch (pattern.type) {
      case RecurrenceType.daily:
        nextDateTime = currentDateTime.add(Duration(days: pattern.interval));
        break;
      case RecurrenceType.weekly:
        nextDateTime = currentDateTime.add(Duration(days: 7 * pattern.interval));
        break;
      case RecurrenceType.monthly:
        nextDateTime = DateTime(
          currentDateTime.year,
          currentDateTime.month + pattern.interval,
          currentDateTime.day,
          currentDateTime.hour,
          currentDateTime.minute,
          currentDateTime.second,
          currentDateTime.millisecond,
          currentDateTime.microsecond,
        );
        break;
      case RecurrenceType.yearly:
        nextDateTime = DateTime(
          currentDateTime.year + pattern.interval,
          currentDateTime.month,
          currentDateTime.day,
          currentDateTime.hour,
          currentDateTime.minute,
          currentDateTime.second,
          currentDateTime.millisecond,
          currentDateTime.microsecond,
        );
        break;
    }
    
    // Check if the next occurrence is after the end date
    if (pattern.endDate != null && nextDateTime.isAfter(pattern.endDate!)) {
      return null;
    }
    
    return nextDateTime;
  }

  /// Send reminders for upcoming publishes
  Future<void> _sendPublishingReminders() async {
    try {
      final now = DateTime.now();
      final future = now.add(_reminderInterval);
      
      // Get all scheduled publishes that are due for reminder
      final scheduledPublishes = await _scheduledPublishRepository.getScheduledPublishesByDateRange(now, future);
      
      for (final scheduledPublish in scheduledPublishes) {
        // Send a reminder notification
        await _notificationsManager.sendScheduledPublishNotification(
          workflowId: scheduledPublish.workflowId,
          scheduledTime: scheduledPublish.scheduledTime,
        );
      }
    } catch (e) {
      debugPrint('Error sending publishing reminders: $e');
    }
  }
}