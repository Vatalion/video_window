import 'package:test/test.dart';
import 'package:video_window_server/src/business/profile/privacy_manager.dart';
import 'package:video_window_server/src/generated/profile/privacy_settings.dart';
import 'package:video_window_server/src/generated/auth/user.dart';
import '../integration/test_tools/serverpod_test_tools.dart';

/// Integration test for privacy visibility enforcement
/// AC3: PrivacyManager enforces visibility rules for public, friends-only, and private queries
void main() {
  withServerpod(
    'Privacy Visibility Enforcement Tests',
    (sessionBuilder, endpoints) {
      group('Privacy Visibility Enforcement', () {
        late PrivacyManager privacyManager;
        late int user1Id;
        late int user2Id;

        setUp(() async {
          final session = sessionBuilder.build();
          privacyManager = PrivacyManager(session);

          // Create test users
          final user1 = User(
            email: 'user1@test.com',
            phone: '+1234567890',
            role: 'viewer',
            authProvider: 'email',
            isEmailVerified: true,
            isPhoneVerified: false,
            isActive: true,
            failedAttempts: 0,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          final user2 = User(
            email: 'user2@test.com',
            phone: '+0987654321',
            role: 'viewer',
            authProvider: 'email',
            isEmailVerified: true,
            isPhoneVerified: false,
            isActive: true,
            failedAttempts: 0,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );

          final savedUser1 = await User.db.insertRow(session, user1);
          final savedUser2 = await User.db.insertRow(session, user2);
          user1Id = savedUser1.id!;
          user2Id = savedUser2.id!;
        });

        test('Public profile visibility - allows anyone to view', () async {
          final session = sessionBuilder.build();
          // Arrange: Create public privacy settings for user1
          final settings = PrivacySettings(
            userId: user1Id,
            profileVisibility: 'public',
            showEmailToPublic: false,
            showPhoneToFriends: false,
            allowTagging: true,
            allowSearchByPhone: false,
            allowDataAnalytics: true,
            allowMarketingEmails: false,
            allowPushNotifications: true,
            shareProfileWithPartners: false,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          await PrivacySettings.db.insertRow(session, settings);

          // Act: user2 tries to view user1's profile
          final canView = await privacyManager.canViewProfile(user2Id, user1Id);

          // Assert: Should be able to view public profile
          expect(canView, isTrue);
        });

        test('Private profile visibility - blocks non-owner access', () async {
          final session = sessionBuilder.build();
          // Arrange: Create private privacy settings for user1
          final settings = PrivacySettings(
            userId: user1Id,
            profileVisibility: 'private',
            showEmailToPublic: false,
            showPhoneToFriends: false,
            allowTagging: true,
            allowSearchByPhone: false,
            allowDataAnalytics: true,
            allowMarketingEmails: false,
            allowPushNotifications: true,
            shareProfileWithPartners: false,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          await PrivacySettings.db.insertRow(session, settings);

          // Act: user2 tries to view user1's profile
          final canView = await privacyManager.canViewProfile(user2Id, user1Id);

          // Assert: Should NOT be able to view private profile
          expect(canView, isFalse);
        });

        test('Friends-only profile visibility - blocks non-friends', () async {
          final session = sessionBuilder.build();
          // Arrange: Create friends-only privacy settings for user1
          final settings = PrivacySettings(
            userId: user1Id,
            profileVisibility: 'friendsOnly',
            showEmailToPublic: false,
            showPhoneToFriends: false,
            allowTagging: true,
            allowSearchByPhone: false,
            allowDataAnalytics: true,
            allowMarketingEmails: false,
            allowPushNotifications: true,
            shareProfileWithPartners: false,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          await PrivacySettings.db.insertRow(session, settings);

          // Act: user2 tries to view user1's profile (not friends)
          final canView = await privacyManager.canViewProfile(user2Id, user1Id);

          // Assert: Should NOT be able to view friends-only profile (friendship check returns false)
          expect(canView, isFalse);
        });

        test('User can always view their own profile', () async {
          final session = sessionBuilder.build();
          // Arrange: Create private privacy settings for user1
          final settings = PrivacySettings(
            userId: user1Id,
            profileVisibility: 'private',
            showEmailToPublic: false,
            showPhoneToFriends: false,
            allowTagging: true,
            allowSearchByPhone: false,
            allowDataAnalytics: true,
            allowMarketingEmails: false,
            allowPushNotifications: true,
            shareProfileWithPartners: false,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          await PrivacySettings.db.insertRow(session, settings);

          // Act: user1 tries to view their own profile
          final canView = await privacyManager.canViewProfile(user1Id, user1Id);

          // Assert: Should always be able to view own profile
          expect(canView, isTrue);
        });

        test('Default visibility when no settings exist - allows public access',
            () async {
          // Act: user2 tries to view user1's profile (no privacy settings)
          final canView = await privacyManager.canViewProfile(user2Id, user1Id);

          // Assert: Should default to public (allow access)
          expect(canView, isTrue);
        });

        test('Email visibility - respects showEmailToPublic setting', () async {
          final session = sessionBuilder.build();
          // Arrange: Create settings with showEmailToPublic = true
          final settings = PrivacySettings(
            userId: user1Id,
            profileVisibility: 'public',
            showEmailToPublic: true,
            showPhoneToFriends: false,
            allowTagging: true,
            allowSearchByPhone: false,
            allowDataAnalytics: true,
            allowMarketingEmails: false,
            allowPushNotifications: true,
            shareProfileWithPartners: false,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          await PrivacySettings.db.insertRow(session, settings);

          // Act: Check if user2 can view user1's email
          final canViewEmail =
              await privacyManager.canViewEmail(user2Id, user1Id);

          // Assert: Should be able to view email when showEmailToPublic is true
          expect(canViewEmail, isTrue);
        });

        test('Phone visibility - respects showPhoneToFriends setting',
            () async {
          final session = sessionBuilder.build();
          // Arrange: Create settings with showPhoneToFriends = true
          final settings = PrivacySettings(
            userId: user1Id,
            profileVisibility: 'public',
            showEmailToPublic: false,
            showPhoneToFriends: true,
            allowTagging: true,
            allowSearchByPhone: false,
            allowDataAnalytics: true,
            allowMarketingEmails: false,
            allowPushNotifications: true,
            shareProfileWithPartners: false,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          await PrivacySettings.db.insertRow(session, settings);

          // Act: Check if user2 can view user1's phone (not friends)
          final canViewPhone =
              await privacyManager.canViewPhone(user2Id, user1Id);

          // Assert: Should NOT be able to view phone (friendship check returns false)
          expect(canViewPhone, isFalse);
        });

        test('Tagging permission - respects allowTagging setting', () async {
          final session = sessionBuilder.build();
          // Arrange: Create settings with allowTagging = false
          final settings = PrivacySettings(
            userId: user1Id,
            profileVisibility: 'public',
            showEmailToPublic: false,
            showPhoneToFriends: false,
            allowTagging: false,
            allowSearchByPhone: false,
            allowDataAnalytics: true,
            allowMarketingEmails: false,
            allowPushNotifications: true,
            shareProfileWithPartners: false,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          await PrivacySettings.db.insertRow(session, settings);

          // Act: Check if user2 can tag user1
          final canTag = await privacyManager.canTagUser(user2Id, user1Id);

          // Assert: Should NOT be able to tag when allowTagging is false
          expect(canTag, isFalse);
        });

        test('Search by phone permission - respects allowSearchByPhone setting',
            () async {
          final session = sessionBuilder.build();
          // Arrange: Create settings with allowSearchByPhone = true
          final settings = PrivacySettings(
            userId: user1Id,
            profileVisibility: 'public',
            showEmailToPublic: false,
            showPhoneToFriends: false,
            allowTagging: true,
            allowSearchByPhone: true,
            allowDataAnalytics: true,
            allowMarketingEmails: false,
            allowPushNotifications: true,
            shareProfileWithPartners: false,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          await PrivacySettings.db.insertRow(session, settings);

          // Act: Check if user1 can be found by phone
          final canSearch = await privacyManager.canSearchByPhone(user1Id);

          // Assert: Should be searchable when allowSearchByPhone is true
          expect(canSearch, isTrue);
        });

        test('Apply privacy filters - filters email and phone correctly',
            () async {
          final session = sessionBuilder.build();
          // Arrange: Create settings
          final settings = PrivacySettings(
            userId: user1Id,
            profileVisibility: 'public',
            showEmailToPublic: false,
            showPhoneToFriends: false,
            allowTagging: true,
            allowSearchByPhone: false,
            allowDataAnalytics: true,
            allowMarketingEmails: false,
            allowPushNotifications: true,
            shareProfileWithPartners: false,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          await PrivacySettings.db.insertRow(session, settings);

          final profileData = {
            'id': user1Id,
            'username': 'testuser',
            'email': 'user1@test.com',
            'emailEncrypted': 'encrypted_email',
            'phone': '+1234567890',
            'phoneEncrypted': 'encrypted_phone',
          };

          // Act: Apply privacy filters
          final filtered = await privacyManager.applyPrivacyFilters(
            profileData,
            user2Id,
            user1Id,
          );

          // Assert: Email and phone should be filtered out
          expect(filtered.containsKey('email'), isFalse);
          expect(filtered.containsKey('emailEncrypted'), isFalse);
          expect(filtered.containsKey('phone'), isFalse);
          expect(filtered.containsKey('phoneEncrypted'), isFalse);
          expect(filtered['username'], equals('testuser'));
        });
      });
    },
  );
}
