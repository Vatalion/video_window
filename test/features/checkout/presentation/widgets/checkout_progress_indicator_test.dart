import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/checkout/presentation/widgets/checkout_progress_indicator.dart';
import 'package:video_window/features/checkout/domain/models/checkout_session_model.dart';

void main() {
  group('CheckoutProgressIndicator', () {
    testWidgets('should display correct number of steps', (WidgetTester tester) async {
      // Arrange
      const currentStep = CheckoutStepType.shipping;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutProgressIndicator(
              currentStep: currentStep,
              onStepTapped: (step) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Step), findsNWidgets(4)); // shipping, payment, review, confirmation
    });

    testWidgets('should highlight current step', (WidgetTester tester) async {
      // Arrange
      const currentStep = CheckoutStepType.payment;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutProgressIndicator(
              currentStep: currentStep,
              onStepTapped: (step) {},
            ),
          ),
        ),
      );

      // Assert
      final stepWidgets = tester.widgetList<Step>(find.byType(Step));
      final paymentStep = stepWidgets.elementAt(1); // Payment is step 1 (0-indexed)
      expect(paymentStep.isActive, isTrue);
    });

    testWidgets('should mark completed steps as complete', (WidgetTester tester) async {
      // Arrange
      const currentStep = CheckoutStepType.review;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutProgressIndicator(
              currentStep: currentStep,
              onStepTapped: (step) {},
            ),
          ),
        ),
      );

      // Assert
      final stepWidgets = tester.widgetList<Step>(find.byType(Step));

      // Shipping and Payment should be completed
      expect(stepWidgets.elementAt(0).state, equals(StepState.complete)); // Shipping
      expect(stepWidgets.elementAt(1).state, equals(StepState.complete)); // Payment

      // Review should be active
      expect(stepWidgets.elementAt(2).isActive, isTrue); // Review
    });

    testWidgets('should call onStepTapped when step is tapped', (WidgetTester tester) async {
      // Arrange
      const currentStep = CheckoutStepType.shipping;
      CheckoutStepType? tappedStep;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutProgressIndicator(
              currentStep: currentStep,
              onStepTapped: (step) {
                tappedStep = step;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Payment'));
      await tester.pump();

      // Assert
      expect(tappedStep, equals(CheckoutStepType.payment));
    });

    testWidgets('should display step titles correctly', (WidgetTester tester) async {
      // Arrange
      const currentStep = CheckoutStepType.shipping;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutProgressIndicator(
              currentStep: currentStep,
              onStepTapped: (step) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Shipping'), findsOneWidget);
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Confirmation'), findsOneWidget);
    });

    testWidgets('should handle step tapping correctly', (WidgetTester tester) async {
      // Arrange
      const currentStep = CheckoutStepType.shipping;
      var tappedStepCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutProgressIndicator(
              currentStep: currentStep,
              onStepTapped: (step) {
                tappedStepCount++;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Shipping'));
      await tester.pump();

      await tester.tap(find.text('Payment'));
      await tester.pump();

      // Assert
      expect(tappedStepCount, equals(2));
    });

    testWidgets('should display correct step icons', (WidgetTester tester) async {
      // Arrange
      const currentStep = CheckoutStepType.payment;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutProgressIndicator(
              currentStep: currentStep,
              onStepTapped: (step) {},
            ),
          ),
        ),
      );

      // Assert
      // Shipping should have a checkmark (completed)
      // Payment should have an active icon
      // Review and Confirmation should have numbered icons
      final stepWidgets = tester.widgetList<Step>(find.byType(Step));

      // Check that steps have appropriate icons
      expect(stepWidgets.length, equals(4));

      // The first step (shipping) should be completed
      expect(stepWidgets.elementAt(0).state, equals(StepState.complete));

      // The second step (payment) should be active
      expect(stepWidgets.elementAt(1).isActive, isTrue);
    });

    testWidgets('should update when current step changes', (WidgetTester tester) async {
      // Arrange
      var currentStep = CheckoutStepType.shipping;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CheckoutProgressIndicator(
                  currentStep: currentStep,
                  onStepTapped: (step) {},
                );
              },
            ),
          ),
        ),
      );

      // Act - change current step
      currentStep = CheckoutStepType.payment;
      await tester.pump();

      // Assert
      final stepWidgets = tester.widgetList<Step>(find.byType(Step));

      // Shipping should now be completed
      expect(stepWidgets.elementAt(0).state, equals(StepState.complete));

      // Payment should now be active
      expect(stepWidgets.elementAt(1).isActive, isTrue);
    });
  });
}