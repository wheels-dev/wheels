/**
 * Watch Wheels application files for changes and automatically reload the application.
 * 
 * {code:bash}
 * wheels watch
 * wheels watch --reload --tests
 * wheels watch --includeDirs=controllers,models --excludeFiles=*.txt,*.log
 * wheels watch --interval=2 --command="wheels test run"
 * {code}
 */
component extends="base" {

    /**
     * @includeDirs Comma-delimited list of directories to watch (defaults to controllers,models,views,config)
     * @excludeFiles Comma-delimited list of file patterns to ignore (defaults to none)
     * @interval Interval in seconds to check for changes (default 1)
     * @reload.hint Reload framework on changes (default true)
     * @tests.hint Run tests on changes
     * @migrations.hint Run migrations on schema changes
     * @command.hint Custom command to run on changes
     * @debounce.hint Debounce delay in milliseconds
     */
    function run(
        string includeDirs="controllers,models,views,config,migrator/migrations", 
        string excludeFiles="", 
        numeric interval=1,
        boolean reload=true,
        boolean tests=false,
        boolean migrations=false,
        string command="",
        numeric debounce=500
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine( "🔄 Wheels Watch Mode" );
        print.line( "Monitoring files for changes..." );
        print.line( "Press Ctrl+C to stop watching" );
        print.line();
        
        // Display what actions will be taken
        if (arguments.reload) print.greenLine("✓ Will reload framework on changes");
        if (arguments.tests) print.greenLine("✓ Will run tests on changes");
        if (arguments.migrations) print.greenLine("✓ Will run migrations on schema changes");
        if (len(arguments.command)) print.greenLine("✓ Will run: #arguments.command#");
        print.line();
        
        // Convert directories to array
        local.dirsToWatch = listToArray(arguments.includeDirs);
        local.filesToExclude = listToArray(arguments.excludeFiles);
        
        // Initialize tracking for last modified times
        local.fileTimestamps = {};
        
        // Initial scan of files to establish baseline
        for (local.dir in local.dirsToWatch) {
            local.path = fileSystemUtil.resolvePath("app/#local.dir#");
            if (directoryExists(local.path)) {
                local.files = directoryList(local.path, true, "path");
                for (local.file in local.files) {
                    // Skip directories and excluded files
                    if (fileExists(local.file) && !isExcluded(local.file, local.filesToExclude)) {
                        local.fileTimestamps[local.file] = getFileInfo(local.file).lastModified;
                    }
                }
            }
        }
        
        print.greenLine("Watching #structCount(local.fileTimestamps)# files across #arrayLen(local.dirsToWatch)# directories");
        
        // Start the watch loop
        while (true) {
            sleep(arguments.interval * 1000);
            
            local.changes = [];
            
            // Scan for changed files
            for (local.dir in local.dirsToWatch) {
                local.path = fileSystemUtil.resolvePath("app/#local.dir#");
                if (directoryExists(local.path)) {
                    local.files = directoryList(local.path, true, "path");
                    for (local.file in local.files) {
                        // Skip directories and excluded files
                        if (fileExists(local.file) && !isExcluded(local.file, local.filesToExclude)) {
                            local.lastModified = getFileInfo(local.file).lastModified;
                            
                            // New file
                            if (!structKeyExists(local.fileTimestamps, local.file)) {
                                local.fileTimestamps[local.file] = local.lastModified;
                                arrayAppend(local.changes, { file: local.file, type: "new" });
                            }
                            // Modified file
                            else if (local.fileTimestamps[local.file] != local.lastModified) {
                                local.fileTimestamps[local.file] = local.lastModified;
                                arrayAppend(local.changes, { file: local.file, type: "modified" });
                            }
                        }
                    }
                }
            }
            
            // If there are changes, take appropriate actions
            if (arrayLen(local.changes) > 0) {
                // Log changes
                print.line();
                print.cyanLine("📝 Detected changes:");
                for (local.change in local.changes) {
                    local.relativePath = replace(local.change.file, getCWD(), "");
                    if (local.change.type == "new") {
                        print.line("  + #local.relativePath# (new)");
                    } else {
                        print.line("  ~ #local.relativePath# (modified)");
                    }
                }
                print.line();
                
                // Perform actions based on settings
                local.actionsTaken = false;
                
                // Reload the application
                if (arguments.reload) {
                    print.yellowLine("🔄 Reloading application...");
                    try {
                        command("wheels reload").run();
                        print.greenLine("✅ Application reloaded successfully at #timeFormat(now(), "HH:mm:ss")#");
                        local.actionsTaken = true;
                    } catch (any e) {
                        print.redLine("❌ Error reloading application: #e.message#");
                    }
                }
                
                // Run tests if enabled
                if (arguments.tests) {
                    print.yellowLine("🧪 Running tests...");
                    try {
                        // Determine which tests to run based on changed files
                        local.testFilter = getTestFilter(local.changes);
                        local.testCommand = "wheels test run";
                        if (len(local.testFilter)) {
                            local.testCommand &= " --filter=#local.testFilter#";
                        }
                        command(local.testCommand).run();
                        local.actionsTaken = true;
                    } catch (any e) {
                        print.redLine("❌ Error running tests: #e.message#");
                    }
                }
                
                // Run migrations if schema changes detected
                if (arguments.migrations && hasMigrationChanges(local.changes)) {
                    print.yellowLine("🗄️  Running migrations...");
                    try {
                        command("wheels dbmigrate up").run();
                        print.greenLine("✅ Migrations completed");
                        local.actionsTaken = true;
                    } catch (any e) {
                        print.redLine("❌ Error running migrations: #e.message#");
                    }
                }
                
                // Run custom command if specified
                if (len(arguments.command)) {
                    print.yellowLine("⚡ Running: #arguments.command#");
                    try {
                        command(arguments.command).run();
                        local.actionsTaken = true;
                    } catch (any e) {
                        print.redLine("❌ Error running command: #e.message#");
                    }
                }
                
                if (local.actionsTaken) {
                    print.line();
                    print.greenLine("✅ All actions completed, watching for more changes...");
                }
                
                print.line();
            }
        }
    }
    
    /**
     * Helper function to check if a file should be excluded
     */
    private boolean function isExcluded(required string filePath, required array exclusions) {
        if (arrayLen(arguments.exclusions) == 0) {
            return false;
        }
        
        local.fileName = getFileFromPath(arguments.filePath);
        
        for (local.pattern in arguments.exclusions) {
            if (local.pattern.startsWith("*")) {
                local.extension = replace(local.pattern, "*", "");
                if (local.fileName.endsWith(local.extension)) {
                    return true;
                }
            } else if (local.fileName == local.pattern) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * Determine test filter based on changed files
     */
    private function getTestFilter(required array changes) {
        local.filters = [];
        
        for (local.change in arguments.changes) {
            local.relativePath = replace(local.change.file, getCWD(), "");
            
            // Extract model/controller name from path
            if (findNoCase("/models/", local.relativePath)) {
                local.modelName = listLast(getFileFromPath(local.change.file), ".");
                arrayAppend(local.filters, local.modelName);
            } else if (findNoCase("/controllers/", local.relativePath)) {
                local.controllerName = listFirst(getFileFromPath(local.change.file), ".");
                arrayAppend(local.filters, local.controllerName);
            }
        }
        
        return arrayToList(arrayRemoveDuplicates(local.filters));
    }
    
    /**
     * Check if any changes are migration-related
     */
    private function hasMigrationChanges(required array changes) {
        for (local.change in arguments.changes) {
            if (findNoCase("/migrator/migrations/", local.change.file) || 
                findNoCase("/db/schema", local.change.file)) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Remove duplicates from array (for older CF versions)
     */
    private function arrayRemoveDuplicates(required array arr) {
        local.result = [];
        local.seen = {};
        
        for (local.item in arguments.arr) {
            if (!structKeyExists(local.seen, local.item)) {
                arrayAppend(local.result, local.item);
                local.seen[local.item] = true;
            }
        }
        
        return local.result;
    }
}