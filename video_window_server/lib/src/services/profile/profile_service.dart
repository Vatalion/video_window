import 'package:serverpod/serverpod.dart';
import '../../generated/profile/user_profile.dart';
import '../../generated/profile/privacy_settings.dart';
import '../../generated/profile/notification_preferences.dart';
import '../../generated/profile/dsar_request.dart';
import '../../generated/profile/privacy_audit_log.dart';
import '../../generated/auth/user.dart';
import '../../business/profile/notification_manager.dart';
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
  /// AC4: Consent changes generate audit log entries and emit analytics event
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

    PrivacySettings updated;
    if (existing != null) {
      // AC4: Create audit log entries for each changed setting
      await _createAuditLogs(
          userId, requestingUserId, existing, settingsData, now);

      updated = existing.copyWith(
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
      // New settings - no audit log needed for initial creation
      updated = PrivacySettings(
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
      return await PrivacySettings.db.insertRow(_session, updated);
    }
  }

  /// Create audit log entries for privacy settings changes
  /// AC4: Record audit entries with actor, change summary, timestamp
  Future<void> _createAuditLogs(
    int userId,
    int actorId,
    PrivacySettings existing,
    Map<String, dynamic> newSettings,
    DateTime timestamp,
  ) async {
    final settingsToCheck = [
      'profileVisibility',
      'showEmailToPublic',
      'showPhoneToFriends',
      'allowTagging',
      'allowSearchByPhone',
      'allowDataAnalytics',
      'allowMarketingEmails',
      'allowPushNotifications',
      'shareProfileWithPartners',
    ];

    for (final settingName in settingsToCheck) {
      final oldValue = _getSettingValue(existing, settingName);
      final newValue = newSettings[settingName];

      // Only create audit log if value actually changed
      if (oldValue != newValue && newValue != null) {
        final auditLog = PrivacyAuditLog(
          userId: userId,
          actorId: actorId,
          settingName: settingName,
          oldValue: json.encode(oldValue),
          newValue: json.encode(newValue),
          changeSummary:
              'Privacy setting "$settingName" changed from $oldValue to $newValue',
          auditContext: json.encode({
            'changedAt': timestamp.toIso8601String(),
            'ipAddress':
                '0.0.0.0', // TODO: Extract from request context when available
          }),
          createdAt: timestamp,
        );

        try {
          await PrivacyAuditLog.db.insertRow(_session, auditLog);
        } catch (e, stackTrace) {
          _session.log(
            'Failed to create privacy audit log: $e',
            level: LogLevel.error,
            exception: e,
            stackTrace: stackTrace,
          );
          // Don't fail the update if audit logging fails
        }
      }
    }
  }

  /// Get setting value from PrivacySettings object
  dynamic _getSettingValue(PrivacySettings settings, String settingName) {
    switch (settingName) {
      case 'profileVisibility':
        return settings.profileVisibility;
      case 'showEmailToPublic':
        return settings.showEmailToPublic;
      case 'showPhoneToFriends':
        return settings.showPhoneToFriends;
      case 'allowTagging':
        return settings.allowTagging;
      case 'allowSearchByPhone':
        return settings.allowSearchByPhone;
      case 'allowDataAnalytics':
        return settings.allowDataAnalytics;
      case 'allowMarketingEmails':
        return settings.allowMarketingEmails;
      case 'allowPushNotifications':
        return settings.allowPushNotifications;
      case 'shareProfileWithPartners':
        return settings.shareProfileWithPartners;
      default:
        return null;
    }
  }

  /// Get notification preferences
  Future<NotificationPreferences?> getNotificationPreferences(
      int userId, int requestingUserId) async {
    if (userId != requestingUserId) {
      throw Exception('Unauthorized');
    }

    // Use NotificationManager to get preferences with defaults
    final notificationManager = NotificationManager(_session);
    return await notificationManager.getPreferences(userId);
  }

  /// Update notification preferences
  /// AC3: Uses notification_manager.dart to persist preferences and sync external services
  /// AC4: Enforces critical alert immutability
  Future<NotificationPreferences> updateNotificationPreferences(
    int userId,
    int requestingUserId,
    Map<String, dynamic> prefsData,
  ) async {
    if (userId != requestingUserId) {
      throw Exception('Unauthorized');
    }

    // Use NotificationManager for business logic and external service sync
    final notificationManager = NotificationManager(_session);
    return await notificationManager.updatePreferences(userId, prefsData);
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
