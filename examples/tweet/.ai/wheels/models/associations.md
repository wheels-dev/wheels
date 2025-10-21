# Model Associations

## Critical Understanding

**🚨 CRITICAL**: Association methods in Wheels return QUERY objects, not arrays. This is essential to understand for views and controllers.

## Association Return Types and Usage

### Understanding Query Returns
```cfm
// All association methods return QUERIES
user = model("User").findByKey(1);
posts = user.posts();           // Returns QUERY, not array
comments = post.comments();     // Returns QUERY, not array

// Use query methods and properties
postCount = user.posts().recordCount;        // ✅ CORRECT
commentCount = post.comments().recordCount;  // ✅ CORRECT

// NOT array methods
postCount = ArrayLen(user.posts());          // ❌ ERROR!
commentCount = ArrayLen(post.comments());    // ❌ ERROR!

// Loop as queries, not arrays
<cfloop query="user.posts()">               // ✅ CORRECT
    #user.posts().title#
</cfloop>

<cfloop array="#user.posts()#" index="post"> // ❌ ERROR!
    #post.title#
</cfloop>
```

## Association Types

### belongsTo (Many-to-One)

Defines a relationship where this model belongs to another model. Used when this model's table contains a foreign key.

**Basic Syntax:**
```cfm
component extends="Model" {
    function config() {
        // Post belongs to User (author)
        belongsTo("author", modelName="User", foreignKey="authorid");

        // Order belongs to Customer (uses convention: customerid)
        belongsTo("customer");

        // Comment belongs to Post (uses convention: postid)
        belongsTo("post");
    }
}
```

**Usage Examples:**
```cfm
// Get the associated parent
post = model("Post").findByKey(1);
author = post.author();  // Returns User object or null

// Check if association exists
if (isObject(post.author())) {
    authorName = post.author().name;
}

// Use in queries
posts = model("Post").findAll(include="author");
```

### hasMany (One-to-Many)

Defines a relationship where this model has many of another model. The other model's table contains the foreign key.

**Basic Syntax:**
```cfm
component extends="Model" {
    function config() {
        // User has many Posts (posts table has authorid)
        hasMany("posts", foreignKey="authorid");

        // Category has many Products (products table has categoryid)
        hasMany("products");

        // Post has many Comments with dependent delete
        hasMany(name="comments", dependent="delete");
    }
}
```

**Usage Examples:**
```cfm
// Get associated records
user = model("User").findByKey(1);
posts = user.posts();  // Returns QUERY of posts

// Count associated records
postCount = user.posts().recordCount;

// Get with conditions
recentPosts = user.posts(where="createdat > '#dateAdd("d", -30, now())#'");

// Check if has any
if (user.posts().recordCount > 0) {
    // User has posts
}
```

### hasOne (One-to-One)

Defines a relationship where this model has exactly one of another model.

**Basic Syntax:**
```cfm
component extends="Model" {
    function config() {
        // User has one Profile
        hasOne(name="profile", dependent="delete");

        // Product has one Inventory record
        hasOne("inventory");
    }
}
```

**Usage Examples:**
```cfm
// Get the associated record
user = model("User").findByKey(1);
profile = user.profile();  // Returns Profile object or null

// Check if exists
if (isObject(user.profile())) {
    bio = user.profile().bio;
}
```

### Many-to-Many Associations

Wheels handles many-to-many relationships through join tables and shortcut associations.

**Setup with Join Table:**
```cfm
// User model
component extends="Model" {
    function config() {
        // Direct relationship to join table
        hasMany("userRoles");

        // Shortcut to final destination
        hasMany(name="userRoles", shortcut="roles");
    }
}

// Role model
component extends="Model" {
    function config() {
        hasMany("userRoles");
        hasMany(name="userRoles", shortcut="users");
    }
}

// UserRole join model
component extends="Model" {
    function config() {
        belongsTo("user");
        belongsTo("role");
    }
}
```

**Usage Examples:**
```cfm
// Get many-to-many associated records
user = model("User").findByKey(1);
roles = user.roles();  // Returns QUERY of roles through userRoles

// Check for specific association
hasAdminRole = user.roles().exists(where="name = 'admin'");

// Add association (create join record)
adminRole = model("Role").findByName("admin");
if (isObject(adminRole)) {
    model("UserRole").create(userid=user.id, roleid=adminRole.id);
}
```

## Dynamic Association Methods

Wheels automatically creates dynamic methods for each association:

### hasMany Dynamic Methods
```cfm
// Given: Post hasMany("comments")
post = model("Post").findByKey(1);

// Get all comments
comments = post.comments();

// Get comments with conditions
recentComments = post.comments(where="createdat > '#dateAdd("d", -7, now())#'");

// Count comments
commentCount = post.commentCount();

// Check if has comments
hasComments = post.hasComments();

// Create new comment
newComment = post.createComment(content="Great post!", authorName="John");

// Add existing comment (sets foreign key)
post.addComment(existingComment);

// Remove comment (sets foreign key to null)
post.removeComment(comment);

// Delete comment (removes from database)
post.deleteComment(comment);
```

### belongsTo Dynamic Methods
```cfm
// Given: Comment belongsTo("post")
comment = model("Comment").findByKey(1);

// Get associated post
post = comment.post();

// Check if has post
hasPost = comment.hasPost();

// Set associated post
comment.setPost(newPost);
```

### hasOne Dynamic Methods
```cfm
// Given: User hasOne("profile")
user = model("User").findByKey(1);

// Get profile
profile = user.profile();

// Check if has profile
hasProfile = user.hasProfile();

// Create profile
newProfile = user.createProfile(bio="User bio", location="City");

// Set profile
user.setProfile(existingProfile);

// Remove profile (sets foreign key to null)
user.removeProfile();

// Delete profile (removes from database)
user.deleteProfile();
```

## Association Options

### Common Options for All Associations
```cfm
function config() {
    // Custom model name
    belongsTo(name="author", modelName="User");

    // Custom foreign key
    hasMany(name="posts", foreignKey="authorid");

    // Custom join type for includes
    hasMany(name="comments", joinType="LEFT OUTER JOIN");
}
```

### Dependent Options
```cfm
function config() {
    // Delete associated records when parent is deleted
    hasMany(name="comments", dependent="delete");
    hasOne(name="profile", dependent="delete");

    // Set foreign key to null when parent is deleted
    hasMany(name="posts", dependent="nullify");
}
```

### Advanced Association Configuration
```cfm
function config() {
    // Complex association with conditions
    hasMany(
        name="publishedPosts",
        modelName="Post",
        foreignKey="authorid",
        where="status = 'published'"
    );

    // Association with custom order
    hasMany(
        name="recentComments",
        modelName="Comment",
        foreignKey="postid",
        order="createdat DESC"
    );
}
```

## Eager Loading with Includes

Prevent N+1 query problems by loading associations upfront:

### Basic Includes
```cfm
// Load posts with their authors
posts = model("Post").findAll(include="author");

// Load users with their posts and comments
users = model("User").findAll(include="posts,comments");

// Load with nested associations
posts = model("Post").findAll(include="author(profile)");
```

### Complex Includes
```cfm
// Multiple levels of nesting
posts = model("Post").findAll(
    include="author(profile(country)),category,comments(author)"
);

// Include with conditions
posts = model("Post").findAll(
    include="comments",
    where="posts.status = 'published' AND comments.approved = 1"
);
```

## Association Best Practices

### 1. Argument Consistency
```cfm
// ✅ CORRECT: All named arguments
hasMany(name="comments", dependent="delete", foreignKey="postid");

// ✅ CORRECT: All positional arguments
hasMany("comments");

// ❌ INCORRECT: Mixed argument styles
hasMany("comments", dependent="delete");  // This will cause errors
```

### 2. Understanding Return Types
```cfm
// ✅ CORRECT: Use query methods
postCount = user.posts().recordCount;
if (user.posts().recordCount > 0) { /* */ }

// ❌ INCORRECT: Treat as arrays
postCount = ArrayLen(user.posts());     // ERROR!
if (ArrayLen(user.posts()) > 0) { /* */ }  // ERROR!
```

### 3. Efficient Querying
```cfm
// ✅ GOOD: Use includes to avoid N+1 queries
posts = model("Post").findAll(include="author,comments");

// ❌ BAD: Causes N+1 queries
posts = model("Post").findAll();
for (post in posts) {
    author = post.author();  // Separate query for each post
}
```

### 4. Proper Loop Syntax
```cfm
// ✅ CORRECT: Store query result before looping
<cfset comments = post.comments()>
<cfloop query="comments">
    <p>#comments.content#</p>
</cfloop>

// ❌ INCORRECT: Method call in loop attribute
<cfloop query="post.comments()">  // Will cause errors
    <p>#post.comments().content#</p>
</cfloop>
```

## Common Errors and Solutions

### Error: "Invalid variable declaration"
```cfm
// ❌ PROBLEM
<cfloop query="user.posts()">
    #user.posts().title#
</cfloop>

// ✅ SOLUTION
<cfset posts = user.posts()>
<cfloop query="posts">
    #posts.title#
</cfloop>
```

### Error: "Component has no accessible Member with name [ARRAYLEN]"
```cfm
// ❌ PROBLEM
postCount = ArrayLen(user.posts());

// ✅ SOLUTION
postCount = user.posts().recordCount;
```

### Error: "Missing argument name"
```cfm
// ❌ PROBLEM: Mixed argument styles
hasMany("comments", dependent="delete");

// ✅ SOLUTION: Consistent argument style
hasMany(name="comments", dependent="delete");
// OR
hasMany("comments");
```

## Testing Associations

### Basic Association Tests
```cfm
function testUserHasManyPosts() {
    user = model("User").create(name="John", email="john@example.com");
    post1 = model("Post").create(title="Post 1", authorid=user.id);
    post2 = model("Post").create(title="Post 2", authorid=user.id);

    posts = user.posts();
    assert(posts.recordCount == 2, "User should have 2 posts");
}

function testPostBelongsToUser() {
    user = model("User").create(name="John", email="john@example.com");
    post = model("Post").create(title="My Post", authorid=user.id);

    author = post.author();
    assert(isObject(author), "Post should have an author");
    assert(author.id == user.id, "Post author should be the correct user");
}
```

## Related Documentation
- [Model Architecture](./architecture.md)
- [Advanced Patterns](./advanced-patterns.md)
- [Common Errors](../../troubleshooting/common-errors.md)
- [Performance Optimization](../patterns/performance.md)