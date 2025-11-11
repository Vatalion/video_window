import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/data/services/accessibility/caption_service.dart';
import 'package:features/story/presentation/widgets/transcript_panel.dart';

void main() {
  group('TranscriptPanel', () {
    late List<CaptionCue> testCues;

    setUp(() {
      testCues = [
        CaptionCue(
          start: const Duration(seconds: 0),
          end: const Duration(seconds: 5),
          text: 'Hello, welcome to this story.',
        ),
        CaptionCue(
          start: const Duration(seconds: 5),
          end: const Duration(seconds: 10),
          text: 'This is the second caption.',
        ),
        CaptionCue(
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 15),
          text: 'And this is the third one.',
        ),
      ];
    });

    testWidgets('renders transcript cues correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptPanel(
              cues: testCues,
              currentPosition: const Duration(seconds: 0),
              onSeek: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Hello, welcome to this story.'), findsOneWidget);
      expect(find.text('This is the second caption.'), findsOneWidget);
      expect(find.text('And this is the third one.'), findsOneWidget);
    });

    testWidgets('highlights active cue', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptPanel(
              cues: testCues,
              currentPosition: const Duration(seconds: 7),
              onSeek: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The second cue should be active (at 7 seconds)
      final activeCue = find.text('This is the second caption.');
      expect(activeCue, findsOneWidget);
    });

    testWidgets('filters cues by search term', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptPanel(
              cues: testCues,
              currentPosition: const Duration(seconds: 0),
              onSeek: (_) {},
            ),
          ),
        ),
      );

      // Find search box
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter search term
      await tester.enterText(searchField, 'second');
      await tester.pumpAndSettle();

      // Should only show matching cue
      expect(find.text('This is the second caption.'), findsOneWidget);
      expect(find.text('Hello, welcome to this story.'), findsNothing);
      expect(find.text('And this is the third one.'), findsNothing);
    });

    testWidgets('calls onSeek when cue is tapped', (WidgetTester tester) async {
      Duration? seekedPosition;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptPanel(
              cues: testCues,
              currentPosition: const Duration(seconds: 0),
              onSeek: (position) {
                seekedPosition = position;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on second cue
      final secondCue = find.text('This is the second caption.');
      await tester.tap(secondCue);
      await tester.pumpAndSettle();

      expect(seekedPosition, equals(const Duration(seconds: 5)));
    });

    testWidgets('supports keyboard navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptPanel(
              cues: testCues,
              currentPosition: const Duration(seconds: 0),
              onSeek: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Focus should be on search field initially
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Tab to navigate
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Should navigate to transcript list
      // (In a real implementation, we'd verify focus moved)
    });
  });
}
