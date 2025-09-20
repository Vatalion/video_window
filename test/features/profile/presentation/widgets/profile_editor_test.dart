import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:video_window/features/profile/presentation/bloc/profile_event.dart';
import 'package:video_window/features/profile/presentation/bloc/profile_state.dart';
import 'package:video_window/features/profile/presentation/widgets/profile_editor.dart';
import 'package:video_window/features/profile/domain/models/user_profile_model.dart';
import 'package:video_window/features/auth/presentation/widgets/password_strength_indicator.dart';

class MockProfileBloc extends Mock implements ProfileBloc {}

void main() {
  late MockProfileBloc mockProfileBloc;

  setUp(() {
    mockProfileBloc = MockProfileBloc();
    when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());
    when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() {
    mockProfileBloc.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<ProfileBloc>.value(
        value: mockProfileBloc,
        child: const ProfileEditor(),
      ),
    );
  }

  group('ProfileEditor Widget Tests', () {
    testWidgets('should display profile editor form', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(6)); // display name, bio, website, location, password fields
      expect(find.byType(DropdownButtonFormField<ProfileVisibility>), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should display form fields with correct labels', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Bio'), findsOneWidget);
      expect(find.text('Website'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Birth Date'), findsOneWidget);
      expect(find.text('Profile Visibility'), findsOneWidget);
    });

    testWidgets('should validate display name field', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Try to save with empty display name
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.text('Please enter a display name'), findsOneWidget);
    });

    testWidgets('should validate display name minimum length', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter single character display name
      await tester.enterText(find.byType(TextFormField).first, 'A');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.text('Display name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('should validate bio character limit', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter long bio text
      final longBio = 'A' * 501;
      await tester.enterText(find.byType(TextFormField).at(1), longBio);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.text('Bio must be less than 500 characters'), findsOneWidget);
    });

    testWidgets('should validate website URL format', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter invalid URL
      await tester.enterText(find.byType(TextFormField).at(2), 'invalid-url');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.text('Please enter a valid URL (starting with http:// or https://)'), findsOneWidget);
    });

    testWidgets('should accept valid URLs', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid URLs
      await tester.enterText(find.byType(TextFormField).at(2), 'https://example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'http://example.com');

      // Try to save
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert - should not show URL validation error
      expect(find.text('Please enter a valid URL (starting with http:// or https://)'), findsNothing);
    });

    testWidgets('should show password change section', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
    });

    testWidgets('should show password strength indicator when typing new password', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Type in new password field
      await tester.enterText(find.byType(TextFormField).at(5), 'password123');
      await tester.pump();

      // Assert
      expect(find.byType(PasswordStrengthIndicator), findsOneWidget);
    });

    testWidgets('should validate password confirmation', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter different passwords
      await tester.enterText(find.byType(TextFormField).at(5), 'password123');
      await tester.enterText(find.byType(TextFormField).at(6), 'differentpassword');
      await tester.tap(find.text('Change Password'));
      await tester.pump();

      // Assert
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should enable save button when form is valid', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Fill form with valid data
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'Test bio');
      await tester.enterText(find.byType(TextFormField).at(2), 'https://example.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'Test Location');

      await tester.pump();

      // Assert
      final saveButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(saveButton.enabled, isTrue);
    });

    testWidgets('should disable save button when loading', (WidgetTester tester) async {
      // Arrange
      when(() => mockProfileBloc.state).thenReturn(const ProfileLoading());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      final saveButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(saveButton.enabled, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show birth date picker when tapped', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap on birth date field
      await tester.tap(find.text('Select your birth date'));
      await tester.pump();

      // Assert - date picker dialog should appear
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('should show profile visibility options', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap on dropdown
      await tester.tap(find.byType(DropdownButtonFormField<ProfileVisibility>));
      await tester.pump();

      // Assert
      expect(find.text('Public - Anyone can view'), findsOneWidget);
      expect(find.text('Private - Only you can view'), findsOneWidget);
      expect(find.text('Friends Only - Only friends can view'), findsOneWidget);
    });

    testWidgets('should dispatch UpdateProfile event when save is tapped', (WidgetTester tester) async {
      // Arrange
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Fill form
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'Test bio');
      await tester.enterText(find.byType(TextFormField).at(2), 'https://example.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'Test Location');

      // Tap save
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      verify(() => mockProfileBloc.add(any(that is UpdateProfile))).called(1);
    });

    testWidgets('should dispatch ChangePassword event when change password is tapped', (WidgetTester tester) async {
      // Arrange
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Fill password fields
      await tester.enterText(find.byType(TextFormField).at(4), 'currentpass');
      await tester.enterText(find.byType(TextFormField).at(5), 'newpass123');
      await tester.enterText(find.byType(TextFormField).at(6), 'newpass123');

      // Tap change password
      await tester.tap(find.text('Change Password'));
      await tester.pump();

      // Assert
      verify(() => mockProfileBloc.add(any(that is ChangePassword))).called(1);
    });

    testWidgets('should show success message when profile is updated', (WidgetTester tester) async {
      // Arrange
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([
          const ProfileInitial(),
          const ProfileUpdated(
            profile: UserProfileModel(
              id: 'test_id',
              userId: 'test_user',
              displayName: 'Test User',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ]),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Save profile
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.text('Profile updated successfully'), findsOneWidget);
    });

    testWidgets('should show error message when profile update fails', (WidgetTester tester) async {
      // Arrange
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([
          const ProfileInitial(),
          const ProfileError(message: 'Failed to update profile'),
        ]),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Save profile
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.text('Failed to update profile'), findsOneWidget);
    });

    testWidgets('should dispose controllers when widget is disposed', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Dispose the widget
      await tester.pumpWidget(const SizedBox()); // Replace with empty widget
      await tester.pump();

      // Assert - No specific assertion, but the test should not crash
      // The important part is that the widget is properly disposed without errors
    });

    testWidgets('should handle profile loaded state', (WidgetTester tester) async {
      // Arrange
      final testProfile = UserProfileModel(
        id: 'test_id',
        userId: 'test_user',
        displayName: 'Test User',
        bio: 'Test bio',
        website: 'https://test.com',
        location: 'Test City',
        birthDate: DateTime(1990, 1, 1),
        visibility: ProfileVisibility.private,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      when(() => mockProfileBloc.state).thenReturn(ProfileLoaded(
        profile: testProfile,
        socialLinks: [],
      ));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('Test bio'), findsOneWidget);
      expect(find.text('https://test.com'), findsOneWidget);
      expect(find.text('Test City'), findsOneWidget);
    });

    testWidgets('should validate current password when changing password', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Try to change password without current password
      await tester.enterText(find.byType(TextFormField).at(5), 'newpass123');
      await tester.enterText(find.byType(TextFormField).at(6), 'newpass123');
      await tester.tap(find.text('Change Password'));
      await tester.pump();

      // Assert
      expect(find.text('Please fill in all password fields'), findsOneWidget);
    });
  });
}