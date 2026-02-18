# Wheels Framework

CFML MVC framework with ActiveRecord ORM. Models in `app/models/`, controllers in `app/controllers/`, views in `app/views/`, migrations in `app/migrator/migrations/`, config in `config/`, tests in `tests/`.

## Directory Layout

```
app/controllers/    app/models/    app/views/    app/views/layout.cfm
app/migrator/migrations/    app/events/    app/global/    app/lib/
app/mailers/    app/jobs/    app/plugins/    app/snippets/
config/settings.cfm    config/routes.cfm    config/environment.cfm
public/    tests/    vendor/    .env (never commit)
```

## Development Tools

Prefer MCP tools when the Wheels MCP server is available (`mcp__wheels__*`). Fall back to CLI otherwise.

| Task | MCP | CLI |
|------|-----|-----|
| Generate | `wheels_generate(type, name, attributes)` | `wheels g model/controller/scaffold Name attrs` |
| Migrate | `wheels_migrate(action="latest\|up\|down\|info")` | `wheels dbmigrate latest\|up\|down\|info` |
| Test | `wheels_test()` | `wheels test run` |
| Reload | `wheels_reload()` | `?reload=true&password=...` |
| Server | `wheels_server(action="status")` | `wheels server start\|stop\|status` |
| Analyze | `wheels_analyze(target="all")` | — |

## Critical Anti-Patterns (Top 10)

These are the most common mistakes when generating Wheels code. Check every time.

### 1. Mixed Argument Styles
Wheels functions cannot mix positional and named arguments. This is the #1 error source.
```cfm
// WRONG — mixed positional + named
hasMany("comments", dependent="delete");
validatesPresenceOf("name", message="Required");

// RIGHT — all named when using options
hasMany(name="comments", dependent="delete");
validatesPresenceOf(properties="name", message="Required");

// RIGHT — positional only (no options)
hasMany("comments");
validatesPresenceOf("name");
```

### 2. Query vs Array Confusion in Views
Model finders return query objects, not arrays. Loop accordingly.
```cfm
// WRONG
<cfloop array="#users#" index="user">

// RIGHT
<cfloop query="users">
    #users.firstName#
</cfloop>
```

### 3. No Nested Resource Routes
Wheels does not support Rails-style nested resource blocks.
```cfm
// WRONG
.resources("posts", function(r) { r.resources("comments"); })

// RIGHT — separate declarations
.resources("posts")
.resources("comments")
```

### 4. Non-Existent Form Helpers
These helpers don't exist in Wheels: `emailField()`, `urlField()`, `numberField()`, `phoneField()`.
```cfm
// WRONG
#emailField(objectName="user", property="email")#

// RIGHT
#textFieldTag(name="user[email]", type="email", value=user.email)#
```

### 5. Migration Seed Data — Use Direct SQL
Parameter binding in `execute()` is unreliable. Use inline SQL for seed data.
```cfm
// WRONG
execute(sql="INSERT INTO roles (name) VALUES (?)", parameters=[{value="admin"}]);

// RIGHT
execute("INSERT INTO roles (name, createdAt, updatedAt) VALUES ('admin', NOW(), NOW())");
```

### 6. Route Order Matters
Routes are matched first-to-last. Wrong order = wrong matches.
```
Order: MCP routes → resources → custom named routes → root → wildcard (last!)
```

### 7. timestamps() Includes createdAt and updatedAt
Don't also add separate datetime columns for these.
```cfm
// WRONG — duplicates
t.timestamps();
t.datetime(columnNames="createdAt");

// RIGHT
t.timestamps();  // creates both createdAt and updatedAt
```

### 8. Database-Agnostic Dates in Migrations
Use `NOW()` — it works across MySQL, PostgreSQL, SQL Server, H2.
```cfm
// WRONG — database-specific
execute("INSERT INTO users (name, createdAt) VALUES ('Admin', CURRENT_TIMESTAMP)");

// RIGHT
execute("INSERT INTO users (name, createdAt, updatedAt) VALUES ('Admin', NOW(), NOW())");
```

### 9. Controller Filters Must Be Private
Filter functions (authentication, data loading) must be declared `private`.
```cfm
// WRONG — public filter becomes a routable action
function authenticate() { ... }

// RIGHT
private function authenticate() { ... }
```

### 10. Always cfparam View Variables
Every variable passed from controller to view needs a cfparam declaration.
```cfm
// At top of every view file
<cfparam name="users" default="">
<cfparam name="user" default="">
```

## Wheels Conventions

- **config()**: All model associations/validations/callbacks and controller filters/verifies go in `config()`
- **Naming**: Models are singular PascalCase (`User.cfc`), controllers are plural PascalCase (`Users.cfc`), table names are plural lowercase (`users`)
- **Parameters**: `params.key` for URL key, `params.user` for form struct, `params.user.firstName` for nested
- **extends**: Models extend `"Model"`, controllers extend `"Controller"`, tests extend `"wheels.Test"` or `"wheels.Testbox"`
- **Associations**: All named params when using options: `hasMany(name="orders")`, `belongsTo(name="user")`, `hasOne(name="profile")`
- **Validations**: Property param is `property` (singular) for single, `properties` (plural) for list: `validatesPresenceOf(properties="name,email")`

## Model Quick Reference

```cfm
component extends="Model" {
    function config() {
        // Table/key (only if non-conventional)
        tableName("tbl_users");
        setPrimaryKey("userId");

        // Associations — all named params when using options
        hasMany(name="orders", dependent="delete");
        belongsTo(name="role");

        // Validations
        validatesPresenceOf("firstName,lastName,email");
        validatesUniquenessOf(property="email");
        validatesFormatOf(property="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");

        // Callbacks
        beforeSave("sanitizeInput");
    }
}
```

Finders: `model("User").findAll()`, `model("User").findOne(where="...")`, `model("User").findByKey(params.key)`.
Create: `model("User").new(params.user)` then `.save()`, or `model("User").create(params.user)`.
Include associations: `findAll(include="role,orders")`. Pagination: `findAll(page=params.page, perPage=25)`.

## Routing Quick Reference

```cfm
// config/routes.cfm
mapper()
    .resources("users")                              // standard CRUD
    .resources("products", except="delete")           // skip actions
    .get(name="login", to="sessions##new")           // named route
    .post(name="authenticate", to="sessions##create")
    .root(to="home##index", method="get")            // homepage
    .wildcard()                                       // keep last!
.end();
```

Helpers: `linkTo(route="user", key=user.id, text="View")`, `urlFor(route="users")`, `redirectTo(route="user", key=user.id)`, `startFormTag(route="user", method="put", key=user.id)`.

## Testing Quick Reference

```cfm
component extends="wheels.Testbox" {
    function run() {
        describe("User", function() {
            it("validates presence of name", function() {
                var user = model("User").new();
                expect(user.valid()).toBeFalse();
            });
        });
    }
}
```

Tests live in `tests/models/`, `tests/controllers/`, `tests/integration/`. Run with MCP `wheels_test()` or CLI `wheels test run`.

## Reference Docs

Deeper documentation lives in `.ai/` — Claude will search it automatically when needed:
- `.ai/cfml/` — CFML language reference (syntax, data types, components)
- `.ai/wheels/models/` — ORM details, associations, validations
- `.ai/wheels/controllers/` — filters, rendering, security
- `.ai/wheels/views/` — layouts, partials, form helpers, link helpers
- `.ai/wheels/database/` — migration column types, queries, advanced operations
- `.ai/wheels/configuration/` — routing, environments, settings

## MCP Server

Endpoint: `/wheels/mcp` (routes must come before `.wildcard()` in routes.cfm).

Tools: `wheels_generate`, `wheels_migrate`, `wheels_test`, `wheels_server`, `wheels_reload`, `wheels_analyze`, `wheels_validate`.
