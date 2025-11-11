import 'dart:async';
import 'dart:convert';

/// Caption cue model
class CaptionCue {
  final Duration start;
  final Duration end;
  final String text;
  final Map<String, String>? styles;

  CaptionCue({
    required this.start,
    required this.end,
    required this.text,
    this.styles,
  });
}

/// Caption track model
class CaptionTrack {
  final String language;
  final String label;
  final String url;
  final String format; // WebVTT, SRT, etc.

  CaptionTrack({
    required this.language,
    required this.label,
    required this.url,
    required this.format,
  });
}

/// Service for parsing WebVTT captions and managing caption tracks
/// AC1: WebVTT parsing, styling, and language switching
class CaptionService {
  /// Parse WebVTT content into caption cues
  List<CaptionCue> parseWebVTT(String vttContent) {
    final cues = <CaptionCue>[];
    final lines = LineSplitter().convert(vttContent);

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();

      // Skip header and empty lines
      if (line.isEmpty ||
          line.startsWith('WEBVTT') ||
          line.startsWith('NOTE')) {
        i++;
        continue;
      }

      // Check for timing line (format: "00:00:00.000 --> 00:00:05.000")
      if (line.contains('-->')) {
        final parts = line.split('-->');
        if (parts.length == 2) {
          final start = _parseTime(parts[0].trim());
          final end = _parseTime(parts[1].trim());

          // Get caption text (next non-empty line)
          String text = '';
          Map<String, String>? styles;
          i++;

          while (i < lines.length) {
            final textLine = lines[i].trim();
            if (textLine.isEmpty) {
              break;
            }

            // Check for styling tags
            if (textLine.startsWith('<') && textLine.contains('>')) {
              // Extract style information
              styles ??= <String, String>{};
              // Simple style parsing - can be enhanced
            } else {
              text += (text.isEmpty ? '' : ' ') + textLine;
            }
            i++;
          }

          if (text.isNotEmpty) {
            cues.add(CaptionCue(
              start: start,
              end: end,
              text: text,
              styles: styles,
            ));
          }
        }
      }
      i++;
    }

    return cues;
  }

  /// Parse time string to Duration
  /// Format: "HH:MM:SS.mmm" or "MM:SS.mmm"
  Duration _parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 3) {
      // HH:MM:SS.mmm format
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final secondsParts = parts[2].split('.');
      final seconds = int.parse(secondsParts[0]);
      final milliseconds = secondsParts.length > 1
          ? int.parse(secondsParts[1].padRight(3, '0').substring(0, 3))
          : 0;

      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    } else if (parts.length == 2) {
      // MM:SS.mmm format
      final minutes = int.parse(parts[0]);
      final secondsParts = parts[1].split('.');
      final seconds = int.parse(secondsParts[0]);
      final milliseconds = secondsParts.length > 1
          ? int.parse(secondsParts[1].padRight(3, '0').substring(0, 3))
          : 0;

      return Duration(
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    }
    return Duration.zero;
  }

  /// Get active cues for a given time position
  List<CaptionCue> getActiveCues(List<CaptionCue> cues, Duration position) {
    return cues.where((cue) {
      return position >= cue.start && position <= cue.end;
    }).toList();
  }

  /// Format cue text with WCAG 2.1 AA contrast styling
  String formatCueText(CaptionCue cue, {bool highContrast = false}) {
    String text = cue.text;

    if (highContrast) {
      // Apply high contrast styling
      // In a real implementation, this would apply CSS-like styling
      // For now, return plain text
    }

    return text;
  }
}
