import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile/presentation/capability_center/widgets/capability_card.dart';

void main() {
  group('CapabilityCard Widget Tests', () {
    testWidgets('displays title and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CapabilityCard(
              title: 'Test Capability',
              description: 'Test description',
              status: CapabilityStatus.inactive,
            ),
          ),
        ),
      );

      expect(find.text('Test Capability'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
    });

    testWidgets('displays status badge with correct label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CapabilityCard(
              title: 'Test',
              description: 'Test',
              status: CapabilityStatus.ready,
            ),
          ),
        ),
      );

      expect(find.text('Ready'), findsOneWidget);
    });

    testWidgets('displays action button when provided', (tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CapabilityCard(
              title: 'Test',
              description: 'Test',
              status: CapabilityStatus.inactive,
              actionLabel: 'Enable',
              onActionPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Enable'), findsOneWidget);

      await tester.tap(find.text('Enable'));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('displays blockers when present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CapabilityCard(
              title: 'Test',
              description: 'Test',
              status: CapabilityStatus.blocked,
              blockers: const [
                'Blocker 1',
                'Blocker 2',
              ],
            ),
          ),
        ),
      );

      expect(find.text('Blocker 1'), findsOneWidget);
      expect(find.text('Blocker 2'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(2));
    });

    testWidgets('shows blocked status badge correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CapabilityCard(
              title: 'Test',
              description: 'Test',
              status: CapabilityStatus.blocked,
            ),
          ),
        ),
      );

      expect(find.text('Blocked'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('shows in progress status correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CapabilityCard(
              title: 'Test',
              description: 'Test',
              status: CapabilityStatus.inProgress,
            ),
          ),
        ),
      );

      expect(find.text('In Progress'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    });

    testWidgets('shows in review status correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CapabilityCard(
              title: 'Test',
              description: 'Test',
              status: CapabilityStatus.inReview,
            ),
          ),
        ),
      );

      expect(find.text('In Review'), findsOneWidget);
      expect(find.byIcon(Icons.pending), findsOneWidget);
    });
  });
}
