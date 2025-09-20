enum SegmentTransitionType { none, fade, crossFade, slide, wipe }

extension SegmentTransitionTypeX on SegmentTransitionType {
  String get label {
    switch (this) {
      case SegmentTransitionType.none:
        return 'None';
      case SegmentTransitionType.fade:
        return 'Fade';
      case SegmentTransitionType.crossFade:
        return 'Cross Fade';
      case SegmentTransitionType.slide:
        return 'Slide';
      case SegmentTransitionType.wipe:
        return 'Wipe';
    }
  }
}
