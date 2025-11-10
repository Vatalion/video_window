import 'package:serverpod/serverpod.dart';
import 'package:redis/redis.dart';

/// Progressive account lockout service
/// Implements SEC-001 requirement: 3/5/10/15 failed attempts trigger escalating locks
class AccountLockoutService {
  final Session session;
  RedisConnection? _redisConn;
  Command? _redis;

  AccountLockoutService(this.session);

  /// Lockout thresholds: attempts -> lock duration
  static const Map<int, Duration> lockoutThresholds = {
    3: Duration(minutes: 5),
    5: Duration(minutes: 30),
    10: Duration(hours: 1),
    15: Duration(hours: 24),
  };

  /// Initialize Redis connection
  Future<void> _initRedis() async {
    if (_redis != null) return;

    try {
      final host = 'localhost';
      final port = 8091;

      _redisConn = RedisConnection();
      _redis = await _redisConn!.connect(host, port);

      try {
        await _redis!.send_object(['AUTH', 'JLLDNS1puOSFsmtR7AePtBQt9huXBltb']);
      } catch (e) {
        session.log('Redis AUTH: $e', level: LogLevel.debug);
      }
    } catch (e) {
      session.log('Failed to connect to Redis: $e',
          level: LogLevel.error, exception: e);
      _redis = null;
    }
  }

  /// Check if account is currently locked
  Future<AccountLockStatus> checkLockStatus({
    required String identifier,
    required String action,
  }) async {
    try {
      await _initRedis();
      if (_redis == null) {
        return AccountLockStatus.notLocked();
      }

      final key = 'lockout:$action:${identifier.toLowerCase()}';
      final attemptsKey = '$key:attempts';
      final lockExpiryKey = '$key:lock_expiry';

      // Check if explicitly locked
      final lockExpiryResponse =
          await _redis!.send_object(['GET', lockExpiryKey]);
      if (lockExpiryResponse != null) {
        final lockExpiry = int.tryParse(lockExpiryResponse.toString()) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (lockExpiry > now) {
          // Still locked
          final remainingMs = lockExpiry - now;
          final remainingSeconds = (remainingMs / 1000).ceil();

          session.log(
            'Account locked: $identifier (${remainingSeconds}s remaining)',
            level: LogLevel.warning,
          );

          return AccountLockStatus.locked(
            remainingDuration: Duration(milliseconds: remainingMs),
            unlocksAt: DateTime.fromMillisecondsSinceEpoch(lockExpiry),
          );
        } else {
          // Lock expired - clean up
          await _redis!.send_object(['DEL', lockExpiryKey]);
        }
      }

      // Get current attempt count
      final attemptsResponse = await _redis!.send_object(['GET', attemptsKey]);
      final attempts = attemptsResponse != null
          ? int.tryParse(attemptsResponse.toString()) ?? 0
          : 0;

      return AccountLockStatus.notLocked(failedAttempts: attempts);
    } catch (e) {
      session.log(
        'Lock status check error: $e',
        level: LogLevel.error,
        exception: e,
      );
      return AccountLockStatus.notLocked();
    }
  }

  /// Record a failed authentication attempt and apply lockout if threshold reached
  Future<void> recordFailedAttempt({
    required String identifier,
    required String action,
  }) async {
    try {
      await _initRedis();
      if (_redis == null) return;

      final key = 'lockout:$action:${identifier.toLowerCase()}';
      final attemptsKey = '$key:attempts';
      final lockExpiryKey = '$key:lock_expiry';

      // Increment attempts
      final attemptsResponse = await _redis!.send_object(['GET', attemptsKey]);
      final currentAttempts = attemptsResponse != null
          ? int.tryParse(attemptsResponse.toString()) ?? 0
          : 0;
      final newAttempts = currentAttempts + 1;

      // Store attempts with 24-hour expiry (resets if no activity)
      await _redis!
          .send_object(['SETEX', attemptsKey, '86400', newAttempts.toString()]);

      session.log(
        'Failed attempt #$newAttempts for $identifier',
        level: LogLevel.info,
      );

      // Check if we hit a lockout threshold
      Duration? lockDuration;
      for (final entry in lockoutThresholds.entries.toList().reversed) {
        if (newAttempts >= entry.key) {
          lockDuration = entry.value;
          break;
        }
      }

      if (lockDuration != null) {
        // Apply lockout
        final lockUntil = DateTime.now().add(lockDuration);
        await _redis!.send_object([
          'SETEX',
          lockExpiryKey,
          lockDuration.inSeconds.toString(),
          lockUntil.millisecondsSinceEpoch.toString(),
        ]);

        session.log(
          'Account locked: $identifier for ${lockDuration.inMinutes} minutes (${newAttempts} attempts)',
          level: LogLevel.warning,
        );

        // Send notification email (async - don't wait)
        _sendLockoutNotification(identifier, lockDuration, newAttempts);
      }
    } catch (e) {
      session.log(
        'Failed to record failed attempt: $e',
        level: LogLevel.error,
        exception: e,
      );
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

      final key = 'lockout:$action:${identifier.toLowerCase()}';
      final attemptsKey = '$key:attempts';
      final lockExpiryKey = '$key:lock_expiry';

      await _redis!.send_object(['DEL', attemptsKey, lockExpiryKey]);

      session.log(
        'Failed attempts cleared for $identifier',
        level: LogLevel.debug,
      );
    } catch (e) {
      session.log(
        'Failed to clear attempts: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }

  /// Manually unlock an account (admin override)
  Future<void> unlockAccount({
    required String identifier,
    required String action,
  }) async {
    try {
      await _initRedis();
      if (_redis == null) return;

      final key = 'lockout:$action:${identifier.toLowerCase()}';
      final lockExpiryKey = '$key:lock_expiry';

      await _redis!.send_object(['DEL', lockExpiryKey]);

      session.log(
        'Account manually unlocked: $identifier',
        level: LogLevel.info,
      );
    } catch (e) {
      session.log(
        'Failed to unlock account: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }

  /// Get lockout statistics for monitoring
  Future<Map<String, dynamic>> getLockoutStats({
    required String identifier,
    required String action,
  }) async {
    try {
      await _initRedis();
      if (_redis == null) {
        return {'error': 'Redis not available'};
      }

      final key = 'lockout:$action:${identifier.toLowerCase()}';
      final attemptsKey = '$key:attempts';
      final lockExpiryKey = '$key:lock_expiry';

      final attemptsResponse = await _redis!.send_object(['GET', attemptsKey]);
      final attempts = attemptsResponse != null
          ? int.tryParse(attemptsResponse.toString()) ?? 0
          : 0;

      final lockExpiryResponse =
          await _redis!.send_object(['GET', lockExpiryKey]);
      bool isLocked = false;
      int? remainingSeconds;

      if (lockExpiryResponse != null) {
        final lockExpiry = int.tryParse(lockExpiryResponse.toString()) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (lockExpiry > now) {
          isLocked = true;
          remainingSeconds = ((lockExpiry - now) / 1000).ceil();
        }
      }

      // Calculate next threshold
      int? nextThreshold;
      Duration? nextLockDuration;
      for (final entry in lockoutThresholds.entries) {
        if (attempts < entry.key) {
          nextThreshold = entry.key;
          nextLockDuration = entry.value;
          break;
        }
      }

      return {
        'identifier': identifier,
        'action': action,
        'failedAttempts': attempts,
        'isLocked': isLocked,
        'remainingLockSeconds': remainingSeconds,
        'nextThreshold': nextThreshold,
        'nextLockDuration': nextLockDuration?.inMinutes,
        'thresholds': lockoutThresholds.map(
          (k, v) => MapEntry(k.toString(), '${v.inMinutes} minutes'),
        ),
      };
    } catch (e) {
      session.log(
        'Failed to get lockout stats: $e',
        level: LogLevel.error,
        exception: e,
      );
      return {'error': e.toString()};
    }
  }

  /// Send lockout notification email (placeholder - integrate with email service)
  void _sendLockoutNotification(
    String identifier,
    Duration lockDuration,
    int attempts,
  ) {
    // TODO: Integrate with SendGrid or email service
    session.log(
      'SECURITY ALERT: Account $identifier locked for ${lockDuration.inMinutes} minutes after $attempts failed attempts',
      level: LogLevel.warning,
    );
  }

  /// Close Redis connection
  Future<void> close() async {
    await _redisConn?.close();
    _redis = null;
    _redisConn = null;
  }
}

/// Account lock status result
class AccountLockStatus {
  final bool isLocked;
  final Duration? remainingDuration;
  final DateTime? unlocksAt;
  final int failedAttempts;

  AccountLockStatus._({
    required this.isLocked,
    this.remainingDuration,
    this.unlocksAt,
    required this.failedAttempts,
  });

  factory AccountLockStatus.locked({
    required Duration remainingDuration,
    required DateTime unlocksAt,
  }) {
    return AccountLockStatus._(
      isLocked: true,
      remainingDuration: remainingDuration,
      unlocksAt: unlocksAt,
      failedAttempts: 0, // Not relevant when locked
    );
  }

  factory AccountLockStatus.notLocked({int failedAttempts = 0}) {
    return AccountLockStatus._(
      isLocked: false,
      failedAttempts: failedAttempts,
    );
  }

  /// Get human-readable message
  String getMessage() {
    if (isLocked && remainingDuration != null) {
      final minutes = remainingDuration!.inMinutes;
      final seconds = remainingDuration!.inSeconds % 60;

      if (minutes > 0) {
        return 'Account locked. Try again in $minutes minute${minutes != 1 ? 's' : ''}.';
      } else {
        return 'Account locked. Try again in $seconds second${seconds != 1 ? 's' : ''}.';
      }
    }
    return 'Account not locked';
  }
}
