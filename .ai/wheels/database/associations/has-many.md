# Has Many Association

## Description
Defines a one-to-many relationship where the current model owns multiple records of another model.

## Key Points
- Use `hasMany()` in model's `config()` method
- Use plural form for association name
- Foreign key assumed to be `modelName + "Id"`
- Generates convenience methods for accessing related records
- Supports through associations for many-to-many relationships

## Code Sample
```cfm
// Post model - a post has many comments
component extends="Model" {
    function config() {
        hasMany("comments");

        // Custom foreign key
        hasMany("reviews", foreignKey="postId");

        // Many-to-many through join table
        hasMany("tags", through="posttags");

        // With conditions
        hasMany("publishedComments",
               modelName="comment",
               where="published = 1");
    }
}

// Usage in controllers/views
post = model("post").findByKey(1);
comments = post.comments();              // Get all comments
newComment = post.newComment();          // Create associated comment
post.addComment(comment);                // Add existing comment
post.removeComment(comment);             // Remove association
hasComments = post.hasComments();        // Check if has comments
```

## Usage
1. Add `hasMany("associationName")` in model's `config()` method
2. Use plural association name (comments, orders, tags)
3. Access via generated methods: `object.associationName()`
4. Create new associated objects: `object.newAssociationName()`
5. Add/remove associations: `addAssociationName()`, `removeAssociationName()`

## Related
- [Belongs To Association](./belongs-to.md)
- [Has One Association](./has-one.md)
- [Nested Properties](./nested-properties.md)

## Important Notes
- Always use plural form for hasMany associations
- Corresponding belongsTo should exist in related model
- Foreign key must exist in related table
- Use `through` parameter for many-to-many relationships

## ⚠️ CRITICAL: Association Parameter Syntax

**The Real Issue: Mixed Positional and Named Parameters**
CFWheels DOES support the `dependent` parameter, but requires consistent parameter syntax:

```cfm
<!-- ❌ INCORRECT - Mixed positional and named parameters -->
hasMany("comments", dependent="delete");    <!-- Error: can't mix parameter styles -->
hasMany("orders", dependent="destroy");     <!-- Error: can't mix parameter styles -->

<!-- ✅ CORRECT - Consistent named parameters -->
hasMany(name="comments", dependent="delete");
hasMany(name="orders", dependent="deleteAll");

<!-- ✅ ALSO CORRECT - All positional parameters (no dependent options) -->
hasMany("comments");
hasMany("orders");
```

**Available dependent options:**
- `dependent="delete"` - Delete associated records when parent is deleted
- `dependent="deleteAll"` - Delete all associated records (faster, no callbacks)
- `dependent="nullify"` - Set foreign key to NULL when parent is deleted

**Alternative Cascade Delete Approaches:**

When not using the `dependent` parameter, you have these options:

1. **Database-level cascade**: Set up foreign key constraints with CASCADE DELETE
2. **Model callbacks**: Implement deletion logic in `beforeDelete` callbacks
3. **Controller logic**: Handle related record deletion in controller actions

```cfm
// Option 2: Model callback approach
component extends="Model" {
    function config() {
        hasMany("comments");
        beforeDelete("deleteAssociatedComments");
    }

    private function deleteAssociatedComments() {
        // Delete associated comments before post deletion
        model("Comment").deleteAll(where="postId = #this.id#");
    }
}

// Option 3: Controller approach
function delete() {
    post = model("Post").findByKey(params.key);

    // Delete comments first
    model("Comment").deleteAll(where="postId = #post.id#");

    // Then delete post
    post.delete();

    redirectTo(route="posts", success="Post deleted successfully!");
}
```

## Rails vs CFWheels Association Differences

CFWheels associations are simpler than Rails but lack some advanced features:

```cfm
// ✅ CFWheels - Simple and clean
hasMany("comments");
hasMany("tags", through="postTags");
hasMany("activeComments", modelName="Comment", where="approved = 1");

// ❌ Rails syntax that doesn't work in CFWheels
hasMany("comments", dependent: :destroy, validate: false, autosave: true);
hasMany("comments", -> { where(approved: true) }, dependent: :delete_all);
```