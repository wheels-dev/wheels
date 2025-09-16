# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) and other AI coding assistants when working with a Wheels application.

## AI Documentation Endpoints

When the development server is running, you can access enhanced documentation:
- **Full Documentation**: `/wheels/ai` - Optimized for AI consumption
- **Documentation Manifest**: `/wheels/ai?action=manifest` - Lists available documentation chunks
- **Project Context**: `/wheels/ai?action=project` - Current project structure and configuration
- **Specific Chunks**: `/wheels/ai?action=chunk&id=models` - Get focused documentation (models, controllers, views, etc.)

### Available Documentation Contexts
- `all` - Complete documentation (default)
- `model` - Model-specific documentation
- `controller` - Controller-specific documentation
- `view` - View helpers and templating
- `migration` - Database migration documentation
- `routing` - URL routing and RESTful resources
- `testing` - Testing framework documentation

## Quick Start

### New to Wheels?
1. **Install Wheels CLI**: `brew install wheels` on Mac and `choco install wheels` on Windows
2. **Generate an app**: `wheels g app myapp`
3. **Start developing**: `wheels server start`

### Common Development Tasks
- **Create a model**: `wheels g model User name:string,email:string,active:boolean`
- **Create a controller**: `wheels g controller Users index,show,new,create,edit,update,delete`
- **Create full scaffold**: `wheels g scaffold Product name:string,price:decimal,instock:boolean`
- **Run migrations**: `wheels dbmigrate latest` `wheels dbmigrate up` `wheels dbmigrate down`
- **Run tests**: `wheels test run`
- **Reload application**: Visit `/?reload=true&password=yourpassword`

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
    
    // Nested resources
    .resources("users", function(nested) {
        nested.resources("orders");
    })
    
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

        // Custom finder methods (CFWheels doesn't have scope() - use custom finder methods instead)
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
            t.string(columnNames="firstName,lastName", null=false);
            t.string(columnNames="email", limit=100, null=false);
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
t.decimal("price", precision=10, scale=2);
t.boolean(columnNames="active", default=false);
t.date("eventDate");
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
component extends="testbox.system.BaseSpec" {

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

// Or use cfqueryparam in raw queries
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

## AI Agent Integration

### MCP (Model Context Protocol) Support
Wheels includes an MCP server for integration with AI coding assistants that support the protocol:

1. **Installation**:
   ```bash
   cd /path/to/wheels
   npm install @modelcontextprotocol/sdk
   ```

2. **Configuration**: Use `mcp-server-wheels.json` for Claude Code, Cursor, or Continue
3. **Available Resources**: API docs, guides, project context, patterns
4. **Available Tools**: Generate components, run migrations, manage server

### Best Practices for AI-Assisted Development

1. **Start with Context**: Always check `/wheels/ai?action=project` to understand the current project
2. **Use Focused Documentation**: Request specific chunks (`/wheels/ai?action=chunk&id=models`) for the task at hand
3. **Follow Conventions**: Wheels has strong conventions - models are singular, controllers are plural
4. **Test Generated Code**: Always run `wheels test run` after generating code
5. **Use Generators**: Prefer `wheels g` commands over manual file creation

### Optimizing for Context Windows

When working with limited context windows:
1. Use the manifest endpoint to discover available chunks
2. Load only relevant documentation chunks for your current task
3. The project context endpoint provides a concise overview
4. Common patterns are available separately for quick reference

### Integration with Popular AI Tools

#### Claude Code
- This CLAUDE.md file is automatically loaded
- Use the `/wheels/ai` endpoints when the dev server is running
- MCP server provides deeper integration

#### GitHub Copilot
- Reference this file in your workspace
- Comments referencing Wheels patterns help Copilot suggestions

#### Cursor / Continue
- Configure MCP server using the provided configuration
- Access Wheels tools directly from the AI interface

#### Custom Integration
- All documentation endpoints return JSON
- Use `/wheels/ai?action=manifest` to discover available resources
- Implement your own MCP client using the provided server

## Native CFML MCP Server

Wheels now includes a native CFML implementation of the Model Context Protocol (MCP) server, eliminating the need for Node.js. This server runs directly within your Wheels application and provides full MCP functionality.

### MCP Server Endpoint

The MCP server is available at `/wheels/mcp` and supports:

- **Streamable HTTP Transport**: Standard MCP transport over HTTP
- **JSON-RPC 2.0 Protocol**: Full compliance with MCP specification
- **Session Management**: Persistent sessions with `Mcp-Session-Id` headers
- **CORS Support**: Cross-origin requests for web-based MCP clients

### Supported Request Methods

**Server-Sent Events (SSE)**:
```bash
curl -H "Accept: text/event-stream" http://localhost:8080/wheels/mcp
```

**JSON-RPC Requests**:
```bash
curl -X POST http://localhost:8080/wheels/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"resources/list","params":{},"id":1}'
```

**Testing via Query Parameters** (for environments with routing restrictions):
```bash
curl "http://localhost:8080/wheels/mcp?method=POST&body=..." \
  -H "Accept: application/json"
```

### Available MCP Methods

#### Resources
- `resources/list` - List all available Wheels resources
- `resources/read` - Read specific resource content

Available resources:
- `wheels://api/documentation` - Complete API documentation
- `wheels://guides/all` - All framework guides and tutorials
- `wheels://project/context` - Current project structure and configuration
- `wheels://patterns/common` - Common Wheels patterns and best practices

#### Tools
- `tools/list` - List all available Wheels tools
- `tools/call` - Execute Wheels CLI commands

Available tools:
- `wheels_generate` - Generate models, controllers, views, migrations, etc.
- `wheels_migrate` - Run database migrations (latest, up, down, reset, info)
- `wheels_test` - Run Wheels tests
- `wheels_server` - Manage development server (start, stop, restart, status)
- `wheels_reload` - Reload the Wheels application

#### Prompts
- `prompts/list` - List all available prompts
- `prompts/get` - Get specific prompt templates

Available prompts:
- `wheels_model_help` - Get help with Wheels model development
- `wheels_controller_help` - Get help with Wheels controller development
- `wheels_migration_help` - Get help with database migrations

### MCP Client Configuration

#### Claude Desktop
```json
{
  "mcpServers": {
    "wheels": {
      "transport": {
        "type": "http",
        "url": "http://localhost:8080/wheels/mcp"
      }
    }
  }
}
```

#### Continue / Cursor
```json
{
  "mcpServers": {
    "wheels": {
      "transport": {
        "type": "http",
        "url": "http://localhost:8080/wheels/mcp"
      }
    }
  }
}
```

### Example Usage

**Initialize MCP Connection**:
```json
{
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {"resources": {}, "tools": {}, "prompts": {}},
    "clientInfo": {"name": "my-client", "version": "1.0.0"}
  },
  "id": 1
}
```

**List Available Resources**:
```json
{
  "jsonrpc": "2.0",
  "method": "resources/list",
  "params": {},
  "id": 2
}
```

**Generate a Model**:
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "wheels_generate",
    "arguments": {
      "type": "model",
      "name": "User",
      "attributes": "name:string,email:string,active:boolean"
    }
  },
  "id": 3
}
```

### Architecture

The native CFML MCP server consists of:

- **`/wheels/mcp` endpoint** - Main HTTP handler in `Public.cfc`
- **`wheels.public.mcp.McpServer`** - Core JSON-RPC message processor
- **`wheels.public.mcp.SessionManager`** - Session state management
- **`wheels.public.views.mcp.cfm`** - Transport layer implementation

### Benefits

- **No Node.js Dependency**: Runs entirely within the CFML engine
- **Integrated with Wheels**: Direct access to all framework functionality
- **Standard Compliant**: Full MCP protocol implementation
- **Easy to Deploy**: No additional processes or dependencies
- **Secure**: Runs within your application's security context
- **Performant**: Direct CFML execution without inter-process communication

This native implementation provides the same functionality as the Node.js MCP server while being fully integrated with your Wheels application and eliminating external dependencies.