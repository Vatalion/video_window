enum TimelineTrackType { video, audio, text }

extension TimelineTrackTypeX on TimelineTrackType {
  String get label {
    switch (this) {
      case TimelineTrackType.video:
        return 'Video';
      case TimelineTrackType.audio:
        return 'Audio';
      case TimelineTrackType.text:
        return 'Text';
    }
  }
}
