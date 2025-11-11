import '../analytics_service.dart';

/// Analytics event for payout activation started
///
/// AC7: Emit events payout_activation_started with duration metrics
class PayoutActivationStartedEvent extends AnalyticsEvent {
  final int userId;
  final String entryPoint;
  final DateTime _timestamp;

  PayoutActivationStartedEvent({
    required this.userId,
    required this.entryPoint,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'payout_activation_started';

  @override
  Map<String, dynamic> get properties => {
        'user_id': userId,
        'entry_point': entryPoint,
        'timestamp': _timestamp.toIso8601String(),
      };

  @override
  DateTime get timestamp => _timestamp;
}

/// Analytics event for payout activation completed
///
/// AC7: Emit events payout_activation_completed with duration metrics
class PayoutActivationCompletedEvent extends AnalyticsEvent {
  final int userId;
  final String entryPoint;
  final int durationSeconds;
  final bool success;
  final String? errorCode;
  final DateTime _timestamp;

  PayoutActivationCompletedEvent({
    required this.userId,
    required this.entryPoint,
    required this.durationSeconds,
    this.success = true,
    this.errorCode,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'payout_activation_completed';

  @override
  Map<String, dynamic> get properties => {
        'user_id': userId,
        'entry_point': entryPoint,
        'duration_seconds': durationSeconds,
        'success': success,
        if (errorCode != null) 'error_code': errorCode,
        'timestamp': _timestamp.toIso8601String(),
      };

  @override
  DateTime get timestamp => _timestamp;
}
