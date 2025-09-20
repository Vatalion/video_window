import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:video_window/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:video_window/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:video_window/features/auth/domain/models/verification_token_model.dart';
import 'package:video_window/features/auth/domain/models/consent_record_model.dart';

class UserModelFake extends Fake implements UserModel {}

class VerificationTokenModelFake extends Fake implements VerificationTokenModel {}

class ConsentRecordModelFake extends Fake implements ConsentRecordModel {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;

  setUpAll(() {
    registerFallbackValue(UserModelFake());
    registerFallbackValue(VerificationTokenModelFake());
    registerFallbackValue(ConsentRecordModelFake());
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('registerWithEmail', () {
    test('should register user with email and cache locally', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      const ageVerified = true;
      const consentData = {'terms_accepted': true};

      final mockUser = UserModel(
        id: '1',
        email: email,
        passwordHash: 'hashed_password',
        verificationStatus: VerificationStatus.pending,
        ageVerified: ageVerified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockRemoteDataSource.registerWithEmail(
            email: email,
            password: password,
            ageVerified: ageVerified,
            consentData: consentData,
          )).thenAnswer((_) async => mockUser);

      when(() => mockLocalDataSource.cacheUser(mockUser))
          .thenAnswer((_) async {});

      // Act
      final result = await repository.registerWithEmail(
        email: email,
        password: password,
        ageVerified: ageVerified,
        consentData: consentData,
      );

      // Assert
      expect(result, mockUser);
      verify(() => mockRemoteDataSource.registerWithEmail(
            email: email,
            password: password,
            ageVerified: ageVerified,
            consentData: consentData,
          )).called(1);
      verify(() => mockLocalDataSource.cacheUser(mockUser)).called(1);
    });
  });

  group('registerWithPhone', () {
    test('should register user with phone and cache locally', () async {
      // Arrange
      const phone = '+1234567890';
      const password = 'password123';
      const ageVerified = true;

      final mockUser = UserModel(
        id: '1',
        email: '',
        phone: phone,
        passwordHash: 'hashed_password',
        verificationStatus: VerificationStatus.pending,
        ageVerified: ageVerified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockRemoteDataSource.registerWithPhone(
            phone: phone,
            password: password,
            ageVerified: ageVerified,
            consentData: null,
          )).thenAnswer((_) async => mockUser);

      when(() => mockLocalDataSource.cacheUser(mockUser))
          .thenAnswer((_) async {});

      // Act
      final result = await repository.registerWithPhone(
        phone: phone,
        password: password,
        ageVerified: ageVerified,
      );

      // Assert
      expect(result, mockUser);
      verify(() => mockRemoteDataSource.registerWithPhone(
            phone: phone,
            password: password,
            ageVerified: ageVerified,
            consentData: null,
          )).called(1);
      verify(() => mockLocalDataSource.cacheUser(mockUser)).called(1);
    });
  });

  group('verifyEmail', () {
    test('should verify email and update cached user', () async {
      // Arrange
      const userId = '1';
      const token = 'verification_token';

      final cachedUser = UserModel(
        id: userId,
        email: 'test@example.com',
        passwordHash: 'hashed_password',
        verificationStatus: VerificationStatus.pending,
        ageVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockRemoteDataSource.verifyEmail(userId, token))
          .thenAnswer((_) async => true);

      when(() => mockLocalDataSource.getCachedUser())
          .thenAnswer((_) async => cachedUser);

      when(() => mockLocalDataSource.cacheUser(any()))
          .thenAnswer((_) async {});

      // Act
      final result = await repository.verifyEmail(userId, token);

      // Assert
      expect(result, true);
      verify(() => mockRemoteDataSource.verifyEmail(userId, token)).called(1);
      verify(() => mockLocalDataSource.getCachedUser()).called(1);
      verify(() => mockLocalDataSource.cacheUser(any())).called(1);
    });

    test('should not update cache when user not found locally', () async {
      // Arrange
      const userId = '1';
      const token = 'verification_token';

      when(() => mockRemoteDataSource.verifyEmail(userId, token))
          .thenAnswer((_) async => true);

      when(() => mockLocalDataSource.getCachedUser())
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.verifyEmail(userId, token);

      // Assert
      expect(result, true);
      verify(() => mockRemoteDataSource.verifyEmail(userId, token)).called(1);
      verify(() => mockLocalDataSource.getCachedUser()).called(1);
      verifyNever(() => mockLocalDataSource.cacheUser(any()));
    });
  });

  group('getCurrentUser', () {
    test('should return cached user', () async {
      // Arrange
      final mockUser = UserModel(
        id: '1',
        email: 'test@example.com',
        passwordHash: 'hashed_password',
        verificationStatus: VerificationStatus.pending,
        ageVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockLocalDataSource.getCachedUser())
          .thenAnswer((_) async => mockUser);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, mockUser);
      verify(() => mockLocalDataSource.getCachedUser()).called(1);
    });
  });

  group('logout', () {
    test('should clear cached user', () async {
      // Arrange
      when(() => mockLocalDataSource.clearCachedUser())
          .thenAnswer((_) async {});

      // Act
      await repository.logout();

      // Assert
      verify(() => mockLocalDataSource.clearCachedUser()).called(1);
    });
  });
}