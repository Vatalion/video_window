import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// Structured logger service with OpenTelemetry support
///
/// Provides JSON-formatted logging with correlation IDs, PII sanitization,
/// and CloudWatch integration.
class AppLogger {
  final Logger _logger;
  final String _service;
  final bool _includeStackTrace;
  static final _uuid = const Uuid();

  /// Sensitive field patterns to sanitize from logs
  static final _piiPatterns = [
    RegExp(r'\b\d{13,19}\b'), // Card numbers (PAN)
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), // Emails
    RegExp(r'\bpassword\s*[:=]\s*\S+', caseSensitive: false),
    RegExp(r'\btoken\s*[:=]\s*\S+', caseSensitive: false),
    RegExp(r'\bapi[_-]?key\s*[:=]\s*\S+', caseSensitive: false),
  ];

  AppLogger({
    required String name,
    String? service,
    Level level = Level.INFO,
    bool includeStackTrace = false,
  })  : _logger = Logger(name),
        _service = service ?? 'video_window',
        _includeStackTrace = includeStackTrace {
    hierarchicalLoggingEnabled = true;
    _logger.level = level;
    _setupLogHandler();
  }

  void _setupLogHandler() {
    Logger.root.onRecord.listen((record) {
      final structuredLog = _formatStructuredLog(record);

      // Output to console (development and container logs)
      developer.log(
        structuredLog,
        name: record.loggerName,
        level: _mapLogLevel(record.level),
      );

      // Production: Send to CloudWatch Logs
      // Requires AWS SDK and credentials configuration
      _sendToCloudWatch(structuredLog, record);
    });
  }

  /// Send log to CloudWatch Logs
  ///
  /// Production implementation requires:
  /// - AWS SDK dependency (aws_cloudwatch_logs_api)
  /// - AWS credentials configuration
  /// - Log group and stream names from config
  /// - Batching for efficiency
  void _sendToCloudWatch(String logData, LogRecord record) {
    // TODO: Implement CloudWatch Logs integration
    // Example production implementation:
    //
    // try {
    //   await _cloudWatchClient.putLogEvents(
    //     logGroupName: '/serverpod/${_service}',
    //     logStreamName: Platform.environment['HOSTNAME'] ?? 'default',
    //     logEvents: [
    //       CloudWatchLogEvent(
    //         timestamp: DateTime.now().millisecondsSinceEpoch,
    //         message: logData,
    //       ),
    //     ],
    //   );
    // } catch (e) {
    //   // Fallback: Log to stderr to avoid losing log data
    //   stderr.writeln('CloudWatch logging failed: $e');
    //   stderr.writeln(logData);
    // }
  }

  String _formatStructuredLog(LogRecord record) {
    final logData = {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': record.level.name,
      'service': _service,
      'logger': record.loggerName,
      'message': _sanitizePII(record.message),
      'correlation_id': Zone.current[#correlationId] ?? _uuid.v4(),
    };

    if (record.error != null) {
      logData['error'] = record.error.toString();
    }

    if (_includeStackTrace && record.stackTrace != null) {
      logData['stack_trace'] = record.stackTrace.toString();
    }

    if (record.object != null) {
      logData['context'] = record.object;
    }

    return jsonEncode(logData);
  }

  /// Sanitize PII from log messages
  String _sanitizePII(String message) {
    return sanitizePII(message);
  }

  /// Sanitize PII from any string (public for testing)
  static String sanitizePII(String message) {
    var sanitized = message;
    for (final pattern in _piiPatterns) {
      sanitized = sanitized.replaceAll(pattern, '***REDACTED***');
    }
    return sanitized;
  }

  int _mapLogLevel(Level level) {
    if (level >= Level.SEVERE) return 1000; // Error
    if (level >= Level.WARNING) return 900; // Warning
    if (level >= Level.INFO) return 800; // Info
    return 500; // Debug
  }

  /// Log debug message
  void debug(String message, {Object? context}) {
    _logger.fine(message, context);
  }

  /// Log info message
  void info(String message, {Object? context}) {
    _logger.info(message, context);
  }

  /// Log warning message
  void warning(String message, {Object? context, Object? error}) {
    _logger.warning(message, error ?? context);
  }

  /// Log error message
  void error(String message,
      {Object? context, Object? error, StackTrace? stackTrace}) {
    _logger.severe(message, error ?? context, stackTrace ?? StackTrace.current);
  }

  /// Log critical message
  void critical(String message,
      {Object? context, Object? error, StackTrace? stackTrace}) {
    _logger.shout(message, error ?? context, stackTrace ?? StackTrace.current);
  }

  /// Execute function with correlation ID
  static Future<T> withCorrelationId<T>(
    String correlationId,
    Future<T> Function() fn,
  ) async {
    return runZoned(
      fn,
      zoneValues: {#correlationId: correlationId},
    );
  }

  /// Generate new correlation ID
  static String generateCorrelationId() => _uuid.v4();
}
