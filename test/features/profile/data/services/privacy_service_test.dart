import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/profile/data/services/privacy_service.dart';
import 'package:video_window/features/profile/domain/models/privacy_setting_model.dart';

class MockPrivacyService extends PrivacyService {
  MockPrivacyService() : super(apiBaseUrl: 'https://api.example.com');
}

void main() {
  group('PrivacyService Tests', () {
    late PrivacyService privacyService;

    setUp(() {
      privacyService = MockPrivacyService();
    });

    group('getPrivacySettings', () {
      test('should return privacy settings with default values', () async {
        // Act
        final settings = await privacyService.getPrivacySettings('test_user');

        // Assert
        expect(settings.userId, equals('test_user'));
        expect(settings.profileVisibility, equals(ProfileVisibility.public));
        expect(settings.searchVisibility, equals(SearchVisibility.everyone));
        expect(settings.dataSharing, isNotNull);
        expect(settings.messageSettings, isNotNull);
        expect(settings.activitySettings, isNotNull);
        expect(settings.createdAt, isNotNull);
        expect(settings.updatedAt, isNotNull);
      });

      test('should have correct default data sharing settings', () async {
        // Act
        final settings = await privacyService.getPrivacySettings('test_user');

        // Assert
        expect(settings.dataSharing.shareProfileWithPartners, isFalse);
        expect(settings.dataSharing.shareActivityWithFriends, isTrue);
        expect(settings.dataSharing.shareLocationData, isFalse);
        expect(settings.dataSharing.allowDataAnalytics, isTrue);
        expect(settings.dataSharing.allowPersonalizedAds, isFalse);
      });

      test('should have correct default message settings', () async {
        // Act
        final settings = await privacyService.getPrivacySettings('test_user');

        // Assert
        expect(settings.messageSettings.allowMessagesFromEveryone, isFalse);
        expect(settings.messageSettings.allowMessagesFromFriends, isTrue);
        expect(settings.messageSettings.allowMessagesFromFollowers, isTrue);
        expect(settings.messageSettings.allowMessageRequests, isTrue);
      });

      test('should have correct default activity settings', () async {
        // Act
        final settings = await privacyService.getPrivacySettings('test_user');

        // Assert
        expect(settings.activitySettings.showOnlineStatus, isTrue);
        expect(settings.activitySettings.showActivityStatus, isTrue);
        expect(settings.activitySettings.showLastSeen, isTrue);
        expect(settings.activitySettings.allowReadReceipts, isTrue);
        expect(settings.activitySettings.allowTypingIndicators, isTrue);
      });
    });

    group('updatePrivacySettings', () {
      test('should update profile visibility', () async {
        // Arrange
        final userId = 'test_user';
        final newVisibility = ProfileVisibility.private;

        // Act
        final updatedSettings = await privacyService.updatePrivacySettings(
          userId: userId,
          profileVisibility: newVisibility,
        );

        // Assert
        expect(updatedSettings.profileVisibility, equals(newVisibility));
        expect(updatedSettings.userId, equals(userId));
        expect(updatedSettings.updatedAt, isNot(equals(updatedSettings.createdAt)));
      });

      test('should update data sharing settings', () async {
        // Arrange
        final userId = 'test_user';
        final newDataSharing = DataSharingSettings(
          shareProfileWithPartners: true,
          shareActivityWithFriends: false,
          shareLocationData: true,
          allowDataAnalytics: false,
          allowPersonalizedAds: true,
        );

        // Act
        final updatedSettings = await privacyService.updatePrivacySettings(
          userId: userId,
          dataSharing: newDataSharing,
        );

        // Assert
        expect(updatedSettings.dataSharing.shareProfileWithPartners, equals(newDataSharing.shareProfileWithPartners));
        expect(updatedSettings.dataSharing.shareActivityWithFriends, equals(newDataSharing.shareActivityWithFriends));
        expect(updatedSettings.dataSharing.shareLocationData, equals(newDataSharing.shareLocationData));
        expect(updatedSettings.dataSharing.allowDataAnalytics, equals(newDataSharing.allowDataAnalytics));
        expect(updatedSettings.dataSharing.allowPersonalizedAds, equals(newDataSharing.allowPersonalizedAds));
      });

      test('should update search visibility', () async {
        // Arrange
        final userId = 'test_user';
        final newSearchVisibility = SearchVisibility.friendsOnly;

        // Act
        final updatedSettings = await privacyService.updatePrivacySettings(
          userId: userId,
          searchVisibility: newSearchVisibility,
        );

        // Assert
        expect(updatedSettings.searchVisibility, equals(newSearchVisibility));
      });

      test('should update message settings', () async {
        // Arrange
        final userId = 'test_user';
        final newMessageSettings = MessageSettings(
          allowMessagesFromEveryone: true,
          allowMessagesFromFriends: false,
          allowMessagesFromFollowers: false,
          allowMessageRequests: false,
        );

        // Act
        final updatedSettings = await privacyService.updatePrivacySettings(
          userId: userId,
          messageSettings: newMessageSettings,
        );

        // Assert
        expect(updatedSettings.messageSettings.allowMessagesFromEveryone, equals(newMessageSettings.allowMessagesFromEveryone));
        expect(updatedSettings.messageSettings.allowMessagesFromFriends, equals(newMessageSettings.allowMessagesFromFriends));
        expect(updatedSettings.messageSettings.allowMessagesFromFollowers, equals(newMessageSettings.allowMessagesFromFollowers));
        expect(updatedSettings.messageSettings.allowMessageRequests, equals(newMessageSettings.allowMessageRequests));
      });

      test('should update activity settings', () async {
        // Arrange
        final userId = 'test_user';
        final newActivitySettings = ActivitySettings(
          showOnlineStatus: false,
          showActivityStatus: false,
          showLastSeen: false,
          allowReadReceipts: false,
          allowTypingIndicators: false,
        );

        // Act
        final updatedSettings = await privacyService.updatePrivacySettings(
          userId: userId,
          activitySettings: newActivitySettings,
        );

        // Assert
        expect(updatedSettings.activitySettings.showOnlineStatus, equals(newActivitySettings.showOnlineStatus));
        expect(updatedSettings.activitySettings.showActivityStatus, equals(newActivitySettings.showActivityStatus));
        expect(updatedSettings.activitySettings.showLastSeen, equals(newActivitySettings.showLastSeen));
        expect(updatedSettings.activitySettings.allowReadReceipts, equals(newActivitySettings.allowReadReceipts));
        expect(updatedSettings.activitySettings.allowTypingIndicators, equals(newActivitySettings.allowTypingIndicators));
      });

      test('should keep existing values when not provided', () async {
        // Arrange
        final userId = 'test_user';
        final originalSettings = await privacyService.getPrivacySettings(userId);

        // Act
        final updatedSettings = await privacyService.updatePrivacySettings(
          userId: userId,
          profileVisibility: ProfileVisibility.private,
        );

        // Assert
        expect(updatedSettings.profileVisibility, equals(ProfileVisibility.private));
        expect(updatedSettings.dataSharing.shareProfileWithPartners, equals(originalSettings.dataSharing.shareProfileWithPartners));
        expect(updatedSettings.dataSharing.shareActivityWithFriends, equals(originalSettings.dataSharing.shareActivityWithFriends));
        expect(updatedSettings.searchVisibility, equals(originalSettings.searchVisibility));
        expect(updatedSettings.messageSettings.allowMessagesFromEveryone, equals(originalSettings.messageSettings.allowMessagesFromEveryone));
        expect(updatedSettings.activitySettings.showOnlineStatus, equals(originalSettings.activitySettings.showOnlineStatus));
      });
    });

    group('updateProfileVisibility', () {
      test('should return true when updating profile visibility', () async {
        // Act
        final result = await privacyService.updateProfileVisibility(
          userId: 'test_user',
          visibility: ProfileVisibility.private,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('updateDataSharingSettings', () {
      test('should return true when updating data sharing settings', () async {
        // Arrange
        final settings = DataSharingSettings(
          shareProfileWithPartners: true,
          shareActivityWithFriends: false,
          shareLocationData: false,
          allowDataAnalytics: false,
          allowPersonalizedAds: false,
        );

        // Act
        final result = await privacyService.updateDataSharingSettings(
          userId: 'test_user',
          settings: settings,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('updateSearchVisibility', () {
      test('should return true when updating search visibility', () async {
        // Act
        final result = await privacyService.updateSearchVisibility(
          userId: 'test_user',
          visibility: SearchVisibility.none,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('updateMessageSettings', () {
      test('should return true when updating message settings', () async {
        // Arrange
        final settings = MessageSettings(
          allowMessagesFromEveryone: false,
          allowMessagesFromFriends: true,
          allowMessagesFromFollowers: false,
          allowMessageRequests: true,
        );

        // Act
        final result = await privacyService.updateMessageSettings(
          userId: 'test_user',
          settings: settings,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('updateActivitySettings', () {
      test('should return true when updating activity settings', () async {
        // Arrange
        final settings = ActivitySettings(
          showOnlineStatus: false,
          showActivityStatus: true,
          showLastSeen: false,
          allowReadReceipts: true,
          allowTypingIndicators: false,
        );

        // Act
        final result = await privacyService.updateActivitySettings(
          userId: 'test_user',
          settings: settings,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('blockUser', () {
      test('should return true when blocking a user', () async {
        // Act
        final result = await privacyService.blockUser(
          userId: 'test_user',
          blockedUserId: 'blocked_user',
          reason: 'Harassment',
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('unblockUser', () {
      test('should return true when unblocking a user', () async {
        // Act
        final result = await privacyService.unblockUser(
          userId: 'test_user',
          blockedUserId: 'blocked_user',
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('getBlockedUsers', () {
      test('should return list of blocked users', () async {
        // Act
        final blockedUsers = await privacyService.getBlockedUsers('test_user');

        // Assert
        expect(blockedUsers, isA<List<Map<String, dynamic>>>());
        expect(blockedUsers.length, greaterThanOrEqualTo(1));

        final firstBlocked = blockedUsers.first;
        expect(firstBlocked.containsKey('user_id'), isTrue);
        expect(firstBlocked.containsKey('blocked_at'), isTrue);
        expect(firstBlocked.containsKey('reason'), isTrue);
      });
    });

    group('restrictUser', () {
      test('should return true when restricting a user', () async {
        // Act
        final result = await privacyService.restrictUser(
          userId: 'test_user',
          restrictedUserId: 'restricted_user',
          type: RestrictionType.comments,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('unrestrictUser', () {
      test('should return true when unrestricting a user', () async {
        // Act
        final result = await privacyService.unrestrictUser(
          userId: 'test_user',
          restrictedUserId: 'restricted_user',
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('getPrivacyAnalytics', () {
      test('should return privacy analytics data', () async {
        // Act
        final analytics = await privacyService.getPrivacyAnalytics('test_user');

        // Assert
        expect(analytics, isA<Map<String, dynamic>>());
        expect(analytics.containsKey('profile_views_last_30_days'), isTrue);
        expect(analytics.containsKey('search_appearances_last_30_days'), isTrue);
        expect(analytics.containsKey('blocked_users_count'), isTrue);
        expect(analytics.containsKey('restricted_users_count'), isTrue);
        expect(analytics.containsKey('data_sharing_status'), isTrue);
        expect(analytics.containsKey('last_updated'), isTrue);
      });
    });

    group('requestDataExport', () {
      test('should return true when requesting data export', () async {
        // Act
        final result = await privacyService.requestDataExport(
          userId: 'test_user',
          format: DataExportFormat.json,
          dataTypes: ['profile', 'social_links'],
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('requestDataDeletion', () {
      test('should return true when requesting data deletion', () async {
        // Act
        final result = await privacyService.requestDataDeletion(
          userId: 'test_user',
          reason: 'User requested deletion',
          password: 'password123',
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('getPrivacyComplianceInfo', () {
      test('should return privacy compliance information', () async {
        // Act
        final complianceInfo = await privacyService.getPrivacyComplianceInfo('test_user');

        // Assert
        expect(complianceInfo, isA<Map<String, dynamic>>());
        expect(complianceInfo.containsKey('user_id'), isTrue);
        expect(complianceInfo.containsKey('data_retention_policy'), isTrue);
        expect(complianceInfo.containsKey('data_subject_request_url'), isTrue);
        expect(complianceInfo.containsKey('last_data_export'), isTrue);
        expect(complianceInfo.containsKey('data_categories'), isTrue);
        expect(complianceInfo.containsKey('third_party_sharing'), isTrue);
        expect(complianceInfo.containsKey('compliance_standards'), isTrue);
      });
    });
  });
}