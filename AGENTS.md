# AGENTS.md

Guidance for AI coding assistants working with Wheels (CFML MVC framework).

## Before You Start

### 1. Check for MCP Tools

If `.mcp.json` exists in the project root, prefer MCP tools (`mcp__wheels__*`) over CLI commands for generation, migration, testing, and reload operations.

| Task | MCP Tool | CLI Fallback |
|------|----------|-------------|
| Generate | `wheels_generate(type, name, attributes)` | `wheels g model/controller/scaffold Name attrs` |
| Migrate | `wheels_migrate(action="latest\|up\|down\|info")` | `wheels dbmigrate latest\|up\|down\|info` |
| Test | `wheels_test()` | `wheels test run` |
| Reload | `wheels_reload()` | `?reload=true&password=...` |
| Server | `wheels_server(action="status")` | `wheels server start\|stop\|status` |
| Analyze | `wheels_analyze(target="all")` | — |

### 2. Load Reference Documentation

The `.ai/` directory contains searchable reference docs:
- **Models**: `.ai/wheels/models/`, `.ai/wheels/database/`
- **Controllers**: `.ai/wheels/controllers/`
- **Views**: `.ai/wheels/views/`
- **CFML syntax**: `.ai/cfml/syntax/`, `.ai/cfml/best-practices/`
- **Patterns**: `.ai/wheels/patterns/`, `.ai/wheels/snippets/`
- **Cross-engine rules**: `.ai/wheels/cross-engine-compatibility.md`

### MCP Slash Commands

When the Wheels MCP server is available, these slash commands provide streamlined workflows:

- `/wheels-develop` — End-to-end development (task, verbose, skip_browser_test)
- `/wheels-generate` — Generate components (type, name, attributes, actions)
- `/wheels-migrate` — Run migrations (action: latest, up, down, reset, info)
- `/wheels-test` — Run tests (target, verbose)
- `/wheels-server` — Server management (action: start, stop, restart, status)
- `/wheels-reload` — Reload application (password)
- `/wheels-analyze` — Analyze project (target: models, controllers, routes, migrations, tests, all)

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

        // Query scopes — reusable, composable query fragments
        scope(name="active", where="status = 'active'");
        scope(name="recent", order="createdAt DESC");
        scope(name="byRole", handler="scopeByRole");

        // Enums — named values with auto-generated checkers and scopes
        enum(property="status", values="draft,published,archived");
    }

    // Dynamic scope handler
    private struct function scopeByRole(required string role) {
        return {where: "role = '#arguments.role#'"};
    }

    function fullName() {
        return trim("#firstname# #lastname#");
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
component extends="wheels.WheelsTest" {

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

## Native MCP Server

Wheels includes a built-in CFML MCP server at `/wheels/mcp`. When available, MCP tools provide better integration than CLI commands.

### Client Configuration

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

Replace `8080` with your development server port. MCP routes must come before `.wildcard()` in `config/routes.cfm`.

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
**Nested resources syntax**
Wheels supports nested resources via the `callback` parameter:

❌ **Incorrect (Rails-style inline function block):**
```cfm
.resources("posts", function(r) { r.resources("comments"); })
```

✅ **Correct (callback syntax — recommended):**
```cfm
.resources(name="posts", callback=function(map) {
    map.resources("comments");
})
```

✅ **Also correct (flat separate declarations — no URL nesting):**
```cfm
.resources("posts")
.resources("comments")
```

**Route ordering matters:** MCP routes → resources → custom routes → root → wildcard (last!)

### HTML5 Form Helpers
Wheels includes dedicated HTML5 input helpers. Use them directly:

```cfm
// Object-bound helpers
#emailField(objectName="user", property="email")#
#urlField(objectName="user", property="website")#
#numberField(objectName="product", property="quantity", min="1", max="100")#
#telField(objectName="user", property="phone")#
#dateField(objectName="event", property="startDate")#
#colorField(objectName="theme", property="primaryColor")#
#rangeField(objectName="settings", property="volume", min="0", max="100")#
#searchField(objectName="search", property="query")#

// Tag-based helpers (not bound to an object)
#emailFieldTag(name="email", value="")#
#numberFieldTag(name="qty", value="1", min="0", step="1")#
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
1. Check Wheels documentation - don't assume Rails conventions work
2. Use simple patterns first, add complexity incrementally
3. Test associations and routes in isolation
4. Use `?reload=true` after configuration changes
5. Check debug footer for route information