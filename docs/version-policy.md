# Version Policy & Compatibility Matrix

**Effective Date:** 2025-10-09
**Review Date:** 2025-12-09
**Owner:** Development Team

## Version Authority

This document serves as the **single source of truth** for all version specifications across the Craft Video Marketplace project.

## Current Stable Versions

### Core Technology Stack
```yaml
Flutter: 3.19.6          # Current stable (verified 2025-10-09)
Dart: 3.5.6              # Bundled with Flutter 3.19.6
Serverpod: 2.9.3         # Latest stable, Dart 3.5+ compatible
```

### Development Tools
```yaml
Melos: 5.3.0             # Latest stable
Flutter CLI: Latest stable
Android Studio: Latest stable
VS Code: Latest stable with Flutter extension
```

### Platform Targets
```yaml
iOS: 14.0+               # Minimum iOS version
Android: API 21+         # Android 5.0+
Web: Chrome 94+          # Modern browser support
```

## Version Compatibility Matrix

| Component | Version | Minimum | Maximum | Notes |
|-----------|---------|---------|---------|-------|
| **Flutter** | 3.19.6 | 3.19.0 | 3.19.x | Current stable only |
| **Dart** | 3.5.6 | 3.5.0 | 3.5.x | Bundled with Flutter |
| **Serverpod** | 2.9.3 | 2.9.0 | 2.9.x | Dart 3.5+ required |
| **flutter_bloc** | 8.1.5 | 8.1.0 | 8.1.x | Flutter 3.19+ compatible |
| **go_router** | 12.1.3 | 12.0.0 | 12.1.x | Flutter 3.19+ compatible |
| **json_annotation** | 4.8.1 | 4.8.0 | 4.8.x | Dart 3.5+ compatible |

## Update Policy

### Major Updates
- **Frequency:** Every 6 months
- **Process:**
  1. Test compatibility in staging environment
  2. Update this policy first
  3. Update all project documentation
  4. Update dependency constraints
  5. Communicate to team

### Minor Updates
- **Frequency:** As needed
- **Process:** Update constraints and documentation together

### Security Updates
- **Frequency:** Immediately when available
- **Process:**
  1. Immediate security patches
  2. Update policy within 24 hours
  3. Full documentation sync within week

## Version History

| Date | Flutter | Dart | Serverpod | Notes |
|------|---------|------|-----------|-------|
| 2025-10-09 | 3.19.6 | 3.5.6 | 2.9.3 | **CORRECTED VERSION CRISIS** |
| 2025-09-27 | 3.35.1 | 3.8.5 | 2.9.x | **INVALID - Flutter 3.35.1 doesn't exist** |

## Validation Commands

### Verify Flutter Version
```bash
flutter --version
# Expected output: Flutter 3.19.6
```

### Verify Dart Version
```bash
dart --version
# Expected output: Dart 3.5.6
```

### Verify Package Compatibility
```bash
flutter pub deps
# Check for any version conflicts
```

## Emergency Version Rollback

If a version causes critical issues:

1. **Immediate Actions:**
   - Roll back to last known working version
   - Update this policy immediately
   - Communicate issue to team

2. **Investigation:**
   - Root cause analysis
   - Impact assessment
   - Fix development timeline

3. **Recovery:**
   - Test fix thoroughly
   - Update documentation
   - Gradual deployment

## Compliance Requirements

- All documentation must reference versions from this policy
- CI/CD pipelines must validate version compliance
- Development environment setup must use these versions
- Package dependency constraints must align with this policy

---

## Related Documents

- [Development Setup Guide](development.md)
- [Architecture Tech Stack](architecture/tech-stack.md)
- [CI/CD Pipeline Configuration](deployment/ci-cd.md)

---

**Next Review:** 2025-12-09 or after major Flutter release
**Approval Required:** Development Team Lead