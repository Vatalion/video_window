# Development & QA Workflow Agreements

1. **Branching**: Follow `story/<id>-<slug>` branches generated via `scripts/story-flow.sh`. Each branch references a story doc under `docs/stories/` and keeps the story Status updated.
2. **Task Sourcing**: Dev agents implement tasks/subtasks from the story files; any new scope requires PM approval and PRD update.
3. **Validation Gates**: Before handoff, run within `crypto_market/`: `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos --fatal-warnings`, and `flutter test --no-pub`.
4. **Dev↔QA Handoff**: Populate the Dev Agent Record and update `## QA Results` once QA completes review. Use `docs/dev-qa-status-flow.md` for status transitions.
5. **Architecture Sync**: Log technical decisions, risks, and feature flag changes in PR or architecture notes, linking back to relevant story and epic docs.
6. **Operations Readiness**: Coordinate moderation, support, and incident response updates with Ops before each release checkpoint outlined in the PRD release phasing table.
