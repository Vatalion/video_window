import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/auth/presentation/widgets/password_strength_indicator.dart';

void main() {
  group('PasswordStrengthIndicator Widget Tests', () {
    testWidgets('should display empty state when password is empty', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: ''),
          ),
        ),
      );

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('Password strength:'), findsNothing);
    });

    testWidgets('should show weak password strength', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'weak'),
          ),
        ),
      );

      // Assert
      expect(find.text('Password strength: Weak'), findsOneWidget);
    });

    testWidgets('should show strong password strength', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'StrongP@ssw0rd!'),
          ),
        ),
      );

      // Assert
      expect(find.text('Password strength: Strong'), findsOneWidget);
    });

    testWidgets('should display password requirements', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'Test123!'),
          ),
        ),
      );

      // Assert
      expect(find.text('Password requirements:'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('Contains uppercase letter'), findsOneWidget);
      expect(find.text('Contains lowercase letter'), findsOneWidget);
      expect(find.text('Contains number'), findsOneWidget);
      expect(find.text('Contains special character'), findsOneWidget);
    });

    testWidgets('should show checkmarks for satisfied requirements', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'Test123!'),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.check_circle), findsNWidgets(5)); // All requirements satisfied
    });

    testWidgets('should show outline icons for unsatisfied requirements', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'weak'),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.circle_outlined), findsNWidgets(5)); // All requirements unsatisfied
    });
  });
}