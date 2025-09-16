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
- Supports cascading deletes with `dependent` option