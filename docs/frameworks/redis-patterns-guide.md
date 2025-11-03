# Redis Patterns Guide - Video Window

**Version:** Redis 6.2.6  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Cache & Queues

---

## Overview

Redis provides caching and task queues for Video Window via Serverpod integration.

---

## Use Cases

### 1. Caching (Session Data)

```dart
// Serverpod handles Redis automatically for sessions
// No manual Redis interaction needed
```

### 2. Task Queues (Future Work)

```dart
// Serverpod uses Redis for background tasks
await session.messages.postMessage('video_processing', {
  'storyId': story.id,
  'videoUrl': videoUrl,
});
```

### 3. Rate Limiting (Future)

```dart
// Track API rate limits
final key = 'rate_limit:${userId}:${endpoint}';
final count = await redis.incr(key);
if (count == 1) {
  await redis.expire(key, 60);  // 60 second window
}
if (count > maxRequests) {
  throw RateLimitException();
}
```

---

## Common Patterns

### Pattern 1: Simple Cache

```dart
// Key structure: {namespace}:{identifier}:{field}
// Example: story:123:view_count

// Get
final value = await redis.get('story:123:view_count');

// Set with expiry
await redis.setex('story:123:view_count', 3600, '42');  // 1 hour TTL
```

### Pattern 2: Lists (Queues)

```dart
// Push to queue
await redis.lpush('video_processing_queue', jsonEncode(job));

// Pop from queue
final job = await redis.rpop('video_processing_queue');
```

### Pattern 3: Sets (Unique Collections)

```dart
// Add to set
await redis.sadd('user:123:viewed_stories', 'story_456');

// Check membership
final hasViewed = await redis.sismember('user:123:viewed_stories', 'story_456');

// Get all members
final viewedStories = await redis.smembers('user:123:viewed_stories');
```

---

## Key Naming Conventions

```
{namespace}:{identifier}:{field}

Examples:
- user:123:session
- story:456:view_count
- auction:789:high_bid
- cache:feed:page_1
```

---

## TTL (Time To Live)

```dart
// Set TTL on creation
await redis.setex('key', 3600, 'value');  // 1 hour

// Set TTL on existing key
await redis.expire('key', 3600);

// Remove TTL
await redis.persist('key');

// Check remaining TTL
final ttl = await redis.ttl('key');  // Seconds remaining
```

---

## Video Window Usage

### Current
- ✅ Session storage (Serverpod automatic)
- ✅ Task queue infrastructure (Serverpod automatic)

### Future Sprints
- Epic 06: Video transcoding job queue
- Epic 09: Auction timer management
- Epic 17: Analytics event buffering

---

## Performance Tips

- **Use pipelines** for multiple commands
- **Set TTLs** on all cache keys to prevent memory bloat
- **Namespace keys** to avoid collisions
- **Use appropriate data structures** (String vs List vs Set)

---

## Reference

- **Redis Docs:** https://redis.io/docs/
- **Serverpod Redis:** https://docs.serverpod.dev/concepts/caching

---

**Last Updated:** 2025-11-03 by Winston
