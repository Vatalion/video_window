# Epic 03: Observability & Compliance Baseline - Technical Specification

**Epic Goal:** Establish logging, monitoring, compliance, and operational excellence foundations to enable production-ready deployments with proper observability and regulatory compliance.

**Stories:**
- 03.1: Logging & Metrics Implementation
- 03.2: Privacy & Legal Disclosures
- 03.3: Data Retention & Backup Procedures

---

## Architecture Overview

### Component Mapping
- **Logging:** Structured logging with OpenTelemetry
- **Metrics:** Prometheus + CloudWatch integration
- **Privacy:** GDPR/CCPA compliance framework
- **Data Retention:** Automated backup and retention policies
- **Compliance:** Legal disclosure management

### Technology Stack
- **Logging:** OpenTelemetry + CloudWatch Logs
- **Metrics:** Prometheus + Grafana + CloudWatch Metrics
- **Tracing:** OpenTelemetry distributed tracing
- **Privacy:** Custom compliance framework
- **Backups:** AWS Backup + PostgreSQL Point-in-Time Recovery
- **Monitoring:** Grafana dashboards + alerting

---

## Logging Architecture

### Structured Logging Implementation

**File:** `video_window_server/lib/src/services/logger.dart`

```dart
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class Logger {
  final String serviceName;
  final String version;
  final Environment environment;
  
  Logger({
    required this.serviceName,
    required this.version,
    required this.environment,
  });
  
  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    Exception? error,
    StackTrace? stackTrace,
  }) {
    final logEntry = {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': level.name.toUpperCase(),
      'service': serviceName,
      'version': version,
      'environment': environment.name,
      'message': message,
      if (context != null) 'context': context,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stack_trace': stackTrace.toString(),
    };
    
    // Send to CloudWatch Logs
    _sendToCloudWatch(logEntry);
    
    // Console output in development
    if (environment == Environment.development) {
      print(json.encode(logEntry));
    }
  }
  
  void debug(String message, {Map<String, dynamic>? context}) {
    log(LogLevel.debug, message, context: context);
  }
  
  void info(String message, {Map<String, dynamic>? context}) {
    log(LogLevel.info, message, context: context);
  }
  
  void warning(String message, {Map<String, dynamic>? context}) {
    log(LogLevel.warning, message, context: context);
  }
  
  void error(
    String message, {
    Exception? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }
  
  void critical(
    String message, {
    Exception? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    log(
      LogLevel.critical,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
    
    // Trigger immediate alert for critical logs
    _triggerAlert(message, error, context);
  }
  
  Future<void> _sendToCloudWatch(Map<String, dynamic> logEntry) async {
    // TODO: Implement CloudWatch Logs SDK integration
  }
  
  Future<void> _triggerAlert(
    String message,
    Exception? error,
    Map<String, dynamic>? context,
  ) async {
    // TODO: Implement SNS alert integration
  }
}
```

### Metrics Collection

**File:** `video_window_server/lib/src/services/metrics.dart`

```dart
class MetricsService {
  static final MetricsService _instance = MetricsService._internal();
  factory MetricsService() => _instance;
  MetricsService._internal();
  
  final Map<String, int> _counters = {};
  final Map<String, double> _gauges = {};
  final Map<String, List<double>> _histograms = {};
  
  // Counter metrics
  void incrementCounter(String name, {int value = 1, Map<String, String>? labels}) {
    final key = _buildKey(name, labels);
    _counters[key] = (_counters[key] ?? 0) + value;
  }
  
  // Gauge metrics
  void setGauge(String name, double value, {Map<String, String>? labels}) {
    final key = _buildKey(name, labels);
    _gauges[key] = value;
  }
  
  // Histogram metrics
  void recordHistogram(String name, double value, {Map<String, String>? labels}) {
    final key = _buildKey(name, labels);
    _histograms[key] = _histograms[key] ?? [];
    _histograms[key]!.add(value);
  }
  
  // Timer utility
  Future<T> measureTime<T>(
    String metricName,
    Future<T> Function() function, {
    Map<String, String>? labels,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await function();
    } finally {
      recordHistogram(
        metricName,
        stopwatch.elapsedMilliseconds.toDouble(),
        labels: labels,
      );
    }
  }
  
  String _buildKey(String name, Map<String, String>? labels) {
    if (labels == null || labels.isEmpty) return name;
    final labelStr = labels.entries.map((e) => '${e.key}="${e.value}"').join(',');
    return '$name{$labelStr}';
  }
  
  // Export metrics in Prometheus format
  String exportPrometheusMetrics() {
    final buffer = StringBuffer();
    
    // Counters
    _counters.forEach((key, value) {
      buffer.writeln('$key $value');
    });
    
    // Gauges
    _gauges.forEach((key, value) {
      buffer.writeln('$key $value');
    });
    
    // Histograms (simplified)
    _histograms.forEach((key, values) {
      if (values.isNotEmpty) {
        final sum = values.reduce((a, b) => a + b);
        final count = values.length;
        buffer.writeln('${key}_sum $sum');
        buffer.writeln('${key}_count $count');
      }
    });
    
    return buffer.toString();
  }
}

// Common metrics
class AppMetrics {
  static final metrics = MetricsService();
  
  // HTTP metrics
  static void recordHttpRequest(String method, String path, int statusCode, double durationMs) {
    metrics.incrementCounter(
      'http_requests_total',
      labels: {
        'method': method,
        'path': path,
        'status': statusCode.toString(),
      },
    );
    metrics.recordHistogram(
      'http_request_duration_ms',
      durationMs,
      labels: {'method': method, 'path': path},
    );
  }
  
  // Database metrics
  static void recordDbQuery(String operation, String table, double durationMs) {
    metrics.incrementCounter(
      'db_queries_total',
      labels: {'operation': operation, 'table': table},
    );
    metrics.recordHistogram(
      'db_query_duration_ms',
      durationMs,
      labels: {'operation': operation, 'table': table},
    );
  }
  
  // Business metrics
  static void recordUserSignIn(String provider) {
    metrics.incrementCounter(
      'user_sign_ins_total',
      labels: {'provider': provider},
    );
  }
  
  static void recordAuctionCreated() {
    metrics.incrementCounter('auctions_created_total');
  }
  
  static void recordPaymentProcessed(String status, double amount) {
    metrics.incrementCounter(
      'payments_total',
      labels: {'status': status},
    );
    metrics.recordHistogram('payment_amount_usd', amount);
  }
}
```

---

## Privacy & Compliance Framework

### GDPR/CCPA Compliance

**File:** `video_window_server/lib/src/services/privacy_service.dart`

```dart
enum DataCategory {
  personal,        // PII data
  behavioral,      // Usage analytics
  financial,       // Payment information
  content,         // User-generated content
  technical,       // System logs
}

enum ProcessingPurpose {
  serviceDelivery,
  analytics,
  marketing,
  legal,
  security,
}

class PrivacyService {
  // Data Subject Access Request (DSAR)
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    return {
      'user_profile': await _exportUserProfile(userId),
      'content': await _exportUserContent(userId),
      'transactions': await _exportTransactions(userId),
      'analytics': await _exportAnalytics(userId),
      'exported_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
  
  // Right to be Forgotten
  Future<void> deleteUserData(String userId) async {
    // Anonymize instead of delete where legally required
    await _anonymizeUserData(userId);
    await _deleteNonEssentialData(userId);
    await _logDeletionRequest(userId);
  }
  
  // Consent Management
  Future<void> updateConsent(
    String userId,
    Map<ProcessingPurpose, bool> consents,
  ) async {
    await _storeConsent(userId, consents);
    await _applyConsentChanges(userId, consents);
  }
  
  // Data Retention
  Future<void> applyRetentionPolicies() async {
    // Automatically delete data past retention period
    await _deleteExpiredSessions();
    await _deleteOldLogs();
    await _archiveInactiveAccounts();
  }
  
  Future<Map<String, dynamic>> _exportUserProfile(String userId) async {
    // TODO: Query user data
    return {};
  }
  
  Future<List<Map<String, dynamic>>> _exportUserContent(String userId) async {
    // TODO: Query user content
    return [];
  }
  
  Future<List<Map<String, dynamic>>> _exportTransactions(String userId) async {
    // TODO: Query transactions
    return [];
  }
  
  Future<Map<String, dynamic>> _exportAnalytics(String userId) async {
    // TODO: Query analytics
    return {};
  }
  
  Future<void> _anonymizeUserData(String userId) async {
    // TODO: Anonymize PII
  }
  
  Future<void> _deleteNonEssentialData(String userId) async {
    // TODO: Delete non-essential data
  }
  
  Future<void> _logDeletionRequest(String userId) async {
    // TODO: Log for audit trail
  }
  
  Future<void> _storeConsent(
    String userId,
    Map<ProcessingPurpose, bool> consents,
  ) async {
    // TODO: Store consent records
  }
  
  Future<void> _applyConsentChanges(
    String userId,
    Map<ProcessingPurpose, bool> consents,
  ) async {
    // TODO: Update data processing based on consent
  }
  
  Future<void> _deleteExpiredSessions() async {
    // Delete sessions older than 90 days
  }
  
  Future<void> _deleteOldLogs() async {
    // Delete logs older than retention period
  }
  
  Future<void> _archiveInactiveAccounts() async {
    // Archive accounts inactive for 2+ years
  }
}
```

### Legal Disclosure Management

**File:** `video_window_flutter/lib/app_shell/legal_disclosures.dart`

```dart
class LegalDisclosures {
  static const privacyPolicyVersion = '1.0.0';
  static const termsOfServiceVersion = '1.0.0';
  static const cookiePolicyVersion = '1.0.0';
  static const lastUpdated = '2025-11-03';
  
  static const privacyPolicyUrl = 'https://craftvideomarketplace.com/privacy';
  static const termsOfServiceUrl = 'https://craftvideomarketplace.com/terms';
  static const cookiePolicyUrl = 'https://craftvideomarketplace.com/cookies';
  
  // Required disclosures for EU users
  static const gdprDisclosures = {
    'data_controller': 'Craft Video Marketplace, Inc.',
    'dpo_email': 'dpo@craftvideomarketplace.com',
    'legal_basis': 'Consent and legitimate interest',
    'data_retention': '2 years from last activity',
    'user_rights': [
      'Right to access',
      'Right to rectification',
      'Right to erasure',
      'Right to data portability',
      'Right to object',
    ],
  };
  
  // Required disclosures for California users
  static const ccpaDisclosures = {
    'business_name': 'Craft Video Marketplace, Inc.',
    'categories_collected': [
      'Identifiers',
      'Commercial information',
      'Internet activity',
      'Geolocation data',
    ],
    'sale_of_data': false,
    'opt_out_available': true,
  };
  
  static Future<bool> requiresConsentPrompt(String userId) async {
    // Check if user has accepted latest terms
    return false; // TODO: Implement
  }
  
  static Future<void> recordConsentAcceptance(String userId) async {
    // Store consent record with timestamp and version
    // TODO: Implement
  }
}
```

---

## Data Retention & Backup

### Backup Configuration

**Infrastructure:** AWS Backup + PostgreSQL PITR

```yaml
# backup_policy.yaml
retention_rules:
  database:
    point_in_time_recovery: 7_days
    automated_snapshots:
      frequency: daily
      retention: 30_days
      
  logs:
    retention: 90_days
    
  user_content:
    active_retention: indefinite
    inactive_retention: 2_years
    
  analytics_events:
    hot_storage: 90_days
    cold_storage: 2_years
    deletion_after: 2_years
    
  financial_records:
    retention: 7_years  # Legal requirement
    
  session_data:
    retention: 90_days
```

### Backup Procedures

**File:** `scripts/backup.sh`

```bash
#!/bin/bash

# Database backup
pg_dump -h $DB_HOST -U $DB_USER -d video_window_prod > backup_$(date +%Y%m%d).sql
aws s3 cp backup_$(date +%Y%m%d).sql s3://video-window-backups/database/

# Verify backup
aws s3 ls s3://video-window-backups/database/backup_$(date +%Y%m%d).sql

# Cleanup local backup
rm backup_$(date +%Y%m%d).sql

# Test restore (staging environment)
# pg_restore -h $STAGING_DB_HOST -U $DB_USER -d video_window_staging backup.sql
```

---

## Monitoring Dashboards

### Grafana Dashboard Configuration

```json
{
  "dashboard": {
    "title": "Video Window - System Health",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{path}}"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m])",
            "legendFormat": "{{path}}"
          }
        ]
      },
      {
        "title": "Database Query Duration",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(db_query_duration_ms[5m]))",
            "legendFormat": "p95 {{operation}}"
          }
        ]
      },
      {
        "title": "Active Users",
        "targets": [
          {
            "expr": "count(active_sessions)",
            "legendFormat": "Active Sessions"
          }
        ]
      }
    ]
  }
}
```

---

## Alert Configuration

### Critical Alerts

```yaml
# alerting_rules.yaml
groups:
  - name: critical_alerts
    interval: 1m
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          
      - alert: DatabaseDown
        expr: up{job="postgres"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Database is down"
          
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_ms[5m])) > 1000
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "95th percentile response time > 1s"
```

---

## Success Criteria

Epic 03 is considered complete when:

- ✅ Structured logging implemented across all services
- ✅ Metrics collection for HTTP, database, and business events
- ✅ Prometheus/Grafana dashboards configured
- ✅ Privacy compliance framework implemented
- ✅ GDPR/CCPA disclosure management
- ✅ Data retention policies documented and automated
- ✅ Backup procedures tested and validated
- ✅ Alert rules configured for critical failures
- ✅ CloudWatch integration functional
- ✅ Legal disclosure versions tracked

---

**Document Version:** 1.0  
**Last Updated:** 2025-11-03  
**Status:** APPROVED  
**Approved By:** Winston (Architect), Murat (Test Lead), John (PM)  
**Approval Date:** 2025-11-03
