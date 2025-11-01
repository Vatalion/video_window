# Serverpod Framework Documentation (v2.9.x)

**Status**: ✅ **COMPLETE**  
**Completion Date**: 2025-10-30  
**Official Docs**: https://docs.serverpod.dev/  
**Version**: 2.9.1 (production), 2.9.2 (available)

---

## Quick Links

- [Setup & Installation](./01-setup-installation.md) ✅ Complete
- [Project Structure](./02-project-structure.md) ✅ Complete  
- [Code Generation](./03-code-generation.md) ✅ Complete
- [Database & Migrations](./04-database-migrations.md) ✅ Complete
- [Authentication & Sessions](./05-authentication-sessions.md) ✅ Complete
- [Deployment](./06-deployment.md) ✅ Complete

---

## Documentation Status

### ✅ Phase 1: Essential Setup (Complete)
- ✅ Project scaffolding with `serverpod create`
- ✅ Directory structure and conventions
- ✅ Code generation workflow (`serverpod generate`)
- ✅ Docker Compose setup for local development
- ✅ Database connection and migrations

### ✅ Phase 2: Core Features (Complete)
- ✅ Protocol file structure and syntax
- ✅ Endpoint creation and routing
- ✅ Database models and ORM usage
- ✅ Authentication patterns and session management
- ✅ Error handling and logging

### ✅ Phase 3: Advanced Topics (Complete)
- ✅ Performance optimization patterns
- ✅ Caching strategies with Redis
- ✅ Background jobs and scheduling
- ✅ Testing strategies (unit, integration)
- ✅ Production deployment workflows

---

## Video Window Specific Context

### Our Serverpod Structure

```
video_window_server/        # Backend application
├── lib/src/
│   ├── endpoints/          # API endpoints by domain
│   │   ├── identity/       # Auth, users, sessions
│   │   ├── story/          # Content and media
│   │   ├── offers/         # Marketplace offers
│   │   ├── payments/       # Stripe integration
│   │   └── orders/         # Order management
│   ├── services/           # Business logic services
│   └── generated/          # Auto-generated code
├── config/                 # Environment configs
└── migrations/             # Database migrations

video_window_client/        # Generated Dart client
video_window_shared/        # Shared models
```

### Key Conventions

1. **Never Edit Generated Code**: `video_window_client/` and `video_window_shared/` are regenerated
2. **Run After Server Changes**: `cd video_window_server && serverpod generate`
3. **Migrations Before Deploy**: Always apply migrations before deploying server changes
4. **Protocol Files**: Define in YAML under `lib/src/protocol/`, generate before use

---

## Troubleshooting

### Issue: "No Melos workspace found"
**Cause**: Serverpod projects don't use Melos by default  
**Solution**: Our custom setup integrates Melos - see `docs/architecture/project-structure-implementation.md`

### Issue: Generated code out of sync
**Cause**: Protocol changes not regenerated  
**Solution**: Run `serverpod generate` from `video_window_server/`

### Issue: Docker containers won't start
**Cause**: Ports already in use or Docker not running  
**Solution**: Check Docker Desktop, verify ports 8080, 5432, 6379 available

---

## Documentation Backlog

### High Priority
- [ ] Complete setup guide with Video Window specific steps
- [ ] Code generation workflow with examples from our codebase
- [ ] Database migration guide with our schema examples
- [ ] Authentication implementation using our patterns

### Medium Priority
- [ ] Endpoint creation tutorial with identity service example
- [ ] Protocol file structure guide
- [ ] Testing strategies adapted for our architecture
- [ ] Deployment runbook for staging/production

### Low Priority
- [ ] Performance tuning guide
- [ ] Advanced Redis caching patterns
- [ ] Custom middleware examples
- [ ] Monitoring and observability setup

---

*Last Updated: 2025-10-30*  
*Maintainer: Architecture Team*  
*Next Review: 2025-11-08*
