import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:serverpod/serverpod.dart';

import 'feed_service.dart';

/// Recommendation bridge service for LightFM API integration
/// AC1: Proxies requests to LightFM API v2025.9 with gRPC deadline 150ms and retries capped at 2
/// AC2: Handles fallback to trending feed when LightFM errors or exceeds deadline
class RecommendationBridgeService {
  final Session _session;
  static const Duration _grpcDeadline = Duration(milliseconds: 150);
  static const int _maxRetries = 2;
  static const String _lightfmApiVersion = 'v2025.9';

  // Public getters for testing
  static Duration get grpcDeadline => _grpcDeadline;
  static int get maxRetries => _maxRetries;
  static String get lightfmApiVersion => _lightfmApiVersion;

  // Circuit breaker state
  bool _circuitOpen = false;
  DateTime? _circuitOpenTime;
  static const Duration _circuitResetTimeout = Duration(minutes: 1);
  int _consecutiveFailures = 0;
  static const int _circuitBreakerThreshold = 5;

  RecommendationBridgeService(this._session);

  /// Get personalized recommendations from LightFM service
  /// AC1: gRPC deadline 150ms, retries capped at 2
  /// AC2: Falls back to trending feed on error or timeout
  /// AC5: Includes user-configured tags and blocked makers in payload
  Future<List<String>> getRecommendations({
    required String userId,
    int limit = 20,
    List<String>? excludeVideoIds,
    List<String>? preferredTags,
    List<String>? blockedMakers,
  }) async {
    // Check circuit breaker
    if (_circuitOpen) {
      if (_shouldResetCircuit()) {
        _resetCircuit();
      } else {
        _session.log(
          'Circuit breaker is open, falling back to trending feed',
          level: LogLevel.warning,
        );
        return await _fallbackToTrending(userId, limit, excludeVideoIds);
      }
    }

    try {
      final recommendations = await _callLightFMService(
        userId: userId,
        limit: limit,
        excludeVideoIds: excludeVideoIds,
        preferredTags: preferredTags,
        blockedMakers: blockedMakers,
      );

      // Reset failure counter on success
      _consecutiveFailures = 0;
      return recommendations;
    } catch (e) {
      _consecutiveFailures++;

      // Open circuit if threshold reached
      if (_consecutiveFailures >= _circuitBreakerThreshold) {
        _openCircuit();
      }

      _session.log(
        'LightFM recommendation failed: $e',
        level: LogLevel.error,
      );

      // AC2: Fallback to trending feed
      return await _fallbackToTrending(userId, limit, excludeVideoIds);
    }
  }

  /// Call LightFM gRPC service with retry logic
  /// AC1: Deadline 150ms, max retries 2
  /// AC5: Includes blocked makers in request payload
  Future<List<String>> _callLightFMService({
    required String userId,
    required int limit,
    List<String>? excludeVideoIds,
    List<String>? preferredTags,
    List<String>? blockedMakers,
  }) async {
    // TODO: Configure actual gRPC channel endpoint from environment/config
    // For now, using placeholder - will be configured via environment variables
    // final channel = ClientChannel(
    //   'lightfm-service.internal', // Replace with actual endpoint
    //   port: 50051,
    //   options: const ChannelOptions(
    //     credentials: ChannelCredentials.insecure(),
    //   ),
    // );

    // TODO: Generate actual gRPC client stub from proto files
    // This is a placeholder implementation structure
    // final stub = RecommendationServiceClient(channel);

    Exception? lastException;
    Stopwatch? stopwatch;

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        stopwatch = Stopwatch()..start();

        // AC1: Set gRPC deadline to 150ms
        // TODO: Use callOptions when actual gRPC call is implemented
        // final callOptions = CallOptions(
        //   timeout: _grpcDeadline,
        //   metadata: {
        //     'api-version': _lightfmApiVersion,
        //     'user-id': userId,
        //   },
        // );

        // TODO: Replace with actual gRPC call when proto files are available
        // AC5: Include blocked makers in request payload
        // final request = GetRecommendationsRequest(
        //   userId: userId,
        //   limit: limit,
        //   excludeVideoIds: excludeVideoIds ?? [],
        //   preferredTags: preferredTags ?? [],
        //   blockedMakers: blockedMakers ?? [], // AC5: Include blocked makers
        // );
        // final response = await stub.getRecommendations(request, options: callOptions);
        // return response.videoIds;

        // Placeholder: Simulate gRPC call
        await Future.delayed(const Duration(milliseconds: 50));

        stopwatch.stop();

        // Log metrics
        _logMetrics(
          success: true,
          duration: stopwatch.elapsedMilliseconds,
          attempt: attempt,
        );

        // Placeholder return - replace with actual response
        return List.generate(limit, (i) => 'video_${userId}_$i');
      } on GrpcError catch (e) {
        lastException = e;
        stopwatch?.stop();

        _logMetrics(
          success: false,
          duration: stopwatch?.elapsedMilliseconds ?? 0,
          attempt: attempt,
          error: e.message,
        );

        // Don't retry on deadline exceeded
        if (e.code == StatusCode.deadlineExceeded) {
          throw Exception('LightFM deadline exceeded: ${e.message}');
        }

        // Retry on other errors if attempts remain
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: 10 * (attempt + 1)));
          continue;
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        if (attempt >= _maxRetries) {
          break;
        }
        await Future.delayed(Duration(milliseconds: 10 * (attempt + 1)));
      }
    }

    throw lastException ??
        Exception('LightFM service call failed after $_maxRetries retries');
  }

  /// Fallback to trending feed when LightFM fails
  /// AC2: Logs Datadog event feed.recommendation.fallback
  Future<List<String>> _fallbackToTrending(
    String userId,
    int limit,
    List<String>? excludeVideoIds,
  ) async {
    // AC2: Log fallback event
    _session.log(
      'feed.recommendation.fallback',
      level: LogLevel.warning,
      // TODO: Emit Datadog event when SDK integrated
      // await _datadogClient.emitEvent('feed.recommendation.fallback', {
      //   'user_id': userId,
      //   'limit': limit,
      //   'reason': 'lightfm_error',
      // });
    );

    // Get trending videos from feed service
    final feedService = FeedService(_session);
    final trendingResult = await feedService.getFeedVideos(
      userId: userId,
      algorithm: 'trending',
      limit: limit,
      excludeVideoIds: excludeVideoIds,
    );

    return trendingResult.videos
        .map((v) => v['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// Log metrics for monitoring
  void _logMetrics({
    required bool success,
    required int duration,
    required int attempt,
    String? error,
  }) {
    _session.log(
      'LightFM recommendation metrics: success=$success, duration=${duration}ms, attempt=$attempt${error != null ? ", error=$error" : ""}',
      level: success ? LogLevel.info : LogLevel.warning,
    );

    // TODO: Publish to Datadog when SDK integrated
    // await _datadogClient.histogram('feed.recommendation.latency', duration, tags: [
    //   'success:$success',
    //   'attempt:$attempt',
    // ]);
  }

  /// Circuit breaker: Open circuit
  void _openCircuit() {
    _circuitOpen = true;
    _circuitOpenTime = DateTime.now();
    _session.log(
      'Circuit breaker opened due to consecutive failures',
      level: LogLevel.error,
    );
  }

  /// Circuit breaker: Reset circuit
  void _resetCircuit() {
    _circuitOpen = false;
    _circuitOpenTime = null;
    _consecutiveFailures = 0;
    _session.log(
      'Circuit breaker reset',
      level: LogLevel.info,
    );
  }

  /// Check if circuit should be reset
  bool _shouldResetCircuit() {
    if (!_circuitOpen || _circuitOpenTime == null) return false;
    return DateTime.now().difference(_circuitOpenTime!) > _circuitResetTimeout;
  }
}
