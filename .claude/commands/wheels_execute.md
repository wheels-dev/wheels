# /wheels_execute - Comprehensive Wheels Development Workflow

## Description
Execute a complete, systematic Wheels development workflow that implements features with professional quality, comprehensive testing, and bulletproof error prevention.

## 🎓 Key Learnings Implemented

This workflow incorporates critical lessons from real-world Wheels development:

### 1. **Views Are Critical** - Don't Skip Them
- Models and controllers are quick to generate, but **views are what make the application functional**
- All CRUD views (index, show, new, edit) must be created for a working application
- Forms need validation error displays, not just input fields
- **Views are where most errors occur** - query access patterns, association handling

### 2. **Test Incrementally, Not At The End**
- Generate model → Test it works → Then move to controller
- Generate controller → Test actions return 200 → Then create views
- Generate view → Test it renders → Then move to next view
- **Don't build everything then test** - you'll waste time debugging stacked errors

### 3. **HTTP 200 ≠ Success** - Verify Content Too
- A page can return 200 OK but contain error messages in the HTML
- Always check: `curl URL | grep "Expected Content"` not just `curl URL -I`
- Verify records display, forms render, links point to correct URLs

### 4. **Query Access Inside Loops Requires Special Handling**
```cfm
❌ BAD: #post.comments.recordCount#  (property access - fails)
✅ GOOD: <cfset postComments = model("Post").findByKey(post.id).comments()>
         #postComments.recordCount#  (method call - works)
```

### 5. **Migration Date Functions Are Database-Specific**
```cfm
❌ BAD: DATE_SUB(NOW(), INTERVAL 1 DAY)  (MySQL only)
✅ GOOD: var day1 = DateAdd("d", -1, Now())
         TIMESTAMP '#DateFormat(day1, "yyyy-mm-dd")# #TimeFormat(day1, "HH:mm:ss")#'
```

### 6. **Forms Without Error Display Are Incomplete**
Every form field needs:
```cfm
#textField(objectName="resource", property="name", label=false)#
<cfif resource.hasErrors("name")>
    <p class="error">#resource.allErrors("name")[1]#</p>
</cfif>
```

### 7. **Controller Filters Must Be Private**
```cfm
private function findResource() {  // Must be private
    resource = model("Resource").findByKey(key=params.key);
    if (!isObject(resource)) {
        flashInsert(error="Resource not found.");
        redirectTo(action="index");
    }
}
```

### 8. **Use Consistent Argument Styles**
```cfm
❌ MIXED: hasMany("comments", dependent="delete")
✅ CONSISTENT: hasMany(name="comments", dependent="delete")
```

### 9. **Frontend Stack Integration Via Layout Templates**
- Provide pre-built layouts (Basic, Tailwind+Alpine+HTMX, Bootstrap)
- Include CDN links, navigation structure, flash messages
- Users choose template during generation

### 10. **Resource Routes Work Differently Than Rails**
- `.resources("posts")` generates `/posts/:id` (not `/posts/show/:id`)
- Test actual generated URLs: `curl URL | grep 'href="'`

## Usage
```
/wheels_execute [task_description]
```

## Examples
```
/wheels_execute create a blog with posts and comments
/wheels_execute add user authentication to the application
/wheels_execute build an e-commerce product catalog with shopping cart
/wheels_execute create admin dashboard for user management
/wheels_execute implement contact form with email notifications
```

## Workflow Overview

The `/wheels_execute` command implements a **Spec-Driven Development** workflow with incremental task-based implementation:

### Execution Modes:

#### **Mode 1: Interactive Spec-Driven (Recommended)**
User gets to review and approve the implementation plan before any code is written.

0. **MCP Detection & Documentation Loading** - Load patterns and verify tools
1. **Requirements Analysis** - Parse user request and identify components needed
2. **📋 Specification Generation** - Create detailed spec with all components, views, routes
3. **✋ User Approval Checkpoint** - Present spec and task list, wait for approval
4. **📝 Task List Creation** - Break spec into granular, testable tasks using TodoWrite
5. **🔄 Incremental Implementation** - Implement one task at a time with testing
6. **✅ Task Completion Tracking** - Mark tasks complete only after testing passes
7. **🎯 Final Verification** - Comprehensive browser testing of complete feature
8. **📊 Results Report** - Summary of what was built with evidence

#### **Mode 2: Autonomous (Fast)**
Claude Code implements immediately without approval (use with caution).

Same as Mode 1 but skips Step 3 (User Approval Checkpoint).

### Why Spec-Driven Development?

**Traditional Approach Problems:**
- User doesn't know what will be built until it's done
- Changes mid-implementation waste time
- Missing requirements discovered at the end
- No visibility into progress

**Spec-Driven Approach Benefits:**
- ✅ User sees complete plan before coding starts
- ✅ User can request changes to the spec
- ✅ Clear task list shows progress in real-time
- ✅ Each task is tested before moving forward
- ✅ User knows exactly what they'll get

## Detailed Phase Descriptions

### Phase 0: MCP Detection & Documentation Loading (1-2 minutes)
**Purpose:** Verify tools are available and load relevant patterns before planning.

**Steps:**
1. Check for `.mcp.json` - if exists, MCP is mandatory
2. Test MCP connection: `mcp__wheels__wheels_server(action="status")`
3. Get server port for testing URLs later
4. Load critical documentation:
   - `.ai/wheels/troubleshooting/common-errors.md`
   - `.ai/wheels/patterns/validation-templates.md`
   - Task-specific docs based on keywords (blog, auth, API, etc.)

**Output:** Confirmation that tools are ready and patterns are loaded.

---

### Phase 1: Requirements Analysis (2-3 minutes)
**Purpose:** Parse user request, load previous specs, and identify what needs to be built.

**Step 1: Load Previous Specifications**
```javascript
// Check if .specs/ directory exists
Glob(pattern=".specs/*.md")

// If specs exist, read recent ones to understand what's already built
Read(".specs/current.md")  // Current state of application

// Load last 3 specs to understand project evolution
Read(".specs/20250930-163000-blog-posts-comments.md")
Read(".specs/20250930-170000-add-user-authentication.md")
```

**Step 2: Analyze Current Request**
- Extract entities (User, Post, Comment, Product, etc.)
- Identify relationships (Post hasMany Comments)
- Determine CRUD requirements (which resources need full CRUD vs partial)
- Detect frontend requirements (Tailwind, Alpine.js, HTMX, Bootstrap, etc.)
- Identify special features (authentication, file upload, email, API endpoints)

**Step 3: Determine What's New vs What Exists**
```
Previous Specs Show:
- Post and Comment models already exist
- Tailwind CSS layout already implemented

Current Request: "add tags to posts"

Analysis:
- NEW: Tag model
- NEW: PostTag join table
- MODIFY: Post model (add hasManyThrough relationship)
- NEW: Tags controller (CRUD)
- NEW: Tag views (index, show)
- MODIFY: posts/new.cfm and posts/edit.cfm (add tag selection)
```

**Example:**
```
User Request: "create a blog with posts and comments, use Tailwind CSS"

Previous Specs: None (fresh installation)

Analysis:
- Entities: Post, Comment
- Relationships: Post hasMany Comments (dependent delete)
- CRUD: Posts (full CRUD), Comments (create, delete only)
- Frontend: Tailwind CSS + Alpine.js (for interactive elements)
- Special: Need comment form on post show page
- Status: Complete new feature (not building on existing)
```

**Output:** Structured analysis showing what's new, what's modified, and what already exists.

---

### Phase 2: 📋 Specification Generation with Versioning (3-5 minutes)
**Purpose:** Create a detailed, human-readable specification document and save it for future reference.

**Specification Storage:**

All specifications are saved in `.specs/` directory:
```
.specs/
├── 20250930-163000-blog-posts-comments.md          (Initial blog)
├── 20250930-170000-add-user-authentication.md      (Added auth)
├── 20250930-173000-add-tags-to-posts.md            (Added tags)
└── current.md                                       (Symlink to latest)
```

**Filename Format:** `YYYYMMDD-HHMMSS-feature-description.md`

**Spec File Structure:**
```markdown
# Feature Specification: Blog with Posts and Comments

**Created:** 2025-09-30 16:30:00
**Status:** approved | in-progress | completed | modified
**Estimated Time:** 20-30 minutes
**Actual Time:** [filled in upon completion]

## User Request
"create a blog with posts and comments, use Tailwind CSS and Alpine.js"

## Previous Specs
- None (initial implementation)

## This Spec Builds On
- Fresh Wheels installation

## Components to Add
- Post model
- Comment model
- Posts controller
- Comments controller
- Views for posts (index, show, new, edit)
- Tailwind + Alpine.js layout

[Full specification details follow...]
```

**Benefits of Spec Versioning:**
1. **Audit Trail** - Complete history of what was built when
2. **Incremental Development** - Each new feature references previous specs
3. **Rollback Capability** - Can see what changed between versions
4. **Team Communication** - Share specs with team members
5. **Documentation** - Automatic project documentation
6. **Context Awareness** - Claude knows what already exists before planning new features

**Specification Includes:**

#### **1. Database Schema**
```
Posts Table:
- id (primary key)
- title (string, required, 3-200 chars)
- slug (string, unique, auto-generated from title)
- content (text, required, min 10 chars)
- published (boolean, default false)
- publishedAt (datetime, nullable)
- createdAt, updatedAt (timestamps)

Indexes:
- slug (unique)
- published + publishedAt (composite for queries)

Comments Table:
- id (primary key)
- content (text, required, 3-1000 chars)
- authorName (string, required, 2-100 chars)
- authorEmail (string, required, valid email)
- postId (foreign key to posts, on delete cascade)
- createdAt, updatedAt (timestamps)

Indexes:
- postId
- createdAt
```

#### **2. Models**
```
Post Model:
- Associations: hasMany(name="comments", dependent="delete")
- Validations:
  - validatesPresenceOf("title,content")
  - validatesUniquenessOf(property="slug")
  - validatesLengthOf(property="title", minimum=3, maximum=200)
  - validatesLengthOf(property="content", minimum=10)
- Methods:
  - generateSlug(text) - creates URL-friendly slug
  - excerpt(length=200) - returns truncated content
  - setSlugAndPublishDate() - callback before validation
- Callbacks:
  - beforeValidationOnCreate("setSlugAndPublishDate")

Comment Model:
- Associations: belongsTo(name="post")
- Validations:
  - validatesPresenceOf("content,authorName,authorEmail,postId")
  - validatesFormatOf(property="authorEmail", regEx="...")
  - validatesLengthOf(property="content", minimum=3, maximum=1000)
- Methods:
  - getGravatarUrl(size=80) - returns Gravatar image URL
```

#### **3. Controllers**
```
Posts Controller:
- Actions: index, show, new, create, edit, update, delete
- Filters: findPost (runs for show, edit, update, delete)
- Parameter Verification: key must be integer for show/edit/update/delete
- Flash Messages: Success/error messages for all actions

Comments Controller:
- Actions: create, delete
- Parameter Verification: postId required for all actions
- Flash Messages: Success/error messages
- Redirects: Always back to post show page
```

#### **4. Views (Complete List)**
```
Layout (layout.cfm):
- Tailwind CSS via CDN
- Alpine.js for interactive elements
- Navigation with links to: Home, Write Post
- Flash messages display area
- Mobile-responsive navigation with hamburger menu

Posts Views:
- index.cfm: Grid of post cards, show title/excerpt/date/comment count
- show.cfm: Full post with comments section, add comment form (Alpine.js toggle)
- new.cfm: Form with title, slug, content, published checkbox
- edit.cfm: Same as new but pre-populated with post data

All forms include:
- Field labels
- Validation error displays
- CSRF tokens
- Submit and Cancel buttons
```

#### **5. Routes**
```
Root: / → posts#index
Resources: posts (generates RESTful routes)
Resources: comments (generates RESTful routes)
Wildcard: Enabled for flexibility
```

#### **6. Frontend Stack**
```
- Tailwind CSS: Utility-first styling
- Alpine.js: Reactive components (comment form toggle, mobile menu)
- HTMX: Available for future enhancements
- Google Fonts (Inter): Typography
```

#### **7. Sample Data**
```
10 tech blog posts with:
- Varied titles (HTMX, Tailwind, Security, Testing, etc.)
- Rich HTML content
- Published status
- Staggered publish dates
```

**Output:** Complete specification document formatted as markdown.

---

### Phase 3: ✋ User Approval Checkpoint
**Purpose:** Let user review, request changes, or approve the specification.

**Claude Code Presents:**
```markdown
## 📋 Implementation Specification

I've analyzed your request and created the following specification:

[Complete spec from Phase 2]

## 📝 Implementation Tasks

If approved, I will implement the following tasks in order:

1. ✅ Generate Post model with validations and associations
2. ✅ Generate Comment model with validations and associations
3. ✅ Create database migrations (posts, comments, seed data)
4. ✅ Run migrations and verify tables created
5. ✅ Generate Posts controller with all CRUD actions
6. ✅ Generate Comments controller (create, delete)
7. ✅ Create layout with Tailwind CSS, Alpine.js, HTMX
8. ✅ Create posts/index.cfm view and test
9. ✅ Create posts/show.cfm view with comments and test
10. ✅ Create posts/new.cfm form and test
11. ✅ Create posts/edit.cfm form and test
12. ✅ Configure routes (root, resources)
13. ✅ Test complete CRUD workflow
14. ✅ Test comment creation and deletion
15. ✅ Final browser testing of all features

Estimated time: 20-30 minutes

---

**Please review and respond:**
- Type "approve" to begin implementation
- Type "change: [description]" to request modifications
- Ask questions about any part of the spec
```

**User Can:**
- ✅ Approve and proceed
- ✅ Request changes (add/remove features, change frontend stack, etc.)
- ✅ Ask clarifying questions
- ✅ Cancel if not what they wanted

**Upon Approval:**
1. Create `.specs/` directory if it doesn't exist
2. Generate timestamped filename: `YYYYMMDD-HHMMSS-feature-name.md`
3. Write complete spec to file with metadata:
   ```markdown
   # Feature Specification: Blog with Posts and Comments

   **Created:** 2025-09-30 16:30:00
   **Status:** approved
   **Estimated Time:** 20-30 minutes
   **Actual Time:** [to be filled upon completion]

   ## User Request
   "create a blog with posts and comments, use Tailwind CSS and Alpine.js"

   ## Previous Specs
   - None (initial implementation)

   ## This Spec Builds On
   - Fresh Wheels installation

   [Complete specification content...]
   ```
4. Create/update `current.md` symlink pointing to this spec
5. Update spec status to "in-progress"
6. Begin implementation

---

### Phase 4: 📝 Task List Creation with TodoWrite
**Purpose:** Create trackable, granular tasks that show real-time progress.

**Step 1: Read Current Spec**
```javascript
// Load the spec that was just approved
Read(".specs/current.md")

// Extract task list from specification
```

**Step 2: Create TodoWrite Tasks**
```javascript
TodoWrite({
  todos: [
    {
      content: "Generate Post model with validations",
      activeForm: "Generating Post model with validations",
      status: "pending"
    },
    {
      content: "Generate Comment model with validations",
      activeForm: "Generating Comment model with validations",
      status: "pending"
    },
    // ... all tasks from spec
  ]
});
```

**Step 3: Update Spec Status**
```javascript
// Update .specs/current.md with status change
Edit(".specs/current.md",
  old_string="**Status:** approved",
  new_string="**Status:** in-progress\n**Started:** [timestamp]"
)
```

**Task Granularity:**
- One task per model
- One task per migration
- One task per controller
- One task per view (index, show, new, edit)
- One task per test suite
- One task per major testing phase

**Why This Matters:**
- User sees progress in real-time
- Claude Code stays focused on one task at a time
- Easy to pause and resume later
- Clear audit trail of what was completed
- Spec file always reflects current status

---

### Phase 5: 🔄 Incremental Implementation with Testing
**Purpose:** Implement one task at a time, test it works, then move to next.

**Pattern for EACH Task:**

```
1. Mark task as in_progress in TodoWrite
2. Implement the task (generate code, create file, etc.)
3. TEST IMMEDIATELY:
   - Reload application if needed
   - Curl the relevant URL
   - Verify HTTP status (200 or expected redirect)
   - Verify content appears (grep for expected text)
4. If test passes:
   - Mark task as completed in TodoWrite
   - Move to next task
5. If test fails:
   - Keep task as in_progress
   - Debug and fix the issue
   - Re-test until passes
   - Then mark completed and move on
```

**Example Task Implementation:**

```markdown
Task: "Create posts/index.cfm view and test"

1. TodoWrite: Mark "Create posts/index.cfm" as in_progress

2. Generate view:
   - Create /app/views/posts/index.cfm
   - Use proper query loop pattern
   - Handle association access correctly
   - Include Tailwind CSS classes

3. Test immediately:
   ```bash
   curl -s http://localhost:PORT?reload=true  # Reload app
   curl -s http://localhost:PORT -I           # Check status (200?)
   curl -s http://localhost:PORT | grep "Latest Tech Posts"  # Content appears?
   curl -s http://localhost:PORT | grep -c "article class"   # Count posts (10?)
   ```

4. Results:
   ✅ 200 OK
   ✅ Title appears
   ✅ 10 posts displayed

5. TodoWrite: Mark "Create posts/index.cfm" as completed

6. Move to next task: "Create posts/show.cfm view and test"
```

**Key Principle:** Never start task N+1 until task N is tested and working.

---

### Phase 6: ✅ Task Completion Tracking
**Purpose:** Maintain accurate progress and provide transparency.

**TodoWrite Updates:**
- Update status in real-time
- Only ONE task should be "in_progress" at a time
- Mark completed IMMEDIATELY after successful test
- If task fails, document the issue and keep as in_progress

**Spec File Updates:**
After each major milestone (models complete, controllers complete, views complete):
```javascript
// Update spec with progress
Edit(".specs/current.md",
  old_string="## Implementation Progress\n\n[Previous content]",
  new_string="## Implementation Progress\n\n**Models:** ✅ Complete (Post, Comment)\n**Controllers:** ✅ Complete (Posts, Comments)\n**Views:** 🔄 In Progress (2/4 complete)\n**Tests:** ⏳ Pending"
)
```

**User Visibility:**
User sees live progress:
```
✅ Generate Post model with validations
✅ Generate Comment model with validations
✅ Create database migrations
✅ Run migrations and verify tables
✅ Generate Posts controller with all CRUD actions
🔄 Create posts/index.cfm view and test (In Progress)
⏳ Create posts/show.cfm view and test (Pending)
⏳ Create posts/new.cfm form and test (Pending)
...
```

**Files Created Tracking:**
Maintain list of created files in spec:
```markdown
## Files Created

**Models:**
- [Post.cfc](app/models/Post.cfc) - Blog post model
- [Comment.cfc](app/models/Comment.cfc) - Comment model

**Controllers:**
- [Posts.cfc](app/controllers/Posts.cfc) - Posts CRUD controller
- [Comments.cfc](app/controllers/Comments.cfc) - Comments controller

**Views:**
- [layout.cfm](app/views/layout.cfm) - Main layout
- [posts/index.cfm](app/views/posts/index.cfm) - Post list view
- [posts/show.cfm](app/views/posts/show.cfm) - Post detail view
```

---

### Phase 7: 🎯 Final Verification
**Purpose:** Comprehensive end-to-end testing of complete feature.

**Full Test Suite:**
1. Homepage displays all posts
2. Click on post → detail page loads
3. Comment form toggles (Alpine.js)
4. Edit button → edit form loads
5. New post button → new form loads
6. Mobile menu works (Alpine.js)
7. All links point to correct URLs
8. Forms have validation error displays
9. CSRF protection present
10. Responsive design works

**Evidence Collection:**
```bash
# Test results
curl -s http://localhost:PORT -I                    # Homepage: 200 OK
curl -s http://localhost:PORT/posts/2 -I            # Show: 200 OK
curl -s http://localhost:PORT/posts/new -I          # New: 200 OK
curl -s http://localhost:PORT/posts/2/edit -I       # Edit: 200 OK

# Content verification
curl -s http://localhost:PORT | grep "Getting Started with HTMX"  # ✅
curl -s http://localhost:PORT | grep -c "article class"           # 10 ✅
curl -s http://localhost:PORT | grep "Tailwind"                   # ✅
curl -s http://localhost:PORT | grep "Alpine"                     # ✅
```

---

### Phase 8: 📊 Results Report and Spec Finalization
**Purpose:** Document what was built with evidence and finalize the specification.

**Step 1: Calculate Implementation Time**
```javascript
// Get start time from spec
var startTime = Read(".specs/current.md") // Extract "Started:" timestamp
var endTime = Now()
var actualTime = DateDiff("n", startTime, endTime) // Minutes
```

**Step 2: Update Spec Status to Completed**
```javascript
// Finalize the spec
Edit(".specs/current.md",
  old_string="**Status:** in-progress",
  new_string="**Status:** completed\n**Completed:** [timestamp]"
)

// Add actual implementation time
Edit(".specs/current.md",
  old_string="**Actual Time:** [to be filled upon completion]",
  new_string="**Actual Time:** [calculated] minutes"
)

// Add test results summary
Edit(".specs/current.md",
  old_string="## Test Results\n\n[To be filled]",
  new_string="## Test Results\n\n**All Tests Passed:** ✅\n**Browser Tests:** ✅ All pages verified\n**Test Coverage:** 90%+\n**Performance:** Acceptable"
)
```

**Step 3: Generate Results Report**
```markdown
## ✅ Implementation Complete!

### What Was Built:

**Database:**
- ✅ Posts table with indexes
- ✅ Comments table with foreign keys
- ✅ 10 sample tech blog posts seeded

**Models:**
- ✅ Post model (validations, associations, methods)
- ✅ Comment model (validations, associations, Gravatar)

**Controllers:**
- ✅ Posts controller (full CRUD with filters)
- ✅ Comments controller (create, delete)

**Views:**
- ✅ Layout with Tailwind CSS, Alpine.js, HTMX
- ✅ posts/index.cfm (grid layout)
- ✅ posts/show.cfm (with comments section)
- ✅ posts/new.cfm (form with validation)
- ✅ posts/edit.cfm (form with validation)

**Routes:**
- ✅ Root route → posts#index
- ✅ RESTful resources for posts and comments

### Test Results:

All pages tested and working:
- ✅ http://localhost:58635 (200 OK, 10 posts displayed)
- ✅ http://localhost:58635/posts/2 (200 OK, comments section visible)
- ✅ http://localhost:58635/posts/new (200 OK, form rendered)
- ✅ http://localhost:58635/posts/2/edit (200 OK, form pre-populated)

Frontend stack verified:
- ✅ Tailwind CSS loaded and styling applied
- ✅ Alpine.js interactive elements working (mobile menu, comment form toggle)
- ✅ HTMX available for future enhancements

### Implementation Metrics:

- **Estimated Time:** 20-30 minutes
- **Actual Time:** 22 minutes
- **Tasks Completed:** 15/15
- **Test Coverage:** 92%
- **Browser Tests:** 100% pass rate

### What You Can Do Now:

1. Visit http://localhost:58635 to see your blog
2. Click any post to view details
3. Click "Write Post" to create new posts
4. Edit or delete posts
5. Add comments to posts
6. Test mobile responsiveness (resize browser)

### Files Created:

Models: app/models/Post.cfc, app/models/Comment.cfc
Controllers: app/controllers/Posts.cfc, app/controllers/Comments.cfc
Views: app/views/layout.cfm, app/views/posts/*.cfm
Migrations: app/migrator/migrations/*.cfc
Routes: config/routes.cfm (updated)

### Specification Reference:

Full implementation details saved to: [.specs/20250930-163000-blog-posts-comments.md](.specs/20250930-163000-blog-posts-comments.md)

To build additional features on top of this, run:
```
/wheels_execute [your next feature request]
```

The system will automatically load this spec and understand what already exists.
```

**Step 4: Preserve Spec History**
```javascript
// The completed spec remains in .specs/ directory
// current.md symlink stays pointed at latest completed spec
// Next /wheels_execute will create a new spec that references this one
```

---

### Phase 0 (Fallback): MCP Tools Detection & Validation (30 seconds)
- **🔴 CRITICAL**: This phase is MANDATORY and must be executed FIRST
- **Check MCP Availability**: Verify `.mcp.json` exists in project root
- **Test MCP Connection**: Run `mcp__wheels__wheels_server(action="status")` to validate server is running
- **Enforce MCP Usage**: If `.mcp.json` exists, ALL operations MUST use `mcp__wheels__*` tools
- **Strict Prohibition**: NEVER use CLI commands (`wheels g`, `wheels dbmigrate`, etc.) when MCP exists
- **Port Discovery**: Get running server port from MCP status or `server.json`

**MCP Detection Logic:**
```bash
# Check for MCP configuration
ls .mcp.json

# If exists → MCP is MANDATORY
# Use: mcp__wheels__wheels_generate, mcp__wheels__wheels_migrate, etc.
# NEVER use: wheels g, wheels dbmigrate, etc.
```

**MCP Tools Reference:**
- `mcp__wheels__wheels_generate(type, name, attributes)` - Generate components
- `mcp__wheels__wheels_migrate(action)` - Run migrations (latest, up, down, info)
- `mcp__wheels__wheels_test(type, reporter)` - Execute tests
- `mcp__wheels__wheels_server(action)` - Manage server (status, start, stop)
- `mcp__wheels__wheels_reload()` - Reload application
- `mcp__wheels__wheels_analyze(target, verbose)` - Analyze project

### Phase 1: Pre-Flight Documentation Loading (2-3 minutes)
- **Critical Error Prevention**: Always load `common-errors.md` and `validation-templates.md` first
- **Smart Documentation Discovery**: Use task-to-documentation mapping decision tree
- **Project Context Loading**: Understand existing codebase patterns and conventions
- **Pattern Recognition**: Detect argument styles and naming conventions already in use

**Documentation Loading Decision Tree:**
- **Task includes "blog" + "posts"** → Load: `.ai/wheels/database/models/associations.md`, `.ai/wheels/controllers/rendering.md`, `.ai/wheels/views/data-handling.md`
- **Task includes "authentication" or "login"** → Load: `.ai/wheels/database/models/user-authentication.md`, `.ai/wheels/security/csrf-protection.md`, `.ai/wheels/controllers/filters.md`
- **Task includes "API"** → Load: `.ai/wheels/controllers/api-development.md`, `.ai/wheels/views/rendering.md`
- **Task includes "forms"** → Load: `.ai/wheels/views/helpers/forms.md`, `.ai/wheels/security/csrf-protection.md`, `.ai/wheels/models/validations.md`
- **Task includes "admin" or "dashboard"** → Load: `.ai/wheels/controllers/filters.md`, `.ai/wheels/security/`, `.ai/wheels/views/layouts.md`

### Phase 2: Intelligent Analysis & Planning with View Requirements (3-5 minutes)
- **Requirement Analysis**: Parse natural language into specific Wheels components
- **Component Mapping**: Identify models, controllers, **AND ALL REQUIRED VIEWS**, migrations needed
- **View Requirements Planning**: For each controller action, identify required view:
  - `index` action → needs `index.cfm` (list view with proper query loops)
  - `show` action → needs `show.cfm` (detail view with association access)
  - `new` action → needs `new.cfm` (form with validation error display)
  - `edit` action → needs `edit.cfm` (form with pre-populated data)
  - Plan forms with: field labels, error displays, CSRF tokens, submit buttons
- **Frontend Stack Selection**: Choose layout template (Basic, Tailwind+Alpine+HTMX, Bootstrap)
- **Dependency Analysis**: Determine implementation order and resolve conflicts
- **Browser Test Planning**: Plan comprehensive user flow testing scenarios
- **Risk Assessment**: Identify potential issues and mitigation strategies

### Phase 3: Incremental Implementation with Real-Time Testing (10-20 minutes)

**🚨 CRITICAL: Test each component IMMEDIATELY after generation before moving to next**

#### Step-by-Step Implementation Order:

**Step 1: Generate & Test Models**
- Generate model via MCP
- Enhance with validations, associations, methods
- **TEST**: Verify model instantiates: `curl http://localhost:PORT?reload=true`
- **TEST**: Check no errors in model code
- ✅ Only proceed if model works

**Step 2: Run & Test Migrations**
- Generate migrations for database schema
- **Fix database-specific functions**: Use CFML `DateAdd()` + `TIMESTAMP` formatting, NOT `DATE_SUB()`
- Run migrations via MCP
- **TEST**: Verify tables exist and migrations complete successfully
- ✅ Only proceed if database is ready

**Step 3: Generate & Test Controllers**
- Generate controller via MCP
- Add actions, filters, parameter verification
- **Use consistent named parameters**: `findByKey(key=params.key, include="assoc")`
- **TEST**: Hit controller action URL: `curl http://localhost:PORT/resource -I`
- **TEST**: Verify returns 200 or expected redirect (not 500 error)
- ✅ Only proceed if controller actions work

**Step 4: Generate & Test Layout**
- Choose frontend stack template (Tailwind+Alpine+HTMX recommended)
- Create layout.cfm with navigation, flash messages, content area
- Include CDN links for CSS/JS libraries
- **TEST**: Reload app and hit homepage
- **TEST**: Verify layout loads without errors
- ✅ Only proceed if layout renders

**Step 5: Generate & Test Views (ONE AT A TIME)**

**For each view:**
1. Create view file (index.cfm, show.cfm, new.cfm, edit.cfm)
2. Use proper query access patterns:
   ```cfm
   ❌ BAD: #resource.association.recordCount#
   ✅ GOOD: <cfset assocRecords = model("Resource").findByKey(resource.id).association()>
            #assocRecords.recordCount#
   ```
3. Include validation error displays in forms:
   ```cfm
   <cfif objectName.hasErrors("property")>
       <p class="error">#objectName.allErrors("property")[1]#</p>
   </cfif>
   ```
4. **TEST IMMEDIATELY**: `curl http://localhost:PORT/resource -I` (should return 200)
5. **TEST CONTENT**: `curl http://localhost:PORT/resource | grep "Expected Content"`
6. ✅ Only proceed to next view if current view works

**Step 6: Configure & Test Routes**
- Add resource routes to routes.cfm
- Set root route
- **TEST**: Reload app
- **TEST**: Verify all route URLs work (index, show, new, edit)
- ✅ Only proceed if all routes map correctly

**Real-Time Anti-Pattern Detection:**
- During code generation, check for anti-patterns BEFORE saving:
  ```cfm
  // DETECT & FIX: Mixed argument styles
  hasMany("comments", dependent="delete");  // ❌ STOP - Fix before proceeding
  hasMany(name="comments", dependent="delete");  // ✅ Save and continue

  // DETECT & FIX: Query/Array confusion
  <cfset count = ArrayLen(post.comments())>  // ❌ STOP - Fix before proceeding
  <cfset count = post.comments().recordCount>  // ✅ Save and continue
  ```

**Error Recovery at Each Step:**
- If any test fails, STOP and fix before proceeding
- Don't generate more code on top of broken code
- Fix the current component until tests pass
- Document what was fixed for learning

**Anti-Pattern Detection During Implementation:**
```cfm
// DETECT: Mixed argument styles
hasMany("comments", dependent="delete");  // ❌ STOP - Fix before proceeding
hasMany(name="comments", dependent="delete");  // ✅ Continue

// DETECT: Query/Array confusion
<cfset count = ArrayLen(post.comments())>  // ❌ STOP - Fix before proceeding
<cfset count = post.comments().recordCount>  // ✅ Continue

// DETECT: Missing CSRF protection
#startFormTag(...)#  // ❌ STOP - Add CSRF token
#startFormTag(...)##authenticityToken()#  // ✅ Continue
```

### Phase 4: TestBox BDD Test Suite Creation (10-20 minutes)
- **⏰ TIMING**: Tests are written AFTER implementation is complete (not before - this is not TDD)
- **✅ REQUIREMENT**: Tests MUST be written BEFORE marking feature complete
- **🧹 CLEANUP**: All tests must include proper `beforeEach()` and `afterEach()` for isolation
- **Model Tests**: Write BDD specs for all model functionality, validations, and associations
- **Controller Tests**: Write BDD specs for all controller actions and security filters
- **Integration Tests**: Write BDD specs for complete user workflows and CRUD operations
- **Test Data Setup**: Create fixtures and test data for comprehensive testing
- **Validation Testing**: Write BDD specs for all form validation scenarios
- **Security Testing**: Write BDD specs for authentication, authorization, and CSRF protection

**Test Writing Order:**
1. Implementation complete → 2. Write tests → 3. Run tests → 4. Mark feature complete

### Phase 5: Multi-Level Testing Execution (3-8 minutes)
- **Unit Test Execution**: Run all model and controller BDD specs
- **Integration Test Execution**: Run all workflow and CRUD BDD specs
- **Migration Testing**: Verify database changes work correctly
- **Test Coverage Analysis**: Ensure all code paths are tested
- **Test Failure Resolution**: Fix any failing tests before proceeding

### Phase 6: Comprehensive Browser Testing with Content Verification (10-15 minutes)

**🚨 CRITICAL: Don't just check HTTP status - verify actual page content renders correctly**

#### Testing Process:

**Step 1: Verify Server & Port**
- Get port from MCP: `mcp__wheels__wheels_server(action="status")`
- Construct base URL: `http://localhost:PORT`

**Step 2: Test Homepage/Index**
```bash
# Check HTTP status
curl -s "http://localhost:PORT" -I  # Should be 200 OK

# Verify actual content appears (not just status code)
curl -s "http://localhost:PORT" | grep "Expected Title"
curl -s "http://localhost:PORT" | grep -c "article class"  # Count records displayed

# Verify frontend stack loaded
curl -s "http://localhost:PORT" | grep -E "(Tailwind|Alpine|HTMX)"
```

**Step 3: Test Individual Resource Pages**
```bash
# Test show page
curl -s "http://localhost:PORT/posts/2" -I  # Should be 200 OK
curl -s "http://localhost:PORT/posts/2" | grep "Comments ("  # Verify comments section

# Test new page
curl -s "http://localhost:PORT/posts/new" -I  # Should be 200 OK
curl -s "http://localhost:PORT/posts/new" | grep "Create"  # Verify form title

# Test edit page
curl -s "http://localhost:PORT/posts/2/edit" -I  # Should be 200 OK
curl -s "http://localhost:PORT/posts/2/edit" | grep "Edit"  # Verify form title
```

**Step 4: Verify Links Generate Correctly**
```bash
# Check what URLs linkTo generates
curl -s "http://localhost:PORT" | grep -o 'href="[^"]*posts[^"]*"' | head -5

# Verify links point to correct resources, not just /posts
```

**Step 5: Test Interactive Elements**
```bash
# Verify Alpine.js directives exist
curl -s "http://localhost:PORT/posts/2" | grep -E "x-data|@click"

# Verify HTMX attributes if used
curl -s "http://localhost:PORT" | grep "hx-"
```

**Step 6: Verify Forms Have Required Elements**
```bash
# Check CSRF tokens present
curl -s "http://localhost:PORT/posts/new" | grep "csrf"

# Check submit buttons exist
curl -s "http://localhost:PORT/posts/new" | grep "submit"

# Verify validation error display areas exist
curl -s "http://localhost:PORT/posts/new" | grep "hasErrors"
```

**Step 7: Test Error Scenarios**
```bash
# Test 404 handling
curl -s "http://localhost:PORT/posts/99999" -I  # Should redirect or show 404

# Test missing views don't cause 500 errors
curl -s "http://localhost:PORT/posts/1" -I  # Should be 200, not 500
```

**What Makes a Test PASS:**
- ✅ HTTP 200 status code
- ✅ Expected content appears in HTML (titles, records, forms)
- ✅ No error messages in page content
- ✅ Frontend libraries loaded (Tailwind, Alpine, HTMX)
- ✅ Links generate correct URLs with IDs
- ✅ Forms have all required elements (fields, labels, submit, CSRF)
- ✅ Interactive elements have proper attributes (x-data, @click, hx-)

**What Makes a Test FAIL:**
- ❌ HTTP 500 Internal Server Error
- ❌ HTTP 302 redirect to unexpected location
- ❌ Page returns HTML but no actual content (empty lists)
- ❌ Error messages visible in page content
- ❌ Links missing or pointing to wrong URLs
- ❌ Forms missing fields or submit buttons
- ❌ Missing CSRF protection

**Port Discovery Process:**
```javascript
// Step 1: Get server status via MCP (preferred)
mcp__wheels__wheels_server(action="status")  // Returns port if running

// Step 2: Fallback - Use CLI command
Bash("wheels server status")  // Returns port and server status

// Step 3: Fallback - Read server.json
Read("server.json")  // Check "port" or "web.http.port" settings

// Step 4: Default - Use 8080 if not specified
var port = discoveredPort || 8080;
var baseUrl = "http://localhost:" + port;
```

### Phase 7: Quality Assurance & Reporting (2-3 minutes)
- **⚠️ NOTE**: Anti-pattern detection should have already occurred during Phase 3 implementation
- **Final Anti-Pattern Scan**: One last check for any missed issues
- **Security Review**: Verify CSRF, authentication, input validation
- **Performance Analysis**: Check for N+1 queries, optimization opportunities
- **Documentation Compliance**: Validate against `.ai` documentation patterns
- **Test Coverage Report**: Generate detailed test coverage analysis
- **Comprehensive Reporting**: Generate detailed results with screenshots and test results

### Phase 8: Rollback & Recovery (if needed)
**This phase only executes if previous phases encounter critical failures.**

- **Test Failures**: Roll back code changes, analyze root cause, fix issues, re-run tests
- **Browser Test Failures**: Investigate root cause in screenshots, fix implementation, re-test
- **Migration Failures**: Run down migrations, fix schema issues, re-apply migrations
- **MCP Tool Failures**: Verify MCP server connection, restart if needed, document fallback to CLI
- **Complete Failure**: Document what worked and what didn't, propose alternative approach
- **Partial Success**: Document completed components, identify blocking issues, plan resolution

**Rollback Strategy:**
```bash
# If MCP tools are available
mcp__wheels__wheels_migrate(action="down")  # Rollback migrations
mcp__wheels__wheels_analyze(target="all")   # Analyze current state

# Document the issue
- What was attempted
- What failed and why
- What was successfully completed
- Recommended next steps
```

## View Generation Templates

### Critical View Patterns

All generated views MUST follow these patterns to avoid common errors:

#### Index View Template (Resource List)
```cfm
<cfparam name="resources">
<cfoutput>
#contentFor("title", "Resource List")#

<h1>Resources</h1>

<cfif resources.recordCount>
    <div class="grid">
        <cfloop query="resources">
            <article>
                <h2>#linkTo(controller="resources", action="show", key=resources.id, text=resources.name)#</h2>

                <!-- CRITICAL: Accessing associations inside query loop -->
                <cfset resourceAssoc = model("Resource").findByKey(resources.id).association()>
                <p>#resourceAssoc.recordCount# associated items</p>
            </article>
        </cfloop>
    </div>
<cfelse>
    <p>No resources found.</p>
</cfif>
</cfoutput>
```

#### Show View Template (Resource Detail)
```cfm
<cfparam name="resource">
<cfparam name="associations">
<cfoutput>
#contentFor("title", "#resource.name# - Detail")#

<h1>#resource.name#</h1>
<p>#resource.description#</p>

<!-- Actions -->
<div class="actions">
    #linkTo(controller="resources", action="edit", key=resource.id, text="Edit")#
    #linkTo(controller="resources", action="index", text="Back to List")#
</div>

<!-- Associated Records -->
<h2>Associated Items (#associations.recordCount#)</h2>
<cfif associations.recordCount>
    <cfloop query="associations">
        <div>#associations.name#</div>
    </cfloop>
</cfif>
</cfoutput>
```

#### New/Edit Form Template
```cfm
<cfparam name="resource">
<cfoutput>
#contentFor("title", "Create Resource")#

<h1>Create Resource</h1>

#startFormTag(controller="resources", action="create", method="post")#

    <!-- Text Field with Validation Errors -->
    <div>
        <label for="resource-name">Name *</label>
        #textField(objectName="resource", property="name", label=false)#
        <cfif resource.hasErrors("name")>
            <p class="error">#resource.allErrors("name")[1]#</p>
        </cfif>
    </div>

    <!-- Textarea with Validation Errors -->
    <div>
        <label for="resource-description">Description</label>
        #textArea(objectName="resource", property="description", label=false)#
        <cfif resource.hasErrors("description")>
            <p class="error">#resource.allErrors("description")[1]#</p>
        </cfif>
    </div>

    <!-- Checkbox -->
    <div>
        <label>
            #checkBox(objectName="resource", property="active", label=false)#
            <span>Active</span>
        </label>
    </div>

    <!-- Submit -->
    <div>
        #submitTag(value="Create Resource")#
        #linkTo(controller="resources", action="index", text="Cancel")#
    </div>

#endFormTag()#
</cfoutput>
```

#### Controller Template with Filters
```cfm
component extends="Controller" {

    function config() {
        // Parameter verification
        verifies(only="show,edit,update,delete", params="key", paramsTypes="integer");

        // Filters
        filters(through="findResource", only="show,edit,update,delete");
    }

    function index() {
        // Load with associations to avoid N+1 queries
        resources = model("Resource").findAll(
            order="createdAt DESC",
            include="association"
        );
    }

    function show() {
        // Resource loaded by filter
        // Load associated records
        associations = resource.association(order="createdAt ASC");
    }

    function new() {
        resource = model("Resource").new();
    }

    function create() {
        resource = model("Resource").new(params.resource);

        if (resource.save()) {
            flashInsert(success="Resource created successfully!");
            redirectTo(action="show", key=resource.id);
        } else {
            flashInsert(error="Please correct the errors below.");
            renderView(action="new");
        }
    }

    function edit() {
        // Resource loaded by filter
    }

    function update() {
        // Resource loaded by filter
        if (resource.update(params.resource)) {
            flashInsert(success="Resource updated successfully!");
            redirectTo(action="show", key=resource.id);
        } else {
            flashInsert(error="Please correct the errors below.");
            renderView(action="edit");
        }
    }

    function delete() {
        // Resource loaded by filter
        if (resource.delete()) {
            flashInsert(success="Resource deleted successfully!");
            redirectTo(action="index");
        } else {
            flashInsert(error="Unable to delete resource.");
            redirectTo(action="show", key=resource.id);
        }
    }

    // Private filter
    private function findResource() {
        resource = model("Resource").findByKey(key=params.key);

        if (!isObject(resource)) {
            flashInsert(error="Resource not found.");
            redirectTo(action="index");
        }
    }
}
```

### Migration Template (Database-Agnostic)
```cfm
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            try {
                // Use CFML date functions, not database-specific
                var now = Now();
                var pastDate = DateAdd("d", -7, now);

                // Create table
                t = createTable(name="resources", force=false);
                t.string(columnNames="name", allowNull=false, limit=255);
                t.text(columnNames="description", allowNull=true);
                t.boolean(columnNames="active", default=false);
                t.timestamps();
                t.create();

                // Add indexes
                addIndex(table="resources", columnNames="name");
                addIndex(table="resources", columnNames="active,createdAt");

                // Seed data (if needed) using CFML date formatting
                execute("INSERT INTO resources (name, description, active, createdAt, updatedAt)
                         VALUES (
                             'Sample Resource',
                             'Description here',
                             1,
                             TIMESTAMP '#DateFormat(now, "yyyy-mm-dd")# #TimeFormat(now, "HH:mm:ss")#',
                             TIMESTAMP '#DateFormat(now, "yyyy-mm-dd")# #TimeFormat(now, "HH:mm:ss")#'
                         )");

            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(errorCode="1", detail=local.exception.detail, message=local.exception.message, type="any");
            } else {
                transaction action="commit";
            }
        }
    }

    function down() {
        dropTable("resources");
    }
}
```

## Anti-Pattern Prevention

The workflow specifically prevents the two most common Wheels errors:

### ❌ Mixed Argument Styles (PREVENTED)
```cfm
// BAD - will cause "Missing argument name" errors
hasMany("comments", dependent="delete");
model("Post").findByKey(params.key, include="comments");
```

### ✅ Consistent Argument Styles (ENFORCED)
```cfm
// GOOD - all named arguments
hasMany(name="comments", dependent="delete");
model("Post").findByKey(key=params.key, include="comments");

// ALSO GOOD - all positional arguments
hasMany("comments");
model("Post").findByKey(params.key);
```

### ❌ Query/Array Confusion (PREVENTED)
```cfm
// BAD - ArrayLen() on query objects
<cfset commentCount = ArrayLen(post.comments())>
<cfloop array="#comments#" index="comment">
```

### ✅ Proper Query Handling (ENFORCED)
```cfm
// GOOD - use .recordCount for queries
<cfset commentCount = post.comments().recordCount>
<cfloop query="comments" startrow="1" endrow="#comments.recordCount#">
```

## Success Criteria

A feature is only considered complete when ALL of the following are true:
- [ ] ✅ **MCP tools were used exclusively (if `.mcp.json` exists)**
- [ ] ✅ **No CLI commands used when MCP available**
- [ ] ✅ **MCP server connection validated before starting**
- [ ] ✅ All relevant `.ai` documentation was consulted
- [ ] ✅ No anti-patterns detected in generated code
- [ ] ✅ **Comprehensive TestBox BDD test suite written and passing**
- [ ] ✅ **All model BDD specs pass (validations, associations, methods)**
- [ ] ✅ **All controller BDD specs pass (actions, filters, security)**
- [ ] ✅ **All integration BDD specs pass (user workflows, CRUD)**
- [ ] ✅ **Test coverage >= 90% for all components**
- [ ] ✅ All browser tests pass
- [ ] ✅ Every button, form, and link has been tested
- [ ] ✅ Responsive design works on mobile, tablet, desktop
- [ ] ✅ Security validations are in place
- [ ] ✅ Performance is acceptable
- [ ] ✅ Error scenarios are handled properly
- [ ] ✅ Screenshot evidence exists for all user flows
- [ ] ✅ Implementation follows Wheels conventions

## Browser Testing Coverage

The workflow automatically tests:

### Navigation Testing
- Homepage load and layout
- All menu links and navigation paths
- Breadcrumb navigation
- Footer links and utility pages

### CRUD Operations Testing
- Index pages (list views)
- Show pages (detail views)
- New/Create forms and submission
- Edit/Update forms and submission
- Delete actions and confirmations

### Form Validation Testing
- Empty form submissions (should show errors)
- Partial form submissions
- Invalid data submissions
- Complete valid form submissions
- CSRF protection verification

### Interactive Elements Testing
- JavaScript functionality
- Alpine.js components and interactions
- HTMX requests and responses
- Modal dialogs and dropdowns
- Dynamic content updates

### Responsive Design Testing
- Mobile viewport (375x667)
- Tablet viewport (768x1024)
- Desktop viewport (1920x1080)
- Wide screen viewport (2560x1440)
- Mobile navigation (hamburger menus)

### Error Scenario Testing
- 404 pages for nonexistent resources
- Authentication redirects
- Authorization failures
- Validation error displays
- Server error handling

## Quality Gates

### Automatic Rejection Criteria
Code will be automatically rejected if:
- Any mixed argument styles are detected
- Any `ArrayLen()` calls on model associations exist
- **Any TestBox BDD spec fails**
- **Test coverage is below 90%**
- **Missing BDD specs for any component**
- Any browser test fails
- Any security check fails
- Any anti-pattern is detected
- Routes don't follow RESTful conventions

### Performance Requirements
- Pages should load without obvious delays
- Forms should submit without timeout errors
- No N+1 query patterns detected (check for missing `include` in model calls)
- Database queries should use indexes where appropriate
- Responsive design should not cause layout shifts

### Security Requirements
- CSRF protection must be enabled
- All forms must include CSRF tokens
- Authentication filters must be present
- Input validation must be implemented
- SQL injection prevention must be verified

## TestBox BDD Testing Requirements

### Mandatory BDD Test Structure

Every component MUST have comprehensive TestBox BDD specs using the following structure:

#### Model Specs (`/tests/specs/models/`)
```cfm
component extends="wheels.Testbox" {

    function beforeAll() {
        // Setup database and test environment
        application.testbox = new testbox.system.TestBox();
    }

    function afterAll() {
        // Cleanup test data
    }

    function run() {
        describe("Post Model", function() {

            beforeEach(function() {
                variables.post = model("Post").new();
            });

            afterEach(function() {
                if (isObject(variables.post) && variables.post.isPersisted()) {
                    variables.post.delete();
                }
            });

            describe("Validations", function() {
                it("should require title", function() {
                    variables.post.title = "";
                    expect(variables.post.valid()).toBeFalse();
                    expect(variables.post.allErrors()).toHaveKey("title");
                });

                it("should require content", function() {
                    variables.post.content = "";
                    expect(variables.post.valid()).toBeFalse();
                    expect(variables.post.allErrors()).toHaveKey("content");
                });

                it("should require unique slug", function() {
                    var existingPost = model("Post").create({
                        title: "Test Post",
                        content: "Test content",
                        slug: "test-slug",
                        published: false
                    });

                    variables.post.slug = "test-slug";
                    expect(variables.post.valid()).toBeFalse();
                    expect(variables.post.allErrors()).toHaveKey("slug");

                    existingPost.delete();
                });
            });

            describe("Associations", function() {
                it("should have many comments", function() {
                    expect(variables.post.comments()).toBeQuery();
                });

                it("should delete associated comments", function() {
                    var savedPost = model("Post").create({
                        title: "Test Post",
                        content: "Test content",
                        published: false
                    });

                    var comment = model("Comment").create({
                        content: "Test comment",
                        authorName: "Test Author",
                        authorEmail: "test@example.com",
                        postId: savedPost.id
                    });

                    expect(savedPost.comments().recordCount).toBe(1);
                    savedPost.delete();
                    expect(model("Comment").findByKey(comment.id)).toBeFalse();
                });
            });

            describe("Methods", function() {
                it("should generate excerpt", function() {
                    variables.post.content = "<p>This is a long content that should be truncated at some point for the excerpt.</p>";
                    expect(len(variables.post.excerpt(20))).toBeLTE(23); // 20 + "..."
                });

                it("should auto-generate slug from title", function() {
                    variables.post.title = "This is a Test Title!";
                    variables.post.setSlugAndPublishDate();
                    expect(variables.post.slug).toBe("this-is-a-test-title");
                });
            });
        });
    }
}
```

#### Controller Specs (`/tests/specs/controllers/`)
```cfm
component extends="wheels.Testbox" {

    function beforeAll() {
        application.testbox = new testbox.system.TestBox();
    }

    function run() {
        describe("Posts Controller", function() {

            beforeEach(function() {
                // Setup test data
                variables.testPost = model("Post").create({
                    title: "Test Post",
                    content: "Test content for controller testing",
                    published: true,
                    publishedAt: now()
                });
            });

            afterEach(function() {
                if (isObject(variables.testPost)) {
                    variables.testPost.delete();
                }
            });

            describe("index action", function() {
                it("should load published posts", function() {
                    var controller = controller("Posts");
                    controller.index();

                    expect(controller.posts).toBeQuery();
                    expect(controller.posts.recordCount).toBeGTE(1);
                });

                it("should order posts by publishedAt DESC", function() {
                    var newerPost = model("Post").create({
                        title: "Newer Post",
                        content: "Newer content",
                        published: true,
                        publishedAt: dateAdd("h", 1, now())
                    });

                    var controller = controller("Posts");
                    controller.index();

                    expect(controller.posts.title[1]).toBe("Newer Post");
                    newerPost.delete();
                });
            });

            describe("show action", function() {
                it("should load post and comments", function() {
                    var controller = controller("Posts");
                    controller.params.key = variables.testPost.id;
                    controller.show();

                    expect(controller.post.id).toBe(variables.testPost.id);
                    expect(controller.comments).toBeQuery();
                });
            });

            describe("create action", function() {
                it("should create valid post", function() {
                    var controller = controller("Posts");
                    controller.params.post = {
                        title: "New Test Post",
                        content: "New test content",
                        published: true
                    };

                    var initialCount = model("Post").count();
                    controller.create();

                    expect(model("Post").count()).toBe(initialCount + 1);

                    // Cleanup
                    var newPost = model("Post").findOne(where="title = 'New Test Post'");
                    if (isObject(newPost)) {
                        newPost.delete();
                    }
                });

                it("should handle validation errors", function() {
                    var controller = controller("Posts");
                    controller.params.post = {
                        title: "", // Invalid - empty title
                        content: "Test content"
                    };

                    controller.create();
                    expect(controller.post.hasErrors()).toBeTrue();
                });
            });
        });
    }
}
```

#### Integration Specs (`/tests/specs/integration/`)
```cfm
component extends="wheels.Testbox" {

    function run() {
        describe("Blog Workflow Integration", function() {

            beforeEach(function() {
                // Setup clean test environment
            });

            afterEach(function() {
                // Cleanup test data
            });

            describe("Complete post lifecycle", function() {
                it("should create, publish, and delete post", function() {
                    // Create post
                    var post = model("Post").create({
                        title: "Integration Test Post",
                        content: "Integration test content",
                        published: false
                    });

                    expect(post.isNew()).toBeFalse();
                    expect(post.published).toBeFalse();

                    // Publish post
                    post.update({published: true, publishedAt: now()});
                    expect(post.published).toBeTrue();

                    // Add comment
                    var comment = model("Comment").create({
                        content: "Integration test comment",
                        authorName: "Test Author",
                        authorEmail: "test@example.com",
                        postId: post.id
                    });

                    expect(post.comments().recordCount).toBe(1);

                    // Delete post (should cascade delete comments)
                    post.delete();
                    expect(model("Comment").findByKey(comment.id)).toBeFalse();
                });
            });

            describe("Form validation workflow", function() {
                it("should prevent invalid post creation", function() {
                    var post = model("Post").new({
                        title: "", // Invalid
                        content: "x" // Too short
                    });

                    expect(post.save()).toBeFalse();
                    expect(post.allErrors()).toHaveKey("title");
                    expect(post.allErrors()).toHaveKey("content");
                });
            });
        });
    }
}
```

### Test Execution Requirements

#### Mandatory Test Commands
All tests MUST be executed and pass before completion:

**If MCP tools available (preferred):**
```javascript
// Run all model specs
mcp__wheels__wheels_test(type="models", reporter="json")

// Run all controller specs
mcp__wheels__wheels_test(type="controllers", reporter="json")

// Run all integration specs
mcp__wheels__wheels_test(type="integration", reporter="json")

// Run complete test suite
mcp__wheels__wheels_test(type="all", reporter="json")
```

**If MCP tools NOT available (fallback only):**
```bash
# Run all model specs
wheels test model --reporter=json

# Run all controller specs
wheels test controller --reporter=json

# Run all integration specs
wheels test integration --reporter=json

# Run complete test suite
wheels test all --reporter=json
```

#### Test Coverage Requirements
- **Models**: 100% coverage of all public methods, validations, and associations
- **Controllers**: 100% coverage of all actions and filters
- **Integration**: 90% coverage of complete user workflows
- **Overall**: Minimum 90% total coverage across all components

#### Test Data Management
- Use TestBox's `beforeEach()` and `afterEach()` for test isolation
- Create test fixtures for complex scenarios
- Always clean up test data to prevent test pollution
- Use database transactions for faster test execution

## Error Recovery System

When errors occur during any phase:

1. **Identify Error Type**: Syntax, logic, pattern, or security error
2. **Load Recovery Documentation**: Load relevant `.ai` documentation for the error
3. **Apply Documented Solution**: Use established patterns from documentation
4. **Retry Operation**: Attempt the operation with corrected approach
5. **Log Pattern**: Document the error pattern for future prevention

### Common Recovery Flows

#### Mixed Argument Error Recovery
```
Error: "Missing argument name" detected
→ Load: .ai/wheels/troubleshooting/common-errors.md
→ Fix: Convert to consistent argument style
→ Retry: Code generation with corrected pattern
→ Validate: Syntax check passes
```

#### Query/Array Confusion Recovery
```
Error: ArrayLen() on query object detected
→ Load: .ai/wheels/models/data-handling.md
→ Fix: Use .recordCount and proper loop syntax
→ Retry: View generation with correct patterns
→ Validate: Browser test confirms functionality
```

#### MCP Connection Failure Recovery
```
Error: MCP server not responding
→ Check: Server running via mcp__wheels__wheels_server(action="status")
→ Fix: Restart server or verify .mcp.json configuration
→ Validate: Test MCP connection before retrying
→ Fallback: Document why MCP unavailable, use CLI tools as last resort
```

#### TestBox BDD Test Failure Recovery
```
Error: BDD specs failing or missing
→ Load: .ai/wheels/testing/ documentation
→ Fix: Write comprehensive BDD specs for all components
→ Retry: Run complete test suite
→ Validate: All tests pass with 90%+ coverage
```

#### Test Coverage Insufficient Recovery
```
Error: Test coverage below 90%
→ Analyze: Identify untested code paths
→ Fix: Add BDD specs for missing scenarios
→ Retry: Run test suite with coverage analysis
→ Validate: Coverage meets minimum requirements
```

## Implementation Strategy

### Documentation Loading Strategy
1. **Universal Critical Documentation** (always loaded first):
   - `.ai/wheels/troubleshooting/common-errors.md`
   - `.ai/wheels/patterns/validation-templates.md`
   - `.ai/wheels/workflows/pre-implementation.md`

2. **Component-Specific Documentation** (loaded based on task analysis):
   - Models: `.ai/wheels/models/architecture.md`, `associations.md`, `validations.md`
   - Controllers: `.ai/wheels/controllers/architecture.md`, `rendering.md`, `filters.md`
   - Views: `.ai/wheels/views/data-handling.md`, `architecture.md`, `forms.md`
   - Migrations: `.ai/wheels/database/migrations/creating-migrations.md`

3. **Feature-Specific Documentation** (loaded as needed):
   - Authentication: `.ai/wheels/models/user-authentication.md`
   - Security: `.ai/wheels/security/csrf-protection.md`
   - Forms: `.ai/wheels/views/helpers/forms.md`

### Task Type Detection
The workflow analyzes the task description for:
- **Model Indicators**: "model", "User", "Post", "association", "validation"
- **Controller Indicators**: "controller", "action", "CRUD", "API", "filter"
- **View Indicators**: "view", "template", "form", "layout", "responsive"
- **Feature Indicators**: "auth", "admin", "search", "email", "upload"

### Browser Testing Strategy
Based on application type detected:
- **Blog Applications**: Post CRUD, commenting, navigation
- **E-commerce Applications**: Product catalog, shopping cart, checkout
- **Admin Applications**: User management, authentication, dashboards
- **API Applications**: Endpoint testing, JSON responses, authentication

## Comparison Benefits vs MCP Tool

### Advantages of Slash Command Approach
- **Flexibility**: Claude Code can adapt the workflow dynamically
- **Error Handling**: Better error recovery and human-readable feedback
- **Documentation Integration**: Direct access to `.ai` folder without MCP resource limitations
- **Comprehensive Testing**: TestBox BDD specs + Browser testing + Integration testing
- **Test Coverage**: Mandatory 90%+ coverage with detailed analysis
- **Quality Assurance**: No feature complete without passing test suite
- **Reporting**: Rich, detailed reporting with screenshots, test results, and coverage analysis
- **Learning**: Users see the complete process and can learn from it

### Testing Strategy
Run both approaches on the same task:
```
/wheels_execute create a blog with posts and comments
vs
mcp__wheels__develop(task="create a blog with posts and comments")
```

Compare results on:
- Code quality and adherence to patterns
- Test coverage and browser testing thoroughness
- Error prevention and pattern consistency
- Implementation time and reliability
- User experience and learning value

This slash command provides a systematic, comprehensive approach to Wheels development that ensures professional quality results with complete testing coverage.

## 📁 Spec Versioning System

### How Specs Are Stored and Used

**Directory Structure:**
```
.specs/
├── 20250930-163000-blog-posts-comments.md          (Initial blog implementation)
├── 20250930-170000-add-user-authentication.md      (Added authentication)
├── 20250930-173000-add-tags-to-posts.md            (Added tagging feature)
├── 20250930-180000-add-search-functionality.md     (Added search)
└── current.md → 20250930-180000-add-search-functionality.md (Symlink to latest)
```

**Each Spec File Contains:**
```markdown
# Feature Specification: [Feature Name]

**Created:** 2025-09-30 16:30:00
**Status:** completed
**Estimated Time:** 20-30 minutes
**Actual Time:** 22 minutes
**Started:** 2025-09-30 16:31:00
**Completed:** 2025-09-30 16:53:00

## User Request
"[original user request verbatim]"

## Previous Specs
- [20250930-163000-blog-posts-comments.md](.specs/20250930-163000-blog-posts-comments.md)

## This Spec Builds On
- Post and Comment models (from 20250930-163000)
- Tailwind CSS layout (from 20250930-163000)

## Components to Add
- [List of NEW components]

## Components to Modify
- [List of MODIFIED components]

## Database Schema
[Complete schema for new/modified tables]

## Models
[Model specifications]

## Controllers
[Controller specifications]

## Views
[View specifications]

## Routes
[Route changes]

## Implementation Progress
**Models:** ✅ Complete
**Controllers:** ✅ Complete
**Views:** ✅ Complete
**Tests:** ✅ Complete

## Files Created
[Clickable links to all created files]

## Test Results
**All Tests Passed:** ✅
**Browser Tests:** ✅ All pages verified
**Test Coverage:** 92%
```

### Incremental Development Example

**First Feature:**
```bash
/wheels_execute create a blog with posts and comments
```
Creates: `.specs/20250930-163000-blog-posts-comments.md`

**Second Feature:**
```bash
/wheels_execute add user authentication with login/logout
```
- Reads `.specs/current.md` to understand existing structure
- Sees: Post model, Comment model, Posts controller, Comments controller already exist
- Creates: `.specs/20250930-170000-add-user-authentication.md`
- References previous spec in "Previous Specs" section
- Lists what it builds on in "This Spec Builds On" section
- Only creates NEW components (User model, Sessions controller, auth views)
- Only MODIFIES what needs changing (Posts controller to add auth filter)

**Third Feature:**
```bash
/wheels_execute add tags to posts with many-to-many relationship
```
- Reads `.specs/current.md` (now pointing to authentication spec)
- Reads previous spec to see Post model structure
- Creates: `.specs/20250930-173000-add-tags-to-posts.md`
- References: 20250930-163000 (original blog) and 20250930-170000 (authentication)
- Builds on: Post model (adds hasManyThrough), existing Tailwind layout
- Creates: Tag model, PostTag join model, Tags controller, tag views
- Modifies: Post model (add association), posts/new.cfm and posts/edit.cfm (add tag picker)

### Benefits of This Approach

1. **Complete Audit Trail**: See exactly what was built, when, and why
2. **Context Awareness**: Each new feature understands what already exists
3. **Avoid Duplication**: Won't recreate models/controllers that already exist
4. **Smart Modifications**: Knows to modify existing files rather than create new ones
5. **Rollback Capability**: Can see state at any point in project history
6. **Documentation**: Automatic project documentation showing evolution
7. **Team Collaboration**: Share specs to show what was implemented
8. **Time Tracking**: Accurate implementation time for future estimation

### Symlink Management

**Creating the Symlink:**
```bash
# After spec is approved and implementation starts
ln -sf 20250930-163000-blog-posts-comments.md .specs/current.md
```

**Updating the Symlink:**
```bash
# When new feature is started, symlink points to new spec
ln -sf 20250930-170000-add-user-authentication.md .specs/current.md
```

**Why current.md is Important:**
- Always points to the latest approved/in-progress spec
- Phase 1 loads this to understand current project state
- Makes it easy to know "what's the current state without sorting by timestamp"

### Handling Spec Modifications

**If User Requests Changes During Approval (Phase 3):**
```markdown
User: "change: use Bootstrap instead of Tailwind"

Claude Code:
1. Update the spec in-memory
2. Re-present updated spec for approval
3. Do NOT save to .specs/ until approved
4. Once approved, save with original timestamp
```

**If Implementation Encounters Issues:**
```markdown
During Phase 5: Discover that Comment model needs additional field

Claude Code:
1. Update .specs/current.md with modification:
   ```
   ## Modifications During Implementation
   - **Comment model**: Added `approved` boolean field for moderation
   ```
2. Continue implementation
3. Final spec shows both original plan and modifications made
```

**Spec Status Lifecycle:**
```
draft → approved → in-progress → completed
                               ↘ modified (if changes occur during implementation)
```

### Version Control Integration

**Recommended .gitignore:**
```gitignore
# Don't ignore specs - they're valuable documentation
# .specs/

# But do ignore symlinks if they cause issues
.specs/current.md
```

**Committing Specs:**
```bash
# After each feature completion
git add .specs/20250930-163000-blog-posts-comments.md
git commit -m "Add spec for blog posts and comments feature"

# Specs become part of project documentation
# Can be referenced in commit messages, pull requests, etc.
```

---

## 📖 Complete Usage Example

### User Request:
```
/wheels_execute create a blog with posts and comments, use Tailwind CSS and Alpine.js
```

### Claude Code Response (Phase 2 - Specification):

```markdown
## 📋 Implementation Specification

I've analyzed your request and created the following specification:

### Database Schema

**Posts Table:**
- id (primary key)
- title (string, required, 3-200 chars)
- slug (string, unique, auto-generated)
- content (text, required, min 10 chars)
- published (boolean, default false)
- publishedAt (datetime, nullable)
- createdAt, updatedAt (timestamps)
- Indexes: slug (unique), published+publishedAt

**Comments Table:**
- id (primary key)
- content (text, required, 3-1000 chars)
- authorName (string, required, 2-100 chars)
- authorEmail (string, required, email format)
- postId (foreign key → posts)
- createdAt, updatedAt (timestamps)
- Indexes: postId, createdAt

### Models

**Post Model:**
- hasMany(name="comments", dependent="delete")
- Validations: presence, uniqueness, length
- Methods: generateSlug(), excerpt(), setSlugAndPublishDate()
- Callbacks: beforeValidationOnCreate

**Comment Model:**
- belongsTo(name="post")
- Validations: presence, email format, length
- Methods: getGravatarUrl()

### Controllers

**Posts:** index, show, new, create, edit, update, delete (with findPost filter)
**Comments:** create, delete (redirects to post show)

### Views

**Layout:** Tailwind CSS, Alpine.js, responsive navigation
**Posts:** index (grid), show (with comments), new (form), edit (form)
All forms include validation error displays, CSRF tokens, submit/cancel buttons

### Routes

- Root: / → posts#index
- Resources: posts, comments
- Wildcard enabled

### Frontend Stack

- Tailwind CSS (utility styling)
- Alpine.js (comment form toggle, mobile menu)
- HTMX (available for enhancements)

### Sample Data

10 tech blog posts (HTMX, Tailwind, Security, Testing, DevOps, etc.)

---

## 📝 Implementation Tasks (15 tasks)

If approved, I will complete these tasks with incremental testing:

1. ✅ Generate Post model with validations and associations
2. ✅ Generate Comment model with validations and associations
3. ✅ Create migrations (posts, comments, seed 10 posts)
4. ✅ Run migrations and verify tables created
5. ✅ Generate Posts controller with CRUD actions
6. ✅ Generate Comments controller (create, delete)
7. ✅ Create layout with Tailwind + Alpine.js
8. ✅ Create posts/index.cfm and test (200 OK, 10 posts)
9. ✅ Create posts/show.cfm and test (200 OK, comments section)
10. ✅ Create posts/new.cfm and test (200 OK, form renders)
11. ✅ Create posts/edit.cfm and test (200 OK, pre-populated)
12. ✅ Configure routes (root, resources)
13. ✅ Test complete CRUD workflow (create, edit, delete)
14. ✅ Test comment creation and deletion
15. ✅ Final browser testing (all URLs, content, frontend stack)

**Estimated Time:** 20-30 minutes

---

**Please review and respond:**
- Type **"approve"** to begin implementation
- Type **"change: [description]"** to request modifications
- Ask questions about any part of the spec
```

### User Response:
```
approve
```

### Claude Code Implementation (Phase 4-6):

```markdown
## 🔄 Implementation Started

Creating task list...

**Tasks:**
✅ Generate Post model with validations
✅ Generate Comment model with validations
✅ Create database migrations
✅ Run migrations and verify tables
✅ Generate Posts controller with all CRUD actions
✅ Generate Comments controller (create, delete)
✅ Create layout with Tailwind CSS, Alpine.js
🔄 Create posts/index.cfm view and test (In Progress)
⏳ Create posts/show.cfm view with comments and test
⏳ Create posts/new.cfm form and test
⏳ Create posts/edit.cfm form and test
⏳ Configure routes
⏳ Test complete CRUD workflow
⏳ Test comment functionality
⏳ Final browser testing

---

Testing posts/index.cfm...
```bash
curl -s http://localhost:58635 -I
# HTTP/1.1 200 OK ✅

curl -s http://localhost:58635 | grep "Latest Tech Posts"
# Found: "Latest Tech Posts" ✅

curl -s http://localhost:58635 | grep -c "article class"
# Count: 10 ✅
```

✅ posts/index.cfm verified!

Moving to next task...

[Continues with each task...]
```

### Final Result (Phase 8):

```markdown
## ✅ Blog Implementation Complete!

### What Was Built:

**Database:**
- ✅ Posts table with slug (unique) and published+publishedAt indexes
- ✅ Comments table with postId and createdAt indexes
- ✅ 10 tech blog posts seeded (HTMX, Tailwind, Security, etc.)

**Models:**
- ✅ Post.cfc (validations, associations, slug generation, excerpt method)
- ✅ Comment.cfc (validations, belongsTo, Gravatar support)

**Controllers:**
- ✅ Posts.cfc (full CRUD with findPost filter, flash messages)
- ✅ Comments.cfc (create, delete with redirects)

**Views:**
- ✅ layout.cfm (Tailwind CSS, Alpine.js, responsive nav)
- ✅ posts/index.cfm (grid layout, post cards)
- ✅ posts/show.cfm (full post, comments section, Alpine.js toggle)
- ✅ posts/new.cfm (form with validation errors)
- ✅ posts/edit.cfm (form pre-populated)

**Routes:**
- ✅ / → posts#index
- ✅ RESTful resources (posts, comments)

### Test Results:

**All pages working:**
- ✅ http://localhost:58635 (200 OK, 10 posts displayed)
- ✅ http://localhost:58635/posts/2 (200 OK, comments section)
- ✅ http://localhost:58635/posts/new (200 OK, form rendered)
- ✅ http://localhost:58635/posts/2/edit (200 OK, pre-populated)

**Frontend verified:**
- ✅ Tailwind CSS styling applied
- ✅ Alpine.js interactive elements working
- ✅ Mobile responsive

### What You Can Do Now:

1. Visit **http://localhost:58635** to see your blog
2. Browse 10 tech articles
3. Click "Write Post" to create new posts
4. Edit or delete posts
5. Add comments with Gravatar avatars
6. Test on mobile (hamburger menu works)

### Files Created:

- Models: [Post.cfc](/Users/peter/projects/ws/blog/app/models/Post.cfc), [Comment.cfc](/Users/peter/projects/ws/blog/app/models/Comment.cfc)
- Controllers: [Posts.cfc](/Users/peter/projects/ws/blog/app/controllers/Posts.cfc), [Comments.cfc](/Users/peter/projects/ws/blog/app/controllers/Comments.cfc)
- Views: [layout.cfm](/Users/peter/projects/ws/blog/app/views/layout.cfm), posts/*.cfm
- Migrations: 3 migration files
- Routes: [routes.cfm](/Users/peter/projects/ws/blog/config/routes.cfm) updated

**Implementation Time:** 22 minutes
**All 15 tasks completed successfully!** ✅
```

---

## 🎯 Key Advantages of Spec-Driven Approach

1. **Transparency:** User sees exactly what will be built before any code is written
2. **Control:** User can request changes to the spec before implementation
3. **Progress Visibility:** Real-time task tracking shows what's done and what's next
4. **Quality:** Each task is tested before moving forward
5. **Documentation:** Complete spec and results report for future reference
6. **Confidence:** User knows the feature is thoroughly tested and working

This approach transforms `/wheels_execute` from a "black box" into a **collaborative, transparent development process**.