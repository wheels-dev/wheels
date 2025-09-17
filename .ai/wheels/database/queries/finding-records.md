# Finding Records

## Description
Wheels provides several finder methods to retrieve records from the database as objects or query results with various criteria and options.

## Key Points
- `findByKey()` - finds single record by primary key
- `findOne()` - finds single record by criteria, returns object
- `findAll()` - finds multiple records, returns query result
- `findFirst()` - finds first record ordered by specified property
- `reload()` - refreshes object with current database values
- Supports complex WHERE conditions, ordering, pagination
- Automatic column mapping and table prefixing

## Code Sample
```cfm
// Find by primary key - returns object or false
author = model("author").findByKey(5);
if (IsObject(author)) {
    // Use author object
}

// Find one record by criteria - returns object or false
latestOrder = model("order").findOne(order="datePurchased DESC");

// Find multiple records - returns query result
activeUsers = model("user").findAll(where="active = 1", order="lastName ASC");

// Complex queries with associations
articlesWithAuthors = model("article").findAll(
    where="publishedAt IS NOT NULL",
    include="author",
    order="publishedAt DESC",
    page=1,
    perPage=10
);

// Find first record ordered by property
firstUser = model("user").findFirst(); // Orders by primary key ASC by default
oldestUser = model("user").findFirst(property="createdAt", $sort="ASC");
newestUser = model("user").findFirst(property="createdAt", $sort="DESC");

// Reload object to get fresh database values
user = model("user").findByKey(5);
// ... user object may be modified elsewhere ...
user.reload(); // Refreshes all properties from database
```

## Usage
1. Use `findByKey(id)` for single records by primary key
2. Use `findOne()` for single records with criteria
3. Use `findAll()` for multiple records or lists
4. Use `findFirst(property, $sort)` for first record ordered by property
5. Use `reload()` to refresh object with current database values
6. Add WHERE conditions with operators: `=, !=, <>, <, <=, >, >=, LIKE, IN`
7. Order results with `order="column ASC/DESC"`
8. Paginate with `page` and `perPage` arguments

## Related
- [Creating Records](./creating-records.md)
- [Updating Records](./updating-records.md)
- [Associations](../associations/has-many.md)
- [Pagination](../getting-paginated-data.md)

## Important Notes
- Strings must be in single quotes in WHERE clauses
- SQL keywords must be uppercase (ASC, DESC, AND, OR)
- Automatic conversion to cfqueryparam for security
- Include associations to avoid N+1 query problems
- `findFirst()` defaults to primary key ordering if no property specified
- `reload()` discards any unsaved changes to the object
- Use `reload()` after external database modifications