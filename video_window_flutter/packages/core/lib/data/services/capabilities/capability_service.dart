import 'dart:async';
import '../../repositories/capabilities/capability_repository.dart';

/// Service layer for capability operations
/// Implements Epic 2 Story 2-1 Tasks 8-9
///
/// Provides:
/// - API calls with retry policies
/// - Exponential backoff polling
/// - Domain event emission for analytics
class CapabilityService {
  final CapabilityRepository _repository;
  final CapabilityEventBus _eventBus;

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration requestTimeout = Duration(seconds: 10);

  CapabilityService(this._repository, this._eventBus);

  /// Fetch capability status with retry policy
  ///
  /// Implements HTTP retry on transient failures (5xx errors, timeouts)
  Future<dynamic> getStatus(int userId) async {
    return await _retryOperation(
      () => _repository.fetchStatus(userId),
      operationName: 'getStatus',
    );
  }

  /// Request capability with analytics emission
  ///
  /// AC5: Analytics event capability_request_submitted is recorded
  Future<dynamic> requestCapability({
    required int userId,
    required String capability,
    required String entryPoint,
    Map<String, String>? additionalContext,
  }) async {
    final context = {
      'entryPoint': entryPoint,
      ...?additionalContext,
    };

    try {
      final result = await _retryOperation(
        () => _repository.requestCapability(
          userId: userId,
          capability: capability,
          context: context,
        ),
        operationName: 'requestCapability',
      );

      // Emit domain event for analytics bus
      _eventBus.emit(CapabilityRequestedEvent(
        userId: userId,
        capability: capability,
        entryPoint: entryPoint,
        success: true,
      ));

      return result;
    } catch (e) {
      // Emit failure event
      _eventBus.emit(CapabilityRequestedEvent(
        userId: userId,
        capability: capability,
        entryPoint: entryPoint,
        success: false,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// Subscribe to capability updates with exponential backoff
  ///
  /// Polls server for status changes
  /// Returns stream of status updates
  Stream<dynamic> subscribeToUpdates(
    int userId, {
    Duration initialInterval = const Duration(seconds: 5),
    Duration maxInterval = const Duration(minutes: 5),
  }) {
    return _repository.subscribeToUpdates(
      userId,
      initialInterval: initialInterval,
      maxInterval: maxInterval,
    );
  }

  /// Internal: Retry operation with exponential backoff
  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    required String operationName,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        attempt++;
        return await operation().timeout(requestTimeout);
      } catch (e) {
        if (attempt >= maxRetries) {
          throw CapabilityServiceException(
            'Operation $operationName failed after $maxRetries attempts: $e',
          );
        }

        // Exponential backoff: 2s, 4s, 8s
        final delay = retryDelay * (1 << (attempt - 1));
        await Future.delayed(delay);
      }
    }
  }
}

/// Domain event bus for capability events
///
/// Emits events to analytics service
class CapabilityEventBus {
  final StreamController<CapabilityEvent> _controller =
      StreamController<CapabilityEvent>.broadcast();

  Stream<CapabilityEvent> get events => _controller.stream;

  void emit(CapabilityEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

/// Base capability event
abstract class CapabilityEvent {
  final DateTime timestamp = DateTime.now();
}

/// Event emitted when capability is requested
///
/// AC5: Analytics event capability_request_submitted
class CapabilityRequestedEvent extends CapabilityEvent {
  final int userId;
  final String capability;
  final String entryPoint;
  final bool success;
  final String? error;

  CapabilityRequestedEvent({
    required this.userId,
    required this.capability,
    required this.entryPoint,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toAnalytics() {
    return {
      'event': 'capability_request_submitted',
      'userId': userId,
      'capability': capability,
      'entryPoint': entryPoint,
      'success': success,
      'timestamp': timestamp.toIso8601String(),
      if (error != null) 'error': error,
    };
  }
}

/// Exception thrown by capability service
class CapabilityServiceException implements Exception {
  final String message;

  CapabilityServiceException(this.message);

  @override
  String toString() => 'CapabilityServiceException: $message';
}
