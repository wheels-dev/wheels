# CLAUDE.md

Guidance for Claude Code when working with Wheels applications.

## 🚨 MANDATORY: 5-Step Development Workflow

**AI ASSISTANTS MUST FOLLOW THIS EXACT ORDER:**

### 🛑 STEP 1: Check MCP Tools
```bash
ls .mcp.json  # If exists → MCP tools are MANDATORY
```
- ✅ Use `mcp__wheels__*` tools for ALL development
- ❌ NEVER use CLI commands (`wheels g`, `wheels test`)

### 🛑 STEP 2: Verify MCP Connection
```javascript
mcp__wheels__wheels_server(action="status")
```

### 🛑 STEP 3: Invoke Claude Code Skills (MANDATORY)

**🔴 CRITICAL: Invoke appropriate skill BEFORE any code generation or debugging**

**Available Skills:**
- `wheels-model-generator` - Models, validations, associations
- `wheels-controller-generator` - Controllers, actions, filters
- `wheels-view-generator` - Views, forms, layouts, partials
- `wheels-migration-generator` - Database migrations
- `wheels-routing-generator` - RESTful routes, nested routes
- `wheels-email-generator` - Mailers, email templates
- `wheels-plugin-generator` - Create Wheels plugins
- `wheels-test-generator` - TestBox tests
- `wheels-debugging` - Troubleshoot errors (use during testing!)
- `wheels-auth-generator` - Authentication systems
- `wheels-api-generator` - RESTful APIs
- `wheels-anti-pattern-detector` - Prevent common errors
- `wheels-refactoring` - Optimize code
- `wheels-deployment` - Production configuration
- `wheels-documentation-generator` - Generate documentation

**When to Invoke:**
- ✅ Before generating ANY Wheels code
- ✅ **Immediately when encountering errors during testing**
- ✅ When creating missing views or fixing bugs
- ✅ When debugging form/validation issues

### 🛑 STEP 4: Generate Code with MCP Tools
```javascript
// After skill guidance, use MCP tools
mcp__wheels__wheels_generate(type="model", name="Post", attributes="title:string")
mcp__wheels__wheels_migrate(action="latest")
```

### 🛑 STEP 5: Browser Testing (MANDATORY)

**When errors occur during testing:**
1. **STOP immediately**
2. **Invoke appropriate skill** (`wheels-debugging`, `wheels-view-generator`)
3. **Follow skill guidance** for fixes
4. **Apply fixes** using skill patterns
5. **Re-test** to verify

**Browser Testing Options (in order of preference):**

**Option A: Puppeteer MCP (Preferred)**
```javascript
// 1. Verify server
mcp__wheels__wheels_server(action="status")

// 2. Navigate and test
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT")
mcp__puppeteer__puppeteer_screenshot(name="test")

// 3. Test user flows (navigation, forms, CRUD operations)
```

**Option B: Playwright MCP**
```javascript
mcp__playwright__playwright_navigate(url="http://localhost:PORT")
mcp__playwright__playwright_screenshot()
```

**Option C: Browser MCP (if Puppeteer/Playwright unavailable)**
```javascript
mcp__browsermcp__browser_navigate(url="http://localhost:PORT")
mcp__browsermcp__browser_screenshot()
```

**When error occurs during testing:**
```javascript
// 4. INVOKE SKILL FIRST - Get guidance before fixing
Skill("wheels-debugging")
```

---

## 🔴 Critical Anti-Patterns (Production-Tested)

### View Anti-Patterns

#### 1. CSRF Token Conflicts (CRITICAL)
**❌ WRONG - Causes `Wheels.InvalidAuthenticityToken`:**
```cfm
#startFormTag(route="login", method="post")#
    <input type="hidden" name="authenticityToken" value="#authenticityToken()#">
```
**✅ CORRECT - startFormTag() includes token automatically:**
```cfm
#startFormTag(route="login", method="post")#
    <!-- NO manual token needed -->
```

#### 2. Property Access on New Objects (CRITICAL)
**❌ WRONG - Causes "no accessible Member" error:**
```cfm
value="#post.title#"
```
**✅ CORRECT - Use structKeyExists():**
```cfm
value="#structKeyExists(post, 'title') ? post.title : ''#"
```

For select options:
```cfm
<option value="draft" #(structKeyExists(post, 'status') AND post.status EQ 'draft') ? 'selected' : ''#>
```

Special case - property/method conflicts (e.g., `excerpt`):
```cfm
<cfif post.hasProperty('excerpt') && len(post.excerpt)>#post.excerpt#</cfif>
```

#### 3. Query vs Array Confusion (CRITICAL)
**❌ WRONG:**
```cfm
<cfif ArrayLen(posts)>
    <cfloop array="#posts#" index="post">
```
**✅ CORRECT - Wheels returns QUERIES:**
```cfm
<cfif posts.recordCount>
    <cfloop query="posts">
        #posts.title#
    </cfloop>
```

#### 4. Creating Missing Views
**Template for new views:**
```cfm
<cfparam name="items">
<cfoutput>
#contentFor(name="title", content="Page Title")#

<cfif items.recordCount>
    <cfloop query="items">
        #linkTo(text=items.title, action="show", key=items.id)#
    </cfloop>
<cfelse>
    <p>No items found.</p>
</cfif>
</cfoutput>
```

### Model Anti-Patterns

#### 1. Validation Parameters (CRITICAL)
**❌ WRONG - Uses singular:**
```cfm
validatesPresenceOf(property="username")
validate(method="customValidator")
```
**✅ CORRECT - Always use PLURAL:**
```cfm
validatesPresenceOf(properties="username,email")
validatesUniquenessOf(properties="email")
validatesFormatOf(properties="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$")
validate(methods="customValidator")
```

#### 2. Primary Key Configuration (CRITICAL)
**Always include in every model:**
```cfm
component extends="Model" {
    function config() {
        table("tablename");
        setPrimaryKey("id");  // ⚠️ REQUIRED - Must be explicit
        // Rest of configuration...
    }
}
```

#### 3. Callback Property Access (CRITICAL)
**❌ WRONG:**
```cfm
function setDefaults() {
    if (!len(this.counter)) {
        this.counter = 0;
    }
}
```
**✅ CORRECT:**
```cfm
function setDefaults() {
    if (!structKeyExists(this, "counter") || !len(this.counter)) {
        this.counter = 0;
    }
}
```

### Controller Anti-Patterns

#### Mixed Parameters (CRITICAL)
**❌ WRONG:**
```cfm
hasMany("comments", dependent="delete")
```
**✅ CORRECT - All named OR all positional:**
```cfm
hasMany(name="comments", dependent="delete")
// OR
hasMany("comments")
```

### Migration Anti-Patterns

#### 1. Boolean Parameters
**❌ CLI generates WRONG:**
```cfm
t = createTable(name='users', force='false', id='true');
```
**✅ Fix to proper booleans:**
```cfm
t = createTable(name='users');  // Use defaults
// OR
t = createTable(name='users', force=false, id=true);
```

#### 2. Foreign Key Naming
**For self-referential tables:**
```cfm
addForeignKey(
    table="follows",
    column="followerId",
    referenceTable="users",
    keyName="FK_follows_follower",  // Explicit name prevents conflicts
    onDelete="cascade"
);
```

#### 3. Composite Index Order
**✅ CORRECT - Composite FIRST:**
```cfm
addIndex(table="likes", columnNames="userId,tweetId", unique=true);  // First
addIndex(table="likes", columnNames="tweetId");  // Then second column
```

---

## 🔍 Common Errors & Solutions

### View Errors (Most Common)

**1. `Wheels.InvalidAuthenticityToken`**
- Cause: Manual CSRF token inside `startFormTag()`
- Fix: Remove `<input type="hidden" name="authenticityToken">`

**2. "Component has no accessible Member [PROPERTY]"**
- Cause: Accessing property on new/unsaved model
- Fix: Use `structKeyExists(object, 'property') ? object.property : ''`

**3. `Wheels.ViewNotFound`**
- Cause: Missing view file
- Fix: Create view with proper Wheels patterns (query loops, recordCount)

**4. "Can't find component [ModelName]"**
- Cause: Using `createObject("component", "Model")`
- Fix: Use `model("ModelName").new()`

### Association Errors

**"Missing argument name" in hasMany()**
- Cause: Mixing positional and named parameters
- Fix: Use consistent parameter style (all named or all positional)

### Routing Issues

**Resources syntax differs from Rails:**
```cfm
// ❌ WRONG (Rails-style)
.resources("posts", function(nested) { nested.resources("comments"); })

// ✅ CORRECT (Wheels)
.resources("posts")
.resources("comments")
```

### Form Helper Limitations

**Not available in Wheels:**
- `emailField()` - Use `textField(type="email")`
- `label(text="Name")` - Use `<label>Name</label>`

---

## 🔧 Quick Reference

### Model Structure
```cfm
component extends="Model" {
    function config() {
        table("tablename");
        setPrimaryKey("id");  // REQUIRED

        hasMany(name="children");
        belongsTo(name="parent");

        validatesPresenceOf(properties="field1,field2");
        validatesUniquenessOf(properties="field1");
        validate(methods="customValidator");

        beforeCreate("setDefaults");
    }

    function setDefaults() {
        if (!structKeyExists(this, "counter") || !len(this.counter)) {
            this.counter = 0;
        }
    }
}
```

### Controller Structure
```cfm
component extends="Controller" {
    function config() {
        filters(through="authenticate", except="index");
        verifies(except="index,new,create", params="key", paramsTypes="integer");
        provides("html,json");
    }

    function index() {
        items = model("Item").findAll(include="associations", order="createdAt DESC");
    }

    function create() {
        item = model("Item").new(params.item);
        if (item.save()) {
            redirectTo(route="item", key=item.id, success="Created!");
        } else {
            renderView(action="new");
        }
    }
}
```

### View Structure
```cfm
<cfparam name="items">
<cfoutput>
#contentFor(name="title", content="Items")#

<h1>Items</h1>

<cfif items.recordCount>
    <table>
        <cfloop query="items">
        <tr>
            <td>#linkTo(route="item", key=items.id, text=items.name)#</td>
        </tr>
        </cfloop>
    </table>
<cfelse>
    <p>No items found.</p>
</cfif>
</cfoutput>
```

### Form View (with Safe Property Access)
```cfm
<cfparam name="item">
<cfoutput>
#startFormTag(route="items", method="post")#
    #textField(
        objectName="item",
        property="name",
        value="#structKeyExists(item, 'name') ? item.name : ''#"
    )#

    <textarea name="item[description]">
    #structKeyExists(item, 'description') ? item.description : ''#
    </textarea>

    <select name="item[status]">
        <option value="active" #(structKeyExists(item, 'status') AND item.status EQ 'active') ? 'selected' : ''#>
            Active
        </option>
    </select>

    <button type="submit">Save</button>
#endFormTag()#
</cfoutput>
```

### Migration Structure
```cfm
component extends="wheels.migrator.Migration" {
    function up() {
        transaction {
            t = createTable(name="items");  // Use defaults for booleans
            t.string(columnNames="name", allowNull=false);
            t.text(columnNames="description");
            t.boolean(columnNames="active", default=true);
            t.timestamps();
            t.create();

            addIndex(table="items", columnNames="name", unique=true);
        }
    }

    function down() {
        dropTable("items");
    }
}
```

---

## 🔐 Security Best Practices

### CSRF Protection
- `startFormTag()` includes CSRF automatically - never add manual token
- Use `csrfMetaTags()` in layout `<head>`

### Password Hashing (Lucee Limitation)
**❌ BCrypt NOT supported natively:**
```cfm
hash(password, "BCrypt")  // Runtime error!
```
**✅ Use SHA-256:**
```cfm
passwordHash = hash(password, "SHA-256")
```

### SQL Injection Prevention
```cfm
// Use Wheels model methods (auto-sanitized)
users = model("User").findAll(where="email = '#params.email#'");

// Or use cfqueryparam
users = queryExecute(
    "SELECT * FROM users WHERE email = :email",
    { email = { value = params.email, cfsqltype = "cf_sql_varchar" } }
);
```

---

## 📦 MCP Tools Reference

```javascript
// Code Generation
mcp__wheels__wheels_generate(type="model", name="Post", attributes="title:string")
mcp__wheels__wheels_generate(type="controller", name="Posts", actions="index,show")
mcp__wheels__wheels_generate(type="view", name="posts/index")
mcp__wheels__wheels_generate(type="migration", name="CreatePostsTable")

// Database
mcp__wheels__wheels_migrate(action="latest")
mcp__wheels__wheels_migrate(action="info")

// Testing & Validation
mcp__wheels__wheels_test()
mcp__wheels__wheels_validate(model="all")

// Server Management
mcp__wheels__wheels_server(action="status")
mcp__wheels__wheels_reload()

// Analysis
mcp__wheels__wheels_analyze(target="all", verbose=true)
```

---

## 🚀 Complete Example Workflow

```javascript
// 1. Check MCP
mcp__wheels__wheels_server(action="status")

// 2. Invoke skill BEFORE generation
Skill("wheels-model-generator")
mcp__wheels__wheels_generate(type="model", name="Post", attributes="title:string,content:text")

Skill("wheels-controller-generator")
mcp__wheels__wheels_generate(type="controller", name="Posts", actions="index,show,new,create")

Skill("wheels-view-generator")
// Create view following skill guidance

Skill("wheels-migration-generator")
mcp__wheels__wheels_migrate(action="latest")

// 3. Browser test (use available MCP tool)
// Puppeteer (preferred):
mcp__puppeteer__puppeteer_navigate(url="http://localhost:8080/posts")
mcp__puppeteer__puppeteer_screenshot(name="posts-index")

// OR Playwright:
mcp__playwright__playwright_navigate(url="http://localhost:8080/posts")
mcp__playwright__playwright_screenshot()

// OR Browser MCP (fallback):
mcp__browsermcp__browser_navigate(url="http://localhost:8080/posts")
mcp__browsermcp__browser_screenshot()

// 4. Error encountered - INVOKE SKILL
Skill("wheels-debugging")
// Follow guidance, apply fix, re-test

// 5. Success - test form submission
mcp__puppeteer__puppeteer_navigate(url="http://localhost:8080/posts/new")
mcp__puppeteer__puppeteer_screenshot(name="posts-new")
```

---

## ⚠️ Critical Rules

**✅ ALWAYS:**
- Invoke skills BEFORE code generation
- Invoke skills IMMEDIATELY when debugging errors
- Use MCP tools when `.mcp.json` exists
- Test in browser after ANY development
- Use `structKeyExists()` for new model objects
- Use query loops, not array loops
- Use plural parameter names (properties, methods)

**❌ NEVER:**
- Skip skill invocation
- Guess at fixes without skills
- Add manual CSRF tokens inside `startFormTag()`
- Use CLI commands when MCP available
- Mix positional and named parameters
- Assume Rails conventions work
- Access properties without existence checks on new objects

---

## 📋 Spec-Driven Development Workflow

This project uses a systematic spec-driven development approach for managing features and maintaining context across sessions.

### Current Development

#### Active Specifications
*(Specifications currently in progress)*

- None yet - use `/new-spec` to create your first feature specification

#### Completed Specifications
*(Successfully implemented features)*

- None yet

#### Recent Decisions
*(Important architectural and implementation decisions)*

1. **Spec-Driven Workflow Implemented**: Using comprehensive task breakdown and session persistence
2. **Testing Strategy**: TestBox BDD specs + browser testing for all features
3. **Context Persistence**: Multi-layer approach (CLAUDE.md, tasks.md, git commits, session notes)

### Development Workflow Commands

#### Starting a New Feature
```bash
/new-spec
# Interactive prompts guide you through specification creation
# Generates spec.md and technical-spec.md
# Presents for review and approval
```

#### Breaking Down a Specification
```bash
/break-down-spec [spec-name]
# Analyzes specification
# Creates granular task breakdown (3-5 parent tasks, 3-8 subtasks each)
# Generates tasks.md with YAML frontmatter
# Creates feature branch
```

#### Implementing Tasks
```bash
/implement-task [task-number]
# Loads task context
# Invokes appropriate skills
# Implements with testing
# Marks complete upon success
```

#### Restoring Context
```bash
/restore-context
# Loads project context from CLAUDE.md
# Finds active specifications
# Analyzes current state from tasks.md and git
# Presents comprehensive status report
# Offers to continue where you left off
```

#### Completing a Feature
```bash
/complete-spec [spec-name]
# Runs comprehensive testing
# Updates spec status to completed
# Generates results report
# Calculates implementation metrics
```

### Session Persistence Strategy

This project uses **defense in depth** for context persistence:

**Layer 1: Named Sessions**
```bash
claude --session-id [feature-name]
claude --resume [feature-name]
```

**Layer 2: CLAUDE.md Updates**
- Automatic session summaries via hooks
- Active spec tracking
- Recent decisions log

**Layer 3: tasks.md Checkpoints**
- Every task completion records timestamp, commit, session ID
- Creates recoverable audit trail

**Layer 4: Git Commit Messages**
- Structured commits reference tasks and specs
- Code becomes documentation

**Layer 5: Automated Restoration**
- `/restore-context` command rebuilds full context from documentation
- Works even if session history is lost

### Specification Storage

All specifications are stored in `.claude/specs/`:
```
.claude/specs/
├── YYYYMMDD-HHMMSS-feature-name/
│   ├── spec.md              # Feature overview, user stories, acceptance criteria
│   ├── technical-spec.md    # Architecture, database schema, API endpoints
│   └── tasks.md             # Task breakdown with progress tracking
```

### Sub-Agents Available

- **task-analyzer**: Analyzes specifications and creates optimal task breakdowns
- **test-runner**: Runs tests and analyzes failures with suggested fixes
- **spec-validator**: Validates specifications for completeness and consistency

---
