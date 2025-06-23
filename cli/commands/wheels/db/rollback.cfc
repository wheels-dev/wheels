/**
 * Rollback database migrations
 */
component extends="../base" {
    
    property name="migrationService" inject="MigrationService@wheelscli";
    
    /**
     * Rollback database migrations
     * 
     * @steps Number of migrations to rollback
     * @environment Environment to rollback migrations for
     * @verbose Show detailed rollback output
     * @force Skip confirmation prompt
     * @help Rollback the last migration(s)
     */
    function run(
        numeric steps = 1,
        string environment = "development",
        boolean verbose = false,
        boolean force = false
    ) {
        ensureWheelsProject();
        
        print.line();
        print.boldBlueLine("Rolling back migrations for #arguments.environment# environment");
        
        // Check if migrations table exists
        if (!migrationService.migrationsTableExists(getCWD())) {
            print.line();
            print.yellowLine("No migrations have been run yet.");
            return;
        }
        
        // Get applied migrations
        var applied = migrationService.getAppliedMigrations(getCWD());
        
        if (!arrayLen(applied)) {
            print.line();
            print.yellowLine("No migrations to rollback.");
            return;
        }
        
        // Show migrations that will be rolled back
        var toRollback = [];
        var count = 0;
        
        for (var i = arrayLen(applied); i >= 1 && count < arguments.steps; i--) {
            arrayAppend(toRollback, applied[i]);
            count++;
        }
        
        print.line();
        print.yellowLine("The following migration#arrayLen(toRollback) != 1 ? 's' : ''# will be rolled back:");
        print.line();
        
        for (var migration in toRollback) {
            print.indentedLine("• #migration.version# - #migration.name#");
        }
        
        if (!arguments.force) {
            print.line();
            print.redLine("⚠️  This operation cannot be automatically undone!");
            
            if (!confirm("Are you sure you want to rollback #arrayLen(toRollback)# migration#arrayLen(toRollback) != 1 ? 's' : ''#?")) {
                print.line("Rollback cancelled.");
                return;
            }
        }
        
        print.line();
        
        // Perform rollback
        var rolledBackCount = migrationService.rollbackMigrations(
            getCWD(),
            arguments.steps,
            arguments.verbose
        );
        
        if (rolledBackCount > 0) {
            print.line();
            print.greenBoldLine("✅ Rollback complete!");
            print.line();
            print.yellowLine("Next steps:");
            print.indentedLine("• Fix any issues in your migration files");
            print.indentedLine("• Run 'wheels db migrate' to re-apply migrations");
        }
    }
}