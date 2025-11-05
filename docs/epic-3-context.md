# Epic 3 Context: Profile & Settings Management

**Generated:** 2025-11-04  
**Epic ID:** 3  
**Epic Title:** Profile & Settings Management  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Profile:** User data with avatar, bio, social links
- **Media:** S3 storage with CloudFront CDN, virus scanning
- **Privacy:** Granular controls with GDPR/CCPA compliance
- **Preferences:** Notification matrix with quiet hours
- **Security:** AWS KMS encryption, PII protection

### Technology Stack
- Flutter: cached_network_image 3.3.1, image_picker 1.0.4, crop_your_image 1.1.4
- Serverpod: Profile, privacy, notification, media endpoints
- Storage: AWS S3 + CloudFront, AWS KMS encryption
- Security: AWS Macie, Lambda virus scanning
- Email/Push: SendGrid API v3, Firebase Cloud Messaging

### Key Integration Points
- `packages/features/profile/` - Profile management UI
- `video_window_server/lib/src/endpoints/profile/` - Profile endpoints
- AWS S3: profile media storage
- PostgreSQL: user_profiles, privacy_settings, notification_preferences

### Implementation Patterns
- **Avatar Upload:** Presigned URLs → Upload → Virus scan → CloudFront
- **Privacy Controls:** Granular toggles with compliance audit
- **Notifications:** Multi-channel matrix with quiet hours
- **DSAR:** Automated data export/delete within 30 days

### Story Dependencies
1. **3.1:** Profile management (foundation)
2. **3.2:** Avatar/media upload (depends on 3.1)
3. **3.3:** Privacy settings (parallel with 3.2)
4. **3.4:** Notification preferences (depends on 3.3)
5. **3.5:** Account settings (depends on all)

### Success Criteria
- Users can manage profile with avatar and bio
- Media uploads complete in <30 seconds
- Privacy controls meet GDPR/CCPA requirements
- Notification preferences honored 100%

**Reference:** See `docs/tech-spec-epic-3.md` for full specification
