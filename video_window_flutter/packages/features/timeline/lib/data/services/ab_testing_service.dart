import 'dart:math';
import '../../domain/entities/feed_configuration.dart';

/// A/B testing service for feed algorithm variants
/// AC8: A/B testing framework for feed algorithm variants and performance monitoring
class ABTestingService {
  static final ABTestingService _instance = ABTestingService._internal();
  factory ABTestingService() => _instance;
  ABTestingService._internal();

  final Random _random = Random();
  final Map<String, String> _userVariants = {}; // userId -> variant

  /// Get variant for user (consistent assignment)
  /// AC8: A/B testing framework for feed algorithm variants
  String getVariant({
    required String userId,
    required List<String> variants,
    String? experimentId,
  }) {
    final key = experimentId != null ? '$userId:$experimentId' : userId;

    // Return cached variant if exists
    if (_userVariants.containsKey(key)) {
      return _userVariants[key]!;
    }

    // Assign variant consistently based on user ID hash
    final hash = userId.hashCode;
    final variantIndex = hash.abs() % variants.length;
    final variant = variants[variantIndex];

    _userVariants[key] = variant;
    return variant;
  }

  /// Get feed algorithm variant for A/B testing
  /// AC8: Performance monitoring integration
  FeedAlgorithm getAlgorithmVariant({
    required String userId,
    String? experimentId,
  }) {
    final variants = [
      FeedAlgorithm.personalized,
      FeedAlgorithm.trending,
      FeedAlgorithm.newest,
    ];

    final variantName = getVariant(
      userId: userId,
      variants: variants.map((a) => a.name).toList(),
      experimentId: experimentId ?? 'feed_algorithm',
    );

    return variants.firstWhere(
      (a) => a.name == variantName,
      orElse: () => FeedAlgorithm.personalized,
    );
  }

  /// Track experiment event for analytics
  /// AC8: Performance monitoring integration
  void trackExperimentEvent({
    required String userId,
    required String experimentId,
    required String variant,
    required String eventType,
    Map<String, dynamic>? metadata,
  }) {
    // This would integrate with analytics service
    // For now, just log the event structure
    final event = {
      'experiment_id': experimentId,
      'variant': variant,
      'event_type': eventType,
      'user_id': userId,
      'metadata': metadata ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };

    // TODO: Integrate with analytics service
    // _analyticsService.track('experiment_event', event);
  }

  /// Record performance metrics for variant comparison
  /// AC8: Performance monitoring integration
  void recordPerformanceMetric({
    required String userId,
    required String experimentId,
    required String variant,
    required String metricName,
    required double value,
    Map<String, dynamic>? metadata,
  }) {
    trackExperimentEvent(
      userId: userId,
      experimentId: experimentId,
      variant: variant,
      eventType: 'performance_metric',
      metadata: {
        'metric_name': metricName,
        'value': value,
        ...?metadata,
      },
    );
  }

  /// Clear cached variants (for testing)
  void clearCache() {
    _userVariants.clear();
  }
}
