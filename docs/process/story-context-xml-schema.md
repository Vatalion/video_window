# Story Context XML Schema - Enhanced with Implementation Guidance

**Version:** 2.0
**Updated:** 2025-11-10
**Status:** Active - MANDATORY for all new stories

---

## Overview

This document defines the **enhanced Story Context XML schema** that includes explicit implementation guidance references. This schema ensures developers have direct access to relevant architectural documentation, patterns, runbooks, and framework guides during story implementation.

---

## Schema Structure

```xml
<?xml version="1.0" encoding="utf-8"?>
<story-context id="{epic}-{story}-{slug}" generated="{YYYY-MM-DD}">
  
  <!-- Existing sections (unchanged) -->
  <metadata>...</metadata>
  <user-story>...</user-story>
  <acceptance-criteria>...</acceptance-criteria>
  <story-tasks>...</story-tasks>
  <prerequisites>...</prerequisites>
  <artifacts>...</artifacts>
  <constraints>...</constraints>
  <tests>...</tests>
  
  <!-- NEW SECTION: Implementation Guidance -->
  <implementation-guidance>
    <architecture>
      <doc priority="CRITICAL|HIGH|MEDIUM">
        <path>{relative-path-from-project-root}</path>
        <section>{specific-section-or-ALL}</section>
        <reason>{why-this-doc-is-relevant}</reason>
        <applies-to>{task-ids-or-ALL}</applies-to>
      </doc>
    </architecture>
    
    <patterns>
      <pattern priority="CRITICAL|HIGH|MEDIUM">
        <path>{relative-path-from-project-root}</path>
        <section>{specific-section-or-ALL}</section>
        <reason>{why-this-pattern-applies}</reason>
        <applies-to>{task-ids-or-ALL}</applies-to>
      </pattern>
    </patterns>
    
    <frameworks>
      <framework priority="CRITICAL|HIGH|MEDIUM">
        <name>{framework-name}</name>
        <path>{relative-path-from-project-root}</path>
        <section>{specific-section-or-ALL}</section>
        <reason>{why-this-framework-guide-matters}</reason>
        <applies-to>{task-ids-or-ALL}</applies-to>
      </framework>
    </frameworks>
    
    <runbooks>
      <runbook priority="CRITICAL|HIGH|MEDIUM">
        <path>{relative-path-from-project-root}</path>
        <section>{specific-section-or-ALL}</section>
        <reason>{operational-context}</reason>
        <applies-to>{task-ids-or-ALL}</applies-to>
      </runbook>
    </runbooks>
    
    <adrs>
      <adr priority="CRITICAL|HIGH|MEDIUM">
        <number>{ADR-####}</number>
        <path>docs/architecture/adr/{ADR-####-name}.md</path>
        <decision>{brief-summary-of-decision}</decision>
        <reason>{why-relevant-to-story}</reason>
        <applies-to>{task-ids-or-ALL}</applies-to>
      </adr>
    </adrs>
    
    <security optional="true">
      <requirement priority="CRITICAL">
        <path>{security-doc-path}</path>
        <section>{specific-section}</section>
        <applies-to>{task-ids}</applies-to>
      </requirement>
    </security>
  </implementation-guidance>
  
</story-context>
```

---

## New Section: `<implementation-guidance>`

### Purpose

Provides **explicit references** to technical documentation that developers MUST consult during implementation. This eliminates:
- Architectural drift from reinventing patterns
- Security oversights from missing security requirements
- Performance issues from ignoring optimization guides
- Framework misuse from not following established patterns

### Subsections

#### 1. `<architecture>`
References to architectural design documents, system integration maps, and structural patterns.

**When to use:**
- Story involves system design, layer boundaries, or component interactions
- New services, endpoints, or major features
- Cross-cutting concerns (auth, caching, state management)

**Examples:**
- BLoC implementation patterns
- Data flow transformations
- Service integration patterns
- API gateway routing

#### 2. `<patterns>`
References to the Pattern Library and specific reusable patterns.

**When to use:**
- Story implements common UI/UX patterns
- Backend patterns (repository, service, endpoint)
- Error handling, validation, or retry patterns

**Examples:**
- Form validation patterns
- Error boundary patterns
- Retry/backoff patterns
- Repository patterns

#### 3. `<frameworks>`
References to framework-specific integration guides (Serverpod, BLoC, Stripe, etc.).

**When to use:**
- Story uses specific framework capabilities
- Integration with external services
- Code generation requirements

**Examples:**
- Serverpod endpoint creation
- BLoC state management
- Stripe payment flows
- Flutter camera integration

#### 4. `<runbooks>`
References to operational procedures, deployment guides, and workflow documentation.

**When to use:**
- Story requires specific operational procedures
- Deployment or configuration changes
- Data migration or management tasks

**Examples:**
- CI/CD pipeline procedures
- Code generation workflows
- Database migration procedures
- Local development setup

#### 5. `<adrs>`
References to Architecture Decision Records that explain WHY certain approaches are used.

**When to use:**
- Story implements features covered by ADR decisions
- Technology choices need context
- Understanding rationale prevents mistakes

**Examples:**
- ADR-0002: Flutter + Serverpod (all stories)
- ADR-0007: State Management (BLoC stories)
- ADR-0009: Security Architecture (auth/security stories)

#### 6. `<security>` (optional)
Explicit security requirements and documentation for stories with security implications.

**When to use:**
- Authentication/authorization stories
- Payment processing
- PII/sensitive data handling
- Compliance requirements (GDPR, PCI-DSS)

---

## Priority Levels

### CRITICAL
- Developer MUST read BEFORE starting implementation
- Failure to follow will result in story rejection
- Security requirements, architectural constraints

### HIGH
- Developer MUST read during implementation
- Referenced when implementing specific tasks
- Framework guides, pattern documentation

### MEDIUM
- Developer SHOULD consult as needed
- Background context, optimization guides
- Additional examples, edge case handling

---

## Attributes

### `priority`
**Required.** Indicates importance level (CRITICAL|HIGH|MEDIUM)

### `<path>`
**Required.** Relative path from project root to documentation file.

### `<section>`
**Optional.** Specific section within the document. Use "ALL" if entire document applies.

### `<reason>`
**Required.** Brief explanation of why this documentation is relevant to this story.

### `<applies-to>`
**Required.** Comma-separated task IDs (e.g., "task1,task2") or "ALL" if applies to entire story.

---

## Developer Contract

When a Story Context XML includes `<implementation-guidance>`:

### Amelia (Developer Agent) SHALL:

1. **Read ALL CRITICAL priority documents BEFORE implementation begins**
2. **Read HIGH priority documents when implementing applicable tasks**
3. **Consult MEDIUM priority documents as needed during implementation**
4. **Treat documented patterns as REQUIREMENTS, not suggestions**
5. **Cite specific documentation sections when making implementation decisions**
6. **Flag conflicts between story requirements and documented patterns immediately**
7. **Request clarification if documentation is unclear or missing**

### Amelia SHALL NOT:

1. **Implement solutions that contradict documented patterns**
2. **Skip reading CRITICAL priority documentation**
3. **Reinvent patterns that exist in pattern library**
4. **Ignore security documentation for security-sensitive stories**

---

## Bob's Story Preparation Checklist

When preparing stories, Bob SHALL:

- [ ] **Review story requirements and identify technical domains**
- [ ] **Consult Winston's Documentation Mapping Guide**
- [ ] **Add `<implementation-guidance>` section to Story Context XML**
- [ ] **Include ALL relevant architecture documentation**
- [ ] **Reference applicable patterns from pattern library**
- [ ] **Link framework guides for technologies used**
- [ ] **Include runbooks for operational procedures**
- [ ] **Reference ADRs that explain architectural decisions**
- [ ] **Add security docs for auth/payment/PII stories**
- [ ] **Set appropriate priority levels (CRITICAL/HIGH/MEDIUM)**
- [ ] **Map documentation to specific tasks using `applies-to`**
- [ ] **Write clear `reason` for each documentation reference**
- [ ] **Verify all paths are correct and documents exist**

---

## Example: Authentication Story

```xml
<implementation-guidance>
  <architecture>
    <doc priority="CRITICAL">
      <path>docs/architecture/serverpod-auth-module-analysis.md</path>
      <section>ALL</section>
      <reason>Serverpod auth module integration patterns and limitations</reason>
      <applies-to>ALL</applies-to>
    </doc>
    <doc priority="HIGH">
      <path>docs/architecture/serverpod-integration-guide.md</path>
      <section>Authentication Endpoints</section>
      <reason>Standard patterns for auth endpoint implementation</reason>
      <applies-to>task1,task2</applies-to>
    </doc>
  </architecture>
  
  <patterns>
    <pattern priority="HIGH">
      <path>docs/architecture/pattern-library.md</path>
      <section>Authentication Patterns</section>
      <reason>Standard OTP generation and validation patterns</reason>
      <applies-to>task1</applies-to>
    </pattern>
    <pattern priority="HIGH">
      <path>docs/architecture/bloc-implementation-guide.md</path>
      <section>Authentication BLoC Patterns</section>
      <reason>Auth state management implementation</reason>
      <applies-to>task8,task9</applies-to>
    </pattern>
  </patterns>
  
  <frameworks>
    <framework priority="CRITICAL">
      <name>Serverpod</name>
      <path>docs/frameworks/serverpod/05-authentication-sessions.md</path>
      <section>ALL</section>
      <reason>Serverpod authentication and session management</reason>
      <applies-to>ALL</applies-to>
    </framework>
  </frameworks>
  
  <runbooks>
    <runbook priority="MEDIUM">
      <path>docs/runbooks/authentication.md</path>
      <section>ALL</section>
      <reason>Auth troubleshooting and operational procedures</reason>
      <applies-to>ALL</applies-to>
    </runbook>
  </runbooks>
  
  <adrs>
    <adr priority="CRITICAL">
      <number>ADR-0009</number>
      <path>docs/architecture/adr/ADR-0009-security-architecture.md</path>
      <decision>Security architecture including OTP, JWT, token management</decision>
      <reason>Defines security requirements and patterns for authentication</reason>
      <applies-to>ALL</applies-to>
    </adr>
  </adrs>
  
  <security>
    <requirement priority="CRITICAL">
      <path>docs/architecture/adr/ADR-0009-security-architecture.md</path>
      <section>SEC-001: OTP Generation, SEC-003: JWT Token Management</section>
      <applies-to>task1,task2,task3,task4,task5,task6</applies-to>
    </requirement>
  </security>
</implementation-guidance>
```

---

## Migration Strategy

### Phase 1: In-Progress Stories (Immediate)
1. Audit stories currently in-progress
2. Add `<implementation-guidance>` sections
3. Notify Amelia of updated Story Context XMLs

### Phase 2: Ready-for-Dev Stories (Before Development)
1. Systematically update all ready-for-dev stories
2. Prioritize by sprint planning order
3. Verify documentation references are current

### Phase 3: Future Stories (Standard Practice)
1. Include `<implementation-guidance>` in all new Story Context XMLs
2. Mandatory section in story preparation checklist
3. Review process verifies documentation references

---

## Validation

Before marking story as ready-for-dev, verify:

- [ ] `<implementation-guidance>` section exists
- [ ] At least one CRITICAL or HIGH priority reference included
- [ ] All file paths are valid and documents exist
- [ ] `applies-to` maps to actual task IDs
- [ ] `reason` clearly explains relevance
- [ ] Security documentation included for sensitive stories
- [ ] ADRs explain architectural context

---

## Benefits

### For Developers
- Clear guidance on where to find implementation patterns
- Reduced cognitive load from not having to search for docs
- Confidence that implementation follows project standards
- Understanding of WHY certain approaches are required

### For Architecture
- Prevents architectural drift
- Ensures patterns are consistently applied
- Documentation actually gets used
- ADRs provide decision context

### For Quality
- Reduces rework from reinventing patterns
- Security requirements explicitly referenced
- Performance optimizations not overlooked
- Testing patterns consistently applied

### For Velocity
- Less time searching for "how do we do X?"
- Fewer implementation mistakes requiring rework
- Knowledge transfer embedded in story context
- New team members onboard faster

---

## Questions?

Contact Bob (Scrum Master) for story preparation guidance.
Contact Winston (Architect) for documentation mapping decisions.

