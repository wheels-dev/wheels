# Nested Properties

## Description
Allows saving associated models through nested attributes from form submissions and complex data structures.

## Key Points
- Enable with `nestedProperties()` in model configuration
- Supports hasMany, hasOne, and belongsTo associations
- Handles create, update, and delete of associated records
- Automatic validation of nested objects
- Useful for complex forms with multiple models

## Code Sample
```cfm
// Post model with nested comments
component extends="Model" {
    function config() {
        hasMany("comments");
        nestedProperties(association="comments", allowDelete=true);

        // Multiple nested properties
        hasOne("author");
        nestedProperties(association="author");
    }
}

// Controller handling nested form submission
function create() {
    post = model("post").new(params.post);

    // params.post might contain:
    // {
    //   title: "My Post",
    //   body: "Content...",
    //   comments: [
    //     {body: "Great post!", authorName: "John"},
    //     {body: "Thanks!", authorName: "Jane"}
    //   ]
    // }

    if (post.save()) {
        redirectTo(route="post", key=post.id);
    } else {
        renderView(action="new");
    }
}
```

## Usage
1. Add `nestedProperties(association="name")` in model's `config()`
2. Use `allowDelete=true` to enable record deletion
3. Submit nested data as arrays (hasMany) or structs (hasOne/belongsTo)
4. Call `save()` on parent object to save all nested data
5. Handle validation errors for both parent and nested objects

## Related
- [Has Many Association](./has-many.md)
- [Form Helpers](../../views/helpers/forms.md)
- [Object Validation](../validations/presence.md)

## Important Notes
- Nested properties require existing associations
- Use `allowDelete=true` carefully - enables record deletion
- Validations run on all nested objects
- Complex forms benefit from nested properties
- Transaction safety - all or nothing saves