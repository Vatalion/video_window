import 'package:video_window_client/video_window_client.dart' show Client;
import 'dart:convert';

/// Repository for profile management
/// Implements data layer for Story 3-1: Viewer Profile Management
class ProfileRepository {
  final Client _client;

  ProfileRepository(this._client);

  /// Get current user profile
  /// AC1: Complete profile management interface
  Future<Map<String, dynamic>?> getMyProfile(int userId) async {
    try {
      final profile = await _client.profile.getMyProfile(userId);
      if (profile == null) return null;

      // Parse profileData JSON string if present
      final profileData = profile.profileData != null
          ? json.decode(profile.profileData!) as Map<String, dynamic>
          : <String, dynamic>{};

      return {
        'id': profile.id,
        'userId': profile.userId,
        'username': profile.username,
        'fullName': profile.fullName,
        'bio': profile.bio,
        'avatarUrl': profile.avatarUrl,
        'visibility': profile.visibility,
        'isVerified': profile.isVerified,
        'profileData': profileData,
        'createdAt': profile.createdAt.toIso8601String(),
        'updatedAt': profile.updatedAt.toIso8601String(),
      };
    } catch (e) {
      throw ProfileRepositoryException('Failed to get profile: $e');
    }
  }

  /// Update current user profile
  /// AC1: Complete profile management interface with validation
  /// AC4: Sensitive PII data encrypted at rest
  Future<Map<String, dynamic>> updateMyProfile(
    int userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final profile =
          await _client.profile.updateMyProfile(userId, profileData);

      final profileDataMap = profile.profileData != null
          ? json.decode(profile.profileData!) as Map<String, dynamic>
          : <String, dynamic>{};

      return {
        'id': profile.id,
        'userId': profile.userId,
        'username': profile.username,
        'fullName': profile.fullName,
        'bio': profile.bio,
        'avatarUrl': profile.avatarUrl,
        'visibility': profile.visibility,
        'isVerified': profile.isVerified,
        'profileData': profileDataMap,
        'createdAt': profile.createdAt.toIso8601String(),
        'updatedAt': profile.updatedAt.toIso8601String(),
      };
    } catch (e) {
      throw ProfileRepositoryException('Failed to update profile: $e');
    }
  }

  /// Get privacy settings
  /// AC3: Granular privacy settings
  Future<Map<String, dynamic>> getPrivacySettings(int userId) async {
    try {
      final settings = await _client.profile.getPrivacySettings(userId);
      return {
        'id': settings.id,
        'userId': settings.userId,
        'profileVisibility': settings.profileVisibility,
        'showEmailToPublic': settings.showEmailToPublic,
        'showPhoneToFriends': settings.showPhoneToFriends,
        'allowTagging': settings.allowTagging,
        'allowSearchByPhone': settings.allowSearchByPhone,
        'allowDataAnalytics': settings.allowDataAnalytics,
        'allowMarketingEmails': settings.allowMarketingEmails,
        'allowPushNotifications': settings.allowPushNotifications,
        'shareProfileWithPartners': settings.shareProfileWithPartners,
        'createdAt': settings.createdAt.toIso8601String(),
        'updatedAt': settings.updatedAt.toIso8601String(),
      };
    } catch (e) {
      throw ProfileRepositoryException('Failed to get privacy settings: $e');
    }
  }

  /// Update privacy settings
  /// AC3: Granular privacy settings with GDPR/CCPA compliance
  Future<Map<String, dynamic>> updatePrivacySettings(
    int userId,
    Map<String, dynamic> settingsData,
  ) async {
    try {
      final settings =
          await _client.profile.updatePrivacySettings(userId, settingsData);
      return {
        'id': settings.id,
        'userId': settings.userId,
        'profileVisibility': settings.profileVisibility,
        'showEmailToPublic': settings.showEmailToPublic,
        'showPhoneToFriends': settings.showPhoneToFriends,
        'allowTagging': settings.allowTagging,
        'allowSearchByPhone': settings.allowSearchByPhone,
        'allowDataAnalytics': settings.allowDataAnalytics,
        'allowMarketingEmails': settings.allowMarketingEmails,
        'allowPushNotifications': settings.allowPushNotifications,
        'shareProfileWithPartners': settings.shareProfileWithPartners,
        'createdAt': settings.createdAt.toIso8601String(),
        'updatedAt': settings.updatedAt.toIso8601String(),
      };
    } catch (e) {
      throw ProfileRepositoryException('Failed to update privacy settings: $e');
    }
  }

  /// Get notification preferences
  /// AC7: Notification preference matrix
  Future<Map<String, dynamic>> getNotificationPreferences(int userId) async {
    try {
      final prefs = await _client.profile.getNotificationPreferences(userId);

      final settings = prefs.settings != null
          ? json.decode(prefs.settings!) as Map<String, dynamic>
          : <String, dynamic>{};

      final quietHours = prefs.quietHours != null
          ? json.decode(prefs.quietHours!) as Map<String, dynamic>
          : <String, dynamic>{};

      return {
        'id': prefs.id,
        'userId': prefs.userId,
        'emailNotifications': prefs.emailNotifications,
        'pushNotifications': prefs.pushNotifications,
        'inAppNotifications': prefs.inAppNotifications,
        'settings': settings,
        'quietHours': quietHours,
        'createdAt': prefs.createdAt.toIso8601String(),
        'updatedAt': prefs.updatedAt.toIso8601String(),
      };
    } catch (e) {
      throw ProfileRepositoryException(
          'Failed to get notification preferences: $e');
    }
  }

  /// Update notification preferences
  /// AC7: Notification preference matrix with granular controls
  Future<Map<String, dynamic>> updateNotificationPreferences(
    int userId,
    Map<String, dynamic> prefsData,
  ) async {
    try {
      final prefs = await _client.profile
          .updateNotificationPreferences(userId, prefsData);

      final settings = prefs.settings != null
          ? json.decode(prefs.settings!) as Map<String, dynamic>
          : <String, dynamic>{};

      final quietHours = prefs.quietHours != null
          ? json.decode(prefs.quietHours!) as Map<String, dynamic>
          : <String, dynamic>{};

      return {
        'id': prefs.id,
        'userId': prefs.userId,
        'emailNotifications': prefs.emailNotifications,
        'pushNotifications': prefs.pushNotifications,
        'inAppNotifications': prefs.inAppNotifications,
        'settings': settings,
        'quietHours': quietHours,
        'createdAt': prefs.createdAt.toIso8601String(),
        'updatedAt': prefs.updatedAt.toIso8601String(),
      };
    } catch (e) {
      throw ProfileRepositoryException(
          'Failed to update notification preferences: $e');
    }
  }

  /// Export user data (DSAR - Right to Access)
  /// AC5: DSAR functionality - data export
  Future<Map<String, dynamic>> exportUserData(int userId) async {
    try {
      return await _client.profile.exportUserData(userId);
    } catch (e) {
      throw ProfileRepositoryException('Failed to export user data: $e');
    }
  }

  /// Delete user data (DSAR - Right to Erasure)
  /// AC5: DSAR functionality - data deletion with audit logging
  Future<void> deleteUserData(int userId) async {
    try {
      await _client.profile.deleteUserData(userId);
    } catch (e) {
      throw ProfileRepositoryException('Failed to delete user data: $e');
    }
  }
}

/// Exception for profile repository errors
class ProfileRepositoryException implements Exception {
  final String message;
  ProfileRepositoryException(this.message);

  @override
  String toString() => 'ProfileRepositoryException: $message';
}
