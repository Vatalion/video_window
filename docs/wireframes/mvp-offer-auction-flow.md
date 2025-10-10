# MVP Wireframes — Offer, Auction, and Countdown

Prepared by UX Expert (Sally) — 2025-09-30

This addendum focuses on the offer submission, live auction, and countdown surfaces aligned with the architecture blueprint (`docs/architecture.md`).

## Offer Qualification Modal

```
┌───────────────────────────────────────────────┐
│  Make an offer                                │
├───────────────────────────────────────────────┤
│  Step 1 — Qualification                       │
│  • Verify you can pay within 24 hours         │
│  • Confirm shipping address is in the US      │
│  • Agree to community guidelines              │
│                                               │
│  [✓] I can pay within 24 hours                │
│  [✓] My shipping address is in the US         │
│  [✓] I agree to marketplace terms             │
│                                               │
│  [ Continue ]                                 │
│  [ Cancel ]                                   │
└───────────────────────────────────────────────┘
```

- Accessibility: checkbox labels tappable; focus order top → bottom.
- Copy references legal ownership per PRD and coding standards doc for localization later.

## Offer Entry

```
┌───────────────────────────────────────────────┐
│  Step 2 — Enter your offer                    │
├───────────────────────────────────────────────┤
│  Current minimum: $___                        │
│  Highest offer:   $___                        │
│                                               │
│  Your offer:  [$_____]                        │
│  Optional note to maker                       │
│  [_______________________________________]    │
│                                               │
│  Info: First accepted offer opens a 72h       │
│  auction with soft-close extensions.          │
│                                               │
│  [ Submit offer ]                             │
└───────────────────────────────────────────────┘
```

- Inline validation if amount < minimum.
- Note limited to 240 chars; store server-side for maker context.

## Auction Live Banner (Story Page)

```
┌───────────────────────────────────────────────┐
│  Auction live                                 │ 15:23:12
├───────────────────────────────────────────────┤
│  Highest bid: $____ (You’re the highest)      │
│  Next minimum: $____                          │
│                                               │
│  [ Increase bid ]   [ Auction rules ]         │
└───────────────────────────────────────────────┘
```

- Banner is sticky below hero video; color-coded based on user status (green when leading, amber when outbid).
- Timer updates each second; animates subtly when <5 minutes.
- “Auction rules” opens modal summarizing soft-close & total cap.

## Outbid Toast

```
┌───────────────────────────────────────────────┐
│  Outbid!                                      │
├───────────────────────────────────────────────┤
│  New highest bid: $____                       │
│  Place at least $____ to regain lead.         │
│                                               │
│  [ Bid now ]                                  │
└───────────────────────────────────────────────┘
```

- Toast persists 6 seconds; accessible via notification inbox if missed.

## Maker Dashboard — Auction Card

```
┌───────────────────────────────────────────────┐
│  Story: “Title”                               │
│  Auction live — ends in 12:45:03              │
│  Highest bid: $____ by @buyer                 │
│                                               │
│  [ Accept now ]  [ View activity ]            │
└───────────────────────────────────────────────┘
```

- Maker can accept at any time per FR5; button confirms acceptance with warning about payment window.
- “View activity” shows bid timeline, withdrawal notes, and audit log snippet.

## Payment Window Expiry State

```
┌───────────────────────────────────────────────┐
│  Payment window expired                       │
├───────────────────────────────────────────────┤
│  The winning buyer did not pay in time.       │
│  You may:                                     │
│  • Accept the next highest bidder ($____)     │
│  • Return to listed and await new offers      │
│                                               │
│  [ Accept next bid ]   [ Return to listed ]   │
└───────────────────────────────────────────────┘
```

- Mirror on buyer side informs them they missed the window and provides re-engagement CTA to continue browsing.

## Events & Instrumentation
- `offer_modal_opened`, `offer_qualification_completed`, `offer_submitted`
- `auction_banner_viewed`, `bid_increment_tapped`, `outbid_toast_viewed`
- `maker_accept_clicked`, `maker_accept_confirmed`, `payment_window_expired`, `maker_next_bid_selected`

## Handoff Notes
- Visual design should ensure countdown timers meet WCAG color contrast (use design tokens).
- Connect countdown with analytics to flag auctions nearing soft-close for operational monitoring.
- Ensure states align with story-component mapping (modules: `offer_bid`, `auction`, `maker_studio`, `notification_service`).

