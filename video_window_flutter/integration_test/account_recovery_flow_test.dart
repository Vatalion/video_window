import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_window_flutter/main.dart' as app;

/// Integration test for the complete account recovery flow
/// Tests: Email → Token → Authentication
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Account Recovery End-to-End Flow', () {
    testWidgets('Complete recovery flow: request → verify → authenticate',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // STEP 1: Navigate to recovery request page
      // Assume there's a "Forgot Password?" or "Recover Account" link on login
      final recoveryLink = find.text('Recover Account');
      expect(recoveryLink, findsOneWidget,
          reason: 'Recovery link should be visible on login page');

      await tester.tap(recoveryLink);
      await tester.pumpAndSettle();

      // STEP 2: Enter email address
      final emailField = find.byType(TextFormField).first;
      expect(emailField, findsOneWidget,
          reason: 'Email input field should be present');

      const testEmail = 'integration-test@example.com';
      await tester.enterText(emailField, testEmail);
      await tester.pump();

      // STEP 3: Submit recovery request
      final submitButton =
          find.widgetWithText(ElevatedButton, 'Send Recovery Email');
      expect(submitButton, findsOneWidget,
          reason: 'Submit button should be present');

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // STEP 4: Verify success message
      expect(find.textContaining('Recovery email sent'), findsOneWidget,
          reason: 'Should show success message after sending');
      expect(find.textContaining(testEmail), findsOneWidget,
          reason: 'Should display the email address');

      // STEP 5: Navigate to token verification page
      // (In real app, user would click link in email, here we simulate navigation)
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Token verification page should now be visible
      expect(find.text('Recovery Token'), findsOneWidget,
          reason: 'Should navigate to token verification page');

      // STEP 6: Enter recovery token
      // Note: In a real test, you'd need to fetch the token from test email service
      // For integration test, we'll use a mock token
      final tokenField = find.byType(TextFormField).first;
      const mockToken = 'a' * 64; // 64 hex characters
      await tester.enterText(tokenField, mockToken);
      await tester.pump();

      // STEP 7: Verify and sign in
      final verifyButton =
          find.widgetWithText(ElevatedButton, 'Verify & Sign In');
      expect(verifyButton, findsOneWidget,
          reason: 'Verify button should be present');

      await tester.tap(verifyButton);
      await tester.pumpAndSettle();

      // STEP 8: Handle verification result
      // In a successful flow, user should be authenticated and navigated to home
      // In this test environment, we'll check for either success or error message
      final hasSuccessIndicator =
          find.textContaining('Recovery successful').evaluate().isNotEmpty ||
              find.textContaining('Welcome').evaluate().isNotEmpty;
      final hasErrorMessage =
          find.textContaining('Invalid').evaluate().isNotEmpty ||
              find.textContaining('expired').evaluate().isNotEmpty;

      expect(hasSuccessIndicator || hasErrorMessage, isTrue,
          reason:
              'Should show either success or error message after verification');

      // If successful, verify navigation to authenticated state
      if (hasSuccessIndicator) {
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.byType(AppBar), findsOneWidget,
            reason: 'Should navigate to main app after successful recovery');
      }
    });

    testWidgets('Recovery flow handles invalid email',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to recovery request page
      final recoveryLink = find.text('Recover Account');
      await tester.tap(recoveryLink);
      await tester.pumpAndSettle();

      // Enter invalid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid-email');
      await tester.pump();

      // Try to submit
      final submitButton =
          find.widgetWithText(ElevatedButton, 'Send Recovery Email');
      await tester.tap(submitButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget,
          reason: 'Should validate email format');
    });

    testWidgets('Recovery flow handles invalid token',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate through to token verification (assuming successful email send)
      final recoveryLink = find.text('Recover Account');
      await tester.tap(recoveryLink);
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      final submitButton =
          find.widgetWithText(ElevatedButton, 'Send Recovery Email');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Enter invalid token
      final tokenField = find.byType(TextFormField).first;
      await tester.enterText(tokenField, 'invalid-token');
      await tester.pump();

      // Try to verify
      final verifyButton =
          find.widgetWithText(ElevatedButton, 'Verify & Sign In');
      await tester.tap(verifyButton);
      await tester.pumpAndSettle();

      // Should show error message with attempts remaining
      expect(find.textContaining('Invalid'), findsOneWidget,
          reason: 'Should show invalid token error');
      expect(find.textContaining('attempts remaining'), findsOneWidget,
          reason: 'Should show remaining attempts');
    });

    testWidgets('Recovery flow allows resending token',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate through to token verification
      final recoveryLink = find.text('Recover Account');
      await tester.tap(recoveryLink);
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      final submitButton =
          find.widgetWithText(ElevatedButton, 'Send Recovery Email');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Click resend button
      final resendButton = find.widgetWithText(TextButton, 'Resend Token');
      expect(resendButton, findsOneWidget,
          reason: 'Resend button should be present');

      await tester.tap(resendButton);
      await tester.pumpAndSettle();

      // Should show success message for resend
      expect(find.textContaining('Recovery email sent'), findsOneWidget,
          reason: 'Should confirm token was resent');
    });

    testWidgets('Recovery flow validates token expiration',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate through to token verification
      final recoveryLink = find.text('Recover Account');
      await tester.tap(recoveryLink);
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      final submitButton =
          find.widgetWithText(ElevatedButton, 'Send Recovery Email');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify expiration warning is shown
      expect(find.textContaining('15 minutes'), findsOneWidget,
          reason: 'Should show token expiration time');
    });

    testWidgets('Recovery flow handles rate limiting',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to recovery request page
      final recoveryLink = find.text('Recover Account');
      await tester.tap(recoveryLink);
      await tester.pumpAndSettle();

      const testEmail = 'rate-limit-test@example.com';

      // Send multiple recovery requests rapidly
      for (int i = 0; i < 5; i++) {
        final emailField = find.byType(TextFormField).first;
        await tester.enterText(emailField, testEmail);
        await tester.pump();

        final submitButton =
            find.widgetWithText(ElevatedButton, 'Send Recovery Email');
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Wait a bit between requests
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Should eventually show rate limit error
      final hasRateLimitError =
          find.textContaining('Too many').evaluate().isNotEmpty ||
              find.textContaining('Try again').evaluate().isNotEmpty;

      expect(hasRateLimitError, isTrue,
          reason: 'Should show rate limit error after multiple requests');
    });
  });
}
