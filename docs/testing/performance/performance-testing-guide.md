# Performance Testing Guide

## Overview

This guide outlines the comprehensive performance testing strategy for the Craft Video Marketplace, ensuring we meet all NFR performance requirements from the PRD.

## Performance Requirements (from PRD)

### Mobile App Performance Targets
- **App cold start**: p50 ≤ 2.5s, p90 ≤ 5s
- **Time to First Frame (TTFF)**: p50 ≤ 1.2s
- **Feed scrolling**: 60fps with ≤2% jank
- **Offer UI optimistic updates**: ≤100ms
- **Timer updates**: Applied within ≤60s

### Backend Performance Targets
- **API response times**: p95 < 500ms
- **Database queries**: p95 < 100ms
- **Video processing**: Complete within 5 minutes
- **Upload speeds**: ≥10Mbps for standard quality

## Performance Testing Framework

### 1. Mobile Performance Testing

#### Flutter Performance Tests

```dart
// test/performance/mobile_performance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Performance Tests', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('App startup performance', () async {
      // Measure cold start time
      final stopwatch = Stopwatch()..start();

      await driver.waitFor(find.byType('MaterialApp'));

      stopwatch.stop();
      final startupTime = stopwatch.elapsedMilliseconds;

      print('App startup time: ${startupTime}ms');

      // PRD requirement: p50 ≤ 2.5s, p90 ≤ 5s
      expect(startupTime, lessThan(5000), reason: 'App should start within 5 seconds');
    });

    test('Feed scrolling performance', () async {
      // Test feed scrolling at 60fps
      await driver.tap(find.byValueKey('feed_tab'));

      final timeline = await driver.traceAction(() async {
        // Scroll through 20 feed items
        for (int i = 0; i < 20; i++) {
          await driver.scroll(
            find.byValueKey('feed_list'),
            0, -300, Duration(milliseconds: 300)
          );
          await Future.delayed(Duration(milliseconds: 100));
        }
      });

      // Analyze frame rate
      final frameRate = _calculateFrameRate(timeline);
      print('Feed scrolling frame rate: ${frameRate.toStringAsFixed(1)}fps');

      // PRD requirement: 60fps with ≤2% jank
      expect(frameRate, greaterThan(58), reason: 'Feed should scroll at 60fps');
    });

    test('Story page load performance', () async {
      // Test story page loading
      await driver.tap(find.byValueKey('first_story_item'));

      final stopwatch = Stopwatch()..start();

      await driver.waitFor(find.byValueKey('story_video_player'));

      stopwatch.stop();
      final loadTime = stopwatch.elapsedMilliseconds;

      print('Story page load time: ${loadTime}ms');
      expect(loadTime, lessThan(2000), reason: 'Story should load within 2 seconds');
    });

    test('Offer submission response time', () async {
      // Test offer submission UI responsiveness
      await driver.tap(find.byValueKey('offer_button'));

      final stopwatch = Stopwatch()..start();

      await driver.tap(find.byValueKey('submit_offer_button'));
      await driver.waitFor(find.byValueKey('offer_confirmation'));

      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;

      print('Offer submission response time: ${responseTime}ms');

      // PRD requirement: ≤100ms for optimistic updates
      expect(responseTime, lessThan(200), reason: 'Offer UI should update optimistically');
    });
  });
}

double _calculateFrameRate(Timeline timeline) {
  final frames = timeline.frames.length;
  final duration = timeline.endTime.inMilliseconds - timeline.startTime.inMilliseconds;
  return (frames * 1000) / duration;
}
```

#### Memory Usage Tests

```dart
// test/performance/memory_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('Memory Usage Tests', () {
    testWidgets('Memory usage within limits', (WidgetTester tester) async {
      // Build app
      await tester.pumpWidget(MyApp());

      // Navigate through app features
      await _simulateUserJourney(tester);

      // Check memory usage
      final memoryInfo = await _getMemoryUsage();

      print('Memory usage: ${memoryInfo.totalMB}MB');
      print('Memory limit: 200MB');

      // Should not exceed 200MB for mobile app
      expect(memoryInfo.totalMB, lessThan(200),
             reason: 'Memory usage should stay within mobile limits');
    });
  });
}

Future<void> _simulateUserJourney(WidgetTester tester) async {
  // Scroll through feed
  await tester.drag(find.byType('ListView'), Offset(0, -500));
  await tester.pumpAndSettle();

  // Open story
  await tester.tap(find.byType('StoryCard').first);
  await tester.pumpAndSettle();

  // Submit offer
  await tester.tap(find.byType('OfferButton'));
  await tester.pumpAndSettle();
}

Future<MemoryInfo> _getMemoryUsage() async {
  // Implementation depends on platform
  // Use device_info_plus or similar package
  return MemoryInfo(totalMB: 150, usedMB: 120);
}

class MemoryInfo {
  final double totalMB;
  final double usedMB;

  MemoryInfo({required this.totalMB, required this.usedMB});
}
```

### 2. Backend Performance Testing

#### API Load Tests

```dart
// test/performance/api_load_test.dart
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('API Performance Tests', () {
    const String baseUrl = 'https://api.craftmarketplace.com';

    test('Feed endpoint performance', () async {
      final stopwatch = Stopwatch()..start();

      final response = await http.get(
        Uri.parse('$baseUrl/feed'),
        headers: {'Authorization': 'Bearer test_token'},
      );

      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;

      print('Feed endpoint response time: ${responseTime}ms');

      expect(response.statusCode, equals(200));
      expect(responseTime, lessThan(500),
             reason: 'API should respond within 500ms');
    });

    test('Concurrent user load test', () async {
      const int concurrentUsers = 100;
      const int requestsPerUser = 10;

      final futures = <Future>[];

      for (int user = 0; user < concurrentUsers; user++) {
        futures.add(_simulateUserBehavior(requestsPerUser));
      }

      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();

      final totalTime = stopwatch.elapsedMilliseconds;
      final totalRequests = concurrentUsers * requestsPerUser;
      final avgResponseTime = totalTime / totalRequests;

      print('Concurrent load test:');
      print('- Users: $concurrentUsers');
      print('- Total requests: $totalRequests');
      print('- Average response time: ${avgResponseTime.toStringAsFixed(1)}ms');

      expect(avgResponseTime, lessThan(1000),
             reason: 'System should handle concurrent load');
    });
  });
}

Future<void> _simulateUserBehavior(int requestCount) async {
  for (int i = 0; i < requestCount; i++) {
    await http.get(Uri.parse('https://api.craftmarketplace.com/feed'));
    await Future.delayed(Duration(milliseconds: 100));
  }
}
```

#### Database Performance Tests

```dart
// test/performance/database_performance_test.dart
import 'package:test/test.dart';
import 'package:serverpod/database.dart';

void main() {
  group('Database Performance Tests', () {
    late Database database;

    setUp(() async {
      database = await Database.connect(
        host: 'localhost',
        port: 5432,
        database: 'craft_marketplace_test',
        user: 'test_user',
        password: 'test_password',
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('Query performance under load', () async {
      const int queryCount = 1000;

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < queryCount; i++) {
        await database.query(
          'SELECT * FROM stories WHERE id = @id',
          parameters: {'id': i % 100 + 1},
        );
      }

      stopwatch.stop();

      final totalTime = stopwatch.elapsedMilliseconds;
      final avgQueryTime = totalTime / queryCount;

      print('Database performance:');
      print('- Total queries: $queryCount');
      print('- Average query time: ${avgQueryTime.toStringAsFixed(2)}ms');

      expect(avgQueryTime, lessThan(100),
             reason: 'Database queries should complete within 100ms');
    });

    test('Index effectiveness test', () async {
      // Test query with and without index
      final queryWithoutIndex = '''
        SELECT * FROM stories
        WHERE maker_id = @makerId
        AND created_at > @date
        ORDER BY created_at DESC
        LIMIT 20
      ''';

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        await database.query(queryWithoutIndex, parameters: {
          'makerId': i % 10 + 1,
          'date': DateTime.now().subtract(Duration(days: 30)),
        });
      }

      stopwatch.stop();

      final totalTime = stopwatch.elapsedMilliseconds;
      final avgQueryTime = totalTime / 100;

      print('Indexed query performance: ${avgQueryTime.toStringAsFixed(2)}ms');

      expect(avgQueryTime, lessThan(50),
             reason: 'Indexed queries should be very fast');
    });
  });
}
```

### 3. Video Performance Testing

#### Streaming Performance Tests

```dart
// test/performance/video_streaming_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

void main() {
  group('Video Streaming Performance Tests', () {
    testWidgets('Video startup time', (WidgetTester tester) async {
      await tester.pumpWidget(VideoTestApp());

      final stopwatch = Stopwatch()..start();

      // Start video playback
      await tester.tap(find.byType(VideoPlayer));
      await tester.pumpAndSettle();

      stopwatch.stop();
      final startupTime = stopwatch.elapsedMilliseconds;

      print('Video startup time: ${startupTime}ms');

      // Video should start within 2 seconds
      expect(startupTime, lessThan(2000),
             reason: 'Video should start quickly');
    });

    testWidgets('Video frame rate consistency', (WidgetTester tester) async {
      await tester.pumpWidget(VideoTestApp());

      await tester.tap(find.byType(VideoPlayer));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Monitor frame rate during playback
      final frameRates = await _collectFrameRates();

      print('Video frame rates: $frameRates');

      // Should maintain 30fps or better
      expect(frameRates.average, greaterThan(28),
             reason: 'Video should maintain smooth playback');
    });
  });
}

class VideoTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: VideoPlayer(
          VideoPlayerController.network(
            'https://cdn.craftmarketplace.com/test-video.mp4'
          )..initialize(),
        ),
      ),
    );
  }
}

Future<List<double>> _collectFrameRates() async {
  // Implementation would collect frame rates during video playback
  return [30.0, 29.8, 30.2, 29.9, 30.1];
}
```

### 4. Integration Performance Tests

#### End-to-End Performance Tests

```dart
// test/performance/e2e_performance_test.dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('End-to-End Performance Tests', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('Complete user journey performance', () async {
      final journey = UserJourney(driver);

      await journey.runCompleteJourney();

      final metrics = journey.getMetrics();

      print('Complete journey metrics:');
      print('- Total time: ${metrics.totalTime.inSeconds}s');
      print('- App start: ${metrics.appStart.inMilliseconds}ms');
      print('- Feed load: ${metrics.feedLoad.inMilliseconds}ms');
      print('- Story view: ${metrics.storyView.inMilliseconds}ms');
      print('- Offer submit: ${metrics.offerSubmit.inMilliseconds}ms');

      // Validate performance against PRD requirements
      expect(metrics.appStart.inMilliseconds, lessThan(5000));
      expect(metrics.feedLoad.inMilliseconds, lessThan(2000));
      expect(metrics.offerSubmit.inMilliseconds, lessThan(200));
    });
  });
}

class UserJourney {
  final FlutterDriver driver;
  final JourneyMetrics metrics = JourneyMetrics();

  UserJourney(this.driver);

  Future<void> runCompleteJourney() async {
    // App startup
    final appStartTimer = Stopwatch()..start();
    await driver.waitFor(find.byType('MaterialApp'));
    appStartTimer.stop();
    metrics.appStart = appStartTimer.elapsed;

    // Feed loading
    final feedTimer = Stopwatch()..start();
    await driver.tap(find.byValueKey('feed_tab'));
    await driver.waitFor(find.byValueKey('feed_loaded'));
    feedTimer.stop();
    metrics.feedLoad = feedTimer.elapsed;

    // Story viewing
    final storyTimer = Stopwatch()..start();
    await driver.tap(find.byValueKey('first_story'));
    await driver.waitFor(find.byValueKey('story_video_ready'));
    storyTimer.stop();
    metrics.storyView = storyTimer.elapsed;

    // Offer submission
    final offerTimer = Stopwatch()..start();
    await driver.tap(find.byValueKey('offer_button'));
    await driver.enterText('100', find.byValueKey('offer_amount'));
    await driver.tap(find.byValueKey('submit_offer'));
    await driver.waitFor(find.byValueKey('offer_confirmation'));
    offerTimer.stop();
    metrics.offerSubmit = offerTimer.elapsed;

    metrics.totalTime = Duration(
      milliseconds: metrics.appStart.inMilliseconds +
                    metrics.feedLoad.inMilliseconds +
                    metrics.storyView.inMilliseconds +
                    metrics.offerSubmit.inMilliseconds,
    );
  }

  JourneyMetrics getMetrics() => metrics;
}

class JourneyMetrics {
  Duration appStart = Duration.zero;
  Duration feedLoad = Duration.zero;
  Duration storyView = Duration.zero;
  Duration offerSubmit = Duration.zero;
  Duration totalTime = Duration.zero;
}
```

## Performance Monitoring

### 1. Real-Time Monitoring

#### Flutter Performance Monitoring

```dart
// lib/core/monitoring/performance_monitor.dart
import 'dart:developer' as developer;

class PerformanceMonitor {
  static void startTimer(String operation) {
    developer.log('PERF_START: $operation', name: 'performance');
  }

  static void endTimer(String operation) {
    developer.log('PERF_END: $operation', name: 'performance');
  }

  static void logMetric(String name, dynamic value) {
    developer.log('PERF_METRIC: $name=$value', name: 'performance');
  }

  static void monitorMemoryUsage() {
    final memoryInfo = _getCurrentMemoryUsage();
    logMetric('memory_usage_mb', memoryInfo.usedMB);

    if (memoryInfo.usedMB > 150) {
      developer.log('WARNING: High memory usage detected', name: 'performance');
    }
  }

  static void monitorFrameRate() {
    // Implement frame rate monitoring
    // This would require integration with Flutter's frame callbacks
  }
}

// Usage example:
class FeedWidget extends StatefulWidget {
  @override
  _FeedWidgetState createState() => _FeedWidgetState();
}

class _FeedWidgetState extends State<FeedWidget> {
  @override
  void initState() {
    super.initState();
    PerformanceMonitor.startTimer('feed_widget_init');
    _loadFeedData().then((_) {
      PerformanceMonitor.endTimer('feed_widget_init');
    });
  }

  Future<void> _loadFeedData() async {
    // Load feed data
    PerformanceMonitor.logMetric('feed_items_loaded', 20);
  }
}
```

#### Serverpod Performance Monitoring

```dart
// packages/serverpod_backend/src/monitoring/performance_middleware.dart
class PerformanceMiddleware {
  @override
  Future<void> request(Session session, HttpRequest request) async {
    final stopwatch = Stopwatch()..start();

    // Process request
    await super.request(session, request);

    stopwatch.stop();

    final endpoint = request.uri.path;
    final responseTime = stopwatch.elapsedMilliseconds;

    // Log performance metrics
    session.log(
      'API_PERFORMANCE: endpoint=$endpoint, response_time=${responseTime}ms',
      level: LogLevel.info,
    );

    // Alert on slow responses
    if (responseTime > 500) {
      session.log(
        'WARNING: Slow endpoint detected: $endpoint (${responseTime}ms)',
        level: LogLevel.warning,
      );
    }

    // Send to monitoring service
    await _sendMetricsToMonitoringService(endpoint, responseTime);
  }

  Future<void> _sendMetricsToMonitoringService(String endpoint, int responseTime) async {
    // Send to Prometheus, DataDog, or similar
  }
}
```

### 2. Performance Alerts

#### Alert Configuration

```yaml
# monitoring/performance-alerts.yml
alerts:
  - name: "High API Response Time"
    condition: "api_response_time_p95 > 1000ms"
    severity: "warning"
    action: "notify_dev_team"

  - name: "Low App Performance"
    condition: "app_start_time_p90 > 5s"
    severity: "critical"
    action: "page_oncall"

  - name: "Memory Usage High"
    condition: "memory_usage_mb > 200"
    severity: "warning"
    action: "notify_dev_team"

  - name: "Video Streaming Issues"
    condition: "video_startup_time_p90 > 3s"
    severity: "critical"
    action: "page_oncall"

  - name: "Database Slow Queries"
    condition: "db_query_time_p95 > 200ms"
    severity: "warning"
    action: "notify_db_team"
```

## Performance Testing CI/CD Integration

### GitHub Actions Performance Test

```yaml
# .github/workflows/performance-tests.yml
name: Performance Tests

on:
  pull_request:
    branches: [ develop ]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

jobs:
  mobile-performance:
    runs-on: macos-latest
    timeout-minutes: 30

    steps:
    - uses: actions/checkout@v4

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.1'

    - name: Run mobile performance tests
      run: |
        cd video_window/packages/mobile_client
        flutter test test/performance/ --performance

    - name: Upload performance results
      uses: actions/upload-artifact@v3
      with:
        name: mobile-performance-results
        path: performance-reports/

  backend-performance:
    runs-on: ubuntu-latest
    timeout-minutes: 20

    steps:
    - uses: actions/checkout@v4

    - name: Setup Dart
      uses: dart-lang/setup-dart@v1

    - name: Run backend performance tests
      run: |
        cd video_window/packages/serverpod_backend
        dart test test/performance/

    - name: Compare with baseline
      run: |
        # Compare performance with previous results
        python scripts/compare_performance.py

  performance-regression:
    runs-on: ubuntu-latest
    needs: [mobile-performance, backend-performance]

    steps:
    - name: Check for performance regression
      run: |
        # Fail build if performance degraded by >10%
        python scripts/check_performance_regression.py
```

## Performance Testing Best Practices

### 1. Test Environment Setup
- Use dedicated performance testing environment
- Ensure consistent hardware/software configuration
- Monitor system resources during tests
- Use realistic data volumes and user loads

### 2. Test Data Management
- Use anonymized production-like data
- Ensure test data is representative of real usage
- Clean up test data after each run
- Version control test datasets

### 3. Result Analysis
- Track performance trends over time
- Set up automated regression detection
- Correlate performance with code changes
- Document performance baselines and targets

### 4. Continuous Improvement
- Regular performance testing in CI/CD
- Performance budgets for new features
- Regular performance optimization sprints
- Monitor real-world performance in production

This comprehensive performance testing framework ensures the Craft Video Marketplace meets all performance requirements and provides excellent user experience across all features.