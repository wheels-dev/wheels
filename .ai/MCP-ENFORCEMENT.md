# 🚨 MCP Enforcement Guidelines

## Mandatory MCP Usage Check

**AI assistants MUST perform this check before ANY development work:**

```bash
# Check if MCP tools are mandatory
ls .mcp.json
```

**If `.mcp.json` exists → MCP tools are MANDATORY**

## 🚫 FORBIDDEN Commands (when .mcp.json exists)

```bash
# NEVER use these when MCP is available:
wheels g model
wheels g controller
wheels g migration
wheels g scaffold
wheels dbmigrate
wheels test
wheels server
curl http://localhost:*/?reload=true
```

## ✅ MANDATORY Commands (when .mcp.json exists)

```javascript
// ALWAYS use these instead:
mcp__wheels__wheels_generate(type="model", ...)
mcp__wheels__wheels_generate(type="controller", ...)
mcp__wheels__wheels_generate(type="migration", ...)
mcp__wheels__wheels_generate(type="scaffold", ...)
mcp__wheels__wheels_migrate(action="...")
mcp__wheels__wheels_test()
mcp__wheels__wheels_server(action="...")
mcp__wheels__wheels_reload()
```

## Enforcement Rules

1. **Check .mcp.json first** - always
2. **Use MCP tools exclusively** - if available
3. **Never mix CLI and MCP** - pick one based on availability
4. **Test MCP connection** - before starting work
5. **Follow MCP patterns** - as documented in CLAUDE.md

## Violation Detection

**If you catch yourself or another AI assistant doing ANY of the following:**
- Using `wheels g` commands when `.mcp.json` exists
- Using `wheels dbmigrate` when MCP is available
- Using `curl` for reload when `mcp__wheels__wheels_reload()` is available
- Mixing CLI and MCP approaches

**→ STOP immediately and switch to MCP tools**

## Benefits of MCP Tools

1. **Better Integration** - Direct integration with Wheels application
2. **Error Handling** - Improved error reporting and handling
3. **Consistency** - Standardized interface across all operations
4. **Validation** - Built-in validation and safety checks
5. **Documentation** - Access to real-time project documentation

---

**Remember: MCP tools provide a superior development experience when available. Always use them when `.mcp.json` exists.**