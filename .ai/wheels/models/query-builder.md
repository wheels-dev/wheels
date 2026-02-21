# Chainable Query Builder

## Description

The chainable query builder provides a fluent, object-oriented alternative to the traditional `findAll(where="...")` string-based approach. Instead of manually constructing SQL strings, you build queries by chaining method calls. All values are automatically quoted using the model's database adapter, preventing SQL injection.

## Key Points

- Start a chain by calling `.where()`, `.orderBy()`, `.limit()`, etc. directly on a model
- All values are auto-quoted based on the column's data type — injection-safe by default
- Finish the chain with a terminal method: `.get()`, `.first()`, `.count()`, `.exists()`, etc.
- Composes with query scopes: `model("User").active().where("age", ">", 18).get()`
- Supports all standard SQL comparison operators
- Ultimately delegates to the model's standard finder methods (`findAll`, `findOne`, etc.)

## Building Queries

### Starting a Chain

Call any builder method directly on a model to start a chain:

```cfm
// These all start a QueryBuilder chain
model("User").where("status", "active")
model("User").whereNotNull("emailVerifiedAt")
model("User").orderBy("name")
model("User").limit(10)
```

### where() — Equality and Comparison

The `where()` method supports three calling conventions:

```cfm
// 2-argument form: property + value (assumes = operator)
model("User").where("status", "active")
// Generates: status = 'active'

// 3-argument form: property + operator + value
model("User").where("age", ">", 18)
// Generates: age > 18

// 1-argument form: raw WHERE string (passthrough)
model("User").where("status = 'active' AND role = 'admin'")
// Generates: status = 'active' AND role = 'admin'
```

**Supported operators (3-argument form):** `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`

### orWhere() — OR Conditions

```cfm
model("User")
    .where("role", "admin")
    .orWhere("role", "moderator")
    .get();
// Generates: role = 'admin' OR role = 'moderator'
```

`orWhere()` supports the same 1-, 2-, and 3-argument forms as `where()`.

### whereNull() / whereNotNull()

```cfm
// Find users who haven't verified their email
model("User").whereNull("emailVerifiedAt").get();
// Generates: emailVerifiedAt IS NULL

// Find users who have verified their email
model("User").whereNotNull("emailVerifiedAt").get();
// Generates: emailVerifiedAt IS NOT NULL
```

### whereBetween()

```cfm
model("Product").whereBetween("price", 10, 100).get();
// Generates: price BETWEEN 10 AND 100
```

### whereIn() / whereNotIn()

Accepts either an array or a comma-delimited list of values:

```cfm
// Array of values
model("User").whereIn("role", ["admin", "editor", "author"]).get();
// Generates: role IN ('admin','editor','author')

// Comma-delimited list
model("User").whereNotIn("status", "banned,suspended").get();
// Generates: status NOT IN ('banned','suspended')
```

### orderBy()

```cfm
model("User")
    .where("status", "active")
    .orderBy("lastName", "ASC")
    .orderBy("firstName", "ASC")
    .get();
// Generates: ORDER BY lastName ASC, firstName ASC
```

The second argument defaults to `"ASC"` if omitted:

```cfm
model("User").orderBy("createdAt").get();       // ASC
model("User").orderBy("createdAt", "DESC").get(); // DESC
```

### limit() and offset()

```cfm
model("User")
    .where("status", "active")
    .orderBy("createdAt", "DESC")
    .limit(25)
    .offset(50)
    .get();
```

### select()

Choose specific columns instead of `SELECT *`:

```cfm
model("User")
    .select("id,firstName,lastName,email")
    .where("status", "active")
    .get();
```

### include()

Eagerly load associations (generates JOINs):

```cfm
model("Post")
    .include("author,comments")
    .where("status", "published")
    .orderBy("publishedAt", "DESC")
    .get();
```

### group()

```cfm
model("Order")
    .select("status, COUNT(*) AS orderCount")
    .group("status")
    .get();
```

### distinct()

```cfm
model("User")
    .select("role")
    .distinct()
    .get();
```

## Combining Multiple Conditions

Chain multiple `where()` calls — they are joined with `AND`:

```cfm
model("User")
    .where("status", "active")
    .where("role", "admin")
    .where("age", ">=", 21)
    .whereNotNull("emailVerifiedAt")
    .orderBy("lastName")
    .limit(50)
    .get();
// WHERE status = 'active' AND role = 'admin' AND age >= 21 AND emailVerifiedAt IS NOT NULL
// ORDER BY lastName ASC
// LIMIT 50
```

Mix `AND` and `OR`:

```cfm
model("User")
    .where("status", "active")
    .where("role", "admin")
    .orWhere("role", "superadmin")
    .get();
// WHERE status = 'active' AND role = 'admin' OR role = 'superadmin'
```

> **Note:** Complex grouping with parentheses (e.g., `WHERE a AND (b OR c)`) is not currently supported by the builder. For those cases, use the 1-argument `where()` passthrough form or the traditional `findAll(where="...")`.

## Terminal Methods

Nothing hits the database until you call a terminal method:

| Method | Returns | Equivalent to |
|--------|---------|---------------|
| `.get()` | Query/Array | `findAll()` |
| `.findAll()` | Query/Array | `findAll()` |
| `.first()` | Object/false | `findOne()` |
| `.findOne()` | Object/false | `findOne()` |
| `.count()` | Numeric | `count()` |
| `.exists()` | Boolean | `exists()` |
| `.updateAll()` | Numeric | `updateAll()` |
| `.deleteAll()` | Numeric | `deleteAll()` |
| `.findEach()` | void | `findEach()` |
| `.findInBatches()` | void | `findInBatches()` |

Terminal methods accept the same optional arguments as their model equivalents:

```cfm
// Pass finder options to the terminal method
model("User")
    .where("status", "active")
    .get(page=2, perPage=25, returnAs="structs");

// Delete with soft-delete awareness
model("User")
    .where("status", "banned")
    .deleteAll(includeSoftDeletes=true);
```

## Composing with Scopes

The query builder and scopes work together seamlessly. You can start with a scope and continue with builder methods, or vice versa:

```cfm
// Scope first, then builder
model("User")
    .active()
    .where("age", ">", 21)
    .orderBy("name")
    .get();

// Multiple scopes, then builder
model("User")
    .active()
    .recent()
    .where("role", "admin")
    .limit(10)
    .get();

// Scope + builder + terminal with extra args
model("User")
    .active()
    .where("role", "admin")
    .findAll(page=1, perPage=25);
```

## SQL Injection Safety

The query builder automatically quotes values based on the column's data type as defined in the database schema. String values are quoted, numeric values are cast appropriately, and special characters are escaped.

```cfm
// Safe — the value "admin" is auto-quoted as a string
model("User").where("role", "admin").get();

// Safe — numeric value is validated against the column type
model("User").where("age", ">", 18).get();

// Safe — each value in the list is individually quoted
model("User").whereIn("status", ["active", "pending"]).get();
```

> **Note:** The 1-argument raw string form (`.where("raw SQL here")`) passes the string through unchanged. If you use that form, you are responsible for preventing injection.

## Complete Example

```cfm
// Controller action: search with filters
function index() {
    local.query = model("Product");

    // Apply filters conditionally
    if (StructKeyExists(params, "category")) {
        local.query = local.query.where("categoryId", params.category);
    }
    if (StructKeyExists(params, "minPrice")) {
        local.query = local.query.where("price", ">=", params.minPrice);
    }
    if (StructKeyExists(params, "maxPrice")) {
        local.query = local.query.where("price", "<=", params.maxPrice);
    }
    if (StructKeyExists(params, "inStock") && params.inStock) {
        local.query = local.query.where("quantity", ">", 0);
    }

    products = local.query
        .include("category")
        .orderBy("name")
        .get(page=params.page, perPage=20);
}
```

## Method Reference

### Builder Methods (Chainable)

| Method | Arguments | Description |
|--------|-----------|-------------|
| `where(property, value)` | 2 args | Equality condition (`=`) |
| `where(property, op, value)` | 3 args | Comparison with operator |
| `where(rawString)` | 1 arg | Raw WHERE passthrough |
| `orWhere(...)` | Same as `where` | OR condition |
| `whereNull(property)` | string | IS NULL check |
| `whereNotNull(property)` | string | IS NOT NULL check |
| `whereBetween(property, low, high)` | string, any, any | BETWEEN check |
| `whereIn(property, values)` | string, array/list | IN list |
| `whereNotIn(property, values)` | string, array/list | NOT IN list |
| `orderBy(property, direction)` | string, string | ORDER BY (default ASC) |
| `limit(value)` | numeric | Max rows to return |
| `offset(value)` | numeric | Rows to skip |
| `select(properties)` | string | Column list |
| `include(associations)` | string | JOIN associations |
| `group(properties)` | string | GROUP BY columns |
| `distinct()` | *none* | Add DISTINCT keyword |
