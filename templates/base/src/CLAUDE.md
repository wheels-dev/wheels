# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with a Wheels application.

## 🚨 MANDATORY: Pre-Implementation Workflow

**AI ASSISTANTS MUST FOLLOW THIS EXACT ORDER:**

### 🛑 STEP 1: CHECK MCP TOOLS AVAILABILITY (ALWAYS FIRST)
```bash
# Check if .mcp.json exists - if YES, MCP tools are MANDATORY
ls .mcp.json
```

**If `.mcp.json` exists, YOU MUST:**
- ✅ Use `mcp__wheels__*` tools for ALL development tasks
- ❌ NEVER use CLI commands (`wheels g`, `wheels test`, etc.)
- ❌ NEVER use bash/curl for Wheels operations

### 🛑 STEP 2: VERIFY MCP TOOLS WORK
```javascript
// Test MCP server connection BEFORE any development
mcp__wheels__wheels_server(action="status")
```

### 🛑 STEP 3: Use Claude Code Skills (MANDATORY)

**🔴 CRITICAL: Before generating ANY Wheels code, you MUST invoke the appropriate Claude Code skill.**

Claude Code provides specialized skills that contain deep expertise about Wheels framework patterns and prevent common errors. These skills MUST be used for code generation tasks.

#### Available Claude Code Skills

1. **wheels-model-generator** - Generate Wheels ORM models
   - Use when: Creating or modifying models, adding validations, defining associations
   - Prevents: Mixed argument styles, invalid associations, CFML syntax errors
   - Invoke before: Any model creation or modification

2. **wheels-controller-generator** - Generate Wheels MVC controllers
   - Use when: Creating controllers, adding actions, implementing filters
   - Prevents: Mixed parameter styles, incorrect rendering, invalid filters
   - Invoke before: Any controller creation or modification

3. **wheels-view-generator** - Generate Wheels view templates
   - Use when: Creating views, forms, layouts, or partials
   - Prevents: Query/array confusion, incorrect form helpers, association display errors
   - Invoke before: Any view creation or modification

4. **wheels-migration-generator** - Generate database migrations
   - Use when: Creating tables, altering schemas, managing database changes
   - Prevents: Database-specific SQL, cross-database incompatibility
   - Invoke before: Any migration creation or modification

5. **wheels-test-generator** - Generate TestBox BDD test specs
   - Use when: Creating tests for models, controllers, or integration workflows
   - Ensures: Comprehensive test coverage with proper Wheels testing conventions
   - Invoke before: Any test creation

6. **wheels-auth-generator** - Generate authentication system
   - Use when: Implementing user authentication, login/logout, session management
   - Provides: Secure authentication patterns with bcrypt support
   - Invoke before: Any authentication implementation

7. **wheels-api-generator** - Generate RESTful API controllers
   - Use when: Creating API endpoints, JSON APIs, or web services
   - Ensures: Proper REST conventions and error handling
   - Invoke before: Any API controller creation

8. **wheels-anti-pattern-detector** - Detect and prevent common errors
   - Use when: Before generating ANY Wheels code (automatically activated)
   - Prevents: Mixed arguments, query confusion, non-existent helpers, database-specific SQL
   - ALWAYS active during code generation

9. **wheels-debugging** - Troubleshoot Wheels errors
   - Use when: Encountering errors, exceptions, or unexpected behavior
   - Provides: Error analysis, common solutions, debugging strategies
   - Invoke when: Debugging issues

10. **wheels-refactoring** - Refactor Wheels code
    - Use when: Optimizing code, fixing anti-patterns, improving performance
    - Provides: Refactoring patterns and best practices
    - Invoke when: Improving existing code

11. **wheels-deployment** - Configure production deployment
    - Use when: Preparing for production, configuring servers, hardening security
    - Provides: Security hardening, performance optimization, environment setup
    - Invoke when: Deploying to production

12. **wheels-documentation-generator** - Generate documentation
    - Use when: Documenting code, creating READMEs, generating API docs
    - Provides: Documentation comments, README files, API documentation
    - Invoke when: Documenting the application

#### How to Use Skills

**🚨 MANDATORY WORKFLOW:**

1. **Identify the task type** (model, controller, view, migration, etc.)
2. **Invoke the appropriate skill FIRST** before any code generation
3. **Follow the skill's guidance** for proper Wheels patterns
4. **Generate code** using MCP tools after skill validation

**Example Workflows:**

```javascript
// Creating a model - MUST invoke skill first
Skill("wheels-model-generator")
// Wait for skill to load and provide guidance
// Then use MCP tool:
mcp__wheels__wheels_generate(type="model", name="User", attributes="name:string,email:string")

// Creating a controller - MUST invoke skill first
Skill("wheels-controller-generator")
// Wait for skill to load and provide guidance
// Then use MCP tool:
mcp__wheels__wheels_generate(type="controller", name="Users", actions="index,show,new,create")

// Creating a migration - MUST invoke skill first
Skill("wheels-migration-generator")
// Wait for skill to load and provide guidance
// Then use MCP tool:
mcp__wheels__wheels_generate(type="migration", name="CreateUsersTable")
```

#### Skill Invocation Rules

**✅ ALWAYS invoke skills:**
- Before generating ANY Wheels component (model, controller, view, migration)
- When encountering Wheels-specific errors
- When refactoring Wheels code
- When implementing authentication or APIs
- Before deploying to production

**❌ NEVER skip skills:**
- Skills prevent common Wheels errors and anti-patterns
- Skills ensure proper CFML syntax and Wheels conventions
- Skills provide framework-specific expertise not available in general AI knowledge

### 🛑 STEP 4: Load Documentation (If Needed)

**After invoking the appropriate skill**, you may load additional documentation:

1. **📖 Load Relevant .ai Documentation**
   - Check if `.ai/` folder exists in project root
   - Load appropriate documentation sections:
     - For models: Read `.ai/wheels/database/` and `.ai/cfml/components/`
     - For controllers: Read `.ai/wheels/controllers/` and `.ai/cfml/syntax/`
     - For CFML syntax: Read `.ai/cfml/syntax/` and `.ai/cfml/best-practices/`
     - For patterns: Read `.ai/wheels/patterns/` and `.ai/wheels/snippets/`

2. **✅ Validate Against Standards**
   - Confirm implementation matches patterns in `.ai/wheels/patterns/`
   - Verify CFML syntax follows `.ai/cfml/best-practices/`
   - Check security practices from `.ai/wheels/security/`
   - Ensure naming conventions match `.ai/wheels/core-concepts/`

3. **🔍 Use Established Code Examples**
   - Reference code templates from `.ai/wheels/snippets/`
   - Follow model patterns from `.ai/wheels/database/models/`
   - Apply controller patterns from `.ai/wheels/controllers/`

**If `.ai/` folder is not available, use the MCP resources:**
- `wheels://.ai/cfml/syntax` - CFML language fundamentals
- `wheels://.ai/wheels/patterns` - Framework patterns
- `wheels://.ai/wheels/snippets` - Code examples

## 🚨 MANDATORY: Browser Testing Workflow

**🔴 CRITICAL: ALL development tasks MUST include comprehensive browser testing - NO EXCEPTIONS**

### 🛑 STEP 5: MANDATORY BROWSER TESTING (ALWAYS REQUIRED)

**After ANY development work (models, views, controllers, routes), you MUST:**

1. **📋 Verify Server Status**
   ```javascript
   mcp__wheels__wheels_server(action="status")
   ```

2. **🌐 Navigate to Application**
   ```javascript
   mcp__puppeteer__puppeteer_navigate(url="http://localhost:[PORT]")
   ```

3. **📸 Take Homepage Screenshot**
   ```javascript
   mcp__puppeteer__puppeteer_screenshot(name="homepage_test", width=1200, height=800)
   ```

4. **🧪 Test Core User Flows (MANDATORY)**
   - **Navigation Testing**: Click all main navigation links
   - **CRUD Operations**: Test create, read, update, delete flows
   - **Form Interactions**: Test all forms and validation
   - **Interactive Elements**: Test JavaScript/Alpine.js/HTMX functionality
   - **Responsive Design**: Test on different viewport sizes

5. **🔍 Verify Key Features Work**
   ```javascript
   // Example: Test clicking first post
   mcp__puppeteer__puppeteer_click(selector="article:first-child h2 a")
   mcp__puppeteer__puppeteer_screenshot(name="post_detail", width=1200, height=800)

   // Example: Test interactive elements
   mcp__puppeteer__puppeteer_click(selector="button[contains-class='btn']")
   mcp__puppeteer__puppeteer_screenshot(name="interaction_test", width=1200, height=800)
   ```

6. **📊 Document Test Results**
   - Confirm all screenshots show expected UI
   - Verify no JavaScript errors in console
   - Document any issues found
   - Ensure responsive design works

### ❌ DEVELOPMENT IS NOT COMPLETE WITHOUT BROWSER TESTING

**If you skip browser testing, the implementation is INCOMPLETE and UNACCEPTABLE.**

**Browser testing must verify:**
- [ ] All pages load correctly
- [ ] Navigation works
- [ ] Forms submit properly
- [ ] Interactive elements (Alpine.js/HTMX) function
- [ ] Responsive design displays correctly
- [ ] No JavaScript errors in console
- [ ] All CRUD operations work end-to-end

### 🚀 Browser Testing Templates

**For Blog Applications:**
```javascript
// Test homepage
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT")
mcp__puppeteer__puppeteer_screenshot(name="blog_homepage")

// Test post detail
mcp__puppeteer__puppeteer_click(selector="article:first-child h2 a")
mcp__puppeteer__puppeteer_screenshot(name="post_detail")

// Test comment form interaction
mcp__puppeteer__puppeteer_click(selector="button:contains('Add Comment')")
mcp__puppeteer__puppeteer_screenshot(name="comment_form")

// Test create post
mcp__puppeteer__puppeteer_click(selector="a:contains('Write Post')")
mcp__puppeteer__puppeteer_screenshot(name="create_post")
```

**For Admin Applications:**
```javascript
// Test admin dashboard
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT/admin")
mcp__puppeteer__puppeteer_screenshot(name="admin_dashboard")

// Test admin CRUD operations
// ... specific admin testing flows
```

**For API Applications:**
```javascript
// Test API endpoints
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT/api/endpoint")
mcp__puppeteer__puppeteer_screenshot(name="api_response")
```

## Quick Start

### Complete Development Workflow

**🚨 MANDATORY ORDER OF OPERATIONS:**

1. **Check for MCP tools** (`ls .mcp.json`)
2. **Verify MCP server** (`mcp__wheels__wheels_server(action="status")`)
3. **Invoke appropriate Claude Code skill** (e.g., `Skill("wheels-model-generator")`)
4. **Generate code using MCP tools** (e.g., `mcp__wheels__wheels_generate(...)`)
5. **Test in browser** (using Puppeteer MCP tools)

### MCP-Enabled Wheels Development

**🚨 CRITICAL: If `.mcp.json` exists, use MCP tools exclusively**

### ✅ Common Development Tasks (Skills + MCP Tools)

**IMPORTANT: Always invoke the appropriate skill BEFORE using MCP tools**

- **Create a model**:
  1. `Skill("wheels-model-generator")` (FIRST)
  2. `mcp__wheels__wheels_generate(type="model", name="User", attributes="name:string,email:string,active:boolean")`

- **Create a controller**:
  1. `Skill("wheels-controller-generator")` (FIRST)
  2. `mcp__wheels__wheels_generate(type="controller", name="Users", actions="index,show,new,create,edit,update,delete")`

- **Create a view**:
  1. `Skill("wheels-view-generator")` (FIRST)
  2. `mcp__wheels__wheels_generate(type="view", name="users/index")`

- **Create a migration**:
  1. `Skill("wheels-migration-generator")` (FIRST)
  2. `mcp__wheels__wheels_generate(type="migration", name="CreateUsersTable")`

- **Create tests**:
  1. `Skill("wheels-test-generator")` (FIRST)
  2. `mcp__wheels__wheels_generate(type="test", name="User")`

- **Create authentication**:
  1. `Skill("wheels-auth-generator")` (FIRST)
  2. Follow skill guidance for auth implementation

- **Create API**:
  1. `Skill("wheels-api-generator")` (FIRST)
  2. Follow skill guidance for API implementation

- **Run migrations**: `mcp__wheels__wheels_migrate(action="latest")`
- **Run tests**: `mcp__wheels__wheels_test()`
- **Reload application**: `mcp__wheels__wheels_reload()`
- **Check server status**: `mcp__wheels__wheels_server(action="status")`
- **Analyze project**: `mcp__wheels__wheels_analyze(target="all")`
- **Debug errors**: `Skill("wheels-debugging")`
- **Refactor code**: `Skill("wheels-refactoring")`

### ❌ Legacy CLI Commands (DO NOT USE if .mcp.json exists)
~~- Create a model: `wheels g model User name:string,email:string,active:boolean`~~
~~- Create a controller: `wheels g controller Users index,show,new,create,edit,update,delete`~~
~~- Create full scaffold: `wheels g scaffold Product name:string,price:decimal,instock:boolean`~~
~~- Run migrations: `wheels dbmigrate latest` `wheels dbmigrate up` `wheels dbmigrate down`~~
~~- Run tests: `wheels test run`~~
~~- Reload application: Visit `/?reload=true&password=yourpassword`~~

**⚠️ Only use CLI commands if:**
1. `.mcp.json` does not exist
2. MCP tools are not available
3. You are setting up a new Wheels project from scratch

## 🔍 MCP Workflow Validation

**Before proceeding with ANY development task, AI assistants MUST verify:**

### ✅ MCP Tools Checklist
1. **Check MCP availability**: `ls .mcp.json` (if exists → MCP is mandatory)
2. **Test MCP connection**: `mcp__wheels__wheels_server(action="status")`
3. **Verify MCP tools list**: `ListMcpResourcesTool(server="wheels")`

### 🚨 Enforcement Rules
- **If ANY of the following are detected, STOP and use MCP tools instead:**
  - Using `wheels g` commands
  - Using `wheels dbmigrate` commands
  - Using `wheels test` commands
  - Using `wheels server` commands
  - Using `curl` for Wheels operations
  - Using bash commands for Wheels development

### 🔄 Correct MCP Usage Pattern
```javascript
// 1. Always check server status first
mcp__wheels__wheels_server(action="status")

// 2. Use MCP tools for all operations
mcp__wheels__wheels_generate(type="model", name="User", attributes="name:string,email:string")
mcp__wheels__wheels_migrate(action="latest")
mcp__wheels__wheels_test()
mcp__wheels__wheels_reload()

// 3. Analyze results
mcp__wheels__wheels_analyze(target="all")
```

## 📚 MCP Tool Usage Examples

### 🎯 Complete Development Workflow Example
```javascript
// 1. Start every session by checking MCP availability
mcp__wheels__wheels_server(action="status")

// 2. Create a complete blog system - INVOKE SKILLS FIRST
Skill("wheels-model-generator")
// Wait for skill to load, then:
mcp__wheels__wheels_generate(type="model", name="Post", attributes="title:string,content:text,published:boolean")

Skill("wheels-controller-generator")
// Wait for skill to load, then:
mcp__wheels__wheels_generate(type="controller", name="Posts", actions="index,show,new,create,edit,update,delete")

Skill("wheels-view-generator")
// Wait for skill to load, then:
mcp__wheels__wheels_generate(type="view", name="posts/index")

Skill("wheels-migration-generator")
// Wait for skill to load, then:
mcp__wheels__wheels_migrate(action="latest")

// 3. Test and validate
Skill("wheels-test-generator")
// Wait for skill to load, then:
mcp__wheels__wheels_test()
mcp__wheels__wheels_analyze(target="all")

// 4. Browser testing (MANDATORY)
mcp__puppeteer__puppeteer_navigate(url="http://localhost:8080")
mcp__puppeteer__puppeteer_screenshot(name="homepage")

// 5. Reload when making configuration changes
mcp__wheels__wheels_reload()
```

### ❌ WRONG: CLI-Based Approach (DO NOT USE)
```bash
# These commands are FORBIDDEN when .mcp.json exists
wheels g model Post title:string,content:text,published:boolean
wheels g controller Posts index,show,new,create,edit,update,delete
wheels dbmigrate latest
wheels test run
curl "http://localhost:8080/?reload=true"
```

### ✅ CORRECT: MCP-Based Approach (MANDATORY)
```javascript
// Always use MCP tools - they provide better integration and error handling
mcp__wheels__wheels_generate(type="model", name="Post", attributes="title:string,content:text,published:boolean")
mcp__wheels__wheels_generate(type="controller", name="Posts", actions="index,show,new,create,edit,update,delete")
mcp__wheels__wheels_migrate(action="latest")
mcp__wheels__wheels_test()
mcp__wheels__wheels_reload()
```

### 🔍 Debugging with MCP Tools
```javascript
// Check project status
mcp__wheels__wheels_analyze(target="all", verbose=true)

// Check migrations
mcp__wheels__wheels_migrate(action="info")

// Validate models
mcp__wheels__wheels_validate(model="all")

// Check server status
mcp__wheels__wheels_server(action="status")
```

## Application Architecture

### MVC Framework Structure
Wheels follows the Model-View-Controller (MVC) architectural pattern:

- **Models** (`/app/models/`): Data layer with ActiveRecord ORM, validation, associations
- **Views** (`/app/views/`): Presentation layer with CFML templates, layouts, partials
- **Controllers** (`/app/controllers/`): Request handling, business logic coordination
- **Configuration** (`/config/`): Application settings, routes, environment configurations
- **Database** (`/app/migrator/migrations/`): Version-controlled schema changes
- **Assets** (`/public/`): Static files, CSS, JavaScript, images
- **Tests** (`/tests/`): TestBox unit and integration tests

### Directory Structure
```
/
├── app/                  (Application code)
│   ├── controllers/      (Request handlers)
│   ├── models/           (Data layer)
│   ├── views/            (Templates)
│   ├── migrator/         (Database migrations)
│   ├── events/           (Application events)
│   ├── global/           (Global functions)
│   ├── mailers/          (Email components)
│   ├── jobs/             (Background jobs)
│   ├── lib/              (Custom libraries)
│   ├── plugins/          (Third-party plugins)
│   └── snippets/         (Code templates)
├── config/               (Configuration files)
│   ├── app.cfm           (Application.cfc this scope settings)
│   ├── environment.cfm   (Current environment)
│   ├── routes.cfm        (URL routing)
│   ├── settings.cfm      (Framework settings)
│   └── [environment]/    (Environment-specific overrides)
├── public/               (Web-accessible files)
│   ├── files/            (User uploads, sendFile() content)
│   ├── images/           (Image assets)
│   ├── javascripts/      (JavaScript files)
│   ├── stylesheets/      (CSS files)
│   ├── miscellaneous/    (Miscellaneous files)
│   ├── Application.cfc   (Framework bootstrap)
│   └── index.cfm         (Entry point)
├── tests/                (Test files)
├── vendor/               (Dependencies)
├── .env                  (Environment variables - NEVER commit)
├── box.json              (Package configuration)
└── server.json           (CommandBox server configuration)
```

## Development Commands

### Code Generation
```bash
# Generate MVC components
wheels g model User name:string,email:string,active:boolean
wheels g controller Users index,show,new,create,edit,update,delete
wheels g view users/dashboard

# Generate full CRUD scaffold
wheels g scaffold Product name:string,price:decimal,instock:boolean

# Generate database migrations
wheels g migration CreateUsersTable
wheels g migration AddEmailToUsers --attributes="email:string:index"

# Generate other components
wheels g mailer UserNotifications --methods="welcome,passwordReset"
wheels g job ProcessOrders --queue=high
wheels g test model User
wheels g helper StringUtils
```

### Migration Management
```bash
# Check migration status
wheels dbmigrate info

# Migration to Latest
wheels dbmigrate latest

# Migration to version 0
wheels dbmigrate reset

# Migration one version UP
wheels dbmigrate up

# Migration one version DOWN
wheels dbmigrate down
```

### Server Management
```bash
# Start/stop development server
wheels server start
wheels server stop
wheels server restart

# View server status
wheels server status

# View server logs
wheels server log --follow
```

### Testing
```bash
# Run all tests
wheels test run
```

## Configuration Management

### Environment Settings
Set your environment in `/config/environment.cfm`:
```cfm
<cfscript>
    set(environment="development");
</cfscript>
```

**Available Environments:**
- `development` - Local development with debug info
- `testing` - Automated testing environment  
- `maintenance` - Maintenance mode with limited access
- `production` - Live production environment

### Framework Settings
Configure global settings in `/config/settings.cfm`:
```cfm
<cfscript>
    // Database configuration
    set(dataSourceName="myapp-dev");
    set(dataSourceUserName="username");
    set(dataSourcePassword="password");
    
    // URL rewriting
    set(URLRewriting="On");
    
    // Reload password
    set(reloadPassword="mypassword");
    
    // Error handling
    set(showErrorInformation=true);
    set(sendEmailOnError=false);
</cfscript>
```

### Environment-Specific Overrides
Create environment-specific settings in `/config/[environment]/settings.cfm`:
```cfm
// /config/production/settings.cfm
<cfscript>
    set(dataSourceName="myapp-prod");
    set(showErrorInformation=false);
    set(sendEmailOnError=true);
    set(cachePages=true);
</cfscript>
```

## URL Routing

### Default Route Pattern
URLs follow the pattern: `[controller]/[action]/[key]`

**Examples:**
- `/users` → `Users.cfc`, `index()` action
- `/users/show/12` → `Users.cfc`, `show()` action, `params.key = 12`

### Custom Routes
Define custom routes in `/config/routes.cfm`:
```cfm
<cfscript>
mapper()
    // Named routes
    .get(name="login", to="sessions##new")
    .post(name="authenticate", to="sessions##create")
    
    // RESTful resources
    .resources("users")
    .resources("products", except="destroy")

    // Nested resources - use separate declarations
    .resources("users")
    .resources("orders")
    
    // Root route
    .root(to="home##index", method="get")
    
    // Wildcard (keep last)
    .wildcard()
.end();
</cfscript>
```

### Route Helpers
```cfm
// Link generation
#linkTo(route="user", key=user.id, text="View User")#
#linkTo(controller="products", action="index", text="All Products")#

// Form generation
#startFormTag(route="user", method="put", key=user.id)#

// URL generation
#urlFor(route="users")#

// Redirects in controllers
redirectTo(route="user", key=user.id);
```

## Model-View-Controller Patterns

### Controller Structure
```cfm
component extends="Controller" {

    function config() {
        // Filters for authentication/authorization
        filters(through="authenticate", except="index");
        filters(through="findUser", only="show,edit,update,delete");
        
        // Parameter verification
        verifies(except="index,new,create", params="key", paramsTypes="integer");
        
        // Content type support
        provides("html,json");
    }

    function index() {
        users = model("User").findAll(order="createdat DESC");
    }

    function create() {
        user = model("User").new(params.user);
        
        if (user.save()) {
            redirectTo(route="user", key=user.id, success="User created!");
        } else {
            renderView(action="new");
        }
    }

    private function authenticate() {
        if (!session.authenticated) {
            redirectTo(controller="sessions", action="new");
        }
    }

    function sendWelcomeEmail() {
        sendEmail(
            template="users/welcome",
            from="noreply@myapp.com",
            to=user.email,
            subject="Welcome to MyApp!",
            user=user
        );
    }

    function downloadReport() {
        sendFile(
            file="report.pdf",
            name="Monthly Report.pdf",
            type="application/pdf",
            disposition="attachment",
            directory="/reports/"
        );
    }

    function requireSSL() {
        if (!isSecure()) {
            redirectTo(protocol="https");
        }
    }
}
```

### Model Structure
```cfm
component extends="Model" {

    function config() {
        // Associations
        hasMany("orders");
        belongsTo("role");
        
        // Validations
        validatesPresenceOf("firstname,lastname,email");
        validatesUniquenessOf(property="email");
        validatesFormatOf(property="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");
        
        // Callbacks
        beforeSave("hashPassword");
        afterCreate("sendWelcomeEmail");

        // Nested properties for associations
        nestedProperties(association="addresses", allowDelete=true, autoSave=true);

        // Custom finder methods (Wheels doesn't have scope() - use custom finder methods instead)
    }

    function findByEmail(required string email) {
        return findOne(where="email = '#arguments.email#'");
    }

    function findActive() {
        return findAll(where="active = 1");
    }

    function findFirst() {
        return findFirst(property="createdAt");
    }

    function fullName() {
        return trim("#firstname# #lastname#");
    }

    function reload() {
        // Reload this model instance from the database
        return super.reload();
    }
}
```

### View Structure
```cfm
<!-- Layout: /app/views/layout.cfm -->
<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    #csrfMetaTags()#
    <title>#contentFor("title", "MyApp")#</title>
    #styleSheetLinkTag("application")#
</head>
<body>
    <main>
        #flashMessages()#
        #includeContent()#
    </main>
    #javaScriptIncludeTag("application")#
</body>
</html>
</cfoutput>

<!-- View: /app/views/users/index.cfm -->
<cfparam name="users">
<cfoutput>
#contentFor("title", "Users")#

<h1>Users</h1>
#linkTo(route="newUser", text="New User", class="btn btn-primary")#

<cfif users.recordCount>
    <table class="table">
        <cfloop query="users">
        <tr>
            <td>#linkTo(route="user", key=users.id, text=users.firstname)#</td>
            <td>#users.email#</td>
            <td>
                #linkTo(route="editUser", key=users.id, text="Edit")#
                #buttonTo(route="user", method="delete", key=users.id, 
                         text="Delete", confirm="Are you sure?")#
            </td>
        </tr>
        </cfloop>
    </table>
<cfelse>
    <p>No users found.</p>
</cfif>
</cfoutput>
```

## Database Migrations

### Migration Workflow
```bash
# Generate new migration
wheels g migration CreateUsersTable

# Generate migration with attributes
wheels g migration AddEmailToUsers --attributes="email:string:index"

# Run pending migrations
wheels dbmigrate latest

# Rollback migrations
wheels dbmigrate down
```

### Migration Example
```cfm
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            t = createTable(name="users", force=false);
            t.string(columnNames="firstName,lastName", allowNull=false);
            t.string(columnNames="email", limit=100, allowNull=false);
            t.boolean(columnNames="active", default=true);
            t.timestamps();
            t.create();
            
            addIndex(table="users", columnNames="email", unique=true);
        }
    }

    function down() {
        dropTable("users");
    }
}
```

### Column Types
```cfm
t.string(columnNames="name", limit=255, allowNull=false, default="");
t.text(columnNames="description", allowNull=true);
t.integer(columnNames="count", allowNull=false, default=0);
t.decimal(columnNames="price", precision=10, scale=2);
t.boolean(columnNames="active", default=false);
t.date(columnNames="eventDate");
t.datetime(columnNames="createdAt"); // Use for createdAt/updatedAt only when not using timestamps(); OK for other columns
t.timestamps();  // Creates createdAt and updatedAt
t.integer(columnNames="userId", allowNull=false);  // Foreign key
```

### Advanced Migration Features

```cfm
// Create database views
component extends="wheels.migrator.Migration" {
    function up() {
        v = createView(name="activeUsers");
        v.sql("SELECT id, name, email FROM users WHERE active = 1");
        v.create();
    }
}

// Modify existing tables
component extends="wheels.migrator.Migration" {
    function up() {
        t = changeTable(name="users");
        t.string(columnNames="middleName", limit=100);
        t.change();

        // Add indexes
        addIndex(table="users", columnNames="email", unique=true);
        addIndex(table="users", columnNames="lastName,firstName");

        // Rename tables
        renameTable(oldName="user_profiles", newName="profiles");
    }

    function down() {
        removeIndex(table="users", indexName="users_email");
        removeIndex(table="users", indexName="users_lastName_firstName");
        renameTable(oldName="profiles", newName="user_profiles");

        t = changeTable(name="users");
        t.removeColumn(columnNames="middleName");
        t.change();
    }
}
```

## Testing

### Test Structure
```
tests/
├── Test.cfc               (Base test component)
├── controllers/           (Controller tests)
├── models/                (Model tests)
└── integration/           (Integration tests)
```

### Model Testing
```cfm
component extends="wheels.Testbox" {

    function beforeAll() {
        // Setup for all tests in this spec
        variables.testData = {};
    }

    function afterAll() {
        // Cleanup after all tests
    }

    function beforeEach() {
        // Setup before each test
        variables.user = "";
    }

    function afterEach() {
        // Cleanup after each test
        if (isObject(variables.user)) {
            variables.user.delete();
        }
    }

    function run() {
        describe("User Model", function() {
            
            it("should be invalid when no data provided", function() {
                var user = model("User").new();
                expect(user.valid()).toBeFalse("User should be invalid without data");
                expect(arrayLen(user.allErrors())).toBeGT(0, "Should have validation errors");
            });

            it("should create user with valid data", function() {
                var userData = {
                    firstname = "John",
                    lastname = "Doe", 
                    email = "john@example.com"
                };
                
                var user = model("User").create(userData);
                
                expect(isObject(user)).toBeTrue("Should return user object");
                expect(user.valid()).toBeTrue("User should be valid");
                expect(user.firstname).toBe("John", "Should set firstname correctly");
            });
        });
    }
}
```

## Security Best Practices

### CSRF Protection
```cfm
// In controllers
function config() {
    protectsFromForgery(); // Enable CSRF protection
}

// In forms
#startFormTag(route="user", method="put", key=user.id)#
    #hiddenFieldTag("authenticityToken", authenticityToken())#
    <!-- form fields -->
#endFormTag()#

// In layout head
#csrfMetaTags()#
```

### Input Validation
```cfm
// Parameter verification
function config() {
    verifies(only="show,edit,update,delete", params="key", paramsTypes="integer");
    verifies(only="create,update", params="user", paramsTypes="struct");
}

// Model validation
function config() {
    validatesPresenceOf("firstname,lastname,email");
    validatesFormatOf(property="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");
    validatesLengthOf(property="password", minimum=8);
}
```

### SQL Injection Prevention
```cfm
// Use model methods (automatically sanitized)
users = model("User").findAll(where="email = '#params.email#'");

// Or use cfqueryparam in custom queries
sql = "SELECT * FROM users WHERE email = :email";
users = queryExecute(sql, { email = { value = params.email, cfsqltype = "cf_sql_varchar" } }, {datasource = yourDatasourceName});
```

## Performance Optimization

### Caching
```cfm
// Page caching
function config() {
    caches(action="index", time=30); // Cache for 30 minutes
}

// Query caching
users = model("User").findAll(cache=60); // Cache for 60 minutes
```

### Database Optimization
```cfm
// Use includes to avoid N+1 queries
users = model("User").findAll(include="role,orders");

// Use select to limit columns
users = model("User").findAll(select="id,firstname,lastname,email");

// Use pagination
users = model("User").findAll(page=params.page, perPage=25);
```

## Deployment

### Production Configuration
```cfm
// /config/production/settings.cfm
<cfscript>
    // Database
    set(dataSourceName="myapp-prod");
    
    // Security
    set(showErrorInformation=false);
    set(sendEmailOnError=true);
    
    // Performance
    set(cachePages=true);
    set(cachePartials=true);
    set(cacheQueries=true);
</cfscript>
```

### Environment Variables
Use `.env` file for sensitive configuration (never commit to version control):
```bash
# .env
DATABASE_URL=mysql://user:pass@localhost:3306/myapp_prod
SMTP_HOST=smtp.example.com
API_KEY=your-secret-api-key
```

Access in configuration:
```cfm
<cfscript>
    if (FileExists(ExpandPath("/.env"))) {
        set(dataSourceName=GetEnv("DATABASE_NAME"));
        set(dataSourceUserName=GetEnv("DATABASE_USER"));
        set(dataSourcePassword=GetEnv("DATABASE_PASSWORD"));
    }
</cfscript>
```

## 🚨 MANDATORY: Native MCP Server

**This Wheels application includes a native CFML MCP (Model Context Protocol) server that MUST be used by AI assistants for all development tasks.**

**🔴 CRITICAL RULE: If `.mcp.json` exists, ALL development MUST use MCP tools - no exceptions.**

The MCP server eliminates the need for Node.js dependencies and provides AI coding assistants with direct, integrated access to your Wheels application.

### Accessing the MCP Server

The MCP server is available at `/wheels/mcp` and supports:
- **Resources**: Documentation, guides, project context, patterns
- **Tools**: Code generation (models, controllers, views, migrations)
- **Prompts**: Context-aware help for Wheels development

### MCP Client Configuration

Configure your AI coding assistant to use the native MCP server:

```json
{
  "mcpServers": {
    "wheels": {
      "type": "http",
      "url": "http://localhost:8080/wheels/mcp"
    }
  }
}
```

Replace `8080` with your development server port.

### Available Tools

- `wheels_generate` - Generate components (models, controllers, etc.)
- `wheels_migrate` - Run database migrations
- `wheels_test` - Execute tests
- `wheels_server` - Manage development server
- `wheels_reload` - Reload application

### Route Configuration

The MCP server routes are pre-configured in the Wheels framework at `/vendor/wheels/public/routes.cfm`:

```cfm
// Framework routes in wheels namespace
.get(name = "mcp", pattern = "mcp", to = "public##mcp")
.post(name = "mcpPost", pattern = "mcp", to = "public##mcp")
```

**IMPORTANT:** These are framework routes (in the `wheels` namespace) and should **NOT** be added to your application's `/config/routes.cfm`. The MCP server is automatically available at `/wheels/mcp` without any application configuration needed.

#### Framework vs Application Routes

**Framework Routes** (`/vendor/wheels/public/routes.cfm`):
- Pre-configured routes for Wheels internal functionality
- Include: `/wheels/mcp`, `/wheels/migrator`, `/wheels/api`, `/wheels/info`, etc.
- Automatically available in all Wheels applications
- Should NOT be duplicated in application routes

**Application Routes** (`/config/routes.cfm`):
- Your custom application routes
- Business logic controllers and actions
- Custom API endpoints and resource routes
- This is where you define your application-specific routing

## Common Patterns

### Service Layer Pattern
```cfm
// /app/lib/UserService.cfc
component {
    
    function createUser(required struct userData) {
        local.user = model("User").new(arguments.userData);
        
        transaction {
            if (local.user.save()) {
                sendWelcomeEmail(local.user);
                return local.user;
            } else {
                transaction action="rollback";
                return false;
            }
        }
    }
}
```

### API Development
```cfm
// API base controller
component extends="wheels.Controller" {
    
    function config() {
        provides("json");
        filters(through="authenticate");
    }
    
    private function authenticate() {
        // API authentication logic
    }
}

// API endpoint
function index() {
    users = model("User").findAll();
    renderWith(data={users=users});
}
```

### Error Handling
```cfm
// Global error handler in Application.cfc
function onError(exception, eventname) {
    if (get("environment") == "production") {
        WriteLog(file="application", text=exception.message, type="error");
        include "/app/views/errors/500.cfm";
    } else {
        return true; // Let ColdFusion handle it
    }
}
```

## Common Issues and Troubleshooting

### Association Errors
**"Missing argument name" in hasMany()**
This error occurs when mixing positional and named parameters in Wheels function calls:

❌ **Incorrect (mixed parameter styles):**
```cfm
hasMany("comments", dependent="delete");  // Error: can't mix positional and named
```

✅ **Correct (consistent named parameters):**
```cfm
hasMany(name="comments", dependent="delete");
```

✅ **Also correct (all positional):**
```cfm
hasMany("comments");
```

Wheels requires consistent parameter syntax - either all positional or all named parameters.

### Routing Issues
**Incorrect .resources() syntax**
Wheels resource routing syntax differs from Rails:

❌ **Incorrect (Rails-style nested):**
```cfm
.resources("posts", function(nested) {
    nested.resources("comments");
})
```

✅ **Correct (separate declarations):**
```cfm
.resources("posts")
.resources("comments")
```

**Route ordering matters:** resources → custom routes → root → wildcard

### Form Helper Limitations
Wheels has more limited form helpers compared to Rails:

❌ **Not available:**
```cfm
#emailField()#    // Doesn't exist
#label(text="Name")#    // text parameter not supported
```

✅ **Use instead:**
```cfm
#textField(type="email")#
<label>Name</label>
```

### Migration Data Seeding
Parameter binding in migrations can be unreliable. Use direct SQL:

❌ **Problematic:**
```cfm
execute(sql="INSERT INTO posts (title) VALUES (?)", parameters=[{value=title}]);
```

✅ **Reliable:**
```cfm
execute("INSERT INTO posts (title, createdAt, updatedAt) VALUES ('My Post', NOW(), NOW())");
```

### Debugging Tips
1. **Invoke `Skill("wheels-debugging")` when encountering errors**
2. Check Wheels documentation - don't assume Rails conventions work
3. Use simple patterns first, add complexity incrementally
4. Test associations and routes in isolation
5. Use `?reload=true` after configuration changes
6. Check debug footer for route information

## Summary: Complete AI Assistant Workflow

**🚨 MANDATORY: Follow this exact workflow for ALL Wheels development tasks**

### The 5-Step Mandatory Process

1. **🔧 Check MCP Tools** (STEP 1)
   - Verify `.mcp.json` exists
   - Test MCP server connection
   - Confirm MCP tools are available

2. **🎯 Invoke Claude Code Skill** (STEP 3)
   - **ALWAYS FIRST** before code generation
   - Select appropriate skill for task:
     - Models → `Skill("wheels-model-generator")`
     - Controllers → `Skill("wheels-controller-generator")`
     - Views → `Skill("wheels-view-generator")`
     - Migrations → `Skill("wheels-migration-generator")`
     - Tests → `Skill("wheels-test-generator")`
     - Auth → `Skill("wheels-auth-generator")`
     - API → `Skill("wheels-api-generator")`
     - Debugging → `Skill("wheels-debugging")`
     - Refactoring → `Skill("wheels-refactoring")`
     - Deployment → `Skill("wheels-deployment")`
   - Wait for skill to load and provide guidance
   - Follow skill's framework-specific patterns

3. **📖 Load Documentation** (STEP 4, if needed)
   - Read relevant `.ai/` documentation
   - Or use MCP resources
   - Validate against established patterns

4. **💻 Generate Code with MCP Tools** (After skill validation)
   - Use MCP tools exclusively (NO CLI commands)
   - Follow skill guidance for proper patterns
   - Examples:
     - `mcp__wheels__wheels_generate(...)`
     - `mcp__wheels__wheels_migrate(...)`
     - `mcp__wheels__wheels_test()`

5. **🌐 Test in Browser** (STEP 5 - MANDATORY)
   - Check server status
   - Navigate to application
   - Screenshot homepage
   - Test all user flows
   - Verify interactive elements
   - Document results

### Critical Rules

**✅ ALWAYS:**
- Invoke appropriate Claude Code skill BEFORE code generation
- Use MCP tools when `.mcp.json` exists
- Test in browser after ANY development work
- Follow Wheels-specific patterns from skills
- Validate against framework conventions

**❌ NEVER:**
- Skip skill invocation for code generation
- Use CLI commands when MCP tools are available
- Skip browser testing
- Mix positional and named parameters in Wheels functions
- Assume Rails conventions work in Wheels
- Skip the anti-pattern detector skill

### Example: Creating a Blog Post Feature

```javascript
// ✅ CORRECT WORKFLOW
// 1. Check MCP
mcp__wheels__wheels_server(action="status")

// 2. Model - Invoke skill FIRST
Skill("wheels-model-generator")
// Then generate:
mcp__wheels__wheels_generate(type="model", name="Post", attributes="title:string,content:text")

// 3. Controller - Invoke skill FIRST
Skill("wheels-controller-generator")
// Then generate:
mcp__wheels__wheels_generate(type="controller", name="Posts", actions="index,show,new,create")

// 4. Views - Invoke skill FIRST
Skill("wheels-view-generator")
// Then generate:
mcp__wheels__wheels_generate(type="view", name="posts/index")

// 5. Migration - Invoke skill FIRST
Skill("wheels-migration-generator")
// Then migrate:
mcp__wheels__wheels_migrate(action="latest")

// 6. Browser test (MANDATORY)
mcp__puppeteer__puppeteer_navigate(url="http://localhost:8080/posts")
mcp__puppeteer__puppeteer_screenshot(name="posts_index")
```

**Following this workflow ensures:**
- ✅ Proper Wheels conventions and patterns
- ✅ Prevention of common framework errors
- ✅ CFML syntax correctness
- ✅ Comprehensive browser validation
- ✅ Production-ready code quality