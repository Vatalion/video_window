# Template Compliance Remediation Workflow

## Overview

This workflow systematically remediates documentation artifacts (stories, tech-specs, epic contexts) to ensure 100% compliance with approved BMAD templates. It provides automated analysis, intelligent content extraction from source documents, and incremental progress tracking with the ability to pause and resume.

## Problem Statement

Based on validation analysis, the project currently has:
- **35 of 75 stories (47%)** missing required sections
- **10 of 20 tech-specs (50%)** incomplete
- **0 of 20 epic contexts** non-compliant ✅

Common issues:
- Missing **Dev Notes** sections (35 stories) - blocks development
- Missing **Status** and **Story** sections (foundation epics)
- Incomplete **Tech Spec** sections (Data Models, API, Implementation)

## Solution Approach

The workflow uses a systematic, evidence-based approach:

1. **Validate**: Run comprehensive validation to identify all non-compliant files
2. **Prioritize**: Categorize by severity (Critical → High → Medium)
3. **Extract**: Pull content from authoritative sources (tech-specs, architecture docs)
4. **Remediate**: Add missing sections with proper citations
5. **Validate**: Confirm improvements and track metrics
6. **Document**: Create audit trail of all changes

### Key Features

- ✅ **Incremental Progress Tracking** - Pause and resume at checkpoints
- ✅ **Automated Content Extraction** - From tech-specs and architecture
- ✅ **Source Citation** - Every statement references original documents
- ✅ **Backup Creation** - Safe rollback for all changes
- ✅ **Interactive Mode** - Review each change before committing
- ✅ **Batch Mode** - Automated remediation for trusted cases
- ✅ **Dry-Run Mode** - Preview changes without file modifications

## Workflow Components

```
template-remediation/
├── workflow.yaml          # Configuration and data sources
├── instructions.md        # Step-by-step workflow logic
├── checklist.md          # Quality gates and acceptance criteria
├── README.md             # This file
└── validation.sh         # (Future) Enhanced validation script
```

## Usage

### Prerequisites

1. Validation script exists: `/tmp/validate_templates.sh`
2. Source documents available:
   - `docs/tech-spec-epic-*.md` (20 files)
   - `docs/epic-*-context.md` (20 files)
   - `docs/architecture/` directory
3. Stories directory: `docs/stories/` (75 files)

### Running the Workflow

**Interactive Mode (Recommended for first run):**
```bash
# From BMad Master agent or SM agent
*run-workflow template-remediation
```

**Batch Mode (For trusted remediation):**
```yaml
# Edit workflow.yaml:
mode: "batch"
```

**Dry-Run Mode (Preview only):**
```yaml
# Edit workflow.yaml:
mode: "dry-run"
```

### Execution Steps

The workflow executes in 7 steps:

1. **Initialize** - Setup environment, create backups, establish baseline
2. **Analyze** - Parse validation results, prioritize by severity
3. **Remediate Critical** - Fix missing Status/Story sections
4. **Remediate High** - Add Dev Notes to 35 stories
5. **Remediate Tech Specs** - Complete missing sections
6. **Final Validation** - Measure improvement, generate report
7. **Cleanup** - Archive progress, optionally commit changes

### Progress Tracking

All progress is logged to: `docs/remediation-progress.md`

Checkpoints allow resuming from:
- ✅ Step 1: Environment initialized
- ✅ Step 2: Analysis complete
- ✅ Step 3: Critical stories remediated
- ✅ Step 4: Dev Notes added
- ✅ Step 5: Tech specs completed
- ✅ Step 6: Final validation
- ✅ Step 7: Cleanup complete

## Content Extraction Strategy

### For Dev Notes Section

**Source Priority:**
1. **Tech Spec (epic-specific)** - Primary source for technical details
   - Data Models → Dev Notes: Data Models
   - API Endpoints → Dev Notes: API Specifications
   - Implementation Details → Dev Notes: Component Specifications

2. **Epic Context** - Secondary for patterns and stack
   - Technology Stack → Dev Notes: Technical references
   - Integration Points → Dev Notes: Component integration
   - Implementation Patterns → Dev Notes: Patterns to follow

3. **Architecture Docs** - Tertiary for constraints
   - Source tree → Dev Notes: File Locations
   - Testing Strategy → Dev Notes: Testing Requirements
   - Coding Standards → Dev Notes: Implementation guidance

4. **Previous Story** - For learnings and reuse
   - Completed Dev Agent Record → Learnings from Previous Story
   - New files created → Components to reuse (not recreate)
   - Technical debt → Items to address

### For Tech Spec Sections

**Missing Data Models:**
- Check PRD feature descriptions
- Reference architecture/data-models.md
- Extract from database schema docs

**Missing API Endpoints:**
- Check PRD functional requirements
- Reference architecture/rest-api-spec.md
- Extract from related epic contexts

**Missing Implementation Details:**
- Check architecture component mapping
- Reference technology stack docs
- Extract from epic context patterns

## Quality Gates

### Pre-Execution
- Validation script exists
- Source documents accessible
- Backup structure created

### Per-Story Quality
- Content extracted from actual sources (not invented)
- All citations properly formatted: `[Source: path#section]`
- Sections in correct template order
- Markdown properly formatted

### Post-Execution
- ≥90% of non-compliant stories remediated
- ≥80% of non-compliant tech-specs remediated
- Zero validation errors in remediated files
- Complete audit trail in progress tracker

See `checklist.md` for complete quality criteria.

## Output Artifacts

### Primary Outputs
1. **Remediated Files** - Updated stories and tech-specs
2. **Progress Tracker** - `docs/remediation-progress.md`
3. **Backups** - `docs/backups/remediation-YYYY-MM-DD/`

### Metrics Reported
- Baseline vs. final non-compliant counts
- Improvement percentages
- Files remediated by priority tier
- Errors encountered
- Manual review list (if any)

## Error Handling

If remediation fails for a file:
1. Error logged in progress tracker
2. File skipped, workflow continues
3. Added to manual review list
4. Reported in final summary

## Manual Review Cases

Workflow flags for manual review when:
- Story cannot be mapped to tech-spec or epic
- Dev Notes sources are missing or incomplete
- Multiple template violations in single file
- Content contradicts architecture or PRD
- Automated remediation produces unclear content

## Rollback Procedure

If remediation produces unexpected results:

1. **Individual File Rollback:**
   ```bash
   cp docs/backups/remediation-YYYY-MM-DD/story-X-Y.md docs/stories/
   ```

2. **Full Rollback:**
   ```bash
   cp -r docs/backups/remediation-YYYY-MM-DD/* docs/
   ```

3. **Git Rollback (if committed):**
   ```bash
   git revert <commit-hash>
   ```

## Success Criteria

Workflow is considered successful when:
- [ ] ≥90% of stories are template-compliant
- [ ] ≥80% of tech-specs are template-compliant
- [ ] All critical priority issues resolved
- [ ] All high priority issues (Dev Notes) resolved
- [ ] Progress tracker shows complete audit trail
- [ ] Validation script confirms improvement

## Next Steps After Completion

1. Review progress tracker: `docs/remediation-progress.md`
2. Address manual review items (if any)
3. Run `melos run analyze` to verify no code issues
4. Commit changes:
   ```bash
   git add docs/stories docs/tech-spec-*.md docs/remediation-progress.md
   git commit -m "docs: template compliance remediation

   - Remediated 35 story files with missing Dev Notes
   - Completed 10 tech-spec files with missing sections
   - All changes extracted from authoritative sources
   - Progress tracked in remediation-progress.md"
   ```
5. Resume development workflows with compliant stories

## Workflow Maintenance

### Updating the Workflow

If templates change in the future:
1. Update `workflow.yaml` with new required sections
2. Update validation script criteria
3. Update `instructions.md` extraction logic
4. Update `checklist.md` quality gates

### Adding New Artifact Types

To extend to new document types:
1. Add validation logic to validation script
2. Add extraction logic to instructions.md
3. Add quality gates to checklist.md
4. Update workflow.yaml with new targets

## Support

For issues or questions:
- Check `docs/remediation-progress.md` for current status
- Review `checklist.md` for quality requirements
- Consult BMad Master agent for workflow guidance
- Review original validation output for baseline

---

**Version:** 1.0.0
**Author:** BMad Team
**Last Updated:** 2025-11-08
