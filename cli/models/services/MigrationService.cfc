/**
 * Migration Service for Wheels CLI
 * Handles database migration operations
 * 
 * @singleton
 * @author CFWheels Team
 * @version 3.0.0
 */
component accessors="true" singleton {
    
    // DI Properties
    property name="fileSystem" inject="FileSystem";
    property name="log" inject="logbox:logger:{this}";
    property name="print" inject="PrintBuffer";
    property name="progressBar" inject="ProgressBar";
    property name="databaseService" inject="DatabaseService@wheels-cli-next";
    property name="configService" inject="ConfigService@wheels-cli-next";
    property name="projectService" inject="ProjectService@wheels-cli-next";
    property name="formatterService" inject="FormatterService@wheels-cli-next";
    
    // Service Properties
    property name="migrationsPath" type="string" default="db/migrate";
    property name="migrationsTable" type="string" default="schema_migrations";
    property name="trackingFile" type="string" default=".migrations";
    
    /**
     * Constructor
     */
    function init() {
        return this;
    }
    
    /**
     * Get list of migration files
     */
    function getMigrationFiles(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        var migrationPath = path & "/" & getMigrationsPath() & "/";
        
        if (!directoryExists(migrationPath)) {
            log.debug("Migration directory not found: #migrationPath#");
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
                migrationInfo.size = file.size;
                migrationInfo.dateLastModified = file.dateLastModified;
                arrayAppend(migrations, migrationInfo);
            }
        }
        
        // Sort by version
        arraySort(migrations, function(a, b) {
            return compare(a.version, b.version);
        });
        
        return migrations;
    }
    
    /**
     * Parse migration file name
     */
    private function parseMigrationFileName(required string fileName) {
        // Format: YYYYMMDDHHMMSS_MigrationName.cfc
        var pattern = "^(\d{14})_(.+)\.cfc$";
        
        var matches = reMatch(pattern, arguments.fileName);
        if (arrayLen(matches)) {
            var parts = reFindNoCase(pattern, arguments.fileName, 1, true);
            if (parts.pos[1]) {
                var version = mid(arguments.fileName, parts.pos[2], parts.len[2]);
                var name = mid(arguments.fileName, parts.pos[3], parts.len[3]);
                
                return {
                    version = version,
                    name = name,
                    className = name,
                    timestamp = parseMigrationTimestamp(version)
                };
            }
        }
        
        log.debug("Invalid migration filename format: #arguments.fileName#");
        return {};
    }
    
    /**
     * Parse migration timestamp
     */
    private function parseMigrationTimestamp(required string version) {
        // Parse YYYYMMDDHHMMSS format
        try {
            var year = left(arguments.version, 4);
            var month = mid(arguments.version, 5, 2);
            var day = mid(arguments.version, 7, 2);
            var hour = mid(arguments.version, 9, 2);
            var minute = mid(arguments.version, 11, 2);
            var second = mid(arguments.version, 13, 2);
            
            return createDateTime(year, month, day, hour, minute, second);
        } catch (any e) {
            log.error("Failed to parse migration timestamp: #arguments.version#", e);
            return now();
        }
    }
    
    /**
     * Generate migration timestamp
     */
    function generateMigrationTimestamp(date timestamp = now()) {
        return dateFormat(arguments.timestamp, "yyyymmdd") & timeFormat(arguments.timestamp, "HHnnss");
    }
    
    /**
     * Get migration status
     */
    function getMigrationStatus(string projectPath = "", boolean detailed = false) {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        var migrations = getMigrationFiles(path);
        var applied = getAppliedMigrations(path);
        var appliedMap = {};
        
        // Create map for faster lookup
        for (var app in applied) {
            appliedMap[app.version] = app;
        }
        
        var status = {
            all = [],
            pending = [],
            applied = [],
            orphaned = []
        };
        
        // Check migration files
        for (var migration in migrations) {
            migration.status = structKeyExists(appliedMap, migration.version) ? "up" : "down";
            migration.appliedAt = migration.status == "up" ? appliedMap[migration.version].appliedAt : "";
            
            arrayAppend(status.all, migration);
            
            if (migration.status == "up") {
                arrayAppend(status.applied, migration);
            } else {
                arrayAppend(status.pending, migration);
            }
        }
        
        // Check for orphaned migrations (in DB but no file)
        if (arguments.detailed) {
            for (var version in appliedMap) {
                var found = false;
                for (var mig in migrations) {
                    if (mig.version == version) {
                        found = true;
                        break;
                    }
                }
                
                if (!found) {
                    arrayAppend(status.orphaned, appliedMap[version]);
                }
            }
        }
        
        return status;
    }
    
    /**
     * Get applied migrations from tracking
     */
    function getAppliedMigrations(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        
        // Try database first (future implementation)
        if (isDatabaseTrackingEnabled()) {
            return getAppliedMigrationsFromDatabase(path);
        }
        
        // Fall back to file tracking
        return getAppliedMigrationsFromFile(path);
    }
    
    /**
     * Get applied migrations from file
     */
    private function getAppliedMigrationsFromFile(required string projectPath) {
        var trackingFile = arguments.projectPath & "/db/" & getTrackingFile();
        
        if (!fileExists(trackingFile)) {
            return [];
        }
        
        try {
            var data = fileRead(trackingFile);
            if (isJSON(data)) {
                var migrations = deserializeJSON(data);
                
                // Ensure proper date format
                for (var mig in migrations) {
                    if (structKeyExists(mig, "appliedAt") && isSimpleValue(mig.appliedAt)) {
                        mig.appliedAt = parseDateTime(mig.appliedAt);
                    }
                }
                
                return migrations;
            }
        } catch (any e) {
            log.error("Error reading migrations tracking file: #e.message#", e);
        }
        
        return [];
    }
    
    /**
     * Get applied migrations from database
     */
    private function getAppliedMigrationsFromDatabase(required string projectPath) {
        // Future implementation: query schema_migrations table
        log.debug("Database tracking not yet implemented, falling back to file tracking");
        return getAppliedMigrationsFromFile(arguments.projectPath);
    }
    
    /**
     * Record applied migration
     */
    function recordAppliedMigration(required string projectPath, required struct migration) {
        var applied = getAppliedMigrations(arguments.projectPath);
        
        // Check if already applied
        for (var app in applied) {
            if (app.version == arguments.migration.version) {
                log.warn("Migration already recorded as applied: #arguments.migration.version#");
                return;
            }
        }
        
        // Add migration to applied list
        arrayAppend(applied, {
            version = arguments.migration.version,
            name = arguments.migration.name,
            appliedAt = now(),
            checksum = calculateMigrationChecksum(arguments.migration)
        });
        
        // Sort by version
        arraySort(applied, function(a, b) {
            return compare(a.version, b.version);
        });
        
        // Save
        if (isDatabaseTrackingEnabled()) {
            saveAppliedMigrationsToDatabase(arguments.projectPath, applied);
        } else {
            saveAppliedMigrationsToFile(arguments.projectPath, applied);
        }
        
        log.info("Recorded migration: #arguments.migration.version# - #arguments.migration.name#");
    }
    
    /**
     * Remove applied migration record
     */
    function removeAppliedMigration(required string projectPath, required string version) {
        var applied = getAppliedMigrations(arguments.projectPath);
        var originalCount = arrayLen(applied);
        
        // Remove migration from list
        applied = arrayFilter(applied, function(m) {
            return m.version != version;
        });
        
        if (arrayLen(applied) == originalCount) {
            log.warn("Migration not found in applied list: #arguments.version#");
            return;
        }
        
        // Save
        if (isDatabaseTrackingEnabled()) {
            saveAppliedMigrationsToDatabase(arguments.projectPath, applied);
        } else {
            saveAppliedMigrationsToFile(arguments.projectPath, applied);
        }
        
        log.info("Removed migration record: #arguments.version#");
    }
    
    /**
     * Save applied migrations to file
     */
    private function saveAppliedMigrationsToFile(required string projectPath, required array migrations) {
        var trackingFile = arguments.projectPath & "/db/" & getTrackingFile();
        
        // Ensure directory exists
        var dir = getDirectoryFromPath(trackingFile);
        if (!directoryExists(dir)) {
            directoryCreate(dir, true);
        }
        
        if (arrayLen(arguments.migrations)) {
            fileWrite(trackingFile, serializeJSON(arguments.migrations, false, false));
        } else if (fileExists(trackingFile)) {
            fileDelete(trackingFile);
        }
    }
    
    /**
     * Save applied migrations to database
     */
    private function saveAppliedMigrationsToDatabase(required string projectPath, required array migrations) {
        // Future implementation
        log.debug("Database tracking not yet implemented, falling back to file tracking");
        saveAppliedMigrationsToFile(arguments.projectPath, arguments.migrations);
    }
    
    /**
     * Run pending migrations
     */
    function runMigrations(string projectPath = "", struct options = {}) {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        var status = getMigrationStatus(path);
        var pending = status.pending;
        
        // Filter by target version if specified
        if (structKeyExists(arguments.options, "target") && len(arguments.options.target)) {
            var target = arguments.options.target;
            var filtered = [];
            
            for (var migration in pending) {
                arrayAppend(filtered, migration);
                if (migration.version == target) {
                    break;
                }
            }
            
            pending = filtered;
        }
        
        if (!arrayLen(pending)) {
            getPrint().yellowLine("No pending migrations to run.");
            return {
                success = true,
                migrationsRun = 0,
                message = "Database is up to date"
            };
        }
        
        getPrint().boldLine("Running #arrayLen(pending)# migration#arrayLen(pending) != 1 ? 's' : ''#:");
        getPrint().line();
        
        // Create progress bar
        var progress = getProgressBarHelper().create(
            total = arrayLen(pending),
            label = "Running migrations",
            showCount = true
        );
        
        var results = {
            success = true,
            migrationsRun = 0,
            failures = [],
            message = ""
        };
        
        // Start transaction if supported
        var useTransaction = structKeyExists(arguments.options, "transaction") ? arguments.options.transaction : true;
        
        try {
            for (var migration in pending) {
                try {
                    // Update progress
                    progress.update(label = "Running: #migration.name#");
                    
                    // Execute migration
                    executeMigration(path, migration, "up", arguments.options);
                    
                    // Record as applied
                    recordAppliedMigration(path, migration);
                    
                    results.migrationsRun++;
                    
                } catch (any e) {
                    results.success = false;
                    arrayAppend(results.failures, {
                        migration = migration,
                        error = e
                    });
                    
                    log.error("Migration failed: #migration.version# - #e.message#", e);
                    
                    // Stop on first error
                    if (!structKeyExists(arguments.options, "continueOnError") || !arguments.options.continueOnError) {
                        progress.error();
                        rethrow;
                    }
                }
                
                progress.increment();
            }
            
            progress.complete();
            
        } catch (any e) {
            results.success = false;
            results.message = "Migration failed: #e.message#";
        }
        
        // Print results
        getPrint().line();
        
        if (results.success) {
            getPrint().greenBoldLine("✅ All migrations completed successfully!");
            results.message = "Ran #results.migrationsRun# migration(s) successfully";
        } else {
            getPrint().yellowLine("Completed #results.migrationsRun# of #arrayLen(pending)# migrations.");
            
            if (arrayLen(results.failures)) {
                getPrint().redBoldLine("❌ #arrayLen(results.failures)# migration(s) failed:");
                for (var failure in results.failures) {
                    getPrint().redLine("  - #failure.migration.name#: #failure.error.message#");
                }
            }
        }
        
        return results;
    }
    
    /**
     * Rollback migrations
     */
    function rollbackMigrations(string projectPath = "", struct options = {}) {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        var applied = getAppliedMigrations(path);
        var steps = structKeyExists(arguments.options, "steps") ? arguments.options.steps : 1;
        
        if (!arrayLen(applied)) {
            getPrint().yellowLine("No migrations to rollback.");
            return {
                success = true,
                migrationsRolledBack = 0,
                message = "No migrations to rollback"
            };
        }
        
        // Get migrations to rollback (most recent first)
        var toRollback = [];
        var count = 0;
        
        for (var i = arrayLen(applied); i >= 1 && count < steps; i--) {
            // Find the migration file
            var migration = findMigrationFile(path, applied[i].version);
            if (structCount(migration)) {
                migration.appliedAt = applied[i].appliedAt;
                arrayAppend(toRollback, migration);
                count++;
            } else {
                log.warn("Migration file not found for version: #applied[i].version#");
            }
        }
        
        if (!arrayLen(toRollback)) {
            getPrint().yellowLine("No migration files found to rollback.");
            return {
                success = false,
                migrationsRolledBack = 0,
                message = "Migration files not found"
            };
        }
        
        getPrint().boldLine("Rolling back #arrayLen(toRollback)# migration#arrayLen(toRollback) != 1 ? 's' : ''#:");
        getPrint().line();
        
        // Create progress bar
        var progress = getProgressBarHelper().create(
            total = arrayLen(toRollback),
            label = "Rolling back migrations",
            showCount = true
        );
        
        var results = {
            success = true,
            migrationsRolledBack = 0,
            failures = [],
            message = ""
        };
        
        try {
            for (var migration in toRollback) {
                try {
                    // Update progress
                    progress.update(label = "Rolling back: #migration.name#");
                    
                    // Execute rollback
                    executeMigration(path, migration, "down", arguments.options);
                    
                    // Remove from applied
                    removeAppliedMigration(path, migration.version);
                    
                    results.migrationsRolledBack++;
                    
                } catch (any e) {
                    results.success = false;
                    arrayAppend(results.failures, {
                        migration = migration,
                        error = e
                    });
                    
                    log.error("Rollback failed: #migration.version# - #e.message#", e);
                    
                    // Stop on first error
                    progress.error();
                    rethrow;
                }
                
                progress.increment();
            }
            
            progress.complete();
            
        } catch (any e) {
            results.success = false;
            results.message = "Rollback failed: #e.message#";
        }
        
        // Print results
        getPrint().line();
        
        if (results.success) {
            getPrint().greenBoldLine("✅ Rollback completed successfully!");
            results.message = "Rolled back #results.migrationsRolledBack# migration(s) successfully";
        } else {
            getPrint().redBoldLine("❌ Rollback failed after #results.migrationsRolledBack# migration(s)");
            
            if (arrayLen(results.failures)) {
                getPrint().redLine("Failed on: #results.failures[1].migration.name#");
                getPrint().redLine("Error: #results.failures[1].error.message#");
            }
        }
        
        return results;
    }
    
    /**
     * Execute a migration
     */
    private function executeMigration(
        required string projectPath,
        required struct migration,
        required string direction,
        struct options = {}
    ) {
        log.info("Executing migration #arguments.direction#: #arguments.migration.version# - #arguments.migration.name#");
        
        // In a real implementation, this would:
        // 1. Create component instance from migration file
        // 2. Call up() or down() method
        // 3. Handle transactions
        
        // For now, simulate execution
        if (structKeyExists(arguments.options, "dryRun") && arguments.options.dryRun) {
            getPrint().greyLine("  [DRY RUN] Would execute #arguments.direction#() in #arguments.migration.file#");
            return;
        }
        
        // Simulate some work
        sleep(100);
        
        // Random failure for testing (remove in production)
        if (structKeyExists(arguments.options, "simulateFailure") && 
            arguments.options.simulateFailure && 
            randRange(1, 5) == 1) {
            throw(type="MigrationError", message="Simulated migration failure");
        }
    }
    
    /**
     * Find migration file by version
     */
    private function findMigrationFile(required string projectPath, required string version) {
        var migrations = getMigrationFiles(arguments.projectPath);
        
        for (var migration in migrations) {
            if (migration.version == arguments.version) {
                return migration;
            }
        }
        
        return {};
    }
    
    /**
     * Create schema migrations table
     */
    function createMigrationsTable(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        
        // For file-based tracking, ensure directory exists
        var dbPath = path & "/db";
        if (!directoryExists(dbPath)) {
            directoryCreate(dbPath, true);
        }
        
        // Create empty tracking file
        var trackingFile = dbPath & "/" & getTrackingFile();
        if (!fileExists(trackingFile)) {
            fileWrite(trackingFile, "[]");
            log.info("Created migrations tracking file: #trackingFile#");
        }
        
        // Future: Create actual database table
        
        return true;
    }
    
    /**
     * Check if migrations table exists
     */
    function migrationsTableExists(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        
        // Check file-based tracking
        var trackingFile = path & "/db/" & getTrackingFile();
        if (fileExists(trackingFile)) {
            return true;
        }
        
        // Future: Check for actual database table
        
        return false;
    }
    
    /**
     * Calculate migration checksum
     */
    private function calculateMigrationChecksum(required struct migration) {
        if (structKeyExists(arguments.migration, "path") && fileExists(arguments.migration.path)) {
            var content = fileRead(arguments.migration.path);
            return hash(content, "MD5");
        }
        return "";
    }
    
    /**
     * Check if database tracking is enabled
     */
    private function isDatabaseTrackingEnabled() {
        return getConfigService().get("migrations.useDatabaseTracking", false);
    }
    
    /**
     * Get migrations path
     */
    private function getMigrationsPath() {
        return getConfigService().get("migrations.path", variables.migrationsPath);
    }
    
    /**
     * Get migrations table name
     */
    private function getMigrationsTable() {
        return getConfigService().get("migrations.tableName", variables.migrationsTable);
    }
    
    /**
     * Get tracking file name
     */
    private function getTrackingFile() {
        return getConfigService().get("migrations.trackingFile", variables.trackingFile);
    }
    
    /**
     * Get print helper
     */
    private function getPrint() {
        return variables.print;
    }
}