# Analyst Session Checkpoint — 2025-09-26

Status: Finalized — brief updated; ready for PM handoff.

## Summary
- Vision: Short‑form craft marketplace turning story‑rich videos into buyable artifacts.
- Audience: Primary — independent makers (MVP focus). Secondary — viewers of maker content across any category who may buy what they saw.
- Core Value: One place for makers to tell an artifact’s story and get paid (no DMs/platform‑hopping), connecting viewers to offers/auctions and checkout.
- Feed: Shorts/TikTok style; right‑rail actions; bottom “View Story” pill; no auction/prices in feed.
- Story: Overview, Process, Materials/Tools, Notes, optional Location; primary CTA “I want this”.
- Offers & Auction Rules: First non‑rejected offer opens auction; if first offer immediately rejected → no auction. Soft‑close in hours: base 48h, tiers 48/72/96h, +24h if >$1k, cap 7 days; resets on each bid. Maker can accept anytime. Min next bid = max(1%, 5 units).
- Payments: On accept → 24h to pay; non‑payment → maker may accept next‑highest within 24h or return to Listed.
- Shipping: Address at payment; seller self‑ships; tracking; ship‑by 72h; auto‑complete 7 days post‑delivery; issues window 48h.
- Docs created: 
  - Wireframes: 
    - docs/wireframes/mvp-feed-and-story.md
    - docs/wireframes/mvp-checkout-and-payment.md
    - docs/wireframes/mvp-orders-and-tracking.md
    - docs/wireframes/mvp-maker-dashboard.md
  - Acceptance Criteria: docs/acceptance-criteria/mvp-acceptance-criteria.md
  - Architecture: docs/architecture/offers-auction-orders-model.md
  - Analytics: docs/analytics/mvp-analytics-events.md

## Checkpoint Update (End of Session)
- docs/brief.md: Major updates
  - Goals & Metrics: Added North Star (POAL), SMART targets, KPI definitions, measurement notes.
  - MVP Scope: Optional story sections; minimal in-app capture/composer; clarified auction mechanics; Stripe Checkout details; orders/shipping; analytics.
  - Auction Rules: New dedicated section (72h, 15m soft close, accept high bid, 24h pay).
  - Payments & PSP: Stripe Connect Express; US-only; hosted Checkout; webhooks; payout policy.
  - Content Protection: Sandboxed encrypted capture; tokenized HLS; watermark; offline disabled in MVP.
  - Playback & Player: HLS ABR; `video_player`/hls.js; no casting/offline; analytics.
  - Backend: Dart + Serverpod modular monolith; microservices later.
  - Next Steps: Owners and target dates assigned.
- Open items not addressed: NFRs & Glossary; Risk mitigations with deadlines.
- Recommended next session: Add NFRs + Glossary; draft risk mitigations.

## Follow-up Update (2025-09-26)
- Action taken: Added comprehensive Non-Functional Requirements to docs/brief.md covering Security & Privacy, Content Protection, Performance, Availability & Reliability, Observability, Payments & Compliance, Accessibility & UX, Mobile/Web Constraints, Data Management, Ops & DR.
- Status alignment: Pending — brief shows "Status: Draft v0.1" while this session reads "Finalized"; reconcile in next update.
- Next suggested actions: Draft Risk Mitigations table (owner/action/deadline) and expand Glossary for payment, shipping, and media terms.

## Follow-up Update (2025-09-27)
- Action taken: Updated docs/brief.md to reflect "Status: Finalized v0.1 (Ready for PM handoff)", added a Risk Mitigations table with owners/actions/dates, and extended the Glossary with payment, shipping, and media terminology.
- Status alignment: Resolved — brief status now matches session summary; brief ready for PM handoff.
- Next suggested actions: Monitor execution owners against targets; once PM creates PRD draft, plan analyst support for validation of assumptions and terminology.

Further updates captured in `docs/sessions/2025-09-29-analyst-checkpoint.md`.
