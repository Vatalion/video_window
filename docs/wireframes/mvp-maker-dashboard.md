# MVP Wireframes — Maker Dashboard

Covers maker workflow post‑publish: manage offers/auction, accept/reject, orders to ship, and basic settings. Focus is on minimal surfaces needed for MVP.

## Dashboard Home

```
┌──────────────────────────────────────────────────────────────┐
│  Maker Dashboard                                             │
├──────────────────────────────────────────────────────────────┤
│  Stats (MVP minimal)                                         │
│  • Active auctions: 1                                        │
│  • Offers to review: 2                                       │
│  • Orders to ship: 1                                         │
│                                                              │
│  Shortcuts                                                   │
│  [ My stories ]  [ Offers ]  [ Orders ]  [ Settings ]        │
└──────────────────────────────────────────────────────────────┘
```

## Offers Queue

```
┌──────────────────────────────────────────────────────────────┐
│  Offers                                                      │
├──────────────────────────────────────────────────────────────┤
│  • “Artifact title”                                         │
│    Highest: $____   New offer: $____ by @buyer               │
│    [ Accept ]  [ Reject ]  [ View story ]                    │
└──────────────────────────────────────────────────────────────┘
```

- First non‑rejected offer opens auction; reject first offer → no auction opens.
- Accept can be done anytime to close auction and create payment window.

## Auction Detail (Active)

```
┌──────────────────────────────────────────────────────────────┐
│  Auction — “Artifact title”                                  │
├──────────────────────────────────────────────────────────────┤
│  Highest bid: $____   Time left: __h__m                      │
│  Bids                                                        │
│  • $____  @buyer1  <timestamp>                               │
│  • $____  @buyer2  <timestamp>                               │
│                                                              │
│  Rule: Min next bid = max(1%, 5 units). New bids extend.     │
│  [ Accept current ]  [ Share link ]                          │
└──────────────────────────────────────────────────────────────┘
```

## Orders — To Ship

```
┌──────────────────────────────────────────────────────────────┐
│  Orders — To Ship                                            │
├──────────────────────────────────────────────────────────────┤
│  • CM‑2025‑000123  “Artifact title”  $____  Ship by: Sep 30  │
│    [ Add tracking ]                                          │
└──────────────────────────────────────────────────────────────┘
```

- Mirrors the buyer flow once tracking is added; status moves to In transit/Delivered.

## Settings (MVP)

```
┌──────────────────────────────────────────────────────────────┐
│  Settings                                                    │
├──────────────────────────────────────────────────────────────┤
│  Offer policy                                                │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Auto‑reject below [ ___ ] (currency) [On/Off]          │  │
│  │ First non‑rejected offer opens the auction; first      │  │
│  │ offer rejected immediately means no auction starts.    │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  Notifications [ ✓ Offers  ✓ Bids  ✓ Orders ]                │
│                                                              │
│  Profile basics (display name, handle, avatar)               │
└──────────────────────────────────────────────────────────────┘
```
