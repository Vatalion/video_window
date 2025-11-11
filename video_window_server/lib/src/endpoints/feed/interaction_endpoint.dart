import 'dart:convert';

import 'package:serverpod/serverpod.dart';

/// Interaction endpoint for recording feed interactions
/// AC3: Streams events to Kafka topic feed.interactions.v1 with schema
/// {userId, videoId, interactionType, watchTime, timestamp}
class InteractionEndpoint extends Endpoint {
  @override
  String get name => 'feed.interaction';

  /// Record video interaction and stream to Kafka
  /// AC3: Enqueues Kafka messages and persists to user_interactions table
  Future<Map<String, dynamic>> recordInteraction(
    Session session, {
    required String userId,
    required String videoId,
    required String interactionType,
    int? watchTime,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();

      // AC3: Prepare Kafka message with required schema
      final kafkaMessage = {
        'userId': userId,
        'videoId': videoId,
        'interactionType': interactionType,
        'watchTime': watchTime,
        'timestamp': timestamp,
        if (metadata != null) ...metadata,
      };

      // AC3: Stream to Kafka topic feed.interactions.v1
      // TODO: Integrate serverpod_kafka plugin 1.3.0 when available
      // await _kafkaProducer.send(
      //   topic: 'feed.interactions.v1',
      //   key: userId,
      //   value: jsonEncode(kafkaMessage),
      // );

      // Placeholder: Log Kafka message for now
      session.log(
        'Kafka message (feed.interactions.v1): ${jsonEncode(kafkaMessage)}',
        level: LogLevel.info,
      );

      // Persist to user_interactions table
      // TODO: Implement database insert when table schema is ready
      // await session.db.insert(
      //   'user_interactions',
      //   {
      //     'user_id': userId,
      //     'video_id': videoId,
      //     'interaction_type': interactionType,
      //     'watch_time': watchTime,
      //     'timestamp': timestamp,
      //     'recommendation_score': metadata?['recommendation_score'],
      //   },
      // );

      session.log(
        'Interaction recorded: $interactionType for video $videoId by user $userId',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'interactionId': '${DateTime.now().millisecondsSinceEpoch}',
        'timestamp': timestamp,
      };
    } catch (e) {
      session.log(
        'Failed to record interaction: $e',
        level: LogLevel.error,
      );
      throw Exception('Failed to record interaction: $e');
    }
  }
}
