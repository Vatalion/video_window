# Develop-Review Workflow

**One-shot automated ping-pong development and review workflow**

## Overview

The `develop-review` workflow orchestrates an automated cycle of development and code review that continues until a story is approved or a safety limit is reached. This eliminates the need for manual handoffs between development and review phases.

## What It Does

1. **Discovers or loads a story** ready for development
2. **Executes development** using the `dev-story` workflow
3. **Performs code review** using the `code-review` workflow
4. **Makes a decision**:
   - ✅ **Approved** → Story marked done, loop exits
   - ⚠️ **Changes Requested** → Loop back to development with review context
   - 🚫 **Blocked** → Halt for manual intervention
5. **Repeats** until approved or max iterations reached

## Key Features

- **Continuous Execution**: Runs multiple dev-review cycles in a single session
- **Review Context Preservation**: dev-story automatically detects and prioritizes review follow-ups
- **Safety Limits**: Max iterations prevent infinite loops
- **Automatic Discovery**: Finds next ready story if path not specified
- **Comprehensive Tracking**: Iteration counts, outcomes, and progress clearly displayed
- **Auto-Commit on Success**: Automatically commits changes when story approved 🆕
- **Optional Push**: Can also push to remote repository automatically 🆕

## How to Use

### Basic Usage (Auto-discover next story)

```bash
develop-review
```

### Specify a particular story

```bash
develop-review story_path="/path/to/story/1-1-example.md"
```

### Customize parameters

```bash
# With auto-commit and push
develop-review max_iterations=10 auto_approve=true auto_commit=true commit_and_push=true

# Disable auto-commit
develop-review auto_commit=false
```

## Configuration

### Required Variables (from config)
- `story_dir`: Location of story files
- `output_folder`: Location of sprint-status.yaml
- `user_name`, `communication_language`, `user_skill_level`: Standard config

### Optional Variables
- `story_path`: Explicit story file path (default: auto-discover)
- `max_iterations`: Maximum review cycles before halting (default: 5)
- `auto_approve`: Automatically mark done when approved (default: false)
- `auto_commit`: Automatically commit changes when approved (default: true) 🆕
- `commit_and_push`: Also push to remote after commit (default: **true**) 🆕

## Workflow Logic

```
┌─────────────────────────────┐
│   Initialize Loop           │
│   (Validate Prerequisites)  │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│   Development Phase         │◄─────┐
│   (Execute dev-story)       │      │
└──────────┬──────────────────┘      │
           │                          │
           ▼                          │
┌─────────────────────────────┐      │
│   Review Phase              │      │
│   (Execute code-review)     │      │
└──────────┬──────────────────┘      │
           │                          │
           ▼                          │
┌─────────────────────────────┐      │
│   Decision Gate             │      │
│   - Approved? → EXIT ✅     │      │
│   - Blocked? → HALT 🚫      │      │
│   - Changes? → LOOP ⚠️      │──────┘
│   - Max iters? → HALT ⏹     │
└─────────────────────────────┘
```

## Exit Conditions

### ✅ Success (Approved)
- Review outcome: "Approve"
- Story status: "done"
- All acceptance criteria met
- All tasks completed
- No action items remaining
- **Changes committed to Git** (if auto_commit=true) 🆕
- **Changes pushed to remote** (if commit_and_push=true) 🆕

### ⚠️ Max Iterations Reached
- Iteration count >= max_iterations
- Changes still requested
- Action items remain
- User must review manually or increase limit

### 🚫 Blocked
- Critical blockers prevent approval
- Manual intervention required
- Review notes contain blocker details

### ❌ Development Failure
- dev-story workflow encounters errors
- Tests fail repeatedly
- Implementation cannot proceed

## Example Execution

### Scenario 1: First-time approval (1 iteration)

```bash
$ develop-review

🔄 Dev-Review Loop Starting
Max iterations: 5 | Auto-approve: false | Story: Auto-discover

🔄 Iteration 1 of 5
Phase: Development 🛠️
---
[dev-story executes...]
✅ Development Phase Complete
Story: 1-2-user-auth | Tasks: 8 | Status: Ready for review
---

🔄 Iteration 1 of 5
Phase: Code Review 🔍
---
[code-review executes...]
📋 Review Phase Complete
Outcome: Approve | Action Items: 0
---

✅ STORY APPROVED! 🎉
Story: 1-2-user-auth | Iterations: 1 | Final Status: done
```

### Scenario 2: Changes requested (2 iterations)

```bash
$ develop-review

🔄 Iteration 1 of 5
[... development ...]
[... review finds 3 issues ...]
📋 Review Phase Complete
Outcome: Changes Requested | Action Items: 3 | Severity: 2 Med, 1 Low

🔄 Changes Requested - Continuing Loop
---

🔄 Iteration 2 of 5
Phase: Development 🛠️
⏯️ Resuming Story After Code Review
Action Items: 3 remaining | Priorities: 2 Med, 1 Low
[... addresses review items ...]
✅ Development Phase Complete

Phase: Code Review 🔍
[... all items resolved ...]
✅ STORY APPROVED! 🎉
Iterations Required: 2
```

## Integration with Other Workflows

### Prerequisites
- `sprint-planning`: Generates sprint-status.yaml
- `create-story`: Creates story files
- `story-context`: Generates context files (optional but recommended)

### Orchestrated Workflows
- `dev-story`: Development execution
- `code-review`: Systematic review

### Follow-up Workflows
- `story-done`: Manual completion if auto_approve=false
- `retrospective`: Epic completion review

## Best Practices

1. **Run story-context first** for better implementation guidance
2. **Start with default max_iterations (5)** - increase if stories are complex
3. **Use auto_approve=false** for visibility into approval decisions
4. **Review accumulated feedback** if max iterations reached
5. **Clear context between runs** for optimal performance

## Troubleshooting

### Loop doesn't start
- Check sprint-status.yaml exists
- Verify stories with status "ready-for-dev" exist
- Ensure story path is valid if specified

### Loop stops after development
- Check test execution is configured
- Verify all tests pass
- Review dev-story output for errors

### Loop doesn't continue after review
- Verify review outcome is "Changes Requested"
- Check iteration count vs max_iterations
- Review decision gate logic in output

### Max iterations reached
- Increase max_iterations value
- Review accumulated feedback manually
- Consider breaking story into smaller pieces

## Related Documentation

- `dev-story` workflow: Development execution details
- `code-review` workflow: Review criteria and process
- Phase 4 Implementation README: Overall sprint workflow
- Story Approval Workflow: Process governance

---

**Module:** BMM (BMad Method Module)
**Phase:** 4 - Implementation
**Type:** Orchestration Workflow
**Author:** BMad
**Status:** Active
