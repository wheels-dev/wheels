/**
 * Show migration status
 */
component extends="../base" {
    
    property name="migrationService" inject="MigrationService@wheelscli";
    
    /**
     * Display the status of database migrations
     * 
     * @environment.hint Environment to check status for
     * @environment.optionsUDF completeEnvironments
     * @pending.hint Show only pending migrations
     * @pending.options true,false
     * @applied.hint Show only applied migrations
     * @applied.options true,false
     * @format.hint Output format
     * @format.optionsUDF completeFormatTypes
     * @help Display which migrations have been run
     */
    function run(
        string environment = "development",
        boolean pending = false,
        boolean applied = false,
        string format = "text"
    ) {
        return runCommand(function() {
            ensureWheelsProject();
            
            var result = {
                environment = arguments.environment,
                migrations = [],
                summary = {
                    total = 0,
                    applied = 0,
                    pending = 0
                }
            };
            
            if (variables.commandMetadata.outputFormat == "text") {
                printHeader("Migration status", "Environment: #arguments.environment#");
            }
            
            // Get migration status
            var status = runWithSpinner("Loading migration status", function() {
                return migrationService.getMigrationStatus(getCWD(), true);
            });
            
            if (!arrayLen(status.all)) {
                if (variables.commandMetadata.outputFormat == "text") {
                    printWarning("No migration files found.");
                    print.line();
                    printInfo("Create a migration with:");
                    print.indentedLine("wheels create migration CreateUsersTable");
                } else {
                    result.message = "No migration files found";
                }
                output(result, arguments.format);
                return;
            }
            
            // Filter based on arguments
            var migrations = status.all;
            if (arguments.pending) {
                migrations = status.pending;
            } else if (arguments.applied) {
                migrations = status.applied;
            }
            
            // Update summary
            result.summary.total = arrayLen(status.all);
            result.summary.applied = arrayLen(status.applied);
            result.summary.pending = arrayLen(status.pending);
            
            // Prepare data for table
            var tableData = [];
            for (var migration in migrations) {
                arrayAppend(tableData, {
                    status = migration.status == "up" ? "UP" : "DOWN",
                    version = migration.version,
                    name = migration.name,
                    appliedAt = migration.status == "up" && isDate(migration.appliedAt) 
                        ? dateTimeFormat(migration.appliedAt, "yyyy-mm-dd HH:nn:ss") 
                        : "Not applied"
                });
            }
            
            result.migrations = tableData;
            
            // Display based on format
            if (variables.commandMetadata.outputFormat == "text") {
                // Use table formatter
                printTable(
                    data = tableData,
                    headers = ["Status", "Version", "Migration Name", "Applied At"],
                    columns = ["status", "version", "name", "appliedAt"]
                );
                
                // Summary
                print.line();
                
                if (!arguments.pending && !arguments.applied) {
                    printInfo("Summary: #result.summary.applied# UP, #result.summary.pending# DOWN");
                    
                    if (result.summary.pending > 0) {
                        print.line();
                        printInfo("Run 'wheels db migrate' to apply pending migrations.");
                    }
                } else if (arguments.pending) {
                    printInfo("Showing #arrayLen(migrations)# pending migration#arrayLen(migrations) != 1 ? 's' : ''#");
                } else if (arguments.applied) {
                    printInfo("Showing #arrayLen(migrations)# applied migration#arrayLen(migrations) != 1 ? 's' : ''#");
                }
                
                // Show orphaned migrations if any
                if (arrayLen(status.orphaned)) {
                    print.line();
                    printWarning("Found #arrayLen(status.orphaned)# orphaned migration#arrayLen(status.orphaned) != 1 ? 's' : ''# (in database but no file):");
                    for (var orphan in status.orphaned) {
                        print.redLine("  - #orphan.version# (#orphan.name#)");
                    }
                }
            } else {
                // Add orphaned to result for non-text output
                if (arrayLen(status.orphaned)) {
                    result.orphaned = status.orphaned;
                }
                output(result, arguments.format);
            }
        }, argumentCollection=arguments);
    }
}