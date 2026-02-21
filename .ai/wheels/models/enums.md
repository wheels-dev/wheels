# Enums

## Description

Enums map a model property to a fixed set of named values — similar to database enums but defined at the application level. When you declare an enum, Wheels automatically generates boolean checker methods (`is<Value>()`), query scopes for each value, and an inclusion validation ensuring only valid values can be saved.

## Key Points

- Defined in `config()` using the `enum()` function
- Accepts a comma-delimited list of values **or** a struct mapping names to stored values
- Auto-generates `is<Value>()` boolean instance methods on model objects
- Auto-generates query scopes for each value (e.g., `model("Post").draft()`)
- Auto-registers a `validatesInclusionOf()` validation
- Works with both string-based and numeric-backed enums

## Defining Enums

### String-Based Enums

When values are a simple comma-delimited list, each name is also the stored database value:

```cfm
component extends="Model" {
    function config() {
        enum(property="status", values="draft,published,archived");
    }
}
```

This stores literal strings `"draft"`, `"published"`, and `"archived"` in the `status` column.

### Numeric-Backed Enums

When values are a struct, the keys are human-readable names and the values are what gets stored in the database:

```cfm
component extends="Model" {
    function config() {
        enum(property="priority", values={low: 0, medium: 1, high: 2});
    }
}
```

This stores `0`, `1`, or `2` in the `priority` column, but you interact with them by name.

### Multiple Enums per Model

You can define as many enums as you need:

```cfm
component extends="Model" {
    function config() {
        enum(property="status", values="draft,published,archived");
        enum(property="visibility", values="public,private,unlisted");
        enum(property="priority", values={low: 0, medium: 1, high: 2});
    }
}
```

## Auto-Generated Methods

### Boolean Checkers: `is<Value>()`

For each enum value, Wheels generates a boolean checker method on model instances. The method name is `is` followed by the capitalized value name.

```cfm
// Given: enum(property="status", values="draft,published,archived")
post = model("Post").findByKey(1);

post.isDraft();      // true if post.status == "draft"
post.isPublished();  // true if post.status == "published"
post.isArchived();   // true if post.status == "archived"
```

For numeric-backed enums, the checker compares against the stored value:

```cfm
// Given: enum(property="priority", values={low: 0, medium: 1, high: 2})
task = model("Task").findByKey(1);

task.isLow();    // true if task.priority == 0
task.isMedium(); // true if task.priority == 1
task.isHigh();   // true if task.priority == 2
```

**Use in views:**

```cfm
<cfparam name="post" default="">

<cfif post.isPublished()>
    <span class="badge badge-success">Published</span>
<cfelseif post.isDraft()>
    <span class="badge badge-warning">Draft</span>
<cfelse>
    <span class="badge badge-secondary">Archived</span>
</cfif>
```

### Auto-Generated Scopes

Each enum value becomes a query scope, letting you filter records by value:

```cfm
// Given: enum(property="status", values="draft,published,archived")

// Find all published posts
published = model("Post").published().findAll();

// Find all drafts, ordered by creation date
drafts = model("Post").draft().findAll(order="createdAt DESC");

// Count archived posts
archiveCount = model("Post").archived().count();

// Chain with other scopes or query builder
model("Post").published().where("authorId", 5).get();
```

For numeric-backed enums, the scope matches the stored value:

```cfm
// Given: enum(property="priority", values={low: 0, medium: 1, high: 2})

highPriorityTasks = model("Task").high().findAll();
lowPriorityCount  = model("Task").low().count();
```

### Automatic Validation

Enums automatically register a `validatesInclusionOf()` on the property, restricting it to the defined values. The validation allows blank values (so you can combine with `validatesPresenceOf()` if you want to require the field).

```cfm
// Given: enum(property="status", values="draft,published,archived")

post = model("Post").new(status="invalid_value");
post.valid();  // false
post.errorsOn("status");  // "is not included in the list"

post.status = "draft";
post.valid();  // true (for this validation)
```

To also require the property, add an explicit presence validation:

```cfm
function config() {
    enum(property="status", values="draft,published,archived");
    validatesPresenceOf("status");
}
```

## enum() Reference

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `property` | string | Yes | The model property to map as an enum. |
| `values` | string or struct | Yes | Comma-delimited list of value names (string-based) or a struct mapping names to stored values (numeric-backed). |

## Common Patterns

### Status Workflow

```cfm
component extends="Model" {
    function config() {
        enum(property="status", values="pending,approved,rejected");

        // Callbacks based on status changes
        beforeSave("notifyOnApproval");
    }

    private function notifyOnApproval() {
        if (hasChanged("status") && this.isApproved()) {
            // Send approval notification
        }
    }
}
```

### Conditional Logic in Controllers

```cfm
function publish() {
    post = model("Post").findByKey(params.key);
    if (post.isDraft()) {
        post.status = "published";
        post.save();
        redirectTo(route="post", key=post.id);
    } else {
        flashInsert(error="Only drafts can be published.");
        redirectTo(route="post", key=post.id);
    }
}
```

### Select Dropdown from Enum Values

Since enum values are defined in the model, you can build form selects from them:

```cfm
<!--- In the controller --->
function edit() {
    post = model("Post").findByKey(params.key);
    statusOptions = "draft,published,archived";
}

<!--- In the view --->
<cfparam name="post" default="">
<cfparam name="statusOptions" default="">

#selectTag(
    name="post[status]",
    options=statusOptions,
    selected=post.status,
    label="Status"
)#
```

### Combining Enums with Query Builder

```cfm
// Use enum scopes as starting points for complex queries
model("Task")
    .high()
    .where("assignedTo", currentUser.id)
    .whereNull("completedAt")
    .orderBy("dueDate")
    .get();
```
