# Message Queue Architecture

**Effective Date:** 2025-10-14
**Version:** 1.0
**Implementation:** Redis Streams + Background Jobs
**Objective:** Heavy operations processing with reliability and scalability

## Overview

This document outlines the message queue architecture for the Video Window platform, designed to handle heavy operations, background processing, and asynchronous communication between services. The architecture uses Redis Streams as the underlying technology combined with a robust background job processing system.

## Architecture Components

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Message Queue Architecture                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐    ┌──────────────────┐    ┌────────────────────┐   │
│  │   API       │    │   Background     │    │   Message          │   │
│  │  Gateway    │───▶│    Jobs Manager  │───▶│    Queues         │   │
│  └─────────────┘    └──────────────────┘    └────────────────────┘   │
│          │                     │                      │                │
│          │                     ▼                      ▼                │
│          │            ┌─────────────┐      ┌──────────────┐     │
│          │            │  Job Store  │      │ Redis Streams│     │
│          │            └─────────────┘      └──────────────┘     │
│          │                     │                      │                │
│          ▼                     ▼                      ▼                │
│  ┌─────────────┐    ┌────────────────────────────────────────────┐ │
│  │   Services  │    │           Worker Processes                │ │
│  │ (Auction,   │    │  ┌─────────┐  ┌─────────┐  ┌─────────┐   │ │
│  │ Payment,   │    │  │ Email   │  │ Video   │  │ Search  │   │ │
│  │  Users,     │    │  │  Worker │  │ Worker  │  │ Worker  │   │ │
│  │   etc.)     │    │  └─────────┘  └─────────┘  └─────────┘   │ │
│  └─────────────┘    └────────────────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Queue Design

### 1. Priority Queues

Messages are categorized into different priority levels to ensure critical operations are processed first:

```yaml
queue_priorities:
  critical:    # Urgent operations (payment processing, security alerts)
    priority: 1
    max_workers: 10
    timeout: 30s

  high:        # User-facing operations (email notifications, content processing)
    priority: 2
    max_workers: 8
    timeout: 300s

  normal:      # Background operations (reports, analytics, cleanup)
    priority: 3
    max_workers: 5
    timeout: 1800s

  low:         # Maintenance tasks (log cleanup, data archiving)
    priority: 4
    max_workers: 2
    timeout: 3600s
```

### 2. Queue Categories

#### 2.1 Communication Queues
- **email_queue**: Outbound email notifications
- **push_queue**: Push notifications to mobile devices
- **sms_queue**: SMS notifications
- **webhook_queue**: External webhook deliveries

#### 2.2 Media Processing Queues
- **video_upload_queue**: Video upload processing
- **video_transcode_queue**: Video transcoding to different formats
- **thumbnail_queue**: Thumbnail generation
- **content_moderation_queue**: Content moderation and review

#### 2.3 Data Processing Queues
- **search_index_queue**: Search index updates
- **analytics_queue**: Analytics data processing
- **report_generation_queue**: Report generation tasks
- **data_export_queue**: Data export requests

#### 2.4 Maintenance Queues
- **cleanup_queue**: Data cleanup tasks
- **backup_queue**: Backup operations
- **maintenance_queue**: System maintenance tasks
- **monitoring_queue**: Health checks and monitoring

## Message Format

### Standard Message Structure

```json
{
  "id": "msg_123456789",
  "queue": "email_queue",
  "priority": 2,
  "payload": {
    "type": "send_welcome_email",
    "recipient": "user@example.com",
    "template": "welcome",
    "data": {
      "name": "John Doe",
      "verification_url": "https://app.example.com/verify/123"
    }
  },
  "metadata": {
    "created_at": "2025-10-14T10:30:00Z",
    "created_by": "user_service",
    "correlation_id": "req_123456789",
    "retry_count": 0,
    "max_retries": 3,
    "delay_until": null,
    "timeout": 30000
  }
}
```

### Message Metadata Fields

- **created_at**: Message creation timestamp
- **created_by**: Service or user that created the message
- **correlation_id**: Links related messages together
- **retry_count**: Number of retry attempts
- **max_retries**: Maximum allowed retry attempts
- **delay_until**: Delay processing until this timestamp
- **timeout**: Maximum processing time in milliseconds

## Queue Operations

### 1. Message Publishing

```dart
// Publishing a message to a queue
class MessagePublisher {
  final RedisConnection _redis;

  Future<void> publish(String queueName, Message message) async {
    final streamKey = 'queue:${queueName}';
    final messageData = {
      'id': message.id,
      'queue': queueName,
      'priority': message.priority,
      'payload': message.payload,
      'metadata': message.metadata,
    };

    await _redis.xAdd(
      streamKey,
      messageData,
      id: '*',
      maxlen: 10000, // Keep only last 10,000 messages
    );
  }
}
```

### 2. Message Consumption

```dart
// Consuming messages from a queue
class MessageConsumer {
  final RedisConnection _redis;
  final Map<String, MessageHandler> _handlers = {};
  final String _consumerGroup;
  final String _consumerName;

  Future<void> startConsuming(String queueName) async {
    final streamKey = 'queue:${queueName}';

    while (true) {
      final messages = await _redis.xReadGroup(
        _consumerGroup,
        _consumerName,
        {streamKey: '>'},
        count: 10,
        block: 1000,
      );

      for (final message in messages) {
        await _processMessage(message);
      }
    }
  }

  Future<void> _processMessage(StreamMessage message) async {
    final queueName = message.data['queue'] as String;
    final handler = _handlers[queueName];

    if (handler != null) {
      try {
        await handler.handle(message);
        await _redis.xAck(message.streamName, _consumerGroup, message.id);
      } catch (error) {
        await _handleProcessingError(message, error);
      }
    }
  }
}
```

### 3. Dead Letter Queue

```dart
// Dead Letter Queue for failed messages
class DeadLetterQueue {
  final RedisConnection _redis;

  Future<void> addToDLQ(StreamMessage originalMessage, String error) async {
    final dlqData = {
      'original_message': originalMessage.data,
      'original_queue': originalMessage.data['queue'],
      'original_id': originalMessage.id,
      'error': error,
      'failed_at': DateTime.now().toIso8601String(),
      'retry_count': originalMessage.metadata['retry_count'],
    };

    await _redis.xAdd(
      'queue:dead_letter',
      dlqData,
      id: '*',
    );
  }

  Future<List<Map<String, dynamic>>> getDLQMessages({int limit = 100}) async {
    final messages = await _redis.xRange(
      'queue:dead_letter',
      '-',
      '+',
      count: limit,
    );

    return messages.map((msg) => msg.fields).toList();
  }
}
```

## Worker Process Architecture

### 1. Worker Pool Management

```dart
class WorkerPool {
  final String queueName;
  final int maxWorkers;
  final List<Worker> _workers = [];
  final List<MessageHandler> _handlers = [];

  WorkerPool({
    required this.queueName,
    required this.maxWorkers,
    required List<MessageHandler> handlers,
  }) : _handlers = handlers;

  Future<void> start() async {
    for (int i = 0; i < maxWorkers; i++) {
      final worker = Worker(
        id: '${queueName}_worker_$i',
        queueName: queueName,
        handlers: _handlers,
      );
      _workers.add(worker);
      worker.start();
    }
  }

  Future<void> stop() async {
    for (final worker in _workers) {
      await worker.stop();
    }
  }
}
```

### 2. Worker Process Implementation

```dart
class Worker {
  final String id;
  final String queueName;
  final List<MessageHandler> _handlers;

  Worker({
    required this.id,
    required this.queueName,
    required List<MessageHandler> handlers,
  }) : _handlers = handlers;

  Future<void> start() async {
    print('Worker $id started for queue: $queueName');

    // Start consuming messages in a separate isolate or thread
    unawaited(_consumeLoop());
  }

  Future<void> _consumeLoop() async {
    while (true) {
      try {
        final message = await _getNextMessage();
        if (message != null) {
          await _processMessage(message);
        }
      } catch (error) {
        print('Worker $id error: $error');
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }

  Future<StreamMessage?> _getNextMessage() async {
    // Implementation would get next message from queue
    return null;
  }

  Future<void> _processMessage(StreamMessage message) async {
    final messageType = message.data['payload']['type'] as String;
    final handler = _handlers.firstWhere(
      (h) => h.canHandle(messageType),
      orElse: () => throw Exception('No handler for message type: $messageType'),
    );

    await handler.handle(message);
  }

  Future<void> stop() async {
    print('Worker $id stopped');
  }
}
```

## Message Handlers

### 1. Email Handler

```dart
class EmailMessageHandler implements MessageHandler {
  @override
  bool canHandle(String messageType) {
    return messageType.startsWith('email_');
  }

  @override
  Future<void> handle(StreamMessage message) async {
    final payload = message.data['payload'] as Map<String, dynamic>;
    final type = payload['type'] as String;

    switch (type) {
      case 'send_welcome_email':
        await _sendWelcomeEmail(payload);
        break;
      case 'send_bid_notification':
        await _sendBidNotification(payload);
        break;
      case 'send_payment_receipt':
        await _sendPaymentReceipt(payload);
        break;
      default:
        throw Exception('Unknown email message type: $type');
    }
  }

  Future<void> _sendWelcomeEmail(Map<String, dynamic> payload) async {
    final recipient = payload['recipient'] as String;
    final template = payload['template'] as String;
    final data = payload['data'] as Map<String, dynamic>;

    // Simulate email sending
    await Future.delayed(Duration(milliseconds: 500));
    print('Welcome email sent to: $recipient');
  }
}
```

### 2. Video Processing Handler

```dart
class VideoProcessingHandler implements MessageHandler {
  @override
  bool canHandle(String messageType) {
    return messageType.startsWith('video_');
  }

  @override
  Future<void> handle(StreamMessage message) async {
    final payload = message.data['payload'] as Map<String, dynamic>;
    final type = payload['type'] as String;

    switch (type) {
      case 'process_video_upload':
        await _processVideoUpload(payload);
        break;
      case 'generate_thumbnails':
        await _generateThumbnails(payload);
        break;
      case 'transcode_video':
        await _transcodeVideo(payload);
        break;
      default:
        throw Exception('Unknown video message type: $type');
    }
  }

  Future<void> _processVideoUpload(Map<String, dynamic> payload) async {
    final videoId = payload['videoId'] as String;
    final filePath = payload['filePath'] as String;

    // Simulate video processing
    await Future.delayed(Duration(seconds: 10));
    print('Video processed: $videoId');
  }
}
```

## Configuration and Deployment

### 1. Queue Configuration

```yaml
# config/queues.yaml
queues:
  email_queue:
    max_length: 10000
    consumer_group: email_consumers
    max_consumers: 5
    ack_timeout: 30s
    retry_delay: 60s
    max_retries: 3

  video_processing_queue:
    max_length: 1000
    consumer_group: video_workers
    max_consumers: 3
    ack_timeout: 1800s
    retry_delay: 300s
    max_retries: 2

  search_index_queue:
    max_length: 5000
    consumer_group: search_workers
    max_consumers: 2
    ack_timeout: 60s
    retry_delay: 30s
    max_retries: 5

  webhook_queue:
    max_length: 2000
    consumer_group: webhook_workers
    max_consumers: 4
    ack_timeout: 30s
    retry_delay: 60s
    max_retries: 3
    exponential_backoff: true
```

### 2. Worker Deployment

```yaml
# docker-compose.workers.yml
version: '3.8'

services:
  email-worker:
    build: ./workers/email
    environment:
      - QUEUE_NAME=email_queue
      - REDIS_URL=redis://redis:6379
      - MAX_CONCURRENT=5
    depends_on:
      - redis
    restart: unless-stopped

  video-worker:
    build: ./workers/video
    environment:
      - QUEUE_NAME=video_processing_queue
      - REDIS_URL=redis://redis:6379
      - MAX_CONCURRENT=3
    depends_on:
      - redis
    restart: unless-stopped

  search-worker:
    build: ./workers/search
    environment:
      - QUEUE_NAME=search_index_queue
      - REDIS_URL=redis://redis:6379
      - MAX_CONCURRENT=2
    depends_on:
      - redis
    restart: unless-stopped

  webhook-worker:
    build: ./workers/webhook
    environment:
      - QUEUE_NAME=webhook_queue
      - REDIS_URL=redis://redis:6379
      - MAX_CONCURRENT=4
    depends_on:
      - redis
    restart: unless-stopped
```

## Monitoring and Observability

### 1. Queue Metrics

```dart
class QueueMetrics {
  final RedisConnection _redis;

  Future<Map<String, dynamic>> getQueueMetrics(String queueName) async {
    final streamKey = 'queue:${queueName}';

    // Get stream info
    final info = await _redis.xInfoStream(streamKey);

    // Get consumer group info
    final groups = await _redis.xInfoGroups(streamKey);

    return {
      'queue_name': queueName,
      'total_messages': info['length'],
      'first_entry': info['first-entry'],
      'last_entry': info['last-entry'],
      'consumer_groups': groups,
      'pending_messages': _calculatePendingMessages(groups),
    };
  }

  int _calculatePendingMessages(List<Map<String, dynamic>> groups) {
    return groups.fold(0, (sum, group) => sum + (group['pending'] as int));
  }
}
```

### 2. Health Checks

```dart
class QueueHealthChecker {
  final List<String> _queueNames;
  final QueueMetrics _metrics;

  Future<Map<String, bool>> checkAllQueues() async {
    final results = <String, bool>{};

    for (final queueName in _queueNames) {
      try {
        final metrics = await _metrics.getQueueMetrics(queueName);
        results[queueName] = _isQueueHealthy(metrics);
      } catch (error) {
        results[queueName] = false;
      }
    }

    return results;
  }

  bool _isQueueHealthy(Map<String, dynamic> metrics) {
    final totalMessages = metrics['total_messages'] as int;
    final pendingMessages = metrics['pending_messages'] as int;

    // Queue is healthy if:
    // - Not exceeding max message limit
    // - Pending messages are not too high
    // - Consumer groups are responding
    return totalMessages < 10000 && pendingMessages < 1000;
  }
}
```

## Error Handling and Retry Logic

### 1. Retry Strategies

```dart
abstract class RetryStrategy {
  Duration calculateDelay(int attemptCount);
}

class ExponentialBackoffRetry implements RetryStrategy {
  final Duration baseDelay;
  final Duration maxDelay;
  final double multiplier;

  ExponentialBackoffRetry({
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 10),
    this.multiplier = 2.0,
  });

  @override
  Duration calculateDelay(int attemptCount) {
    final delay = Duration(
      milliseconds: (baseDelay.inMilliseconds * math.pow(multiplier, attemptCount)).round(),
    );

    return delay > maxDelay ? maxDelay : delay;
  }
}

class FixedDelayRetry implements RetryStrategy {
  final Duration delay;

  FixedDelayRetry(this.delay);

  @override
  Duration calculateDelay(int attemptCount) {
    return delay;
  }
}
```

### 2. Error Classification

```dart
enum ErrorCategory {
  transient,    // Temporary errors (network timeout, rate limit)
  permanent,    // Permanent errors (invalid data, configuration)
  retryable,    // Errors that might succeed on retry
  non_retryable, // Errors that should not be retried
}

class ErrorClassifier {
  static ErrorCategory classifyError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('rate limit')) {
      return ErrorCategory.transient;
    }

    if (errorString.contains('invalid') ||
        errorString.contains('not found') ||
        errorString.contains('unauthorized')) {
      return ErrorCategory.permanent;
    }

    return ErrorCategory.retryable;
  }
}
```

## Performance Optimization

### 1. Batch Processing

```dart
class BatchProcessor {
  final int batchSize;
  final Duration batchTimeout;
  final List<Map<String, dynamic>> _batch = [];

  BatchProcessor({this.batchSize = 100, this.batchTimeout = const Duration(seconds: 5)});

  Future<void> addToBatch(Map<String, dynamic> message) async {
    _batch.add(message);

    if (_batch.length >= batchSize) {
      await _processBatch();
    } else {
      _scheduleBatchProcessing();
    }
  }

  Future<void> _processBatch() async {
    if (_batch.isEmpty) return;

    final currentBatch = List.from(_batch);
    _batch.clear();

    // Process batch
    await _handleBatch(currentBatch);
  }

  Future<void> _handleBatch(List<Map<String, dynamic>> batch) async {
    // Process messages in batch
    for (final message in batch) {
      await _processMessage(message);
    }
  }

  Timer? _batchTimer;

  void _scheduleBatchProcessing() {
    _batchTimer?.cancel();
    _batchTimer = Timer(batchTimeout, () {
      _processBatch();
    });
  }
}
```

### 2. Connection Pooling

```dart
class RedisConnectionPool {
  final String _redisUrl;
  final int _maxConnections;
  final Queue<RedisConnection> _availableConnections = Queue();
  final Set<RedisConnection> _usedConnections = {};

  RedisConnectionPool(this._redisUrl, this._maxConnections);

  Future<RedisConnection> getConnection() async {
    if (_availableConnections.isNotEmpty) {
      return _availableConnections.removeFirst();
    }

    if (_usedConnections.length < _maxConnections) {
      final connection = await _createConnection();
      _usedConnections.add(connection);
      return connection;
    }

    // Wait for available connection
    return await _waitForConnection();
  }

  Future<void> releaseConnection(RedisConnection connection) async {
    if (_usedConnections.contains(connection)) {
      _availableConnections.add(connection);
    }
  }

  Future<RedisConnection> _createConnection() async {
    // Create new Redis connection
    return RedisConnection.connect(_redisUrl);
  }

  Future<RedisConnection> _waitForConnection() async {
    // Implementation would wait for available connection
    await Future.delayed(Duration(milliseconds: 100));
    return getConnection();
  }
}
```

## Security Considerations

### 1. Message Authentication

```dart
class MessageAuthenticator {
  final String _secretKey;

  MessageAuthenticator(this._secretKey);

  String signMessage(Map<String, dynamic> message) {
    final messageJson = jsonEncode(message);
    final signature = Hmac(sha256, utf8.encode(_secretKey))
        .convert(utf8.encode(messageJson))
        .toString();

    return base64Encode(signature.bytes);
  }

  bool verifyMessage(Map<String, dynamic> message, String signature) {
    final expectedSignature = signMessage(message);
    return expectedSignature == signature;
  }
}
```

### 2. Access Control

```dart
class QueueAccessControl {
  final Map<String, Set<String>> _queuePermissions = {};

  void grantPermission(String queueName, String consumer) {
    _queuePermissions.putIfAbsent(queueName, () => {}).add(consumer);
  }

  bool canConsume(String queueName, String consumer) {
    return _queuePermissions[queueName]?.contains(consumer) ?? false;
  }
}
```

## Testing Strategy

### 1. Unit Tests

```dart
void main() {
  group('Message Queue Tests', () {
    late MessageQueue queue;

    setUp(() {
      queue = MessageQueue(RedisConnection.mock());
    });

    test('should publish and consume message', () async {
      final message = Message(
        id: 'test_1',
        queue: 'test_queue',
        payload: {'type': 'test', 'data': 'value'},
      );

      await queue.publish(message);

      final consumedMessage = await queue.consume('test_queue');
      expect(consumedMessage, isNotNull);
      expect(consumedMessage!.id, equals(message.id));
    });

    test('should handle message retry on failure', () async {
      final message = Message(
        id: 'test_2',
        queue: 'test_queue',
        payload: {'type': 'fail_test', 'data': 'value'},
      );

      await queue.publish(message);

      // Simulate processing failure
      // Verify message is retried
    });
  });
}
```

### 2. Integration Tests

```dart
void main() {
  group('Queue Integration Tests', () {
    late RedisContainer redis;
    late MessageQueue queue;

    setUpAll(() async {
      redis = RedisContainer();
      await redis.start();
      queue = MessageQueue(RedisConnection.connect(redis.connectionString));
    });

    tearDownAll(() async {
      await redis.stop();
    });

    test('should process messages across multiple workers', () async {
      final workerPool = WorkerPool(
        queueName: 'integration_test',
        maxWorkers: 3,
        handlers: [TestMessageHandler()],
      );

      await workerPool.start();

      // Publish multiple messages
      for (int i = 0; i < 10; i++) {
        await queue.publish(Message(
          id: 'test_$i',
          queue: 'integration_test',
          payload: {'type': 'test', 'data': 'value_$i'},
        ));
      }

      // Wait for processing
      await Future.delayed(Duration(seconds: 5));

      // Verify all messages were processed
      final processedMessages = await getProcessedMessages();
      expect(processedMessages.length, equals(10));

      await workerPool.stop();
    });
  });
}
```

## Deployment and Scaling

### 1. Horizontal Scaling

```yaml
# Kubernetes deployment for workers
apiVersion: apps/v1
kind: Deployment
metadata:
  name: message-workers
spec:
  replicas: 3
  selector:
    matchLabels:
      app: message-workers
  template:
    metadata:
      labels:
        app: message-workers
    spec:
      containers:
      - name: worker
        image: video-window/message-workers:latest
        env:
        - name: QUEUE_NAMES
          value: "email_queue,video_processing_queue,search_index_queue"
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: redis-secret
              key: url
        - name: MAX_CONCURRENT_JOBS
          value: "5"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### 2. Auto-scaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: message-workers-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: message-workers
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

---

**Related Documents:**
- [Background Job Processing System](../background_jobs/)
- [Event-Driven Architecture](../adr/ADR-002-event-driven-architecture.md)
- [API Gateway Implementation](../adr/ADR-001-api-gateway.md)

**Next Steps:**
1. Implement message queue monitoring
2. Set up automated testing for queues
3. Configure production deployments
4. Establish performance benchmarks
5. Create queue operation runbooks