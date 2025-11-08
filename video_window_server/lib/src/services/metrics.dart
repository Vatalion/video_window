import 'dart:async';
import 'package:logging/logging.dart';

/// Metrics service for Prometheus monitoring
///
/// Provides counter, gauge, and histogram metrics for tracking
/// application performance and health.
class MetricsService {
  static final MetricsService _instance = MetricsService._internal();
  factory MetricsService() => _instance;
  MetricsService._internal();

  final _logger = Logger('MetricsService');
  final Map<String, Counter> _counters = {};
  final Map<String, Gauge> _gauges = {};
  final Map<String, Histogram> _histograms = {};

  /// Increment a counter metric
  void incrementCounter(String name,
      {Map<String, String>? labels, double value = 1.0}) {
    final key = _makeKey(name, labels);
    _counters.putIfAbsent(key, () => Counter(name, labels: labels));
    _counters[key]!.increment(value);
    _logger.fine('Counter incremented: $name = ${_counters[key]!.value}');
  }

  /// Set a gauge metric value
  void setGauge(String name, double value, {Map<String, String>? labels}) {
    final key = _makeKey(name, labels);
    _gauges.putIfAbsent(key, () => Gauge(name, labels: labels));
    _gauges[key]!.set(value);
    _logger.fine('Gauge set: $name = $value');
  }

  /// Record a value in histogram
  void recordHistogram(String name, double value,
      {Map<String, String>? labels}) {
    final key = _makeKey(name, labels);
    _histograms.putIfAbsent(key, () => Histogram(name, labels: labels));
    _histograms[key]!.observe(value);
    _logger.fine('Histogram recorded: $name = $value');
  }

  /// Measure execution time of a function
  Future<T> measureTime<T>(
    String name,
    Future<T> Function() fn, {
    Map<String, String>? labels,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await fn();
      stopwatch.stop();
      recordHistogram(
        '${name}_duration_ms',
        stopwatch.elapsedMilliseconds.toDouble(),
        labels: labels,
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      incrementCounter('${name}_errors', labels: labels);
      rethrow;
    }
  }

  /// Get counter value
  double? getCounter(String name, {Map<String, String>? labels}) {
    final key = _makeKey(name, labels);
    return _counters[key]?.value;
  }

  /// Get gauge value
  double? getGauge(String name, {Map<String, String>? labels}) {
    final key = _makeKey(name, labels);
    return _gauges[key]?.value;
  }

  /// Get histogram stats
  HistogramStats? getHistogramStats(String name,
      {Map<String, String>? labels}) {
    final key = _makeKey(name, labels);
    return _histograms[key]?.getStats();
  }

  /// Export metrics in Prometheus text format
  String exportPrometheusMetrics() {
    final buffer = StringBuffer();

    // Export counters
    for (final counter in _counters.values) {
      buffer.writeln(counter.toPrometheusFormat());
    }

    // Export gauges
    for (final gauge in _gauges.values) {
      buffer.writeln(gauge.toPrometheusFormat());
    }

    // Export histograms
    for (final histogram in _histograms.values) {
      buffer.writeln(histogram.toPrometheusFormat());
    }

    return buffer.toString();
  }

  /// Reset all metrics (useful for testing)
  void reset() {
    _counters.clear();
    _gauges.clear();
    _histograms.clear();
  }

  String _makeKey(String name, Map<String, String>? labels) {
    if (labels == null || labels.isEmpty) return name;
    final labelStr =
        labels.entries.map((e) => '${e.key}="${e.value}"').join(',');
    return '$name{$labelStr}';
  }
}

/// Counter metric
class Counter {
  final String name;
  final Map<String, String>? labels;
  double _value = 0.0;

  Counter(this.name, {this.labels});

  void increment([double value = 1.0]) {
    if (value < 0) throw ArgumentError('Counter cannot be decremented');
    _value += value;
  }

  double get value => _value;

  String toPrometheusFormat() {
    final labelStr = _formatLabels();
    return '# TYPE $name counter\n$name$labelStr $_value';
  }

  String _formatLabels() {
    if (labels == null || labels!.isEmpty) return '';
    final parts = labels!.entries.map((e) => '${e.key}="${e.value}"').join(',');
    return '{$parts}';
  }
}

/// Gauge metric
class Gauge {
  final String name;
  final Map<String, String>? labels;
  double _value = 0.0;

  Gauge(this.name, {this.labels});

  void set(double value) {
    _value = value;
  }

  void increment([double value = 1.0]) {
    _value += value;
  }

  void decrement([double value = 1.0]) {
    _value -= value;
  }

  double get value => _value;

  String toPrometheusFormat() {
    final labelStr = _formatLabels();
    return '# TYPE $name gauge\n$name$labelStr $_value';
  }

  String _formatLabels() {
    if (labels == null || labels!.isEmpty) return '';
    final parts = labels!.entries.map((e) => '${e.key}="${e.value}"').join(',');
    return '{$parts}';
  }
}

/// Histogram metric
class Histogram {
  final String name;
  final Map<String, String>? labels;
  final List<double> _observations = [];
  final List<double> buckets;

  Histogram(
    this.name, {
    this.labels,
    this.buckets = const [
      0.005,
      0.01,
      0.025,
      0.05,
      0.1,
      0.25,
      0.5,
      1,
      2.5,
      5,
      10
    ],
  });

  void observe(double value) {
    _observations.add(value);
  }

  HistogramStats getStats() {
    if (_observations.isEmpty) {
      return HistogramStats(count: 0, sum: 0, min: 0, max: 0, avg: 0);
    }

    final sorted = List<double>.from(_observations)..sort();
    final sum = _observations.reduce((a, b) => a + b);

    return HistogramStats(
      count: _observations.length,
      sum: sum,
      min: sorted.first,
      max: sorted.last,
      avg: sum / _observations.length,
      p50: _percentile(sorted, 0.5),
      p95: _percentile(sorted, 0.95),
      p99: _percentile(sorted, 0.99),
    );
  }

  double _percentile(List<double> sorted, double percentile) {
    final index = (sorted.length * percentile).ceil() - 1;
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  String toPrometheusFormat() {
    final stats = getStats();
    final labelStr = _formatLabels();
    final buffer = StringBuffer();

    buffer.writeln('# TYPE $name histogram');

    // Bucket counts
    for (final bucket in buckets) {
      final count = _observations.where((v) => v <= bucket).length;
      buffer.writeln('${name}_bucket{le="$bucket"$labelStr} $count');
    }

    // +Inf bucket
    buffer.writeln('${name}_bucket{le="+Inf"$labelStr} ${stats.count}');

    // Sum and count
    buffer.writeln('${name}_sum$labelStr ${stats.sum}');
    buffer.writeln('${name}_count$labelStr ${stats.count}');

    return buffer.toString();
  }

  String _formatLabels() {
    if (labels == null || labels!.isEmpty) return '';
    final parts = labels!.entries.map((e) => ',${e.key}="${e.value}"').join();
    return parts;
  }
}

/// Histogram statistics
class HistogramStats {
  final int count;
  final double sum;
  final double min;
  final double max;
  final double avg;
  final double? p50;
  final double? p95;
  final double? p99;

  HistogramStats({
    required this.count,
    required this.sum,
    required this.min,
    required this.max,
    required this.avg,
    this.p50,
    this.p95,
    this.p99,
  });
}
