import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/auth/presentation/widgets/biometric_setup_prompt.dart';
import 'package:video_window/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:video_window/features/auth/domain/models/biometric_models.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest({required BiometricType biometricType}) {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: Scaffold(
          body: BiometricSetupPrompt(
            biometricType: biometricType,
            onSetupComplete: () {},
            onSkip: () {},
          ),
        ),
      ),
    );
  }

  group('BiometricSetupPrompt Widget', () {
    testWidgets('should display Face ID setup correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(biometricType: BiometricType.faceId));

      // Act & Assert
      expect(find.text('Enable Face ID'), findsOneWidget);
      expect(find.text('Use Face ID for faster, more secure access'), findsOneWidget);
      expect(find.byIcon(Icons.speed), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
      expect(find.byIcon(Icons.phonelink_lock), findsOneWidget);
    });

    testWidgets('should display Touch ID setup correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(biometricType: BiometricType.touchId));

      // Act & Assert
      expect(find.text('Enable Touch ID'), findsOneWidget);
      expect(find.text('Use Touch ID for faster, more secure access'), findsOneWidget);
    });

    testWidgets('should display generic biometric setup for unknown type', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(biometricType: BiometricType.none));

      // Act & Assert
      expect(find.text('Enable Biometrics'), findsOneWidget);
      expect(find.text('Use Biometrics for faster, more secure access'), findsOneWidget);
    });

    testWidgets('should call onSkip when skip button is pressed', (WidgetTester tester) async {
      // Arrange
      bool skipCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: BiometricSetupPrompt(
            biometricType: BiometricType.faceId,
            onSetupComplete: () {},
            onSkip: () => skipCalled = true,
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Skip for Now'));
      await tester.pump();

      // Assert
      expect(skipCalled, isTrue);
    });

    testWidgets('should dispatch SetupBiometricAuthEvent when enable button is pressed', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(biometricType: BiometricType.faceId));

      // Act
      await tester.tap(find.text('Enable Face ID'));
      await tester.pump();

      // Assert
      verify(() => mockAuthBloc.add(SetupBiometricAuthEvent())).called(1);
    });

    testWidgets('should display benefit items correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(biometricType: BiometricType.faceId));

      // Act & Assert
      expect(find.text('Lightning Fast'), findsOneWidget);
      expect(find.text('Access your account in under a second'), findsOneWidget);
      expect(find.text('Highly Secure'), findsOneWidget);
      expect(find.text('Military-grade encryption protection'), findsOneWidget);
      expect(find.text('Device Only'), findsOneWidget);
      expect(find.text('Biometric data stays on your device'), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(biometricType: BiometricType.faceId));

      // Act & Assert
      expect(find.byType(Container), findsAtLeastNWidgets(1));
      expect(find.byType(Column), findsAtLeastNWidgets(2));
      expect(find.byType(Row), findsAtLeastNWidgets(1));
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}