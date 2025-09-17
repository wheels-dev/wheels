# Query Basics

## Overview
CFML provides simple yet powerful database querying capabilities through cfquery tags and queryExecute() functions. Queries can be executed against named datasources, with support for parameterized queries to prevent SQL injection.

## Syntax
```cfscript
// Function syntax
result = queryExecute(sql, params, options);

// Tag syntax
<cfquery name="result" datasource="myDB">
    SQL statement here
</cfquery>
```

## Examples

### Basic Query Execution
```cfscript
// Simple query with queryExecute()
qItems = queryExecute(
    "SELECT quantity, item FROM cupboard ORDER BY item"
);

// Query with named datasource
qUsers = queryExecute(
    "SELECT id, name, email FROM users",
    {},
    { datasource: "myDatabase" }
);
```

### Tag Syntax
```markup
<cfquery name="qItems" datasource="pantry">
    SELECT quantity, item
    FROM cupboard
    ORDER BY item
</cfquery>
```

### Parameterized Queries (SQL Injection Prevention)
```cfscript
// Named parameters
userID = 123;
qUser = queryExecute(
    "SELECT * FROM users WHERE id = :userID",
    {
        userID: { value: userID, cfsqltype: "integer" }
    }
);

// Positional parameters
qProducts = queryExecute(
    "SELECT * FROM products WHERE category = ? AND price > ?",
    [
        { value: "electronics", cfsqltype: "varchar" },
        { value: 100, cfsqltype: "numeric" }
    ]
);
```

### Datasource Configuration in Application.cfc
```cfscript
// Application.cfc
component {
    this.name = "MyApp";

    // Default datasource
    this.datasource = "myDB";

    // Multiple datasources
    this.datasources = {
        "myDB": {
            driver: "MySQL",
            host: "localhost",
            port: "3306",
            database: "myapp",
            username: getSystemSetting("DB_USER"),
            password: getSystemSetting("DB_PASSWORD")
        },
        "reporting": {
            class: "com.mysql.jdbc.Driver",
            connectionString: "jdbc:mysql://localhost:3306/reports",
            username: "reporter",
            password: "secret"
        }
    };
}
```

### Inline Datasource Definition (Lucee)
```cfscript
qData = queryExecute(
    "SELECT * FROM employees WHERE department = ?",
    [{ value: "IT", cfsqltype: "varchar" }],
    {
        datasource: {
            class: "com.microsoft.sqlserver.jdbc.SQLServerDriver",
            connectionString: "jdbc:sqlserver://server:1433;databaseName=HR",
            username: getSystemSetting("DB_USER"),
            password: getSystemSetting("DB_PASSWORD")
        }
    }
);
```

### Query Result Processing
```cfscript
// Traditional loop
for (var row in qItems) {
    writeOutput("Item: #row.item#, Quantity: #row.quantity#<br>");
}

// Each() method
qItems.each(function(row, index) {
    writeOutput("Row #index#: #row.item# - #row.quantity#<br>");
});

// Index-based access
for (var i = 1; i <= qItems.recordCount; i++) {
    writeOutput("#qItems.item[i]#: #qItems.quantity[i]#<br>");
}
```

### Query Metadata Access
```cfscript
qResult = queryExecute("SELECT * FROM users LIMIT 5");

// Query properties
recordCount = qResult.recordCount;      // Number of rows
columnList = qResult.columnList;        // Comma-delimited column names
columns = qResult.getColumnNames();     // Array of column names

// Check if query has data
if (qResult.recordCount > 0) {
    // Process results
}
```

### Dynamic Query Building
```cfscript
function searchUsers(filters = {}) {
    var sql = "SELECT * FROM users WHERE 1=1";
    var params = {};

    if (structKeyExists(filters, "name")) {
        sql &= " AND name LIKE :name";
        params.name = { value: "%#filters.name#%", cfsqltype: "varchar" };
    }

    if (structKeyExists(filters, "active")) {
        sql &= " AND active = :active";
        params.active = { value: filters.active, cfsqltype: "bit" };
    }

    return queryExecute(sql, params);
}
```

### Query Options
```cfscript
qResults = queryExecute(
    "SELECT * FROM large_table",
    {},
    {
        datasource: "myDB",
        timeout: 30,                    // Query timeout in seconds
        maxrows: 1000,                  // Limit result set
        blockfactor: 100,               // Rows to fetch at once
        returntype: "array",            // Return as array of structs
        ormoptions: { cacheable: true } // ORM-specific options
    }
);
```

## Key Points
- Always use parameterized queries to prevent SQL injection
- Default datasource can be set in Application.cfc for convenience
- Query objects are iterable and provide metadata access
- Lucee supports inline datasource definitions
- CFML queries return special query objects with built-in methods
- Parameters support type validation through cfsqltype

## SQL Parameter Types (cfsqltype)
- `varchar`, `char` - String data
- `integer`, `numeric`, `decimal` - Numeric data
- `bit`, `boolean` - Boolean values
- `date`, `time`, `timestamp` - Date/time values
- `blob`, `clob` - Binary/large text data

## Security Best Practices
- Always parameterize user input
- Use cfsqltype for proper type validation
- Store database credentials as environment variables
- Implement connection limits and timeouts
- Use read-only database users for reporting queries

## Performance Considerations
- Use appropriate indexes on queried columns
- Limit result sets with WHERE clauses and LIMIT
- Consider using blockfactor for large result sets
- Cache frequently-used query results
- Monitor query execution times

## Related Concepts
- [Query Methods](query-methods.md)
- [Query of Queries](query-of-queries.md)
- [Exception Handling](../control-flow/exception-handling.md)
- [Application Configuration](../advanced/application-cfc.md)