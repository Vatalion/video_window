enum PublishingStatus {
  draft,
  review,
  scheduled,
  published,
  archived,
  removed;

  String get label {
    switch (this) {
      case PublishingStatus.draft:
        return 'Draft';
      case PublishingStatus.review:
        return 'Review';
      case PublishingStatus.scheduled:
        return 'Scheduled';
      case PublishingStatus.published:
        return 'Published';
      case PublishingStatus.archived:
        return 'Archived';
      case PublishingStatus.removed:
        return 'Removed';
    }
  }
}