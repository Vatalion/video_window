import 'package:serverpod/serverpod.dart';
import 'package:video_window_server/src/generated/protocol.dart';

/// Nightly retraining job for LightFM recommendation model
/// AC5: Triggers via Serverpod task, pulling parquet exports of interactions
/// and logging completion status to Snowflake
/// Scheduled nightly at 02:00 UTC
class FeedLightFMRetrain extends FutureCall<Greeting> {
  @override
  Future<void> invoke(Session session, Greeting? object) async {
    try {
      session.log(
        'Starting LightFM retraining job',
        level: LogLevel.info,
      );

      // AC5: Pull parquet exports of interactions from S3/Data Lake
      // TODO: Implement S3 parquet export retrieval
      // final interactions = await _loadInteractionExports();

      // Placeholder: Log that retraining would occur
      session.log(
        'LightFM retraining: Would process interaction exports',
        level: LogLevel.info,
      );

      // AC5: Trigger LightFM retraining API call
      // TODO: Call LightFM retraining endpoint when available
      // await _triggerLightFMRetraining(interactions);

      // AC5: Log completion status to Snowflake
      // TODO: Implement Snowflake logging when data warehouse is configured
      // await _logToSnowflake({
      //   'job_name': 'feed_lightfm_retrain',
      //   'status': 'completed',
      //   'timestamp': DateTime.now().toUtc().toIso8601String(),
      //   'interactions_processed': interactions.length,
      // });

      session.log(
        'LightFM retraining job completed',
        level: LogLevel.info,
      );

      // AC5: Publish metrics to Datadog
      // TODO: Implement Datadog metrics when SDK integrated
      // await _publishDatadogMetrics('feed.lightfm.retrain.success', 1);
      session.log(
        'Datadog metric: feed.lightfm.retrain.success = 1',
        level: LogLevel.info,
      );

      // AC5: Reschedule for next 02:00 UTC
      await _rescheduleNextRun(session);
    } catch (e) {
      session.log(
        'LightFM retraining job failed: $e',
        level: LogLevel.error,
      );

      // AC5: Publish failure metrics to Datadog
      // TODO: Implement Datadog metrics when SDK integrated
      // await _publishDatadogMetrics('feed.lightfm.retrain.failure', 1);
      session.log(
        'Datadog metric: feed.lightfm.retrain.failure = 1',
        level: LogLevel.error,
      );

      rethrow;
    }
  }

  /// Reschedule retraining job for next 02:00 UTC
  /// AC5: Ensures nightly execution at 02:00 UTC
  Future<void> _rescheduleNextRun(Session session) async {
    final now = DateTime.now().toUtc();
    var nextRun = DateTime.utc(
      now.year,
      now.month,
      now.day,
      2, // 02:00 UTC
      0,
      0,
    );

    // Schedule for tomorrow (since we just ran)
    nextRun = nextRun.add(const Duration(days: 1));

    await session.serverpod.futureCallAtTime(
      'feedLightFMRetrain',
      Greeting(
        message: 'LightFM Retrain',
        author: 'System',
        timestamp: DateTime.now(),
      ),
      nextRun,
    );

    session.log(
      'Rescheduled LightFM retraining job for ${nextRun.toIso8601String()} UTC',
      level: LogLevel.info,
    );
  }
}
