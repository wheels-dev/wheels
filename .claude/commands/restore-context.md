# /restore-context - Restore Development Context

Restore full development context from documentation after session loss or when resuming work.

## Purpose

Rebuild complete understanding of project state, active specifications, current tasks, and recent work from persistent documentation (CLAUDE.md, tasks.md, git history).

## Workflow

### Step 1: Load Project Context
```javascript
// Read CLAUDE.md for project overview
Read("CLAUDE.md")

// Extract:
// - Active specifications
// - Recent decisions
// - Technical stack
// - Coding standards
```

### Step 2: Find Active Specifications
```javascript
// From CLAUDE.md "Active Specifications" section
Glob(pattern=".claude/specs/*/tasks.md")

// For each active spec, check status
Read(".claude/specs/[spec]/tasks.md")

// Identify:
// - Which spec is in-progress
// - Which task is currently being worked on (marked 🔄)
// - How many tasks completed vs total
```

### Step 3: Load Spec Details
```javascript
// For the in-progress spec
Read(".claude/specs/[spec]/spec.md")
Read(".claude/specs/[spec]/technical-spec.md")
Read(".claude/specs/[spec]/tasks.md")

// Parse task status:
// - ✅ Completed tasks with timestamps
// - 🔄 In-progress task
// - ⏸️ Pending tasks
```

### Step 4: Check Git Status
```bash
// Get current branch
git branch --show-current

// Get last commit
git log -1 --pretty=format:"%h - %s (%ar)"

// Check for uncommitted changes
git status --short

// Get recent commits on this branch
git log --oneline -5
```

### Step 5: Analyze Current State
```javascript
// From tasks.md session notes
// Last session timestamp
// Last task worked on
// Any blockers noted

// From git
// What was last committed
// What's uncommitted (work in progress)

// From file system
// Which files exist vs what spec describes
```

### Step 6: Present Comprehensive Status Report
```markdown
## 📍 Development Context Restored

### Project Overview
**Name**: [from CLAUDE.md]
**Stack**: [technical stack]
**Active Specs**: [count] in progress

---

### Current Location

**Specification**: [spec-name]
**Feature**: [feature name from spec.md]
**Progress**: [completed]/[total] tasks ([percentage]%)

**Current Task**: X.Y - [task description]
**Status**: [in_progress|blocked|ready]

---

### Recent History

**Last Session**: [timestamp from tasks.md]
**Last Completed Task**: X.Y - [description] ([time ago])
**Last Commit**: [git hash] - [message] ([time ago])

**Recent Work**:
1. ✅ Task X.Y - [description] ([timestamp])
2. ✅ Task X.Y-1 - [description] ([timestamp])
3. ✅ Task X.Y-2 - [description] ([timestamp])

---

### Working Files

**Uncommitted Changes**:
[Output from git status --short]

**Recently Modified**:
- [file1] ([time ago])
- [file2] ([time ago])

---

### Task Context

**Current Task Details** (from spec):
[Relevant excerpt from technical-spec.md for current task]

**What Needs to Be Done**:
[Parse current task to explain what's next]

**MCP Tools Required**:
- [list from tasks.md]

**Skills to Invoke**:
- [appropriate skill based on task type]

---

### Session Notes (from Last Session)
[Extract session notes from tasks.md]

**Decisions Made**:
[Any architectural decisions noted]

**Blockers** (if any):
[Any blockers mentioned]

---

### Suggested Actions

Based on the current state, here are your options:

**1. Continue Current Task**
```bash
/implement-task X.Y
```
[Will pick up where you left off]

**2. Review Uncommitted Changes**
```bash
git diff
```
[See what was in progress]

**3. Start Next Task**
```bash
/implement-task X.Y+1
```
[If current task is actually complete]

**4. Run Tests**
```bash
mcp__wheels__test(type="all")
```
[Verify everything still works]

---

### Context Successfully Restored ✅

I have full context of your project and can continue development.

**Ready to continue?** Just let me know which action you'd like to take!
```

## Recovery Scenarios

### Scenario 1: Session Lost Mid-Task
```markdown
**Context**: Task 2.3 marked as in_progress, uncommitted changes exist

**Status**: Work was in progress on controller generation

**Recovery**:
1. Review uncommitted changes to see progress
2. Continue implementation of task 2.3
3. Complete and test before marking done
```

### Scenario 2: Resuming After Break
```markdown
**Context**: Last session was 2 days ago, all tasks committed

**Status**: Task 3.1 is next pending task

**Recovery**:
1. Review what was completed in previous session
2. Read spec context for task 3.1
3. Begin implementation of task 3.1
```

### Scenario 3: Complete Context Loss
```markdown
**Context**: New machine, cloned repo, no session history

**Status**: Branch shows feature work, tasks.md shows progress

**Recovery**:
1. Restore from CLAUDE.md + tasks.md + git history
2. Full context rebuilt from documentation
3. Can continue exactly where left off
```

## Multi-Layer Context Sources

The system reconstructs context from multiple redundant sources:

**Layer 1**: CLAUDE.md (project overview, active specs)
**Layer 2**: tasks.md (task progress, session notes)
**Layer 3**: spec.md/technical-spec.md (feature details)
**Layer 4**: Git history (what was implemented, when)
**Layer 5**: File system (what actually exists)

Even if one layer is missing, others provide enough context to continue.

## Success Criteria

✅ Current specification identified
✅ Current task located
✅ Progress percentage calculated
✅ Git history reviewed
✅ Uncommitted changes identified
✅ Session notes loaded
✅ Next actions suggested
✅ Full context restored for continuation

## Example
```bash
/restore-context

# Output:
# 📍 Development Context Restored
# Specification: blog-posts-comments
# Progress: 7/15 tasks (47%)
# Current Task: 3.2 - Create posts/index.cfm view
# Last Session: 2 hours ago
# Ready to continue!
```

This command ensures you **never lose context**, even if Claude Code crashes or you resume work days later!
