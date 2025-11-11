import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:video_window_flutter/presentation/bloc/auth_bloc.dart';
import 'package:video_window_flutter/packages/features/auth/lib/presentation/pages/account_recovery_request_page.dart';

@GenerateMocks([AuthBloc])
import 'account_recovery_request_page_test.mocks.dart';

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(mockAuthBloc.state).thenReturn(const AuthInitial());
    when(mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>(
        create: (_) => mockAuthBloc,
        child: const AccountRecoveryRequestPage(),
      ),
    );
  }

  group('AccountRecoveryRequestPage Widget Tests', () {
    testWidgets('renders email input field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
    });

    testWidgets('renders submit button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.widgetWithText(ElevatedButton, 'Send Recovery Email'),
          findsOneWidget);
    });

    testWidgets('displays security information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining('15 minute'), findsOneWidget);
      expect(find.textContaining('one-time'), findsOneWidget);
    });

    testWidgets('validates empty email', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find and tap submit button without entering email
      final submitButton =
          find.widgetWithText(ElevatedButton, 'Send Recovery Email');
      await tester.tap(submitButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter your email address'), findsOneWidget);
    });

    testWidgets('validates invalid email format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField), 'invalid-email');

      // Tap submit button
      final submitButton =
          find.widgetWithText(ElevatedButton, 'Send Recovery Email');
      await tester.tap(submitButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets(
        'dispatches AuthRecoverySendRequested event on valid submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter valid email
      const testEmail = 'test@example.com';
      await tester.enterText(find.byType(TextFormField), testEmail);

      // Tap submit button
      final submitButton =
          find.widgetWithText(ElevatedButton, 'Send Recovery Email');
      await tester.tap(submitButton);
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

    testWidgets('shows success message when AuthRecoverySent',
        (WidgetTester tester) async {
      const testEmail = 'test@example.com';
      when(mockAuthBloc.state)
          .thenReturn(const AuthRecoverySent(email: testEmail));
      when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(const AuthRecoverySent(email: testEmail)));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should show success message
      expect(find.textContaining('Recovery email sent'), findsOneWidget);
      expect(find.textContaining(testEmail), findsOneWidget);
    });

    testWidgets('shows error message when AuthError',
        (WidgetTester tester) async {
      const errorMessage = 'Failed to send recovery email';
      when(mockAuthBloc.state)
          .thenReturn(const AuthError(message: errorMessage));
      when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(const AuthError(message: errorMessage)));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should show error message
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('shows rate limit error with retry after',
        (WidgetTester tester) async {
      const errorMessage = 'Too many requests';
      const retryAfter = 300; // 5 minutes
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

      // Should show error with retry time
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.textContaining('Try again'), findsOneWidget);
    });

    testWidgets('back button navigates back', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find back button (should be in AppBar)
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);
    });
  });
}
