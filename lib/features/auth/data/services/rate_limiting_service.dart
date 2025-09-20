import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/exceptions.dart';

abstract class RateLimitingService {
  Future<bool> canSendSms(String userId);
  Future<void> recordSmsAttempt(String userId);
  Future<bool> canAttemptVerification(String userId);
  Future<void> recordVerificationAttempt(String userId);
  Future<void> resetRateLimits(String userId);
  Future<Map<String, dynamic>> getRateLimitStatus(String userId);
}

class RateLimitingServiceImpl implements RateLimitingService {
  final FlutterSecureStorage secureStorage;
  final Logger logger;

  static const Duration smsCooldown = Duration(hours: 1);
  static const Duration verificationCooldown = Duration(minutes: 15);
  static const int maxSmsPerHour = 5;
  static const int maxVerificationAttempts = 10;

  RateLimitingServiceImpl({required this.secureStorage, required this.logger});

  String _getKey(String userId, String type) => 'rate_limit_${userId}_$type';

  Future<Map<String, dynamic>?> _getRateData(String userId, String type) async {
    try {
      final key = _getKey(userId, type);
      final data = await secureStorage.read(key: key);
      if (data == null) return null;

      final parts = data.split('|');
      if (parts.length != 3) return null;

      return {
        'count': int.tryParse(parts[0]) ?? 0,
        'lastAttempt': DateTime.tryParse(parts[1]) ?? DateTime.now(),
        'blockedUntil': parts[2] == 'null' ? null : DateTime.tryParse(parts[2]),
      };
    } catch (e) {
      logger.e('Failed to get rate data: ${e.toString()}');
      return null;
    }
  }

  Future<void> _setRateData(
    String userId,
    String type,
    Map<String, dynamic> data,
  ) async {
    try {
      final key = _getKey(userId, type);
      final value =
          '${data['count']}|${data['lastAttempt']}|${data['blockedUntil']}';
      await secureStorage.write(key: key, value: value);
    } catch (e) {
      logger.e('Failed to set rate data: ${e.toString()}');
      throw CacheException('Failed to store rate limit data');
    }
  }

  @override
  Future<bool> canSendSms(String userId) async {
    try {
      final data = await _getRateData(userId, 'sms');
      if (data == null) return true;

      final now = DateTime.now();

      if (data['blockedUntil'] != null && now.isBefore(data['blockedUntil'])) {
        logger.w(
          'SMS sending blocked for user $userId until ${data['blockedUntil']}',
        );
        return false;
      }

      if (now.difference(data['lastAttempt']) > smsCooldown) {
        await _resetRateData(userId, 'sms');
        return true;
      }

      return data['count'] < maxSmsPerHour;
    } catch (e) {
      logger.e('Failed to check SMS rate limit: ${e.toString()}');
      return false;
    }
  }

  @override
  Future<void> recordSmsAttempt(String userId) async {
    try {
      final data =
          await _getRateData(userId, 'sms') ??
          {'count': 0, 'lastAttempt': DateTime.now(), 'blockedUntil': null};

      final now = DateTime.now();
      data['count'] = (data['count'] as int) + 1;
      data['lastAttempt'] = now;

      if (data['count'] >= maxSmsPerHour) {
        data['blockedUntil'] = now.add(smsCooldown);
        logger.w(
          'SMS sending blocked for user $userId until ${data['blockedUntil']}',
        );
      }

      await _setRateData(userId, 'sms', data);
      logger.i(
        'Recorded SMS attempt for user $userId. Count: ${data['count']}',
      );
    } catch (e) {
      logger.e('Failed to record SMS attempt: ${e.toString()}');
      throw CacheException('Failed to record SMS attempt');
    }
  }

  @override
  Future<bool> canAttemptVerification(String userId) async {
    try {
      final data = await _getRateData(userId, 'verification');
      if (data == null) return true;

      final now = DateTime.now();

      if (data['blockedUntil'] != null && now.isBefore(data['blockedUntil'])) {
        logger.w(
          'Verification blocked for user $userId until ${data['blockedUntil']}',
        );
        return false;
      }

      if (now.difference(data['lastAttempt']) > verificationCooldown) {
        await _resetRateData(userId, 'verification');
        return true;
      }

      return data['count'] < maxVerificationAttempts;
    } catch (e) {
      logger.e('Failed to check verification rate limit: ${e.toString()}');
      return false;
    }
  }

  @override
  Future<void> recordVerificationAttempt(String userId) async {
    try {
      final data =
          await _getRateData(userId, 'verification') ??
          {'count': 0, 'lastAttempt': DateTime.now(), 'blockedUntil': null};

      final now = DateTime.now();
      data['count'] = (data['count'] as int) + 1;
      data['lastAttempt'] = now;

      if (data['count'] >= maxVerificationAttempts) {
        data['blockedUntil'] = now.add(verificationCooldown);
        logger.w(
          'Verification blocked for user $userId until ${data['blockedUntil']}',
        );
      }

      await _setRateData(userId, 'verification', data);
      logger.i(
        'Recorded verification attempt for user $userId. Count: ${data['count']}',
      );
    } catch (e) {
      logger.e('Failed to record verification attempt: ${e.toString()}');
      throw CacheException('Failed to record verification attempt');
    }
  }

  @override
  Future<void> resetRateLimits(String userId) async {
    try {
      await _resetRateData(userId, 'sms');
      await _resetRateData(userId, 'verification');
      logger.i('Reset rate limits for user $userId');
    } catch (e) {
      logger.e('Failed to reset rate limits: ${e.toString()}');
      throw CacheException('Failed to reset rate limits');
    }
  }

  Future<void> _resetRateData(String userId, String type) async {
    final data = {
      'count': 0,
      'lastAttempt': DateTime.now(),
      'blockedUntil': null,
    };
    await _setRateData(userId, type, data);
  }

  @override
  Future<Map<String, dynamic>> getRateLimitStatus(String userId) async {
    try {
      final smsData = await _getRateData(userId, 'sms');
      final verificationData = await _getRateData(userId, 'verification');
      final now = DateTime.now();

      return {
        'sms': {
          'attempts': smsData?['count'] ?? 0,
          'maxAttempts': maxSmsPerHour,
          'cooldown': smsCooldown.inMinutes,
          'nextAttempt':
              smsData?['blockedUntil'] != null &&
                  now.isBefore(smsData!['blockedUntil'])
              ? smsData['blockedUntil'].difference(now).inMinutes
              : 0,
          'isBlocked':
              smsData?['blockedUntil'] != null &&
              now.isBefore(smsData!['blockedUntil']),
        },
        'verification': {
          'attempts': verificationData?['count'] ?? 0,
          'maxAttempts': maxVerificationAttempts,
          'cooldown': verificationCooldown.inMinutes,
          'nextAttempt':
              verificationData?['blockedUntil'] != null &&
                  now.isBefore(verificationData!['blockedUntil'])
              ? verificationData['blockedUntil'].difference(now).inMinutes
              : 0,
          'isBlocked':
              verificationData?['blockedUntil'] != null &&
              now.isBefore(verificationData!['blockedUntil']),
        },
      };
    } catch (e) {
      logger.e('Failed to get rate limit status: ${e.toString()}');
      throw CacheException('Failed to get rate limit status');
    }
  }
}
