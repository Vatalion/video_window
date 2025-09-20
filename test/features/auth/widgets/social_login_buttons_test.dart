import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/auth/presentation/widgets/social_login_buttons.dart';

void main() {
  group('SocialLoginButtons Widget Tests', () {
    testWidgets('should display all three social login options', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButtons(
              onGoogleLogin: () {},
              onAppleLogin: () {},
              onFacebookLogin: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.byIcon(Icons.g_mobile), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsOneWidget);
      expect(find.byIcon(Icons.facebook), findsOneWidget);
    });

    testWidgets('should handle loading state correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButtons(
              isLoading: true,
              onGoogleLogin: () {},
              onAppleLogin: () {},
              onFacebookLogin: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Opacity), findsNWidgets(3)); // All buttons should be disabled
    });

    testWidgets('should call callbacks when buttons are tapped', (WidgetTester tester) async {
      // Arrange
      var googleCalled = false;
      var appleCalled = false;
      var facebookCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButtons(
              onGoogleLogin: () => googleCalled = true,
              onAppleLogin: () => appleCalled = true,
              onFacebookLogin: () => facebookCalled = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Google'));
      await tester.pump();

      await tester.tap(find.text('Apple'));
      await tester.pump();

      await tester.tap(find.text('Facebook'));
      await tester.pump();

      // Assert
      expect(googleCalled, true);
      expect(appleCalled, true);
      expect(facebookCalled, true);
    });
  });

  group('GoogleLoginButton Tests', () {
    testWidgets('should display Google branding correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleLoginButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byIcon(Icons.g_mobile), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleLoginButton(
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue with Google'), findsNothing);
    });
  });

  group('AppleLoginButton Tests', () {
    testWidgets('should display Apple branding correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppleLoginButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsOneWidget);
    });
  });

  group('FacebookLoginButton Tests', () {
    testWidgets('should display Facebook branding correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FacebookLoginButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Continue with Facebook'), findsOneWidget);
      expect(find.byIcon(Icons.facebook), findsOneWidget);
    });
  });
}