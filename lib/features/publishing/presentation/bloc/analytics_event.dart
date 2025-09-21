part of 'analytics_bloc.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object> get props => [];
}

class LoadContentAnalytics extends AnalyticsEvent {
  final String contentId;

  const LoadContentAnalytics(this.contentId);

  @override
  List<Object> get props => [contentId];
}

class LoadTrendingContent extends AnalyticsEvent {
  final int limit;
  final String? timeRange;

  const LoadTrendingContent({this.limit = 10, this.timeRange});

  @override
  List<Object> get props => [limit, timeRange];
}

class CompareContentPerformance extends AnalyticsEvent {
  final String contentId1;
  final String contentId2;

  const CompareContentPerformance(this.contentId1, this.contentId2);

  @override
  List<Object> get props => [contentId1, contentId2];
}

class LoadUserAnalyticsSummary extends AnalyticsEvent {
  final String userId;

  const LoadUserAnalyticsSummary(this.userId);

  @override
  List<Object> get props => [userId];
}