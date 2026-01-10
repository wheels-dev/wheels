# wheels generate snippets

Generate code snippets and boilerplate code for common Wheels patterns.

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

| Option | Description | Valid Values | Default |
|--------|-------------|--------------|---------|
| `--list` | List all available snippets | `true`/`false` | `false` |
| `--category` | Filter by category | `authentication`, `model`, `controller`, `view`, `database` | All categories |
| `--output` | Output format | `console`, `file` | `console` |
| `--path` | Output file path (required when output=file) | Any valid file path | |
| `--customize` | Show customization options | `true`/`false` | `false` |
| `--create` | Create custom snippet template | `true`/`false` | `false` |
| `--force` | Overwrite existing files | `true`/`false` | `false` |

## Available Snippets

### List All Snippets
```bash
wheels generate snippets --list
```

Output:
```
Available Snippets

Authentication:
  - login-form - Login form with remember me
  - auth-filter - Authentication filter
  - password-reset - Password reset flow
  - user-registration - User registration with validation

Model:
  - soft-delete - Soft delete implementation
  - audit-trail - Audit trail with timestamps
  - sluggable - URL-friendly slugs
  - versionable - Version tracking
  - searchable - Full-text search

Controller:
  - crud-actions - Complete CRUD actions
  - api-controller - JSON API controller
  - nested-resource - Nested resource controller
  - admin-controller - Admin area controller

View:
  - form-with-errors - Form with error handling
  - pagination-links - Pagination navigation
  - search-form - Search form with filters
  - ajax-form - AJAX form submission

Database:
  - migration-indexes - Common index patterns
  - seed-data - Database seeding
  - constraints - Foreign key constraints


Next steps:
   1. Generate a snippet: wheels g snippets <pattern-name>
```

## Authentication Snippets

### Login Form
```bash
wheels generate snippets login-form
```

Generates:
```cfm
#startFormTag(action="create")#
  #textField(objectName="user", property="email", label="Email")#
  #passwordField(objectName="user", property="password", label="Password")#
  #checkBox(objectName="user", property="rememberMe", label="Remember me")#
  #submitTag(value="Login")#
#endFormTag()#
```

**Note**: This is a basic snippet. You can customize it by saving to a file and editing:
```bash
wheels generate snippets login-form --output=file --path=app/views/sessions/new.cfm
```

### Authentication Filter
```bash
wheels generate snippets auth-filter
```

Generates:
```cfc
function init() {
  filters(through="authenticate", except="new,create");
}

private function authenticate() {
  if (!StructKeyExists(session, "userId")) {
    redirectTo(route="login");
  }
}
```

### Password Reset
```bash
wheels generate snippets password-reset
```

Generates:
```cfc
function requestReset() {
  user = model("User").findOne(where="email='#params.email#'");
  if (IsObject(user)) {
    token = Hash(CreateUUID());
    user.update(resetToken=token, resetExpiresAt=DateAdd("h", 1, Now()));
    // Send email with token
  }
}
```

### User Registration
```bash
wheels generate snippets user-registration
```

Generates:
```cfm
#startFormTag(action="create")#
  #textField(objectName="user", property="firstName", label="First Name")#
  #textField(objectName="user", property="email", label="Email")#
  #passwordField(objectName="user", property="password", label="Password")#
  #submitTag(value="Register")#
#endFormTag()#
```

## Model Patterns

### Soft Delete
```bash
wheels generate snippets soft-delete
```

Generates:
```cfc
function init() {
  property(name="deletedAt", sql="deleted_at");
  beforeDelete("softDelete");
}

private function softDelete() {
  this.deletedAt = Now();
  this.save(validate=false, callbacks=false);
  return false;
}
```

### Audit Trail
```bash
wheels generate snippets audit-trail
```

Generates:
```cfc
function init() {
  property(name="createdBy", sql="created_by");
  property(name="updatedBy", sql="updated_by");
  beforeSave("setAuditFields");
}

private function setAuditFields() {
  if (StructKeyExists(session, "userId")) {
    if (this.isNew()) this.createdBy = session.userId;
    this.updatedBy = session.userId;
  }
}
```

### Sluggable
```bash
wheels generate snippets sluggable
```

Generates:
```cfc
function init() {
  property(name="slug");
  beforeSave("generateSlug");
}

private function generateSlug() {
  if (!len(this.slug) && len(this.title)) {
    this.slug = lCase(reReplace(this.title, "[^a-zA-Z0-9]", "-", "all"));
  }
}
```

### Versionable
```bash
wheels generate snippets versionable
```

Generates:
```cfc
function init() {
  property(name="version", default=1);
  beforeUpdate("incrementVersion");
}

private function incrementVersion() {
  this.version = this.version + 1;
}
```

### Searchable
```bash
wheels generate snippets searchable
```

Generates:
```cfc
function search(required string query) {
  return findAll(where="title LIKE '%#arguments.query#%' OR content LIKE '%#arguments.query#%'");
}
```

## Controller Patterns

### CRUD Actions
```bash
wheels generate snippets crud-actions
```

Generates:
```cfc
function index() {
  users = model("User").findAll();
}

function show() {
  user = model("User").findByKey(params.key);
}

function create() {
  user = model("User").create(params.user);
  if (user.valid()) {
    redirectTo(route="user", key=user.id);
  } else {
    renderView(action="new");
  }
}
```

### API Controller
```bash
wheels generate snippets api-controller
```

Generates:
```cfc
function init() {
  provides("json");
}

function index() {
  users = model("User").findAll();
  renderWith(data={users=users});
}
```

### Nested Resource
```bash
wheels generate snippets nested-resource
```

Generates:
```cfc
function init() {
  filters(through="findParent");
}

private function findParent() {
  user = model("User").findByKey(params.userId);
}
```

### Admin Controller
```bash
wheels generate snippets admin-controller
```

Generates:
```cfc
function init() {
  filters(through="requireAdmin");
}

private function requireAdmin() {
  if (!currentUser().isAdmin()) {
    redirectTo(route="home");
  }
}
```

## View Patterns

### Form with Errors
```bash
wheels generate snippets form-with-errors
```

Generates:
```cfm
#errorMessagesFor("user")#

#startFormTag(action="create")#
  #textField(objectName="user", property="firstName", label="First Name")#
  <cfif user.errors("firstName").len()>
    <span class="error">#user.errors("firstName").get()#</span>
  </cfif>
  #submitTag(value="Submit")#
#endFormTag()#
```

### Pagination Links
```bash
wheels generate snippets pagination-links
```

Generates:
```cfm
<cfif users.totalPages gt 1>
  <nav>
    <cfif users.currentPage gt 1>
      #linkTo(text="Previous", params={page: users.currentPage - 1})#
    </cfif>
    <cfloop from="1" to="#users.totalPages#" index="pageNum">
      #linkTo(text=pageNum, params={page: pageNum})#
    </cfloop>
    <cfif users.currentPage lt users.totalPages>
      #linkTo(text="Next", params={page: users.currentPage + 1})#
    </cfif>
  </nav>
</cfif>
```

### Search Form
```bash
wheels generate snippets search-form
```

Generates:
```cfm
#startFormTag(method="get")#
  #textField(name="q", value=params.q, placeholder="Search...")#
  #submitTag(value="Search")#
#endFormTag()#
```

### AJAX Form
```bash
wheels generate snippets ajax-form
```

Generates:
```cfm
#startFormTag(action="create", id="userForm")#
  #textField(objectName="user", property="name")#
  #submitTag(value="Submit")#
#endFormTag()#

<script>
$("#userForm").submit(function(e) {
  e.preventDefault();
  $.post($(this).attr("action"), $(this).serialize());
});
</script>
```

## Database Snippets

### Migration Indexes
```bash
wheels generate snippets migration-indexes
```

Generates:
```cfc
t.index("email");
t.index(["last_name", "first_name"]);
t.index("email", unique=true);
t.index("user_id");
```

### Seed Data
```bash
wheels generate snippets seed-data
```

Generates:
```cfc
execute("INSERT INTO users (name, email) VALUES ('Admin', 'admin@example.com')");
```

### Constraints
```bash
wheels generate snippets constraints
```

Generates:
```cfc
t.references("user_id", "users");
t.references("category_id", "categories");
```

## Custom Snippets

### Create Custom Snippet
```bash
wheels generate snippets --create my-custom-snippet
```

This creates a directory structure in `app/snippets/my-custom-snippet/`:
```
my-custom-snippet/
└── template.txt
```

You can then edit the template file and use your custom snippet:
```bash
wheels generate snippets my-custom-snippet
```

## Output Options

### Output to Console (Default)
```bash
wheels generate snippets login-form
# or explicitly:
wheels generate snippets login-form --output=console
```

### Save to File
```bash
wheels generate snippets api-controller --output=file --path=app/controllers/Api.cfc
```

Use `--force` to overwrite existing files:
```bash
wheels generate snippets api-controller --output=file --path=app/controllers/Api.cfc --force
```

### Customization Options
```bash
wheels generate snippets [pattern] --customize
```

Shows available customization options for snippets.

## Filter by Category

List snippets from a specific category:
```bash
wheels generate snippets --list --category=model
wheels generate snippets --list --category=authentication
wheels generate snippets --list --category=controller
wheels generate snippets --list --category=view
wheels generate snippets --list --category=database
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