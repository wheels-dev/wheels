# CLAUDE.md - Database Migrations Dispatcher

⚠️ **Documentation moved to .ai folder!**

## Database Migrations (`/app/migrator/`)

**For complete migrations documentation:**
- **See:** `.ai/wheels/database/migrations/` for comprehensive migration docs
- **Main Documentation:** `.ai/wheels/` root documentation

### Quick Reference
Database migrations handle schema changes:
- Table creation and modification
- Index management
- Data seeding (use direct SQL)

### Before Implementation
**ALWAYS read:** `.ai/wheels/troubleshooting/common-errors.md` first

### Critical Migration Patterns
- ✅ Use direct SQL for data seeding (not parameter binding)
- ✅ Wrap operations in transactions
- ✅ Implement both up() and down() methods

🚨 **Read complete .ai documentation before implementing migrations!**