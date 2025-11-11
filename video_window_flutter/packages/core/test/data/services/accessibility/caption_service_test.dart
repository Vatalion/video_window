import 'package:flutter_test/flutter_test.dart';
import 'package:core/data/services/accessibility/caption_service.dart';

void main() {
  group('CaptionService', () {
    late CaptionService service;

    setUp(() {
      service = CaptionService();
    });

    test('parses WebVTT content correctly', () {
      const vttContent = '''
WEBVTT

00:00:00.000 --> 00:00:05.000
Hello, welcome to this story.

00:00:05.000 --> 00:00:10.000
This is the second caption.

00:00:10.000 --> 00:00:15.000
And this is the third one.
''';

      final cues = service.parseWebVTT(vttContent);

      expect(cues.length, equals(3));
      expect(cues[0].text, equals('Hello, welcome to this story.'));
      expect(cues[0].start, equals(const Duration(seconds: 0)));
      expect(cues[0].end, equals(const Duration(seconds: 5)));

      expect(cues[1].text, equals('This is the second caption.'));
      expect(cues[1].start, equals(const Duration(seconds: 5)));
      expect(cues[1].end, equals(const Duration(seconds: 10)));

      expect(cues[2].text, equals('And this is the third one.'));
      expect(cues[2].start, equals(const Duration(seconds: 10)));
      expect(cues[2].end, equals(const Duration(seconds: 15)));
    });

    test('parses WebVTT with MM:SS format', () {
      const vttContent = '''
WEBVTT

00:00 --> 00:05
Short format test.
''';

      final cues = service.parseWebVTT(vttContent);

      expect(cues.length, equals(1));
      expect(cues[0].start, equals(const Duration(minutes: 0, seconds: 0)));
      expect(cues[0].end, equals(const Duration(minutes: 0, seconds: 5)));
    });

    test('gets active cues for position', () {
      final cues = [
        CaptionCue(
          start: const Duration(seconds: 0),
          end: const Duration(seconds: 5),
          text: 'First',
        ),
        CaptionCue(
          start: const Duration(seconds: 5),
          end: const Duration(seconds: 10),
          text: 'Second',
        ),
        CaptionCue(
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 15),
          text: 'Third',
        ),
      ];

      // At 7 seconds, should return second cue
      final activeCues =
          service.getActiveCues(cues, const Duration(seconds: 7));
      expect(activeCues.length, equals(1));
      expect(activeCues[0].text, equals('Second'));

      // At 0 seconds, should return first cue
      final activeCuesAtStart =
          service.getActiveCues(cues, const Duration(seconds: 0));
      expect(activeCuesAtStart.length, equals(1));
      expect(activeCuesAtStart[0].text, equals('First'));

      // At 12 seconds, should return third cue
      final activeCuesAtMiddle =
          service.getActiveCues(cues, const Duration(seconds: 12));
      expect(activeCuesAtMiddle.length, equals(1));
      expect(activeCuesAtMiddle[0].text, equals('Third'));

      // At 20 seconds, should return empty
      final activeCuesAtEnd =
          service.getActiveCues(cues, const Duration(seconds: 20));
      expect(activeCuesAtEnd, isEmpty);
    });

    test('handles overlapping cues', () {
      final cues = [
        CaptionCue(
          start: const Duration(seconds: 0),
          end: const Duration(seconds: 10),
          text: 'First',
        ),
        CaptionCue(
          start: const Duration(seconds: 5),
          end: const Duration(seconds: 15),
          text: 'Second',
        ),
      ];

      // At 7 seconds, both cues should be active
      final activeCues =
          service.getActiveCues(cues, const Duration(seconds: 7));
      expect(activeCues.length, equals(2));
    });

    test('formats cue text with high contrast', () {
      final cue = CaptionCue(
        start: const Duration(seconds: 0),
        end: const Duration(seconds: 5),
        text: 'Test caption',
      );

      final formatted = service.formatCueText(cue, highContrast: true);
      expect(formatted, equals('Test caption'));
    });
  });
}
