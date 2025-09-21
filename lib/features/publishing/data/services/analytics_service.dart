import 'package:flutter/foundation.dart';

import '../../domain/entities/analytics_data.dart';
import '../../domain/repositories/analytics_repository.dart';

class AnalyticsService implements AnalyticsRepository {
  // In-memory storage for analytics data
  final Map<String, AnalyticsData> _analyticsData = {};

  @override
  Future<AnalyticsData?> getContentAnalytics(String contentId) async {
    return _analyticsData[contentId];
  }

  @override
  Future<List<AnalyticsData>> getMultipleContentAnalytics(List<String> contentIds) async {
    return contentIds
        .where((id) => _analyticsData.containsKey(id))
        .map((id) => _analyticsData[id]!)
        .toList();
  }

  @override
  Future<List<AnalyticsData>> getTrendingContent({
    int limit = 10,
    String? timeRange,
  }) async {
    // Sort by engagement rate and return top content
    final sortedContent = _analyticsData.values.toList()
      ..sort((a, b) => b.engagementRate.compareTo(a.engagementRate));
    
    return sortedContent.take(limit).toList();
  }

  @override
  Future<ContentPerformanceComparison> compareContentPerformance(
    String contentId1,
    String contentId2,
  ) async {
    final content1 = _analyticsData[contentId1];
    final content2 = _analyticsData[contentId2];

    if (content1 == null || content2 == null) {
      throw Exception('One or both content analytics not found');
    }

    // Determine better performing content
    final betterPerformingContentId = content1.engagementRate > content2.engagementRate
        ? contentId1
        : contentId2;

    // Generate recommendations based on comparison
    final recommendations = <String>[];
    
    if (content1.views < content2.views) {
      recommendations.add('Content ${contentId2} has more views. Consider analyzing its title and description for better visibility.');
    } else if (content1.views > content2.views) {
      recommendations.add('Content ${contentId1} has more views. Consider replicating its success factors.');
    }
    
    if (content1.engagementRate < content2.engagementRate) {
      recommendations.add('Content ${contentId2} has higher engagement. Review its content format and posting time.');
    } else if (content1.engagementRate > content2.engagementRate) {
      recommendations.add('Content ${contentId1} has higher engagement. Consider using similar strategies.');
    }

    return ContentPerformanceComparison(
      content1: content1,
      content2: content2,
      insights: PerformanceInsights(
        betterPerformingContentId: betterPerformingContentId,
        recommendations: recommendations,
      ),
    );
  }

  @override
  Future<AnalyticsSummary> getUserAnalyticsSummary(String userId) async {
    // Filter analytics data by user (in a real implementation, this would be done via content ownership)
    final userAnalytics = _analyticsData.values.where((data) => data.contentId.contains(userId)).toList();
    
    if (userAnalytics.isEmpty) {
      return AnalyticsSummary(
        totalViews: 0,
        totalLikes: 0,
        totalShares: 0,
        totalComments: 0,
        averageEngagementRate: 0.0,
        platformMetrics: [],
      );
    }

    // Calculate summary metrics
    int totalViews = 0;
    int totalLikes = 0;
    int totalShares = 0;
    int totalComments = 0;
    
    for (var data in userAnalytics) {
      totalViews += data.views;
      totalLikes += data.likes;
      totalShares += data.shares;
      totalComments += data.comments;
    }
    
    final averageEngagementRate = userAnalytics.fold(0.0, (sum, data) => sum + data.engagementRate) / userAnalytics.length;
    
    // Aggregate platform metrics
    final platformMetricsMap = <String, PlatformMetrics>{};
    
    for (var data in userAnalytics) {
      for (var platformMetric in data.platformMetrics) {
        if (platformMetricsMap.containsKey(platformMetric.platform)) {
          final existing = platformMetricsMap[platformMetric.platform]!;
          platformMetricsMap[platformMetric.platform] = existing.copyWith(
            views: existing.views + platformMetric.views,
            likes: existing.likes + platformMetric.likes,
            shares: existing.shares + platformMetric.shares,
            comments: existing.comments + platformMetric.comments,
            engagementRate: (existing.engagementRate + platformMetric.engagementRate) / 2,
          );
        } else {
          platformMetricsMap[platformMetric.platform] = platformMetric;
        }
      }
    }
    
    return AnalyticsSummary(
      totalViews: totalViews,
      totalLikes: totalLikes,
      totalShares: totalShares,
      totalComments: totalComments,
      averageEngagementRate: averageEngagementRate,
      platformMetrics: platformMetricsMap.values.toList(),
    );
  }
  
  /// Update analytics data for a content (simulating real-time updates)
  void updateAnalytics(String contentId, AnalyticsData data) {
    _analyticsData[contentId] = data;
  }
}