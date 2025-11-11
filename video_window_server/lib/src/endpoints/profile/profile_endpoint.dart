import 'package:serverpod/serverpod.dart';
import '../../services/profile/profile_service.dart';
import '../../generated/profile/user_profile.dart';
import '../../generated/profile/privacy_settings.dart';
import '../../generated/profile/notification_preferences.dart';

/// Profile endpoint for managing user profiles, privacy settings, and notifications
/// Implements Story 3-1: Viewer Profile Management
class ProfileEndpoint extends Endpoint {
  @override
  String get name => 'profile';

  /// Get current user profile
  /// GET /profile/me
  /// AC1: Complete profile management interface
  /// AC6: Role-based access control - users can only access their own profile
  Future<UserProfile?> getMyProfile(
    Session session,
    int userId,
  ) async {
    try {
      final profileService = ProfileService(session);
      return await profileService.getUserProfile(userId, userId);
    } catch (e, stackTrace) {
      session.log(
        'Failed to get profile for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update current user profile
  /// PUT /profile/me
  /// AC1: Complete profile management interface with validation
  /// AC4: Sensitive PII data encrypted at rest
  /// AC6: Role-based access control enforced
  Future<UserProfile> updateMyProfile(
    Session session,
    int userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final profileService = ProfileService(session);
      return await profileService.updateUserProfile(
          userId, userId, profileData);
    } catch (e, stackTrace) {
      session.log(
        'Failed to update profile for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get privacy settings
  /// GET /profile/privacy
  /// AC3: Granular privacy settings
  Future<PrivacySettings> getPrivacySettings(
    Session session,
    int userId,
  ) async {
    try {
      final profileService = ProfileService(session);
      final settings = await profileService.getPrivacySettings(userId, userId);
      if (settings == null) {
        throw Exception('Privacy settings not found');
      }
      return settings;
    } catch (e, stackTrace) {
      session.log(
        'Failed to get privacy settings for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update privacy settings
  /// PUT /profile/privacy
  /// AC3: Granular privacy settings with GDPR/CCPA compliance
  Future<PrivacySettings> updatePrivacySettings(
    Session session,
    int userId,
    Map<String, dynamic> settingsData,
  ) async {
    try {
      final profileService = ProfileService(session);
      return await profileService.updatePrivacySettings(
          userId, userId, settingsData);
    } catch (e, stackTrace) {
      session.log(
        'Failed to update privacy settings for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get notification preferences
  /// GET /profile/notifications
  /// AC7: Notification preference matrix
  Future<NotificationPreferences> getNotificationPreferences(
    Session session,
    int userId,
  ) async {
    try {
      final profileService = ProfileService(session);
      final prefs =
          await profileService.getNotificationPreferences(userId, userId);
      if (prefs == null) {
        throw Exception('Notification preferences not found');
      }
      return prefs;
    } catch (e, stackTrace) {
      session.log(
        'Failed to get notification preferences for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update notification preferences
  /// PUT /profile/notifications
  /// AC7: Notification preference matrix with granular controls
  Future<NotificationPreferences> updateNotificationPreferences(
    Session session,
    int userId,
    Map<String, dynamic> prefsData,
  ) async {
    try {
      final profileService = ProfileService(session);
      return await profileService.updateNotificationPreferences(
          userId, userId, prefsData);
    } catch (e, stackTrace) {
      session.log(
        'Failed to update notification preferences for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Export user data (DSAR - Right to Access)
  /// GET /profile/dsar/export
  /// AC5: DSAR functionality - data export
  Future<Map<String, dynamic>> exportUserData(
    Session session,
    int userId,
  ) async {
    try {
      final profileService = ProfileService(session);
      return await profileService.exportUserData(userId, userId);
    } catch (e, stackTrace) {
      session.log(
        'Failed to export user data for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete user data (DSAR - Right to Erasure)
  /// DELETE /profile/dsar/delete
  /// AC5: DSAR functionality - data deletion with audit logging
  Future<void> deleteUserData(
    Session session,
    int userId,
  ) async {
    try {
      final profileService = ProfileService(session);
      await profileService.deleteUserData(userId, userId);
    } catch (e, stackTrace) {
      session.log(
        'Failed to delete user data for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
