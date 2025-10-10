# MVP Wireframes — Feed and Story

This document captures low‑fi ASCII wireframes and key interaction notes for the MVP buyer and story experiences.

## Feed (Shorts/TikTok‑style)

```
┌──────────────────────────────────────────────────────────────┐
│  Maker • @handle                    Share ⋯                   │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                                                        │  │
│  │                    HERO VIDEO (autoplay)               │  │
│  │                    (tap → Story)                       │  │
│  │                                                        │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│     ❤  1.2k      🔖  340      ⤴︎  120      + Follow      ⋯    │
│                                                              │
│  [ View Story ]  (bottom pill — replaces chat)               │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

- Gestures: swipe up/down to browse; double‑tap to like; long‑press → quick actions (Save/Share/Not interested).
- Right rail (icons + optional counts): Like, Save, Share, Follow, More.
- Bottom pill: “View Story” opens Artifact Story; no auction or price info in feed.
- Accessibility: ≥44px tap targets; captions toggle; haptic on like/save.

## Story Page

```
┌──────────────────────────────────────────────────────────────┐
│  Maker • @handle              Follow   Share (123)     ⋯      │
├──────────────────────────────────────────────────────────────┤
│  ┌─────────────── HERO VIDEO (scrubbable) ─────────────────┐  │
│  │                                                      ▶ │  │
│  └────────────────────────────────────────────────────────┘  │
│  [ thumbnails ▷ ▷ ▷ ]                                         │
├──────────────────────────────────────────────────────────────┤
│  Title • Category                                            │
│  Short description (≤140 chars)                              │
│  [ I want this ]  (scrolls to Offers & Auction)              │
├──────────────────────────────────────────────────────────────┤
│  Process Timeline (optional steps with timestamps)           │
├──────────────────────────────────────────────────────────────┤
│  Materials & Tools (name, notes, links)                      │
├──────────────────────────────────────────────────────────────┤
│  Notes (freeform)                                            │
│  Location (optional)                                         │
├──────────────────────────────────────────────────────────────┤
│  Offers & Auction                                            │
│  ─────────────────────────────────────────────────────────   │
│  Make an offer to the creator for a chance to acquire this   │
│  item.                                                       │
│  Hint: The creator can accept or reject your proposal. Until │
│  accepted, anyone can outbid your offer.                     │
│                                                              │
│  When no auction yet:                                        │
│    Amount [____]  Note [____________________]                │
│    Chips: 50  100  250  |  Round up  |  Custom              │
│    [ Submit offer ]                                          │
│                                                              │
│  When auction open:                                          │
│    Highest bid: $___    Time left: __h__m    Watchers: __    │
│    Amount [____]  Note [____________________]                │
│    Chips: +5%  +10%  +25%  ×2  ×3  |  Round up               │
│    Rule: Min next bid = max(1%, 5 units). New bids extend.   │
│    [ Place bid ]   [ Watch auction ]                         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Offer/Bid Sheet (Modal)

```
┌──────────────────────────────────────────────────────────────┐
│  Make an offer                                                │
├──────────────────────────────────────────────────────────────┤
│  Amount [__________]  (currency‑aware)                       │
│  Note   [______________________________] (optional)          │
│                                                              │
│  Quick suggestions (no auction):  50   100   250   Round up  │
│                                                              │
│  Quick picks (auction open):  +5%   +10%   +25%   ×2   ×3    │
│                               Round up                       │
│                                                              │
│  Hint: The creator can accept or reject your proposal. Until │
│  accepted, anyone can outbid your offer.                     │
│                                                              │
│  Min next bid: max(1%, 5 units).                             │
│                                                              │
│  [ Cancel ]                       [ Submit offer / Place bid ]│
└──────────────────────────────────────────────────────────────┘
```

- Validation: Disable submit until amount ≥ min next bid (if auction). Inline errors show; helper text gives “Estimated next valid bid”.
- Behavior: On submit, close modal → toast; update Story state (highest bid/time left) as applicable.

## Maker — Publish Flow

```
┌──────────────────────────────────────────────────────────────┐
│  Create Artifact Story                                       │
├──────────────────────────────────────────────────────────────┤
│  Title [____________________]                                │
│  Category [ select ▾ ]                                       │
│  Short description (≤140) [______________________________]   │
│                                                              │
│  Hero media  [ Upload ]  [ Choose from gallery ]             │
│  Gallery     [ Add images/videos ]                           │
│  Timeline    [ + Add step ] (time‑coded, optional)           │
│                                                              │
│  Materials & Tools  [ + Add item ]                           │
│  Notes               [______________________________]        │
│  Location (optional) [ City/Country ]                        │
│                                                              │
│  Offer policy                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Auto‑reject below [ ___ ] (currency) [On/Off]          │  │
│  │ First non‑rejected offer opens the auction; the first  │  │
│  │ offer rejected immediately means no auction starts.    │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  [ Preview ]                         [ Publish (disabled) ]  │
│                                                              │
│  Publish requires: Title, Hero, Category, Short description. │
└──────────────────────────────────────────────────────────────┘
```

- Publish gate: Enable Publish only when required fields are present; show checklist.
- After publish: Item becomes Listed; feed uses Hero media; Story hosts Offers & Auction.

## Key Rules Recap

- First non‑rejected offer opens the auction; immediate rejection of the first offer means no auction starts.
- Soft‑close in hours: base 48h; popularity tiers 48/72/96h; +24h if >$1k; cap 7 days total; timer resets on each new bid.
- Maker can accept at any time to close; buyer then has 24h to pay.
- Shipping MVP: address at payment; seller self‑ships; tracking required; ship‑by 72h; auto‑complete 7 days after delivery.

## Notes

- Deep‑links: Share goes to the Story page (OG tags: title, hero image, maker).
- Feed shows no auction or price signals—keeps focus on discovery; Story hosts all transaction logic.
