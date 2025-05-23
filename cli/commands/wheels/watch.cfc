/**
 * Watch Wheels application files for changes and automatically reload the application.
 * 
 * {code:bash}
 * wheels watch
 * wheels watch --includeDirs=controllers,models --excludeFiles=*.txt,*.log
 * wheels watch --interval=2
 * {code}
 */
component extends="base" {

    /**
     * @includeDirs Comma-delimited list of directories to watch (defaults to controllers,models,views,config)
     * @excludeFiles Comma-delimited list of file patterns to ignore (defaults to none)
     * @interval Interval in seconds to check for changes (default 1)
     */
    function run(
        string includeDirs="controllers,models,views,config", 
        string excludeFiles="", 
        numeric interval=1
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine( "Wheels Watch Mode" );
        print.line( "Monitoring files for changes..." );
        print.line( "Press Ctrl+C to stop watching" );
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
            
            // If there are changes, reload the application
            if (arrayLen(local.changes) > 0) {
                // Log changes
                for (local.change in local.changes) {
                    local.relativePath = replace(local.change.file, getCWD(), "");
                    if (local.change.type == "new") {
                        print.boldCyanLine("New file detected: #local.relativePath#");
                    } else {
                        print.boldCyanLine("Modified file detected: #local.relativePath#");
                    }
                }
                
                // Reload the application
                print.line();
                print.boldGreenLine("Reloading application...");
                
                try {
                    command("wheels reload").run();
                    print.boldGreenLine("Application reloaded successfully at #timeFormat(now(), "HH:mm:ss")#");
                } catch (any e) {
                    print.boldRedLine("Error reloading application: #e.message#");
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
}