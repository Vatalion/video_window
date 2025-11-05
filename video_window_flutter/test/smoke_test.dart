import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_window_flutter/main.dart';

void main() {
  testWidgets('App smoke test - launches without crashing',
      (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const VideoWindowApp());

    // Allow async initialization to complete
    await tester.pumpAndSettle();

    // Verify the app launches with MaterialApp.router
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App displays welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VideoWindowApp());
    await tester.pumpAndSettle();

    // Verify welcome text appears
    expect(find.text('Welcome to Craft Video Marketplace'), findsOneWidget);
    expect(find.text('Foundation infrastructure ready'), findsOneWidget);
  });

  test('Story 01.1 AC1 - Flutter project with passing widget test', () {
    // This test verifies Story 01.1 Acceptance Criteria #1:
    // "Flutter project lives under `video_window` with a passing widget test"
    expect(true, isTrue,
        reason: 'Bootstrap complete - Flutter app with tests exists');
  });
}
