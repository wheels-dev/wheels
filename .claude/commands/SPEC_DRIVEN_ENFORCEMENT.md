# 🚨 SPEC-DRIVEN WORKFLOW ENFORCEMENT RULES

## CRITICAL: This document contains MANDATORY enforcement rules for /wheels_execute

**These rules MUST be followed. They are not optional. Violations will result in incomplete or incorrect implementations.**

---

## 🔒 Phase 3.5: MANDATORY Spec File Creation (NEW - ENFORCED)

**This phase is INSERTED between Phase 3 (User Approval) and Phase 4 (TodoWrite).**

### What Happens After User Approval

When the user approves via ExitPlanMode, you MUST immediately execute these steps IN ORDER:

#### ✅ Step 1: Create .specs/ Directory
```bash
mkdir -p .specs
```

**Validation:** Verify directory exists before proceeding.

#### ✅ Step 2: Generate Timestamped Filename
```javascript
// Format: YYYYMMDD-HHMMSS-feature-description.md
var timestamp = DateFormat(Now(), "yyyymmdd") + "-" + TimeFormat(Now(), "HHnnss")
var featureName = sanitizeFeatureName(userRequest)  // e.g., "blog-posts-comments"
var filename = timestamp + "-" + featureName + ".md"

// Example: 20250930-215203-blog-posts-comments.md
```

**Validation:** Verify filename follows format before proceeding.

#### ✅ Step 3: Write Complete Specification to File
```javascript
Write(".specs/" + filename, fullSpecificationContent)
```

**The specification MUST include ALL of these sections:**
- Feature title
- Metadata (Created, Status, Estimated Time, Actual Time)
- User Request (verbatim)
- Previous Specs (references to prior specs, or "None")
- This Spec Builds On (existing components)
- Components to Add (new files)
- Components to Modify (existing files to change)
- Database Schema (complete table structures)
- Models (associations, validations, methods, callbacks)
- Controllers (actions, filters, parameter verification)
- Views (all views with descriptions)
- Routes (route configuration)
- Frontend Stack (CSS/JS libraries)
- Sample Data (if applicable)
- Implementation Progress (placeholder, to be updated)
- Files Created (placeholder, to be updated)
- Test Results (placeholder, to be updated)

**Validation:** Verify file exists and contains all sections before proceeding.

#### ✅ Step 4: Create/Update current.md Symlink
```bash
cd .specs
ln -sf ${filename} current.md
cd ..
```

**Validation:** Verify symlink exists and points to correct file before proceeding.

#### ✅ Step 5: Update Spec Status to "in-progress"
```javascript
Edit(".specs/" + filename,
  old_string: "**Status:** approved",
  new_string: "**Status:** in-progress\n**Started:** " + Now()
)
```

**Validation:** Read spec file and verify status is "in-progress" before proceeding.

#### ✅ Step 6: Record Start Timestamp
Extract and store the "Started:" timestamp for later time calculation.

**Validation:** Verify timestamp is recorded before proceeding.

---

## 🛑 PRE-IMPLEMENTATION VALIDATION CHECKPOINT

**BEFORE starting TodoWrite or any implementation, you MUST run this validation:**

```javascript
function validateSpecDrivenWorkflowCompleted() {
    // Check 1: .specs/ directory exists
    var specsDir = Bash("test -d .specs && echo 'exists' || echo 'missing'")
    if (specsDir.includes("missing")) {
        throw "WORKFLOW VIOLATION: .specs/ directory does not exist. Cannot proceed."
    }

    // Check 2: At least one spec file exists
    var specFiles = Glob(pattern=".specs/*.md")
    if (specFiles.length === 0) {
        throw "WORKFLOW VIOLATION: No spec files found in .specs/. Cannot proceed."
    }

    // Check 3: current.md symlink exists
    var currentExists = Bash("test -L .specs/current.md && echo 'exists' || echo 'missing'")
    if (currentExists.includes("missing")) {
        throw "WORKFLOW VIOLATION: .specs/current.md symlink missing. Cannot proceed."
    }

    // Check 4: current.md is readable
    try {
        var spec = Read(".specs/current.md")
    } catch (e) {
        throw "WORKFLOW VIOLATION: Cannot read .specs/current.md. Cannot proceed."
    }

    // Check 5: Spec has required sections
    var requiredSections = [
        "# Feature Specification:",
        "**Status:**",
        "## User Request",
        "## Database Schema",
        "## Models",
        "## Controllers",
        "## Views",
        "## Routes"
    ]

    for (var section of requiredSections) {
        if (!spec.includes(section)) {
            throw "WORKFLOW VIOLATION: Spec missing required section: " + section
        }
    }

    // Check 6: Spec status is "in-progress"
    if (!spec.includes("**Status:** in-progress")) {
        throw "WORKFLOW VIOLATION: Spec status must be 'in-progress'. Current status: " + extractStatus(spec)
    }

    // Check 7: Start timestamp exists
    if (!spec.includes("**Started:**")) {
        throw "WORKFLOW VIOLATION: Spec missing start timestamp. Cannot track time."
    }

    return true
}
```

**YOU MUST run this validation function before starting TodoWrite.**

If ANY check fails, STOP immediately and fix the issue before proceeding.

---

## 📝 MANDATORY Pre-Implementation Checklist

Before calling TodoWrite, you MUST verify ALL items:

- [ ] `.specs/` directory exists
- [ ] Spec file written: `.specs/YYYYMMDD-HHMMSS-feature-name.md`
- [ ] `current.md` symlink created and points to latest spec
- [ ] Spec contains "# Feature Specification:" header
- [ ] Spec contains "**Status:** in-progress"
- [ ] Spec contains "**Started:**" timestamp
- [ ] Spec contains "## User Request" section
- [ ] Spec contains "## Database Schema" section
- [ ] Spec contains "## Models" section
- [ ] Spec contains "## Controllers" section
- [ ] Spec contains "## Views" section
- [ ] Spec contains "## Routes" section
- [ ] Spec can be read via `Read(".specs/current.md")`

**IF ANY ITEM IS UNCHECKED, YOU MUST NOT PROCEED WITH IMPLEMENTATION.**

**GO BACK AND CREATE THE SPEC FILE FIRST.**

---

## 🎯 POST-IMPLEMENTATION FINALIZATION (MANDATORY)

**After all tasks are completed, you MUST finalize the spec:**

### Step 1: Calculate Actual Implementation Time
```javascript
// Read spec to get start time
var spec = Read(".specs/current.md")

// Extract timestamps
var startTime = extractTimestamp(spec, "**Started:**")
var endTime = Now()

// Calculate duration in minutes
var actualMinutes = DateDiff("n", startTime, endTime)
```

### Step 2: Update Spec Status to "completed"
```javascript
Edit(".specs/current.md",
  old_string: "**Status:** in-progress",
  new_string: "**Status:** completed\n**Completed:** " + DateFormat(Now(), "yyyy-mm-dd HH:nn:ss")
)
```

### Step 3: Fill in Actual Implementation Time
```javascript
Edit(".specs/current.md",
  old_string: "**Actual Time:** [to be filled upon completion]",
  new_string: "**Actual Time:** " + actualMinutes + " minutes"
)
```

### Step 4: Update Implementation Progress Section
```javascript
Edit(".specs/current.md",
  old_string: "## Implementation Progress\n\n[To be filled]",
  new_string: "## Implementation Progress\n\n" +
              "**Models:** ✅ Complete\n" +
              "**Controllers:** ✅ Complete\n" +
              "**Views:** ✅ Complete\n" +
              "**Routes:** ✅ Complete\n" +
              "**Tests:** ✅ Complete"
)
```

### Step 5: Add Test Results Summary
```javascript
var testSummary = "## Test Results\n\n" +
                  "**All Tests Passed:** ✅\n" +
                  "**Browser Tests:** ✅ All pages verified\n" +
                  "**HTTP Status Checks:** ✅ All 200 OK\n" +
                  "**Content Verification:** ✅ Expected content displays\n" +
                  "**Frontend Stack:** ✅ Tailwind/Alpine/HTMX loaded\n" +
                  "**Interactive Elements:** ✅ Alpine.js directives working\n" +
                  "**Responsive Design:** ✅ Mobile/tablet/desktop tested"

Edit(".specs/current.md",
  old_string: "## Test Results\n\n[To be filled]",
  new_string: testSummary
)
```

### Step 6: Add Files Created List
```javascript
var filesList = "## Files Created\n\n" +
                "**Models:**\n" +
                "- [Post.cfc](app/models/Post.cfc)\n" +
                "- [Comment.cfc](app/models/Comment.cfc)\n\n" +
                "**Controllers:**\n" +
                "- [Posts.cfc](app/controllers/Posts.cfc)\n" +
                "- [Comments.cfc](app/controllers/Comments.cfc)\n\n" +
                "**Views:**\n" +
                "- [layout.cfm](app/views/layout.cfm)\n" +
                "- [posts/index.cfm](app/views/posts/index.cfm)\n" +
                "- [posts/show.cfm](app/views/posts/show.cfm)\n" +
                "- [posts/new.cfm](app/views/posts/new.cfm)\n" +
                "- [posts/edit.cfm](app/views/posts/edit.cfm)\n\n" +
                "**Migrations:**\n" +
                "- 3 migration files in app/migrator/migrations/\n\n" +
                "**Routes:**\n" +
                "- [config/routes.cfm](config/routes.cfm) (updated)"

Edit(".specs/current.md",
  old_string: "## Files Created\n\n[To be filled]",
  new_string: filesList
)
```

---

## ⚠️ WHAT HAPPENS IF YOU SKIP THESE STEPS

If you skip spec file creation:
- ❌ No audit trail of what was built
- ❌ Future features won't know what exists
- ❌ No context for incremental development
- ❌ No documentation for team members
- ❌ Cannot track implementation time
- ❌ Workflow violations

**THIS IS UNACCEPTABLE.**

---

## ✅ CORRECT WORKFLOW SEQUENCE

```
Phase 0: MCP Detection & Documentation Loading
         ↓
Phase 1: Requirements Analysis (load previous specs from .specs/)
         ↓
Phase 2: Specification Generation (create spec in memory)
         ↓
Phase 3: User Approval Checkpoint (ExitPlanMode)
         ↓
    [USER APPROVES]
         ↓
Phase 3.5: MANDATORY Spec File Creation ⬅️ NEW ENFORCEMENT POINT
         ├─ Create .specs/ directory
         ├─ Generate timestamped filename
         ├─ Write spec to file
         ├─ Create current.md symlink
         ├─ Update status to "in-progress"
         └─ Record start timestamp
         ↓
    [VALIDATION CHECKPOINT] ⬅️ BLOCKS PROGRESS IF SPEC MISSING
         ↓
Phase 4: Task List Creation with TodoWrite
         ↓
Phase 5: Incremental Implementation
         ↓
Phase 6: Task Completion Tracking
         ↓
Phase 7: Final Verification
         ↓
Phase 8: Results Report & Spec Finalization ⬅️ MANDATORY UPDATES
         ├─ Calculate actual time
         ├─ Update status to "completed"
         ├─ Fill in actual time
         ├─ Update implementation progress
         ├─ Add test results
         └─ Add files created list
         ↓
    [DONE - Spec saved and finalized]
```

---

## 🎯 SUMMARY: WHAT CHANGED

**Before (what I did wrong):**
```
ExitPlanMode → User approves → TodoWrite → Implementation
```

**After (correct workflow with enforcement):**
```
ExitPlanMode → User approves → CREATE SPEC FILE → VALIDATE SPEC → TodoWrite → Implementation → FINALIZE SPEC
```

**The spec file creation and validation are now MANDATORY checkpoints that cannot be skipped.**

---

## 📋 ENFORCEMENT CHECKLIST FOR AI ASSISTANT

Before starting any `/wheels_execute` task, verify:

1. ✅ I have read this SPEC_DRIVEN_ENFORCEMENT.md file
2. ✅ I understand that spec file creation is MANDATORY
3. ✅ I understand that validation checkpoints BLOCK implementation
4. ✅ I understand that spec finalization is MANDATORY
5. ✅ I will NOT skip Phase 3.5 under any circumstances
6. ✅ I will NOT proceed to TodoWrite without validation
7. ✅ I will NOT consider implementation complete without finalizing spec

**IF ANY ITEM IS UNCHECKED, RE-READ THIS DOCUMENT.**

---

## 🔧 INTEGRATION WITH EXISTING WORKFLOW

This document SUPPLEMENTS the main `/wheels_execute` command documentation.

**When there is a conflict between documents:**
- This enforcement document takes precedence for spec file management
- The main workflow document takes precedence for implementation details

**Both documents must be followed.**

---

## 📖 EXAMPLE: CORRECT WORKFLOW EXECUTION

```javascript
// User runs: /wheels_execute create a blog with posts and comments

// Phase 0-3: Analysis, spec generation, approval (as documented)
ExitPlanMode(plan="[complete specification]")

// User responds: "approve"

// ⬇️ Phase 3.5: MANDATORY Spec File Creation (NEW)
Bash("mkdir -p .specs")
var timestamp = "20250930-215203"
var filename = timestamp + "-blog-posts-comments.md"
Write(".specs/" + filename, fullSpecContent)
Bash("cd .specs && ln -sf " + filename + " current.md")
Edit(".specs/" + filename, "**Status:** approved", "**Status:** in-progress\n**Started:** 2025-09-30 21:52:03")

// ⬇️ VALIDATION CHECKPOINT (NEW)
validateSpecDrivenWorkflowCompleted()  // Must pass before proceeding

// ✅ Validation passed - continue

// Phase 4: TodoWrite
TodoWrite([...tasks...])

// Phase 5-7: Implementation and testing (as documented)
// ... all tasks completed ...

// ⬇️ Phase 8: MANDATORY Spec Finalization (NEW)
var spec = Read(".specs/current.md")
var actualTime = calculateActualTime(spec)
Edit(".specs/current.md", "**Status:** in-progress", "**Status:** completed")
Edit(".specs/current.md", "**Actual Time:** [to be filled]", "**Actual Time:** " + actualTime + " minutes")
// ... update test results, files created, etc.

// ✅ Implementation complete with spec saved and finalized
```

---

## END OF ENFORCEMENT RULES

**These rules are mandatory and must be followed for every `/wheels_execute` invocation.**