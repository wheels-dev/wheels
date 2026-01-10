# CLAUDE.md - Views Documentation Dispatcher

⚠️ **CRITICAL: This content has been moved to comprehensive documentation!**

## 🚨 MANDATORY: Before Working with Views

**BEFORE implementing ANY view code, you MUST read the complete documentation:**

### 📖 Required Reading (IN ORDER)
1. **`.ai/wheels/troubleshooting/common-errors.md`** - PREVENT FATAL ERRORS
2. **`.ai/wheels/views/data-handling.md`** - CRITICAL query vs array patterns
3. **`.ai/wheels/views/architecture.md`** - View structure and conventions
4. **`.ai/wheels/views/forms.md`** - Form helpers and limitations (CRITICAL)
5. **`.ai/wheels/views/layouts.md`** - Layout patterns and inheritance
6. **`.ai/wheels/views/best-practices.md`** - View implementation checklist

### 🔍 Quick Anti-Pattern Check
- [ ] ❌ **NO** ArrayLen() on queries: `ArrayLen(posts)`
- [ ] ❌ **NO** array loops on queries: `<cfloop array="#posts#">`
- [ ] ❌ **NO** emailField() or passwordField() (don't exist)
- [ ] ✅ **YES** use .recordCount: `posts.recordCount`
- [ ] ✅ **YES** query loops: `<cfloop query="posts">`
- [ ] ✅ **YES** textField() with type: `textField(type="email")`

## 📚 Complete Views Documentation

**All view documentation is now located in:** `.ai/wheels/views/`

The following files contain comprehensive view guidance:
- `data-handling.md` - Critical query vs array patterns
- `architecture.md` - View structure and file organization
- `layouts.md` - Layout patterns and inheritance
- `partials.md` - Partial usage and patterns
- `forms.md` - Form helpers and Wheels limitations
- `helpers.md` - View helpers and custom helpers
- `advanced-patterns.md` - AJAX, performance, caching
- `testing.md` - View testing patterns
- `best-practices.md` - Implementation checklist and patterns

🚨 **DO NOT use code from this file - read the complete documentation first!**

### ⚡ Critical Wheels View Patterns

**REMEMBER:** Wheels associations return QUERIES, not arrays:
```cfm
<!-- ✅ CORRECT -->
<cfif posts.recordCount gt 0>
    <cfloop query="posts">
        <h2>#posts.title#</h2>
    </cfloop>
</cfif>

<!-- ❌ WRONG -->
<cfif ArrayLen(posts) gt 0>
    <cfloop array="#posts#" index="post">
        <h2>#post.title#</h2>
    </cfloop>
</cfif>
```