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
        // Display command header
        Style.commandHeader("WHEELS WATCH MODE");
        Style.info("Monitoring files for changes. Press Ctrl+C to stop watching.");
        print.line();
        
        // Convert directories to array
        local.dirsToWatch = listToArray(arguments.includeDirs);
        local.filesToExclude = listToArray(arguments.excludeFiles);
        
        // Display watch configuration
        local.configTable = [
            ["Directories", arguments.includeDirs],
            ["Excluded Files", len(arguments.excludeFiles) ? arguments.excludeFiles : "None"],
            ["Check Interval", arguments.interval & " second" & (arguments.interval > 1 ? "s" : "")]
        ];
        Style.table(local.configTable);
        
        // Initialize tracking for last modified times
        local.fileTimestamps = {};
        
        // Show progress during initial scan
        local.scanProgressId = Style.startProgress("Scanning files");
        
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
        
        Style.endProgress(local.scanProgressId, true);
        Style.success("Watching #structCount(local.fileTimestamps)# files across #arrayLen(local.dirsToWatch)# directories");
        print.line();
        
        // Display interactive tips
        Style.tip("You can view your application at: http://localhost:8080");
        Style.tip("Changes to #local.dirsToWatch[1]# will be detected automatically");
        print.line();
        
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
                Style.sectionHeader("Changes Detected");
                
                for (local.change in local.changes) {
                    local.relativePath = replace(local.change.file, getCWD(), "");
                    if (local.change.type == "new") {
                        print.cyanLine("📄 New file: #local.relativePath#");
                    } else {
                        print.cyanLine("🔄 Modified: #local.relativePath#");
                    }
                }
                
                // Reload the application
                print.line();
                local.reloadId = Style.startProgress("Reloading application");
                
                try {
                    command("wheels reload").run();
                    Style.endProgress(local.reloadId, true);
                    Style.success("Application reloaded successfully at #timeFormat(now(), "HH:mm:ss")#");
                } catch (any e) {
                    Style.endProgress(local.reloadId, false);
                    Style.errorWithSolutions(
                        "Error reloading application: #e.message#",
                        [
                            "Check server logs for more information",
                            "Ensure the application server is running",
                            "Check for syntax errors in modified files"
                        ],
                        "https://wheels.dev/docs/troubleshooting"
                    );
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