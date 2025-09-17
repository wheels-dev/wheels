# CLAUDE.md - Controllers Documentation Dispatcher

⚠️ **CRITICAL: This content has been moved to comprehensive documentation!**

## 🚨 MANDATORY: Before Working with Controllers

**BEFORE implementing ANY controller code, you MUST read the complete documentation:**

### 📖 Required Reading (IN ORDER)
1. **`.ai/wheels/troubleshooting/common-errors.md`** - PREVENT FATAL ERRORS
2. **`.ai/wheels/controllers/architecture.md`** - Controller fundamentals and CRUD
3. **`.ai/wheels/controllers/rendering.md`** - View rendering and responses
4. **`.ai/wheels/controllers/filters.md`** - Authentication and authorization
5. **`.ai/wheels/controllers/model-interactions.md`** - Controller-model patterns
6. **`.ai/wheels/controllers/best-practices.md`** - Controller development guidelines

### 🔍 Quick Anti-Pattern Check
- [ ] ❌ **NO** mixed arguments: `renderText("error", status=404)`
- [ ] ❌ **NO** ArrayLen() on model results: `ArrayLen(users)`
- [ ] ✅ **YES** consistent arguments: ALL named OR ALL positional
- [ ] ✅ **YES** use .recordCount: `users.recordCount`
- [ ] ✅ **YES** plural naming: `UsersController.cfc`

## 📚 Complete Controllers Documentation

**All controller documentation is now located in:** `.ai/wheels/controllers/`

The following files contain comprehensive controller guidance:
- `architecture.md` - Controller structure and CRUD patterns
- `rendering.md` - View rendering, redirects, flash messages
- `filters.md` - Authentication, authorization, data loading
- `model-interactions.md` - Controller-model patterns, validation
- `api.md` - JSON/XML APIs, authentication, versioning
- `security.md` - CSRF, parameter verification, sanitization
- `testing.md` - Controller testing patterns and helpers

🚨 **DO NOT use code from this file - read the complete documentation first!**

## Quick Generator Reference

```bash
# Generate a new controller
wheels g controller Users index,show,new,create,edit,update,delete

# After generation, ALWAYS read .ai/wheels/controllers/ documentation
```