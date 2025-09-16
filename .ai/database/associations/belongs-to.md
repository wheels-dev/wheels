# Belongs To Association

## Description
Defines a many-to-one relationship where the current model belongs to another model via a foreign key.

## Key Points
- Use `belongsTo()` in model's `config()` method
- Use singular form for association name
- Foreign key column must exist in current model's table
- Generates convenience methods for accessing parent record
- Typically paired with hasMany in related model

## Code Sample
```cfm
// Comment model - a comment belongs to a post
component extends="Model" {
    function config() {
        belongsTo("post");

        // Custom foreign key
        belongsTo("author", modelName="user", foreignKey="authorId");

        // Multiple belongs to relationships
        belongsTo("category");
        belongsTo("user");
    }
}

// Usage in controllers/views
comment = model("comment").findByKey(1);
post = comment.post();                   // Get associated post
author = comment.author();               // Get associated author

// Create comment with association
comment = model("comment").new();
comment.postId = 5;                      // Set foreign key
comment.post(model("post").findByKey(5)); // Or set object directly
```

## Usage
1. Add `belongsTo("associationName")` in model's `config()` method
2. Use singular association name (post, user, category)
3. Ensure foreign key column exists in current table
4. Access via generated method: `object.associationName()`
5. Set association: `object.associationName(otherObject)`

## Related
- [Has Many Association](./has-many.md)
- [Has One Association](./has-one.md)
- [Finding Records](../queries/finding-records.md)

## Important Notes
- Always use singular form for belongsTo associations
- Foreign key must exist in current model's table
- Use `modelName` parameter if association name differs from model
- Use `foreignKey` parameter for non-standard foreign key names
- Supports polymorphic associations with `type` column