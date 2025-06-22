/**
 * CLI Interceptor for Wheels CLI
 * Handles command lifecycle events and cross-cutting concerns
 * 
 * @author CFWheels Team
 * @version 3.0.0
 */
component extends="coldbox.system.Interceptor" {
    
    // DI Properties
    property name="log" inject="logbox:logger:{this}";
    property name="configService" inject="ConfigService@wheelscli";
    property name="print" inject="PrintBuffer";
    
    /**
     * Configure the interceptor
     */
    function configure() {
        // Interceptor configuration
        variables.startTime = getTickCount();
        variables.commandStats = {};
    }
    
    /**
     * Pre-command execution
     */
    function preWheelsCommand(event, interceptData) {
        var command = arguments.interceptData.command ?: "unknown";
        var args = arguments.interceptData.args ?: {};
        
        // Start timing
        variables.commandStats[command] = {
            startTime = getTickCount(),
            args = args,
            user = systemSettings.getSystemSetting("USER", "unknown"),
            startMemory = getJVMMemoryUsage()
        };
        
        // Log command execution
        if (log.canDebug()) {
            log.debug("Executing command: #command#", args);
        }
        
        // Check for updates periodically
        checkForUpdates(command);
        
        // Validate environment
        validateEnvironment(command);
    }
    
    /**
     * Post-command execution
     */
    function postWheelsCommand(event, interceptData) {
        var command = arguments.interceptData.command ?: "unknown";
        var result = arguments.interceptData.result ?: {};
        var duration = arguments.interceptData.duration ?: 0;
        
        // Calculate metrics
        if (structKeyExists(variables.commandStats, command)) {
            var stats = variables.commandStats[command];
            stats.endTime = getTickCount();
            stats.duration = stats.endTime - stats.startTime;
            stats.endMemory = getJVMMemoryUsage();
            stats.memoryUsed = stats.endMemory - stats.startMemory;
            
            // Log metrics
            if (log.canInfo()) {
                log.info("Command completed: #command# (Duration: #stats.duration#ms, Memory: #formatBytes(stats.memoryUsed)#)");
            }
            
            // Record usage statistics
            recordUsageStats(command, stats);
            
            // Clean up
            structDelete(variables.commandStats, command);
        }
        
        // Show performance info in verbose mode
        if (getConfigService().get("verbose", false)) {
            getPrint().line();
            getPrint().greyLine("Command completed in #numberFormat(duration)#ms");
        }
    }
    
    /**
     * Command error handling
     */
    function onWheelsCommandError(event, interceptData) {
        var command = arguments.interceptData.command ?: "unknown";
        var error = arguments.interceptData.error ?: {};
        var args = arguments.interceptData.args ?: {};
        
        // Log error
        log.error("Command failed: #command#", {
            error = error,
            args = args,
            stackTrace = structKeyExists(error, "stackTrace") ? error.stackTrace : ""
        });
        
        // Record error statistics
        recordErrorStats(command, error);
        
        // Send error report if enabled
        if (getConfigService().get("errorReporting.enabled", false)) {
            sendErrorReport(command, error, args);
        }
        
        // Suggest solutions
        suggestErrorSolutions(error);
    }
    
    /**
     * Project detection event
     */
    function onWheelsProjectDetection(event, interceptData) {
        var projectInfo = arguments.interceptData ?: {};
        
        // Log project detection
        if (log.canDebug()) {
            log.debug("Project detected", projectInfo);
        }
        
        // Validate project structure
        if (projectInfo.isWheelsProject && arrayLen(projectInfo.errors ?: [])) {
            getPrint().line();
            getPrint().yellowBoldLine("⚠️  Project structure issues detected:");
            for (var error in projectInfo.errors) {
                getPrint().yellowLine("  - #error#");
            }
            getPrint().line();
        }
        
        // Check for legacy migration needs
        if (projectInfo.isLegacyProject ?: false) {
            getPrint().line();
            getPrint().yellowBoldLine("📦 Legacy Wheels project detected");
            getPrint().yellowLine("Consider upgrading to Wheels 3.0+ for better CLI support.");
            getPrint().yellowLine("Run 'wheels upgrade' for migration assistance.");
            getPrint().line();
        }
    }
    
    /**
     * Module load event
     */
    function afterConfigurationLoad(event, interceptData) {
        // Initialize services
        log.info("Wheels CLI Interceptor initialized");
        
        // Check first run
        if (isFirstRun()) {
            showWelcomeMessage();
        }
    }
    
    /**
     * Module unload event
     */
    function preModuleUnload(event, interceptData) {
        // Cleanup
        if (structCount(variables.commandStats)) {
            log.warn("Cleaning up #structCount(variables.commandStats)# incomplete command stats");
        }
    }
    
    // ========================================
    // Private Helper Methods
    // ========================================
    
    /**
     * Check for updates periodically
     */
    private function checkForUpdates(required string command) {
        // Skip for certain commands
        if (listFindNoCase("version,help,update", arguments.command)) {
            return;
        }
        
        var lastCheck = getConfigService().get("lastUpdateCheck", "");
        var checkInterval = getConfigService().get("updateCheckInterval", 86400); // 24 hours
        
        if (!isDate(lastCheck) || dateDiff("s", lastCheck, now()) > checkInterval) {
            // Perform async update check
            thread name="updateCheck#createUUID()#" action="run" {
                try {
                    var wheelsService = getWireBox().getInstance("WheelsService@wheelscli");
                    var updateInfo = wheelsService.checkForUpdates();
                    
                    if (updateInfo.updateAvailable) {
                        // Store for later display
                        getConfigService().set("pendingUpdate", updateInfo);
                    }
                    
                    // Update last check time
                    getConfigService().set("lastUpdateCheck", now());
                    getConfigService().save();
                } catch (any e) {
                    // Silently fail update checks
                    log.debug("Update check failed: #e.message#");
                }
            }
        }
        
        // Display pending update notification
        var pendingUpdate = getConfigService().get("pendingUpdate", {});
        if (structCount(pendingUpdate) && pendingUpdate.updateAvailable ?: false) {
            getPrint().line();
            getPrint().yellowLine("📦 Update available: Wheels CLI #pendingUpdate.latestVersion# (current: #pendingUpdate.currentVersion#)");
            getPrint().yellowLine("Run 'wheels update' to upgrade");
            getPrint().line();
            
            // Clear notification
            getConfigService().set("pendingUpdate", {});
        }
    }
    
    /**
     * Validate environment
     */
    private function validateEnvironment(required string command) {
        // Skip for certain commands
        if (listFindNoCase("create,init,help,version", listFirst(arguments.command, "."))) {
            return;
        }
        
        // Check Java version
        var javaVersion = server.java.version;
        if (val(listFirst(javaVersion, ".")) < 11) {
            log.warn("Java version #javaVersion# detected. Java 11+ is recommended.");
        }
        
        // Check available memory
        var memoryUsage = getJVMMemoryUsage();
        var freeMemory = server.java.free;
        
        if (freeMemory < 52428800) { // Less than 50MB free
            log.warn("Low memory warning: #formatBytes(freeMemory)# free");
        }
    }
    
    /**
     * Record usage statistics
     */
    private function recordUsageStats(required string command, required struct stats) {
        try {
            var usageFile = expandPath("~/.wheels/usage.json");
            var usage = {};
            
            // Load existing usage data
            if (fileExists(usageFile)) {
                usage = deserializeJSON(fileRead(usageFile));
            }
            
            // Initialize command stats
            if (!structKeyExists(usage, arguments.command)) {
                usage[arguments.command] = {
                    count = 0,
                    totalDuration = 0,
                    totalMemory = 0,
                    lastUsed = "",
                    errors = 0
                };
            }
            
            // Update stats
            usage[arguments.command].count++;
            usage[arguments.command].totalDuration += arguments.stats.duration;
            usage[arguments.command].totalMemory += arguments.stats.memoryUsed;
            usage[arguments.command].lastUsed = now();
            usage[arguments.command].avgDuration = usage[arguments.command].totalDuration / usage[arguments.command].count;
            usage[arguments.command].avgMemory = usage[arguments.command].totalMemory / usage[arguments.command].count;
            
            // Save updated stats
            var dir = getDirectoryFromPath(usageFile);
            if (!directoryExists(dir)) {
                directoryCreate(dir, true);
            }
            
            fileWrite(usageFile, serializeJSON(usage));
        } catch (any e) {
            // Don't fail commands due to stats collection errors
            log.debug("Failed to record usage stats: #e.message#");
        }
    }
    
    /**
     * Record error statistics
     */
    private function recordErrorStats(required string command, required struct error) {
        try {
            var errorFile = expandPath("~/.wheels/errors.log");
            var errorEntry = {
                timestamp = now(),
                command = arguments.command,
                error = arguments.error.message ?: "Unknown error",
                type = arguments.error.type ?: "Error",
                detail = arguments.error.detail ?: ""
            };
            
            var dir = getDirectoryFromPath(errorFile);
            if (!directoryExists(dir)) {
                directoryCreate(dir, true);
            }
            
            fileAppend(errorFile, serializeJSON(errorEntry) & chr(10));
        } catch (any e) {
            // Don't fail commands due to error logging
            log.debug("Failed to record error stats: #e.message#");
        }
    }
    
    /**
     * Send error report
     */
    private function sendErrorReport(
        required string command,
        required struct error,
        required struct args
    ) {
        // This would send error reports to a central service
        // For now, just log it
        log.info("Error report would be sent for command: #arguments.command#");
    }
    
    /**
     * Suggest error solutions
     */
    private function suggestErrorSolutions(required struct error) {
        var message = arguments.error.message ?: "";
        var suggestions = [];
        
        // Database connection errors
        if (findNoCase("datasource", message) || findNoCase("database", message)) {
            arrayAppend(suggestions, "Check your database configuration in server.json");
            arrayAppend(suggestions, "Ensure the database server is running");
            arrayAppend(suggestions, "Run 'wheels db create' to create the database");
        }
        
        // File not found errors
        if (findNoCase("file not found", message) || findNoCase("does not exist", message)) {
            arrayAppend(suggestions, "Ensure you're in a Wheels project directory");
            arrayAppend(suggestions, "Check file permissions");
            arrayAppend(suggestions, "Run 'wheels init' to initialize the project");
        }
        
        // Permission errors
        if (findNoCase("permission", message) || findNoCase("access denied", message)) {
            arrayAppend(suggestions, "Check file and directory permissions");
            arrayAppend(suggestions, "Try running with appropriate privileges");
        }
        
        // Display suggestions
        if (arrayLen(suggestions)) {
            getPrint().line();
            getPrint().yellowBoldLine("💡 Suggestions:");
            for (var suggestion in suggestions) {
                getPrint().yellowLine("  - #suggestion#");
            }
        }
    }
    
    /**
     * Check if this is the first run
     */
    private function isFirstRun() {
        var configFile = expandPath("~/.wheels/config.json");
        return !fileExists(configFile);
    }
    
    /**
     * Show welcome message for first run
     */
    private function showWelcomeMessage() {
        getPrint().line();
        getPrint().boldBlueLine("🎉 Welcome to Wheels CLI!");
        getPrint().line();
        getPrint().line("This appears to be your first time using Wheels CLI.");
        getPrint().line("Here are some commands to get you started:");
        getPrint().line();
        getPrint().yellowLine("  wheels create app myapp    - Create a new Wheels application");
        getPrint().yellowLine("  wheels help                - Show all available commands");
        getPrint().yellowLine("  wheels --version          - Show version information");
        getPrint().line();
        getPrint().greyLine("Configuration stored in: ~/.wheels/");
        getPrint().line();
        
        // Create config directory
        var configDir = expandPath("~/.wheels/");
        if (!directoryExists(configDir)) {
            directoryCreate(configDir, true);
        }
        
        // Create initial config
        getConfigService().createDefault(configDir & "config.json");
    }
    
    /**
     * Get JVM memory usage
     */
    private function getJVMMemoryUsage() {
        var runtime = createObject("java", "java.lang.Runtime").getRuntime();
        return runtime.totalMemory() - runtime.freeMemory();
    }
    
    /**
     * Format bytes to human readable
     */
    private function formatBytes(required numeric bytes) {
        var units = ["B", "KB", "MB", "GB"];
        var size = arguments.bytes;
        var unit = 1;
        
        while (size >= 1024 && unit < arrayLen(units)) {
            size = size / 1024;
            unit++;
        }
        
        return numberFormat(size, "0.00") & " " & units[unit];
    }
    
    /**
     * Get print helper
     */
    private function getPrint() {
        return variables.print;
    }
    
    /**
     * Get WireBox
     */
    private function getWireBox() {
        return variables.wirebox;
    }
}