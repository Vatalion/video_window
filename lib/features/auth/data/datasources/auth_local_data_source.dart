import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_window/features/auth/domain/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCachedUser();
  Future<void> saveProgressiveProfile(
    String userId,
    Map<String, dynamic> profileData,
  );
  Future<Map<String, dynamic>?> getProgressiveProfile(String userId);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _cachedUserKey = 'CACHED_USER';
  static const String _progressiveProfilePrefix = 'PROGRESSIVE_PROFILE_';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheUser(UserModel user) async {
    await sharedPreferences.setString(
      _cachedUserKey,
      jsonEncode(user.toJson()),
    );
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final userJson = sharedPreferences.getString(_cachedUserKey);
    if (userJson != null) {
      try {
        // Parse the JSON string back to a Map
        final userMap = Map<String, dynamic>.from(jsonDecode(userJson) as Map);
        return UserModel.fromJson(userMap);
      } catch (e) {
        await clearCachedUser();
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> clearCachedUser() async {
    await sharedPreferences.remove(_cachedUserKey);
  }

  @override
  Future<void> saveProgressiveProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    await sharedPreferences.setString(
      '$_progressiveProfilePrefix$userId',
      profileData.toString(),
    );
  }

  @override
  Future<Map<String, dynamic>?> getProgressiveProfile(String userId) async {
    final profileJson = sharedPreferences.getString(
      '$_progressiveProfilePrefix$userId',
    );
    if (profileJson != null) {
      try {
        return profileJson as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
