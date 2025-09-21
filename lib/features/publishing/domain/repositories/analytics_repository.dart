import 'package:flutter/foundation.dart';

import '../entities/analytics_data.dart';

abstract class AnalyticsRepository {
  /// Get analytics data for a specific content ID
  Future<AnalyticsData?> getContentAnalytics(String contentId);

  /// Get analytics data for multiple content IDs
  Future<List<AnalyticsData>> getMultipleContentAnalytics(List<String> contentIds);

  /// Get trending content based on engagement metrics
  Future<List<AnalyticsData>> getTrendingContent({
    int limit = 10,
    String? timeRange,
  });

  /// Get content performance comparison
  Future<ContentPerformanceComparison> compareContentPerformance(
    String contentId1,
    String contentId2,
  );

  /// Get analytics summary for a user
  Future<AnalyticsSummary> getUserAnalyticsSummary(String userId);
}

class ContentPerformanceComparison {
  final AnalyticsData content1;
  final AnalyticsData content2;
  final PerformanceInsights insights;

  ContentPerformanceComparison({
    required this.content1,
    required this.content2,
    required this.insights,
  });
}

class PerformanceInsights {
  final String betterPerformingContentId;
  final List<String> recommendations;

  PerformanceInsights({
    required this.betterPerformingContentId,
    required this.recommendations,
  });
}

class AnalyticsSummary {
  final int totalViews;
  final int totalLikes;
  final int totalShares;
  final int totalComments;
  final double averageEngagementRate;
  final List<PlatformMetrics> platformMetrics;

  AnalyticsSummary({
    required this.totalViews,
    required this.totalLikes,
    required this.totalShares,
    required this.totalComments,
    required this.averageEngagementRate,
    required this.platformMetrics,
  });
}