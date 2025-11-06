# Develop-Review - Validation Checklist

## Pre-Execution Validation

### Story Readiness
- [ ] At least one story exists with status `ready-for-dev` OR `in-progress`
- [ ] Sprint status file exists at `{output_folder}/sprint-status.yaml`
- [ ] Story files are accessible in `{story_dir}`
- [ ] Story context files (.context.xml) exist if required

### Configuration Validation
- [ ] `max_iterations` is set (default: 5)
- [ ] `story_path` is valid if provided (or empty for auto-discovery)
- [ ] `auto_approve` flag is configured (default: false)
- [ ] Dev story workflow exists at `{dev_story_workflow}`
- [ ] Code review workflow exists at `{code_review_workflow}`

### Environment Readiness
- [ ] Test execution command is configured or detectable
- [ ] All necessary tools/dependencies are installed
- [ ] Git working directory is clean (or changes are intentional)

---

## During Execution Validation

### Loop Iteration Tracking
- [ ] Iteration counter increments correctly
- [ ] Current iteration is clearly displayed
- [ ] Max iterations limit is enforced

### Development Phase (Step 2)
- [ ] Dev-story workflow loads successfully
- [ ] Story is discovered or loaded from provided path
- [ ] Review continuation is detected if applicable
- [ ] All incomplete tasks are processed
- [ ] Tests are written and executed
- [ ] Story file is updated with completion status
- [ ] Story status changes to "review"

### Review Phase (Step 3)
- [ ] Code-review workflow loads successfully
- [ ] Story is loaded with "review" status
- [ ] Context and tech spec are resolved
- [ ] Systematic validation is performed (ACs, tasks, quality)
- [ ] Review outcome is determined (Approve/Changes/Blocked)
- [ ] Review notes are appended to story
- [ ] Sprint status is updated based on outcome

### Decision Gate (Step 4)
- [ ] Review outcome is captured correctly
- [ ] Loop continues if changes requested
- [ ] Loop halts if approved or blocked
- [ ] Max iterations check prevents infinite loops
- [ ] Auto-approve works if enabled

---

## Post-Execution Validation

### Success Criteria (Approved)
- [ ] Story status is "done"
- [ ] All acceptance criteria are met
- [ ] All tasks are marked complete
- [ ] Review notes show "Approve" outcome
- [ ] No unresolved action items remain
- [ ] Tests pass successfully
- [ ] Sprint status file is updated

### Changes Requested Criteria
- [ ] Iteration count is within max_iterations
- [ ] Review action items are added to story
- [ ] Review Follow-ups section exists in Tasks
- [ ] Story status is "in-progress"
- [ ] Loop continues to next iteration

### Blocked Criteria
- [ ] Critical blockers are documented in review notes
- [ ] Story status remains "review" or set appropriately
- [ ] User is notified of manual intervention required
- [ ] Loop halts gracefully

### Safety Limits
- [ ] Max iterations limit prevents runaway loops
- [ ] User intervention options are provided
- [ ] Failure modes are handled gracefully
- [ ] All file changes are tracked in story Change Log

---

## Quality Checks

### Code Quality
- [ ] All code follows project standards
- [ ] No regressions introduced
- [ ] Error handling is appropriate
- [ ] Performance is acceptable

### Test Quality
- [ ] Tests cover acceptance criteria
- [ ] Tests pass consistently
- [ ] Edge cases are tested
- [ ] No flaky tests introduced

### Documentation Quality
- [ ] Story file is complete and accurate
- [ ] Review notes are clear and actionable
- [ ] Change log is updated
- [ ] File list reflects all changes

---

## Troubleshooting Checklist

### If Loop Doesn't Start
- [ ] Check story availability (ready-for-dev or in-progress)
- [ ] Verify sprint-status.yaml exists and is readable
- [ ] Confirm story path is valid if provided
- [ ] Check workflow file paths are correct

### If Development Fails
- [ ] Review dev-story output for errors
- [ ] Check test execution logs
- [ ] Verify code compiles/runs
- [ ] Check for missing dependencies

### If Review Fails
- [ ] Review code-review output for errors
- [ ] Verify tech spec and context files exist
- [ ] Check story file format is correct
- [ ] Ensure all required sections are present

### If Loop Doesn't Continue
- [ ] Verify review outcome is "Changes Requested"
- [ ] Check iteration count vs max_iterations
- [ ] Review decision gate logic
- [ ] Check for unhandled errors

---

## Final Validation

- [ ] Story is complete and approved (or blocked with clear reason)
- [ ] All intermediate files are cleaned up if needed
- [ ] Sprint status accurately reflects final state
- [ ] User receives clear summary of results
- [ ] Next recommended action is provided
