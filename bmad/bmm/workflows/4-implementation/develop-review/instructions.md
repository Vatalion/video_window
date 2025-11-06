# Develop-Review - Orchestration Instructions

```xml
<critical>The workflow execution engine is governed by: {project-root}/bmad/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {installed_path}/workflow.yaml</critical>
<critical>Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}</critical>
<critical>This is a COMPOSITE ORCHESTRATION workflow that continuously loops dev-story → code-review until approved</critical>
<critical>DO NOT stop between iterations unless max_iterations reached or user intervention required</critical>
<critical>Execute the COMPLETE loop in a single session - this is the PRIMARY PURPOSE of this workflow</critical>

<workflow>

  <step n="1" goal="Initialize loop and validate prerequisites">
    <action>Set iteration_count = 0</action>
    <action>Set loop_active = true</action>
    
    <output>🔄 **Dev-Review Loop Starting** 

**Configuration:**
- Max iterations: {{max_iterations}}
- Auto-approve on success: {{auto_approve}}
- Story path: {{story_path || "Auto-discover"}}

This workflow will continuously develop and review until the story is approved or max iterations reached.
    </output>

    <check if="{{story_path}} is provided">
      <action>Validate story file exists at {{story_path}}</action>
      <action if="story file not found">HALT with error: "Story file not found at {{story_path}}"</action>
    </check>

    <action>Load sprint-status.yaml to verify stories are available</action>
    <check if="no stories with status ready-for-dev or in-progress">
      <output>❌ No stories available for development

**Available actions:**
1. Run `story-context` to prepare drafted stories
2. Run `create-story` to draft new stories
3. Check sprint-status.yaml for current state
      </output>
      <action>HALT</action>
    </check>
  </step>

  <step n="2" goal="Development phase - Execute dev-story workflow">
    <action>Increment iteration_count by 1</action>
    
    <output>🔄 **Iteration {{iteration_count}} of {{max_iterations}}**

**Phase: Development** 🛠️
---
    </output>

    <critical>Execute dev-story workflow by loading its instructions completely</critical>
    <action>Load {dev_story_workflow} configuration</action>
    <action>Load dev-story instructions from: {project-root}/bmad/bmm/workflows/4-implementation/dev-story/instructions.md</action>
    <action>Pass {{story_path}} variable if provided, otherwise let dev-story auto-discover</action>
    
    <action>Execute dev-story workflow steps 1-6 completely:
      - Find/load story (with context if available)
      - Detect if resuming after review (Step 1.5)
      - Mark story in-progress
      - Implement all incomplete tasks (prioritizing review follow-ups)
      - Write and run tests
      - Update story file with completions
      - Mark story status as "review"
    </action>

    <action>Capture from dev-story execution:
      - {{current_story_key}}: The story key being worked on
      - {{current_story_path}}: Full path to story file
      - {{dev_completion_status}}: Success or failure
      - {{tasks_completed}}: Count of tasks completed
    </action>

    <check if="dev_completion_status == failure">
      <output>❌ **Development Phase Failed**

The dev-story workflow encountered an error. Please review the output above and address any issues manually.

**Story:** {{current_story_key}}
**Status:** Development incomplete
      </output>
      <action>HALT</action>
    </check>

    <output>✅ **Development Phase Complete**

**Story:** {{current_story_key}}
**Tasks Completed:** {{tasks_completed}}
**Status:** Ready for review

---
    </output>
  </step>

  <step n="3" goal="Review phase - Execute code-review workflow">
    <output>🔄 **Iteration {{iteration_count}} of {{max_iterations}}**

**Phase: Code Review** 🔍
---
    </output>

    <critical>Execute code-review workflow by loading its instructions completely</critical>
    <action>Load {code_review_workflow} configuration</action>
    <action>Load code-review instructions from: {project-root}/bmad/bmm/workflows/4-implementation/code-review/instructions.md</action>
    <action>Pass {{current_story_path}} as story_path to review the just-completed story</action>
    
    <action>Execute code-review workflow steps 1-8 completely:
      - Load story with status "review"
      - Resolve context and tech spec
      - Detect tech stack and best practices
      - Systematic validation (ACs, tasks, code quality)
      - Perform security and risk review
      - Decide review outcome
      - Append review notes to story
      - Update sprint status based on outcome
    </action>

    <action>Capture from code-review execution:
      - {{review_outcome}}: Approve | Changes Requested | Blocked
      - {{action_item_count}}: Number of issues found
      - {{severity_breakdown}}: High/Med/Low counts
      - {{new_story_status}}: Updated story status (done | in-progress | review)
    </action>

    <output>📋 **Review Phase Complete**

**Outcome:** {{review_outcome}}
**Action Items:** {{action_item_count}}
**Severity:** {{severity_breakdown}}
**New Status:** {{new_story_status}}

---
    </output>
  </step>

  <step n="4" goal="Decision gate - Determine next action">
    <check if="review_outcome == 'Approve'">
      <action>Set loop_active = false</action>
      
      <output>✅ **STORY APPROVED!** 🎉

**Story:** {{current_story_key}}
**Iterations Required:** {{iteration_count}}
**Final Status:** done

The story has passed code review and is complete!
      </output>

      <check if="{{auto_commit}} == true">
        <action>Stage all changed files for commit</action>
        <action>Run: git add {{story_dir}}/{{current_story_key}}.md</action>
        <action>Run: git add {{output_folder}}/sprint-status.yaml</action>
        <action>Run: git add . (to capture all implementation files)</action>
        
        <action>Create commit message:
          - Format: "feat({{current_story_key}}): Story complete - {{story_title}}"
          - Body: Include completion date, iteration count, review outcome
        </action>
        
        <action>Run git commit with formatted message</action>
        
        <check if="commit successful">
          <output>✅ Changes committed to Git
          
Commit: feat({{current_story_key}}): Story complete
          </output>
          
          <check if="{{commit_and_push}} == true">
            <action>Get current branch name</action>
            <action>Run: git push origin {{current_branch}}</action>
            <check if="push successful">
              <output>✅ Changes pushed to remote repository</output>
            </check>
            <check if="push failed">
              <output>⚠️ Commit successful but push failed. Run `git push` manually.</output>
            </check>
          </check>
        </check>
        
        <check if="commit failed">
          <output>⚠️ Git commit failed - changes are staged but not committed
          
Please review git status and commit manually.
          </output>
        </check>
      </check>

      <check if="{{auto_approve}} == true">
        <action>Run story-done workflow to mark story as done</action>
        <output>✓ Story automatically marked as done</output>
      </check>

      <action>HALT - Loop complete successfully</action>
    </check>

    <check if="review_outcome == 'Blocked'">
      <output>🚫 **REVIEW BLOCKED**

**Story:** {{current_story_key}}
**Iteration:** {{iteration_count}}
**Reason:** Critical blockers prevent approval

**Blocker details in review notes. Please:**
1. Review the "Senior Developer Review (AI)" section in the story
2. Address blocking issues manually
3. Re-run this workflow when ready

Loop halted - manual intervention required.
      </output>
      <action>HALT - User intervention needed</action>
    </check>

    <check if="review_outcome == 'Changes Requested'">
      <check if="iteration_count >= {{max_iterations}}">
        <output>⚠️ **MAX ITERATIONS REACHED**

**Story:** {{current_story_key}}
**Iterations:** {{iteration_count}} / {{max_iterations}}
**Status:** Changes still needed

The story has not been approved within {{max_iterations}} review cycles.

**Action Items Remaining:** {{action_item_count}}

**Options:**
1. Review the accumulated feedback in the story file
2. Address issues manually and run `code-review` again
3. Increase max_iterations and re-run this workflow
4. Continue with `dev-story` to address remaining items

Loop halted - iteration limit reached.
        </output>
        <action>HALT - Max iterations exceeded</action>
      </check>

      <output>🔄 **Changes Requested - Continuing Loop**

**Iteration:** {{iteration_count}} / {{max_iterations}}
**Action Items:** {{action_item_count}}

Review findings have been added to the story. Continuing to next development iteration...

---
      </output>

      <action>GOTO step 2 - Development phase (dev-story will detect review continuation)</action>
    </check>
  </step>

</workflow>
```
