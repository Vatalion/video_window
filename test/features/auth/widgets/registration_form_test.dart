import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:video_window/features/auth/presentation/widgets/registration_form.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: Scaffold(
          body: RegistrationForm(),
        ),
      ),
    );
  }

  group('RegistrationForm Widget Tests', () {
    testWidgets('should display email and phone registration toggle', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const AuthInitialState());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('should display email field when in email mode', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const AuthInitialState());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(TextFormField), findsNWidgets(4)); // email, password, confirm password, strength indicator
      expect(find.text('Email Address'), findsOneWidget);
    });

    testWidgets('should display phone field when in phone mode', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const AuthInitialState());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Phone'));
      await tester.pump();

      // Assert
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4)); // phone, password, confirm password, strength indicator
    });

    testWidgets('should show password strength indicator', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const AuthInitialState());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byKey(const Key('password_field')), 'Test123!');

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should validate email format', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const AuthInitialState());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid-email');

      // Assert
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should validate password strength', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const AuthInitialState());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byKey(const Key('password_field')), 'weak');

      // Assert
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('should require password confirmation', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const AuthInitialState());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byKey(const Key('password_field')), 'Test123!');
      await tester.enterText(find.byKey(const Key('confirm_password_field')), 'Different123!');

      // Assert
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should require age verification and terms acceptance', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const AuthInitialState());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'Test123!');
      await tester.enterText(find.byKey(const Key('confirm_password_field')), 'Test123!');
      await tester.tap(find.byType(ElevatedButton).last);

      // Assert
      expect(find.text('Create Account'), findsOneWidget);
      // Button should not trigger registration due to missing checkboxes
      verifyNever(() => mockAuthBloc.add(any()));
    });

    testWidgets('should submit registration when form is valid', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const AuthInitialState());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'Test123!');
      await tester.enterText(find.byKey(const Key('confirm_password_field')), 'Test123!');
      await tester.tap(find.text('I confirm that I am 13 years of age or older'));
      await tester.tap(find.text('I accept the Terms of Service and Privacy Policy'));
      await tester.tap(find.byType(ElevatedButton).last);

      // Assert
      verify(() => mockAuthBloc.add(RegisterWithEmailEvent(
            email: 'test@example.com',
            password: 'Test123!',
            ageVerified: true,
          ))).called(1);
    });
  });
}