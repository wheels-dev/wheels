# wheels runner

Execute a script file in the Wheels application context.

## Synopsis

```bash
wheels runner <file> [options]
```

## Description

The `wheels runner` command executes CFML script files with full access to your Wheels application context. This is useful for running data migrations, maintenance tasks, batch processing, and other scripts that need access to your models and application functionality.

Scripts are executed on the server via HTTP, ensuring they run with the proper application context, database connections, and Wheels framework features.

## Arguments

### `file`
- **Type:** String
- **Required:** Yes
- **Description:** Path to the script file to execute (.cfm, .cfc, or .cfs)
- **Example:** `wheels runner scripts/migrate-data.cfm`

## Options

### `environment`
- **Type:** String
- **Default:** `development`
- **Description:** Environment to run in (development, testing, production)
- **Example:** `wheels runner script.cfm environment=production`

### `--verbose`
- **Type:** Boolean flag
- **Default:** `false`
- **Description:** Show detailed output including execution time
- **Example:** `wheels runner script.cfm --verbose`

### `params`
- **Type:** String (JSON format)
- **Description:** Additional parameters to pass to the script
- **Example:** `wheels runner import.cfm params='{"source":"data.csv","limit":100}'`

## Examples

### Basic Usage
```bash
# Run a migration script
wheels runner scripts/migrate-users.cfm

# Run in production environment
wheels runner scripts/cleanup.cfm environment=production

# Run with parameters
wheels runner scripts/import.cfm params='{"file":"products.csv","dryRun":true}'

# Run with verbose output
wheels runner scripts/process-orders.cfm --verbose
```

### Script Examples

#### Data Migration Script
```cfm
<!--- scripts/migrate-legacy-users.cfm --->
<cfscript>
// Access passed parameters
var dryRun = structKeyExists(request.scriptParams, "dryRun") ? request.scriptParams.dryRun : false;
var batchSize = structKeyExists(request.scriptParams, "batchSize") ? request.scriptParams.batchSize : 100;

writeOutput("<h3>Legacy User Migration</h3>");
writeOutput("Dry run: #dryRun#<br>");
writeOutput("Batch size: #batchSize#<br><br>");

// Query legacy database
var legacyUsers = request.query("
    SELECT * FROM legacy_users 
    WHERE migrated = 0 
    LIMIT #batchSize#
");

writeOutput("Found #legacyUsers.recordCount# users to migrate<br><br>");

var migrated = 0;
for (var legacyUser in legacyUsers) {
    try {
        if (!dryRun) {
            // Create user in new system
            var newUser = request.model("User").create(
                email: legacyUser.email_address,
                firstName: legacyUser.fname,
                lastName: legacyUser.lname,
                createdAt: legacyUser.created_date
            );
            
            // Mark as migrated
            request.query("
                UPDATE legacy_users 
                SET migrated = 1, new_id = #newUser.id# 
                WHERE id = #legacyUser.id#
            ");
        }
        
        migrated++;
        writeOutput("✓ Migrated: #legacyUser.email_address#<br>");
        
    } catch (any e) {
        writeOutput("✗ Failed: #legacyUser.email_address# - #e.message#<br>");
    }
}

writeOutput("<br><strong>Migration complete: #migrated# users processed</strong>");
</cfscript>
```

#### Maintenance Script
```cfm
<!--- scripts/cleanup-temp-files.cfm --->
<cfscript>
var daysOld = structKeyExists(request.scriptParams, "days") ? request.scriptParams.days : 7;
var verbose = request.scriptVerbose;

writeOutput("Cleaning temporary files older than #daysOld# days...<br><br>");

// Clean up old session files
var cutoffDate = dateAdd('d', -daysOld, now());
var deletedCount = 0;

// Find and delete old upload records
var oldUploads = request.model("TempUpload").findAll(
    where="createdAt < '#cutoffDate#'"
);

for (var upload in oldUploads) {
    // Delete physical file
    if (fileExists(upload.filePath)) {
        fileDelete(upload.filePath);
        if (verbose) {
            writeOutput("Deleted file: #upload.filePath#<br>");
        }
    }
    
    // Delete database record
    request.model("TempUpload").deleteByKey(upload.id);
    deletedCount++;
}

writeOutput("<br>Deleted #deletedCount# temporary files<br>");

// Clean up orphaned cart items
var orphanedItems = request.query("
    SELECT COUNT(*) as total 
    FROM cart_items 
    WHERE updatedAt < '#cutoffDate#' 
    AND orderId IS NULL
").total;

if (orphanedItems > 0) {
    request.query("
        DELETE FROM cart_items 
        WHERE updatedAt < '#cutoffDate#' 
        AND orderId IS NULL
    ");
    writeOutput("Removed #orphanedItems# orphaned cart items<br>");
}

writeOutput("<br><strong>Cleanup complete!</strong>");
</cfscript>
```

#### Report Generation Script
```cfm
<!--- scripts/generate-monthly-report.cfm --->
<cfscript>
// Get report parameters
var month = structKeyExists(request.scriptParams, "month") ? request.scriptParams.month : month(now());
var year = structKeyExists(request.scriptParams, "year") ? request.scriptParams.year : year(now());
var emailTo = structKeyExists(request.scriptParams, "emailTo") ? request.scriptParams.emailTo : "";

writeOutput("<h2>Monthly Report - #monthAsString(month)# #year#</h2>");

// Calculate date range
var startDate = createDate(year, month, 1);
var endDate = dateAdd('m', 1, startDate);

// Get statistics
var stats = {};

// New users
stats.newUsers = request.model("User").count(
    where="createdAt >= '#startDate#' AND createdAt < '#endDate#'"
);

// Orders
var orderData = request.query("
    SELECT 
        COUNT(*) as totalOrders,
        SUM(total) as revenue,
        AVG(total) as avgOrderValue
    FROM orders
    WHERE createdAt >= '#startDate#' 
    AND createdAt < '#endDate#'
    AND status = 'completed'
");

stats.orders = orderData.totalOrders;
stats.revenue = orderData.revenue ?: 0;
stats.avgOrderValue = orderData.avgOrderValue ?: 0;

// Display report
writeOutput("<h3>Summary</h3>");
writeOutput("<ul>");
writeOutput("<li>New Users: #stats.newUsers#</li>");
writeOutput("<li>Total Orders: #stats.orders#</li>");
writeOutput("<li>Revenue: #dollarFormat(stats.revenue)#</li>");
writeOutput("<li>Average Order Value: #dollarFormat(stats.avgOrderValue)#</li>");
writeOutput("</ul>");

// Send email if requested
if (len(emailTo)) {
    // Use Wheels email functionality
    writeOutput("<br>Sending report to: #emailTo#...<br>");
    // Email sending logic here
}

writeOutput("<br><em>Report generated on #dateTimeFormat(now())#</em>");
</cfscript>
```

## Script Context

Scripts executed by the runner have access to:

### Available Functions
- `request.model(name)` - Access Wheels models
- `request.query(sql)` - Execute SQL queries
- `request.scriptParams` - Access passed parameters
- `request.scriptVerbose` - Check if verbose mode is enabled

### Available Variables
- All Wheels helper functions
- Application scope
- Standard CFML functions

### Example Accessing Script Context
```cfm
<cfscript>
// Access parameters
var limit = structKeyExists(request.scriptParams, "limit") ? request.scriptParams.limit : 10;

// Use models
var users = request.model("User").findAll(maxRows=limit);

// Direct queries
var stats = request.query("SELECT COUNT(*) as total FROM posts");

// Use helpers
writeOutput("Found #pluralize(users.recordCount, 'user')#<br>");
</cfscript>
```

## Best Practices

1. **Error Handling**: Always include try/catch blocks for critical operations
2. **Dry Run Mode**: Implement a dryRun parameter for destructive operations
3. **Progress Output**: Use writeOutput() to show progress for long-running scripts
4. **Transactions**: Use database transactions for data consistency
5. **Logging**: Log important operations for audit trails
6. **Idempotency**: Make scripts safe to run multiple times

## Security Considerations

- Scripts run with full application permissions
- Validate and sanitize any external input
- Be cautious with production environment scripts
- Consider implementing confirmation prompts for destructive operations

## Troubleshooting

### "Script file not found"
- Check the file path is correct
- Use relative paths from the application root
- Ensure file extension is .cfm, .cfc, or .cfs

### "Server must be running"
- Start the server: `wheels server start`
- Check server status: `wheels server status`

### Script errors
- Check syntax in your script file
- Verify model and table names
- Test queries separately in console first

## Related Commands

- [`wheels console`](console.md) - Interactive REPL for testing code
- [`wheels environment`](environment.md) - Manage environment settings
- [`wheels generate migration`](../generate/migration.md) - Create database migrations

## See Also

- [Wheels Model Documentation](../../../database-interaction-through-models/)
- [CommandBox Task Runners](https://commandbox.ortusbooks.com/task-runners)