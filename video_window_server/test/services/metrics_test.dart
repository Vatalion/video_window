import 'package:test/test.dart';
import 'package:video_window_server/src/services/metrics.dart';

void main() {
  group('MetricsService', () {
    late MetricsService metrics;

    setUp(() {
      metrics = MetricsService();
      metrics.reset(); // Clear metrics before each test
    });

    group('Counter', () {
      test('increments counter', () {
        metrics.incrementCounter('test_counter');
        expect(metrics.getCounter('test_counter'), 1.0);
      });

      test('increments counter by custom value', () {
        metrics.incrementCounter('test_counter', value: 5.0);
        expect(metrics.getCounter('test_counter'), 5.0);
      });

      test('increments counter multiple times', () {
        metrics.incrementCounter('test_counter');
        metrics.incrementCounter('test_counter');
        metrics.incrementCounter('test_counter');
        expect(metrics.getCounter('test_counter'), 3.0);
      });

      test('supports labels', () {
        metrics.incrementCounter('http_requests',
            labels: {'method': 'GET', 'endpoint': '/api/users'});
        metrics.incrementCounter('http_requests',
            labels: {'method': 'POST', 'endpoint': '/api/users'});

        expect(
            metrics.getCounter('http_requests',
                labels: {'method': 'GET', 'endpoint': '/api/users'}),
            1.0);
        expect(
            metrics.getCounter('http_requests',
                labels: {'method': 'POST', 'endpoint': '/api/users'}),
            1.0);
      });

      test('cannot be decremented', () {
        final counter = Counter('test');
        expect(() => counter.increment(-1), throwsArgumentError);
      });

      test('exports to Prometheus format', () {
        metrics.incrementCounter('api_calls', value: 42.0);
        final export = metrics.exportPrometheusMetrics();

        expect(export, contains('# TYPE api_calls counter'));
        expect(export, contains('api_calls 42.0'));
      });
    });

    group('Gauge', () {
      test('sets gauge value', () {
        metrics.setGauge('active_connections', 10.0);
        expect(metrics.getGauge('active_connections'), 10.0);
      });

      test('updates gauge value', () {
        metrics.setGauge('active_connections', 10.0);
        metrics.setGauge('active_connections', 20.0);
        expect(metrics.getGauge('active_connections'), 20.0);
      });

      test('supports labels', () {
        metrics.setGauge('memory_usage', 512.0, labels: {'service': 'api'});
        metrics.setGauge('memory_usage', 256.0, labels: {'service': 'worker'});

        expect(metrics.getGauge('memory_usage', labels: {'service': 'api'}),
            512.0);
        expect(metrics.getGauge('memory_usage', labels: {'service': 'worker'}),
            256.0);
      });

      test('exports to Prometheus format', () {
        metrics.setGauge('temperature', 23.5);
        final export = metrics.exportPrometheusMetrics();

        expect(export, contains('# TYPE temperature gauge'));
        expect(export, contains('temperature 23.5'));
      });
    });

    group('Histogram', () {
      test('records observations', () {
        metrics.recordHistogram('request_duration', 100.0);
        metrics.recordHistogram('request_duration', 200.0);
        metrics.recordHistogram('request_duration', 150.0);

        final stats = metrics.getHistogramStats('request_duration');
        expect(stats, isNotNull);
        expect(stats!.count, 3);
        expect(stats.sum, 450.0);
      });

      test('calculates statistics correctly', () {
        for (var i = 1; i <= 100; i++) {
          metrics.recordHistogram('test_histogram', i.toDouble());
        }

        final stats = metrics.getHistogramStats('test_histogram');
        expect(stats, isNotNull);
        expect(stats!.count, 100);
        expect(stats.min, 1.0);
        expect(stats.max, 100.0);
        expect(stats.avg, 50.5);
        expect(stats.p50, closeTo(50.0, 5.0));
        expect(stats.p95, closeTo(95.0, 5.0));
        expect(stats.p99, closeTo(99.0, 5.0));
      });

      test('supports labels', () {
        metrics.recordHistogram('latency', 100.0,
            labels: {'endpoint': '/api/users'});
        metrics.recordHistogram('latency', 200.0,
            labels: {'endpoint': '/api/posts'});

        final stats1 = metrics
            .getHistogramStats('latency', labels: {'endpoint': '/api/users'});
        final stats2 = metrics
            .getHistogramStats('latency', labels: {'endpoint': '/api/posts'});

        expect(stats1!.count, 1);
        expect(stats2!.count, 1);
      });

      test('exports to Prometheus format', () {
        metrics.recordHistogram('response_time', 50.0);
        metrics.recordHistogram('response_time', 100.0);
        metrics.recordHistogram('response_time', 150.0);

        final export = metrics.exportPrometheusMetrics();

        expect(export, contains('# TYPE response_time histogram'));
        expect(export, contains('response_time_bucket'));
        expect(export, contains('response_time_sum'));
        expect(export, contains('response_time_count'));
      });

      test('handles empty histogram', () {
        final stats = metrics.getHistogramStats('empty_histogram');
        expect(stats, isNull);
      });
    });

    group('measureTime', () {
      test('records execution time', () async {
        await metrics.measureTime('test_operation', () async {
          await Future.delayed(Duration(milliseconds: 10));
        });

        final stats = metrics.getHistogramStats('test_operation_duration_ms');
        expect(stats, isNotNull);
        expect(stats!.count, 1);
        expect(stats.avg, greaterThanOrEqualTo(10.0));
      });

      test('records errors separately', () async {
        try {
          await metrics.measureTime('failing_operation', () async {
            throw Exception('Test error');
          });
        } catch (e) {
          // Expected
        }

        final errorCount = metrics.getCounter('failing_operation_errors');
        expect(errorCount, 1.0);
      });

      test('returns result from measured function', () async {
        final result = await metrics.measureTime('calculation', () async {
          return 42;
        });

        expect(result, 42);
      });

      test('supports labels', () async {
        await metrics.measureTime(
          'api_call',
          () async => Future.delayed(Duration(milliseconds: 5)),
          labels: {'endpoint': '/test'},
        );

        final stats = metrics.getHistogramStats(
          'api_call_duration_ms',
          labels: {'endpoint': '/test'},
        );
        expect(stats, isNotNull);
      });
    });

    group('exportPrometheusMetrics', () {
      test('exports all metric types', () {
        metrics.incrementCounter('counter_metric');
        metrics.setGauge('gauge_metric', 100.0);
        metrics.recordHistogram('histogram_metric', 50.0);

        final export = metrics.exportPrometheusMetrics();

        expect(export, contains('counter_metric'));
        expect(export, contains('gauge_metric'));
        expect(export, contains('histogram_metric'));
      });

      test('formats labels correctly', () {
        metrics.incrementCounter('requests',
            labels: {'method': 'GET', 'status': '200'});

        final export = metrics.exportPrometheusMetrics();
        expect(export, contains('{method="GET",status="200"}'));
      });

      test('exports valid Prometheus text format', () {
        metrics.incrementCounter('test_counter', value: 5.0);
        metrics.setGauge('test_gauge', 10.0);

        final export = metrics.exportPrometheusMetrics();

        // Should have TYPE comments
        expect(export, contains('# TYPE'));
        // Should have metric names and values
        expect(RegExp(r'test_counter\s+5\.0').hasMatch(export), true);
        expect(RegExp(r'test_gauge\s+10\.0').hasMatch(export), true);
      });
    });

    group('reset', () {
      test('clears all metrics', () {
        metrics.incrementCounter('test_counter');
        metrics.setGauge('test_gauge', 100.0);
        metrics.recordHistogram('test_histogram', 50.0);

        metrics.reset();

        expect(metrics.getCounter('test_counter'), isNull);
        expect(metrics.getGauge('test_gauge'), isNull);
        expect(metrics.getHistogramStats('test_histogram'), isNull);
      });
    });

    group('Singleton pattern', () {
      test('returns same instance', () {
        final instance1 = MetricsService();
        final instance2 = MetricsService();

        expect(identical(instance1, instance2), true);
      });

      test('shares state across instances', () {
        final instance1 = MetricsService();
        final instance2 = MetricsService();

        instance1.incrementCounter('shared_counter');
        expect(instance2.getCounter('shared_counter'), 1.0);
      });
    });
  });

  group('HistogramStats', () {
    test('contains all required fields', () {
      final stats = HistogramStats(
        count: 10,
        sum: 100.0,
        min: 5.0,
        max: 20.0,
        avg: 10.0,
        p50: 10.0,
        p95: 19.0,
        p99: 19.8,
      );

      expect(stats.count, 10);
      expect(stats.sum, 100.0);
      expect(stats.min, 5.0);
      expect(stats.max, 20.0);
      expect(stats.avg, 10.0);
      expect(stats.p50, 10.0);
      expect(stats.p95, 19.0);
      expect(stats.p99, 19.8);
    });
  });
}
