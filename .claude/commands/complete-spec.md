# /complete-spec - Finalize Specification Implementation

Mark a specification as complete after comprehensive testing, generate results report, and update project documentation.

## Usage
```
/complete-spec [spec-name]
```

## Arguments
- `[spec-name]`: The feature name (without timestamp)

## Workflow

### Step 1: Verify All Tasks Complete
```javascript
// Load tasks.md
Read(".claude/specs/[timestamp]-[spec-name]/tasks.md")

// Check that ALL subtasks are marked [x]
// If any [ ] remain, warn user and abort
```

### Step 2: Run Comprehensive Test Suite
```javascript
// Run all TestBox tests
mcp__wheels__test(type="all", reporter="json")

// If tests fail, invoke test-runner agent
if (tests_failed) {
  Task(subagent_type="Explore",
    description="Analyze test failures",
    prompt="Use test-runner agent to analyze failures and suggest fixes")

  // Don't proceed until all tests pass
}
```

### Step 3: Browser Testing
```javascript
// Get server port
mcp__wheels__server(action="status")

// Test all key URLs
mcp__browsermcp__browser_navigate(url="http://localhost:PORT/")
mcp__browsermcp__browser_screenshot()

// Test CRUD operations
// Test forms
// Test responsive design
```

### Step 4: Calculate Implementation Metrics
```javascript
// Get start time from tasks.md YAML frontmatter
// Get end time: now
// Calculate actual time

// Count tasks completed
// Calculate estimated vs actual time variance

// Identify which tasks took longer/shorter than expected
```

### Step 5: Update Spec Status
```javascript
// Update spec.md
Edit(".claude/specs/[timestamp]-[spec-name]/spec.md",
  old_string="**Status:** in-progress",
  new_string="**Status:** completed\n**Completed:** [timestamp]"
)

Edit(...
  old_string="**Actual Time:** [to be filled]",
  new_string="**Actual Time:** [calculated] hours"
)

// Update tasks.md
Edit(".claude/specs/[timestamp]-[spec-name]/tasks.md",
  old_string="status: in-progress",
  new_string="status: completed"
)
```

### Step 6: Generate Results Report
```markdown
## ✅ [Feature Name] Implementation Complete!

### Implementation Summary

**Specification**: [feature-name]
**Started**: [timestamp]
**Completed**: [timestamp]
**Total Time**: [X] hours ([Y]% of estimate)

---

### What Was Built

**Database**:
- ✅ [table1] table with indexes
- ✅ [table2] table with foreign keys
- ✅ [X] sample records seeded

**Models** ([count] total):
- ✅ [Model1].cfc - [description]
  - Validations: [list]
  - Associations: [list]
  - Methods: [list]
- ✅ [Model2].cfc - [description]

**Controllers** ([count] total):
- ✅ [Controller1].cfc - [actions]
- ✅ [Controller2].cfc - [actions]

**Views** ([count] total):
- ✅ layout.cfm - [frontend stack]
- ✅ [resource]/index.cfm - [description]
- ✅ [resource]/show.cfm - [description]
- ✅ [resource]/new.cfm - [description]
- ✅ [resource]/edit.cfm - [description]

**Routes**:
- ✅ Root route configured
- ✅ RESTful resources added
- ✅ [Custom routes if any]

---

### Test Results

**TestBox BDD Specs**: ✅ All Passing
- Model specs: [X] tests, [X] passed
- Controller specs: [Y] tests, [Y] passed
- Integration specs: [Z] tests, [Z] passed

**Browser Tests**: ✅ All Verified
- ✅ http://localhost:[PORT]/ (200 OK, [X] records displayed)
- ✅ http://localhost:[PORT]/[resource]/[id] (200 OK, detail view working)
- ✅ http://localhost:[PORT]/[resource]/new (200 OK, form rendered)
- ✅ http://localhost:[PORT]/[resource]/[id]/edit (200 OK, pre-populated)

**Frontend Stack**: ✅ Verified
- ✅ [CSS framework] loaded and styled
- ✅ [JS framework] interactive elements working
- ✅ Responsive design working (mobile, tablet, desktop)

**Test Coverage**: [percentage]% ([meets/exceeds] 90% minimum)

---

### Implementation Metrics

**Task Completion**:
- Parent tasks: [X]/[X] (100%)
- Subtasks: [Y]/[Y] (100%)

**Time Analysis**:
- Estimated: [X] hours
- Actual: [Y] hours
- Variance: [+/-Z]% ([reason for variance])

**Breakdown by Phase**:
- Database & Models: [X] hours ([estimated] vs [actual])
- Controllers: [Y] hours
- Views: [Z] hours (typically longest phase ✓)
- Testing: [W] hours

**Learning for Future Estimates**:
- [Component type] consistently took [X]% longer than estimated
- [Component type] was faster than expected
- [Special consideration for next similar feature]

---

### Files Created

**Models**: [count] files
- [file path with link]

**Controllers**: [count] files
- [file path with link]

**Views**: [count] files
- [file path with link]

**Migrations**: [count] files
- [file path with link]

**Tests**: [count] files
- [file path with link]

**Total**: [count] new files, [count] modified files

---

### What You Can Do Now

1. **Use the feature**:
   Visit http://localhost:[PORT] to see your new [feature]

2. **Run the full application**:
   ```bash
   box server start
   ```

3. **Run tests anytime**:
   ```bash
   mcp__wheels__test(type="all")
   ```

4. **Build another feature**:
   ```bash
   /new-spec
   ```

5. **Deploy to production**:
   [Instructions if applicable]

---

### Specification Reference

**Full details**: [.claude/specs/[timestamp]-[spec-name]/spec.md](.claude/specs/[timestamp]-[spec-name]/spec.md)

**Task breakdown**: [.claude/specs/[timestamp]-[spec-name]/tasks.md](.claude/specs/[timestamp]-[spec-name]/tasks.md)

**Git history**:
```bash
git log --oneline --grep="[spec-name]"
```

---

### Next Steps

Your project now has [feature description]. To build on this:

**Immediate enhancements**:
- [Suggested next feature related to this one]

**Future possibilities**:
- [Feature from "Future Enhancements" section of spec]

**Start next feature**:
```bash
/new-spec
```
```

### Step 7: Update CLAUDE.md
```javascript
// Move spec from "Active" to "Completed"
Edit("CLAUDE.md",
  old_string="#### Active Specifications\n- **[spec-name]**...",
  new_string="#### Active Specifications\n*(No active specifications - ready for next feature!)*"
)

Edit("CLAUDE.md",
  old_string="#### Completed Specifications\n- None yet",
  new_string="#### Completed Specifications\n- **[spec-name]** ([timestamp]) - [feature description] - [X] hours"
)

// Add any new architectural decisions to "Recent Decisions"
Edit("CLAUDE.md",
  append to Recent Decisions section with learnings from this implementation
)
```

### Step 8: Create Final Commit
```bash
git add .claude/specs/[timestamp]-[spec-name]/
git add CLAUDE.md
git commit -m "Complete [feature-name] specification

Feature: [description]
Tasks completed: [X]/[X]
Time: [actual] hours ([estimated] hours estimated)
Test coverage: [X]%

All tests passing, browser verified, production ready.

Closes: [spec-name]"
```

### Step 9: Offer Next Actions
```markdown
## 🎉 Congratulations!

[Feature name] is complete and production-ready!

**What would you like to do next?**

1. **Start another feature**: `/new-spec`
2. **Review the code**: Open files in editor
3. **Deploy to production**: [deployment instructions]
4. **Take a break**: You've earned it! 🎉
```

## Quality Gates

Before marking complete, verify:

✅ All tasks in tasks.md marked [x]
✅ All TestBox tests passing (models, controllers, integration)
✅ Test coverage >= 90%
✅ All browser tests pass (HTTP 200 + content verification)
✅ Responsive design works
✅ No uncommitted changes (or commit them)
✅ No anti-patterns detected
✅ Security checks pass (CSRF, validation, etc.)

If any gate fails, abort and explain what needs to be fixed.

## Error Handling

**If tasks incomplete:**
```
Error: Cannot complete specification - tasks still pending.

Remaining tasks:
- [ ] 3.4 - [description]
- [ ] 4.2 - [description]

Complete all tasks before running /complete-spec.
```

**If tests failing:**
```
Error: Cannot complete specification - tests failing.

Failed tests:
- Model: Post - validation test
- Controller: Posts - create action test

Fix failing tests before marking complete.

Run `/implement-task test-fixes` or invoke test-runner agent.
```

## Success Criteria

✅ All tasks verified complete
✅ All tests passing
✅ Browser verification complete
✅ Metrics calculated and reported
✅ Spec status updated to "completed"
✅ CLAUDE.md updated
✅ Final commit created
✅ Comprehensive results report generated
✅ User given clear next steps

## Example
```bash
/complete-spec blog-posts-comments

# Verifies all 15 tasks complete
# Runs test suite (all pass)
# Browser tests (all verified)
# Calculates: 22 minutes actual vs 20-30 estimated
# Generates comprehensive report
# Updates CLAUDE.md
# Commits final changes
# Celebrates completion! 🎉
```
