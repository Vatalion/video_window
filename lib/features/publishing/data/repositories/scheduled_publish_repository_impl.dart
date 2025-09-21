import 'package:flutter/foundation.dart';

import '../../domain/entities/scheduled_publish.dart';
import '../../domain/repositories/scheduled_publish_repository.dart';
import '../services/scheduled_publish_service.dart';

class ScheduledPublishRepositoryImpl implements ScheduledPublishRepository {
  final ScheduledPublishService _scheduledPublishService;

  ScheduledPublishRepositoryImpl({
    required ScheduledPublishService scheduledPublishService,
  }) : _scheduledPublishService = scheduledPublishService;

  @override
  Future<ScheduledPublish?> getScheduledPublish(String id) async {
    return _scheduledPublishService.getScheduledPublish(id);
  }

  @override
  Future<List<ScheduledPublish>> getScheduledPublishesForWorkflow(String workflowId) async {
    return _scheduledPublishService.getScheduledPublishesForWorkflow(workflowId);
  }

  @override
  Future<ScheduledPublish> createScheduledPublish(ScheduledPublish scheduledPublish) async {
    return _scheduledPublishService.createScheduledPublish(scheduledPublish);
  }

  @override
  Future<ScheduledPublish> updateScheduledPublish(ScheduledPublish scheduledPublish) async {
    return _scheduledPublishService.updateScheduledPublish(scheduledPublish);
  }

  @override
  Future<bool> deleteScheduledPublish(String id) async {
    return _scheduledPublishService.deleteScheduledPublish(id);
  }

  @override
  Future<List<ScheduledPublish>> getScheduledPublishesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _scheduledPublishService.getScheduledPublishesByDateRange(startDate, endDate);
  }
}