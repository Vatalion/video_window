part of 'analytics_bloc.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class ContentAnalyticsLoaded extends AnalyticsState {
  final AnalyticsData analytics;

  const ContentAnalyticsLoaded(this.analytics);

  @override
  List<Object> get props => [analytics];
}

class TrendingContentLoaded extends AnalyticsState {
  final List<AnalyticsData> trendingContent;

  const TrendingContentLoaded(this.trendingContent);

  @override
  List<Object> get props => [trendingContent];
}

class ContentPerformanceCompared extends AnalyticsState {
  final ContentPerformanceComparison comparison;

  const ContentPerformanceCompared(this.comparison);

  @override
  List<Object> get props => [comparison];
}

class UserAnalyticsSummaryLoaded extends AnalyticsState {
  final AnalyticsSummary summary;

  const UserAnalyticsSummaryLoaded(this.summary);

  @override
  List<Object> get props => [summary];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object> get props => [message];
}