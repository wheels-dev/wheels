/**
 * List available environments
 * Examples:
 * wheels env list
 * wheels env list --format=json
 * wheels env list --verbose
 * wheels env list --check --filter=production
 */
component extends="../base" {
    
    property name="environmentService" inject="EnvironmentService@wheels-cli";
    
    /**
     * @format.hint Output format: table (default), json, or yaml
     * @format.options table,json,yaml
     * @verbose.hint Show detailed configuration
     * @check.hint Validate environment configurations
     * @filter.hint Filter by environment type (All, local, development, staging, production, file, server.json, valid, issues)
     * @sort.hint Sort by (name, type, modified)
     * @help.hint Show help information
     */
    function run(
        string format = "table",
        boolean verbose = false,
        boolean check = false,
        string filter = "All",
        string sort = "name",
        boolean help = false
    ) {
        var projectRoot = resolvePath(".");
        arguments = reconstructArgs(arguments);
        arguments.rootPath = projectRoot;
        
        
        var result = environmentService.list(argumentCollection=arguments);
        
        // Handle different format outputs
        if (arguments.format == "json") {
            print.line(deserializeJSON(result));
        } else{
            print.line(result);
        }
    }
}