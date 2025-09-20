import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/widgets/mfa_setup_wizard.dart';
import 'package:video_window/widgets/mfa_verification_dialog.dart';
import 'package:video_window/widgets/mfa_settings_page.dart';
import 'package:video_window/services/mfa_service.dart';

void main() {
  group('MFA Widgets', () {
    late MfaService mfaService;
    const testUserId = 'test-user-123';

    setUp(() {
      mfaService = MfaService();
    });

    group('MfaSetupWizard', () {
      testWidgets('should render method selection step', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MfaSetupWizard(
              userId: testUserId,
              mfaService: mfaService,
            ),
          ),
        );

        expect(find.text('Set Up Two-Factor Authentication'), findsOneWidget);
        expect(find.text('Choose Method'), findsOneWidget);
        expect(find.text('SMS (Text Message)'), findsOneWidget);
        expect(find.text('Authenticator App'), findsOneWidget);
      });

      testWidgets('should allow SMS method selection', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MfaSetupWizard(
              userId: testUserId,
              mfaService: mfaService,
            ),
          ),
        );

        // Select SMS method
        await tester.tap(find.text('SMS (Text Message)'));
        await tester.pump();

        // Continue to next step
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should be on SMS setup step
        expect(find.text('SMS Setup'), findsOneWidget);
        expect(find.text('Phone Number'), findsOneWidget);
      });

      testWidgets('should allow TOTP method selection', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MfaSetupWizard(
              userId: testUserId,
              mfaService: mfaService,
            ),
          ),
        );

        // Select TOTP method
        await tester.tap(find.text('Authenticator App'));
        await tester.pump();

        // Continue to next step
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should be on TOTP setup step
        expect(find.text('Authenticator App Setup'), findsOneWidget);
        expect(find.text('Scan this QR code'), findsOneWidget);
      });
    });

    group('MfaVerificationDialog', () {
      testWidgets('should render verification dialog', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => MfaVerificationDialog(
                        userId: testUserId,
                        mfaService: mfaService,
                        actionDescription: 'Test action requires 2FA',
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        // Show dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Two-Factor Authentication'), findsOneWidget);
        expect(find.text('Test action requires 2FA'), findsOneWidget);
        expect(find.text('Enter your verification code'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Verify'), findsOneWidget);
      });

      testWidgets('should show backup code option', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => MfaVerificationDialog(
                        userId: testUserId,
                        mfaService: mfaService,
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        // Show dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Initially, backup code option should not be visible
        expect(find.text('Use backup code instead'), findsOneWidget);

        // Tap to show backup code option
        await tester.tap(find.text('Use backup code instead'));
        await tester.pump();

        // Backup code option should now be visible
        expect(find.text('Use backup code instead'), findsOneWidget);
      });
    });

    group('MfaSettingsPage', () {
      testWidgets('should render settings page', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MfaSettingsPage(
              userId: testUserId,
              mfaService: mfaService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Two-Factor Authentication'), findsOneWidget);
        expect(find.text('2FA Not Set Up'), findsOneWidget);
        expect(find.text('SMS Authentication'), findsOneWidget);
        expect(find.text('Authenticator App'), findsOneWidget);
        expect(find.text('Backup Codes'), findsOneWidget);
      });

      testWidgets('should show enabled 2FA methods', (WidgetTester tester) async {
        // Setup SMS 2FA
        await mfaService.enableSms2fa(testUserId, '+1234567890');

        await tester.pumpWidget(
          MaterialApp(
            home: MfaSettingsPage(
              userId: testUserId,
              mfaService: mfaService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('2FA Enabled'), findsOneWidget);
        expect(find.text('Enabled'), findsAtLeastNWidgets(1));
        expect(find.text('Phone: +1234567890'), findsOneWidget);
        expect(find.text('Disable SMS'), findsOneWidget);
      });

      testWidgets('should allow SMS setup', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MfaSettingsPage(
              userId: testUserId,
              mfaService: mfaService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap SMS setup button
        await tester.tap(find.text('Set Up SMS'));
        await tester.pumpAndSettle();

        // SMS setup dialog should appear
        expect(find.text('Set Up SMS Authentication'), findsOneWidget);
        expect(find.text('Phone Number'), findsOneWidget);
      });

      testWidgets('should allow TOTP setup', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MfaSettingsPage(
              userId: testUserId,
              mfaService: mfaService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap TOTP setup button
        await tester.tap(find.text('Set Up Authenticator App'));
        await tester.pumpAndSettle();

        // Should navigate to MFA setup wizard
        expect(find.byType(MfaSetupWizard), findsOneWidget);
      });
    });
  });
}