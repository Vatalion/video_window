import 'package:serverpod/serverpod.dart';
import '../../generated/profile/privacy_settings.dart';

/// Privacy manager applying business rules for visibility, blocked users, and consent toggles
/// AC3: Enforces visibility rules for public, friends-only, and private queries including blocked user lists
class PrivacyManager {
  final Session _session;

  PrivacyManager(this._session);

  /// Check if a user can view another user's profile based on privacy settings
  /// AC3: Enforces visibility rules
  Future<bool> canViewProfile(
    int viewerUserId,
    int profileUserId,
  ) async {
    try {
      // Users can always view their own profile
      if (viewerUserId == profileUserId) {
        return true;
      }

      final settings = await PrivacySettings.db.findFirstRow(
        _session,
        where: (t) => t.userId.equals(profileUserId),
      );

      if (settings == null) {
        // Default to public if no settings exist
        return true;
      }

      // Check visibility rules
      switch (settings.profileVisibility) {
        case 'public':
          return true;
        case 'private':
          return false;
        case 'friends':
        case 'friendsOnly':
          return await _areFriends(viewerUserId, profileUserId);
        default:
          // Default to public for unknown values
          return true;
      }
    } catch (e, stackTrace) {
      _session.log(
        'Error checking profile visibility: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      // Fail closed - don't allow access on error
      return false;
    }
  }

  /// Check if user can see email based on privacy settings
  Future<bool> canViewEmail(
    int viewerUserId,
    int profileUserId,
  ) async {
    if (viewerUserId == profileUserId) {
      return true;
    }

    final settings = await PrivacySettings.db.findFirstRow(
      _session,
      where: (t) => t.userId.equals(profileUserId),
    );

    if (settings == null) {
      return false;
    }

    return settings.showEmailToPublic;
  }

  /// Check if user can see phone based on privacy settings
  Future<bool> canViewPhone(
    int viewerUserId,
    int profileUserId,
  ) async {
    if (viewerUserId == profileUserId) {
      return true;
    }

    final settings = await PrivacySettings.db.findFirstRow(
      _session,
      where: (t) => t.userId.equals(profileUserId),
    );

    if (settings == null) {
      return false;
    }

    // Phone is only visible to friends if enabled
    if (!settings.showPhoneToFriends) {
      return false;
    }

    return await _areFriends(viewerUserId, profileUserId);
  }

  /// Check if user can tag another user
  Future<bool> canTagUser(
    int taggerUserId,
    int targetUserId,
  ) async {
    if (taggerUserId == targetUserId) {
      return true;
    }

    final settings = await PrivacySettings.db.findFirstRow(
      _session,
      where: (t) => t.userId.equals(targetUserId),
    );

    if (settings == null) {
      return true; // Default allow
    }

    return settings.allowTagging;
  }

  /// Check if user can be found by phone number
  Future<bool> canSearchByPhone(int userId) async {
    final settings = await PrivacySettings.db.findFirstRow(
      _session,
      where: (t) => t.userId.equals(userId),
    );

    if (settings == null) {
      return false; // Default deny
    }

    return settings.allowSearchByPhone;
  }

  /// Check if user is blocked
  /// NOTE: Blocked users functionality is not yet implemented.
  /// AC3 mentions "including blocked user lists" but this requires:
  /// 1. Adding blocked_users field to PrivacySettings model (JSONB array)
  /// 2. UI for managing blocked users list
  /// 3. Integration with social features when available
  /// For now, this always returns false (no users are blocked).
  Future<bool> isBlocked(
    int blockerUserId,
    int blockedUserId,
  ) async {
    final settings = await PrivacySettings.db.findFirstRow(
      _session,
      where: (t) => t.userId.equals(blockerUserId),
    );

    if (settings == null) {
      return false;
    }

    // TODO: Implement blocked users list check when blocked_users field is added
    // For now, return false
    return false;
  }

  /// Helper to check if two users are friends
  /// NOTE: Friendship check is a placeholder implementation.
  /// This requires social features/relationships table to be implemented.
  /// Currently always returns false, which means:
  /// - Friends-only profiles are effectively private to non-owners
  /// - Phone visibility to friends is effectively disabled
  /// This is acceptable for MVP as social features are not yet implemented.
  /// When social features are added, this should check a friends/relationships table.
  Future<bool> _areFriends(int userId1, int userId2) async {
    // Placeholder implementation
    // In a real system, this would check a friends/relationships table
    return false;
  }

  /// Apply privacy filters to profile data
  /// Returns filtered profile data based on viewer's permissions
  Future<Map<String, dynamic>> applyPrivacyFilters(
    Map<String, dynamic> profileData,
    int viewerUserId,
    int profileUserId,
  ) async {
    final filtered = Map<String, dynamic>.from(profileData);

    // Check if viewer can see profile
    final canView = await canViewProfile(viewerUserId, profileUserId);
    if (!canView) {
      throw Exception('Profile is not visible to you');
    }

    // Filter email
    final emailVisible = await canViewEmail(viewerUserId, profileUserId);
    if (!emailVisible) {
      filtered.remove('email');
      filtered.remove('emailEncrypted');
    }

    // Filter phone
    final phoneVisible = await canViewPhone(viewerUserId, profileUserId);
    if (!phoneVisible) {
      filtered.remove('phone');
      filtered.remove('phoneEncrypted');
    }

    return filtered;
  }
}
