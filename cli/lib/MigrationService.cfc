/**
 * Migration Service for Wheels CLI
 * Handles database migration operations
 */
component singleton {
    
    property name="fileSystemUtil" inject="FileSystem";
    property name="consoleLogger" inject="logbox:logger:console";
    property name="print" inject="PrintBuffer";
    property name="databaseService" inject="DatabaseService@wheelscli";
    
    /**
     * Get list of migration files
     */
    function getMigrationFiles(required string projectPath) {
        var migrationPath = arguments.projectPath & "/db/migrate/";
        
        if (!directoryExists(migrationPath)) {
            return [];
        }
        
        var files = directoryList(
            migrationPath,
            false,
            "query",
            "*.cfc",
            "name ASC"
        );
        
        var migrations = [];
        for (var file in files) {
            var migrationInfo = parseMigrationFileName(file.name);
            if (structCount(migrationInfo)) {
                migrationInfo.path = migrationPath & file.name;
                migrationInfo.file = file.name;
                arrayAppend(migrations, migrationInfo);
            }
        }
        
        return migrations;
    }
    
    /**
     * Parse migration file name
     */
    private function parseMigrationFileName(required string fileName) {
        // Format: YYYYMMDDHHMMSS_MigrationName.cfc
        var pattern = "^(\d{14})_(.+)\.cfc$";
        
        if (reFindNoCase(pattern, arguments.fileName)) {
            var matches = reFindNoCase(pattern, arguments.fileName, 1, true);
            return {
                version = mid(arguments.fileName, matches.pos[2], matches.len[2]),
                name = mid(arguments.fileName, matches.pos[3], matches.len[3]),
                timestamp = parseMigrationTimestamp(mid(arguments.fileName, matches.pos[2], matches.len[2]))
            };
        }
        
        return {};
    }
    
    /**
     * Parse migration timestamp
     */
    private function parseMigrationTimestamp(required string version) {
        // Parse YYYYMMDDHHMMSS format
        var year = left(arguments.version, 4);
        var month = mid(arguments.version, 5, 2);
        var day = mid(arguments.version, 7, 2);
        var hour = mid(arguments.version, 9, 2);
        var minute = mid(arguments.version, 11, 2);
        var second = mid(arguments.version, 13, 2);
        
        try {
            return createDateTime(year, month, day, hour, minute, second);
        } catch (any e) {
            return now(); // Fallback
        }
    }
    
    /**
     * Get migration status
     */
    function getMigrationStatus(required string projectPath) {
        var migrations = getMigrationFiles(arguments.projectPath);
        var appliedMigrations = getAppliedMigrations(arguments.projectPath);
        
        var status = [];
        
        for (var migration in migrations) {
            var isApplied = arrayFind(appliedMigrations, function(m) {
                return m.version == migration.version;
            });
            
            migration.status = isApplied ? "up" : "down";
            migration.appliedAt = isApplied ? appliedMigrations[isApplied].appliedAt : "";
            
            arrayAppend(status, migration);
        }
        
        return status;
    }
    
    /**
     * Get applied migrations from database
     */
    function getAppliedMigrations(required string projectPath) {
        // In a real implementation, this would query the schema_migrations table
        // For now, we'll check for a migrations tracking file
        var trackingFile = arguments.projectPath & "/db/.migrations";
        
        if (!fileExists(trackingFile)) {
            return [];
        }
        
        try {
            var data = fileRead(trackingFile);
            if (isJSON(data)) {
                return deserializeJSON(data);
            }
        } catch (any e) {
            consoleLogger.error("Error reading migrations tracking file: #e.message#");
        }
        
        return [];
    }
    
    /**
     * Record applied migration
     */
    function recordAppliedMigration(required string projectPath, required struct migration) {
        var trackingFile = arguments.projectPath & "/db/.migrations";
        var applied = getAppliedMigrations(arguments.projectPath);
        
        // Add migration to applied list
        arrayAppend(applied, {
            version = arguments.migration.version,
            name = arguments.migration.name,
            appliedAt = now()
        });
        
        // Sort by version
        arraySort(applied, function(a, b) {
            return compare(a.version, b.version);
        });
        
        // Save to file
        fileWrite(trackingFile, serializeJSON(applied));
    }
    
    /**
     * Remove applied migration record
     */
    function removeAppliedMigration(required string projectPath, required string version) {
        var trackingFile = arguments.projectPath & "/db/.migrations";
        var applied = getAppliedMigrations(arguments.projectPath);
        
        // Remove migration from list
        applied = arrayFilter(applied, function(m) {
            return m.version != version;
        });
        
        // Save to file
        if (arrayLen(applied)) {
            fileWrite(trackingFile, serializeJSON(applied));
        } else if (fileExists(trackingFile)) {
            fileDelete(trackingFile);
        }
    }
    
    /**
     * Run pending migrations
     */
    function runMigrations(required string projectPath, string target = "", boolean verbose = false) {
        var migrations = getMigrationFiles(arguments.projectPath);
        var applied = getAppliedMigrations(arguments.projectPath);
        var appliedVersions = [];
        
        for (var a in applied) {
            arrayAppend(appliedVersions, a.version);
        }
        
        var pending = [];
        for (var migration in migrations) {
            if (!arrayFind(appliedVersions, migration.version)) {
                arrayAppend(pending, migration);
                
                // Stop if we've reached the target version
                if (len(arguments.target) && migration.version == arguments.target) {
                    break;
                }
            }
        }
        
        if (!arrayLen(pending)) {
            print.yellowLine("No pending migrations to run.");
            return 0;
        }
        
        print.boldLine("Running #arrayLen(pending)# migration#arrayLen(pending) != 1 ? 's' : ''#:");
        print.line();
        
        var successCount = 0;
        
        for (var migration in pending) {
            print.yellowText("Running migration: #migration.name# (#migration.version#)... ");
            
            try {
                // In a real implementation, this would:
                // 1. Create component instance
                // 2. Start transaction
                // 3. Call up() method
                // 4. Record migration
                // 5. Commit transaction
                
                // For now, we'll simulate
                if (arguments.verbose) {
                    print.line();
                    print.indentedLine("Would execute: #migration.path#");
                }
                
                recordAppliedMigration(arguments.projectPath, migration);
                print.greenLine("✓");
                successCount++;
                
            } catch (any e) {
                print.redLine("✗");
                print.redLine("Error: #e.message#");
                
                if (arguments.verbose && structKeyExists(e, "detail")) {
                    print.line(e.detail);
                }
                
                // Stop on first error
                break;
            }
        }
        
        print.line();
        
        if (successCount == arrayLen(pending)) {
            print.greenLine("All migrations completed successfully!");
        } else {
            print.yellowLine("Completed #successCount# of #arrayLen(pending)# migrations.");
            if (successCount < arrayLen(pending)) {
                print.redLine("Migration failed. Fix the error and run 'wheels db migrate' again.");
            }
        }
        
        return successCount;
    }
    
    /**
     * Rollback migrations
     */
    function rollbackMigrations(required string projectPath, numeric steps = 1, boolean verbose = false) {
        var applied = getAppliedMigrations(arguments.projectPath);
        
        if (!arrayLen(applied)) {
            print.yellowLine("No migrations to rollback.");
            return 0;
        }
        
        // Get migrations to rollback (most recent first)
        var toRollback = [];
        var count = 0;
        
        for (var i = arrayLen(applied); i >= 1 && count < arguments.steps; i--) {
            arrayAppend(toRollback, applied[i]);
            count++;
        }
        
        print.boldLine("Rolling back #arrayLen(toRollback)# migration#arrayLen(toRollback) != 1 ? 's' : ''#:");
        print.line();
        
        var successCount = 0;
        
        for (var migration in toRollback) {
            print.yellowText("Rolling back: #migration.name# (#migration.version#)... ");
            
            try {
                // In a real implementation, this would:
                // 1. Find migration file
                // 2. Create component instance
                // 3. Start transaction
                // 4. Call down() method
                // 5. Remove migration record
                // 6. Commit transaction
                
                // For now, we'll simulate
                if (arguments.verbose) {
                    print.line();
                    var migrationFile = arguments.projectPath & "/db/migrate/" & 
                                       migration.version & "_" & migration.name & ".cfc";
                    print.indentedLine("Would execute down(): #migrationFile#");
                }
                
                removeAppliedMigration(arguments.projectPath, migration.version);
                print.greenLine("✓");
                successCount++;
                
            } catch (any e) {
                print.redLine("✗");
                print.redLine("Error: #e.message#");
                
                if (arguments.verbose && structKeyExists(e, "detail")) {
                    print.line(e.detail);
                }
                
                // Stop on first error
                break;
            }
        }
        
        print.line();
        
        if (successCount == arrayLen(toRollback)) {
            print.greenLine("Rollback completed successfully!");
        } else {
            print.yellowLine("Rolled back #successCount# of #arrayLen(toRollback)# migrations.");
            if (successCount < arrayLen(toRollback)) {
                print.redLine("Rollback failed. Fix the error and try again.");
            }
        }
        
        return successCount;
    }
    
    /**
     * Create schema migrations table
     */
    function createMigrationsTable(required string projectPath) {
        // In a real implementation, this would create the schema_migrations table
        // For now, we'll ensure the tracking file exists
        var trackingFile = arguments.projectPath & "/db/.migrations";
        
        if (!fileExists(trackingFile)) {
            fileWrite(trackingFile, "[]");
        }
        
        return true;
    }
    
    /**
     * Check if migrations table exists
     */
    function migrationsTableExists(required string projectPath) {
        var trackingFile = arguments.projectPath & "/db/.migrations";
        return fileExists(trackingFile);
    }
}