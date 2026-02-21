# Query Scopes

## Description

Query scopes let you define reusable query fragments in your model's `config()` method and compose them together using a fluent, chainable API. Instead of repeating the same `where`, `order`, or `include` arguments across your controllers, you define them once as named scopes and call them like methods on the model.

## Key Points

- Defined in `config()` using the `scope()` function
- Called as methods directly on the model: `model("User").active()`
- Chainable: `model("User").active().recent().findAll()`
- Support static arguments (`where`, `order`, `select`, `include`, `maxRows`)
- Support dynamic arguments via a `handler` function
- Compose with all terminal finder methods: `findAll()`, `findOne()`, `count()`, `exists()`, `sum()`, `average()`, `minimum()`, `maximum()`, `updateAll()`, `deleteAll()`, `findEach()`, `findInBatches()`
- Multiple `where` clauses are combined with `AND`
- Multiple `order` clauses are appended together
- Multiple `include` clauses are merged

## Defining Scopes

### Static Scopes

Static scopes use fixed query arguments that don't change at call time.

```cfm
component extends="Model" {
    function config() {
        // Filter by a WHERE condition
        scope(name="active", where="status = 'active'");

        // Order results
        scope(name="recent", order="createdAt DESC");

        // Combine WHERE + ORDER
        scope(name="recentlyActive", where="status = 'active'", order="createdAt DESC");

        // Limit results
        scope(name="topTen", order="score DESC", maxRows=10);

        // Select specific columns
        scope(name="nameOnly", select="id,firstName,lastName");

        // Eagerly load associations
        scope(name="withOrders", include="orders");
    }
}
```

### Dynamic Scopes

Dynamic scopes accept parameters at call time. Define them with the `handler` argument pointing to a private method on your model. The handler receives whatever arguments the caller passes and must return a struct with valid query keys (`where`, `order`, `select`, `include`, `maxRows`).

```cfm
component extends="Model" {
    function config() {
        scope(name="byRole", handler="scopeByRole");
        scope(name="createdAfter", handler="scopeCreatedAfter");
        scope(name="search", handler="scopeSearch");
    }

    private struct function scopeByRole(required string role) {
        return {where: "role = '#arguments.role#'"};
    }

    private struct function scopeCreatedAfter(required date startDate) {
        return {
            where: "createdAt >= '#DateFormat(arguments.startDate, 'yyyy-mm-dd')#'",
            order: "createdAt ASC"
        };
    }

    private struct function scopeSearch(required string term) {
        return {
            where: "firstName LIKE '%#arguments.term#%' OR lastName LIKE '%#arguments.term#%' OR email LIKE '%#arguments.term#%'"
        };
    }
}
```

## Using Scopes

### Basic Usage

```cfm
// In a controller action
function index() {
    // Single scope
    users = model("User").active().findAll();

    // Chain multiple scopes — WHERE clauses are AND'd, ORDER BY clauses are appended
    users = model("User").active().recent().findAll();

    // Dynamic scope with parameter
    admins = model("User").byRole("admin").findAll();

    // Scopes with additional finder arguments
    users = model("User").active().findAll(page=params.page, perPage=25);
}
```

### Chaining Scopes Together

When you chain scopes, their query fragments are merged:

```cfm
// Given these scopes:
//   active  -> where="status = 'active'"
//   recent  -> order="createdAt DESC"
//   topTen  -> order="score DESC", maxRows=10

// This:
model("User").active().recent().findAll();

// Produces a query equivalent to:
model("User").findAll(where="status = 'active'", order="createdAt DESC");
```

**Merge rules:**
- `where` clauses are combined with `AND`: `(scope1.where) AND (scope2.where)`
- `order` clauses are appended: `scope1.order, scope2.order`
- `include` clauses are appended: `scope1.include, scope2.include`
- `select` takes the last scope's value (overrides earlier scopes)
- `maxRows` takes the smallest value when multiple scopes specify it

### Terminal Methods

Scope chains are lazy — nothing hits the database until you call a terminal method:

```cfm
// Retrieve records
users = model("User").active().findAll();
user  = model("User").active().findOne();
user  = model("User").active().findByKey(42);
user  = model("User").active().findFirst();

// Aggregations
total   = model("User").active().count();
found   = model("User").active().exists();
avgAge  = model("User").active().average(property="age");
total   = model("User").active().sum(property="balance");
oldest  = model("User").active().minimum(property="createdAt");
newest  = model("User").active().maximum(property="createdAt");

// Bulk operations
model("User").active().updateAll(status="archived");
model("User").active().deleteAll();

// Batch processing
model("User").active().findEach(batchSize=500, callback=function(user) {
    user.sendReminder();
});
```

### Combining Scopes with the Query Builder

Scopes and the chainable query builder work together. Start with a scope, then add builder conditions:

```cfm
// Start with scope, then add query builder conditions
model("User")
    .active()
    .where("age", ">", 21)
    .orderBy("lastName", "ASC")
    .get();
```

## scope() Reference

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | string | *required* | The scope name. Becomes a callable method on the model. |
| `where` | string | `""` | A WHERE clause fragment. |
| `order` | string | `""` | An ORDER BY clause fragment. |
| `select` | string | `""` | A SELECT clause override. |
| `include` | string | `""` | Associations to include (join). |
| `maxRows` | numeric | `0` | Maximum records to return (0 = unlimited). |
| `handler` | string | `""` | Name of a private model method for dynamic scopes. |

## Common Patterns

### Default Scope via Controller Filter

```cfm
// In your controller
component extends="Controller" {
    function config() {
        filters(through="loadActiveUsers", only="index");
    }

    function index() {
        // users already scoped to active by the filter
    }

    private function loadActiveUsers() {
        users = model("User").active().recent().findAll(page=params.page, perPage=25);
    }
}
```

### Scope per Status

```cfm
component extends="Model" {
    function config() {
        scope(name="draft", where="status = 'draft'");
        scope(name="published", where="status = 'published'");
        scope(name="archived", where="status = 'archived'");
    }
}

// Usage
drafts    = model("Post").draft().findAll();
published = model("Post").published().recent().findAll();
```

> **Tip:** If you're defining scopes for every value of a property, consider using `enum()` instead — it generates scopes automatically. See the [Enums documentation](enums.md).
