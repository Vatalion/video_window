# Framework Documentation

This directory contains curated documentation from third-party frameworks used in the Video Window project. Documentation is versioned and contextualized for our specific implementation.

## Purpose

- **Single Source of Truth**: Developers shouldn't need to leave our documentation to understand framework usage
- **Version Specific**: Documentation matches the exact versions we use in production
- **Context Applied**: Generic framework docs are adapted with our specific patterns and conventions
- **Quick Reference**: Common tasks and troubleshooting without external searches

## Frameworks

### Serverpod (v2.9.x)
Location: `serverpod/`

**Status**: 🚧 In Progress (Target: Sprint 1 - Nov 8, 2025)

Curated documentation covering:
- Project setup and scaffolding
- Code generation workflows
- Database migrations and ORM
- Authentication patterns
- Deployment procedures

**Source**: https://docs.serverpod.dev/ (v2.9.x docs)

---

## Contributing

When adding framework documentation:

1. **Create version-specific directory**: `framework-name/v{major.minor}/`
2. **Include attribution**: Always cite original source with URL and date accessed
3. **Apply context**: Add "In Video Window" sections showing our specific usage
4. **Keep updated**: Review quarterly for framework version updates
5. **Link bidirectionally**: Reference from our architecture docs and vice versa

## Maintenance Schedule

| Framework | Current Version | Docs Last Updated | Next Review |
|-----------|----------------|-------------------|-------------|
| Serverpod | 2.9.1 | 2025-10-30 | 2025-11-08 |
| Flutter | 3.19.6 | Pending | TBD |

---

*Last Updated: 2025-10-30*
