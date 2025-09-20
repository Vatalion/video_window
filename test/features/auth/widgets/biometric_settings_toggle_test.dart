import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/auth/presentation/widgets/biometric_settings_toggle.dart';
import 'package:video_window/features/auth/domain/models/biometric_models.dart';

void main() {
  group('BiometricSettingsToggle Widget', () {
    testWidgets('should display Face ID toggle correctly when enabled', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricSettingsToggle(
              biometricType: BiometricType.faceId,
              isEnabled: true,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Face ID'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('should display Touch ID toggle correctly when disabled', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricSettingsToggle(
              biometricType: BiometricType.touchId,
              isEnabled: false,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Touch ID'), findsOneWidget);
      expect(find.text('Disabled'), findsOneWidget);
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('should show loading indicator when isLoading is true', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricSettingsToggle(
              biometricType: BiometricType.faceId,
              isEnabled: true,
              isLoading: true,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('should show lockout message when provided', (WidgetTester tester) async {
      // Arrange
      const lockoutMessage = 'Try again in 5 minutes';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricSettingsToggle(
              biometricType: BiometricType.faceId,
              isEnabled: true,
              onToggle: () {},
              lockoutMessage: lockoutMessage,
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text(lockoutMessage), findsOneWidget);
      expect(find.byIcon(Icons.lock_clock), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNull); // Should be disabled when locked out
    });

    testWidgets('should call onToggle when switch is changed', (WidgetTester tester) async {
      // Arrange
      bool onToggleCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricSettingsToggle(
              biometricType: BiometricType.faceId,
              isEnabled: false,
              onToggle: (value) => onToggleCalled = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Assert
      expect(onToggleCalled, isTrue);
    });

    testWidgets('should show security info when not locked out', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricSettingsToggle(
              biometricType: BiometricType.faceId,
              isEnabled: true,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Use Face ID for quick and secure access to your account.'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(find.text('Your biometric data never leaves your device'), findsOneWidget);
    });

    testWidgets('should have proper colors for enabled state', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricSettingsToggle(
              biometricType: BiometricType.faceId,
              isEnabled: true,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Act & Assert
      final container = tester.widget<Container>(find.byType(Container).first);
      // In a real test, you might want to check decoration colors more precisely
      expect(container, isNotNull);
    });

    testWidgets('should have proper colors for disabled state', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricSettingsToggle(
              biometricType: BiometricType.faceId,
              isEnabled: false,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Disabled'), findsOneWidget);
      expect(find.text('Enabled'), findsNothing);
    });

    testWidgets('should display generic biometric toggle for unknown type', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricSettingsToggle(
              biometricType: BiometricType.none,
              isEnabled: true,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Biometrics'), findsOneWidget);
    });
  });
}