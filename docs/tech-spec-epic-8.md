# Epic 8: Story Publishing & Moderation Pipeline - Technical Specification

**Epic Goal:** Enable makers to review drafts, submit for moderation, publish approved content, and manage versioning with rollback capabilities.

**Stories:**
- 8-1: Draft Review & Publishing UI
- 8-2: Moderation Queue & Admin Tools
- 8-3: Publishing Workflow & Scheduling
- 8-4: Content Versioning & Rollback

## Architecture Overview

### Technology Stack
- **Flutter 3.19.6** for maker/admin UI
- **Serverpod 2.9.2** for moderation workflows
- **PostgreSQL 15** for content versioning
- **Redis 7.2.4** for moderation queue
- **AWS S3** for version snapshots

## Publishing States

### Content Lifecycle
```dart
enum PublishingStatus {
  draft,              // Maker editing
  pending_review,     // Submitted for moderation
  approved,           // Ready to publish
  published,          // Live on platform
  rejected,           // Moderation rejected
  taken_down,         // Removed from platform
  archived            // Maker archived
}
```

## Moderation Workflow

### Moderation Queue
```dart
class ModerationQueue {
  Future<List<Story>> getPendingStories({
    int limit = 50,
    ModerationPriority? priority,
  }) async {
    return await _repository.getStories(
      status: PublishingStatus.pending_review,
      orderBy: priority ?? ModerationPriority.flagged_first,
      limit: limit,
    );
  }
  
  Future<void> approveStory(String storyId, String moderatorId) async {
    await _repository.updateStatus(
      storyId,
      PublishingStatus.approved,
      moderatorId: moderatorId,
      timestamp: DateTime.now(),
    );
    
    // Notify maker
    await _notificationService.sendNotification(
      userId: story.makerId,
      type: NotificationType.content_approved,
      title: 'Your story "${story.title}" was approved!',
    );
  }
  
  Future<void> rejectStory(String storyId, String moderatorId, String reason) async {
    await _repository.updateStatus(
      storyId,
      PublishingStatus.rejected,
      moderatorId: moderatorId,
      rejectionReason: reason,
    );
    
    // Notify maker with reason
    await _notificationService.sendNotification(
      userId: story.makerId,
      type: NotificationType.content_rejected,
      title: 'Story needs updates',
      body: reason,
    );
  }
}
```

## Content Versioning

### Version Management
```dart
class ContentVersion {
  final String id;
  final String storyId;
  final int version;
  final Map<String, dynamic> snapshot;
  final String createdBy;
  final DateTime createdAt;
  final String? publishedAt;
}

class VersioningService {
  Future<void> createVersion(Story story) async {
    final version = ContentVersion(
      id: _generateUuid(),
      storyId: story.id,
      version: await _getNextVersion(story.id),
      snapshot: story.toJson(),
      createdBy: story.makerId,
      createdAt: DateTime.now(),
    );
    
    await _repository.saveVersion(version);
    await _s3Service.uploadSnapshot(version.id, version.snapshot);
  }
  
  Future<void> rollbackToVersion(String storyId, int targetVersion) async {
    final version = await _repository.getVersion(storyId, targetVersion);
    final story = Story.fromJson(version.snapshot);
    
    await _storyRepository.update(story);
    await createVersion(story); // Create new version of rollback
  }
}
```

## Scheduled Publishing

### Publishing Scheduler
```dart
class PublishingScheduler {
  Future<void> schedulePublishing(String storyId, DateTime publishAt) async {
    await _repository.setScheduledPublishTime(storyId, publishAt);
    
    // Schedule background job
    await _eventBridge.schedule(
      name: 'publish-story-$storyId',
      expression: 'at(${publishAt.toIso8601String()})',
      target: 'publish-story-function',
      input: {'storyId': storyId},
    );
  }
  
  Future<void> publishStory(String storyId) async {
    final story = await _repository.getStory(storyId);
    
    if (story.status != PublishingStatus.approved) {
      throw InvalidStateException('Story must be approved before publishing');
    }
    
    await _repository.updateStatus(storyId, PublishingStatus.published);
    await _cacheService.invalidateStory(storyId);
    await _searchService.indexStory(story);
    
    // Notify followers
    await _notificationService.notifyFollowers(
      makerId: story.makerId,
      storyId: storyId,
    );
  }
}
```

## Source Tree & File Directives

| Path | Action | Story | Notes |
| --- | --- | --- | --- |
| `video_window_flutter/packages/features/publishing/lib/presentation/pages/draft_review_page.dart` | create | 8.1 | Maker draft review UI |
| `video_window_flutter/packages/features/publishing/lib/presentation/pages/moderation_queue_page.dart` | create | 8.2 | Admin moderation interface |
| `video_window_server/lib/src/services/moderation_service.dart` | create | 8.2 | Moderation workflow logic |
| `video_window_server/lib/src/services/versioning_service.dart` | create | 8.4 | Content versioning |
| `video_window_server/lib/src/services/publishing_scheduler.dart` | create | 8.3 | Scheduled publishing |

## Success Criteria

- ✅ Moderation queue processes 100+ stories/day
- ✅ Publishing completes within 30 seconds
- ✅ Version rollback works 100% reliably
- ✅ Scheduled publishing accuracy ±2 minutes
- ✅ Maker notification sent within 5 minutes of moderation decision

---

**Version:** v1.0 (Definitive)
**Date:** 2025-10-30
**Dependencies:** Epic 7 (Story creation), Epic 11 (Notifications)
**Blocks:** Content going live on platform
