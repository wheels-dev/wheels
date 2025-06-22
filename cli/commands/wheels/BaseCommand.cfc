/**
 * Base Command for all Wheels CLI commands
 * Provides common functionality, utilities, and helpers
 * 
 * @author CFWheels Team
 * @version 3.0.0
 */
component extends="commandbox.system.BaseCommand" accessors="true" {
    
    // DI Properties
    property name="fileSystemUtil"    inject="FileSystem";
    property name="packageService"    inject="PackageService";
    property name="progressBarHelper" inject="ProgressBarHelper";
    property name="progressBar"       inject="ProgressBar";
    property name="system"           inject="System@constants";
    property name="cr"               inject="cr@constants";
    property name="formatterUtil"    inject="Formatter";
    
    // Module Services
    property name="configService"     inject="ConfigService@wheelscli";
    property name="projectService"    inject="ProjectService@wheelscli";
    property name="templateService"   inject="TemplateService@wheelscli";
    property name="formatterService"  inject="FormatterService@wheelscli";
    property name="tabCompletionService" inject="TabCompletionService@wheelscli";
    
    // Command metadata
    property name="commandMetadata" type="struct";
    
    /**
     * Constructor
     */
    function init() {
        super.init();
        variables.commandMetadata = {
            startTime = getTickCount(),
            environment = "",
            outputFormat = "text"
        };
        return this;
    }
    
    /**
     * Run wrapper for all commands - handles common pre/post processing
     */
    function runCommand(required function commandFunction, struct args = {}) {
        try {
            // Pre-command interceptor
            announce("preWheelsCommand", {command = getCommandPath(), args = arguments.args});
            
            // Parse global flags
            parseGlobalFlags(argumentCollection = arguments.args);
            
            // Load configuration
            getConfigService().loadConfiguration();
            
            // Detect project
            detectProject();
            
            // Execute command
            var result = arguments.commandFunction(argumentCollection = arguments.args);
            
            // Post-command interceptor
            announce("postWheelsCommand", {
                command = getCommandPath(),
                args = arguments.args,
                result = result ?: {},
                duration = getTickCount() - variables.commandMetadata.startTime
            });
            
            return result;
            
        } catch (any e) {
            // Error interceptor
            announce("onWheelsCommandError", {
                command = getCommandPath(),
                args = arguments.args,
                error = e
            });
            
            // Re-throw with better formatting
            handleError(e);
        }
    }
    
    /**
     * Parse global command flags
     */
    private function parseGlobalFlags(
        string format = "",
        boolean quiet = false,
        boolean verbose = false,
        boolean noColor = false
    ) {
        // Output format
        if (len(arguments.format) && listFindNoCase("text,json,xml,table", arguments.format)) {
            variables.commandMetadata.outputFormat = arguments.format;
        }
        
        // Quiet mode
        if (arguments.quiet) {
            setQuietMode(true);
        }
        
        // Verbose mode
        if (arguments.verbose || getConfigService().get("defaults.verbose", false)) {
            setVerbose(true);
        }
        
        // Color output
        if (arguments.noColor) {
            shell.setUseColor(false);
        }
    }
    
    /**
     * Project detection and validation
     */
    private function detectProject() {
        variables.commandMetadata.projectInfo = getProjectService().detectProject(getCWD());
        
        // Announce detection results
        announce("onWheelsProjectDetection", variables.commandMetadata.projectInfo);
    }
    
    /**
     * Check if we're in a Wheels project
     */
    function isWheelsProject() {
        return variables.commandMetadata.projectInfo.isWheelsProject ?: false;
    }
    
    /**
     * Check if we're in a legacy Wheels project
     */
    function isLegacyWheelsProject() {
        return variables.commandMetadata.projectInfo.isLegacyProject ?: false;
    }
    
    /**
     * Ensure command is run from Wheels project root
     */
    function ensureWheelsProject() {
        if (!isWheelsProject()) {
            if (isLegacyWheelsProject()) {
                error(
                    "This appears to be a legacy Wheels project (pre-3.0). Please upgrade to Wheels 3.0+ to use this CLI.",
                    "Use 'wheels upgrade' to upgrade your project structure."
                );
            } else {
                error(
                    "This command must be run from a Wheels project root directory.",
                    "Run 'wheels create app <name>' to create a new Wheels project."
                );
            }
        }
    }
    
    /**
     * Get Wheels version from the project
     */
    function getWheelsVersion() {
        return variables.commandMetadata.projectInfo.version ?: "Unknown";
    }
    
    // ========================================
    // Output Utilities
    // ========================================
    
    /**
     * Print formatted output based on output format
     */
    function output(required any data, string format = "") {
        var outputFormat = len(arguments.format) ? arguments.format : variables.commandMetadata.outputFormat;
        
        switch(outputFormat) {
            case "json":
                print.line(serializeJSON(arguments.data));
                break;
            case "xml":
                print.line(toXML(arguments.data));
                break;
            case "table":
                if (isQuery(arguments.data) || isArray(arguments.data)) {
                    print.table(arguments.data);
                } else {
                    print.line(arguments.data);
                }
                break;
            default:
                if (isSimpleValue(arguments.data)) {
                    print.line(arguments.data);
                } else {
                    print.line(serializeJSON(arguments.data));
                }
        }
    }
    
    /**
     * Print a formatted header
     */
    function printHeader(required string title, string subtitle = "") {
        print.line();
        print.boldBlueLine(arguments.title);
        if (len(arguments.subtitle)) {
            print.greyLine(arguments.subtitle);
        }
        print.line("=" repeatString 60);
    }
    
    /**
     * Print a formatted section
     */
    function printSection(required string title) {
        print.line();
        print.yellowLine(arguments.title);
        print.line("-" repeatString len(arguments.title));
    }
    
    /**
     * Print success message with icon
     */
    function printSuccess(required string message) {
        print.greenBoldLine("✅ #arguments.message#");
    }
    
    /**
     * Print error message with icon
     */
    function printError(required string message) {
        print.redBoldLine("❌ #arguments.message#");
    }
    
    /**
     * Print warning message with icon
     */
    function printWarning(required string message) {
        print.yellowBoldLine("⚠️  #arguments.message#");
    }
    
    /**
     * Print info message with icon
     */
    function printInfo(required string message) {
        print.blueLine("ℹ️  #arguments.message#");
    }
    
    // ========================================
    // Progress Indicators
    // ========================================
    
    /**
     * Start a progress bar
     */
    function startProgress(
        required string message,
        numeric total = 0,
        boolean showCount = true
    ) {
        if (variables.commandMetadata.outputFormat != "text") {
            return;
        }
        
        print.line().toConsole();
        
        variables.activeProgressBar = getProgressBarHelper().create(
            total = arguments.total,
            label = arguments.message,
            showCount = arguments.showCount
        );
    }
    
    /**
     * Update progress bar
     */
    function updateProgress(numeric increment = 1, string message = "") {
        if (!structKeyExists(variables, "activeProgressBar")) {
            return;
        }
        
        if (len(arguments.message)) {
            variables.activeProgressBar.update(
                increment = arguments.increment,
                label = arguments.message
            );
        } else {
            variables.activeProgressBar.update(increment = arguments.increment);
        }
    }
    
    /**
     * Complete progress bar
     */
    function completeProgress() {
        if (structKeyExists(variables, "activeProgressBar")) {
            variables.activeProgressBar.clear();
            structDelete(variables, "activeProgressBar");
        }
    }
    
    /**
     * Run a task with spinner
     */
    function runWithSpinner(required string message, required function task) {
        if (variables.commandMetadata.outputFormat != "text") {
            return arguments.task();
        }
        
        var spinner = getProgressBarHelper().spinner(
            label = arguments.message
        );
        
        try {
            var result = arguments.task();
            spinner.complete();
            return result;
        } catch (any e) {
            spinner.error();
            rethrow;
        }
    }
    
    // ========================================
    // Interactive Utilities
    // ========================================
    
    /**
     * Enhanced confirmation prompt
     */
    function confirm(required string message, boolean defaultValue = false) {
        if (getQuietMode()) {
            return arguments.defaultValue;
        }
        
        var defaultText = arguments.defaultValue ? "Y/n" : "y/N";
        var response = ask("#arguments.message# [#defaultText#]: ");
        
        if (!len(trim(response))) {
            return arguments.defaultValue;
        }
        
        return listFindNoCase("y,yes,true,1", trim(response)) > 0;
    }
    
    /**
     * Multiple choice prompt
     */
    function choose(required string message, required array options, numeric defaultOption = 1) {
        print.line(arguments.message);
        
        for (var i = 1; i <= arrayLen(arguments.options); i++) {
            var prefix = i == arguments.defaultOption ? ">" : " ";
            print.line("#prefix# #i#) #arguments.options[i]#");
        }
        
        var choice = ask("Select option [#arguments.defaultOption#]: ");
        
        if (!len(trim(choice))) {
            return arguments.options[arguments.defaultOption];
        }
        
        var index = val(choice);
        if (index >= 1 && index <= arrayLen(arguments.options)) {
            return arguments.options[index];
        }
        
        return arguments.options[arguments.defaultOption];
    }
    
    // ========================================
    // Table Formatting
    // ========================================
    
    /**
     * Print a formatted table
     */
    function printTable(
        required array data,
        array headers = [],
        array columns = [],
        boolean border = true
    ) {
        getFormatterService().printTable(argumentCollection = arguments);
    }
    
    // ========================================
    // Template Utilities
    // ========================================
    
    /**
     * Render template with data
     */
    function renderTemplate(required string template, required struct data) {
        return getTemplateService().render(arguments.template, arguments.data);
    }
    
    /**
     * Get template content
     */
    function getTemplate(required string type, string name = "default") {
        return getTemplateService().getTemplate(arguments.type, arguments.name);
    }
    
    /**
     * Check if using custom template
     */
    function isUsingCustomTemplate(required string path) {
        return getTemplateService().isCustomTemplate(arguments.path);
    }
    
    // ========================================
    // Path Utilities
    // ========================================
    
    /**
     * Get app directory path
     */
    function getAppPath(string type = "") {
        var basePath = getCWD() & "/app";
        return len(arguments.type) ? basePath & "/" & arguments.type : basePath;
    }
    
    /**
     * Get config directory path
     */
    function getConfigPath(string type = "") {
        var basePath = getCWD() & "/config";
        return len(arguments.type) ? basePath & "/" & arguments.type : basePath;
    }
    
    /**
     * Get database directory path
     */
    function getDbPath(string type = "") {
        var basePath = getCWD() & "/db";
        return len(arguments.type) ? basePath & "/" & arguments.type : basePath;
    }
    
    /**
     * Get vendor directory path
     */
    function getVendorPath() {
        return getCWD() & "/vendor";
    }
    
    /**
     * Get Wheels framework path
     */
    function getWheelsPath() {
        return getVendorPath() & "/wheels";
    }
    
    // ========================================
    // String Utilities
    // ========================================
    
    /**
     * Enhanced pluralization
     */
    function pluralize(required string word) {
        return getFormatterService().pluralize(arguments.word);
    }
    
    /**
     * Enhanced singularization
     */
    function singularize(required string word) {
        return getFormatterService().singularize(arguments.word);
    }
    
    /**
     * Convert to camelCase
     */
    function camelCase(required string text) {
        return getFormatterService().camelCase(arguments.text);
    }
    
    /**
     * Convert to PascalCase
     */
    function pascalCase(required string text) {
        return getFormatterService().pascalCase(arguments.text);
    }
    
    /**
     * Convert to snake_case
     */
    function snakeCase(required string text) {
        return getFormatterService().snakeCase(arguments.text);
    }
    
    /**
     * Convert to kebab-case
     */
    function kebabCase(required string text) {
        return getFormatterService().kebabCase(arguments.text);
    }
    
    // ========================================
    // Error Handling
    // ========================================
    
    /**
     * Enhanced error handling
     */
    function handleError(required any exception) {
        var e = arguments.exception;
        
        // Format error based on output format
        if (variables.commandMetadata.outputFormat == "json") {
            print.line(serializeJSON({
                error = true,
                message = e.message,
                detail = e.detail ?: "",
                type = e.type ?: "Error"
            }));
            setExitCode(1);
            return;
        }
        
        // Text output
        print.line();
        printError(e.message);
        
        if (structKeyExists(e, "detail") && len(e.detail)) {
            print.line();
            print.indentedLine(e.detail);
        }
        
        if (getVerbose()) {
            print.line();
            print.greyLine("Stack Trace:");
            print.greyLine(e.stacktrace);
        }
        
        setExitCode(1);
    }
    
    /**
     * Enhanced error method
     */
    function error(required string message, string detail = "", numeric exitCode = 1) {
        var exception = {
            message = arguments.message,
            detail = arguments.detail,
            type = "WheelsCommandError"
        };
        
        handleError(exception);
        setExitCode(arguments.exitCode);
        
        // Throw to stop execution
        throw(
            type = "WheelsCommandError",
            message = arguments.message,
            detail = arguments.detail
        );
    }
    
    // ========================================
    // Private Utilities
    // ========================================
    
    /**
     * Get command path for logging
     */
    private function getCommandPath() {
        var metadata = getMetadata(this);
        return listLast(metadata.name, ".");
    }
    
    /**
     * Convert data to XML
     */
    private function toXML(required any data) {
        // Simple XML conversion - could be enhanced
        return "<result>" & serializeJSON(arguments.data) & "</result>";
    }
    
    /**
     * Set quiet mode
     */
    private function setQuietMode(required boolean quiet) {
        variables.commandMetadata.quiet = arguments.quiet;
    }
    
    /**
     * Get quiet mode
     */
    private function getQuietMode() {
        return variables.commandMetadata.quiet ?: false;
    }
    
    /**
     * Set verbose mode
     */
    private function setVerbose(required boolean verbose) {
        variables.commandMetadata.verbose = arguments.verbose;
    }
    
    /**
     * Get verbose mode
     */
    private function getVerbose() {
        return variables.commandMetadata.verbose ?: false;
    }
    
    // ========================================
    // Tab Completion Helpers
    // ========================================
    
    /**
     * Complete model names
     */
    function completeModelNames(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getModelNames(arguments.paramSoFar, arguments.passedNamedParameters);
    }
    
    /**
     * Complete controller names
     */
    function completeControllerNames(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getControllerNames(arguments.paramSoFar, arguments.passedNamedParameters);
    }
    
    /**
     * Complete migration names
     */
    function completeMigrationNames(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getMigrationNames(arguments.paramSoFar, arguments.passedNamedParameters);
    }
    
    /**
     * Complete migration versions
     */
    function completeMigrationVersions(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getMigrationVersions(arguments.paramSoFar, arguments.passedNamedParameters);
    }
    
    /**
     * Complete environment names
     */
    function completeEnvironments(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getEnvironments(arguments.paramSoFar, arguments.passedNamedParameters);
    }
    
    /**
     * Complete database types
     */
    function completeDatabaseTypes(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getDatabaseTypes(arguments.paramSoFar, arguments.passedNamedParameters);
    }
    
    /**
     * Complete template names
     */
    function completeTemplateNames(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getTemplateNames(arguments.paramSoFar, arguments.passedNamedParameters);
    }
    
    /**
     * Complete template types
     */
    function completeTemplateTypes(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getTemplateTypes(arguments.paramSoFar, arguments.passedNamedParameters);
    }
    
    /**
     * Complete test types
     */
    function completeTestTypes(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getTestTypes(arguments.paramSoFar, arguments.passedNamedParameters);
    }
    
    /**
     * Complete property types
     */
    function completePropertyTypes(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getPropertyTypes(arguments.paramSoFar, arguments.passedNamedParameters);
    }
    
    /**
     * Complete action names
     */
    function completeActionNames(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getActionNames(arguments.paramSoFar, arguments.passedNamedParameters);
    }
    
    /**
     * Complete format types
     */
    function completeFormatTypes(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getFormatTypes(arguments.paramSoFar, arguments.passedNamedParameters);
    }
    
    /**
     * Get tab completion service
     */
    private function getTabCompletionService() {
        return variables.tabCompletionService;
    }
}