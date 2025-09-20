import '../services/profile_service.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/profile_media.dart';
import '../../domain/models/social_link.dart';
import '../../domain/models/privacy_setting.dart';
import '../../domain/models/notification_preference.dart';

class ProfileRepository {
  final ProfileService _service = ProfileService();

  Future<UserProfile?> getUserProfile(String userId) async {
    return await _service.getUserProfile(userId);
  }

  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    _service.validateProfileData(profile);
    return await _service.updateUserProfile(profile);
  }

  Future<ProfileMedia?> getProfileMedia(String userId, ProfileMediaType type) async {
    return await _service.getProfileMedia(userId, type);
  }

  Future<ProfileMedia> uploadProfileMedia(
    String userId,
    ProfileMediaType type,
    String filePath,
  ) async {
    return await _service.uploadProfileMedia(userId, type, filePath);
  }

  Future<List<SocialLink>> getSocialLinks(String userId) async {
    return await _service.getSocialLinks(userId);
  }

  Future<SocialLink> addSocialLink(SocialLink link) async {
    return await _service.addSocialLink(link);
  }

  Future<PrivacySetting> getPrivacySettings(String userId) async {
    return await _service.getPrivacySettings(userId);
  }

  Future<PrivacySetting> updatePrivacySettings(PrivacySetting settings) async {
    return await _service.updatePrivacySettings(settings);
  }

  Future<List<NotificationPreference>> getNotificationPreferences(String userId) async {
    return await _service.getNotificationPreferences(userId);
  }

  Future<NotificationPreference> updateNotificationPreference(
    NotificationPreference preference,
  ) async {
    return await _service.updateNotificationPreference(preference);
  }

  Future<Map<String, dynamic>> exportUserData(String userId) async {
    return await _service.exportUserData(userId);
  }

  Future<bool> deleteAccount(String userId) async {
    return await _service.deleteAccount(userId);
  }
}