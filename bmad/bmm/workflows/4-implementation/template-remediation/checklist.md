# Template Remediation - Quality Checklist

## Pre-Execution Validation
- [ ] Validation script exists and is executable
- [ ] Backup directory structure created
- [ ] All source documents accessible (tech-specs, epic-contexts, architecture)
- [ ] Progress tracker initialized
- [ ] Baseline metrics captured

## Story Remediation Quality Gates

### Critical Sections (Status, Story, AC)
- [ ] Status value is appropriate for story state
- [ ] Story follows "As a/I want/so that" format
- [ ] Story aligns with epic goals and tech-spec
- [ ] Acceptance Criteria are measurable and testable
- [ ] Acceptance Criteria reference sources correctly

### Dev Notes Section Quality
- [ ] All subsections present (Data Models, API Specs, Components, File Locations, Testing)
- [ ] Content extracted from actual tech-spec (not invented)
- [ ] All sources properly cited with [Source: ...] format
- [ ] Previous story learnings included (if applicable)
- [ ] File locations match actual project structure
- [ ] Testing requirements align with architecture strategy

### Formatting and Structure
- [ ] Markdown headers use correct hierarchy (##, ###)
- [ ] Lists properly formatted (-, [ ])
- [ ] Code blocks use correct syntax highlighting
- [ ] No trailing whitespace or broken links
- [ ] Sections in correct order per template

## Tech Spec Remediation Quality Gates

### Required Sections
- [ ] Architecture Overview present and complete
- [ ] Data Models section with entities and relationships
- [ ] API Endpoints section with methods and paths
- [ ] Implementation Details section with guidance

### Content Quality
- [ ] Data models align with database schema
- [ ] API endpoints match backend implementation
- [ ] Implementation details reference actual components
- [ ] All sections cite source materials

## Epic Context Validation
- [ ] All epic contexts already compliant (100% baseline)
- [ ] No remediation needed for epic contexts

## Post-Remediation Validation

### File-Level Checks
- [ ] All remediated files pass validation script
- [ ] Backups created for all modified files
- [ ] No files corrupted or malformed
- [ ] Git diff shows only intended changes

### Metrics Validation
- [ ] Final non-compliant count reduced
- [ ] Improvement percentage calculated correctly
- [ ] Progress tracker shows all completed items
- [ ] Error log captures any failures

### Documentation
- [ ] Progress tracker complete with all sessions
- [ ] Final validation report generated
- [ ] Manual review list populated (if applicable)
- [ ] Next steps clearly documented

## Acceptance Criteria

### Story Remediation Success
- [ ] ≥90% of non-compliant stories remediated
- [ ] All critical priority stories (missing Status/Story) fixed
- [ ] All high priority stories (missing Dev Notes) fixed
- [ ] Remaining issues documented for manual review

### Tech Spec Remediation Success
- [ ] ≥80% of non-compliant tech-specs remediated
- [ ] Foundation epics (01-03) fully compliant
- [ ] All missing sections have content from valid sources
- [ ] No placeholder or TODO content in required sections

### Overall Quality
- [ ] Zero validation errors in remediated files
- [ ] All citations reference existing documents
- [ ] Consistent formatting across all files
- [ ] Progress tracker provides audit trail

## Manual Review Triggers

Flag for manual review if:
- [ ] Story cannot be mapped to tech-spec or epic
- [ ] Dev Notes sources are missing or incomplete
- [ ] Multiple template violations in single file
- [ ] Content contradicts architecture or PRD
- [ ] Automated remediation produces unclear content

## Final Sign-Off

- [ ] All quality gates passed
- [ ] Validation script shows improvement
- [ ] Progress tracker archived
- [ ] Changes ready for commit
- [ ] Team notified of completion

**Reviewer:** _______________
**Date:** _______________
**Status:** [ ] Approved [ ] Changes Requested [ ] Blocked
