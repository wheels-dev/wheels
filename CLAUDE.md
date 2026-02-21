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

### 3. Nested Resource Routes — Use Callback Syntax
Wheels supports nested resources via the `callback` parameter or `nested=true` with manual `end()`. Do NOT use Rails-style inline function blocks.
```cfm
// WRONG — Rails-style inline (not supported)
.resources("posts", function(r) { r.resources("comments"); })

// RIGHT — callback syntax (recommended)
.resources(name="posts", callback=function(map) {
    map.resources("comments");
})

// RIGHT — manual nested=true + end()
.resources(name="posts", nested=true)
    .resources("comments")
.end()

// RIGHT — flat separate declarations (no URL nesting)
.resources("posts")
.resources("comments")
```

### 4. HTML5 Form Helpers Available
Wheels provides dedicated HTML5 input helpers. Use them instead of manual type attributes.
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

// Tag-based helpers
#emailFieldTag(name="email", value="")#
#numberFieldTag(name="qty", value="1", min="0", step="1")#
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
- **extends**: Models extend `"Model"`, controllers extend `"Controller"`, tests extend `"wheels.Test"` or `"wheels.WheelsTest"`
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

        // Query scopes — reusable, composable query fragments
        scope(name="active", where="status = 'active'");
        scope(name="recent", order="createdAt DESC");
        scope(name="byRole", handler="scopeByRole");  // dynamic scope

        // Enums — named values with auto-generated checkers and scopes
        enum(property="status", values="draft,published,archived");
        enum(property="priority", values={low: 0, medium: 1, high: 2});
    }

    // Dynamic scope handler (must return struct with query keys)
    private struct function scopeByRole(required string role) {
        return {where: "role = '#arguments.role#'"};
    }
}
```

Finders: `model("User").findAll()`, `model("User").findOne(where="...")`, `model("User").findByKey(params.key)`.
Create: `model("User").new(params.user)` then `.save()`, or `model("User").create(params.user)`.
Include associations: `findAll(include="role,orders")`. Pagination: `findAll(page=params.page, perPage=25)`.

### Scopes (Composable Query Fragments)
```cfm
// Chain scopes together — each adds to the query
model("User").active().recent().findAll();
model("User").byRole("admin").findAll(page=1, perPage=25);
model("User").active().recent().count();
```

### Chainable Query Builder (Injection-Safe)
```cfm
// Fluent alternative to raw WHERE strings — values are auto-quoted
model("User")
    .where("status", "active")
    .where("age", ">", 18)
    .whereNotNull("emailVerifiedAt")
    .orderBy("name", "ASC")
    .limit(25)
    .get();

// Combine with scopes
model("User").active().where("role", "admin").get();

// Other builder methods: orWhere, whereNull, whereBetween, whereIn, whereNotIn
```

### Enums (Named Property Values)
```cfm
// Auto-generated boolean checkers
user.isDraft();       // true/false
user.isPublished();   // true/false

// Auto-generated scopes per value
model("User").draft().findAll();
model("User").published().findAll();
```

### Batch Processing (Memory-Efficient)
```cfm
// Process one record at a time (loads in batches internally)
model("User").findEach(batchSize=1000, callback=function(user) {
    user.sendReminderEmail();
});

// Process in batch groups (callback receives query/array)
model("User").findInBatches(batchSize=500, callback=function(users) {
    processUserBatch(users);
});

// Works with scopes and conditions
model("User").active().findEach(batchSize=500, callback=function(user) { /* ... */ });
```

## Routing Quick Reference

```cfm
// config/routes.cfm
mapper()
    .resources("users")                              // standard CRUD
    .resources("products", except="delete")           // skip actions
    .resources(name="posts", callback=function(map) { // nested resources
        map.resources("comments");
        map.resources("tags");
    })
    .get(name="login", to="sessions##new")           // named route
    .post(name="authenticate", to="sessions##create")
    .root(to="home##index", method="get")            // homepage
    .wildcard()                                       // keep last!
.end();
```

Helpers: `linkTo(route="user", key=user.id, text="View")`, `urlFor(route="users")`, `redirectTo(route="user", key=user.id)`, `startFormTag(route="user", method="put", key=user.id)`.

## Testing Quick Reference

```cfm
component extends="wheels.WheelsTest" {
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

## Background Jobs Quick Reference

```cfm
// Define a job: app/jobs/SendWelcomeEmailJob.cfc
component extends="wheels.Job" {
    function config() {
        super.config();
        this.queue = "mailers";
        this.maxRetries = 5;
    }
    public void function perform(struct data = {}) {
        sendEmail(to=data.email, subject="Welcome!", from="app@example.com");
    }
}

// Enqueue from a controller
job = new app.jobs.SendWelcomeEmailJob();
job.enqueue(data={email: user.email});           // immediate
job.enqueueIn(seconds=300, data={email: "..."});  // delayed 5 minutes
job.enqueueAt(runAt=scheduledDate, data={});       // at specific time

// Process jobs (call from scheduled task or controller)
job = new wheels.Job();
result = job.processQueue(queue="mailers", limit=10);

// Queue management
stats = job.queueStats();          // {pending, processing, completed, failed, total}
job.retryFailed(queue="mailers");  // retry all failed jobs
job.purgeCompleted(days=7);        // clean up old completed jobs
```

Requires migration: `20260221000001_create_wheels_jobs_table.cfc`. Run with `wheels dbmigrate latest`.

## Server-Sent Events (SSE) Quick Reference

```cfm
// In a controller action — single event response
function notifications() {
    var data = model("Notification").findAll(where="userId=#params.userId#");
    renderSSE(data=SerializeJSON(data), event="notifications", id=params.lastId);
}

// Streaming multiple events (long-lived connection)
function stream() {
    var writer = initSSEStream();
    for (var item in items) {
        sendSSEEvent(writer=writer, data=SerializeJSON(item), event="update");
    }
    closeSSEStream(writer=writer);
}

// Check if request is from EventSource
if (isSSERequest()) { renderSSE(data="..."); }
```

Client-side: `const es = new EventSource('/controller/notifications');`

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
