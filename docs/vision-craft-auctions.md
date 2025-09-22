# Vision: Craft Process Videos with Auctions

## Summary
Enable makers to showcase the creation process of unique, one-of-a-kind goods in short, vertical videos while buyers open time-boxed auctions on eligible posts. Makers never open auctions; they accept or decline buyer-initiated auction requests. Buyers discover craft-in-progress content in a TikTok-style feed and place bids with confidence thanks to provenance, authenticity, and escrow-backed fulfillment.

## Product Principles
- Process-first storytelling: prioritize making sequences, materials, and skill over polished catalogs.
- Scarcity by design: listings are unique or limited editions with visible numbering and provenance.
- Low-friction creation: record, clip, caption, and mark posts as auction-eligible with maker-defined constraints (reserve floor, quantity, ship regions) without leaving the app.
- Safe to buy: verified makers, reserve pricing, hold-in-escrow, and clear dispute flows.
- Trust signals: maker profile, workshop verification, build logs, and authenticity certificates.

## North Star Metric
Weekly Gross Auction Volume from first-time buyers completing escrow-backed purchases on buyer-opened auctions.

## V1 Scope (Guardrails)
- Vertical short-form feed (auto-play, swipe) sourced from maker posts marked auction-eligible by the maker.
- Auction types: English ascending with reserve price; time-boxed; anti-sniping extension window; buyer opens an auction request that must be accepted by the maker before going live.
- Bidding: pre-authorization holds; outbid notifications; max-bid proxy.
- Payments: card + major wallets at close; funds held in escrow until receipt or completion milestone.
- Fulfillment: shipping label generation and tracking; optional local pickup; dispute mediation.
- Maker tools: capture + simple edits; add materials, build stages, and quantity (1-of-1 or small batch); set eligibility and constraints (reserve floor, edition limit, ship regions); accept/decline auction requests.

## Non-Goals (V1)
- Live streaming; wholesale catalogs; generalized marketplace for mass-produced goods; BNPL.

## Dependencies
- Identity verification (01), content capture/editing (03), feed/discovery (04), payments/escrow/fulfillment (05).
