/**
 * Base Command for all Wheels CLI commands
 */
component excludeFromHelp="true" {
    
    // DI Properties
    property name="fileSystemUtil"    inject="FileSystem";
    property name="packageService"    inject="PackageService";
    property name="serverService"     inject="ServerService";
    property name="print"             inject="PrintBuffer";
    property name="shell"             inject="Shell";
    property name="formatter"         inject="Formatter";
    
    // Module Services
    property name="configService"     inject="ConfigService@wheels-cli-next";
    property name="projectService"    inject="ProjectService@wheels-cli-next";
    property name="snippetService"    inject="SnippetService@wheels-cli-next";
    property name="databaseService"   inject="DatabaseService@wheels-cli-next";
    property name="migrationService"  inject="MigrationService@wheels-cli-next";
    property name="formatterService"  inject="FormatterService@wheels-cli-next";
    
    /**
     * Get current working directory
     */
    function getCWD() {
        return shell.pwd();
    }
    
    /**
     * Ask user for input
     */
    function ask(required string message, string defaultResponse = "", string mask = "") {
        return shell.ask(argumentCollection = arguments);
    }
    
    /**
     * Confirm with user
     */
    function confirm(required string message) {
        return shell.confirm(arguments.message);
    }
    
    /**
     * Print error and exit
     */
    function error(required string message, string detail = "") {
        print.redBoldLine(arguments.message);
        if (len(arguments.detail)) {
            print.redLine(arguments.detail);
        }
        // Set error exit code
        shell.setExitCode(1);
    }
    
    /**
     * Check if we're in a Wheels project
     */
    function isWheelsProject(string directory = getCWD()) {
        return projectService.detectProject(arguments.directory).isWheelsProject;
    }
    
    /**
     * Check if we're in a legacy Wheels project
     */
    function isLegacyWheelsProject(string directory = getCWD()) {
        var projectInfo = projectService.detectProject(arguments.directory);
        return projectInfo.isLegacyProject ?: false;
    }
    
    /**
     * Get Wheels project information
     */
    function getWheelsInfo() {
        var projectInfo = projectService.detectProject(getCWD());
        return {
            version = projectInfo.version ?: "Unknown",
            name = projectInfo.name ?: "",
            author = "",
            homepage = "https://cfwheels.org"
        };
    }
    
    /**
     * Ensure command is run from Wheels project root
     */
    function ensureWheelsProject() {
        if (!isWheelsProject()) {
            error(
                "This command must be run from a Wheels project root directory.",
                "Run 'wheels create app <name>' to create a new Wheels project."
            );
        }
    }
    
    /**
     * Get Wheels version from the project
     */
    function getWheelsVersion() {
        var projectInfo = projectService.detectProject(getCWD());
        return projectInfo.version ?: "Unknown";
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
        print.line(repeatString("=", 60));
    }
    
    /**
     * Print success message
     */
    function printSuccess(required string message) {
        print.greenBoldLine("✅ #arguments.message#");
    }
    
    /**
     * Print error message
     */
    function printError(required string message) {
        print.redBoldLine("❌ #arguments.message#");
    }
    
    /**
     * Print warning message
     */
    function printWarning(required string message) {
        print.yellowBoldLine("⚠️  #arguments.message#");
    }
    
    /**
     * Print info message
     */
    function printInfo(required string message) {
        print.blueLine("ℹ️  #arguments.message#");
    }
    
    /**
     * Get snippet content
     */
    function getSnippet(required string type, string name = "default") {
        return snippetService.getSnippet(arguments.type, arguments.name);
    }
    
    /**
     * Render snippet with data
     */
    function renderSnippet(required string snippet, required struct data) {
        return snippetService.render(arguments.snippet, arguments.data);
    }
    
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
     * Pluralize a word
     */
    function pluralize(required string word) {
        return formatterService.pluralize(arguments.word);
    }
    
    /**
     * Singularize a word
     */
    function singularize(required string word) {
        return formatterService.singularize(arguments.word);
    }
    
    /**
     * Convert to camelCase
     */
    function camelCase(required string text) {
        return formatterService.camelCase(arguments.text);
    }
    
    /**
     * Convert to PascalCase
     */
    function pascalCase(required string text) {
        return formatterService.pascalCase(arguments.text);
    }
}