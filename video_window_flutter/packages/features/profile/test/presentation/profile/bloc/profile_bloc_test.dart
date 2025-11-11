import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/data/repositories/profile/profile_repository.dart';
import 'package:profile/presentation/profile/bloc/profile_bloc.dart';
import 'package:profile/presentation/profile/bloc/profile_event.dart';
import 'package:profile/presentation/profile/bloc/profile_state.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  group('ProfileBloc', () {
    late MockProfileRepository mockRepository;
    late ProfileBloc profileBloc;

    setUp(() {
      mockRepository = MockProfileRepository();
      profileBloc = ProfileBloc(mockRepository);
    });

    tearDown(() {
      profileBloc.close();
    });

    test('initial state is ProfileInitial', () {
      expect(profileBloc.state, equals(const ProfileInitial()));
    });

    group('ProfileLoadRequested', () {
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
      };

      blocTest<ProfileBloc, ProfileState>(
        'emits [Loading, Loaded] when profile loads successfully',
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
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [Loading, Error] when profile load fails',
        build: () {
          when(() => mockRepository.getMyProfile(userId))
              .thenThrow(Exception('Load failed'));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested(userId)),
        expect: () => [
          const ProfileLoading(),
          const ProfileError(
            message: 'Failed to load profile: Exception: Load failed',
            errorCode: 'LOAD_ERROR',
          ),
        ],
      );
    });

    group('ProfileUpdateRequested', () {
      const userId = 1;
      final updateData = {
        'username': 'updateduser',
        'fullName': 'Updated User',
        'bio': 'Updated bio',
      };
      final updatedProfile = {
        'id': 1,
        'userId': userId,
        'username': 'updateduser',
        'fullName': 'Updated User',
        'bio': 'Updated bio',
      };

      blocTest<ProfileBloc, ProfileState>(
        'emits [Updated] when profile updates successfully',
        build: () {
          when(() => mockRepository.updateMyProfile(userId, updateData))
              .thenAnswer((_) async => updatedProfile);
          return profileBloc;
        },
        act: (bloc) => bloc.add(ProfileUpdateRequested(userId, updateData)),
        expect: () => [
          ProfileUpdated(profile: updatedProfile),
        ],
      );
    });

    group('ExportUserDataRequested', () {
      const userId = 1;
      final exportData = {
        'userId': userId,
        'exportedAt': '2025-01-01T00:00:00Z',
        'account': {},
        'profile': {},
      };

      blocTest<ProfileBloc, ProfileState>(
        'emits [Exported] when data export succeeds',
        build: () {
          when(() => mockRepository.exportUserData(userId))
              .thenAnswer((_) async => exportData);
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ExportUserDataRequested(userId)),
        expect: () => [
          UserDataExported(exportData: exportData),
        ],
      );
    });

    group('DeleteUserDataRequested', () {
      const userId = 1;

      blocTest<ProfileBloc, ProfileState>(
        'emits [Deleted] when data deletion succeeds',
        build: () {
          when(() => mockRepository.deleteUserData(userId))
              .thenAnswer((_) async => Future.value());
          return profileBloc;
        },
        act: (bloc) => bloc.add(const DeleteUserDataRequested(userId)),
        expect: () => [
          const UserDataDeleted(),
        ],
      );
    });
  });
}
