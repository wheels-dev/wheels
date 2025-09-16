# Performance Best Practices

## Overview
CFML performance optimization involves proper variable scoping, efficient database queries, appropriate caching strategies, and understanding engine-specific behaviors. Modern CFML engines provide many optimization opportunities.

## Key Performance Areas
- Variable scoping and memory management
- Database query optimization
- Caching strategies
- String and array operations
- Component instantiation patterns

## Examples

### Variable Scoping Performance
```cfscript
// SLOW: Unscoped variables require scope chain lookup
function processData(data) {
    result = [];  // Searches through scope chain
    for (item in arguments.data) {
        processedItem = processItem(item);  // Scope chain lookup
        result.append(processedItem);
    }
    return result;
}

// FAST: Explicitly scoped variables
function processData(data) {
    var result = [];  // Local scope - direct access
    for (var item in arguments.data) {
        var processedItem = processItem(item);  // Local scope
        result.append(processedItem);
    }
    return result;
}
```

### Database Query Optimization
```cfscript
// SLOW: Multiple queries in loop
function getUsersWithProfiles(userIDs) {
    var users = [];
    for (var id in arguments.userIDs) {
        var user = queryExecute("SELECT * FROM users WHERE id = ?", [id]);
        var profile = queryExecute("SELECT * FROM profiles WHERE user_id = ?", [id]);
        users.append({user: user, profile: profile});
    }
    return users;
}

// FAST: Single query with JOIN
function getUsersWithProfiles(userIDs) {
    var sql = "
        SELECT u.*, p.*
        FROM users u
        LEFT JOIN profiles p ON u.id = p.user_id
        WHERE u.id IN (" & arrayToList(arguments.userIDs) & ")
    ";
    return queryExecute(sql);
}

// BETTER: Parameterized with IN clause
function getUsersWithProfiles(userIDs) {
    var placeholders = arrayMap(arguments.userIDs, function() { return "?"; });
    var sql = "
        SELECT u.*, p.*
        FROM users u
        LEFT JOIN profiles p ON u.id = p.user_id
        WHERE u.id IN (" & arrayToList(placeholders) & ")
    ";
    return queryExecute(sql, arguments.userIDs);
}
```

### Caching Strategies
```cfscript
// Application-level caching
component singleton {

    function getExpensiveData(key) {
        var cacheKey = "expensive_data_" & arguments.key;

        // Check application cache first
        if (structKeyExists(application.cache, cacheKey)) {
            return application.cache[cacheKey];
        }

        // Generate expensive data
        var data = performExpensiveCalculation(arguments.key);

        // Cache for 1 hour
        if (!structKeyExists(application, "cache")) {
            application.cache = {};
        }
        application.cache[cacheKey] = data;

        return data;
    }
}

// Query caching
function getCachedUsers() {
    return queryExecute(
        "SELECT * FROM users WHERE active = 1",
        {},
        {
            cachedwithin: createTimeSpan(0, 1, 0, 0)  // 1 hour
        }
    );
}
```

### String Operations Performance
```cfscript
// SLOW: String concatenation in loop
function buildLargeString(items) {
    var result = "";
    for (var item in arguments.items) {
        result = result & item & chr(13);  // Creates new string each time
    }
    return result;
}

// FAST: Use StringBuilder for large string operations
function buildLargeString(items) {
    var buffer = createObject("java", "java.lang.StringBuilder").init();
    for (var item in arguments.items) {
        buffer.append(item).append(chr(13));
    }
    return buffer.toString();
}

// FASTEST: Use array join for simple concatenation
function buildLargeString(items) {
    return arrayToList(arguments.items, chr(13));
}
```

### Array Operations Performance
```cfscript
// SLOW: Growing array in loop without pre-sizing
function processLargeDataset(data) {
    var results = [];
    for (var item in arguments.data) {
        results.append(processItem(item));  // Array grows dynamically
    }
    return results;
}

// FAST: Pre-size array when length is known
function processLargeDataset(data) {
    var results = arrayNew(1);
    arrayResize(results, arrayLen(arguments.data));  // Pre-allocate space

    var index = 1;
    for (var item in arguments.data) {
        results[index] = processItem(item);
        index++;
    }
    return results;
}
```

### Component Instantiation Performance
```cfscript
// SLOW: Creating new instances repeatedly
function processMultipleItems(items) {
    var results = [];
    for (var item in arguments.items) {
        var processor = new ItemProcessor();  // New instance each time
        results.append(processor.process(item));
    }
    return results;
}

// FAST: Reuse component instances
component {

    property name="itemProcessor";

    function init() {
        variables.itemProcessor = new ItemProcessor();  // Single instance
        return this;
    }

    function processMultipleItems(items) {
        var results = [];
        for (var item in arguments.items) {
            results.append(variables.itemProcessor.process(item));
        }
        return results;
    }
}
```

### Memory Management
```cfscript
// GOOD: Explicit cleanup of large objects
function processLargeFile(filePath) {
    var fileData = fileRead(arguments.filePath);  // Large memory usage

    try {
        var results = processFileData(fileData);
        return results;
    } finally {
        fileData = "";  // Help GC by nullifying large variables
    }
}

// GOOD: Limit result set sizes
function getUsers(filters = {}) {
    // Always include reasonable limits
    if (!structKeyExists(filters, "maxResults")) {
        filters.maxResults = 1000;
    }

    var sql = "SELECT * FROM users WHERE active = 1";
    var params = [];

    if (structKeyExists(filters, "department")) {
        sql &= " AND department = ?";
        params.append(filters.department);
    }

    sql &= " LIMIT " & filters.maxResults;

    return queryExecute(sql, params);
}
```

### Efficient Data Structures
```cfscript
// Use appropriate data structures
component {

    function init() {
        // Use ordered struct for maintaining insertion order
        variables.orderedData = structNew("ordered");

        // Use case-sensitive struct when case matters
        variables.caseSensitiveData = structNew("casesensitive");

        // Use synchronized arrays for thread-safe operations
        variables.threadSafeArray = arrayNew(1, "string", true);

        return this;
    }
}
```

### Lazy Loading Pattern
```cfscript
component {

    property name="expensiveResource";

    function getExpensiveResource() {
        if (!structKeyExists(variables, "expensiveResource")) {
            variables.expensiveResource = loadExpensiveResource();
        }
        return variables.expensiveResource;
    }

    private function loadExpensiveResource() {
        // Expensive initialization only when needed
        return performExpensiveOperation();
    }
}
```

### Bulk Operations
```cfscript
// SLOW: Individual database operations
function updateMultipleUsers(userUpdates) {
    for (var update in arguments.userUpdates) {
        queryExecute(
            "UPDATE users SET name = ? WHERE id = ?",
            [update.name, update.id]
        );
    }
}

// FAST: Batch operations
function updateMultipleUsers(userUpdates) {
    var sql = "UPDATE users SET name = CASE ";
    var params = [];

    for (var update in arguments.userUpdates) {
        sql &= "WHEN id = ? THEN ? ";
        params.append(update.id);
        params.append(update.name);
    }

    sql &= "END WHERE id IN (" & arrayToList(arrayMap(arguments.userUpdates, function(u) { return u.id; })) & ")";

    queryExecute(sql, params);
}
```

## Engine-Specific Performance Tips

### Adobe ColdFusion
- Use `cachedwithin` for query caching
- Enable trusted cache in production
- Use `cfupdate` and `cfinsert` for simple database operations
- Configure JVM heap size appropriately

### Lucee
- Arrays passed by reference (performance benefit)
- Use `cachedWithin` or query caching
- Configure connection pooling in datasources
- Use Lucee-specific functions where available

## Monitoring and Profiling

### Application Monitoring
```cfscript
component {

    function monitoredFunction(data) {
        var startTime = getTickCount();

        try {
            var result = expensiveOperation(data);
            return result;
        } finally {
            var executionTime = getTickCount() - startTime;

            if (executionTime > 5000) {  // Log slow operations
                writeLog(
                    text = "Slow operation detected: #executionTime#ms",
                    type = "warning",
                    file = "performance"
                );
            }
        }
    }
}
```

### Memory Usage Tracking
```cfscript
function memoryIntensiveOperation() {
    var initialMemory = getMemoryUsage();

    // Perform memory-intensive work
    var result = processLargeDataSet();

    var finalMemory = getMemoryUsage();
    var memoryUsed = finalMemory.used - initialMemory.used;

    if (memoryUsed > 100 * 1024 * 1024) {  // 100MB
        writeLog("High memory usage: " & memoryUsed & " bytes");
    }

    return result;
}
```

## Performance Testing
```cfscript
// Simple performance timing
function benchmarkFunction(func, iterations = 1000) {
    var startTime = getTickCount();

    for (var i = 1; i <= iterations; i++) {
        func();
    }

    var totalTime = getTickCount() - startTime;
    var avgTime = totalTime / iterations;

    return {
        totalTime: totalTime,
        averageTime: avgTime,
        iterations: iterations
    };
}
```

## Key Takeaways
- **Always scope variables** explicitly for performance
- **Use appropriate caching** strategies (query, application, session)
- **Minimize database round trips** with JOINs and batch operations
- **Pre-size collections** when possible
- **Reuse component instances** instead of creating new ones
- **Use StringBuilder** for large string operations
- **Monitor and profile** application performance
- **Choose appropriate data structures** for the use case

## Related Concepts
- [Variable Scopes](../data-types/variable-scopes.md)
- [Query Basics](../database/query-basics.md)
- [Components](../components/component-basics.md)
- [Arrays](../data-types/arrays/array-methods.md)