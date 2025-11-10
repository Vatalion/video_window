import 'package:serverpod/serverpod.dart';
import 'package:redis/redis.dart';

/// Multi-layer rate limiting service using Redis
/// Implements SEC-001 requirements for OTP request protection
class RateLimitService {
  final Session session;
  RedisConnection? _redisConn;
  Command? _redis;

  RateLimitService(this.session);

  /// Initialize Redis connection from Serverpod configuration
  Future<void> _initRedis() async {
    if (_redis != null) return; // Already initialized

    try {
      // Use configuration from development.yaml
      // TODO: Make this configurable via environment variables or config file
      final host = 'localhost';
      final port = 8091; // Development Redis port

      _redisConn = RedisConnection();
      _redis = await _redisConn!.connect(host, port);

      // Authenticate with password
      // TODO: Get password from Serverpod config properly
      // For now, try AUTH with known password, fail gracefully if not needed
      try {
        // Try authenticating with development password
        await _redis!.send_object(['AUTH', 'JLLDNS1puOSFsmtR7AePtBQt9huXBltb']);
      } catch (e) {
        // AUTH command may fail if Redis doesn't require password or wrong password
        // Log and continue - connection might still work without AUTH
        session.log(
          'Redis AUTH command result: $e',
          level: LogLevel.debug,
        );
      }
    } catch (e) {
      session.log(
        'Failed to connect to Redis: $e',
        level: LogLevel.error,
        exception: e,
      );
      // Fail open - allow requests if Redis is unavailable
      _redis = null;
    }
  }

  /// Rate limit configuration for per-identifier limits
  static const List<RateLimitRule> identifierRules = [
    RateLimitRule(
      requests: 3,
      windowSeconds: 300, // 5 minutes
      blockDurationSeconds: 900, // 15 minutes
    ),
    RateLimitRule(
      requests: 5,
      windowSeconds: 3600, // 1 hour
      blockDurationSeconds: 3600, // 1 hour
    ),
    RateLimitRule(
      requests: 10,
      windowSeconds: 86400, // 24 hours
      blockDurationSeconds: 86400, // 24 hours
    ),
  ];

  /// Rate limit configuration for per-IP limits
  static const List<RateLimitRule> ipRules = [
    RateLimitRule(
      requests: 20,
      windowSeconds: 300, // 5 minutes
      blockDurationSeconds: 300, // 5 minutes
    ),
    RateLimitRule(
      requests: 100,
      windowSeconds: 3600, // 1 hour
      blockDurationSeconds: 900, // 15 minutes
    ),
  ];

  /// Global rate limit configuration
  static const RateLimitRule globalRule = RateLimitRule(
    requests: 1000,
    windowSeconds: 60, // 1 minute
    blockDurationSeconds: 60, // 1 minute
  );

  /// Check if a request from identifier and IP should be allowed
  /// Returns RateLimitResult with allow/deny and metadata
  Future<RateLimitResult> checkRateLimit({
    required String identifier,
    required String ipAddress,
    required String action,
  }) async {
    try {
      await _initRedis();

      // If Redis is unavailable, fail open (allow request)
      if (_redis == null) {
        return RateLimitResult.allowed(
          remaining: 999,
          resetAt: DateTime.now().add(Duration(seconds: 60)),
        );
      }

      // Layer 1: Per-identifier rate limiting
      final identifierResult = await _checkLayerRateLimits(
        key: 'ratelimit:identifier:$action:${identifier.toLowerCase()}',
        rules: identifierRules,
        label: 'identifier',
      );

      if (!identifierResult.allowed) {
        session.log(
          'Rate limit exceeded for identifier: $identifier (action: $action)',
          level: LogLevel.warning,
        );
        return identifierResult;
      }

      // Layer 2: Per-IP rate limiting
      final ipResult = await _checkLayerRateLimits(
        key: 'ratelimit:ip:$action:$ipAddress',
        rules: ipRules,
        label: 'IP',
      );

      if (!ipResult.allowed) {
        session.log(
          'Rate limit exceeded for IP: $ipAddress (action: $action)',
          level: LogLevel.warning,
        );
        return ipResult;
      }

      // Layer 3: Global rate limiting
      final globalResult = await _checkLayerRateLimits(
        key: 'ratelimit:global:$action',
        rules: [globalRule],
        label: 'global',
      );

      if (!globalResult.allowed) {
        session.log(
          'Global rate limit exceeded (action: $action)',
          level: LogLevel.warning,
        );
        return globalResult;
      }

      // All layers passed - increment counters
      await _incrementCounters(
        identifier: identifier,
        ipAddress: ipAddress,
        action: action,
      );

      // Calculate remaining AFTER incrementing (subtract 1 from what we had before)
      final remainingAfterIncrement = (identifierResult.remaining ?? 1) - 1;

      return RateLimitResult.allowed(
        remaining:
            remainingAfterIncrement.clamp(0, identifierRules.first.requests),
        resetAt: identifierResult.resetAt ??
            DateTime.now().add(Duration(seconds: 300)),
      );
    } catch (e) {
      session.log(
        'Rate limit check error: $e',
        level: LogLevel.error,
        exception: e,
      );
      // Fail open - allow request if error occurs
      return RateLimitResult.allowed(
        remaining: 0,
        resetAt: DateTime.now().add(Duration(seconds: 60)),
      );
    }
  }

  /// Check rate limits for a specific layer with multiple rules
  Future<RateLimitResult> _checkLayerRateLimits({
    required String key,
    required List<RateLimitRule> rules,
    required String label,
  }) async {
    if (_redis == null) {
      return RateLimitResult.allowed(
        remaining: 999,
        resetAt: DateTime.now().add(Duration(seconds: 60)),
      );
    }

    for (final rule in rules) {
      final windowKey = '$key:${rule.windowSeconds}';

      // Get current count
      final countResponse = await _redis!.send_object(['GET', windowKey]);
      final count = countResponse != null
          ? int.tryParse(countResponse.toString()) ?? 0
          : 0;

      if (count >= rule.requests) {
        // Rate limit exceeded - check TTL
        final ttlResponse = await _redis!.send_object(['TTL', windowKey]);
        final ttl = ttlResponse is int ? ttlResponse : 0;
        final resetAt = DateTime.now()
            .add(Duration(seconds: ttl > 0 ? ttl : rule.windowSeconds));

        return RateLimitResult.denied(
          reason: '$label rate limit exceeded',
          retryAfter: Duration(seconds: ttl > 0 ? ttl : rule.windowSeconds),
          resetAt: resetAt,
          rule: rule,
        );
      }
    }

    // Calculate remaining and reset time from most restrictive rule
    final mostRestrictive = rules.first;
    final windowKey = '$key:${mostRestrictive.windowSeconds}';
    final countResponse = await _redis!.send_object(['GET', windowKey]);
    final count =
        countResponse != null ? int.tryParse(countResponse.toString()) ?? 0 : 0;
    final remaining = mostRestrictive.requests - count;

    final ttlResponse = await _redis!.send_object(['TTL', windowKey]);
    final ttl =
        ttlResponse is int ? ttlResponse : mostRestrictive.windowSeconds;
    final resetAt = DateTime.now()
        .add(Duration(seconds: ttl > 0 ? ttl : mostRestrictive.windowSeconds));

    return RateLimitResult.allowed(
      remaining: remaining,
      resetAt: resetAt,
    );
  }

  /// Increment counters for all layers after successful rate limit check
  Future<void> _incrementCounters({
    required String identifier,
    required String ipAddress,
    required String action,
  }) async {
    if (_redis == null) return;

    // Increment identifier counters
    for (final rule in identifierRules) {
      final key =
          'ratelimit:identifier:$action:${identifier.toLowerCase()}:${rule.windowSeconds}';
      await _incrementCounter(key, rule.windowSeconds);
    }

    // Increment IP counters
    for (final rule in ipRules) {
      final key = 'ratelimit:ip:$action:$ipAddress:${rule.windowSeconds}';
      await _incrementCounter(key, rule.windowSeconds);
    }

    // Increment global counter
    final globalKey = 'ratelimit:global:$action:${globalRule.windowSeconds}';
    await _incrementCounter(globalKey, globalRule.windowSeconds);
  }

  /// Increment a Redis counter with expiry
  Future<void> _incrementCounter(String key, int windowSeconds) async {
    if (_redis == null) return;

    final value = await _redis!.send_object(['GET', key]);
    if (value == null) {
      // First request - set with expiry
      await _redis!.send_object(['SETEX', key, windowSeconds.toString(), '1']);
    } else {
      // Increment existing counter
      await _redis!.send_object(['INCR', key]);
    }
  }

  /// Record a failed authentication attempt with progressive delays
  /// Used for progressive delays on failed OTP verifications
  Future<void> recordFailedAttempt({
    required String identifier,
    required String action,
  }) async {
    try {
      await _initRedis();
      if (_redis == null) return;

      final key = 'ratelimit:failed:$action:${identifier.toLowerCase()}';

      // Get current failed attempts
      final countResponse = await _redis!.send_object(['GET', key]);
      final failedAttempts = countResponse != null
          ? int.tryParse(countResponse.toString()) ?? 0
          : 0;

      // Increment failed attempts
      final newCount = failedAttempts + 1;
      await _redis!.send_object(
          ['SETEX', key, '3600', newCount.toString()]); // 1 hour TTL

      session.log(
        'Failed attempt recorded for $identifier: $newCount',
        level: LogLevel.info,
      );
    } catch (e) {
      session.log(
        'Failed to record failed attempt: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }

  /// Get progressive delay based on failed attempts
  /// Implements exponential backoff: 2^attempts seconds
  Future<Duration?> getProgressiveDelay({
    required String identifier,
    required String action,
  }) async {
    try {
      await _initRedis();
      if (_redis == null) return null;

      final key = 'ratelimit:failed:$action:${identifier.toLowerCase()}';

      final countResponse = await _redis!.send_object(['GET', key]);
      final failedAttempts = countResponse != null
          ? int.tryParse(countResponse.toString()) ?? 0
          : 0;

      if (failedAttempts == 0) {
        return null; // No delay
      }

      // Exponential backoff: 2^attempts seconds, max 300 seconds (5 minutes)
      final delaySeconds = (1 << failedAttempts).clamp(1, 300);
      return Duration(seconds: delaySeconds);
    } catch (e) {
      session.log(
        'Failed to get progressive delay: $e',
        level: LogLevel.error,
        exception: e,
      );
      return null; // No delay on error
    }
  }

  /// Clear failed attempts after successful authentication
  Future<void> clearFailedAttempts({
    required String identifier,
    required String action,
  }) async {
    try {
      await _initRedis();
      if (_redis == null) return;

      final key = 'ratelimit:failed:$action:${identifier.toLowerCase()}';
      await _redis!.send_object(['DEL', key]);

      session.log(
        'Failed attempts cleared for $identifier',
        level: LogLevel.debug,
      );
    } catch (e) {
      session.log(
        'Failed to clear failed attempts: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }

  /// Get current rate limit status for debugging/monitoring
  Future<Map<String, dynamic>> getRateLimitStatus({
    required String identifier,
    required String ipAddress,
    required String action,
  }) async {
    try {
      await _initRedis();
      if (_redis == null) {
        return {'error': 'Redis not available'};
      }

      final status = <String, dynamic>{};

      // Identifier limits
      final identifierLimits = <Map<String, dynamic>>[];
      for (final rule in identifierRules) {
        final key =
            'ratelimit:identifier:$action:${identifier.toLowerCase()}:${rule.windowSeconds}';
        final countResponse = await _redis!.send_object(['GET', key]);
        final count = countResponse != null
            ? int.tryParse(countResponse.toString()) ?? 0
            : 0;
        final ttlResponse = await _redis!.send_object(['TTL', key]);
        final ttl = ttlResponse is int ? ttlResponse : 0;

        identifierLimits.add({
          'window': '${rule.windowSeconds}s',
          'limit': rule.requests,
          'used': count,
          'remaining': rule.requests - count,
          'resetIn': '${ttl}s',
        });
      }
      status['identifier'] = identifierLimits;

      // IP limits
      final ipLimits = <Map<String, dynamic>>[];
      for (final rule in ipRules) {
        final key = 'ratelimit:ip:$action:$ipAddress:${rule.windowSeconds}';
        final countResponse = await _redis!.send_object(['GET', key]);
        final count = countResponse != null
            ? int.tryParse(countResponse.toString()) ?? 0
            : 0;
        final ttlResponse = await _redis!.send_object(['TTL', key]);
        final ttl = ttlResponse is int ? ttlResponse : 0;

        ipLimits.add({
          'window': '${rule.windowSeconds}s',
          'limit': rule.requests,
          'used': count,
          'remaining': rule.requests - count,
          'resetIn': '${ttl}s',
        });
      }
      status['ip'] = ipLimits;

      // Global limit
      final globalKey = 'ratelimit:global:$action:${globalRule.windowSeconds}';
      final globalCountResponse = await _redis!.send_object(['GET', globalKey]);
      final globalCount = globalCountResponse != null
          ? int.tryParse(globalCountResponse.toString()) ?? 0
          : 0;
      final globalTtlResponse = await _redis!.send_object(['TTL', globalKey]);
      final globalTtl = globalTtlResponse is int ? globalTtlResponse : 0;

      status['global'] = {
        'window': '${globalRule.windowSeconds}s',
        'limit': globalRule.requests,
        'used': globalCount,
        'remaining': globalRule.requests - globalCount,
        'resetIn': '${globalTtl}s',
      };

      // Failed attempts
      final failedKey = 'ratelimit:failed:$action:${identifier.toLowerCase()}';
      final failedCountResponse = await _redis!.send_object(['GET', failedKey]);
      final failedCount = failedCountResponse != null
          ? int.tryParse(failedCountResponse.toString()) ?? 0
          : 0;
      status['failedAttempts'] = failedCount;

      return status;
    } catch (e) {
      session.log(
        'Failed to get rate limit status: $e',
        level: LogLevel.error,
        exception: e,
      );
      return {'error': e.toString()};
    }
  }

  /// Close Redis connection
  Future<void> close() async {
    await _redisConn?.close();
    _redis = null;
    _redisConn = null;
  }
}

/// Rate limit rule configuration
class RateLimitRule {
  final int requests;
  final int windowSeconds;
  final int blockDurationSeconds;

  const RateLimitRule({
    required this.requests,
    required this.windowSeconds,
    required this.blockDurationSeconds,
  });
}

/// Result of rate limit check
class RateLimitResult {
  final bool allowed;
  final String? reason;
  final int? remaining;
  final DateTime? resetAt;
  final Duration? retryAfter;
  final RateLimitRule? rule;

  RateLimitResult._({
    required this.allowed,
    this.reason,
    this.remaining,
    this.resetAt,
    this.retryAfter,
    this.rule,
  });

  factory RateLimitResult.allowed({
    required int remaining,
    required DateTime resetAt,
  }) {
    return RateLimitResult._(
      allowed: true,
      remaining: remaining,
      resetAt: resetAt,
    );
  }

  factory RateLimitResult.denied({
    required String reason,
    required Duration retryAfter,
    required DateTime resetAt,
    required RateLimitRule rule,
  }) {
    return RateLimitResult._(
      allowed: false,
      reason: reason,
      retryAfter: retryAfter,
      resetAt: resetAt,
      rule: rule,
    );
  }

  /// Convert to HTTP headers (X-RateLimit-*)
  Map<String, String> toHeaders() {
    final headers = <String, String>{};

    if (remaining != null) {
      headers['X-RateLimit-Remaining'] = remaining.toString();
    }

    if (resetAt != null) {
      headers['X-RateLimit-Reset'] =
          (resetAt!.millisecondsSinceEpoch ~/ 1000).toString();
    }

    if (retryAfter != null) {
      headers['Retry-After'] = retryAfter!.inSeconds.toString();
    }

    return headers;
  }
}
