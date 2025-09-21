import 'package:flutter/foundation.dart';

import '../../domain/entities/analytics_data.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../services/analytics_service.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsService _analyticsService;

  AnalyticsRepositoryImpl({required AnalyticsService analyticsService})
      : _analyticsService = analyticsService;

  @override
  Future<AnalyticsData?> getContentAnalytics(String contentId) async {
    return _analyticsService.getContentAnalytics(contentId);
  }

  @override
  Future<List<AnalyticsData>> getMultipleContentAnalytics(List<String> contentIds) async {
    return _analyticsService.getMultipleContentAnalytics(contentIds);
  }

  @override
  Future<List<AnalyticsData>> getTrendingContent({
    int limit = 10,
    String? timeRange,
  }) async {
    return _analyticsService.getTrendingContent(limit: limit, timeRange: timeRange);
  }

  @override
  Future<ContentPerformanceComparison> compareContentPerformance(
    String contentId1,
    String contentId2,
  ) async {
    return _analyticsService.compareContentPerformance(contentId1, contentId2);
  }

  @override
  Future<AnalyticsSummary> getUserAnalyticsSummary(String userId) async {
    return _analyticsService.getUserAnalyticsSummary(userId);
  }
}