import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/profile_media.dart';
import '../../domain/models/social_link.dart';
import '../../domain/models/privacy_setting.dart';
import '../../domain/models/notification_preference.dart';

class ProfileService {
  // Mock service implementation - in real app this would connect to backend

  Future<UserProfile?> getUserProfile(String userId) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock data
    return UserProfile(
      userId: userId,
      displayName: 'John Doe',
      bio: 'Flutter developer and tech enthusiast',
      website: 'https://johndoe.com',
      location: 'San Francisco, CA',
      birthDate: DateTime(1990, 5, 15),
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Return updated profile with new timestamp
    return profile.copyWith(updatedAt: DateTime.now());
  }

  Future<ProfileMedia?> getProfileMedia(String userId, ProfileMediaType type) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    // Return mock data
    return ProfileMedia(
      userId: userId,
      mediaType: type,
      mediaUrl: 'https://example.com/media/${type.name}_$userId.jpg',
      uploadedAt: DateTime.now().subtract(const Duration(days: 60)),
    );
  }

  Future<ProfileMedia> uploadProfileMedia(
    String userId,
    ProfileMediaType type,
    String filePath,
  ) async {
    // Simulate upload
    await Future.delayed(const Duration(seconds: 2));

    return ProfileMedia(
      userId: userId,
      mediaType: type,
      mediaUrl: 'https://example.com/media/${type.name}_$userId.jpg',
      uploadedAt: DateTime.now(),
    );
  }

  Future<List<SocialLink>> getSocialLinks(String userId) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    // Return mock data
    return [
      SocialLink(
        userId: userId,
        platform: SocialPlatform.twitter,
        url: 'https://twitter.com/johndoe',
        displayOrder: 0,
      ),
      SocialLink(
        userId: userId,
        platform: SocialPlatform.github,
        url: 'https://github.com/johndoe',
        displayOrder: 1,
      ),
    ];
  }

  Future<SocialLink> addSocialLink(SocialLink link) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    return link.copyWith(verified: true);
  }

  Future<PrivacySetting> getPrivacySettings(String userId) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    return PrivacySetting(
      userId: userId,
      profileVisibility: ProfileVisibility.public,
      allowDataSharing: true,
      searchVisibility: SearchVisibility.visible,
      updatedAt: DateTime.now().subtract(const Duration(days: 15)),
    );
  }

  Future<PrivacySetting> updatePrivacySettings(PrivacySetting settings) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    return settings.copyWith();
  }

  Future<List<NotificationPreference>> getNotificationPreferences(String userId) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    return NotificationType.values.map((type) {
      return NotificationPreference(
        userId: userId,
        notificationType: type,
        enabled: true,
        deliveryMethods: {DeliveryMethod.push, DeliveryMethod.inApp},
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      );
    }).toList();
  }

  Future<NotificationPreference> updateNotificationPreference(
    NotificationPreference preference,
  ) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    return preference.copyWith();
  }

  Future<Map<String, dynamic>> exportUserData(String userId) async {
    // Simulate data export
    await Future.delayed(const Duration(seconds: 2));

    // Return mock export data
    return {
      'userId': userId,
      'profile': {
        'displayName': 'John Doe',
        'bio': 'Flutter developer and tech enthusiast',
        'location': 'San Francisco, CA',
      },
      'socialLinks': [
        {
          'platform': 'twitter',
          'url': 'https://twitter.com/johndoe',
        },
      ],
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<bool> deleteAccount(String userId) async {
    // Simulate account deletion
    await Future.delayed(const Duration(seconds: 2));

    return true; // Return success
  }

  void validateProfileData(UserProfile profile) {
    if (profile.displayName.trim().isEmpty) {
      throw const FormatException('Display name cannot be empty');
    }

    if (profile.displayName.length > 50) {
      throw const FormatException('Display name must be less than 50 characters');
    }

    if (profile.bio != null && profile.bio!.length > 500) {
      throw const FormatException('Bio must be less than 500 characters');
    }

    if (profile.website != null && profile.website!.isNotEmpty) {
      if (!_isValidUrl(profile.website!)) {
        throw const FormatException('Invalid website URL');
      }
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}