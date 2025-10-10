# MVP Wireframes — Orders & Tracking

Covers buyer order detail, shipment tracking, and post‑delivery flows. Aligns with MVP rules: seller self‑ships, tracking required; ship‑by 72h; auto‑complete 7 days after delivery; issues window 48h.

## Orders List (Buyer)

```
┌──────────────────────────────────────────────────────────────┐
│  Orders                                                       │
├──────────────────────────────────────────────────────────────┤
│  ▸ Awaiting shipment (1)                                      │
│    • CM‑2025‑000123  “Artifact title”  $____                  │
│      Ship by: Sep 30                                          │
│  ▸ In transit (0)                                             │
│  ▸ Delivered (0)                                              │
│  ▸ Completed (0)                                              │
└──────────────────────────────────────────────────────────────┘
```

- Sort by status then recency; show ship‑by on awaiting shipment.

## Order Detail (Buyer)

```
┌──────────────────────────────────────────────────────────────┐
│  Order CM‑2025‑000123                                        │
├──────────────────────────────────────────────────────────────┤
│  Artifact: “Title” by Maker @handle                          │
│  Paid:    $____  on <date/time>                              │
│  Status:  Awaiting shipment  (ship by <date>)                │
│  Ship to: John A, 123 Main St, City, ST 00000               │
│                                                              │
│  [ Contact maker ]   [ View story ]                          │
│                                                              │
│  Shipment                                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Not yet shipped                                       │  │
│  │ ETA: —                                                │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  Timeline                                                   │
│  • Paid                                                     │
│  • Label created (when available)                           │
│  • In transit                                              │
│  • Out for delivery                                        │
│  • Delivered                                               │
│                                                              │
│  [ Report an issue ] (enabled 0–48h after delivery)          │
└──────────────────────────────────────────────────────────────┘
```

- Delivery detection: mark delivered via tracking webhook or user confirm.
- Auto‑complete: 7 days after delivery → Completed unless issue open.

## Report Issue (Buyer)

```
┌──────────────────────────────────────────────────────────────┐
│  Report an issue                                             │
├──────────────────────────────────────────────────────────────┤
│  Within 48h of delivery you can open an issue.               │
│  Type [ select ▾ ]   (not received / damaged / not as described / other)
│  Details [____________________________________________]      │
│  Photos  [ + Add ]                                           │
│                                                              │
│  [ Cancel ]                         [ Submit ]               │
└──────────────────────────────────────────────────────────────┘
```

- Submits a case; pauses auto‑complete; flags for maker support workflow (MVP: manual resolution).

## Orders — Maker (To Ship)

```
┌──────────────────────────────────────────────────────────────┐
│  To Ship                                                     │
├──────────────────────────────────────────────────────────────┤
│  • CM‑2025‑000123  “Title”  $____   Ship by: Sep 30          │
│    [ Add tracking ]                                          │
└──────────────────────────────────────────────────────────────┘
```

## Add Tracking (Maker)

```
┌──────────────────────────────────────────────────────────────┐
│  Add tracking                                                │
├──────────────────────────────────────────────────────────────┤
│  Carrier [ select ▾ ]                                       │
│  Tracking number [__________________]                        │
│  Ship date [____-__-__]                                     │
│                                                              │
│  [ Save ]                                                    │
└──────────────────────────────────────────────────────────────┘
```

- On save: order → In transit; buyer sees tracking; timeline updates.

## Delivered State

```
┌──────────────────────────────────────────────────────────────┐
│  Order CM‑2025‑000123                                        │
├──────────────────────────────────────────────────────────────┤
│  Status: Delivered  (issues window: 47h 12m left)            │
│  [ Report an issue ]                                         │
│                                                              │
│  Auto‑complete: on Oct 07 unless an issue is opened.         │
└──────────────────────────────────────────────────────────────┘
```

## Completed State

```
┌──────────────────────────────────────────────────────────────┐
│  Order CM‑2025‑000123                                        │
├──────────────────────────────────────────────────────────────┤
│  Status: Completed                                           │
│  [ Leave feedback ] (post‑MVP)                               │
└──────────────────────────────────────────────────────────────┘
```
