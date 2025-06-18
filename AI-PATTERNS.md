# AI-PATTERNS.md

This file provides common code patterns and solutions for AI assistants working with the Wheels framework.

## Common Code Patterns

### 1. Controller Patterns

#### Basic CRUD Controller
```cfml
component extends="Controller" {
  
  function config() {
    // Always use config() for initialization, NOT init()
    provides("html,json");
    filters("authenticate", except="index,show");
  }
  
  function index() {
    posts = model("Post").findAll(order="createdAt DESC");
    renderWith(posts);
  }
  
  function show() {
    post = model("Post").findByKey(params.key);
    if (!IsObject(post)) {
      redirectTo(route="posts");
    }
    renderWith(post);
  }
  
  function new() {
    post = model("Post").new();
  }
  
  function create() {
    post = model("Post").create(params.post);
    if (post.hasErrors()) {
      renderView("new");
    } else {
      redirectTo(route="post", key=post.key());
    }
  }
  
  function edit() {
    post = model("Post").findByKey(params.key);
    if (!IsObject(post)) {
      redirectTo(route="posts");
    }
  }
  
  function update() {
    post = model("Post").findByKey(params.key);
    if (IsObject(post) && post.update(params.post)) {
      redirectTo(route="post", key=post.key());
    } else {
      renderView("edit");
    }
  }
  
  function delete() {
    post = model("Post").findByKey(params.key);
    if (IsObject(post)) {
      post.delete();
    }
    redirectTo(route="posts");
  }
}
```

#### API Controller with Content Negotiation
```cfml
component extends="Controller" {
  
  function config() {
    // Only respond to JSON requests
    onlyProvides("json");
    
    // Set common variables for all actions
    filters("setApiHeaders");
  }
  
  function setApiHeaders() {
    header name="X-API-Version" value="1.0";
  }
  
  function index() {
    local.users = model("User").findAll(
      select="id,name,email",
      order="name ASC"
    );
    renderWith(local.users);
  }
  
  function create() {
    local.user = model("User").create(params.user);
    if (local.user.hasErrors()) {
      renderWith(data=local.user.allErrors(), status=422);
    } else {
      renderWith(data=local.user, status=201);
    }
  }
}
```

### 2. Model Patterns

#### Model with Associations and Validations
```cfml
component extends="Model" {
  
  function config() {
    // Table configuration
    table("users");
    
    // Associations
    hasMany("posts");
    hasMany("comments");
    belongsTo("role");
    hasOne("profile");
    
    // Validations
    validatesPresenceOf("name,email");
    validatesUniquenessOf("email");
    validatesFormatOf(property="email", regex="^[^@]+@[^@]+\.[^@]+$");
    validatesLengthOf(property="name", minimum=2, maximum=100);
    
    // Callbacks
    beforeValidation("sanitizeInput");
    beforeCreate("setDefaults");
    afterCreate("sendWelcomeEmail");
    
    // Calculated properties
    property(name="fullName", sql="CONCAT(firstName, ' ', lastName)");
  }
  
  // Private callback methods use $ prefix
  private function sanitizeInput() {
    if (StructKeyExists(this, "email")) {
      this.email = Trim(LCase(this.email));
    }
  }
  
  private function setDefaults() {
    if (!StructKeyExists(this, "status")) {
      this.status = "active";
    }
  }
  
  private function sendWelcomeEmail() {
    // Send email logic here
  }
  
  // Public instance methods
  public boolean function isActive() {
    return this.status == "active";
  }
  
  // Custom finder
  public query function findActive() {
    return this.findAll(where="status='active'", order="name ASC");
  }
}
```

#### Model with Nested Properties
```cfml
component extends="Model" {
  
  function config() {
    hasMany("orderItems");
    
    // Allow nested attributes
    nestedProperties(
      association="orderItems",
      allowDelete=true,
      rejectIf="isBlank"
    );
  }
  
  private boolean function isBlank(struct properties) {
    return !Len(Trim(arguments.properties.productId ?: ""));
  }
}
```

### 3. Routing Patterns

#### RESTful Resource Routes
```cfml
// config/routes.cfm
mapper()
  .resources("posts")
  .resource("account")
  .namespace("admin")
    .resources("users")
    .resources("products")
  .end()
  .root(to="pages##home")
.end();
```

#### Custom Routes with Constraints
```cfml
mapper()
  .get(
    name="userProfile",
    pattern="users/[username]",
    to="users##show",
    constraints={username="[a-zA-Z0-9_]+"}
  )
  .post(
    name="apiLogin",
    pattern="api/v1/login",
    to="api.v1.sessions##create"
  )
  .scope(path="api/v1", name="apiV1")
    .resources("posts", only="index,show,create,update,delete")
  .end()
.end();
```

### 4. View Patterns

#### Form with Error Handling
```cfm
<cfoutput>
#startFormTag(route="posts", method="post")#

  #errorMessagesFor("post")#
  
  #textField(objectName="post", property="title", label="Title")#
  #textArea(objectName="post", property="body", label="Body")#
  
  #select(
    objectName="post",
    property="categoryId",
    options=categories,
    includeBlank="-- Select Category --",
    label="Category"
  )#
  
  #checkBox(objectName="post", property="published", label="Published?")#
  
  #submitTag("Save Post")#

#endFormTag()#
</cfoutput>
```

#### Partial with Local Variables
```cfm
<!--- views/posts/_post.cfm --->
<cfoutput>
<article class="post">
  <h2>#linkTo(text=post.title, route="post", key=post.key())#</h2>
  <p class="meta">
    By #post.author().name# on #dateFormat(post.createdAt, "mmm d, yyyy")#
  </p>
  <div class="content">
    #post.excerpt#
  </div>
</article>
</cfoutput>

<!--- Usage in view --->
<cfoutput>
#includePartial(partial="post", query=posts)#
</cfoutput>
```

### 5. Testing Patterns

#### Controller Test
```cfml
component extends="wheels.test" {
  
  function setup() {
    super.setup();
    // Create test data
    testUser = model("User").create(
      name="Test User",
      email="test@example.com"
    );
  }
  
  function teardown() {
    super.teardown();
    // Cleanup happens automatically with transactions
  }
  
  function test_index_returns_users() {
    result = processRequest(route="users", method="GET");
    
    assert("result.status == 200");
    assert("IsArray(result.users)");
    assert("ArrayLen(result.users) > 0");
  }
  
  function test_create_with_valid_data() {
    params = {
      user = {
        name = "New User",
        email = "new@example.com"
      }
    };
    
    result = processRequest(
      route="users",
      method="POST",
      params=params
    );
    
    assert("result.status == 201");
    assert("result.user.name == 'New User'");
  }
}
```

#### Model Test
```cfml
component extends="wheels.test" {
  
  function test_validations() {
    user = model("User").new();
    assert("!user.valid()");
    
    user.name = "John";
    user.email = "invalid-email";
    user.valid();
    
    assert("ArrayLen(user.errorsOn('email')) > 0");
    
    user.email = "john@example.com";
    assert("user.valid()");
  }
  
  function test_associations() {
    user = model("User").findOne(include="posts");
    
    assert("IsObject(user)");
    assert("IsArray(user.posts)");
  }
  
  function test_callbacks() {
    user = model("User").create(
      name="  John Doe  ",
      email="  JOHN@EXAMPLE.COM  "
    );
    
    // sanitizeInput callback should trim and lowercase
    assert("user.email == 'john@example.com'");
    assert("user.name == 'John Doe'");
  }
}
```

### 6. Migration Patterns

#### Create Table Migration
```cfml
component extends="wheels.migrator.Migration" {
  
  function up() {
    transaction {
      createTable(name="posts", id=true, force=true) {
        t.string(columnNames="title", limit=255, null=false);
        t.text(columnNames="body");
        t.integer(columnNames="userId", null=false);
        t.string(columnNames="status", limit=20, default="draft");
        t.boolean(columnNames="published", default=false);
        t.timestamps();
      };
      
      addIndex(table="posts", columnNames="userId");
      addIndex(table="posts", columnNames="status,published");
    }
  }
  
  function down() {
    transaction {
      dropTable("posts");
    }
  }
}
```

#### Add Column Migration
```cfml
component extends="wheels.migrator.Migration" {
  
  function up() {
    transaction {
      addColumn(
        table="users",
        columnName="lastLoginAt",
        columnType="datetime",
        null=true
      );
      
      addColumn(
        table="users",
        columnName="loginCount",
        columnType="integer",
        null=false,
        default=0
      );
    }
  }
  
  function down() {
    transaction {
      removeColumn(table="users", columnName="lastLoginAt");
      removeColumn(table="users", columnName="loginCount");
    }
  }
}
```

## Common Anti-Patterns to Avoid

### 1. Using init() instead of config()
```cfml
// WRONG
component extends="Model" {
  function init() {
    // This won't work!
  }
}

// CORRECT
component extends="Model" {
  function config() {
    // Configuration goes here
  }
}
```

### 2. Calling $ prefixed methods from application code
```cfml
// WRONG
user.$save();

// CORRECT
user.save();
```

### 3. Not checking for object existence
```cfml
// WRONG
post = model("Post").findByKey(params.key);
post.update(params.post); // Will error if post not found

// CORRECT
post = model("Post").findByKey(params.key);
if (IsObject(post)) {
  post.update(params.post);
} else {
  redirectTo(route="posts");
}
```

### 4. Forgetting content negotiation in API controllers
```cfml
// WRONG
component extends="Controller" {
  function index() {
    users = model("User").findAll();
    // Will try to render HTML view
  }
}

// CORRECT
component extends="Controller" {
  function config() {
    provides("json");
  }
  
  function index() {
    users = model("User").findAll();
    renderWith(users); // Will render JSON
  }
}
```

### 5. Not using transactions in migrations
```cfml
// WRONG
function up() {
  createTable("users");
  addIndex(table="users", columnNames="email");
}

// CORRECT
function up() {
  transaction {
    createTable("users");
    addIndex(table="users", columnNames="email");
  }
}
```

## Quick Reference

### Model Methods
- `findAll()` - Find all records
- `findOne()` - Find first record
- `findByKey()` - Find by primary key
- `create()` - Create new record
- `update()` - Update existing record
- `save()` - Save record (create or update)
- `delete()` - Delete record
- `new()` - Create new instance
- `valid()` - Run validations
- `hasErrors()` - Check for validation errors

### Controller Methods
- `renderView()` - Render specific view
- `renderWith()` - Render with content negotiation
- `renderText()` - Render plain text
- `redirectTo()` - Redirect to route or URL
- `flashInsert()` - Add flash message
- `provides()` - Set content types
- `filters()` - Set before/after filters

### View Helpers
- `linkTo()` - Create links
- `startFormTag()`/`endFormTag()` - Form tags
- `textField()` - Text input
- `textArea()` - Textarea
- `select()` - Select dropdown
- `checkBox()` - Checkbox
- `radioButton()` - Radio button
- `submitTag()` - Submit button
- `errorMessagesFor()` - Display errors
- `includePartial()` - Include partial view