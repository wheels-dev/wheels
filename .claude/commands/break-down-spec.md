# /break-down-spec - Break Down Specification into Tasks

Break down an approved specification into granular, testable tasks using the task-analyzer sub-agent.

## Usage
```
/break-down-spec [spec-name]
```

## Arguments
- `[spec-name]`: The feature name (without timestamp or path)

## Workflow

### Step 1: Load Specification
```javascript
// Find the spec directory
Glob(pattern=".claude/specs/*-[spec-name]")

// Read both specification files
Read(".claude/specs/[timestamp]-[spec-name]/spec.md")
Read(".claude/specs/[timestamp]-[spec-name]/technical-spec.md")
```

### Step 2: Load Project Context
```javascript
// Read CLAUDE.md for project patterns and conventions
Read("CLAUDE.md")
```

### Step 3: Invoke Task Analyzer
```javascript
Task(
  subagent_type="Explore",
  description="Analyze spec and create task breakdown",
  prompt="Use the task-analyzer agent to analyze this specification and create an optimal task breakdown.

  Specification content:
  [Include full spec.md and technical-spec.md content]

  Follow the task-analyzer's principles:
  - 3-5 parent tasks
  - 3-8 subtasks per parent
  - TDD structure (tests first, tests last)
  - Dependency order
  - Include ALL views (critical)

  Return structured JSON with task breakdown."
)
```

### Step 4: Generate tasks.md
Create tasks.md in the spec directory with YAML frontmatter and hierarchical structure:

```markdown
---
spec: [spec-name]
created: [timestamp]
status: ready
branch: feature/[spec-name]
session_id: [spec-name]-impl
last_updated: [timestamp]
---

# Tasks: [Feature Name]

> Specification: @.claude/specs/[timestamp]-[spec-name]/spec.md
> Status: Ready to implement
> Branch: feature/[spec-name]
> Session: [spec-name]-impl

## Progress Summary
- ⏸️ [Parent Task 1] (0/X subtasks)
- ⏸️ [Parent Task 2] (0/Y subtasks)
- ⏸️ [Parent Task 3] (0/Z subtasks)
...

## Parent Tasks

### ⏸️ 1. [Parent Task Name]
- [ ] 1.1 [Subtask description]
- [ ] 1.2 [Subtask description]
...

**Status**: Not started
**Complexity**: [small|medium|large]
**Estimated Time**: [hours]
**MCP Tools**: [list of mcp tools needed]
**Wheels Components**: [model|controller|view|migration]

### ⏸️ 2. [Next Parent Task]
...

## Session Notes
[Empty - will be filled during implementation]

## Technical Context
**Wheels Components**:
- Models: [list]
- Controllers: [list]
- Views: [list]
- Migrations: [list]

**MCP Tools Required**:
- mcp__wheels__generate
- mcp__wheels__migrate
- mcp__wheels__test
- mcp__browsermcp__browser_navigate

**Key Anti-Patterns to Prevent**:
- Use plural properties in validations
- Consistent argument styles in associations
- Query loops (not array loops) in views
- structKeyExists() for property access
- CFML date functions in migrations
```

### Step 5: Create Feature Branch
```bash
git checkout -b feature/[spec-name]
git add .claude/specs/[timestamp]-[spec-name]/
git commit -m "Add specification and task breakdown for [feature-name]"
```

### Step 6: Update CLAUDE.md
```javascript
Edit("CLAUDE.md",
  old_string="- None yet - use `/new-spec` to create your first feature specification",
  new_string="- **[spec-name]** (.claude/specs/[timestamp]-[spec-name]/) - Ready to implement"
)
```

### Step 7: Present Task Breakdown
```markdown
## 📝 Task Breakdown Complete

**Specification**: [Feature Name]
**Total Tasks**: [X parent tasks, Y total subtasks]
**Estimated Time**: [hours]
**Branch**: feature/[spec-name]

### Task Structure:

**1. [Parent Task 1]** ([complexity], [time])
   - 1.1 [Subtask]
   - 1.2 [Subtask]
   - ...

**2. [Parent Task 2]** ([complexity], [time])
   - 2.1 [Subtask]
   - 2.2 [Subtask]
   - ...

**3. [Parent Task 3]** ([complexity], [time])
   - 3.1 [Subtask]
   - 3.2 [Subtask]
   - ...

### Implementation Notes:
- Tasks ordered by dependency (1 → 2 → 3...)
- Tests written first and verified last for each component
- MCP tools will be used for all generation
- Browser testing after view creation

### Ready to Start!

To begin implementation:
```bash
/implement-task 1.1
```

Or for comprehensive automated implementation:
```bash
/wheels_execute implement from spec [spec-name]
```
```

## Success Criteria

✅ tasks.md created with complete task breakdown
✅ YAML frontmatter includes all metadata
✅ 3-5 parent tasks with 3-8 subtasks each
✅ TDD structure applied (tests first, tests last)
✅ All views included (critical!)
✅ Feature branch created
✅ CLAUDE.md updated with active spec
✅ User presented with clear task structure

## Error Handling

**If spec not found:**
```
Error: Specification '[spec-name]' not found.

Available specifications:
- [list from .claude/specs/]

Please check the name and try again.
```

**If spec not approved:**
```
Error: Specification '[spec-name]' status is '[status]', not 'approved'.

Only approved specifications can be broken down into tasks.

Run `/new-spec` to create and approve a specification first.
```

## Example
```bash
/break-down-spec blog-posts-comments
```

Creates:
- `.claude/specs/20251021-190000-blog-posts-comments/tasks.md`
- Feature branch: `feature/blog-posts-comments`
- Updates CLAUDE.md active specifications
- Presents task breakdown for review
