# UX & Dev Handoff Package — Craft Video Marketplace MVP

Status: Draft v0.2 — Prepared after architecture baseline (2025-09-30); updated with action owners and due dates.

## UX Expert Brief (Owner: Sally — UX Expert)
- **Deliverable:** High-fidelity screens covering the flows below, exported to Figma + PNG previews.
- **Deadline:** 2025-10-07 (one week before Epic 4 development start).
- **Handoff:** Link artefacts in `docs/wireframes/README.md` and tag PM/Dev/QA in story change logs.
- **Primary Screens:**
  1. Feed (short-form video list with sticky "View Story" pill).
  2. Story detail (Overview, Process, Materials/Tools, Notes, optional Location; accessible playback + CTA).
  3. Offer/Bid flow (qualification modal, auction state display, confirmation).
  4. Payment countdown screen + Stripe Checkout entry (hosted webview handoff).
  5. Orders timeline (buyer view: tracking states; maker tasks: ship-by countdown).
  6. Maker dashboard (active listings, auctions, fulfillment tasks).
- **UI Guardrails:**
  - Apply design tokens from `packages/design_system` (color/typography/spacing) once finalized in Epic F2.
  - Respect accessibility: 44x44 tap targets, captions, reduced motion toggles, contrast ≥4.5:1.
  - Integrate watermark/capture deterrence cues (e.g., overlay indicator, no download affordances).
  - Use Serverpod-generated models from `packages/shared_models` for type safety.
- **Inputs for Wireframes:**
  - PRD Epics 4–7, 9–13 detail FR/NFR expectations.
  - Architecture doc sections show data interactions across packages.
  - Story-component mapping clarifies which packages own each flow (`docs/architecture/story-component-mapping.md`).
  - Data flow patterns (`docs/architecture/data-flow-mapping.md`) show Serverpod integration points.
- **Deliverables:**
  - High-fidelity mockups for each primary screen (Feed, Story, Offer/Bid, Payment, Orders, Maker dashboard).
  - Interaction specs for auction countdown, offer qualification, payment window expiry (embedded annotations).
  - Accessibility checklist per screen (captions, motion, voiceover labels) appended to mockups.
  - Component inventory mapping to design tokens (colors, typography, elevation) for developer reference.

## Developer Kickoff (Epic F1 Focus — Owner: Dev Lead)
- **Immediate Goals:**
  1. Setup Melos workspace and unified package structure (`docs/architecture/source-tree.md`).
  2. Implement core packages (mobile_client, core, shared_models, design_system).
  3. Configure CI (format/analyze/test) and branching guardrails per `docs/architecture/coding-standards.md`.
  4. Configure secrets handling and release channel docs (F1.4).
- **Work Breakdown:**
  - Use story mapping table (Epic F1 stories) to assign tasks; keep PR/branches scoped to single story.
  - Update `docs/stories/...` for status changes and Dev Agent Record.
  - Ensure `melos run validate` is operational; document any adjustments in story logs.
- **Technical References:**
  - Unified package structure in `docs/architecture/source-tree.md`.
  - Serverpod module layout in `docs/architecture/SERVERPOD-INTEGRATION-GUIDE.md`.
  - Database schema excerpt for initial migrations (users, stories, offers, auctions).
  - Coding standards for package dependencies, BLoC patterns, testing.
  - Data flow patterns (`docs/architecture/data-flow-mapping.md`) for Serverpod integration.
- **Risks/Watchouts:**
  - Flutter/Serverpod version alignment (3.35+/2.9.x) — run `flutter --version` + `serverpod --version` in setup.
  - Melos workspace setup complexity; ensure path dependencies work correctly.
  - Serverpod code generation workflow; must run `melos run generate` after model changes.
  - Media pipeline dependencies (FFmpeg/MediaConvert) stubbed during F1; ensure placeholder modules throw clear TODOs.
  - Secrets scanning must run in CI to prevent leakage when scaffolding environment configs.

## Coordination Notes
- Schedule architecture/UX sync after wireframes to validate CTA placements vs technical constraints (e.g., Stripe hosted flows).
- Dev team to review UX wireframes before implementing Epics 4–7 to align on state ownership and analytics instrumentation.
- Update this handoff doc as UX specs or development conventions evolve.
