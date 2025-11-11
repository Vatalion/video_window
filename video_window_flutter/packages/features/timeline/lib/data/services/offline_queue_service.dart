import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/video_interaction.dart';

/// Offline queue service for failed network requests
/// PERF-004: Offline queue with exponential backoff retry
/// AC6: Crash-safe resume with offline queue support
class OfflineQueueService {
  static const String _queueKey = 'feed_offline_queue';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Timer? _retryTimer;
  static const Duration _initialRetryDelay = Duration(seconds: 5);
  static const Duration _maxRetryDelay = Duration(minutes: 5);
  int _retryAttempts = 0;

  /// Add interaction to offline queue
  Future<void> queueInteraction(VideoInteraction interaction) async {
    try {
      final queue = await getQueuedInteractions();
      queue.add(interaction);
      await _saveQueue(queue);
    } catch (e) {
      // Log error
    }
  }

  /// Get all queued interactions
  Future<List<VideoInteraction>> getQueuedInteractions() async {
    try {
      final queueJson = await _storage.read(key: _queueKey);
      if (queueJson == null) return [];

      final List<dynamic> queueList = jsonDecode(queueJson);
      return queueList
          .map((item) => _interactionFromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Process queued interactions with exponential backoff
  Future<void> processQueue(
      Future<void> Function(VideoInteraction) processFn) async {
    final queue = await getQueuedInteractions();
    if (queue.isEmpty) return;

    try {
      final interaction = queue.first;
      await processFn(interaction);

      // Success - remove from queue
      queue.removeAt(0);
      await _saveQueue(queue);
      _retryAttempts = 0; // Reset on success
    } catch (e) {
      // Failed - schedule retry with exponential backoff
      _scheduleRetry(() => processQueue(processFn));
    }
  }

  void _scheduleRetry(VoidCallback retryFn) {
    _retryTimer?.cancel();

    final delay = Duration(
      milliseconds: (_initialRetryDelay.inMilliseconds *
              (1 << _retryAttempts.clamp(0, 10)))
          .clamp(
        _initialRetryDelay.inMilliseconds,
        _maxRetryDelay.inMilliseconds,
      ),
    );

    _retryAttempts++;
    _retryTimer = Timer(delay, retryFn);
  }

  Future<void> _saveQueue(List<VideoInteraction> queue) async {
    try {
      final queueJson =
          jsonEncode(queue.map((i) => _interactionToJson(i)).toList());
      await _storage.write(key: _queueKey, value: queueJson);
    } catch (e) {
      // Log error
    }
  }

  Map<String, dynamic> _interactionToJson(VideoInteraction interaction) {
    return {
      'id': interaction.id,
      'userId': interaction.userId,
      'videoId': interaction.videoId,
      'type': interaction.type.name,
      'watchTime': interaction.watchTime?.inSeconds,
      'timestamp': interaction.timestamp.toIso8601String(),
      'metadata': interaction.metadata,
    };
  }

  VideoInteraction _interactionFromJson(Map<String, dynamic> json) {
    return VideoInteraction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      videoId: json['videoId'] as String,
      type: InteractionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InteractionType.view,
      ),
      watchTime: json['watchTime'] != null
          ? Duration(seconds: json['watchTime'] as int)
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  void dispose() {
    _retryTimer?.cancel();
  }
}
