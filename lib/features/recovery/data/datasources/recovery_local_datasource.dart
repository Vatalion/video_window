import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/recovery_models.dart';

abstract class RecoveryLocalDataSource {
  // Account lock information
  Future<void> saveAccountLockInfo(
    String email,
    AccountLockStatus status,
    DateTime? lockedUntil,
  );
  Future<AccountLockStatus?> getAccountLockStatus(String email);
  Future<DateTime?> getAccountLockUntil(String email);
  Future<void> removeAccountLockInfo(String email);

  // Recovery attempt tracking
  Future<void> saveRecoveryAttempt(RecoveryAttempt attempt);
  Future<List<RecoveryAttempt>> getLocalRecoveryAttempts(String email);
  Future<void> clearRecoveryAttempts(String email);

  // User preferences
  Future<void> setRecoveryMethodPreference(
    String email,
    RecoveryMethod method,
  );
  Future<RecoveryMethod?> getRecoveryMethodPreference(String email);

  // Security questions cache
  Future<void> cacheSecurityQuestions(List<SecurityQuestion> questions);
  Future<List<SecurityQuestion>?> getCachedSecurityQuestions();
  Future<void> clearSecurityQuestionsCache();
}

class RecoveryLocalDataSourceImpl implements RecoveryLocalDataSource {
  final SharedPreferences sharedPreferences;

  RecoveryLocalDataSourceImpl({required this.sharedPreferences});

  static const String _accountLockPrefix = 'account_lock_';
  static const String _recoveryAttemptsPrefix = 'recovery_attempts_';
  static const String _recoveryMethodPrefix = 'recovery_method_';
  static const String _securityQuestionsKey = 'security_questions';

  @override
  Future<void> saveAccountLockInfo(
    String email,
    AccountLockStatus status,
    DateTime? lockedUntil,
  ) async {
    final key = '$_accountLockPrefix${email.toLowerCase()}';
    await sharedPreferences.setString(key, status.name);

    if (lockedUntil != null) {
      await sharedPreferences.setString(
        '${key}_until',
        lockedUntil.toIso8601String(),
      );
    }
  }

  @override
  Future<AccountLockStatus?> getAccountLockStatus(String email) async {
    final key = '$_accountLockPrefix${email.toLowerCase()}';
    final statusString = sharedPreferences.getString(key);

    if (statusString == null) return null;

    return AccountLockStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => AccountLockStatus.unlocked,
    );
  }

  @override
  Future<DateTime?> getAccountLockUntil(String email) async {
    final key = '$_accountLockPrefix${email.toLowerCase()}_until';
    final dateString = sharedPreferences.getString(key);

    if (dateString == null) return null;

    return DateTime.tryParse(dateString);
  }

  @override
  Future<void> removeAccountLockInfo(String email) async {
    final key = '$_accountLockPrefix${email.toLowerCase()}';
    await sharedPreferences.remove(key);
    await sharedPreferences.remove('${key}_until');
  }

  @override
  Future<void> saveRecoveryAttempt(RecoveryAttempt attempt) async {
    final key = '$_recoveryAttemptsPrefix${attempt.email.toLowerCase()}';
    final attempts = await getLocalRecoveryAttempts(attempt.email);

    attempts.add(attempt);

    // Keep only last 50 attempts
    if (attempts.length > 50) {
      attempts.removeRange(0, attempts.length - 50);
    }

    final attemptsJson = attempts.map((a) => a.toJson()).toList();
    await sharedPreferences.setString(key, attemptsJson.toString());
  }

  @override
  Future<List<RecoveryAttempt>> getLocalRecoveryAttempts(String email) async {
    final key = '$_recoveryAttemptsPrefix${email.toLowerCase()}';
    final attemptsString = sharedPreferences.getString(key);

    if (attemptsString == null) return [];

    try {
      final attemptsList = attemptsString
          .substring(1, attemptsString.length - 1)
          .split('},')
          .map((s) => s.endsWith('}') ? s : '$s}')
          .toList();

      return attemptsList.map((json) {
        final cleanJson = json.replaceAllMapped(
          RegExp(r'(\w+):'),
          (match) => '"${match.group(1)}":',
        );
        return RecoveryAttempt.fromJson(cleanJson);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> clearRecoveryAttempts(String email) async {
    final key = '$_recoveryAttemptsPrefix${email.toLowerCase()}';
    await sharedPreferences.remove(key);
  }

  @override
  Future<void> setRecoveryMethodPreference(
    String email,
    RecoveryMethod method,
  ) async {
    final key = '$_recoveryMethodPrefix${email.toLowerCase()}';
    await sharedPreferences.setString(key, method.name);
  }

  @override
  Future<RecoveryMethod?> getRecoveryMethodPreference(String email) async {
    final key = '$_recoveryMethodPrefix${email.toLowerCase()}';
    final methodString = sharedPreferences.getString(key);

    if (methodString == null) return null;

    return RecoveryMethod.values.firstWhere(
      (e) => e.name == methodString,
      orElse: () => RecoveryMethod.email,
    );
  }

  @override
  Future<void> cacheSecurityQuestions(List<SecurityQuestion> questions) async {
    final questionsJson = questions.map((q) => q.toJson()).toList();
    await sharedPreferences.setString(
      _securityQuestionsKey,
      questionsJson.toString(),
    );
  }

  @override
  Future<List<SecurityQuestion>?> getCachedSecurityQuestions() async {
    final questionsString = sharedPreferences.getString(_securityQuestionsKey);

    if (questionsString == null) return null;

    try {
      final questionsList = questionsString
          .substring(1, questionsString.length - 1)
          .split('},')
          .map((s) => s.endsWith('}') ? s : '$s}')
          .toList();

      return questionsList.map((json) {
        final cleanJson = json.replaceAllMapped(
          RegExp(r'(\w+):'),
          (match) => '"${match.group(1)}":',
        );
        return SecurityQuestion.fromJson(cleanJson);
      }).toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearSecurityQuestionsCache() async {
    await sharedPreferences.remove(_securityQuestionsKey);
  }
}