# PostgreSQL Patterns Guide - Video Window

**Version:** PostgreSQL 16.10  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Primary Database

---

## Overview

PostgreSQL is Video Window's primary relational database, managed by Serverpod. This guide covers schema patterns, NOT raw SQL (Serverpod handles that).

---

## Serverpod Schema Definition

### Define Models

```yaml
# video_window_server/lib/src/protocol/user.yaml
class: User
table: users
fields:
  id: String, primary
  email: String, unique
  displayName: String
  createdAt: DateTime
  lastLoginAt: DateTime?
  isActive: bool, default=true
indexes:
  email_idx:
    fields: email
    unique: true
```

### Generate Code

```bash
cd video_window_server
serverpod generate
```

---

## Common Patterns

### Pattern 1: Relationships

```yaml
# One-to-Many: User has many Stories
class: Story
table: stories
fields:
  id: String, primary
  title: String
  userId: String, foreign=User.id
  createdAt: DateTime
```

### Pattern 2: Indexes

```yaml
class: Auction
table: auctions
fields:
  id: String, primary
  storyId: String
  endsAt: DateTime
  status: String
indexes:
  status_ends_idx:
    fields: status, endsAt  # Composite index
  story_idx:
    fields: storyId
```

### Pattern 3: JSONB Fields

```yaml
class: Story
table: stories
fields:
  id: String, primary
  metadata: Map<String, dynamic>  # Stored as JSONB
```

---

## Query Patterns (via Serverpod)

```dart
// Find by ID
final user = await User.findById(session, userId);

// Find with conditions
final activeUsers = await User.find(
  session,
  where: (t) => t.isActive.equals(true),
);

// Order and limit
final recentStories = await Story.find(
  session,
  orderBy: (t) => t.createdAt,
  orderDescending: true,
  limit: 10,
);

// Count
final userCount = await User.count(session);
```

---

## Migrations

```bash
# Create migration
cd video_window_server
serverpod create-migration

# Apply migration
dart run bin/main.dart --apply-migrations

# Rollback (manual)
psql -U postgres -d video_window -f migrations/rollback_001.sql
```

---

## Video Window Schema Conventions

### Table Naming
- `snake_case` plural: `users`, `auction_bids`

### Column Naming
- `snake_case`: `created_at`, `user_id`

### Primary Keys
- Always `id` of type `String` (UUIDs)

### Timestamps
- `created_at` (required)
- `updated_at` (optional)
- `deleted_at` (soft deletes)

### Foreign Keys
- Pattern: `{table_singular}_id` (e.g., `user_id`)

---

## Performance Tips

```yaml
# Add indexes for:
# - Foreign keys
# - WHERE clause fields
# - ORDER BY fields
# - Composite queries

indexes:
  user_created_idx:
    fields: userId, createdAt  # For queries filtering by user and sorting by date
```

---

## Reference

- **PostgreSQL Docs:** https://www.postgresql.org/docs/16/
- **Serverpod Database:** https://docs.serverpod.dev/concepts/database

---

**Last Updated:** 2025-11-03 by Winston
