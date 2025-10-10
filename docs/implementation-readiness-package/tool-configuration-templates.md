# Tool Configuration Templates

**Pre-configured Templates for Jira, Slack, GitHub, and Development Tools**
**Version:** 1.0
**Date:** 2025-10-09

## Overview

This section provides ready-to-use configuration templates for all essential development and project management tools. These templates are pre-configured for the Craft Video Marketplace project and can be immediately deployed.

## GitHub Configuration

### Repository Settings

#### `.github/settings.yml`
```yaml
# GitHub repository configuration
# Apply using: gh repo edit --settings-file .github/settings.yml

repository:
  name: "video-window"
  description: "Craft Video Marketplace - Flutter + Serverpod"
  homepage: "https://craft.marketplace"
  topics: ["flutter", "serverpod", "video-marketplace", "mobile-app"]

  # Basic settings
  private: false
  has_issues: true
  has_projects: true
  has_wiki: false
  has_downloads: false
  is_template: false

  # Merge settings
  allow_squash_merge: true
  allow_merge_commit: false
  allow_rebase_merge: false
  delete_branch_on_merge: true

  # Collaboration
  allow_auto_merge: false
  allow_forking: true
  allow_update_branch: true

  # Security
  default_branch: "develop"
  require_signed_commits: false
  require_linear_history: true
```

### Branch Protection Rules

#### `.github/branch-protection.yml`
```yaml
# Branch protection rules for main and develop branches
# Apply via GitHub repository settings

protection_rules:
  develop:
    required_status_checks:
      strict: true
      contexts:
        - "format (3.19.6)"
        - "analyze (3.19.6)"
        - "test (3.19.6)"
        - "build_ios (3.19.6)"
        - "build_android (3.19.6)"

    enforce_admins: false
    required_pull_request_reviews:
      required_approving_review_count: 1
      dismiss_stale_reviews: true
      require_code_owner_reviews: false
      require_last_push_approval: true

    restrictions: null
    allow_force_pushes: false
    allow_deletions: false

  main:
    required_status_checks:
      strict: true
      contexts:
        - "format (3.19.6)"
        - "analyze (3.19.6)"
        - "test (3.19.6)"
        - "integration_tests (3.19.6)"
        - "security_scan (3.19.6)"

    enforce_admins: true
    required_pull_request_reviews:
      required_approving_review_count: 2
      dismiss_stale_reviews: true
      require_code_owner_reviews: true
      require_last_push_approval: true

    restrictions:
      users: ["tech-lead", "devops-lead"]
      teams: ["core-team"]

    allow_force_pushes: false
    allow_deletions: false
```

### Issue Templates

#### `.github/ISSUE_TEMPLATE/bug_report.md`
```markdown
---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## Describe the Bug
A clear and concise description of what the bug is.

## To Reproduce
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## Expected Behavior
A clear and concise description of what you expected to happen.

## Screenshots
If applicable, add screenshots to help explain your problem.

## Environment
 - OS: [e.g. iOS 16.0, Android 13]
 - App Version: [e.g. 1.0.0]
 - Device: [e.g. iPhone 14 Pro, Pixel 7]

## Additional Context
Add any other context about the problem here.

## Logs
```
Add relevant logs here
```

## Story Reference
Link to related Jira story if applicable.
```

#### `.github/ISSUE_TEMPLATE/feature_request.md`
```markdown
---
name: Feature Request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Feature Description
A clear and concise description of the feature you'd like to see added.

## Problem Statement
What problem does this feature solve? What pain point does it address?

## Proposed Solution
Describe the solution you'd like in detail.

## Alternatives Considered
Describe any alternative solutions or features you've considered.

## Additional Context
Add any other context or screenshots about the feature request here.

## Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2
- [ ] Criteria 3

## Story Reference
Link to related Jira story if applicable.
```

### Pull Request Template

#### `.github/pull_request_template.md`
```markdown
## Description
Brief description of changes made in this pull request.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Issue Reference
Fixes # (issue number)
Related to # (issue number)

## Testing
- [ ] Unit tests pass locally
- [ ] Integration tests pass locally
- [ ] Manual testing completed
- [ ] Accessibility verified (screen reader, contrast, touch targets)
- [ ] Performance tested (no memory leaks, smooth animations)

## Screenshots
If applicable, add screenshots to help explain your changes.

## Checklist
- [ ] My code follows the project's coding standards
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published in downstream modules

## Performance Impact
- [ ] No performance impact
- [ ] Minor performance impact (<5% slower)
- [ ] Major performance impact (requires separate discussion)

## Security Considerations
- [ ] No security implications
- [ ] Security review required (describe implications)

## Deployment Notes
Any special considerations for deployment:

## Story Points
Estimated: [story points]
Actual: [story points]
```

### GitHub Actions Workflows

#### `.github/workflows/ci.yml`
```yaml
name: CI

on:
  push:
    branches: [develop, main]
  pull_request:
    branches: [develop]

env:
  FLUTTER_VERSION: '3.19.6'
  DART_VERSION: '3.5.6'

jobs:
  format:
    name: Format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - name: Verify formatting
        run: dart format --set-exit-if-changed .

  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - name: Install dependencies
        run: flutter pub get
      - name: Analyze
        run: flutter analyze --fatal-infos --fatal-warnings

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - name: Install dependencies
        run: flutter pub get
      - name: Run tests
        run: flutter test --no-pub --coverage
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

  build_android:
    name: Build Android
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - name: Build APK
        run: flutter build apk --debug
      - name: Build app bundle
        run: flutter build appbundle --debug

  build_ios:
    name: Build iOS
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable
      - name: Build iOS
        run: flutter build ios --debug --simulator

  security_scan:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
```

## Jira Configuration

### Project Settings Template

#### Jira Project Configuration
```json
{
  "project": {
    "key": "CVM",
    "name": "Craft Video Marketplace",
    "type": "Software",
    "template": "Scrum",
    "lead": "product-manager",
    "avatar": "https://example.com/avatar.png"
  },
  "workflows": {
    "story_workflow": {
      "name": "Story Workflow",
      "statuses": [
        {"name": "Backlog", "category": "TO_DO"},
        {"name": "Ready for Dev", "category": "IN_PROGRESS"},
        {"name": "In Development", "category": "IN_PROGRESS"},
        {"name": "In Review", "category": "IN_PROGRESS"},
        {"name": "Ready for QA", "category": "IN_PROGRESS"},
        {"name": "In QA", "category": "IN_PROGRESS"},
        {"name": "Done", "category": "DONE"}
      ],
      "transitions": [
        {"from": "Backlog", "to": "Ready for Dev"},
        {"from": "Ready for Dev", "to": "In Development"},
        {"from": "In Development", "to": "In Review"},
        {"from": "In Review", "to": "Ready for QA"},
        {"from": "Ready for QA", "to": "In QA"},
        {"from": "In QA", "to": "Done"},
        {"from": "In QA", "to": "In Development"}
      ]
    }
  },
  "issue_types": {
    "story": {
      "name": "Story",
      "description": "User story or feature implementation",
      "fields": [
        "summary",
        "description",
        "priority",
        "labels",
        "components",
        "fixVersions",
        "customfield_10001" // Story Points
      ]
    },
    "bug": {
      "name": "Bug",
      "description": "Software bug that needs fixing",
      "fields": [
        "summary",
        "description",
        "priority",
        "labels",
        "components",
        "customfield_10002" // Severity
      ]
    },
    "task": {
      "name": "Task",
      "description": "General task that doesn't fit other categories",
      "fields": [
        "summary",
        "description",
        "priority",
        "labels",
        "components"
      ]
    }
  }
}
```

### Custom Fields

#### Custom Field Definitions
```json
{
  "custom_fields": {
    "story_points": {
      "name": "Story Points",
      "type": "number",
      "searcher": "exact number search",
      "description": "Estimated effort using Fibonacci sequence"
    },
    "severity": {
      "name": "Severity",
      "type": "select",
      "options": [
        {"value": "Critical", "description": "Blocks release or critical functionality"},
        {"value": "High", "description": "Major impact on user experience"},
        {"value": "Medium", "description": "Moderate impact, workarounds available"},
        {"value": "Low", "description": "Minor issue, cosmetic or edge case"}
      ]
    },
    "device_type": {
      "name": "Device Type",
      "type": "multi select",
      "options": [
        {"value": "iOS", "description": "Apple iOS devices"},
        {"value": "Android", "description": "Android devices"},
        {"value": "Web", "description": "Web browsers"},
        {"value": "Backend", "description": "Server-side issues"}
      ]
    },
    "acceptance_criteria": {
      "name": "Acceptance Criteria",
      "type": "text area",
      "description": "Clear criteria for when the story is complete"
    }
  }
}
```

### Board Configuration

#### Scrum Board Template
```json
{
  "board": {
    "name": "Craft Video Marketplace Board",
    "type": "scrum",
    "columns": [
      {
        "name": "Backlog",
        "statuses": ["Backlog"],
        "maxIssues": 50
      },
      {
        "name": "Ready for Dev",
        "statuses": ["Ready for Dev"],
        "maxIssues": 10
      },
      {
        "name": "In Development",
        "statuses": ["In Development"],
        "maxIssues": 8
      },
      {
        "name": "In Review",
        "statuses": ["In Review"],
        "maxIssues": 5
      },
      {
        "name": "Ready for QA",
        "statuses": ["Ready for QA"],
        "maxIssues": 5
      },
      {
        "name": "In QA",
        "statuses": ["In QA"],
        "maxIssues": 3
      },
      {
        "name": "Done",
        "statuses": ["Done"],
        "maxIssues": null
      }
    ],
    "swimlanes": [
      {
        "name": "All Issues",
        "type": "default"
      },
      {
        "name": "By Priority",
        "type": "queries",
        "queries": [
          {"name": "High", "query": "priority = Highest OR priority = High"},
          {"name": "Medium", "query": "priority = Medium"},
          {"name": "Low", "query": "priority = Lowest OR priority = Low"}
        ]
      }
    ]
  }
}
```

### Sprint Template

#### Sprint Configuration
```json
{
  "sprint_template": {
    "name": "Sprint {number}",
    "state": "active",
    "startDate": "{start_date}",
    "endDate": "{end_date}",
    "goal": "{sprint_goal}",
    "capacity": {
      "development_team": 40,
      "qa_team": 10,
      "total": 50
    },
    "default_velocity": 25,
    "stories": [],
    "notes": "Sprint notes and objectives"
  }
}
```

## Slack Configuration

### Workspace Setup

#### Channel Configuration
```json
{
  "channels": {
    "#general": {
      "purpose": "Project announcements and updates",
      "topic": "Craft Video Marketplace - General Channel",
      "members": ["all-team"],
      "private": false,
      "archived": false
    },
    "#development": {
      "purpose": "Technical discussions and development questions",
      "topic": "Flutter, Serverpod, and technical discussions",
      "members": ["developers", "tech-lead", "devops-lead"],
      "private": false,
      "archived": false
    },
    "#reviews": {
      "purpose": "Code review requests and feedback",
      "topic": "Pull requests, code reviews, and quality discussions",
      "members": ["developers", "tech-lead", "qa-team"],
      "private": false,
      "archived": false
    },
    "#design": {
      "purpose": "UI/UX design discussions and reviews",
      "topic": "Design system, user experience, and accessibility",
      "members": ["designers", "developers", "product-manager"],
      "private": false,
      "archived": false
    },
    "#devops": {
      "purpose": "Infrastructure, deployment, and operations",
      "topic": "CI/CD, infrastructure, and monitoring",
      "members": ["devops-lead", "tech-lead"],
      "private": false,
      "archived": false
    },
    "#qa": {
      "purpose": "Quality assurance and testing discussions",
      "topic": "Testing, quality, and bug tracking",
      "members": ["qa-team", "developers", "tech-lead"],
      "private": false,
      "archived": false
    },
    "#product": {
      "purpose": "Product management and planning",
      "topic": "Product requirements, planning, and strategy",
      "members": ["product-manager", "tech-lead", "designers"],
      "private": false,
      "archived": false
    },
    "#incidents": {
      "purpose": "Production incidents and emergency response",
      "topic": "Critical issues and incident response",
      "members": ["all-team"],
      "private": false,
      "archived": false
    },
    "#random": {
      "purpose": "Non-work related conversations",
      "topic": "Water cooler discussions",
      "members": ["all-team"],
      "private": false,
      "archived": false
    }
  }
}
```

### Bot Configuration

#### GitHub Integration Bot
```yaml
# GitHub Bot Configuration for Slack
name: GitHub Bot
description: Integrates GitHub activities with Slack

webhooks:
  - event: pull_request
    channel: "#reviews"
    message_template: |
      🔄 **Pull Request {action}**
      **Title:** {title}
      **Author:** {user}
      **Branch:** {branch} → {base_branch}
      **Link:** {url}
      {#if reviewers}
      **Reviewers:** {reviewers}
      {/if}

  - event: push
    channel: "#development"
    message_template: |
      📤 **Push to {branch}**
      **Author:** {user}
      **Commits:** {commit_count}
      **Link:** {compare_url}

  - event: issues
    channel: "#development"
    message_template: |
      🐛 **Issue {action}**
      **Title:** {title}
      **Author:** {user}
      **Labels:** {labels}
      **Link:** {url}

  - event: deployment
    channel: "#devops"
    message_template: |
      🚀 **Deployment {status}**
      **Environment:** {environment}
      **Commit:** {commit}
      **Author:** {user}
      **Link:** {url}
```

#### Jira Integration Bot
```yaml
# Jira Bot Configuration for Slack
name: Jira Bot
description: Integrates Jira activities with Slack

webhooks:
  - event: issue_created
    channel: "#development"
    message_template: |
      ✨ **New Issue Created**
      **Key:** {key}
      **Type:** {issue_type}
      **Summary:** {summary}
      **Assignee:** {assignee}
      **Priority:** {priority}
      **Link:** {url}

  - event: issue_updated
    channel: "#development"
    message_template: |
      📝 **Issue Updated**
      **Key:** {key}
      **Field:** {field}
      **Old Value:** {old_value}
      **New Value:** {new_value}
      **Updated By:** {user}
      **Link:** {url}

  - event: sprint_started
    channel: "#general"
    message_template: |
      🏁 **Sprint Started**
      **Sprint:** {sprint_name}
      **Goal:** {sprint_goal}
      **Duration:** {start_date} - {end_date}
      **Stories:** {story_count}

  - event: sprint_completed
    channel: "#general"
    message_template: |
      🎉 **Sprint Completed**
      **Sprint:** {sprint_name}
      **Completed Stories:** {completed_stories}/{total_stories}
      **Story Points:** {completed_points}/{planned_points}
      **Velocity:** {velocity_percentage}%
```

### Custom Commands

#### Useful Slack Commands
```json
{
  "slash_commands": {
    "/standup": {
      "description": "Post daily standup update",
      "usage": "/standup [yesterday] [today] [blockers]",
      "response_type": "in_channel"
    },
    "/review": {
      "description": "Request code review",
      "usage": "/review [pr_url] [reviewers]",
      "response_type": "in_channel"
    },
    "/deploy": {
      "description": "Trigger deployment",
      "usage": "/deploy [environment] [branch]",
      "response_type": "in_channel"
    },
    "/help": {
      "description": "Show available commands",
      "usage": "/help",
      "response_type": "ephemeral"
    },
    "/incident": {
      "description": "Report incident",
      "usage": "/incident [severity] [description]",
      "response_type": "in_channel",
      "channel": "#incidents"
    }
  }
}
```

## Development Tools Configuration

### VS Code Configuration

#### Workspace Settings (`.vscode/settings.json`)
```json
{
  "dart.flutterSdkPath": "flutter",
  "dart.lineLength": 80,
  "editor.rulers": [80],
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "editor.formatOnSave": true,
  "editor.formatOnType": true,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true,
  "dart.debugExternalLibraries": false,
  "dart.debugSdkLibraries": false,
  "dart.previewLsp": true,
  "search.exclude": {
    "**/.git": true,
    "**/.dart_tool": true,
    "**/build": true,
    "**/ios/Pods": true,
    "**/android/.gradle": true
  },
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/node_modules/**": true,
    "**/android/.gradle/**": true,
    "**/ios/Pods/**": true,
    "**/build/**": true
  },
  "emmet.includeLanguages": {
    "dart": "html"
  },
  "dart.completeFunctionCalls": true,
  "dart.closingLabels": true,
  "dart.flutterOutline": true,
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true,
  "terminal.integrated.shell.osx": "/bin/zsh"
}
```

#### Extensions (`.vscode/extensions.json`)
```json
{
  "recommendations": [
    "Dart-Code.flutter",
    "Dart-Code.dart-code",
    "eamodio.gitlens",
    "esbenp.prettier-vscode",
    "redhat.vscode-yaml",
    "ms-vscode.vscode-json",
    "bradlc.vscode-tailwindcss",
    "formulahendry.auto-rename-tag",
    "christian-kohler.path-intellisense",
    "ms-vscode.hexeditor",
    "ms-vscode.test-adapter-converter",
    "Dart-Code.test-explorer",
    "nash.awesome-flutter-snippets",
    "jeroen-meijer.pubspec-assist",
    "robert-brunhage.flutter-riverpod-snippets"
  ]
}
```

#### Tasks (`.vscode/tasks.json`)
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Flutter: Get Packages",
      "type": "shell",
      "command": "flutter",
      "args": ["pub", "get"],
      "group": "build",
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      },
      "problemMatcher": []
    },
    {
      "label": "Flutter: Run Tests",
      "type": "shell",
      "command": "flutter",
      "args": ["test"],
      "group": "test",
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      },
      "problemMatcher": []
    },
    {
      "label": "Flutter: Analyze",
      "type": "shell",
      "command": "flutter",
      "args": ["analyze"],
      "group": "build",
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      },
      "problemMatcher": []
    },
    {
      "label": "Flutter: Format",
      "type": "shell",
      "command": "dart",
      "args": ["format", "."],
      "group": "build",
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      },
      "problemMatcher": []
    },
    {
      "label": "Serverpod: Generate",
      "type": "shell",
      "command": "serverpod",
      "args": ["generate"],
      "options": {
        "cwd": "${workspaceFolder}/serverpod"
      },
      "group": "build",
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      },
      "problemMatcher": []
    }
  ]
}
```

### Git Configuration

#### `.gitignore`
```gitignore
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/
migrate_working_dir/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# The .vscode folder contains launch configuration and tasks you configure in
# VS Code which you may wish to be included in version control, so this line
# is commented out by default.
#.vscode/

# Flutter/Dart/Pub related
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/

# Symbolication related
app.*.symbols

# Obfuscation related
app.*.map.json

# Android Studio will place build artifacts here
/android/app/debug
/android/app/profile
/android/app/release

# Serverpod
serverpod/.dart_tool/
serverpod/.packages
serverpod/pubspec.lock
serverpod/build/
serverpod/generated/
serverpod/config/generate.yaml

# Environment variables
.env
.env.local
.env.development
.env.production

# Database
*.db
*.sqlite
*.sqlite3

# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# nyc test coverage
.nyc_output

# Dependency directories
node_modules/
jspm_packages/

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env

# parcel-bundler cache (https://parceljs.org/)
.cache
.parcel-cache

# next.js build output
.next

# nuxt.js build output
.nuxt

# vuepress build output
.vuepress/dist

# Serverless directories
.serverless

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# TernJS port file
.tern-port

# Local Netlify folder
.netlify

# Backup files
*.bak
*.backup
*.old

# Temporary files
*.tmp
*.temp
```

#### Pre-commit Hook (`.git/hooks/pre-commit`)
```bash
#!/bin/bash

# Flutter pre-commit hook
# Run formatting, analysis, and tests before commit

echo "🔍 Running pre-commit checks..."

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Not a Flutter project. Skipping pre-commit checks."
    exit 0
fi

# Run dart format
echo "📝 Running dart format..."
if ! dart format --set-exit-if-changed .; then
    echo "❌ dart format failed. Please run 'dart format .' and commit again."
    exit 1
fi

# Run flutter analyze
echo "🔬 Running flutter analyze..."
if ! flutter analyze --fatal-infos --fatal-warnings; then
    echo "❌ flutter analyze failed. Please fix the issues and commit again."
    exit 1
fi

# Run tests
echo "🧪 Running tests..."
if ! flutter test --no-pub; then
    echo "❌ Tests failed. Please fix the failing tests and commit again."
    exit 1
fi

# Check for TODOs in new code
echo "🔍 Checking for TODOs in new code..."
if git diff --cached --name-only | xargs grep -l "TODO" 2>/dev/null; then
    echo "⚠️  Warning: TODOs found in staged files. Please consider addressing them."
fi

echo "✅ All pre-commit checks passed!"
exit 0
```

## Testing Configuration

### Test Configuration Files

#### `test/test_config.dart`
```dart
import 'package:flutter_test/flutter_test.dart';

/// Global test configuration
void configureTests() {
  // Configure test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up mock services
  setUpAll(() {
    // Initialize test dependencies
  });

  // Clean up after tests
  tearDownAll(() {
    // Clean up test dependencies
  });
}

/// Custom test utilities
class TestUtils {
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  static Widget wrapWithMaterialApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }
}
```

#### `test/mocks/mock_services.dart`
```dart
import 'package:mockito/mockito.dart';
import 'package:video_window/core/services/api_service.dart';
import 'package:video_window/core/services/auth_service.dart';

class MockApiService extends Mock implements ApiService {}

class MockAuthService extends Mock implements AuthService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockNotificationService extends Mock implements NotificationService {}

// Factory for creating mock services
class MockServiceFactory {
  static MockApiService createApiService() {
    return MockApiService();
  }

  static MockAuthService createAuthService() {
    return MockAuthService();
  }

  static MockDatabaseService createDatabaseService() {
    return MockDatabaseService();
  }

  static MockNotificationService createNotificationService() {
    return MockNotificationService();
  }
}
```

## Environment Configuration

### Development Environment

#### `.env.development`
```bash
# Flutter Configuration
FLUTTER_ENV=development
DEBUG_MODE=true
LOG_LEVEL=debug

# API Configuration
API_BASE_URL=http://localhost:8080
API_TIMEOUT=30000

# Database Configuration
DATABASE_URL=postgresql://dev_user:dev_password@localhost:5432/video_window_dev
DATABASE_POOL_SIZE=10

# Redis Configuration
REDIS_URL=redis://localhost:6379
REDIS_POOL_SIZE=5

# Authentication Configuration
JWT_SECRET=development-secret-key
JWT_EXPIRY=86400

# Third-party Services
STRIPE_PUBLIC_KEY=pk_test_development_key
FIREBASE_API_KEY=development_firebase_key
SENTRY_DSN=development_sentry_dsn

# Feature Flags
ENABLE_DEBUG_MENU=true
ENABLE_ANALYTICS=false
ENABLE_CRASH_REPORTING=true
```

#### `.env.staging`
```bash
# Flutter Configuration
FLUTTER_ENV=staging
DEBUG_MODE=true
LOG_LEVEL=info

# API Configuration
API_BASE_URL=https://api-staging.craft.marketplace
API_TIMEOUT=30000

# Database Configuration
DATABASE_URL=postgresql://staging_user:staging_password@staging-db.craft.marketplace:5432/video_window_staging
DATABASE_POOL_SIZE=20

# Redis Configuration
REDIS_URL=redis://staging-redis.craft.marketplace:6379
REDIS_POOL_SIZE=10

# Authentication Configuration
JWT_SECRET=staging-secret-key
JWT_EXPIRY=86400

# Third-party Services
STRIPE_PUBLIC_KEY=pk_test_staging_key
FIREBASE_API_KEY=staging_firebase_key
SENTRY_DSN=staging_sentry_dsn

# Feature Flags
ENABLE_DEBUG_MENU=true
ENABLE_ANALYTICS=true
ENABLE_CRASH_REPORTING=true
```

#### `.env.production`
```bash
# Flutter Configuration
FLUTTER_ENV=production
DEBUG_MODE=false
LOG_LEVEL=error

# API Configuration
API_BASE_URL=https://api.craft.marketplace
API_TIMEOUT=30000

# Database Configuration
DATABASE_URL=postgresql://prod_user:prod_password@prod-db.craft.marketplace:5432/video_window_prod
DATABASE_POOL_SIZE=50

# Redis Configuration
REDIS_URL=redis://prod-redis.craft.marketplace:6379
REDIS_POOL_SIZE=25

# Authentication Configuration
JWT_SECRET=production-secret-key
JWT_EXPIRY=86400

# Third-party Services
STRIPE_PUBLIC_KEY=pk_live_production_key
FIREBASE_API_KEY=production_firebase_key
SENTRY_DSN=production_sentry_dsn

# Feature Flags
ENABLE_DEBUG_MENU=false
ENABLE_ANALYTICS=true
ENABLE_CRASH_REPORTING=true
```

## Deployment Configuration

### Docker Configuration

#### `Dockerfile` (Flutter)
```dockerfile
# Flutter Web Dockerfile
FROM dart:3.5.6 as build

WORKDIR /app

# Copy pubspec and dependencies
COPY pubspec.yaml ./
COPY pubspec.lock ./

# Install dependencies
RUN dart pub get

# Copy source code
COPY . .

# Build web app
RUN dart pub global activate webdev
RUN dart pub global run webdev build --output=build/web

# Production stage
FROM nginx:alpine as production

# Copy built web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

#### `docker-compose.yml`
```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "80:80"
    environment:
      - FLUTTER_ENV=production
    depends_on:
      - api
      - redis
      - postgres

  api:
    build:
      context: ./serverpod
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/video_window
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=video_window
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - app

volumes:
  postgres_data:
  redis_data:
```

## Monitoring and Logging Configuration

### Monitoring Setup

#### Prometheus Configuration (`prometheus.yml`)
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'video-window-api'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 10s

  - job_name: 'postgres'
    static_configs:
      - targets: ['localhost:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['localhost:9121']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

#### Grafana Dashboard Configuration
```json
{
  "dashboard": {
    "id": null,
    "title": "Craft Video Marketplace Dashboard",
    "tags": ["flutter", "serverpod", "video-marketplace"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "API Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "50th percentile"
          }
        ]
      },
      {
        "id": 2,
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "Requests/sec"
          }
        ]
      },
      {
        "id": 3,
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m]) / rate(http_requests_total[5m])",
            "legendFormat": "Error Rate"
          }
        ]
      },
      {
        "id": 4,
        "title": "Database Connections",
        "type": "singlestat",
        "targets": [
          {
            "expr": "pg_stat_database_numbackends",
            "legendFormat": "Active Connections"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
```

---

These tool configuration templates provide a comprehensive foundation for all development and project management tools. They are designed to be immediately deployable and can be customized as needed for the specific requirements of the Craft Video Marketplace project.