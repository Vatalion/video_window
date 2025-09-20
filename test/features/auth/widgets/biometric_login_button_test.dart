import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/auth/presentation/widgets/biometric_login_button.dart';
import 'package:video_window/features/auth/domain/models/biometric_models.dart';

void main() {
  group('BiometricLoginButton Widget', () {
    testWidgets('should display Face ID button correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricLoginButton(
              biometricType: BiometricType.faceId,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Sign in with Face ID'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byIcon(Icons.face), findsNothing); // Icon is SVG, not IconData
    });

    testWidgets('should display Touch ID button correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricLoginButton(
              biometricType: BiometricType.touchId,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Sign in with Touch ID'), findsOneWidget);
    });

    testWidgets('should show loading indicator when isLoading is true', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricLoginButton(
              biometricType: BiometricType.faceId,
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sign in with Face ID'), findsNothing);
    });

    testWidgets('should show error message when provided', (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Authentication failed';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricLoginButton(
              biometricType: BiometricType.faceId,
              onPressed: () {},
              errorMessage: errorMessage,
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should call onPressed when button is tapped', (WidgetTester tester) async {
      // Arrange
      bool onPressedCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricLoginButton(
              biometricType: BiometricType.faceId,
              onPressed: () => onPressedCalled = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(onPressedCalled, isTrue);
    });

    testWidgets('should be disabled when isLoading is true', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricLoginButton(
              biometricType: BiometricType.faceId,
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Act & Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should have proper styling', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricLoginButton(
              biometricType: BiometricType.faceId,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Act & Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style?.backgroundColor?.resolve({}), isNotNull);
      expect(button.style?.foregroundColor?.resolve({}), equals(Colors.white));
      expect(button.style?.elevation, equals(0));
    });

    testWidgets('should display generic biometric button for unknown type', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricLoginButton(
              biometricType: BiometricType.none,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Sign in with Biometrics'), findsOneWidget);
    });
  });
}