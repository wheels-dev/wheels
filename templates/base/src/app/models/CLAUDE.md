# CLAUDE.md - Models Documentation Dispatcher

⚠️ **CRITICAL: This content has been moved to comprehensive documentation!**

## 🚨 MANDATORY: Before Working with Models

**BEFORE implementing ANY model code, you MUST read the complete documentation:**

### 📖 Required Reading (IN ORDER)
1. **`.ai/wheels/troubleshooting/common-errors.md`** - PREVENT FATAL ERRORS
2. **`.ai/wheels/models/data-handling.md`** - Critical query vs array patterns
3. **`.ai/wheels/models/architecture.md`** - Model fundamentals and structure
4. **`.ai/wheels/models/associations.md`** - Relationship patterns (CRITICAL)
5. **`.ai/wheels/models/validations.md`** - Validation methods and patterns
6. **`.ai/wheels/models/best-practices.md`** - Model development guidelines

### 🔍 Quick Anti-Pattern Check
- [ ] ❌ **NO** mixed arguments: `hasMany("comments", dependent="delete")`
- [ ] ❌ **NO** ArrayLen() on associations: `ArrayLen(user.posts())`
- [ ] ✅ **YES** consistent arguments: `hasMany(name="comments", dependent="delete")`
- [ ] ✅ **YES** use .recordCount: `user.posts().recordCount`

## 📚 Complete Models Documentation

**All model documentation is now located in:** `.ai/wheels/models/`

The following files contain comprehensive model guidance:
- `architecture.md` - Model structure and fundamentals
- `associations.md` - Relationships and foreign keys
- `validations.md` - Validation rules and methods
- `callbacks.md` - Lifecycle hooks and events
- `methods-reference.md` - Complete method documentation
- `advanced-patterns.md` - Complex model examples
- `user-authentication.md` - Authentication model patterns
- `testing.md` - Model testing strategies
- `performance.md` - Query optimization
- `best-practices.md` - Development guidelines
- `advanced-features.md` - Timestamps and dirty tracking

🚨 **DO NOT use code from this file - read the complete documentation first!**

## Quick Generator Reference

```bash
# Generate a new model
wheels g model User name:string,email:string,active:boolean

# After generation, ALWAYS read .ai/wheels/models/ documentation
```