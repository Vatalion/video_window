import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/profile/data/services/profile_service.dart';
import 'package:video_window/features/profile/domain/models/user_profile_model.dart';
import 'package:video_window/features/profile/domain/models/social_link_model.dart';

class MockProfileService extends ProfileService {
  MockProfileService() : super(
    apiBaseUrl: 'https://api.example.com',
    storageBaseUrl: 'https://storage.example.com',
  );

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    return UserProfileModel(
      id: 'test_profile_$userId',
      userId: userId,
      displayName: 'Test User $userId',
      bio: 'This is a test bio',
      website: 'https://test.com',
      location: 'Test City',
      birthDate: DateTime(1990, 1, 1),
      profilePhotoUrl: 'https://storage.example.com/profiles/$userId/avatar.jpg',
      coverPhotoUrl: 'https://storage.example.com/profiles/$userId/cover.jpg',
      visibility: ProfileVisibility.public,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<bool> validateUrl(String url) {
    return super.validateUrl(url);
  }

  @override
  Future<bool> validateSocialUrl(SocialPlatform platform, String url) {
    return super.validateSocialUrl(platform, url);
  }
}

void main() {
  group('ProfileService Tests', () {
    late ProfileService profileService;

    setUp(() {
      profileService = MockProfileService();
    });

    group('getUserProfile', () {
      test('should return user profile with valid data', () async {
        // Act
        final profile = await profileService.getUserProfile('test_user_123');

        // Assert
        expect(profile.userId, equals('test_user_123'));
        expect(profile.displayName, equals('Test User test_user_123'));
        expect(profile.bio, equals('This is a test bio'));
        expect(profile.website, equals('https://test.com'));
        expect(profile.location, equals('Test City'));
        expect(profile.birthDate, isNotNull);
        expect(profile.visibility, equals(ProfileVisibility.public));
        expect(profile.profilePhotoUrl, isNotNull);
        expect(profile.coverPhotoUrl, isNotNull);
      });

      test('should generate unique profile ID for different users', () async {
        // Act
        final profile1 = await profileService.getUserProfile('user1');
        final profile2 = await profileService.getUserProfile('user2');

        // Assert
        expect(profile1.id, isNot(equals(profile2.id)));
        expect(profile1.userId, isNot(equals(profile2.userId)));
      });
    });

    group('updateProfile', () {
      test('should update profile with new values', () async {
        // Arrange
        final userId = 'test_user';
        await profileService.getUserProfile(userId);

        // Act
        final updatedProfile = await profileService.updateProfile(
          userId: userId,
          displayName: 'Updated Name',
          bio: 'Updated bio',
          website: 'https://updated.com',
          location: 'Updated Location',
          birthDate: DateTime(1995, 5, 15),
          visibility: ProfileVisibility.private,
        );

        // Assert
        expect(updatedProfile.displayName, equals('Updated Name'));
        expect(updatedProfile.bio, equals('Updated bio'));
        expect(updatedProfile.website, equals('https://updated.com'));
        expect(updatedProfile.location, equals('Updated Location'));
        expect(updatedProfile.birthDate, equals(DateTime(1995, 5, 15)));
        expect(updatedProfile.visibility, equals(ProfileVisibility.private));
        expect(updatedProfile.updatedAt, isNot(equals(updatedProfile.createdAt)));
      });

      test('should keep existing values when not provided', () async {
        // Arrange
        final userId = 'test_user';
        final originalProfile = await profileService.getUserProfile(userId);

        // Act
        final updatedProfile = await profileService.updateProfile(
          userId: userId,
          displayName: 'Only Name Updated',
        );

        // Assert
        expect(updatedProfile.displayName, equals('Only Name Updated'));
        expect(updatedProfile.bio, equals(originalProfile.bio));
        expect(updatedProfile.website, equals(originalProfile.website));
        expect(updatedProfile.location, equals(originalProfile.location));
        expect(updatedProfile.birthDate, equals(originalProfile.birthDate));
        expect(updatedProfile.visibility, equals(originalProfile.visibility));
      });
    });

    group('uploadProfilePhoto', () {
      test('should return photo URL with correct format', () async {
        // Act
        final url = await profileService.uploadProfilePhoto(
          userId: 'test_user',
          filePath: '/path/to/photo.jpg',
          mimeType: 'image/jpeg',
        );

        // Assert
        expect(url, startsWith('https://storage.example.com/profiles/test_user/profile_'));
        expect(url, endsWith('.jpg'));
        expect(url, contains('test_user'));
      });

      test('should generate unique filename for each upload', () async {
        // Act
        final url1 = await profileService.uploadProfilePhoto(
          userId: 'test_user',
          filePath: '/path/to/photo.jpg',
          mimeType: 'image/jpeg',
        );

        final url2 = await profileService.uploadProfilePhoto(
          userId: 'test_user',
          filePath: '/path/to/photo.jpg',
          mimeType: 'image/jpeg',
        );

        // Assert
        expect(url1, isNot(equals(url2)));
      });
    });

    group('uploadCoverImage', () {
      test('should return cover image URL with correct format', () async {
        // Act
        final url = await profileService.uploadCoverImage(
          userId: 'test_user',
          filePath: '/path/to/cover.jpg',
          mimeType: 'image/jpeg',
        );

        // Assert
        expect(url, startsWith('https://storage.example.com/profiles/test_user/cover_'));
        expect(url, endsWith('.jpg'));
        expect(url, contains('test_user'));
      });
    });

    group('deleteProfileMedia', () {
      test('should return true when deleting profile media', () async {
        // Act
        final result = await profileService.deleteProfileMedia(
          userId: 'test_user',
          mediaUrl: 'https://example.com/profile.jpg',
          type: ProfileMediaType.profilePhoto,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('getSocialLinks', () {
      test('should return list of social links', () async {
        // Act
        final links = await profileService.getSocialLinks('test_user');

        // Assert
        expect(links, isA<List<SocialLinkModel>>());
        expect(links.length, greaterThanOrEqualTo(1));

        final firstLink = links.first;
        expect(firstLink.userId, equals('test_user'));
        expect(firstLink.platform, isNotNull);
        expect(firstLink.url, isNotNull);
      });
    });

    group('addSocialLink', () {
      test('should add new social link with correct data', () async {
        // Act
        final link = await profileService.addSocialLink(
          userId: 'test_user',
          platform: SocialPlatform.twitter,
          url: 'https://twitter.com/testuser',
          username: 'testuser',
        );

        // Assert
        expect(link.userId, equals('test_user'));
        expect(link.platform, equals(SocialPlatform.twitter));
        expect(link.url, equals('https://twitter.com/testuser'));
        expect(link.username, equals('testuser'));
        expect(link.createdAt, isNotNull);
        expect(link.updatedAt, isNotNull);
      });
    });

    group('updateSocialLink', () {
      test('should update existing social link', () async {
        // Act
        final link = await profileService.updateSocialLink(
          linkId: 'test_link_id',
          userId: 'test_user',
          platform: SocialPlatform.github,
          url: 'https://github.com/updateduser',
          username: 'updateduser',
          displayOrder: 1,
        );

        // Assert
        expect(link.id, equals('test_link_id'));
        expect(link.userId, equals('test_user'));
        expect(link.platform, equals(SocialPlatform.github));
        expect(link.url, equals('https://github.com/updateduser'));
        expect(link.username, equals('updateduser'));
        expect(link.displayOrder, equals(1));
      });
    });

    group('deleteSocialLink', () {
      test('should return true when deleting social link', () async {
        // Act
        final result = await profileService.deleteSocialLink('test_link_id', 'test_user');

        // Assert
        expect(result, isTrue);
      });
    });

    group('reorderSocialLinks', () {
      test('should return true when reordering social links', () async {
        // Act
        final result = await profileService.reorderSocialLinks(
          userId: 'test_user',
          linkIds: ['link1', 'link2', 'link3'],
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('exportProfileData', () {
      test('should return profile data in correct format', () async {
        // Act
        final data = await profileService.exportProfileData('test_user');

        // Assert
        expect(data, isA<Map<String, dynamic>>());
        expect(data.containsKey('profile'), isTrue);
        expect(data.containsKey('social_links'), isTrue);
        expect(data.containsKey('exported_at'), isTrue);
        expect(data.containsKey('export_format'), isTrue);
        expect(data['export_format'], equals('json'));
      });
    });

    group('deleteAccount', () {
      test('should return true when deleting account', () async {
        // Act
        final result = await profileService.deleteAccount('test_user', 'password123');

        // Assert
        expect(result, isTrue);
      });
    });

    group('URL Validation', () {
      test('should validate correct URLs', () {
        // Act & Assert
        expect(profileService.validateUrl('https://example.com'), isTrue);
        expect(profileService.validateUrl('http://example.com'), isTrue);
        expect(profileService.validateUrl('https://www.example.com'), isTrue);
      });

      test('should reject invalid URLs', () {
        // Act & Assert
        expect(profileService.validateUrl(''), isFalse);
        expect(profileService.validateUrl('not-a-url'), isFalse);
        expect(profileService.validateUrl('ftp://example.com'), isFalse);
        expect(profileService.validateUrl('example.com'), isFalse);
      });

      test('should validate social platform URLs correctly', () async {
        // Act & Assert
        expect(await profileService.validateSocialUrl(SocialPlatform.twitter, 'https://twitter.com/username'), isTrue);
        expect(await profileService.validateSocialUrl(SocialPlatform.github, 'https://github.com/username'), isTrue);
        expect(await profileService.validateSocialUrl(SocialPlatform.twitter, 'https://facebook.com/username'), isFalse);
        expect(await profileService.validateSocialUrl(SocialPlatform.website, 'https://custom-site.com'), isTrue);
      });
    });
  });
}