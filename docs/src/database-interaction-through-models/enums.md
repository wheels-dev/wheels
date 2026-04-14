# Enums

Enums let you define a fixed set of allowed values for a model property. Wheels automatically generates boolean checker methods, query scopes, and inclusion validation for each enum.

## Defining Enums

Add enums in your model's `config()` function:

```cfm
component extends="Model" {
    function config() {
        // String list — each value is both the name and stored value
        enum(property="status", values="draft,published,archived");

        // Struct mapping — names map to different stored values
        enum(property="priority", values={low: 0, medium: 1, high: 2});
    }
}
```

### String List

When you pass a comma-delimited string, each value serves as both the display name and the stored database value:

```cfm
enum(property="status", values="draft,published,archived");
// Stores "draft", "published", or "archived" in the database
```

### Struct Mapping

When you pass a struct, the keys are the names and the values are what gets stored in the database:

```cfm
enum(property="priority", values={low: 0, medium: 1, high: 2});
// Stores 0, 1, or 2 in the database
```

## What Enums Generate

Defining an enum automatically creates three things:

### 1. Boolean Checker Methods

For each enum value, an `is<Value>()` method is generated on model instances:

```cfm
post = model("Post").findByKey(1);

post.isDraft();      // true or false
post.isPublished();  // true or false
post.isArchived();   // true or false
```

### 2. Query Scopes

Each enum value becomes a named scope you can chain:

```cfm
// Find all draft posts
drafts = model("Post").draft().findAll();

// Find all published posts, ordered by date
published = model("Post").published().findAll(order="createdAt DESC");

// Count archived posts
archivedCount = model("Post").archived().count();
```

### 3. Inclusion Validation

A `validatesInclusionOf` validation is automatically registered, preventing invalid values:

```cfm
post = model("Post").new();
post.status = "invalid_value";
post.valid();  // false — "invalid_value" is not in the enum

post.status = "published";
post.valid();  // true (assuming other validations pass)
post.errorsOn("status");  // empty array
```

The validation uses `allowBlank=true`, so blank/empty values are permitted unless you add a separate `validatesPresenceOf`.

## Examples

### Filtering by Enum Value

```cfm
// Using auto-generated scopes
model("Post").published().findAll(page=1, perPage=25);

// Using standard WHERE clause
model("Post").findAll(where="status = 'published'");

// Using query builder
model("Post").where("status", "published").get();
```

### Checking State in Views

```cfm
<cfif post.isPublished()>
    <span class="badge badge-success">Published</span>
<cfelseif post.isDraft()>
    <span class="badge badge-warning">Draft</span>
<cfelse>
    <span class="badge badge-secondary">Archived</span>
</cfif>
```

### Combining Scopes

```cfm
// Enum scopes compose with other scopes
model("Post").published().recent().findAll();
```
