# Finding Records

## Description
Wheels provides three main finder methods to retrieve records from the database as objects or query results.

## Key Points
- `findByKey()` - finds single record by primary key
- `findOne()` - finds single record by criteria, returns object
- `findAll()` - finds multiple records, returns query result
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
```

## Usage
1. Use `findByKey(id)` for single records by primary key
2. Use `findOne()` for single records with criteria
3. Use `findAll()` for multiple records or lists
4. Add WHERE conditions with operators: `=, !=, <>, <, <=, >, >=, LIKE, IN`
5. Order results with `order="column ASC/DESC"`
6. Paginate with `page` and `perPage` arguments

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