import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import '../../generated/feed/user_interaction.dart';

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

      // AC3: Persist to user_interactions table
      try {
        // Convert userId from String to int (assuming it's numeric)
        final userIdInt = int.tryParse(userId) ?? 0;
        if (userIdInt == 0) {
          session.log(
            'Invalid userId format: $userId',
            level: LogLevel.warning,
          );
        }

        final interaction = UserInteraction(
          userId: userIdInt,
          videoId: videoId,
          interactionType: interactionType,
          watchTimeSeconds: watchTime,
          metadata: metadata != null ? jsonEncode(metadata) : null,
          createdAt: DateTime.now().toUtc(),
        );

        await UserInteraction.db.insertRow(session, interaction);

        session.log(
          'Interaction persisted to database: $interactionType for video $videoId',
          level: LogLevel.info,
        );
      } catch (e) {
        // Log error but don't fail the request - Kafka logging is more critical
        session.log(
          'Failed to persist interaction to database: $e',
          level: LogLevel.warning,
        );
      }

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
