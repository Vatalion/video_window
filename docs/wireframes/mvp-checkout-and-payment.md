# MVP Wireframes — Checkout & Payment

This document captures low‑fi ASCII wireframes and key interaction notes for the buyer checkout flow after an offer/bid is accepted. It aligns with MVP rules: buyer has 24h to pay; seller ships within 72h; issues window 48h; auto‑complete 7 days after delivery.

## Entry Points

- Accepted offer or winning bid → Payment Required screen
- Story → Offers & Auction → visible when user is eligible to pay (accepted)
- Notifications/Inbox → tap → Payment Required

## Payment Required

```
┌──────────────────────────────────────────────────────────────┐
│  Payment required                                            │
├──────────────────────────────────────────────────────────────┤
│  You have 24h to complete payment for this artifact.         │
│  After 24h, the creator may accept the next highest offer.   │
│                                                              │
│  Amount:        $____                                        │
│  Winning offer: $____    Fees/Tax: $__   Total: $____        │
│                                                              │
│  Time left: 23:58:12                                         │
│                                                              │
│  [ Pay now ]                         [ Back to story ]        │
└──────────────────────────────────────────────────────────────┘
```

- Timer persists in background; updates in real time.
- No cancel in MVP; non‑payment simply expires.

## Checkout (Stepper)

```
┌──────────────────────────────────────────────────────────────┐
│  Checkout                                                     │
│  ● Address   ○ Payment   ○ Review   ○ Done                    │
├──────────────────────────────────────────────────────────────┤
│  Step 1 — Shipping address                                    │
│  Full name [________________ ]                                 │
│  Address   [________________ ]                                 │
│  Address 2 [________________ ]                                 │
│  City      [________ ]  State [__]  ZIP [_____ ]               │
│  Country   [ select ▾ ]                                        │
│  Phone     [______________ ]                                   │
│  [ Use saved address ▾ ]                                       │
│                                                                │
│  [ Continue ]                                                  │
└──────────────────────────────────────────────────────────────┘
```

- Validation: postal/phone formats by country; inline errors; focus to first error.
- Accessibility: proper labels, keyboard nav, address autocomplete optional (MVP: manual OK).

```
┌──────────────────────────────────────────────────────────────┐
│  Checkout                                                     │
│  ○ Address   ● Payment   ○ Review   ○ Done                    │
├──────────────────────────────────────────────────────────────┤
│  Step 2 — Payment method                                      │
│  Card number      [____ ____ ____ ____]                       │
│  Exp [MM/YY] [__]    CVC [___]   Name [______________]        │
│  Billing same as shipping [✓]  [ Edit ]                       │
│                                                                │
│  [ Save card ]  (optional)                                     │
│                                                                │
│  [ Continue ]                                                  │
└──────────────────────────────────────────────────────────────┘
```

- Security: tokenize via PSP; no raw card storage in app.
- Errors: decline, insufficient funds, AVS/CVC mismatch → inline + retry.

```
┌──────────────────────────────────────────────────────────────┐
│  Checkout                                                     │
│  ○ Address   ○ Payment   ● Review   ○ Done                    │
├──────────────────────────────────────────────────────────────┤
│  Step 3 — Review & pay                                        │
│  Artifact:  “Title” by Maker @handle                          │
│  Ship to:   John A, 123 Main St, City, ST 00000              │
│                                                                │
│  Subtotal:      $____                                         │
│  Fees/Tax:      $____                                         │
│  Total:         $____                                         │
│                                                                │
│  Ship window: Creator ships within 72h of payment.            │
│  Issues window: 48h after delivery to report issues.          │
│                                                                │
│  [ Pay $____ ]                                                │
└──────────────────────────────────────────────────────────────┘
```

- While paying: show blocking progress; retry on transient PSP errors; prevent double‑submit.

```
┌──────────────────────────────────────────────────────────────┐
│  Checkout                                                     │
│  ○ Address   ○ Payment   ○ Review   ● Done                    │
├──────────────────────────────────────────────────────────────┤
│  Payment successful                                           │
│  Order # CM‑2025‑000123                                       │
│  Next: Creator ships by <date> (72h). You’ll get tracking.    │
│  [ View order ]  [ Back to story ]                            │
└──────────────────────────────────────────────────────────────┘
```

## Error & Edge States

- Expired window: Disable checkout; banner on Story: “Payment window expired. The creator may accept the next highest offer.”
- PSP failure (hard): Surface specific reason when available; allow card change.
- Address invalid: block progress with clear inline guidance.

## Events (Analytics)

- checkout_viewed, checkout_address_submitted, checkout_payment_submitted, checkout_payment_succeeded, checkout_payment_failed
- order_created, order_viewed

## Resulting State

- On success: Order = Paid → Awaiting Shipment (ship‑by = payment_time + 72h)
- Buyer can view order; maker sees order in “To Ship”.
