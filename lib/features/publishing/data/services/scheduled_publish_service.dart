import 'package:flutter/foundation.dart';

import '../../domain/entities/scheduled_publish.dart';
import '../../domain/repositories/scheduled_publish_repository.dart';

class ScheduledPublishService implements ScheduledPublishRepository {
  // In-memory storage for scheduled publishes
  final Map<String, ScheduledPublish> _scheduledPublishes = {};
  
  // In-memory storage for workflow scheduled publishes
  final Map<String, List<String>> _workflowScheduledPublishes = {};

  @override
  Future<ScheduledPublish?> getScheduledPublish(String id) async {
    return _scheduledPublishes[id];
  }

  @override
  Future<List<ScheduledPublish>> getScheduledPublishesForWorkflow(String workflowId) async {
    final scheduledPublishIds = _workflowScheduledPublishes[workflowId] ?? [];
    return scheduledPublishIds.map((id) => _scheduledPublishes[id]!).toList();
  }

  @override
  Future<ScheduledPublish> createScheduledPublish(ScheduledPublish scheduledPublish) async {
    // Check for scheduling conflicts
    final hasConflict = await _hasSchedulingConflict(scheduledPublish);
    if (hasConflict) {
      throw Exception('Scheduling conflict detected. Please choose a different time.');
    }
    
    _scheduledPublishes[scheduledPublish.id] = scheduledPublish;
    
    // Add to workflow scheduled publishes mapping
    if (_workflowScheduledPublishes.containsKey(scheduledPublish.workflowId)) {
      _workflowScheduledPublishes[scheduledPublish.workflowId]!.add(scheduledPublish.id);
    } else {
      _workflowScheduledPublishes[scheduledPublish.workflowId] = [scheduledPublish.id];
    }
    
    return scheduledPublish;
  }

  @override
  Future<ScheduledPublish> updateScheduledPublish(ScheduledPublish scheduledPublish) async {
    // Check for scheduling conflicts (excluding the current publish being updated)
    final hasConflict = await _hasSchedulingConflict(scheduledPublish, excludeId: scheduledPublish.id);
    if (hasConflict) {
      throw Exception('Scheduling conflict detected. Please choose a different time.');
    }
    
    _scheduledPublishes[scheduledPublish.id] = scheduledPublish;
    return scheduledPublish;
  }

  @override
  Future<bool> deleteScheduledPublish(String id) async {
    if (_scheduledPublishes.containsKey(id)) {
      final scheduledPublish = _scheduledPublishes[id]!;
      _scheduledPublishes.remove(id);
      
      // Remove from workflow scheduled publishes mapping
      if (_workflowScheduledPublishes.containsKey(scheduledPublish.workflowId)) {
        _workflowScheduledPublishes[scheduledPublish.workflowId]!.remove(id);
        if (_workflowScheduledPublishes[scheduledPublish.workflowId]!.isEmpty) {
          _workflowScheduledPublishes.remove(scheduledPublish.workflowId);
        }
      }
      
      return true;
    }
    return false;
  }

  @override
  Future<List<ScheduledPublish>> getScheduledPublishesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _scheduledPublishes.values
        .where((scheduledPublish) =>
            scheduledPublish.scheduledTime.isAfter(startDate) &&
            scheduledPublish.scheduledTime.isBefore(endDate))
        .toList();
  }
  
  /// Check if a scheduled publish has conflicts with existing schedules
  Future<bool> _hasSchedulingConflict(ScheduledPublish scheduledPublish, {String? excludeId}) async {
    // Get all scheduled publishes for the same workflow
    final workflowScheduledPublishes = await getScheduledPublishesForWorkflow(scheduledPublish.workflowId);
    
    // If we're updating, exclude the current publish from conflict checking
    final existingScheduledPublishes = excludeId != null 
        ? workflowScheduledPublishes.where((publish) => publish.id != excludeId).toList() 
        : workflowScheduledPublishes;
    
    // Check for conflicts
    for (final existingPublish in existingScheduledPublishes) {
      // For recurring publishes, we need to check if any occurrences overlap
      if (scheduledPublish.isRecurring && existingPublish.isRecurring) {
        // Simplified conflict detection for recurring publishes
        // In a real implementation, this would need to check all possible occurrences
        if (_hasBasicConflict(scheduledPublish, existingPublish)) {
          return true;
        }
      } 
      // For non-recurring publishes, check direct time overlap
      else if (!scheduledPublish.isRecurring && !existingPublish.isRecurring) {
        if (_hasBasicConflict(scheduledPublish, existingPublish)) {
          return true;
        }
      }
      // Check conflicts between recurring and non-recurring publishes
      else {
        if (_hasRecurringAndNonRecurringConflict(scheduledPublish, existingPublish)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Basic conflict detection between two scheduled publishes
  bool _hasBasicConflict(ScheduledPublish publish1, ScheduledPublish publish2) {
    // Simple overlap detection: 
    // If publish1 starts before publish2 ends and publish1 ends after publish2 starts, there's a conflict
    // For simplicity, we'll assume each publish takes about 1 hour
    final publish1End = publish1.scheduledTime.add(const Duration(hours: 1));
    final publish2End = publish2.scheduledTime.add(const Duration(hours: 1));
    
    return publish1.scheduledTime.isBefore(publish2End) && 
           publish1End.isAfter(publish2.scheduledTime);
  }
  
  /// Conflict detection between recurring and non-recurring publishes
  bool _hasRecurringAndNonRecurringConflict(ScheduledPublish recurring, ScheduledPublish nonRecurring) {
    // The recurring publish is the one with isRecurring = true
    final recurringPublish = recurring.isRecurring ? recurring : nonRecurring;
    final singlePublish = recurring.isRecurring ? nonRecurring : recurring;
    
    // Simplified conflict detection - in a real implementation, 
    // we would need to check all occurrences of the recurring publish
    // For now, we'll just check if the single publish falls within the recurring pattern
    
    if (recurringPublish.recurrencePattern != null) {
      // Check if single publish time conflicts with the first occurrence of recurring publish
      return _hasBasicConflict(recurringPublish, singlePublish);
    }
    
    return false;
  }
}