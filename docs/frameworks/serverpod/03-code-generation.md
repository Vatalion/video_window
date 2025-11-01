# Serverpod Code Generation Workflow

**Version:** Serverpod 2.9.x  
**Last Updated:** 2025-10-30

---

## Overview

Serverpod uses code generation to create type-safe clients and shared models from protocol definitions. This guide covers the complete workflow.

---

## When to Generate Code

Run `serverpod generate` after:
- Creating/modifying protocol files (`.yaml` in `lib/src/protocol/`)
- Changing endpoint signatures
- Updating database table definitions
- Adding new endpoints or models

---

## Protocol Files

### Location
`video_window_server/lib/src/protocol/`

### Syntax Example

```yaml
# user.yaml
class: User
table: users
fields:
  id: int, primary, autoIncrement
  email: String, unique
  displayName: String?
  avatarUrl: String?
  role: UserRole
  createdAt: DateTime
  updatedAt: DateTime

indexes:
  email_idx:
    fields: email
    unique: true
```

### Field Types
- **Primitives:** `int`, `double`, `String`, `bool`, `DateTime`, `ByteData`
- **Nullable:** Add `?` suffix (e.g., `String?`)
- **Relations:** Use `parent=ClassName`
- **Enums:** Define separately

### Enum Example

```yaml
# user_role.yaml
enum: UserRole
values:
  - viewer
  - maker
  - admin
```

---

## Running Code Generation

### Command

```bash
cd video_window_server
serverpod generate
```

### What Gets Generated

1. **Server Code:**
   - `lib/src/generated/protocol.dart`
   - `lib/src/generated/endpoints.dart`

2. **Client Code** (`video_window_client/`):
   - `lib/src/protocol/*.dart` - All models
   - `lib/src/endpoints/*.dart` - Endpoint clients

3. **Shared Code** (`video_window_shared/`):
   - Shared model definitions

### Output Example

```
Generating code...
✓ Protocol classes generated
✓ Endpoint clients generated
✓ Database models generated
✓ Client package updated
✓ Shared package updated

Generation complete! (2.3s)
```

---

## Integration with Flutter

### Using Generated Models

```dart
import 'package:video_window_client/video_window_client.dart';

// Models are strongly typed
final user = User(
  id: 1,
  email: 'maker@example.com',
  displayName: 'Jane Smith',
  role: UserRole.maker,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

### Calling Endpoints

```dart
// Client is auto-configured with all endpoints
final client = Client('http://localhost:8080/');

// Type-safe endpoint calls
final stories = await client.story.getHomeFeed(
  page: 1,
  limit: 20,
);

// Results are strongly typed
for (final story in stories) {
  print('${story.title} by ${story.maker.displayName}');
}
```

---

## Common Issues

### Issue: "Protocol file has errors"
**Solution:** Check YAML syntax
```yaml
# ❌ BAD - Missing colon
fields
  id: int

# ✅ GOOD
fields:
  id: int
```

### Issue: "Circular dependency detected"
**Solution:** Use forward references
```yaml
# story.yaml
class: Story
fields:
  makerId: int, parent=User
  # Don't include full User object
```

### Issue: "Generated code out of sync"
**Solution:** Clean and regenerate
```bash
cd video_window_server
rm -rf lib/src/generated/
serverpod generate
```

---

## Best Practices

### 1. Version Control
```bash
# Commit protocol files
git add lib/src/protocol/*.yaml

# DO NOT commit generated code
# (already in .gitignore)
```

### 2. Run After Pull
```bash
git pull
cd video_window_server
serverpod generate  # Ensure sync with team changes
```

### 3. CI/CD Integration
```yaml
# .github/workflows/serverpod-ci.yml
- name: Generate Serverpod code
  run: |
    cd video_window_server
    serverpod generate
    
- name: Verify no changes
  run: git diff --exit-code lib/src/generated/
```

---

## Related Documentation

- **Setup:** [01-setup-installation.md](./01-setup-installation.md)
- **Project Structure:** [02-project-structure.md](./02-project-structure.md)
- **Database:** [04-database-migrations.md](./04-database-migrations.md)

---

**Key Takeaway:** Always run `serverpod generate` after protocol changes, and never manually edit generated code.
