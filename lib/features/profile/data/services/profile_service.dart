import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../models/social_link_model.dart';

class ProfileService {
  final String _apiBaseUrl;
  final String _storageBaseUrl;

  ProfileService({
    required String apiBaseUrl,
    required String storageBaseUrl,
  })  : _apiBaseUrl = apiBaseUrl,
        _storageBaseUrl = storageBaseUrl;

  Future<UserProfileModel> getUserProfile(String userId) async {
    // Mock implementation - in real app, this would call API
    debugPrint('Getting profile for user: $userId');

    return UserProfileModel(
      id: 'profile_$userId',
      userId: userId,
      displayName: 'User $userId',
      bio: 'This is my bio',
      website: 'https://example.com',
      location: 'San Francisco, CA',
      birthDate: DateTime(1990, 1, 1),
      profilePhotoUrl: '$_storageBaseUrl/profiles/$userId/avatar.jpg',
      coverPhotoUrl: '$_storageBaseUrl/profiles/$userId/cover.jpg',
      visibility: ProfileVisibility.public,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  Future<UserProfileModel> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? website,
    String? location,
    DateTime? birthDate,
    ProfileVisibility? visibility,
  }) async {
    // Get current profile
    final currentProfile = await getUserProfile(userId);

    // Update with new values
    final updatedProfile = currentProfile.copyWith(
      displayName: displayName ?? currentProfile.displayName,
      bio: bio ?? currentProfile.bio,
      website: website ?? currentProfile.website,
      location: location ?? currentProfile.location,
      birthDate: birthDate ?? currentProfile.birthDate,
      visibility: visibility ?? currentProfile.visibility,
      updatedAt: DateTime.now(),
    );

    // Mock API call
    debugPrint('Updating profile: ${updatedProfile.toJson()}');

    return updatedProfile;
  }

  Future<String> uploadProfilePhoto({
    required String userId,
    required String filePath,
    required String mimeType,
  }) async {
    // Mock implementation - in real app, this would upload to S3/CloudFront
    final fileExtension = mimeType.split('/').last;
    final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final url = '$_storageBaseUrl/profiles/$userId/$fileName';

    debugPrint('Uploading profile photo: $fileName to $url');

    return url;
  }

  Future<String> uploadCoverImage({
    required String userId,
    required String filePath,
    required String mimeType,
  }) async {
    // Mock implementation
    final fileExtension = mimeType.split('/').last;
    final fileName = 'cover_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final url = '$_storageBaseUrl/profiles/$userId/$fileName';

    debugPrint('Uploading cover image: $fileName to $url');

    return url;
  }

  Future<bool> deleteProfileMedia({
    required String userId,
    required String mediaUrl,
    required ProfileMediaType type,
  }) async {
    // Mock implementation
    debugPrint('Deleting $type media for user $userId: $mediaUrl');
    return true;
  }

  Future<List<SocialLinkModel>> getSocialLinks(String userId) async {
    // Mock implementation
    return [
      SocialLinkModel(
        id: 'link_1',
        userId: userId,
        platform: SocialPlatform.twitter,
        url: 'https://twitter.com/user$userId',
        username: 'user$userId',
        displayOrder: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      SocialLinkModel(
        id: 'link_2',
        userId: userId,
        platform: SocialPlatform.github,
        url: 'https://github.com/user$userId',
        username: 'user$userId',
        isVerified: true,
        displayOrder: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  Future<SocialLinkModel> addSocialLink({
    required String userId,
    required SocialPlatform platform,
    required String url,
    String? username,
  }) async {
    final link = SocialLinkModel(
      id: 'link_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      platform: platform,
      url: url,
      username: username,
      displayOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    debugPrint('Adding social link: ${link.toJson()}');
    return link;
  }

  Future<SocialLinkModel> updateSocialLink({
    required String linkId,
    required String userId,
    required SocialPlatform platform,
    required String url,
    String? username,
    int? displayOrder,
  }) async {
    final link = SocialLinkModel(
      id: linkId,
      userId: userId,
      platform: platform,
      url: url,
      username: username,
      displayOrder: displayOrder ?? 0,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    );

    debugPrint('Updating social link: ${link.toJson()}');
    return link;
  }

  Future<bool> deleteSocialLink(String linkId, String userId) async {
    debugPrint('Deleting social link: $linkId for user: $userId');
    return true;
  }

  Future<bool> reorderSocialLinks({
    required String userId,
    required List<String> linkIds,
  }) async {
    debugPrint('Reordering social links for user $userId: $linkIds');
    return true;
  }

  Future<Map<String, dynamic>> exportProfileData(String userId) async {
    final profile = await getUserProfile(userId);
    final socialLinks = await getSocialLinks(userId);

    return {
      'profile': profile.toJson(),
      'social_links': socialLinks.map((link) => link.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
      'export_format': 'json',
    };
  }

  Future<bool> deleteAccount(String userId, String password) async {
    // Mock implementation - in real app, this would require proper verification
    debugPrint('Deleting account for user: $userId');

    // In real implementation, this would:
    // 1. Verify password
    // 2. Delete all user data
    // 3. Cancel subscriptions
    // 4. Send confirmation email
    // 5. Log the deletion for compliance

    return true;
  }

  bool validateUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  bool validateWebsite(String website) {
    if (website.isEmpty) return true;
    return validateUrl(website);
  }

  bool validateSocialUrl(SocialPlatform platform, String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme) return false;

      // Platform-specific validation
      switch (platform) {
        case SocialPlatform.twitter:
          return uri.host.contains('twitter.com');
        case SocialPlatform.instagram:
          return uri.host.contains('instagram.com');
        case SocialPlatform.facebook:
          return uri.host.contains('facebook.com');
        case SocialPlatform.linkedin:
          return uri.host.contains('linkedin.com');
        case SocialPlatform.youtube:
          return uri.host.contains('youtube.com');
        case SocialPlatform.github:
          return uri.host.contains('github.com');
        case SocialPlatform.website:
          return true;
        default:
          return true;
      }
    } catch (e) {
      return false;
    }
  }
}