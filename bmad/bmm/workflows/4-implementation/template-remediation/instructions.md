# Template Compliance Remediation - Instructions

<critical>The workflow execution engine is governed by: {project_root}/bmad/core/tasks/workflow.xml</critical>
<critical>This workflow systematically remediates non-compliant stories, tech-specs, and epic contexts to match approved templates</critical>
<critical>Progress is tracked incrementally - workflow can be paused and resumed at any checkpoint</critical>

<workflow>

<step n="1" goal="Initialize and validate environment">
  <action>Load workflow.yaml configuration and resolve all variables</action>
  <action>Verify validation script exists at {{validation_script}}</action>
  <action>Create backup directory: {{output_folder}}/backups/remediation-{{date}}</action>
  <action>Run initial validation to establish baseline metrics</action>
  
  <template-output file="{progress_tracker}">
# Template Remediation Progress Tracker

**Started:** {{date}}
**Mode:** {{mode}}
**Baseline Metrics:**
- Stories: {{total_stories}} total, {{non_compliant_stories}} non-compliant ({{compliance_pct}}%)
- Tech Specs: {{total_tech_specs}} total, {{non_compliant_tech_specs}} non-compliant
- Epic Contexts: {{total_epic_contexts}} total, {{non_compliant_epic_contexts}} non-compliant

## Remediation Sessions

### Session 1 - {{date}}
**Status:** In Progress
**Target:** Story files remediation
  </template-output>
  
  <action>Display summary and ask user to confirm start</action>
</step>

<step n="2" goal="Analyze non-compliant files and prioritize">
  <action>Run validation script and capture detailed output</action>
  <action>Parse validation results to extract:
    - List of non-compliant story files with missing sections
    - List of non-compliant tech-spec files with missing sections
    - Epic context files (if any non-compliant)
  </action>
  
  <action>Categorize issues by severity:
    - **Critical**: Missing Status, Story, or Acceptance Criteria
    - **High**: Missing Dev Notes (blocks development)
    - **Medium**: Missing optional sections
  </action>
  
  <action>Group files by epic for logical remediation batches:
    - Foundation epics (01-03): 9 stories
    - Feature epics (1-13): Varying
    - Support epics (14-17): 22 stories
  </action>
  
  <template-output file="{progress_tracker}">
## Analysis Results

### Stories by Priority
**Critical (Missing Status/Story):** {{critical_count}} files
{{critical_files_list}}

**High (Missing Dev Notes):** {{high_count}} files
{{high_files_list}}

### Tech Specs by Epic
{{tech_spec_analysis}}

### Recommended Remediation Order
1. Critical priority stories (foundation epics)
2. High priority stories (missing Dev Notes)
3. Tech spec completions
4. Final validation
  </template-output>
</step>

<step n="3" goal="Remediate Critical Priority Stories" repeat="for-each-critical-story">
  <action>For each critical priority story file:</action>
  <action>Load complete story file: {{story_file_path}}</action>
  <action>Identify missing sections from validation output</action>
  
  <substep n="3a" goal="Backup original file">
    <action>Copy file to backup location with timestamp</action>
    <action>Log backup path in progress tracker</action>
  </substep>
  
  <substep n="3b" goal="Add missing Status section" if="status-missing">
    <action>Determine appropriate status based on file analysis:
      - If has Dev Agent Record with completions → "review" or "done"
      - If has Tasks but no Dev Agent Record → "ready" or "in-progress"
      - If minimal content → "backlog" or "draft"
    </action>
    <action>Insert Status section at top of file after title</action>
  </substep>
  
  <substep n="3c" goal="Add missing Story section" if="story-missing">
    <action>Extract story intent from:
      1. File title and epic context
      2. Acceptance Criteria (derive user value)
      3. Related tech-spec epic section
    </action>
    <action>Generate story statement in format:
      **As a** [role],
      **I want** [capability],
      **so that** [benefit]
    </action>
    <action>Insert Story section after Status</action>
  </substep>
  
  <substep n="3d" goal="Add missing Dev Notes section" if="devnotes-missing">
    <action>Analyze story content to populate Dev Notes:</action>
    
    <action>Extract from Tech Spec (epic-specific):
      - Data Models section → Dev Notes: Data Models
      - API Endpoints → Dev Notes: API Specifications
      - Implementation Details → Dev Notes: Component Specifications
      - File structure → Dev Notes: File Locations
      - Testing requirements → Dev Notes: Testing Requirements
    </action>
    
    <action>Extract from Architecture docs:
      - Component mapping → Dev Notes: Component Specifications
      - Technology stack → Dev Notes: Technical stack references
      - Patterns and conventions → Dev Notes: Implementation patterns
    </action>
    
    <action>Check for previous story in same epic:
      - If exists and completed → Add "Learnings from Previous Story"
      - Extract new files, patterns, warnings from previous story
    </action>
    
    <action>Generate Dev Notes section with subsections:
      ### Previous Story Insights (if applicable)
      ### Data Models
      ### API Specifications
      ### Component Specifications
      ### File Locations
      ### Testing Requirements
    </action>
    
    <action>Insert Dev Notes section before Dev Agent Record (or at end)</action>
  </substep>
  
  <substep n="3e" goal="Validate and save">
    <action>Run section validation on updated file</action>
    <action>Save updated file</action>
    <action>Update progress tracker with completion</action>
    
    <check if="mode == interactive">
      <action>Show diff of changes made</action>
      <ask>Review changes - Continue [c], Edit [e], or Skip [s]?</ask>
    </check>
  </substep>
  
  <template-output file="{progress_tracker}">
#### Story: {{story_filename}}
- **Status:** ✅ Remediated
- **Sections Added:** {{sections_added}}
- **Backup:** {{backup_path}}
- **Timestamp:** {{timestamp}}
  </template-output>
</step>

<step n="4" goal="Remediate High Priority Stories (Dev Notes)" repeat="for-each-high-priority">
  <action>For each story missing only Dev Notes section:</action>
  <action>Follow same process as Step 3d (Add missing Dev Notes)</action>
  <action>This is the most common remediation - 35 stories need Dev Notes</action>
  
  <critical>Dev Notes MUST reference actual tech-spec and architecture content - DO NOT invent</critical>
  
  <action>For each story, execute systematic Dev Notes generation:</action>
  
  <substep n="4a" goal="Load source documentation">
    <action>Identify epic number from story filename (e.g., "4-2-..." → epic 4)</action>
    <action>Load tech-spec-epic-{{epic_num}}.md COMPLETELY</action>
    <action>Load epic-{{epic_num}}-context.md COMPLETELY</action>
    <action>Load relevant architecture docs from architecture/ directory</action>
  </substep>
  
  <substep n="4b" goal="Extract relevant technical details">
    <action>From tech-spec, extract sections matching story's acceptance criteria:
      - Specific data models referenced in ACs
      - API endpoints needed for implementation
      - Component specifications
      - File paths and locations
      - Testing requirements
    </action>
    
    <action>From epic-context, extract:
      - Technology stack components
      - Integration points
      - Implementation patterns
    </action>
    
    <action>From architecture docs, extract:
      - Architectural constraints
      - Design patterns to follow
      - Testing strategy
    </action>
  </substep>
  
  <substep n="4c" goal="Generate comprehensive Dev Notes">
    <action>Create Dev Notes section with proper citations:</action>
    
    <format>
## Dev Notes

### Previous Story Insights
[If previous story in epic exists and is completed]
- Reference previous story learnings
- Note reusable components
[Source: stories/{{previous_story_key}}.md]

### Data Models
[Extract from tech-spec Data Models section]
- List relevant entities and their fields
- Note relationships and constraints
[Source: tech-spec-epic-{{epic_num}}.md#data-models]

### API Specifications
[Extract from tech-spec API Endpoints section]
- List endpoints used: method, path, purpose
- Note request/response formats
[Source: tech-spec-epic-{{epic_num}}.md#api-endpoints]

### Component Specifications
[Extract from tech-spec Implementation Details]
- Module/package locations
- Component architecture
- Integration patterns
[Source: tech-spec-epic-{{epic_num}}.md#implementation-details]

### File Locations
- UI/State code: [path from architecture]
- Backend code: [path from tech-spec]
- Tests: [path from architecture]
[Source: architecture/architecture.md#source-tree]

### Testing Requirements
- Coverage target: [from testing strategy]
- Test types: [unit/integration/widget]
- Test patterns: [from architecture]
[Source: architecture/architecture.md#testing-strategy]
    </format>
  </substep>
  
  <substep n="4d" goal="Insert and validate">
    <action>Insert Dev Notes section before Dev Agent Record (or at end if no Dev Agent Record)</action>
    <action>Validate section is properly formatted</action>
    <action>Save file and update progress tracker</action>
    
    <check if="mode == interactive">
      <action>Show generated Dev Notes</action>
      <ask>Review Dev Notes - Continue [c], Edit [e], or Skip [s]?</ask>
    </check>
  </substep>
  
  <template-output file="{progress_tracker}">
#### Story: {{story_filename}}
- **Status:** ✅ Dev Notes Added
- **Sources Referenced:** {{sources_list}}
- **Backup:** {{backup_path}}
- **Timestamp:** {{timestamp}}
  </template-output>
</step>

<step n="5" goal="Remediate Tech Spec Files" repeat="for-each-non-compliant-techspec">
  <action>For each non-compliant tech-spec file:</action>
  <action>Load complete tech-spec file</action>
  <action>Identify missing sections from validation</action>
  
  <substep n="5a" goal="Add missing sections from source material">
    <action>Check if corresponding PRD or epic-context exists</action>
    <action>Extract missing content from source documents:</action>
    
    <check if="missing-data-models">
      <action>Look for entity definitions in:
        - PRD feature descriptions
        - Architecture data-models.md
        - Database schema docs
      </action>
      <action>Generate Data Models section with entities, fields, relationships</action>
    </check>
    
    <check if="missing-api">
      <action>Look for API specifications in:
        - PRD functional requirements
        - Architecture rest-api-spec.md
        - Related epic contexts
      </action>
      <action>Generate API Endpoints section with method, path, purpose</action>
    </check>
    
    <check if="missing-implementation">
      <action>Look for implementation guidance in:
        - Architecture component mapping
        - Technology stack docs
        - Epic context implementation patterns
      </action>
      <action>Generate Implementation Details section</action>
    </check>
  </substep>
  
  <substep n="5b" goal="Validate and save">
    <action>Backup original file</action>
    <action>Insert missing sections in proper order</action>
    <action>Run validation on updated file</action>
    <action>Save and update progress tracker</action>
  </substep>
  
  <template-output file="{progress_tracker}">
#### Tech Spec: {{techspec_filename}}
- **Status:** ✅ Sections Completed
- **Sections Added:** {{sections_added}}
- **Backup:** {{backup_path}}
- **Timestamp:** {{timestamp}}
  </template-output>
</step>

<step n="6" goal="Run final validation and generate report">
  <action>Execute validation script on all remediated files</action>
  <action>Compare results with baseline metrics</action>
  <action>Calculate improvement percentages</action>
  
  <template-output file="{progress_tracker}">
## Final Validation Results

**Completion Date:** {{date}}

### Stories
- **Before:** {{initial_non_compliant_stories}}/{{total_stories}} non-compliant
- **After:** {{final_non_compliant_stories}}/{{total_stories}} non-compliant
- **Improvement:** {{stories_improvement_pct}}%
- **Status:** {{stories_status}}

### Tech Specs
- **Before:** {{initial_non_compliant_specs}}/{{total_tech_specs}} non-compliant
- **After:** {{final_non_compliant_specs}}/{{total_tech_specs}} non-compliant
- **Improvement:** {{specs_improvement_pct}}%
- **Status:** {{specs_status}}

### Epic Contexts
- **Before:** {{initial_non_compliant_contexts}}/{{total_epic_contexts}} non-compliant
- **After:** {{final_non_compliant_contexts}}/{{total_epic_contexts}} non-compliant
- **Status:** {{contexts_status}}

## Summary
- **Total Files Remediated:** {{total_remediated}}
- **Total Backups Created:** {{total_backups}}
- **Errors Encountered:** {{errors_count}}
- **Manual Review Required:** {{manual_review_list}}

## Next Steps
{{#if final_non_compliant_stories > 0}}
- [ ] Review remaining {{final_non_compliant_stories}} non-compliant stories
- [ ] Manual remediation may be required for complex cases
{{/if}}
{{#if final_non_compliant_specs > 0}}
- [ ] Complete remaining {{final_non_compliant_specs}} tech specs
{{/if}}
- [ ] Run `melos run analyze` to verify no code issues
- [ ] Commit changes with message: "docs: template compliance remediation"
  </template-output>
  
  <action>Display final report to user</action>
  <action>Provide recommendations for any remaining issues</action>
</step>

<step n="7" goal="Cleanup and documentation">
  <action>Move validation script to permanent location if needed</action>
  <action>Archive progress tracker to docs/archive/ with date</action>
  <action>Update workflow-status if applicable</action>
  
  <check if="auto_commit == true">
    <action>Stage all remediated files</action>
    <action>Create commit with detailed message</action>
  </check>
  
  <check if="auto_commit == false">
    <ask>Would you like to commit the remediated files now? (y/n)</ask>
  </check>
  
  <action>Display completion message with statistics</action>
  <action>Provide guidance on next workflow steps</action>
</step>

</workflow>

## Special Handling Rules

### Story Status Inference
When adding missing Status section, infer from file state:
- Has completed Dev Agent Record → "done"
- Has Dev Agent Record in progress → "in-progress"
- Has Review section → "review"
- Has Tasks but no Dev Agent → "ready"
- Minimal content → "backlog"

### Dev Notes Source Priority
1. **Tech Spec (epic-specific)** - Primary source
2. **Epic Context** - Secondary for patterns/stack
3. **Architecture docs** - Tertiary for constraints
4. **Previous story** - For learnings/reuse

### Citation Format
Always cite sources in Dev Notes:
```markdown
[Source: tech-spec-epic-X.md#section-name]
[Source: architecture/architecture.md#source-tree]
[Source: stories/previous-story.md]
```

### Validation After Each Batch
After completing each epic or priority tier:
1. Run validation script
2. Update progress tracker
3. Show user current completion percentage
4. Ask to continue or pause

### Error Handling
If remediation fails for a file:
1. Log error in progress tracker
2. Skip to next file
3. Add to manual review list
4. Continue workflow
5. Report errors in final summary

## Progress Checkpoints

The workflow creates checkpoints after each major step:
- ✅ Step 1: Environment initialized
- ✅ Step 2: Analysis complete
- ✅ Step 3: Critical stories remediated
- ✅ Step 4: Dev Notes added
- ✅ Step 5: Tech specs completed
- ✅ Step 6: Final validation
- ✅ Step 7: Cleanup complete

User can resume from any checkpoint by rerunning workflow.
