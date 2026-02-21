# Batch Processing

## Description

Batch processing methods let you work with large result sets memory-efficiently. Instead of loading thousands of records into memory at once, `findEach()` and `findInBatches()` paginate through the data internally and hand you records in manageable chunks. This is essential for background jobs, data migrations, bulk emails, and any operation that touches many records.

## Key Points

- `findEach()` — processes one record at a time (callback receives a single object or struct)
- `findInBatches()` — processes groups of records (callback receives a query/array batch)
- Both use pagination internally, fetching `batchSize` records per database query
- Support all standard finder arguments: `where`, `order`, `include`, `select`, `parameterize`, `includeSoftDeletes`
- Compose with query scopes and the chainable query builder
- Default ordering is primary key ascending (for consistent pagination)

## findEach()

Iterates through records one at a time. Internally loads records in batches (default 1,000) but invokes the callback for each individual record.

### Basic Usage

```cfm
// Send a reminder email to every active user
model("User").findEach(
    where="status = 'active'",
    batchSize=500,
    callback=function(user) {
        sendEmail(
            to=user.email,
            subject="Monthly Reminder",
            from="app@example.com"
        );
    }
);
```

### With Scopes

```cfm
// Using a scope to filter
model("User").active().findEach(
    batchSize=1000,
    callback=function(user) {
        user.lastNotifiedAt = Now();
        user.save();
    }
);
```

### With the Query Builder

```cfm
model("Order")
    .where("status", "pending")
    .where("createdAt", "<", DateAdd("d", -30, Now()))
    .findEach(batchSize=200, callback=function(order) {
        order.status = "expired";
        order.save();
    });
```

### Returning Structs Instead of Objects

By default `findEach()` yields model objects. Set `returnAs="struct"` if you only need data and want to avoid object creation overhead:

```cfm
model("User").findEach(
    returnAs="struct",
    batchSize=1000,
    callback=function(user) {
        writeOutput("Processing: #user.email#<br>");
    }
);
```

### findEach() Reference

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `batchSize` | numeric | `1000` | Records to load per internal query. |
| `callback` | function | *required* | Closure called for each record. Receives one argument: the record (object or struct). |
| `where` | string | `""` | WHERE clause to filter records. |
| `order` | string | PK ASC | ORDER BY clause. Defaults to primary key for consistent pagination. |
| `include` | string | `""` | Associations to JOIN. |
| `select` | string | `""` | Column list (default: all). |
| `parameterize` | any | — | Whether to use `cfqueryparam`. |
| `includeSoftDeletes` | boolean | `false` | Include soft-deleted records. |
| `returnAs` | string | `"object"` | `"object"` or `"struct"`. |

## findInBatches()

Processes records in groups. The callback receives the entire batch (query result set, array of objects, or array of structs) rather than individual records. Useful when the operation benefits from bulk processing (e.g., batch API calls, bulk inserts into another system).

### Basic Usage

```cfm
// Export users in CSV batches
model("User").findInBatches(
    batchSize=500,
    callback=function(users) {
        // 'users' is a query result set (default returnAs="query")
        writeBatchToCSV(users);
    }
);
```

### With Objects

```cfm
model("Order").findInBatches(
    where="status = 'pending'",
    batchSize=100,
    returnAs="objects",
    callback=function(orders) {
        // 'orders' is an array of model objects
        for (var order in orders) {
            order.process();
        }
    }
);
```

### With Scopes

```cfm
model("Product").active().findInBatches(
    batchSize=200,
    returnAs="structs",
    callback=function(products) {
        // 'products' is an array of structs
        syncToExternalCatalog(products);
    }
);
```

### With the Query Builder

```cfm
model("LogEntry")
    .where("createdAt", "<", DateAdd("m", -6, Now()))
    .findInBatches(batchSize=1000, callback=function(logs) {
        archiveLogBatch(logs);
    });
```

### findInBatches() Reference

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `batchSize` | numeric | `500` | Records per batch. |
| `callback` | function | *required* | Closure called for each batch. Receives one argument: the batch. |
| `where` | string | `""` | WHERE clause to filter records. |
| `order` | string | PK ASC | ORDER BY clause. |
| `include` | string | `""` | Associations to JOIN. |
| `select` | string | `""` | Column list (default: all). |
| `parameterize` | any | — | Whether to use `cfqueryparam`. |
| `includeSoftDeletes` | boolean | `false` | Include soft-deleted records. |
| `returnAs` | string | `"query"` | `"query"`, `"objects"`, or `"structs"`. |

## Choosing Between findEach() and findInBatches()

| Use case | Method | Why |
|----------|--------|-----|
| Send individual emails | `findEach()` | One email per record |
| Update records one by one | `findEach()` | Each record saved individually |
| Export data to CSV in chunks | `findInBatches()` | Write many rows at once |
| Sync batch to external API | `findInBatches()` | API accepts arrays |
| Aggregate/report generation | `findInBatches()` | Process sets of data |
| Simple per-record logic | `findEach()` | Cleaner callback |

## Choosing batchSize

| Scenario | Recommended batchSize |
|----------|-----------------------|
| Simple reads (few columns) | 1000–5000 |
| Object creation (many columns) | 200–1000 |
| Heavy processing per record | 50–200 |
| External API calls per record | 10–50 |
| Memory-constrained environment | 100–500 |

The default values (1000 for `findEach`, 500 for `findInBatches`) are good starting points for most applications.

## Common Patterns

### Data Migration

```cfm
// Backfill a new column
model("User").findEach(
    batchSize=500,
    callback=function(user) {
        if (!Len(user.displayName)) {
            user.displayName = user.firstName & " " & user.lastName;
            user.save(callbacks=false);
        }
    }
);
```

### Bulk Email

```cfm
// Send newsletter to subscribers
model("Subscriber").active().findEach(
    batchSize=200,
    callback=function(subscriber) {
        sendEmail(
            to=subscriber.email,
            subject="Weekly Newsletter",
            from="newsletter@example.com",
            template="emails/newsletter"
        );
    }
);
```

### Cleanup Old Records

```cfm
// Archive old log entries in batches
model("AuditLog")
    .where("createdAt", "<", DateAdd("yyyy", -1, Now()))
    .findInBatches(batchSize=1000, callback=function(logs) {
        // Move to archive table, then delete
        for (var i = 1; i <= logs.recordCount; i++) {
            archiveLog(logs.id[i], logs.action[i], logs.createdAt[i]);
        }
    });

// Then delete the originals
model("AuditLog").deleteAll(where="createdAt < '#DateAdd('yyyy', -1, Now())#'");
```

### Progress Reporting

```cfm
local.processed = 0;
local.total = model("User").active().count();

model("User").active().findEach(
    batchSize=500,
    callback=function(user) {
        // ... process user ...
        local.processed++;
        if (local.processed MOD 100 == 0) {
            writeLog(text="Processed #local.processed# / #local.total# users", type="information");
        }
    }
);
```
