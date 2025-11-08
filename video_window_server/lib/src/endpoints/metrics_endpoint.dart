import 'package:serverpod/serverpod.dart';
import '../services/metrics.dart';

/// Endpoint for exposing Prometheus metrics
///
/// Provides /metrics endpoint that returns Prometheus-formatted metrics
/// for scraping by Prometheus server.
class MetricsEndpoint extends Endpoint {
  /// Export metrics in Prometheus text format
  ///
  /// GET /metrics
  /// Returns: text/plain with Prometheus metrics
  Future<String> getMetrics(Session session) async {
    try {
      final metrics = MetricsService().exportPrometheusMetrics();

      // Log metrics request (for audit trail)
      session.log('Prometheus metrics scraped', level: LogLevel.debug);

      return metrics;
    } catch (e, stackTrace) {
      session.log(
        'Error exporting Prometheus metrics',
        exception: e,
        stackTrace: stackTrace,
        level: LogLevel.error,
      );
      throw Exception('Failed to export metrics: $e');
    }
  }

  /// Health check endpoint
  ///
  /// GET /metrics/health
  /// Returns: JSON with status
  Future<Map<String, dynamic>> getHealth(Session session) async {
    return {
      'status': 'healthy',
      'service': 'video_window',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
