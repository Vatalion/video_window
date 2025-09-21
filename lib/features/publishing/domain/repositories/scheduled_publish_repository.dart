import 'package:flutter/foundation.dart';

import '../entities/scheduled_publish.dart';

abstract class ScheduledPublishRepository {
  /// Get a scheduled publish by ID
  Future<ScheduledPublish?> getScheduledPublish(String id);

  /// Get all scheduled publishes for a workflow
  Future<List<ScheduledPublish>> getScheduledPublishesForWorkflow(String workflowId);

  /// Create a new scheduled publish
  Future<ScheduledPublish> createScheduledPublish(ScheduledPublish scheduledPublish);

  /// Update an existing scheduled publish
  Future<ScheduledPublish> updateScheduledPublish(ScheduledPublish scheduledPublish);

  /// Delete a scheduled publish
  Future<bool> deleteScheduledPublish(String id);

  /// Get all scheduled publishes within a date range
  Future<List<ScheduledPublish>> getScheduledPublishesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
}