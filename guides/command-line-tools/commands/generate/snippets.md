# wheels generate snippets

Generate code snippets and boilerplate code for common patterns.

## Synopsis

```bash
wheels generate snippets [pattern] [options]
wheels g snippets [pattern] [options]
```

## Description

The `wheels generate snippets` command creates code snippets for common Wheels patterns and best practices. It provides ready-to-use code blocks that can be customized for your specific needs, helping you implement standard patterns quickly and consistently.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `pattern` | Snippet pattern to generate | Shows available patterns |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--list` | List all available snippets | `false` |
| `--category` | Filter by category | All categories |
| `--output` | Output format (console, file, clipboard) | `console` |
| `--customize` | Interactive customization | `false` |
| `--force` | Overwrite existing files | `false` |
| `--help` | Show help information | |

## Available Snippets

### List All Snippets
```bash
wheels generate snippets --list
```

Output:
```
Available Snippets:
━━━━━━━━━━━━━━━━━━━

Authentication:
  - login-form          Login form with remember me
  - auth-filter         Authentication filter
  - password-reset      Password reset flow
  - user-registration   User registration with validation

Model Patterns:
  - soft-delete         Soft delete implementation
  - audit-trail         Audit trail with timestamps
  - sluggable          URL-friendly slugs
  - versionable        Version tracking
  - searchable         Full-text search

Controller Patterns:
  - crud-actions       Complete CRUD actions
  - api-controller     JSON API controller
  - nested-resource    Nested resource controller
  - admin-controller   Admin area controller

View Patterns:
  - form-with-errors   Form with error handling
  - pagination-links   Pagination navigation
  - search-form        Search form with filters
  - ajax-form          AJAX form submission

Database:
  - migration-indexes  Common index patterns
  - seed-data         Database seeding
  - constraints       Foreign key constraints
```

## Authentication Snippets

### Login Form
```bash
wheels generate snippets login-form
```

Generates:
```cfm
<!--- views/sessions/new.cfm --->
<h1>Login</h1>

#errorMessagesFor("user")#

#startFormTag(action="create", class="login-form")#
    
    <div class="form-group">
        #textField(
            objectName="user",
            property="email",
            label="Email",
            class="form-control",
            placeholder="email@example.com",
            required=true,
            autofocus=true
        )#
    </div>
    
    <div class="form-group">
        #passwordField(
            objectName="user",
            property="password",
            label="Password",
            class="form-control",
            required=true
        )#
    </div>
    
    <div class="form-group">
        #checkBox(
            objectName="user",
            property="rememberMe",
            label="Remember me",
            value="1"
        )#
    </div>
    
    <div class="form-group">
        #submitTag(value="Login", class="btn btn-primary")#
        #linkTo(text="Forgot password?", route="forgotPassword", class="btn btn-link")#
    </div>
    
#endFormTag()#

<!--- controllers/Sessions.cfc --->
component extends="Controller" {
    
    function new() {
        user = model("User").new();
    }
    
    function create() {
        user = model("User").findOne(where="email='#params.user.email#'");
        
        if (IsObject(user) && user.authenticate(params.user.password)) {
            session.userId = user.id;
            
            if (params.user.rememberMe == 1) {
                cookie.rememberToken = user.generateRememberToken();
                cookie.userId = encrypt(user.id, application.encryptionKey);
            }
            
            flashInsert(success="Welcome back, #user.firstName#!");
            redirectTo(route="dashboard");
        } else {
            user = model("User").new(email=params.user.email);
            flashInsert(error="Invalid email or password.");
            renderView(action="new");
        }
    }
    
    function delete() {
        StructDelete(session, "userId");
        StructDelete(cookie, "rememberToken");
        StructDelete(cookie, "userId");
        
        flashInsert(success="You have been logged out.");
        redirectTo(route="home");
    }
    
}
```

### Authentication Filter
```bash
wheels generate snippets auth-filter
```

Generates:
```cfc
// In Controller.cfc or specific controller

function init() {
    filters(through="authenticate", except="new,create");
    filters(through="rememberUser", only="new");
}

private function authenticate() {
    if (!isLoggedIn()) {
        storeLocation();
        flashInsert(notice="Please log in to continue.");
        redirectTo(route="login");
    }
}

private function isLoggedIn() {
    return StructKeyExists(session, "userId") && session.userId > 0;
}

private function currentUser() {
    if (!StructKeyExists(request, "currentUser")) {
        if (isLoggedIn()) {
            request.currentUser = model("User").findByKey(session.userId);
        } else {
            request.currentUser = false;
        }
    }
    return request.currentUser;
}

private function rememberUser() {
    if (!isLoggedIn() && StructKeyExists(cookie, "rememberToken")) {
        user = model("User").findOne(
            where="rememberToken='#cookie.rememberToken#' AND rememberTokenExpiresAt > NOW()"
        );
        
        if (IsObject(user)) {
            session.userId = user.id;
            user.updateRememberToken();
        }
    }
}

private function storeLocation() {
    if (request.method == "GET") {
        session.returnTo = request.cgi.path_info;
        if (Len(request.cgi.query_string)) {
            session.returnTo &= "?" & request.cgi.query_string;
        }
    }
}

private function redirectBackOrTo(required string route) {
    if (StructKeyExists(session, "returnTo")) {
        local.returnTo = session.returnTo;
        StructDelete(session, "returnTo");
        redirectTo(location=local.returnTo);
    } else {
        redirectTo(route=arguments.route);
    }
}
```

## Model Patterns

### Soft Delete
```bash
wheels generate snippets soft-delete
```

Generates:
```cfc
// In Model init()
property(name="deletedAt", sql="deleted_at");

// Soft delete callbacks
beforeDelete("softDelete");
afterFind("excludeDeleted");

// Default scope
function excludeDeleted() {
    if (!StructKeyExists(arguments, "includeSoftDeleted") || !arguments.includeSoftDeleted) {
        if (StructKeyExists(this, "deletedAt") && !IsNull(this.deletedAt)) {
            return false; // Exclude from results
        }
    }
}

// Soft delete implementation
private function softDelete() {
    this.deletedAt = Now();
    this.save(validate=false, callbacks=false);
    return false; // Prevent actual deletion
}

// Scopes
function active() {
    return this.findAll(where="deleted_at IS NULL", argumentCollection=arguments);
}

function deleted() {
    return this.findAll(where="deleted_at IS NOT NULL", argumentCollection=arguments);
}

function withDeleted() {
    return this.findAll(includeSoftDeleted=true, argumentCollection=arguments);
}

// Restore method
function restore() {
    this.deletedAt = "";
    return this.save(validate=false);
}

// Permanent delete
function forceDelete() {
    return this.delete(callbacks=false);
}
```

### Audit Trail
```bash
wheels generate snippets audit-trail --customize
```

Interactive customization:
```
? Include user tracking? (Y/n) › Y
? Track IP address? (y/N) › Y
? Track changes in JSON? (Y/n) › Y
```

Generates:
```cfc
// models/AuditLog.cfc
component extends="Model" {
    
    function init() {
        belongsTo("user");
        
        property(name="modelName", sql="model_name");
        property(name="recordId", sql="record_id");
        property(name="action", sql="action");
        property(name="changes", sql="changes");
        property(name="userId", sql="user_id");
        property(name="ipAddress", sql="ip_address");
        property(name="userAgent", sql="user_agent");
        
        validatesPresenceOf("modelName,recordId,action");
    }
    
}

// In audited model
function init() {
    afterCreate("logCreate");
    afterUpdate("logUpdate");
    afterDelete("logDelete");
}

private function logCreate() {
    createAuditLog("create", this.properties());
}

private function logUpdate() {
    if (hasChanged()) {
        createAuditLog("update", this.changedProperties());
    }
}

private function logDelete() {
    createAuditLog("delete", {id: this.id});
}

private function createAuditLog(required string action, required struct data) {
    model("AuditLog").create({
        modelName: ListLast(GetMetaData(this).name, "."),
        recordId: this.id,
        action: arguments.action,
        changes: SerializeJSON(arguments.data),
        userId: request.currentUser.id ?: "",
        ipAddress: request.remoteAddress,
        userAgent: request.userAgent
    });
}

private function changedProperties() {
    local.changes = {};
    local.properties = this.properties();
    
    for (local.key in local.properties) {
        if (hasChanged(local.key)) {
            local.changes[local.key] = {
                from: this.changedFrom(local.key),
                to: local.properties[local.key]
            };
        }
    }
    
    return local.changes;
}

// Audit log migration
component extends="wheels.migrator.Migration" {
    
    function up() {
        createTable(name="audit_logs") {
            t.increments("id");
            t.string("model_name", null=false);
            t.integer("record_id", null=false);
            t.string("action", null=false);
            t.text("changes");
            t.integer("user_id");
            t.string("ip_address");
            t.string("user_agent");
            t.timestamps();
            
            t.index(["model_name", "record_id"]);
            t.index("user_id");
            t.index("created_at");
        };
    }
    
    function down() {
        dropTable("audit_logs");
    }
    
}
```

## Controller Patterns

### CRUD Actions
```bash
wheels generate snippets crud-actions
```

Generates complete CRUD controller with error handling, pagination, and filters.

### API Controller
```bash
wheels generate snippets api-controller
```

Generates:
```cfc
component extends="Controller" {
    
    function init() {
        provides("json");
        filters(through="setApiHeaders");
        filters(through="authenticateApi");
        filters(through="logApiRequest", except="index,show");
    }
    
    private function setApiHeaders() {
        header name="X-API-Version" value="1.0";
        header name="X-RateLimit-Limit" value="1000";
        header name="X-RateLimit-Remaining" value=getRateLimitRemaining();
    }
    
    private function authenticateApi() {
        local.token = getAuthToken();
        
        if (!Len(local.token)) {
            renderUnauthorized("Missing authentication token");
        }
        
        request.apiUser = model("ApiKey").authenticate(local.token);
        
        if (!IsObject(request.apiUser)) {
            renderUnauthorized("Invalid authentication token");
        }
    }
    
    private function getAuthToken() {
        // Check Authorization header
        if (StructKeyExists(getHttpRequestData().headers, "Authorization")) {
            local.auth = getHttpRequestData().headers.Authorization;
            if (Left(local.auth, 7) == "Bearer ") {
                return Mid(local.auth, 8, Len(local.auth));
            }
        }
        
        // Check X-API-Key header
        if (StructKeyExists(getHttpRequestData().headers, "X-API-Key")) {
            return getHttpRequestData().headers["X-API-Key"];
        }
        
        // Check query parameter
        if (StructKeyExists(params, "api_key")) {
            return params.api_key;
        }
        
        return "";
    }
    
    private function renderUnauthorized(required string message) {
        renderWith(
            data={
                error: {
                    code: 401,
                    message: arguments.message
                }
            },
            status=401
        );
    }
    
    private function renderError(required string message, numeric status = 400) {
        renderWith(
            data={
                error: {
                    code: arguments.status,
                    message: arguments.message
                }
            },
            status=arguments.status
        );
    }
    
    private function renderSuccess(required any data, numeric status = 200) {
        renderWith(
            data={
                success: true,
                data: arguments.data
            },
            status=arguments.status
        );
    }
    
    private function renderPaginated(required any query) {
        renderWith(
            data={
                success: true,
                data: arguments.query,
                pagination: {
                    page: arguments.query.currentPage,
                    perPage: arguments.query.perPage,
                    total: arguments.query.totalRecords,
                    pages: arguments.query.totalPages
                }
            }
        );
    }
    
}
```

## View Patterns

### Form with Errors
```bash
wheels generate snippets form-with-errors
```

### AJAX Form
```bash
wheels generate snippets ajax-form
```

Generates:
```cfm
<!--- View file --->
<div id="contact-form-container">
    #startFormTag(
        action="send",
        id="contact-form",
        class="ajax-form",
        data={
            remote: true,
            method: "post",
            success: "handleFormSuccess",
            error: "handleFormError"
        }
    )#
        
        <div class="form-messages" style="display: none;"></div>
        
        <div class="form-group">
            #textField(
                name="name",
                label="Name",
                class="form-control",
                required=true
            )#
        </div>
        
        <div class="form-group">
            #emailField(
                name="email",
                label="Email",
                class="form-control",
                required=true
            )#
        </div>
        
        <div class="form-group">
            #textArea(
                name="message",
                label="Message",
                class="form-control",
                rows=5,
                required=true
            )#
        </div>
        
        <div class="form-group">
            #submitTag(
                value="Send Message",
                class="btn btn-primary",
                data={loading: "Sending..."}
            )#
        </div>
        
    #endFormTag()#
</div>

<script>
// AJAX form handler
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('contact-form');
    
    form.addEventListener('submit', function(e) {
        e.preventDefault();
        
        const submitBtn = form.querySelector('[type="submit"]');
        const originalText = submitBtn.value;
        const loadingText = submitBtn.dataset.loading;
        
        // Disable form
        submitBtn.disabled = true;
        submitBtn.value = loadingText;
        
        // Send AJAX request
        fetch(form.action, {
            method: form.method,
            body: new FormData(form),
            headers: {
                'X-Requested-With': 'XMLHttpRequest'
            }
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                handleFormSuccess(data);
            } else {
                handleFormError(data);
            }
        })
        .catch(error => {
            handleFormError({message: 'Network error. Please try again.'});
        })
        .finally(() => {
            submitBtn.disabled = false;
            submitBtn.value = originalText;
        });
    });
});

function handleFormSuccess(data) {
    const form = document.getElementById('contact-form');
    const messages = form.querySelector('.form-messages');
    
    // Show success message
    messages.className = 'form-messages alert alert-success';
    messages.textContent = data.message || 'Message sent successfully!';
    messages.style.display = 'block';
    
    // Reset form
    form.reset();
    
    // Hide message after 5 seconds
    setTimeout(() => {
        messages.style.display = 'none';
    }, 5000);
}

function handleFormError(data) {
    const form = document.getElementById('contact-form');
    const messages = form.querySelector('.form-messages');
    
    // Show error message
    messages.className = 'form-messages alert alert-danger';
    messages.textContent = data.message || 'An error occurred. Please try again.';
    messages.style.display = 'block';
    
    // Show field errors
    if (data.errors) {
        Object.keys(data.errors).forEach(field => {
            const input = form.querySelector(`[name="${field}"]`);
            if (input) {
                input.classList.add('is-invalid');
                const error = document.createElement('div');
                error.className = 'invalid-feedback';
                error.textContent = data.errors[field].join(', ');
                input.parentNode.appendChild(error);
            }
        });
    }
}
</script>

<!--- Controller action --->
function send() {
    contact = model("Contact").new(params);
    
    if (contact.save()) {
        if (isAjax()) {
            renderWith(data={
                success: true,
                message: "Thank you! We'll be in touch soon."
            });
        } else {
            flashInsert(success="Thank you! We'll be in touch soon.");
            redirectTo(route="home");
        }
    } else {
        if (isAjax()) {
            renderWith(data={
                success: false,
                message: "Please correct the errors below.",
                errors: contact.allErrors()
            }, status=422);
        } else {
            renderView(action="new");
        }
    }
}
```

## Database Snippets

### Migration Indexes
```bash
wheels generate snippets migration-indexes
```

Generates common index patterns:
```cfc
// Performance indexes
t.index("email"); // Single column
t.index(["last_name", "first_name"]); // Composite
t.index("created_at"); // Timestamp queries

// Unique constraints
t.index("email", unique=true);
t.index(["user_id", "role_id"], unique=true);

// Foreign key indexes
t.index("user_id");
t.index("category_id");

// Full-text search
t.index("title", type="fulltext");
t.index(["title", "content"], type="fulltext");

// Partial indexes (PostgreSQL)
t.index("email", where="deleted_at IS NULL");

// Expression indexes
t.index("LOWER(email)", name="idx_email_lower");
```

### Seed Data
```bash
wheels generate snippets seed-data
```

## Custom Snippets

### Create Custom Snippet
```bash
wheels generate snippets --create=my-pattern
```

Creates template in `~/.wheels/snippets/my-pattern/`:
```
my-pattern/
├── snippet.json
├── files/
│   ├── controller.cfc
│   ├── model.cfc
│   └── view.cfm
└── README.md
```

`snippet.json`:
```json
{
    "name": "my-pattern",
    "description": "Custom pattern description",
    "category": "custom",
    "author": "Your Name",
    "version": "1.0.0",
    "variables": [
        {
            "name": "modelName",
            "prompt": "Model name?",
            "default": "MyModel"
        }
    ],
    "files": [
        {
            "source": "files/controller.cfc",
            "destination": "controllers/${controllerName}.cfc"
        }
    ]
}
```

## Output Options

### Copy to Clipboard
```bash
wheels generate snippets login-form --output=clipboard
```

### Save to File
```bash
wheels generate snippets api-controller --output=file --path=./controllers/Api.cfc
```

### Interactive Mode
```bash
wheels generate snippets --customize
```

## Best Practices

1. **Review generated code**: Customize for your needs
2. **Understand the patterns**: Don't blindly copy
3. **Keep snippets updated**: Maintain with framework updates
4. **Share useful patterns**: Contribute back to community
5. **Document customizations**: Note changes made
6. **Test generated code**: Ensure it works in your context
7. **Use consistent patterns**: Across your application

## See Also

- [wheels generate controller](controller.md) - Generate controllers
- [wheels generate model](model.md) - Generate models
- [wheels scaffold](scaffold.md) - Generate complete resources