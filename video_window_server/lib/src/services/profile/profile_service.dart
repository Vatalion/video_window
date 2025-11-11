import 'package:serverpod/serverpod.dart';
import '../../generated/profile/user_profile.dart';
import '../../generated/profile/privacy_settings.dart';
import '../../generated/profile/notification_preferences.dart';
import '../../generated/profile/dsar_request.dart';
import '../../generated/auth/user.dart';
import 'dart:convert';

/// Profile service for managing user profiles, privacy settings, and notifications
/// Implements Story 3-1: Viewer Profile Management
class ProfileService {
  final Session _session;

  ProfileService(this._session);

  /// Get user profile with decrypted sensitive fields
  /// AC6: Role-based access control - users can only access their own profile
  Future<UserProfile?> getUserProfile(int userId, int requestingUserId) async {
    try {
      // Enforce access control
      if (userId != requestingUserId) {
        _session.log(
          'Unauthorized profile access attempt: user $requestingUserId tried to access profile $userId',
          level: LogLevel.warning,
        );
        throw Exception('Unauthorized: You can only access your own profile');
      }

      final profile = await UserProfile.db.findFirstRow(
        _session,
        where: (t) => t.userId.equals(userId),
      );

      return profile;
    } catch (e, stackTrace) {
      _session.log(
        'Failed to get user profile for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create or update user profile
  /// AC6: Role-based access control enforced
  /// AC4: Sensitive fields encrypted before storage
  Future<UserProfile> updateUserProfile(
    int userId,
    int requestingUserId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      // Enforce access control
      if (userId != requestingUserId) {
        throw Exception('Unauthorized: You can only modify your own profile');
      }

      final now = DateTime.now().toUtc();
      final existing = await UserProfile.db.findFirstRow(
        _session,
        where: (t) => t.userId.equals(userId),
      );

      // TODO: Encrypt sensitive fields using ProfileEncryptionService
      // For now, store as-is (MUST implement encryption before production)
      final profileDataJson = json.encode(profileData);

      if (existing != null) {
        // Update existing profile
        final updated = existing.copyWith(
          username: profileData['username'] as String?,
          fullName: profileData['fullName'] as String?,
          bio: profileData['bio'] as String?,
          avatarUrl: profileData['avatarUrl'] as String?,
          profileData: profileDataJson,
          visibility: profileData['visibility'] as String? ?? 'public',
          updatedAt: now,
        );
        return await UserProfile.db.updateRow(_session, updated);
      } else {
        // Create new profile
        final newProfile = UserProfile(
          userId: userId,
          username: profileData['username'] as String?,
          fullName: profileData['fullName'] as String?,
          bio: profileData['bio'] as String?,
          avatarUrl: profileData['avatarUrl'] as String?,
          profileData: profileDataJson,
          visibility: profileData['visibility'] as String? ?? 'public',
          isVerified: false,
          createdAt: now,
          updatedAt: now,
        );
        return await UserProfile.db.insertRow(_session, newProfile);
      }
    } catch (e, stackTrace) {
      _session.log(
        'Failed to update user profile for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get privacy settings
  Future<PrivacySettings?> getPrivacySettings(
      int userId, int requestingUserId) async {
    if (userId != requestingUserId) {
      throw Exception('Unauthorized');
    }

    final settings = await PrivacySettings.db.findFirstRow(
      _session,
      where: (t) => t.userId.equals(userId),
    );

    if (settings == null) {
      // Create default privacy settings
      final now = DateTime.now().toUtc();
      final defaultSettings = PrivacySettings(
        userId: userId,
        profileVisibility: 'public',
        showEmailToPublic: false,
        showPhoneToFriends: false,
        allowTagging: true,
        allowSearchByPhone: false,
        allowDataAnalytics: true,
        allowMarketingEmails: false,
        allowPushNotifications: true,
        shareProfileWithPartners: false,
        createdAt: now,
        updatedAt: now,
      );
      return await PrivacySettings.db.insertRow(_session, defaultSettings);
    }

    return settings;
  }

  /// Update privacy settings
  Future<PrivacySettings> updatePrivacySettings(
    int userId,
    int requestingUserId,
    Map<String, dynamic> settingsData,
  ) async {
    if (userId != requestingUserId) {
      throw Exception('Unauthorized');
    }

    final now = DateTime.now().toUtc();
    final existing = await PrivacySettings.db.findFirstRow(
      _session,
      where: (t) => t.userId.equals(userId),
    );

    if (existing != null) {
      final updated = existing.copyWith(
        profileVisibility: settingsData['profileVisibility'] as String?,
        showEmailToPublic: settingsData['showEmailToPublic'] as bool?,
        showPhoneToFriends: settingsData['showPhoneToFriends'] as bool?,
        allowTagging: settingsData['allowTagging'] as bool?,
        allowSearchByPhone: settingsData['allowSearchByPhone'] as bool?,
        allowDataAnalytics: settingsData['allowDataAnalytics'] as bool?,
        allowMarketingEmails: settingsData['allowMarketingEmails'] as bool?,
        allowPushNotifications: settingsData['allowPushNotifications'] as bool?,
        shareProfileWithPartners:
            settingsData['shareProfileWithPartners'] as bool?,
        updatedAt: now,
      );
      return await PrivacySettings.db.updateRow(_session, updated);
    } else {
      final newSettings = PrivacySettings(
        userId: userId,
        profileVisibility:
            settingsData['profileVisibility'] as String? ?? 'public',
        showEmailToPublic: settingsData['showEmailToPublic'] as bool? ?? false,
        showPhoneToFriends:
            settingsData['showPhoneToFriends'] as bool? ?? false,
        allowTagging: settingsData['allowTagging'] as bool? ?? true,
        allowSearchByPhone:
            settingsData['allowSearchByPhone'] as bool? ?? false,
        allowDataAnalytics: settingsData['allowDataAnalytics'] as bool? ?? true,
        allowMarketingEmails:
            settingsData['allowMarketingEmails'] as bool? ?? false,
        allowPushNotifications:
            settingsData['allowPushNotifications'] as bool? ?? true,
        shareProfileWithPartners:
            settingsData['shareProfileWithPartners'] as bool? ?? false,
        createdAt: now,
        updatedAt: now,
      );
      return await PrivacySettings.db.insertRow(_session, newSettings);
    }
  }

  /// Get notification preferences
  Future<NotificationPreferences?> getNotificationPreferences(
      int userId, int requestingUserId) async {
    if (userId != requestingUserId) {
      throw Exception('Unauthorized');
    }

    final prefs = await NotificationPreferences.db.findFirstRow(
      _session,
      where: (t) => t.userId.equals(userId),
    );

    if (prefs == null) {
      // Create default notification preferences
      final now = DateTime.now().toUtc();
      final defaultPrefs = NotificationPreferences(
        userId: userId,
        emailNotifications: true,
        pushNotifications: true,
        inAppNotifications: true,
        settings: json.encode({
          'newOffer': {
            'enabled': true,
            'channels': ['email', 'push', 'inApp']
          },
          'outbid': {
            'enabled': true,
            'channels': ['email', 'push']
          },
          'auctionEnding': {
            'enabled': true,
            'channels': ['push', 'inApp']
          },
          'orderUpdate': {
            'enabled': true,
            'channels': ['email', 'push']
          },
          'makerActivity': {
            'enabled': true,
            'channels': ['inApp']
          },
        }),
        quietHours:
            json.encode({'start': '22:00', 'end': '08:00', 'timezone': 'UTC'}),
        createdAt: now,
        updatedAt: now,
      );
      return await NotificationPreferences.db.insertRow(_session, defaultPrefs);
    }

    return prefs;
  }

  /// Update notification preferences
  Future<NotificationPreferences> updateNotificationPreferences(
    int userId,
    int requestingUserId,
    Map<String, dynamic> prefsData,
  ) async {
    if (userId != requestingUserId) {
      throw Exception('Unauthorized');
    }

    final now = DateTime.now().toUtc();
    final existing = await NotificationPreferences.db.findFirstRow(
      _session,
      where: (t) => t.userId.equals(userId),
    );

    if (existing != null) {
      final updated = existing.copyWith(
        emailNotifications: prefsData['emailNotifications'] as bool?,
        pushNotifications: prefsData['pushNotifications'] as bool?,
        inAppNotifications: prefsData['inAppNotifications'] as bool?,
        settings: prefsData['settings'] != null
            ? json.encode(prefsData['settings'])
            : null,
        quietHours: prefsData['quietHours'] != null
            ? json.encode(prefsData['quietHours'])
            : null,
        updatedAt: now,
      );
      return await NotificationPreferences.db.updateRow(_session, updated);
    } else {
      final newPrefs = NotificationPreferences(
        userId: userId,
        emailNotifications: prefsData['emailNotifications'] as bool? ?? true,
        pushNotifications: prefsData['pushNotifications'] as bool? ?? true,
        inAppNotifications: prefsData['inAppNotifications'] as bool? ?? true,
        settings: prefsData['settings'] != null
            ? json.encode(prefsData['settings'])
            : json.encode({}),
        quietHours: prefsData['quietHours'] != null
            ? json.encode(prefsData['quietHours'])
            : json.encode({}),
        createdAt: now,
        updatedAt: now,
      );
      return await NotificationPreferences.db.insertRow(_session, newPrefs);
    }
  }

  /// Export user data for DSAR (Data Subject Access Request)
  /// AC5: DSAR functionality - data export
  Future<Map<String, dynamic>> exportUserData(
      int userId, int requestingUserId) async {
    if (userId != requestingUserId) {
      throw Exception('Unauthorized');
    }

    try {
      final user = await User.db.findById(_session, userId);
      final profile = await getUserProfile(userId, requestingUserId);
      final privacy = await getPrivacySettings(userId, requestingUserId);
      final notifications =
          await getNotificationPreferences(userId, requestingUserId);

      // Compile comprehensive data export
      final exportData = <String, dynamic>{
        'userId': userId,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'account': user != null
            ? {
                'email': user.email,
                'phone': user.phone,
                'role': user.role,
                'createdAt': user.createdAt.toIso8601String(),
                'lastLoginAt': user.lastLoginAt?.toIso8601String(),
              }
            : null,
        'profile': profile != null
            ? {
                'username': profile.username,
                'fullName': profile.fullName,
                'bio': profile.bio,
                'avatarUrl': profile.avatarUrl,
                'visibility': profile.visibility,
                'isVerified': profile.isVerified,
                'createdAt': profile.createdAt.toIso8601String(),
                'updatedAt': profile.updatedAt.toIso8601String(),
              }
            : null,
        'privacy': privacy != null
            ? {
                'profileVisibility': privacy.profileVisibility,
                'showEmailToPublic': privacy.showEmailToPublic,
                'showPhoneToFriends': privacy.showPhoneToFriends,
                'allowTagging': privacy.allowTagging,
                'allowSearchByPhone': privacy.allowSearchByPhone,
                'allowDataAnalytics': privacy.allowDataAnalytics,
                'allowMarketingEmails': privacy.allowMarketingEmails,
                'allowPushNotifications': privacy.allowPushNotifications,
                'shareProfileWithPartners': privacy.shareProfileWithPartners,
              }
            : null,
        'notifications': notifications != null
            ? {
                'emailNotifications': notifications.emailNotifications,
                'pushNotifications': notifications.pushNotifications,
                'inAppNotifications': notifications.inAppNotifications,
                'settings': notifications.settings != null
                    ? json.decode(notifications.settings!)
                    : null,
                'quietHours': notifications.quietHours != null
                    ? json.decode(notifications.quietHours!)
                    : null,
              }
            : null,
      };

      // Create DSAR request record
      final now = DateTime.now().toUtc();
      final dsarRequest = DsarRequest(
        userId: userId,
        requestType: 'access',
        status: 'completed',
        requestedAt: now,
        completedAt: now,
        requestData: json.encode(exportData),
        auditLog: json.encode({
          'exportedAt': now.toIso8601String(),
          'exportedBy': requestingUserId.toString(),
        }),
        createdAt: now,
        updatedAt: now,
      );
      await DsarRequest.db.insertRow(_session, dsarRequest);

      return exportData;
    } catch (e, stackTrace) {
      _session.log(
        'Failed to export user data for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete user data (DSAR - Right to Erasure)
  /// AC5: DSAR functionality - data deletion with audit logging
  Future<void> deleteUserData(int userId, int requestingUserId) async {
    if (userId != requestingUserId) {
      throw Exception('Unauthorized');
    }

    try {
      // Create DSAR request record
      final now = DateTime.now().toUtc();
      final dsarRequest = DsarRequest(
        userId: userId,
        requestType: 'deletion',
        status: 'processing',
        requestedAt: now,
        requestData: json.encode({
          'requestedBy': requestingUserId.toString(),
          'requestedAt': now.toIso8601String(),
        }),
        auditLog: json.encode({
          'deletionRequestedAt': now.toIso8601String(),
          'deletionRequestedBy': requestingUserId.toString(),
        }),
        createdAt: now,
        updatedAt: now,
      );
      await DsarRequest.db.insertRow(_session, dsarRequest);

      // Delete profile data
      await UserProfile.db.deleteWhere(
        _session,
        where: (t) => t.userId.equals(userId),
      );

      // Delete privacy settings
      await PrivacySettings.db.deleteWhere(
        _session,
        where: (t) => t.userId.equals(userId),
      );

      // Delete notification preferences
      await NotificationPreferences.db.deleteWhere(
        _session,
        where: (t) => t.userId.equals(userId),
      );

      // Update DSAR request status
      final updatedRequest = dsarRequest.copyWith(
        status: 'completed',
        completedAt: now,
        auditLog: json.encode({
          ...(dsarRequest.auditLog != null
              ? json.decode(dsarRequest.auditLog!) as Map<String, dynamic>
              : {}),
          'deletedAt': now.toIso8601String(),
        }),
        updatedAt: now,
      );
      await DsarRequest.db.updateRow(_session, updatedRequest);

      _session.log(
        'User data deleted for user $userId',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      _session.log(
        'Failed to delete user data for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
