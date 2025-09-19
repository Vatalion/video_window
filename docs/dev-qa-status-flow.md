# Dev ↔ QA Status Flow

1. **Draft** – PM/PO preparing requirements; no engineering work yet.
2. **Approved** – Requirements baselined; development can start when capacity opens.
3. **InProgress** – Active development on a story branch; dev agent updates Tasks/Subtasks.
4. **Ready for Review** – Development complete, local gates passed, Dev Agent Record updated.
5. **QA Review** – QA agent executes validation checklist, records results, and either approves or requests changes.
6. **Done** – QA approved, branch merged after CI green; deployment scheduling follows release phase criteria from `docs/prd.md`.
7. **Blocked / Decision Needed** – Used at any stage to flag dependencies or scope questions for PM follow-up.

Reference `docs/architecture/development-workflow.md` for operational agreements supporting these states.
