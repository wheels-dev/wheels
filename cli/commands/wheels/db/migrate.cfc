/**
 * Run database migrations
 */
component extends="../base" {
    
    property name="migrationService" inject="MigrationService@wheelscli";
    
    /**
     * Run pending database migrations
     * 
     * @environment.hint Environment to run migrations for
     * @environment.optionsUDF completeEnvironments
     * @target.hint Run migrations up to a specific version
     * @target.optionsUDF completeMigrationVersions
     * @verbose.hint Show detailed migration output
     * @verbose.options true,false
     * @dryRun.hint Show what would be migrated without actually running
     * @dryRun.options true,false
     * @force.hint Skip confirmation prompts
     * @force.options true,false
     * @format.hint Output format
     * @format.optionsUDF completeFormatTypes
     * @help Run all pending database migrations
     */
    function run(
        string environment = "development",
        string target = "",
        boolean verbose = false,
        boolean dryRun = false,
        boolean force = false,
        string format = "text"
    ) {
        return runCommand(function() {
            ensureWheelsProject();
            
            var result = {
                success = true,
                environment = arguments.environment,
                migrationsRun = 0,
                migrations = [],
                errors = []
            };
            
            if (variables.commandMetadata.outputFormat == "text") {
                printHeader("Database Migrations", "Environment: #arguments.environment#");
            }
            
            // Ensure migrations table exists
            if (!migrationService.migrationsTableExists(getCWD())) {
                printInfo("Creating migrations tracking...");
                migrationService.createMigrationsTable(getCWD());
            }
            
            // Get migration status
            var status = runWithSpinner("Checking migration status", function() {
                return migrationService.getMigrationStatus(getCWD());
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
            
            // Filter pending migrations
            var pending = status.pending;
            
            // Apply target filter if specified
            if (len(arguments.target)) {
                var targetFound = false;
                var filtered = [];
                
                for (var migration in pending) {
                    arrayAppend(filtered, migration);
                    if (migration.version == arguments.target) {
                        targetFound = true;
                        break;
                    }
                }
                
                if (!targetFound) {
                    error("Target migration version not found: #arguments.target#");
                }
                
                pending = filtered;
            }
            
            if (!arrayLen(pending)) {
                if (variables.commandMetadata.outputFormat == "text") {
                    printSuccess("All migrations are up to date!");
                } else {
                    result.message = "All migrations are up to date";
                }
                output(result, arguments.format);
                return;
            }
            
            // Show pending migrations
            if (variables.commandMetadata.outputFormat == "text") {
                printSection("Pending migrations");
                
                for (var migration in pending) {
                    print.indentedLine("• #migration.version# - #migration.name#");
                }
                
                if (arguments.dryRun) {
                    print.line();
                    printWarning("Dry run mode - no migrations will be executed.");
                    result.message = "Dry run completed";
                    result.pendingMigrations = pending;
                    output(result, arguments.format);
                    return;
                }
                
                // Confirm before running
                if (!arguments.force) {
                    print.line();
                    if (!confirm("Run #arrayLen(pending)# migration#arrayLen(pending) != 1 ? 's' : ''#?")) {
                        printWarning("Migration cancelled.");
                        result.success = false;
                        result.message = "Migration cancelled by user";
                        output(result, arguments.format);
                        return;
                    }
                }
            }
            
            // Run migrations
            var migrationResult = migrationService.runMigrations(getCWD(), {
                target = arguments.target,
                verbose = arguments.verbose,
                dryRun = arguments.dryRun,
                continueOnError = false
            });
            
            result.success = migrationResult.success;
            result.migrationsRun = migrationResult.migrationsRun;
            result.migrations = migrationResult.migrations ?: [];
            
            if (!migrationResult.success && arrayLen(migrationResult.failures)) {
                result.errors = migrationResult.failures;
            }
            
            // Output based on format
            if (variables.commandMetadata.outputFormat == "text") {
                if (!result.success) {
                    printError("Migration failed!");
                    if (arrayLen(result.errors)) {
                        for (var error in result.errors) {
                            print.redLine("  #error.migration.name#: #error.error.message#");
                        }
                    }
                }
            } else {
                output(result, arguments.format);
            }
        }, argumentCollection=arguments);
    }
}