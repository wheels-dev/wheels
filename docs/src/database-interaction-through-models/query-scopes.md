# Query Scopes

Query scopes let you define reusable, composable query fragments on your models. Instead of repeating the same `where` or `order` clauses across your application, define them once in the model's `config()` and chain them together.

## Defining Scopes

Add scopes in your model's `config()` function using `scope()`:

```cfm
component extends="Model" {
    function config() {
        // Static scopes — fixed query fragments
        scope(name="active", where="status = 'active'");
        scope(name="recent", order="createdAt DESC");
        scope(name="limited", maxRows=10);

        // Dynamic scope — accepts arguments at call time
        scope(name="byRole", handler="scopeByRole");
    }

    private struct function scopeByRole(required string role) {
        return {where: "role = '#arguments.role#'"};
    }
}
```

### Static Scopes

Static scopes define a fixed set of query parameters. The `scope()` function accepts these keys:

| Parameter | Description |
|-----------|-------------|
| `name` | The scope name (becomes the chainable method) |
| `where` | SQL WHERE clause fragment |
| `order` | SQL ORDER BY clause |
| `select` | Columns to select |
| `include` | Associated models to include |
| `maxRows` | Limit the number of rows returned |

### Dynamic Scopes

Dynamic scopes use a `handler` function that returns a struct of query parameters. The handler receives whatever arguments the caller passes:

```cfm
scope(name="olderThan", handler="scopeOlderThan");

private struct function scopeOlderThan(required numeric age) {
    return {where: "age > #arguments.age#"};
}
```

## Using Scopes

Call scopes as methods on the model, then finish with a terminal method like `findAll()`, `findOne()`, `count()`, or `exists()`:

```cfm
// Single scope
users = model("User").active().findAll();

// Chained scopes — conditions are AND'd together
users = model("User").active().recent().findAll();

// Dynamic scope with argument
admins = model("User").byRole("admin").findAll();

// With additional finder arguments
users = model("User").active().findAll(page=1, perPage=25);
```

## How Scopes Combine

When you chain multiple scopes:

- **WHERE** clauses are combined with `AND`
- **ORDER BY** clauses are appended (first scope's order comes first)
- **INCLUDE** clauses are appended
- **SELECT** uses the last scope's value (last wins)
- **maxRows** uses the smallest value

```cfm
// These two WHERE clauses become: (status = 'active') AND (role = 'admin')
model("User").active().byRole("admin").findAll();
```

## Terminal Methods

After building a scope chain, call one of these to execute the query:

| Method | Returns |
|--------|---------|
| `findAll()` | Query result set |
| `findOne()` | Single model object |
| `findByKey(key)` | Model object by primary key |
| `count()` | Number of matching records |
| `exists()` | Boolean |
| `average(property)` | Average value |
| `sum(property)` | Sum of values |
| `maximum(property)` | Maximum value |
| `minimum(property)` | Minimum value |
| `updateAll(...)` | Updates matching records |
| `deleteAll()` | Deletes matching records |
| `findEach(callback)` | Batch iteration (one at a time) |
| `findInBatches(callback)` | Batch iteration (groups) |

## Transitioning to the Query Builder

You can move from a scope chain into the chainable query builder at any point:

```cfm
model("User")
    .active()
    .where("age", ">", 18)
    .orderBy("name", "ASC")
    .get();
```

See [Query Builder](query-builder.md) for the full fluent API.
