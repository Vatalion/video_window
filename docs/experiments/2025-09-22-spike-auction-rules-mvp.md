# Spike: Auction Rules MVP

Date: 2025-09-22  
Owner: Eng Lead (TBD)  
Timebox: 3 days

## Questions
- Exact MVP rules: start/end conditions, fixed min increment (+1 USD), optional anti-snipe policy.
- Validation: currency handling, precision, rounding, and edge cases.

## Approach
- Draft rule spec → simulate a set of auctions/bids → document outcomes and edge cases.

## Deliverables
- Rule spec doc
- Simulation results and recommendations (go/no-go for anti-snipe in pilot)
 
## Pilot decisions noted
- Min increment: +1 USD (enforce server-side)
