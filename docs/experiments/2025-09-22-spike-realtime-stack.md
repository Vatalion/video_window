# Spike: Realtime Stack for Auctions (Flutter)

Date: 2025-09-22  
Owner: Eng Lead (TBD)  
Timebox: 3 days

## Questions
- WebSockets MVP feasibility across Android/iOS/Web; fallback polling cadence.
- Compare with managed alternatives (e.g., Firebase, Pusher) for N+1.

## Approach
- Prototype WS channel per auction; measure latency, reliability; implement polling fallback.

## Deliverables
- Prototype code and metrics
- Recommendation for pilot and N+1
 
## Pilot decisions noted
- MVP uses WebSockets with polling fallback; evaluate managed options (Firebase/Pusher) for N+1.
