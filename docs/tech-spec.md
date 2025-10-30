# Technical Specifications Index

**Status:** Updated 2025-10-30 - Reflects consolidated file structure and current validation status

## Foundational Epics (Infrastructure)
| Epic | Title | Document | Tech Spec | Stories | Validation Status |
|------|-------|----------|-----------|---------|-------------------|
| 01 | Environment & CI/CD Enablement | [tech-spec-epic-1.md](tech-spec-epic-1.md) | ✅ Complete | ✅ Story 01.1 | Ready for Validation |
| 02 | Core Platform Services | [tech-spec-epic-2.md](tech-spec-epic-2.md) | ✅ Complete | ❌ Missing | Blocked - No Stories |
| 03 | Observability & Compliance Baseline | [tech-spec-epic-3.md](tech-spec-epic-3.md) | ✅ Complete | ❌ Missing | Blocked - No Stories |

## Core Feature Epics (MVP Required)
| Epic | Title | Document | Tech Spec | Stories | Validation Status |
|------|-------|----------|-----------|---------|-------------------|
| 1 | Viewer Authentication & Session Handling | [tech-spec-epic-1.md](tech-spec-epic-1.md) | ✅ Complete | ✅ 4 Stories | Ready for Validation |
| 2 | Maker Authentication & Access Control | [tech-spec-epic-2.md](tech-spec-epic-2.md) | ✅ Complete | ✅ 4 Stories | Ready for Validation |
| 3 | Profile & Settings Management | [tech-spec-epic-3.md](tech-spec-epic-3.md) | ✅ Complete | ✅ 5 Stories | Ready for Validation |
| 4 | Feed Browsing Experience | [tech-spec-epic-4.md](tech-spec-epic-4.md) | ✅ Complete | ✅ 6 Stories | Ready for Validation |
| 5 | Story Detail Playback & Consumption | [tech-spec-epic-5.md](tech-spec-epic-5.md) | ✅ Complete | ✅ 3 Stories | Ready for Validation |
| 6 | Media Pipeline & Content Protection | [tech-spec-epic-6.md](tech-spec-epic-6.md) | ✅ Complete | ✅ 3 Stories | Ready for Validation |
| 7 | Maker Story Capture & Editing Tools | [tech-spec-epic-7.md](tech-spec-epic-7.md) | ✅ Complete | ✅ 3 Stories | Ready for Validation |
| 8 | Story Publishing & Moderation Pipeline | [tech-spec-epic-8.md](tech-spec-epic-8.md) | ✅ Complete | ❌ Missing | **CRITICAL** - No Stories |
| 9 | Offer Submission Flow | [tech-spec-epic-9.md](tech-spec-epic-9.md) | ✅ Complete | ✅ 4 Stories | Ready for Validation |
| 10 | Auction Timer & State Management | [tech-spec-epic-10.md](tech-spec-epic-10.md) | ✅ Complete | ✅ 4 Stories | Ready for Validation |
| 11 | Notifications & Activity Surfaces | [tech-spec-epic-11.md](tech-spec-epic-11.md) | ✅ Complete | ❌ Missing | Blocked - No Stories |
| 12 | Checkout & Payment Processing | [tech-spec-epic-12.md](tech-spec-epic-12.md) | ✅ Complete | ✅ 4 Stories | **TECHNICAL APPROVED** |
| 13 | Shipping & Tracking Management | [tech-spec-epic-13.md](tech-spec-epic-13.md) | ✅ Complete | ❌ Missing | **CRITICAL** - No Stories |

## Post-MVP Epics (Future Releases)
| Epic | Title | Document | Tech Spec | Stories | Validation Status |
|------|-------|----------|-----------|---------|-------------------|
| 14 | Issue Resolution & Customer Support | ❌ Missing | ❌ Missing | ❌ Missing | Blocked - No Tech Spec |
| 15 | Admin Moderation & Content Management | ❌ Missing | ❌ Missing | ❌ Missing | Blocked - No Tech Spec |
| 16 | Security & Compliance Framework | ❌ Missing | ❌ Missing | ❌ Missing | Blocked - No Tech Spec |
| 17 | Analytics & Reporting Dashboard | ❌ Missing | ❌ Missing | ❌ Missing | Blocked - No Tech Spec |

## 🚨 Critical MVP Gaps

**Epics 8 & 13 are CRITICAL for MVP but lack story files:**
- **Epic 8** (Story Publishing): Required for makers to publish content to the marketplace
- **Epic 13** (Shipping & Tracking): Required for order fulfillment and completion

**Resolution Required:** Create story files for these epics before development can begin.

## Usage Guidelines

- **Authoritative Index**: This document serves as the single source of truth for epic status and file locations
- **Validation Tracking**: See [epic-validation-backlog.md](process/epic-validation-backlog.md) for detailed validation status
- **Story Development**: All stories must exist before epic validation can begin
- **File Structure**: All tech spec files follow `tech-spec-epic-X.md` naming (non-padded numbers)
- **Cross-References**: Update this index when epic statuses change or new files are created

## Related Documentation

- **Stories**: [docs/stories/](stories/) - User stories aligned with these epics
- **Process**: [docs/process/](process/) - Epic validation and approval workflows  
- **Validation Reports**: [docs/validation-report-*.md](.) - Historical validation tracking
- **Architecture**: [docs/architecture/](architecture/) - Technical implementation guidance

---
**Last Updated:** 2025-10-30  
**Next Review:** Upon completion of Epic 8 & 13 story development
