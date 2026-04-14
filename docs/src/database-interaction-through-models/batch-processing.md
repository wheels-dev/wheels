# Batch Processing

When working with large datasets, loading all records into memory at once can cause performance problems or even crash your application. Wheels provides two batch processing methods that iterate through records in manageable chunks: `findEach()` and `findInBatches()`.

## findEach()

Processes records **one at a time** via a callback function. Internally, records are fetched in batches (default 1000) but your callback receives individual model objects.

```cfm
model("User").findEach(
    order = "id",
    callback = function(user) {
        user.sendReminderEmail();
    }
);
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `callback` | function | *required* | Closure receiving each record as a model object (or struct) |
| `batchSize` | numeric | 1000 | Number of records fetched per internal query |
| `where` | string | `""` | SQL WHERE clause to filter records |
| `order` | string | primary key ASC | Sort order (defaults to primary key for consistent pagination) |
| `include` | string | `""` | Associated models to include |
| `select` | string | `""` | Columns to select |
| `returnAs` | string | `"object"` | Set to `"struct"` to receive structs instead of objects |
| `includeSoftDeletes` | boolean | `false` | Include soft-deleted records |

### Examples

**Filter with a WHERE clause:**

```cfm
model("Order").findEach(
    where = "status = 'pending'",
    batchSize = 500,
    callback = function(order) {
        order.update(status = "processing");
    }
);
```

**With associated models:**

```cfm
model("User").findEach(
    include = "profile",
    callback = function(user) {
        writeOutput(user.profile.bio);
    }
);
```

## findInBatches()

Processes records **in groups**. Your callback receives the entire batch as a query result set (or array of objects/structs).

```cfm
model("User").findInBatches(
    order = "id",
    batchSize = 500,
    callback = function(users) {
        // `users` is a query with up to 500 rows
        processBatch(users);
    }
);
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `callback` | function | *required* | Closure receiving each batch |
| `batchSize` | numeric | 500 | Number of records per batch |
| `where` | string | `""` | SQL WHERE clause to filter records |
| `order` | string | primary key ASC | Sort order |
| `include` | string | `""` | Associated models to include |
| `select` | string | `""` | Columns to select |
| `returnAs` | string | `"query"` | Set to `"objects"` or `"structs"` for arrays |
| `includeSoftDeletes` | boolean | `false` | Include soft-deleted records |

### Examples

**Export data in chunks:**

```cfm
model("Transaction").findInBatches(
    where = "year(createdAt) = 2025",
    order = "createdAt",
    batchSize = 1000,
    callback = function(batch) {
        writeToCSV(batch);
    }
);
```

**Receive objects instead of a query:**

```cfm
model("Product").findInBatches(
    batchSize = 100,
    returnAs = "objects",
    callback = function(products) {
        for (var product in products) {
            product.recalculatePrice();
            product.save();
        }
    }
);
```

## Using with Scopes

Both methods work with query scopes when called through a scope chain:

```cfm
model("User").active().findEach(
    batchSize = 500,
    callback = function(user) {
        user.sendNewsletter();
    }
);
```

## Choosing Between findEach and findInBatches

| Use Case | Method |
|----------|--------|
| Need to process or update individual records | `findEach()` |
| Bulk operations on groups of records (CSV export, API calls) | `findInBatches()` |
| Need model callbacks (save, update) on each record | `findEach()` |
| Need to pass batches to external services | `findInBatches()` |
