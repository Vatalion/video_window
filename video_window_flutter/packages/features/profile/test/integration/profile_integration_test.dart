import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/data/repositories/profile/profile_repository.dart';
import 'package:core/services/analytics_service.dart';
import 'package:profile/presentation/profile/bloc/profile_bloc.dart';
import 'package:profile/presentation/profile/bloc/profile_event.dart';
import 'package:profile/presentation/profile/bloc/profile_state.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeAnalyticsEvent extends Fake implements AnalyticsEvent {
  @override
  String get name => 'fake_event';

  @override
  Map<String, dynamic> get properties => {};

  @override
  DateTime get timestamp => DateTime.now();
}

/// Integration tests for profile management
/// AC8: Integration tests covering profile CRUD operations, privacy controls
void main() {
  setUpAll(() {
    registerFallbackValue(FakeAnalyticsEvent());
  });

  group('Profile Integration Tests', () {
    late MockProfileRepository mockRepository;
    late MockAnalyticsService mockAnalytics;
    late ProfileBloc profileBloc;

    setUp(() {
      mockRepository = MockProfileRepository();
      mockAnalytics = MockAnalyticsService();

      profileBloc = ProfileBloc(
        mockRepository,
        analyticsService: mockAnalytics,
      );

      // Setup default mock behavior
      when(() => mockAnalytics.trackEvent(any())).thenAnswer((_) async {});
    });

    tearDown(() {
      profileBloc.close();
    });

    group('Profile CRUD Operations', () {
      const userId = 1;
      final profileData = {
        'id': 1,
        'userId': userId,
        'username': 'testuser',
        'fullName': 'Test User',
        'bio': 'Test bio',
        'avatarUrl': null,
        'visibility': 'public',
        'isVerified': false,
        'createdAt': '2025-01-01T00:00:00Z',
        'updatedAt': '2025-01-01T00:00:00Z',
      };

      blocTest<ProfileBloc, ProfileState>(
        'loads profile successfully and emits loaded state',
        build: () {
          when(() => mockRepository.getMyProfile(userId))
              .thenAnswer((_) async => profileData);
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested(userId)),
        expect: () => [
          const ProfileLoading(),
          ProfileLoaded(profile: profileData),
        ],
        verify: (_) {
          verify(() => mockRepository.getMyProfile(userId)).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'updates profile successfully and emits analytics event',
        build: () {
          final updatedProfile = {
            ...profileData,
            'username': 'updateduser',
            'bio': 'Updated bio',
          };
          when(() => mockRepository.updateMyProfile(userId, any()))
              .thenAnswer((_) async => updatedProfile);
          return profileBloc;
        },
        act: (bloc) => bloc.add(
          ProfileUpdateRequested(
            userId,
            {'username': 'updateduser', 'bio': 'Updated bio'},
          ),
        ),
        expect: () => [
          ProfileUpdated(profile: {
            ...profileData,
            'username': 'updateduser',
            'bio': 'Updated bio',
          }),
        ],
        verify: (_) {
          verify(() => mockRepository.updateMyProfile(userId, any())).called(1);
          verify(() => mockAnalytics.trackEvent(any())).called(1);
        },
      );
    });

    group('Privacy Controls', () {
      const userId = 1;
      final privacySettings = {
        'id': 1,
        'userId': userId,
        'profileVisibility': 'public',
        'showEmailToPublic': false,
        'showPhoneToFriends': true,
        'allowTagging': true,
        'allowSearchByPhone': false,
        'allowDataAnalytics': true,
        'allowMarketingEmails': false,
        'allowPushNotifications': true,
        'shareProfileWithPartners': false,
        'createdAt': '2025-01-01T00:00:00Z',
        'updatedAt': '2025-01-01T00:00:00Z',
      };

      blocTest<ProfileBloc, ProfileState>(
        'loads privacy settings successfully',
        build: () {
          when(() => mockRepository.getPrivacySettings(userId))
              .thenAnswer((_) async => privacySettings);
          return profileBloc;
        },
        act: (bloc) => bloc.add(const PrivacySettingsLoadRequested(userId)),
        expect: () => [
          PrivacySettingsUpdated(settings: privacySettings),
        ],
        verify: (_) {
          verify(() => mockRepository.getPrivacySettings(userId)).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'updates privacy settings and emits analytics event',
        build: () {
          final updatedSettings = {
            ...privacySettings,
            'profileVisibility': 'private',
            'allowDataAnalytics': false,
          };
          when(() => mockRepository.updatePrivacySettings(userId, any()))
              .thenAnswer((_) async => updatedSettings);
          return profileBloc;
        },
        act: (bloc) => bloc.add(
          PrivacySettingsUpdateRequested(
            userId,
            {
              'profileVisibility': 'private',
              'allowDataAnalytics': false,
            },
          ),
        ),
        expect: () => [
          PrivacySettingsUpdated(settings: {
            ...privacySettings,
            'profileVisibility': 'private',
            'allowDataAnalytics': false,
          }),
        ],
        verify: (_) {
          verify(() => mockRepository.updatePrivacySettings(userId, any()))
              .called(1);
          verify(() => mockAnalytics.trackEvent(any())).called(1);
        },
      );
    });

    group('Notification Preferences', () {
      const userId = 1;
      final notificationPrefs = {
        'id': 1,
        'userId': userId,
        'emailNotifications': true,
        'pushNotifications': true,
        'inAppNotifications': true,
        'settings': {},
        'quietHours': {},
        'createdAt': '2025-01-01T00:00:00Z',
        'updatedAt': '2025-01-01T00:00:00Z',
      };

      blocTest<ProfileBloc, ProfileState>(
        'loads notification preferences successfully',
        build: () {
          when(() => mockRepository.getNotificationPreferences(userId))
              .thenAnswer((_) async => notificationPrefs);
          return profileBloc;
        },
        act: (bloc) =>
            bloc.add(const NotificationPreferencesLoadRequested(userId)),
        expect: () => [
          NotificationPreferencesUpdated(preferences: notificationPrefs),
        ],
        verify: (_) {
          verify(() => mockRepository.getNotificationPreferences(userId))
              .called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'updates notification preferences and emits analytics event',
        build: () {
          final updatedPrefs = {
            ...notificationPrefs,
            'emailNotifications': false,
            'pushNotifications': true,
          };
          when(() =>
                  mockRepository.updateNotificationPreferences(userId, any()))
              .thenAnswer((_) async => updatedPrefs);
          return profileBloc;
        },
        act: (bloc) => bloc.add(
          NotificationPreferencesUpdateRequested(
            userId,
            {
              'emailNotifications': false,
              'pushNotifications': true,
              'inAppNotifications': true,
            },
          ),
        ),
        expect: () => [
          NotificationPreferencesUpdated(preferences: {
            ...notificationPrefs,
            'emailNotifications': false,
            'pushNotifications': true,
          }),
        ],
        verify: (_) {
          verify(() =>
                  mockRepository.updateNotificationPreferences(userId, any()))
              .called(1);
          verify(() => mockAnalytics.trackEvent(any())).called(1);
        },
      );
    });

    group('DSAR Operations', () {
      const userId = 1;

      blocTest<ProfileBloc, ProfileState>(
        'exports user data successfully and emits analytics event',
        build: () {
          final exportData = {
            'profile': {'username': 'testuser'},
            'privacySettings': {'profileVisibility': 'public'},
            'notificationPreferences': {'emailNotifications': true},
          };
          when(() => mockRepository.exportUserData(userId))
              .thenAnswer((_) async => exportData);
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ExportUserDataRequested(userId)),
        expect: () => [
          UserDataExported(exportData: {
            'profile': {'username': 'testuser'},
            'privacySettings': {'profileVisibility': 'public'},
            'notificationPreferences': {'emailNotifications': true},
          }),
        ],
        verify: (_) {
          verify(() => mockRepository.exportUserData(userId)).called(1);
          verify(() => mockAnalytics.trackEvent(any())).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'deletes user data successfully and emits analytics event',
        build: () {
          when(() => mockRepository.deleteUserData(userId))
              .thenAnswer((_) async {});
          return profileBloc;
        },
        act: (bloc) => bloc.add(const DeleteUserDataRequested(userId)),
        expect: () => [
          const UserDataDeleted(),
        ],
        verify: (_) {
          verify(() => mockRepository.deleteUserData(userId)).called(1);
          verify(() => mockAnalytics.trackEvent(any())).called(1);
        },
      );
    });

    group('Error Handling', () {
      const userId = 1;

      blocTest<ProfileBloc, ProfileState>(
        'handles repository errors gracefully',
        build: () {
          when(() => mockRepository.getMyProfile(userId))
              .thenThrow(ProfileRepositoryException('Network error'));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested(userId)),
        expect: () => [
          const ProfileLoading(),
          const ProfileError(
            message:
                'Failed to load profile: ProfileRepositoryException: Network error',
            errorCode: 'LOAD_ERROR',
          ),
        ],
      );
    });
  });
}
