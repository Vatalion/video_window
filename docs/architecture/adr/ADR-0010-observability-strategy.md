# ADR-0010: Observability Strategy

**Date:** 2025-10-09
**Status:** Accepted
**Decider(s):** Technical Lead, DevOps Team
**Reviewers:** Development Team, QA Team, Operations Team

## Context
The video marketplace platform requires comprehensive observability to ensure reliable operation, quick issue detection, and optimal performance. We need to monitor application health, user behavior, business metrics, and infrastructure performance across our Flutter + Serverpod stack with complex real-time auction functionality.

## Decision
Implement a comprehensive observability strategy using OpenTelemetry for distributed tracing, Prometheus for metrics collection, Loki for log aggregation, and Grafana for visualization. This provides end-to-end visibility across mobile clients, backend services, and infrastructure.

## Options Considered

1. **Option A** - Basic Cloud Provider Monitoring
   - Pros: Simple setup, managed service
   - Cons: Limited customization, vendor lock-in
   - Risk: Insufficient for complex debugging

2. **Option B** - Comprehensive OpenTelemetry Stack (Chosen)
   - Pros: Standardized, vendor-neutral, comprehensive
   - Cons: Higher operational complexity
   - Risk: Learning curve for team

3. **Option C** - Commercial APM Solution (DataDog/New Relic)
   - Pros: Feature-rich, managed service
   - Cons: High cost, vendor lock-in
   - Risk: Budget constraints at scale

4. **Option D** - DIY Monitoring Solution
   - Pros: Full control, tailored to needs
   - Cons: High maintenance, security expertise needed
   - Risk: Implementation complexity and maintenance burden

## Decision Outcome
Chose Option B: Comprehensive OpenTelemetry Stack. This provides:
- Standardized observability across all components
- Vendor-neutral data collection
- Powerful visualization and alerting
- Scalable monitoring architecture
- Cost-effective solution

## Observability Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Data Collection Layer                     │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ │
│  │   OpenTelemetry │ │   Prometheus    │ │      Loki       │ │
│  │   (Traces/Metrics)│ │   (Metrics)     │ │   (Logs)        │ │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Processing Layer                         │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ │
│  │   Jaeger        │ │   AlertManager  │ │   Loki Aggregator│ │
│  │   (Trace Storage)│ │   (Alerting)    │ │   (Log Storage) │ │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                  Visualization Layer                         │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ │
│  │     Grafana     │ │   Grafana       │ │   Grafana       │ │
│  │   (Traces)      │ │   (Metrics)     │ │   (Logs)        │ │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Metrics Strategy

### 1. Application Metrics
```dart
class MetricsCollector {
  late final MeterProvider _meterProvider;
  late final Counter _requestCounter;
  late final Histogram _requestDuration;
  late final UpDownCounter _activeUsers;

  void initialize() {
    _meterProvider = MeterProviderBuilder()
        .addResource(Resource.getDefault().merge(Resource.builder()
            .putAttributes({
              'service.name': 'video-marketplace',
              'service.version': '1.0.0',
              'environment': Environment.current.name,
            }).build()))
        .build();

    _requestCounter = _meterProvider.createCounter(
      'http_requests_total',
      description: 'Total number of HTTP requests',
    );

    _requestDuration = _meterProvider.createHistogram(
      'http_request_duration_ms',
      description: 'HTTP request duration in milliseconds',
      unit: 'ms',
    );

    _activeUsers = _meterProvider.createUpDownCounter(
      'active_users',
      description: 'Number of currently active users',
    );
  }

  void recordRequest(String method, String path, int statusCode, Duration duration) {
    final attributes = <String, Object>{
      'http.method': method,
      'http.route': path,
      'http.status_code': statusCode,
      'status_category': _getStatusCategory(statusCode),
    };

    _requestCounter.add(1, attributes: attributes);
    _requestDuration.record(duration.inMilliseconds.toDouble(), attributes: attributes);
  }

  void incrementActiveUsers() {
    _activeUsers.add(1, attributes: {'status': 'active'});
  }

  void decrementActiveUsers() {
    _activeUsers.add(-1, attributes: {'status': 'active'});
  }

  String _getStatusCategory(int statusCode) {
    if (statusCode < 300) return 'success';
    if (statusCode < 400) return 'redirect';
    if (statusCode < 500) return 'client_error';
    return 'server_error';
  }
}
```

### 2. Business Metrics
```dart
class BusinessMetrics {
  late final Counter _auctionsCreated;
  late final Counter _bidsPlaced;
  late final Histogram _auctionFinalPrice;
  late final Counter _paymentsCompleted;
  late final Gauge _activeAuctions;

  void initialize() {
    final meterProvider = MeterProviderBuilder().build();

    _auctionsCreated = meterProvider.createCounter(
      'auctions_created_total',
      description: 'Total number of auctions created',
    );

    _bidsPlaced = meterProvider.createCounter(
      'bids_placed_total',
      description: 'Total number of bids placed',
    );

    _auctionFinalPrice = meterProvider.createHistogram(
      'auction_final_price',
      description: 'Final price of completed auctions',
      unit: 'usd',
    );

    _paymentsCompleted = meterProvider.createCounter(
      'payments_completed_total',
      description: 'Total number of completed payments',
    );

    _activeAuctions = meterProvider.createGauge(
      'active_auctions_count',
      description: 'Number of currently active auctions',
    );
  }

  void recordAuctionCreated(String category) {
    _auctionsCreated.add(1, attributes: {
      'category': category,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void recordBidPlaced(String auctionId, double amount) {
    _bidsPlaced.add(1, attributes: {
      'auction_id': auctionId,
      'amount_range': _getAmountRange(amount),
    });
  }

  void recordAuctionCompletion(double finalPrice) {
    _auctionFinalPrice.record(finalPrice, attributes: {
      'currency': 'USD',
      'completion_time': DateTime.now().toIso8601String(),
    });
  }

  void updateActiveAuctionsCount(int count) {
    _activeAuctions.record(count.toDouble());
  }

  String _getAmountRange(double amount) {
    if (amount < 50) return '0-50';
    if (amount < 100) return '50-100';
    if (amount < 500) return '100-500';
    if (amount < 1000) return '500-1000';
    return '1000+';
  }
}
```

### 3. Infrastructure Metrics
```yaml
# Prometheus Configuration
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'serverpod-app'
    static_configs:
      - targets: ['app:8080']
    metrics_path: '/metrics'
    scrape_interval: 10s

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'aws-cloudwatch'
    ec2_sd_configs:
      - region: us-east-1
        port: 9100
        filters:
          - name: 'tag:monitoring'
            values: ['enabled']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

## Logging Strategy

### 1. Structured Logging
```dart
class StructuredLogger {
  late final Logger _logger;
  late final Resource _resource;

  void initialize() {
    _resource = Resource.builder()
        .putAttributes({
          'service.name': 'video-marketplace',
          'service.version': '1.0.0',
          'environment': Environment.current.name,
        }).build();

    _logger = LoggerProvider(
      processors: [
        BatchSpanProcessor(ConsoleExporter()),
        BatchSpanProcessor(OtlpTraceExporter()),
      ],
      resource: _resource,
    ).getLogger('video-marketplace-logger');
  }

  void logInfo(String message, {Map<String, Object>? attributes}) {
    final event = LogEvent(
      timestamp: DateTime.now(),
      severity: TextSeverityKey.info,
      body: message,
      attributes: attributes ?? {},
    );

    _logger.emit(event);
  }

  void logError(String message, {Object? error, StackTrace? stackTrace, Map<String, Object>? attributes}) {
    final event = LogEvent(
      timestamp: DateTime.now(),
      severity: TextSeverityKey.error,
      body: message,
      attributes: {
        ...?attributes,
        if (error != null) 'error.type': error.runtimeType.toString(),
        if (error != null) 'error.message': error.toString(),
        if (stackTrace != null) 'stack_trace': stackTrace.toString(),
      },
    );

    _logger.emit(event);
  }

  void logSecurityEvent(SecurityEvent event) {
    final logEvent = LogEvent(
      timestamp: event.timestamp,
      severity: TextSeverityKey.warn,
      body: 'Security event: ${event.type}',
      attributes: {
        'security.event_type': event.type.name,
        'security.user_id': event.userId,
        'security.ip_address': event.ipAddress,
        'security.metadata': jsonEncode(event.metadata),
      },
    );

    _logger.emit(logEvent);
  }

  void logBusinessEvent(BusinessEvent event) {
    final logEvent = LogEvent(
      timestamp: event.timestamp,
      severity: TextSeverityKey.info,
      body: 'Business event: ${event.type}',
      attributes: {
        'business.event_type': event.type.name,
        'business.user_id': event.userId,
        'business.auction_id': event.auctionId,
        'business.amount': event.amount ?? 0,
        'business.metadata': jsonEncode(event.metadata),
      },
    );

    _logger.emit(logEvent);
  }
}
```

### 2. Log Correlation
```dart
class CorrelationService {
  static const String _correlationIdHeader = 'X-Correlation-ID';
  static const String _traceIdHeader = 'X-Trace-ID';

  String generateCorrelationId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_randomString(8)}';
  }

  Map<String, String> getCorrelationHeaders() {
    final correlationId = generateCorrelationId();
    final traceId = getCurrentTraceId();

    return {
      _correlationIdHeader: correlationId,
      _traceIdHeader: traceId,
    };
  }

  void setCorrelationContext(Map<String, String> headers) {
    final correlationId = headers[_correlationIdHeader];
    final traceId = headers[_traceIdHeader];

    if (correlationId != null) {
      Context.current().set(
        AttributeKey('correlation.id'),
        correlationId,
      );
    }

    if (traceId != null) {
      Context.current().set(
        AttributeKey('trace.id'),
        traceId,
      );
    }
  }

  String? getCurrentCorrelationId() {
    return Context.current().getAttribute(AttributeKey('correlation.id'));
  }

  String? getCurrentTraceId() {
    return Context.current().getAttribute(AttributeKey('trace.id'));
  }
}
```

## Distributed Tracing

### 1. Trace Configuration
```dart
class TracingService {
  late final TracerProvider _tracerProvider;
  late final Tracer _tracer;

  void initialize() {
    _tracerProvider = TracerProviderBuilder()
        .addResource(Resource.getDefault().merge(Resource.builder()
            .putAttributes({
              'service.name': 'video-marketplace',
              'service.version': '1.0.0',
              'environment': Environment.current.name,
            }).build()))
        .addOtlpExporter()
        .addJaegerExporter()
        .build();

    _tracer = _tracerProvider.getTracer('video-marketplace-tracer');
  }

  Span? startSpan(String name, {SpanKind kind = SpanKind.server}) {
    return _tracer.startSpan(name, kind: kind);
  }

  Future<T> traceAsync<T>(
    String name,
    Future<T> Function() operation, {
    SpanKind kind = SpanKind.server,
    Map<String, Object>? attributes,
  }) async {
    final span = startSpan(name, kind: kind);

    try {
      if (attributes != null) {
        attributes.forEach((key, value) {
          span?.setAttribute(key, value);
        });
      }

      final result = await operation();
      span?.setStatus(Status.ok());
      return result;
    } catch (error, stackTrace) {
      span?.recordError(error, stackTrace);
      span?.setStatus(Status.error(error.toString()));
      rethrow;
    } finally {
      span?.end();
    }
  }

  void traceSync<T>(
    String name,
    T Function() operation, {
    SpanKind kind = SpanKind.server,
    Map<String, Object>? attributes,
  }) {
    final span = startSpan(name, kind: kind);

    try {
      if (attributes != null) {
        attributes.forEach((key, value) {
          span?.setAttribute(key, value);
        });
      }

      final result = operation();
      span?.setStatus(Status.ok());
      return result;
    } catch (error, stackTrace) {
      span?.recordError(error, stackTrace);
      span?.setStatus(Status.error(error.toString()));
      rethrow;
    } finally {
      span?.end();
    }
  }
}
```

### 2. Trace Instrumentation
```dart
class InstrumentedAuctionService {
  final TracingService _tracing;
  final MetricsCollector _metrics;
  final StructuredLogger _logger;

  InstrumentedAuctionService(this._tracing, this._metrics, this._logger);

  Future<AuctionBid> placeBid(PlaceBidRequest request) async {
    return await _tracing.traceAsync('auction.place_bid', () async {
      final stopwatch = Stopwatch()..start();

      try {
        _logger.logInfo('Placing bid', attributes: {
          'auction_id': request.auctionId,
          'user_id': request.userId,
          'amount': request.amount,
        });

        final bid = await _placeBidInternal(request);

        _metrics.recordBidPlaced(request.auctionId, request.amount);
        _logger.logInfo('Bid placed successfully', attributes: {
          'bid_id': bid.id,
          'auction_id': request.auctionId,
          'amount': bid.amount,
        });

        return bid;
      } catch (error) {
        _metrics.recordBidError(request.auctionId, error);
        _logger.logError('Failed to place bid', error: error, attributes: {
          'auction_id': request.auctionId,
          'user_id': request.userId,
          'amount': request.amount,
        });
        rethrow;
      } finally {
        stopwatch.stop();
        _metrics.recordOperationDuration('place_bid', stopwatch.elapsed);
      }
    });
  }

  Future<Auction> getAuction(String auctionId) async {
    return await _tracing.traceAsync('auction.get_auction', () async {
      _logger.logInfo('Fetching auction', attributes: {
        'auction_id': auctionId,
      });

      try {
        final auction = await _getAuctionInternal(auctionId);

        _logger.logInfo('Auction fetched successfully', attributes: {
          'auction_id': auctionId,
          'auction_status': auction.status.name,
        });

        return auction;
      } catch (error) {
        _logger.logError('Failed to fetch auction', error: error, attributes: {
          'auction_id': auctionId,
        });
        rethrow;
      }
    });
  }
}
```

## Alerting Strategy

### 1. Alert Rules
```yaml
# alert_rules.yml
groups:
  - name: application.rules
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status_category="server_error"}[5m]) > 0.1
        for: 2m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} errors per second"

      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(http_request_duration_ms_bucket[5m])) > 1000
        for: 5m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "High latency detected"
          description: "95th percentile latency is {{ $value }}ms"

      - alert: LowActiveUsers
        expr: active_users < 10
        for: 10m
        labels:
          severity: warning
          team: product
        annotations:
          summary: "Low active users"
          description: "Only {{ $value }} active users detected"

  - name: business.rules
    rules:
      - alert: NoAuctionActivity
        expr: increase(auctions_created_total[1h]) == 0
        for: 2h
        labels:
          severity: warning
          team: product
        annotations:
          summary: "No auction activity"
          description: "No new auctions created in the last hour"

      - alert: PaymentFailureRate
        expr: rate(payments_completed_total{status="failed"}[5m]) / rate(payments_completed_total[5m]) > 0.1
        for: 5m
        labels:
          severity: critical
          team: payments
        annotations:
          summary: "High payment failure rate"
          description: "Payment failure rate is {{ $value | humanizePercentage }}"

  - name: infrastructure.rules
    rules:
      - alert: HighCPUUsage
        expr: cpu_usage_percent > 80
        for: 5m
        labels:
          severity: warning
          team: devops
        annotations:
          summary: "High CPU usage"
          description: "CPU usage is {{ $value }}%"

      - alert: LowDiskSpace
        expr: (disk_available_bytes / disk_total_bytes) * 100 < 10
        for: 5m
        labels:
          severity: critical
          team: devops
        annotations:
          summary: "Low disk space"
          description: "Disk space is {{ $value }}% available"
```

### 2. Alert Notification Configuration
```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alerts@example.com'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'
  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
    - match:
        severity: warning
      receiver: 'warning-alerts'
    - match:
        team: payments
      receiver: 'payment-team'

receivers:
  - name: 'default'
    email_configs:
      - to: 'devops@example.com'
        subject: '[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}

  - name: 'critical-alerts'
    email_configs:
      - to: 'oncall@example.com'
        subject: '[CRITICAL] {{ .GroupLabels.alertname }}'
    slack_configs:
      - api_url: 'https://hooks.slack.com/...'
        channel: '#alerts-critical'
        title: 'Critical Alert: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: 'warning-alerts'
    email_configs:
      - to: 'dev-team@example.com'
        subject: '[WARNING] {{ .GroupLabels.alertname }}'
    slack_configs:
      - api_url: 'https://hooks.slack.com/...'
        channel: '#alerts-warning'

  - name: 'payment-team'
    email_configs:
      - to: 'payments@example.com'
        subject: '[PAYMENT] {{ .GroupLabels.alertname }}'
```

## Dashboard Configuration

### 1. Application Performance Dashboard
```json
{
  "dashboard": {
    "title": "Application Performance",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{route}}"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "singlestat",
        "targets": [
          {
            "expr": "rate(http_requests_total{status_category=\"server_error\"}[5m]) / rate(http_requests_total[5m])"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.50, rate(http_request_duration_ms_bucket[5m]))",
            "legendFormat": "50th percentile"
          },
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_ms_bucket[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.99, rate(http_request_duration_ms_bucket[5m]))",
            "legendFormat": "99th percentile"
          }
        ]
      },
      {
        "title": "Active Users",
        "type": "singlestat",
        "targets": [
          {
            "expr": "active_users"
          }
        ]
      }
    ]
  }
}
```

### 2. Business Metrics Dashboard
```json
{
  "dashboard": {
    "title": "Business Metrics",
    "panels": [
      {
        "title": "Auctions Created",
        "type": "graph",
        "targets": [
          {
            "expr": "increase(auctions_created_total[1h])",
            "legendFormat": "Auctions per hour"
          }
        ]
      },
      {
        "title": "Bids Placed",
        "type": "graph",
        "targets": [
          {
            "expr": "increase(bids_placed_total[1h])",
            "legendFormat": "Bids per hour"
          }
        ]
      },
      {
        "title": "Active Auctions",
        "type": "singlestat",
        "targets": [
          {
            "expr": "active_auctions_count"
          }
        ]
      },
      {
        "title": "Payment Success Rate",
        "type": "singlestat",
        "targets": [
          {
            "expr": "rate(payments_completed_total{status=\"success\"}[5m]) / rate(payments_completed_total[5m])"
          }
        ]
      },
      {
        "title": "Average Auction Price",
        "type": "graph",
        "targets": [
          {
            "expr": "avg_over_time(auction_final_price[1h])",
            "legendFormat": "Average price (USD)"
          }
        ]
      }
    ]
  }
}
```

## Implementation Timeline

### Phase 1: Core Infrastructure (Week 1-2)
- [ ] OpenTelemetry SDK setup
- [ ] Prometheus and Grafana deployment
- [ ] Loki log aggregation setup
- [ ] Basic metrics collection

### Phase 2: Application Integration (Week 3-4)
- [ ] Serverpod tracing integration
- [ ] Flutter client metrics
- [ ] Structured logging implementation
- [ ] Business metrics setup

### Phase 3: Advanced Monitoring (Week 5-6)
- [ ] Alert rules configuration
- [ ] Dashboard development
- [ ] SLA monitoring setup
- [ ] Performance baseline establishment

### Phase 4: Optimization (Week 7-8)
- [ ] Metric optimization
- [ ] Alert tuning
- [ ] Automated incident response
- [ ] Monitoring documentation

## Success Metrics
- **Visibility**: 100% application coverage with traces
- **Alerting**: <5 minutes detection time for critical issues
- **Performance**: <1% overhead from monitoring
- **Reliability**: 99.9% monitoring system uptime
- **Usability**: Dashboard load time <2 seconds
- **Effectiveness**: 90% of issues detected before user impact

## Related ADRs
- ADR-0002: Flutter + Serverpod Architecture
- ADR-0005: AWS Infrastructure Strategy
- ADR-0009: Security Architecture

## References
- [OpenTelemetry Documentation](https://opentelemetry.io/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [Google SRE Book](https://sre.google/books/)

## Status Updates
- **2025-10-09**: Accepted - Observability strategy approved
- **2025-10-09**: Technology selection completed
- **TBD**: Core infrastructure deployment
- **TBD**: Application integration
- **TBD**: Advanced monitoring setup

---

*This ADR establishes a comprehensive observability strategy that provides end-to-end visibility across all system components, enabling proactive issue detection and optimal performance management.*