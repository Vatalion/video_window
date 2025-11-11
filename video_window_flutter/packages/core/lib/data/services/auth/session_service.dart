import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../repositories/auth_repository.dart';

/// Session refresh scheduler with exponential backoff
/// Implements AC-1: Background refresh 5min before expiry, retries, graceful logout
class SessionService {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _secureStorage;

  Timer? _refreshTimer;
  DateTime? _tokenExpiry;
  int _consecutiveFailures = 0;
  DateTime? _lastRefreshAttempt;

  // Constants for AC-1 compliance
  static const _refreshBeforeExpiry = Duration(minutes: 5);
  static const _maxConsecutiveFailures = 3;
  static const _minRetryDelay = Duration(seconds: 5);
  static const _maxRetryDelay = Duration(minutes: 5);

  // Secure storage keys
  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyTokenExpiry = 'auth_token_expiry';
  static const _keyLastRefreshTime = 'auth_last_refresh_time';
  static const _keyFailureStreak = 'auth_failure_streak';

  SessionService({
    required AuthRepository authRepository,
    required FlutterSecureStorage secureStorage,
  })  : _authRepository = authRepository,
        _secureStorage = secureStorage;

  /// Initialize session scheduler from stored credentials
  /// Resumes refresh schedule after app restart (crash resilience)
  Future<bool> initialize() async {
    try {
      final accessToken = await _secureStorage.read(key: _keyAccessToken);
      final refreshToken = await _secureStorage.read(key: _keyRefreshToken);
      final expiryStr = await _secureStorage.read(key: _keyTokenExpiry);
      final failureStreakStr =
          await _secureStorage.read(key: _keyFailureStreak);

      if (accessToken == null || refreshToken == null || expiryStr == null) {
        return false; // No existing session
      }

      _tokenExpiry = DateTime.parse(expiryStr);
      _consecutiveFailures = int.tryParse(failureStreakStr ?? '0') ?? 0;

      // Check if token is already expired
      if (_tokenExpiry!.isBefore(DateTime.now())) {
        debugPrint('Session expired, attempting refresh');
        await _attemptRefresh();
        return _consecutiveFailures < _maxConsecutiveFailures;
      }

      // Schedule next refresh
      _scheduleNextRefresh();
      return true;
    } catch (e) {
      debugPrint('Failed to initialize session service: $e');
      return false;
    }
  }

  /// Store new session tokens and schedule refresh
  Future<void> storeSession({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    try {
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

      await _secureStorage.write(key: _keyAccessToken, value: accessToken);
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
      await _secureStorage.write(
        key: _keyTokenExpiry,
        value: _tokenExpiry!.toIso8601String(),
      );

      // Reset failure streak on successful token storage
      _consecutiveFailures = 0;
      await _secureStorage.write(
        key: _keyFailureStreak,
        value: _consecutiveFailures.toString(),
      );

      // Record last refresh time
      await _secureStorage.write(
        key: _keyLastRefreshTime,
        value: DateTime.now().toIso8601String(),
      );

      // Schedule next refresh 5 minutes before expiry (AC-1)
      _scheduleNextRefresh();

      debugPrint('Session stored, refresh scheduled for ${_getRefreshTime()}');
    } catch (e) {
      debugPrint('Failed to store session: $e');
      rethrow;
    }
  }

  /// Schedule refresh timer 5 minutes before token expiry
  void _scheduleNextRefresh() {
    _refreshTimer?.cancel();

    if (_tokenExpiry == null) return;

    final refreshTime = _getRefreshTime();
    final delay = refreshTime.difference(DateTime.now());

    if (delay.isNegative) {
      // Token expired, refresh immediately
      debugPrint('Token expired, refreshing immediately');
      _attemptRefresh();
    } else {
      _refreshTimer = Timer(delay, () {
        debugPrint('Scheduled refresh triggered');
        _attemptRefresh();
      });
      debugPrint('Next refresh scheduled in ${delay.inSeconds}s');
    }
  }

  /// Calculate refresh time (5 minutes before expiry per AC-1)
  DateTime _getRefreshTime() {
    if (_tokenExpiry == null) return DateTime.now();
    return _tokenExpiry!.subtract(_refreshBeforeExpiry);
  }

  /// Attempt token refresh with exponential backoff
  /// AC-1: Retries with exponential backoff, graceful logout after failures
  Future<bool> _attemptRefresh() async {
    try {
      // Prevent refresh loops
      if (_lastRefreshAttempt != null &&
          DateTime.now().difference(_lastRefreshAttempt!) < _minRetryDelay) {
        debugPrint('Refresh throttled, too soon since last attempt');
        return false;
      }

      _lastRefreshAttempt = DateTime.now();

      final refreshToken = await _secureStorage.read(key: _keyRefreshToken);
      if (refreshToken == null) {
        debugPrint('No refresh token available');
        await _handleRefreshFailure('NO_REFRESH_TOKEN');
        return false;
      }

      debugPrint(
          'Attempting token refresh (failure streak: $_consecutiveFailures)');

      final result = await _authRepository.refreshToken(refreshToken);

      if (result.success && result.tokens != null) {
        // Success! Store new tokens and reset failures
        await storeSession(
          accessToken: result.tokens!.accessToken,
          refreshToken: result.tokens!.refreshToken,
          expiresIn: result.tokens!.expiresIn,
        );

        debugPrint('Token refresh successful');
        _consecutiveFailures = 0;
        await _secureStorage.write(
          key: _keyFailureStreak,
          value: '0',
        );

        return true;
      } else {
        // Refresh failed
        debugPrint('Token refresh failed: ${result.error}');
        await _handleRefreshFailure(result.error ?? 'UNKNOWN_ERROR');
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh exception: $e');
      await _handleRefreshFailure('EXCEPTION');
      return false;
    }
  }

  /// Handle refresh failure with retry logic
  /// AC-1: Exponential backoff, graceful logout after max failures
  Future<void> _handleRefreshFailure(String error) async {
    _consecutiveFailures++;

    await _secureStorage.write(
      key: _keyFailureStreak,
      value: _consecutiveFailures.toString(),
    );

    // AC-1: Graceful logout after consecutive failures
    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      debugPrint(
        'Max consecutive refresh failures reached ($_maxConsecutiveFailures), initiating logout',
      );
      await forceLogout();
      return;
    }

    // Exponential backoff: 5s, 15s, 45s, 2m15s, 5m (capped)
    final backoffDelay = _calculateBackoffDelay(_consecutiveFailures);
    debugPrint(
      'Scheduling retry in ${backoffDelay.inSeconds}s (attempt ${_consecutiveFailures + 1})',
    );

    _refreshTimer?.cancel();
    _refreshTimer = Timer(backoffDelay, () {
      debugPrint('Retry attempt ${_consecutiveFailures + 1}');
      _attemptRefresh();
    });
  }

  /// Calculate exponential backoff delay
  /// Formula: min(base * 3^failures, max_delay)
  Duration _calculateBackoffDelay(int failures) {
    final delaySeconds = _minRetryDelay.inSeconds * (3 ^ failures);
    return Duration(
      seconds: delaySeconds.clamp(
        _minRetryDelay.inSeconds,
        _maxRetryDelay.inSeconds,
      ),
    );
  }

  /// Force logout (clears session and stops refresh)
  /// AC-3: Clear secure storage and stop scheduler
  Future<void> forceLogout() async {
    try {
      debugPrint('Force logout initiated');

      _refreshTimer?.cancel();
      _refreshTimer = null;
      _tokenExpiry = null;
      _consecutiveFailures = 0;
      _lastRefreshAttempt = null;

      // Try to revoke tokens on server
      final accessToken = await _secureStorage.read(key: _keyAccessToken);
      final refreshToken = await _secureStorage.read(key: _keyRefreshToken);

      if (accessToken != null && refreshToken != null) {
        try {
          await _authRepository.logout(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
          debugPrint('Server-side logout successful');
        } catch (e) {
          debugPrint('Server-side logout failed: $e');
        }
      }

      // Clear all stored credentials (AC-3)
      await _secureStorage.deleteAll();
      debugPrint('Session cleared from secure storage');
    } catch (e) {
      debugPrint('Force logout error: $e');
    }
  }

  /// Manual refresh trigger (for pull-to-refresh scenarios)
  Future<bool> manualRefresh() async {
    debugPrint('Manual refresh requested');
    return await _attemptRefresh();
  }

  /// Get current failure streak (for UI feedback)
  int get consecutiveFailures => _consecutiveFailures;

  /// Check if session is near expiry (within refresh window)
  bool get isNearExpiry {
    if (_tokenExpiry == null) return false;
    return DateTime.now().isAfter(_getRefreshTime());
  }

  /// Get time until next refresh
  Duration? get timeUntilRefresh {
    if (_tokenExpiry == null) return null;
    final refreshTime = _getRefreshTime();
    final diff = refreshTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _keyAccessToken);
  }

  /// Get current refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _keyRefreshToken);
  }

  /// Clean up resources
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}
