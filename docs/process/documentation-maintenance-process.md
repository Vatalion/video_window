# Documentation Maintenance Process

**Created:** 2025-10-30  
**Purpose:** Establish automated checks and maintenance procedures for documentation quality  
**Owner:** Documentation Team

## Overview

This process ensures documentation remains accurate, consistent, and complete throughout the development lifecycle. It combines automated validation with manual review procedures to prevent documentation debt.

## Automated Validation

### 1. Documentation Validation Script

**Location:** `scripts/validate-docs.sh`  
**Purpose:** Comprehensive validation of documentation structure and consistency

**Checks Performed:**
- ✅ Epic numbering consistency (non-padded format: `tech-spec-epic-1.md` not `tech-spec-epic-01.md`)
- ✅ Cross-reference validation (all links point to existing files)
- ✅ Dead link detection (broken internal markdown links)
- ✅ Orphaned file detection (unreferenced documentation files)
- ✅ Story structure validation (required sections: Status, Story, ACs, Tasks, Dev Notes)
- ✅ Process document validation (required files exist with correct BMAD references)
- ✅ Epic validation status consistency

**Usage:**
```bash
# Run locally before committing
./scripts/validate-docs.sh

# Run with verbose output
bash -x ./scripts/validate-docs.sh
```

### 2. GitHub Actions Integration

**Workflow:** `.github/workflows/docs-validation.yml`  
**Triggers:**
- Push to `develop`, `main`, or `release/*` branches (docs changes only)
- Pull requests affecting documentation
- Daily scheduled run at 1 AM UTC

**Validation Steps:**
1. Custom documentation validation script
2. Markdownlint for formatting consistency
3. Markdown link checker for external links
4. Epic structure validation
5. Story-epic alignment verification
6. Documentation coverage analysis

**Outputs:**
- ✅ Pass/Fail status for pull requests
- 📊 Documentation coverage reports
- 🚨 Automated issue creation for documentation debt

### 3. Quality Gates

**Pre-commit Requirements:**
- All documentation validation checks must pass
- No broken internal links
- All required sections present in stories
- Consistent epic numbering format

**Pull Request Requirements:**
- Documentation validation workflow must pass
- New epics must include corresponding stories
- Process changes must update related documentation

## Manual Maintenance Procedures

### 1. Epic Development Workflow

**When creating new epics:**
1. Create tech spec: `docs/tech-spec-epic-X.md`
2. Add entry to `docs/tech-spec.md` index
3. Update `docs/process/epic-validation-backlog.md`
4. Create related story files in `docs/stories/`
5. Run `./scripts/validate-docs.sh` to verify consistency

**When removing epics:**
1. Archive tech spec to `docs/archive/`
2. Update index files to remove references
3. Archive related stories
4. Update validation backlog status

### 2. Story Management

**Story File Requirements:**
- **Naming:** `{epic}-{story}-{title}.md` (e.g., `1-1-user-registration.md`)
- **Required Sections:**
  - `## Status` - Current development status
  - `## Story` - User story description
  - `## Acceptance Criteria` - Testable acceptance criteria
  - `## Tasks` - Implementation tasks and subtasks
  - `## Dev Notes` - Technical implementation notes

**Status Values:**
- `Ready for Dev` - Story ready for development
- `In Development` - Currently being implemented
- `Ready for Review` - Implementation complete, pending review
- `Completed` - Story fully implemented and verified

### 3. Cross-Reference Management

**When renaming files:**
1. Update all references in markdown files
2. Update index documents
3. Run validation script to catch missed references
4. Commit all changes together to maintain consistency

**When creating new sections:**
1. Add to relevant index documents
2. Ensure proper cross-linking
3. Update navigation structures
4. Test all links before committing

## Prevention Strategies

### 1. File Naming Conventions

**Epic Files:** `tech-spec-epic-{number}.md` (non-padded)
- ✅ `tech-spec-epic-1.md`
- ❌ `tech-spec-epic-01.md`

**Story Files:** `{epic}-{story}-{title}.md`
- ✅ `1-1-user-registration.md`
- ✅ `10-3-auction-timer-management.md`

**Process Files:** Descriptive kebab-case
- ✅ `definition-of-ready.md`
- ✅ `story-approval-workflow.md`

### 2. Template Usage

**Story Template:** Use BMAD workflow template
```markdown
# Story {Epic}.{Number}: {Title}

## Status
**Status:** Ready for Dev

## Story
As a {user type}, I want {goal} so that {benefit}.

## Acceptance Criteria
- [ ] AC1: {criteria}
- [ ] AC2: {criteria}

## Tasks
- [ ] Task 1: {description}
  - [ ] Subtask 1.1: {description}

## Dev Notes
{Technical implementation notes}
```

### 3. Review Checklist

**For all documentation changes:**
- [ ] File naming follows conventions
- [ ] All required sections present
- [ ] Cross-references are accurate
- [ ] Links point to existing files
- [ ] Status values are valid
- [ ] Validation script passes locally

**For epic changes:**
- [ ] Index files updated
- [ ] Validation backlog updated
- [ ] Related stories created/updated
- [ ] Process implications considered

## Troubleshooting

### Common Issues

**"Dead link" errors:**
- Check file paths are relative to project root
- Ensure referenced files exist
- Verify no typos in filenames

**"Orphaned file" warnings:**
- Add references to orphaned files in index documents
- Archive files that are no longer needed
- Create explicit entry points for standalone files

**"Epic numbering" errors:**
- Rename files to non-padded format
- Update all references in index files
- Run validation script to verify consistency

**"Missing required sections" in stories:**
- Add all required sections: Status, Story, ACs, Tasks, Dev Notes
- Use proper markdown heading format (## Section)
- Ensure sections contain actual content

### Emergency Procedures

**If validation fails in CI:**
1. Check workflow logs for specific errors
2. Run `./scripts/validate-docs.sh` locally to reproduce
3. Fix identified issues
4. Re-run validation locally to verify
5. Commit fixes with descriptive message

**If documentation becomes inconsistent:**
1. Run full validation: `./scripts/validate-docs.sh`
2. Review all ERROR messages first
3. Address WARNING messages for quality
4. Update index files to reflect current state
5. Verify all cross-references are valid

## Metrics and Monitoring

### Key Metrics

**Coverage Metrics:**
- Tech spec completion: X/13 epics (target: 100%)
- Story completion: X stories per epic (varies by epic)
- Process documentation: 4/4 required files (target: 100%)

**Quality Metrics:**
- Validation errors: 0 (target: 0)
- Validation warnings: <5 (target: 0)
- Dead links: 0 (target: 0)
- Orphaned files: <3 (target: 0)

**Maintenance Metrics:**
- Documentation debt issues: tracked in GitHub
- Time to fix validation failures: <24 hours
- Review cycle time: <2 days for documentation PRs

### Dashboard

The documentation validation workflow generates reports available in:
- GitHub Actions artifacts (documentation-report.md)
- Automated issue tracking for debt
- Daily validation status emails (if configured)

## Related Documentation

- **Validation Script:** `scripts/validate-docs.sh`
- **GitHub Workflow:** `.github/workflows/docs-validation.yml`
- **BMAD Templates:** `bmad/bmm/workflows/create-story.mdc`
- **Epic Validation:** `docs/process/epic-validation-backlog.md`
- **Story Approval:** `docs/process/story-approval-workflow.md`

---
**Last Updated:** 2025-10-30  
**Next Review:** Monthly or upon major process changes  
**Owner:** Documentation Team  
**Stakeholders:** Development Team, Product Team, QA Team