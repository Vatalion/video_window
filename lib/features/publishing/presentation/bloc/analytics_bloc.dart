import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/analytics_data.dart';
import '../../domain/repositories/analytics_repository.dart';

part 'analytics_event.dart';
part 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository _analyticsRepository;

  AnalyticsBloc({required AnalyticsRepository analyticsRepository})
      : _analyticsRepository = analyticsRepository,
        super(AnalyticsInitial()) {
    on<LoadContentAnalytics>(_onLoadContentAnalytics);
    on<LoadTrendingContent>(_onLoadTrendingContent);
    on<CompareContentPerformance>(_onCompareContentPerformance);
    on<LoadUserAnalyticsSummary>(_onLoadUserAnalyticsSummary);
  }

  Future<void> _onLoadContentAnalytics(
    LoadContentAnalytics event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final analytics = await _analyticsRepository.getContentAnalytics(event.contentId);
      if (analytics != null) {
        emit(ContentAnalyticsLoaded(analytics));
      } else {
        emit(const AnalyticsError('Analytics data not found'));
      }
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onLoadTrendingContent(
    LoadTrendingContent event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final trendingContent = await _analyticsRepository.getTrendingContent(
        limit: event.limit,
        timeRange: event.timeRange,
      );
      emit(TrendingContentLoaded(trendingContent));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onCompareContentPerformance(
    CompareContentPerformance event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final comparison = await _analyticsRepository.compareContentPerformance(
        event.contentId1,
        event.contentId2,
      );
      emit(ContentPerformanceCompared(comparison));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onLoadUserAnalyticsSummary(
    LoadUserAnalyticsSummary event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final summary = await _analyticsRepository.getUserAnalyticsSummary(event.userId);
      emit(UserAnalyticsSummaryLoaded(summary));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }
}