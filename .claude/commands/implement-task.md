# /implement-task - Implement a Specific Task

Implement a single task from the active specification with appropriate skill invocation, MCP tools, and immediate testing.

## Usage
```
/implement-task [task-number]
```

## Arguments
- `[task-number]`: Task number in format `X.Y` (e.g., `1.1`, `2.3`)

## Workflow

### Step 1: Load Active Spec and Task
```javascript
// Find active spec
Read("CLAUDE.md") // Get active spec from "Active Specifications" section

// Load tasks.md
Read(".claude/specs/[active-spec]/tasks.md")

// Parse to find task X.Y
```

### Step 2: Load Contextual Information
```javascript
// Load full spec for context
Read(".claude/specs/[active-spec]/spec.md")
Read(".claude/specs/[active-spec]/technical-spec.md")

// Load project patterns
Read("CLAUDE.md")
```

### Step 3: Mark Task as In Progress
```javascript
TodoWrite({
  todos: [{
    content: "[Task description]",
    activeForm: "[Task description in present continuous]",
    status: "in_progress"
  }]
});

// Also update tasks.md
Edit(".claude/specs/[active-spec]/tasks.md",
  old_string="- [ ] X.Y [description]",
  new_string="- [🔄] X.Y [description] (In Progress)"
)
```

### Step 4: Determine Component Type and Invoke Appropriate Skill
```javascript
// Based on task description, invoke the right skill:

if (task involves "model") {
  Skill("wheels-model-generator")
} else if (task involves "controller") {
  Skill("wheels-controller-generator")
} else if (task involves "view") {
  Skill("wheels-view-generator")
} else if (task involves "migration") {
  Skill("wheels-migration-generator")
} else if (task involves "test") {
  Skill("wheels-test-generator")
}
```

### Step 5: Implement Using MCP Tools
```javascript
// Always use MCP tools (never CLI)
mcp__wheels__generate(type="[type]", name="[name]", attributes="[attrs]")

// OR for migrations
mcp__wheels__migrate(action="latest")

// OR for tests
mcp__wheels__test(type="[type]")
```

### Step 6: Test Immediately
```javascript
// For models/controllers:
mcp__wheels__test(type="[component]")

// For views:
mcp__browsermcp__browser_navigate(url="http://localhost:PORT/[route]")
mcp__browsermcp__browser_screenshot()

// Verify HTTP 200 and content
Bash("curl -s http://localhost:PORT/[route] -I | grep '200 OK'")
Bash("curl -s http://localhost:PORT/[route] | grep '[expected-content]'")
```

### Step 7: Mark Task Complete (Only if Tests Pass)
```javascript
// Update TodoWrite
TodoWrite({
  todos: [{
    content: "[Task description]",
    activeForm: "[Task description in present continuous]",
    status: "completed"
  }]
});

// Update tasks.md with completion details
Edit(".claude/specs/[active-spec]/tasks.md",
  old_string="- [🔄] X.Y [description] (In Progress)",
  new_string="- [x] X.Y [description]\n\n**Completed**: [timestamp]\n**Session**: [session-id]\n**Commit**: [git-hash]\n**Files**: [list of files created/modified]"
)

// Commit
Bash("git add . && git commit -m 'Complete task X.Y: [description]

Task: [spec-name] / X.Y
Session: [session-id]
Files: [files]

[Brief description of what was implemented]'")
```

### Step 8: Update Progress Summary
```javascript
// Update tasks.md progress summary at top
Edit(".claude/specs/[active-spec]/tasks.md",
  old_string="- ⏸️ [Parent Task X] (Y/Z subtasks)",
  new_string="- 🔄 [Parent Task X] (Y+1/Z subtasks)"
)

// If parent task complete, update to ✅
if (all subtasks complete) {
  Edit(...status to "✅ [Parent Task X] (Z/Z subtasks)")
}
```

### Step 9: Suggest Next Task
```markdown
## ✅ Task X.Y Complete!

**What was done:**
- [Summary of implementation]

**Files created/modified:**
- [file1]
- [file2]

**Tests**: ✅ All passing

**Next task**: X.Y+1 - [description]

Would you like to continue with the next task?
```bash
/implement-task X.Y+1
```
```

## Anti-Pattern Prevention

During implementation, actively prevent common issues:

✅ **Models**: Use plural `properties` in validations
✅ **Associations**: Consistent argument style (all named)
✅ **Views**: Query loops with `recordCount`, not `ArrayLen()`
✅ **Views**: `structKeyExists()` for property access
✅ **Migrations**: CFML date functions, not database-specific SQL
✅ **Controllers**: Private filter methods
✅ **Forms**: Validation error displays

## Error Handling

**If tests fail:**
```markdown
## ⚠️ Task X.Y Tests Failed

**Error**: [error message]

**Analysis**:
[Invoke test-runner agent to analyze failure]

**Suggested Fix**:
[Specific fix from test-runner]

**Action**: Keeping task as in_progress until tests pass.

Shall I apply the suggested fix?
```

**If task not found:**
```
Error: Task X.Y not found in active specification.

Available tasks:
[List incomplete tasks from tasks.md]
```

**If no active spec:**
```
Error: No active specification found.

Run `/new-spec` to create a specification, or check CLAUDE.md for available specs.
```

## Example
```bash
/implement-task 1.1

# Loads task 1.1: "Write TestBox BDD specs for Post model"
# Invokes wheels-test-generator skill
# Creates tests/specs/models/Post.cfc
# Runs tests
# Marks complete
# Commits with structured message
# Suggests task 1.2
```

## Success Criteria

✅ Appropriate skill invoked before generation
✅ MCP tools used (never CLI)
✅ Code generated following anti-pattern prevention
✅ Tests run immediately after implementation
✅ Task only marked complete if tests pass
✅ tasks.md updated with completion details
✅ Git commit with structured message
✅ TodoWrite status updated
✅ Next task suggested
