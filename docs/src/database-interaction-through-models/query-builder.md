# Query Builder

The query builder provides a fluent, chainable API for constructing database queries. It is an alternative to passing raw SQL strings to `findAll(where="...")`, with the added benefit of automatic value quoting for SQL injection safety.

## Basic Usage

Start a query chain by calling `.where()` on any model, then finish with a terminal method like `.get()`:

```cfm
users = model("User")
    .where("status", "active")
    .where("age", ">", 18)
    .orderBy("name", "ASC")
    .limit(25)
    .get();
```

## WHERE Conditions

### Equality

```cfm
// Two arguments: property, value
model("User").where("status", "active").get();
// Generates: status = 'active'
```

### Operators

```cfm
// Three arguments: property, operator, value
model("User").where("age", ">", 18).get();
model("User").where("views", ">=", 100).get();
model("User").where("name", "LIKE", "%smith%").get();
```

### Raw Strings

```cfm
// One argument: raw WHERE clause (no auto-quoting)
model("User").where("status = 'active' AND role = 'admin'").get();
```

### OR Conditions

```cfm
model("User")
    .where("role", "admin")
    .orWhere("role", "superadmin")
    .get();
// Generates: role = 'admin' OR role = 'superadmin'
```

### NULL Checks

```cfm
model("User").whereNull("deletedAt").get();
model("User").whereNotNull("emailVerifiedAt").get();
```

### BETWEEN

```cfm
model("Product").whereBetween("price", 10, 50).get();
// Generates: price BETWEEN 10 AND 50
```

### IN / NOT IN

```cfm
// With a comma-delimited list
model("User").whereIn("role", "admin,editor,author").get();

// With an array
model("User").whereIn("role", ["admin", "editor"]).get();

// NOT IN
model("User").whereNotIn("status", "banned,suspended").get();
```

## Ordering

```cfm
model("User").orderBy("name", "ASC").get();
model("User").orderBy("createdAt", "DESC").get();

// Multiple order clauses
model("User")
    .orderBy("lastName", "ASC")
    .orderBy("firstName", "ASC")
    .get();
```

## Limiting Results

```cfm
model("User").limit(10).get();
model("User").offset(20).limit(10).get();
```

## Other Builder Methods

```cfm
// Select specific columns
model("User").select("id,name,email").get();

// Include associations
model("User").include("profile,orders").get();

// Group by
model("Order").select("status,COUNT(id) as orderCount").group("status").get();

// Distinct
model("User").select("city").distinct().get();
```

## Terminal Methods

Call one of these to execute the built query:

| Method | Returns | Description |
|--------|---------|-------------|
| `get()` | query | Alias for `findAll()` |
| `findAll()` | query | All matching records |
| `first()` | object | Alias for `findOne()` |
| `findOne()` | object | First matching record |
| `count()` | numeric | Number of matching records |
| `exists()` | boolean | Whether any records match |
| `updateAll(...)` | numeric | Update matching records |
| `deleteAll()` | numeric | Delete matching records |
| `findEach(callback)` | void | Batch iterate one at a time |
| `findInBatches(callback)` | void | Batch iterate in groups |

## Combining with Scopes

You can transition from scopes to the query builder at any point in the chain:

```cfm
model("User")
    .active()                    // scope
    .where("role", "admin")      // query builder
    .orderBy("name", "ASC")
    .get();
```

See [Query Scopes](query-scopes.md) for defining reusable scope fragments.

## SQL Injection Safety

All values passed to `where()`, `whereBetween()`, `whereIn()`, and `whereNotIn()` are automatically quoted using the model's database adapter. You do not need to manually escape values:

```cfm
// Safe — value is auto-quoted
model("User").where("name", userInput).get();

// Also safe
model("User").whereIn("id", userSuppliedIds).get();
```

Raw string WHERE clauses (single-argument `where()`) are passed through as-is. Avoid interpolating user input into raw strings.
