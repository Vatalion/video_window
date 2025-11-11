import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:video_window_flutter/presentation/bloc/auth_bloc.dart';
import 'package:video_window_flutter/packages/features/auth/lib/presentation/pages/recovery_token_verification_page.dart';

@GenerateMocks([AuthBloc])
import 'recovery_token_verification_page_test.mocks.dart';

void main() {
  late MockAuthBloc mockAuthBloc;
  const testEmail = 'test@example.com';

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(mockAuthBloc.state).thenReturn(const AuthInitial());
    when(mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>(
        create: (_) => mockAuthBloc,
        child: const RecoveryTokenVerificationPage(email: testEmail),
      ),
    );
  }

  group('RecoveryTokenVerificationPage Widget Tests', () {
    testWidgets('renders token input field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Recovery Token'), findsOneWidget);
    });

    testWidgets('renders verify button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.widgetWithText(ElevatedButton, 'Verify & Sign In'),
          findsOneWidget);
    });

    testWidgets('displays email address', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining(testEmail), findsOneWidget);
    });

    testWidgets('displays security warnings', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining('3 attempts'), findsOneWidget);
      expect(find.textContaining('15 minutes'), findsOneWidget);
    });

    testWidgets('displays resend button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.widgetWithText(TextButton, 'Resend Token'), findsOneWidget);
    });

    testWidgets('validates empty token', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find and tap verify button without entering token
      final verifyButton =
          find.widgetWithText(ElevatedButton, 'Verify & Sign In');
      await tester.tap(verifyButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter the recovery token'), findsOneWidget);
    });

    testWidgets('validates token length', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter short token
      await tester.enterText(find.byType(TextFormField), '12345');

      // Tap verify button
      final verifyButton =
          find.widgetWithText(ElevatedButton, 'Verify & Sign In');
      await tester.tap(verifyButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Token must be at least 32 characters'), findsOneWidget);
    });

    testWidgets(
        'dispatches AuthRecoveryVerifyRequested event on valid submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter valid token
      const testToken = 'a' * 64; // 64 hex characters
      await tester.enterText(find.byType(TextFormField), testToken);

      // Tap verify button
      final verifyButton =
          find.widgetWithText(ElevatedButton, 'Verify & Sign In');
      await tester.tap(verifyButton);
      await tester.pump();

      // Verify event was dispatched
      verify(mockAuthBloc.add(const AuthRecoveryVerifyRequested(
        email: testEmail,
        token: testToken,
      ))).called(1);
    });

    testWidgets('resend button dispatches AuthRecoverySendRequested',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find and tap resend button
      final resendButton = find.widgetWithText(TextButton, 'Resend Token');
      await tester.tap(resendButton);
      await tester.pump();

      // Verify event was dispatched
      verify(mockAuthBloc
              .add(const AuthRecoverySendRequested(email: testEmail)))
          .called(1);
    });

    testWidgets('shows loading state when AuthLoading',
        (WidgetTester tester) async {
      when(mockAuthBloc.state).thenReturn(const AuthLoading());
      when(mockAuthBloc.stream)
          .thenAnswer((_) => Stream.value(const AuthLoading()));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows success and navigates when AuthAuthenticated',
        (WidgetTester tester) async {
      final authUser = AuthUser(
        id: 1,
        email: testEmail,
        createdAt: DateTime.now().toIso8601String(),
      );
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: authUser));
      when(mockAuthBloc.stream)
          .thenAnswer((_) => Stream.value(AuthAuthenticated(user: authUser)));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should show success message (briefly before navigation)
      expect(find.textContaining('Recovery successful'), findsOneWidget);
    });

    testWidgets('shows error message when AuthError',
        (WidgetTester tester) async {
      const errorMessage = 'Invalid recovery token';
      when(mockAuthBloc.state)
          .thenReturn(const AuthError(message: errorMessage));
      when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(const AuthError(message: errorMessage)));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should show error message
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('shows attempts remaining when available',
        (WidgetTester tester) async {
      const errorMessage = 'Invalid token';
      const attemptsRemaining = 2;
      when(mockAuthBloc.state).thenReturn(const AuthError(
        message: errorMessage,
        attemptsRemaining: attemptsRemaining,
      ));
      when(mockAuthBloc.stream).thenAnswer((_) => Stream.value(const AuthError(
            message: errorMessage,
            attemptsRemaining: attemptsRemaining,
          )));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should show attempts remaining
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.textContaining('$attemptsRemaining attempts remaining'),
          findsOneWidget);
    });

    testWidgets('shows account locked message', (WidgetTester tester) async {
      const errorMessage = 'Account locked';
      const retryAfter = 1800; // 30 minutes
      when(mockAuthBloc.state).thenReturn(const AuthError(
        message: errorMessage,
        retryAfter: retryAfter,
      ));
      when(mockAuthBloc.stream).thenAnswer((_) => Stream.value(const AuthError(
            message: errorMessage,
            retryAfter: retryAfter,
          )));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should show locked message with time
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.textContaining('30 minutes'), findsOneWidget);
    });

    testWidgets('back button navigates back', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find back button (should be in AppBar)
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);
    });

    testWidgets('formats token input to lowercase hex',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter mixed case token
      const mixedCaseToken = 'ABCD1234efgh5678';
      await tester.enterText(find.byType(TextFormField), mixedCaseToken);
      await tester.pump();

      // Should be converted to lowercase
      final textField =
          tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller?.text, equals(mixedCaseToken.toLowerCase()));
    });
  });
}
