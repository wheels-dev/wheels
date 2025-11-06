/**
 * List all configuration settings
 * 
 * {code:bash}
 * wheels config:list
 * wheels config:list --environment=production
 * wheels config:list --filter=dataSource
 * {code}
 */
component extends="../base" {

    /**
     * @environment Environment to display settings for (development, testing, production)
     * @filter Filter results by this string
     * @showSensitive Show sensitive information (passwords, keys, etc.)
     */
    function run(
        string environment="",
        string filter="",
        boolean showSensitive=false
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(arguments);
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Configuration Settings");
        print.line();
        
        // Create URL parameters
        local.urlParams = "&command=configList";
        
        if (len(trim(arguments.environment))) {
            local.urlParams &= "&environment=#arguments.environment#";
        }
        
        if (len(trim(arguments.filter))) {
            local.urlParams &= "&filter=#arguments.filter#";
        }
        
        if (arguments.showSensitive) {
            local.urlParams &= "&showSensitive=true";
        }
        
        // Send command to get configuration
        print.line("Retrieving configuration settings...");
        local.result = $sendToCliCommand(urlstring=local.urlParams);
        
        // Display results
        if (structKeyExists(local.result, "config") && isStruct(local.result.config)) {
            // Get environment
            local.env = len(trim(arguments.environment)) ? arguments.environment : local.result.environment;
            print.boldYellowLine("Environment: #local.env#");
            print.line();
            
            // Build and display table
            local.configTable = [];
            local.keys = structKeyArray(local.result.config);
            arraySort(local.keys, "textnocase");
            
            for (local.key in local.keys) {
                // Apply filter if specified
                if (len(trim(arguments.filter)) && !findNoCase(arguments.filter, local.key)) {
                    continue;
                }
                
                local.value = local.result.config[local.key];
                
                // Handle sensitive information
                if (!arguments.showSensitive && isSensitiveKey(local.key)) {
                    local.value = "********";
                }
                
                // Format value for display
                if (isSimpleValue(local.value)) {
                    local.formattedValue = local.value;
                } else {
                    local.formattedValue = serializeJSON(local.value);
                }
                
                arrayAppend(local.configTable, [local.key, local.formattedValue]);
            }
            
            // Print table
            print.table(local.configTable, ["Setting", "Value"]);
        } else {
            print.boldRedLine("No configuration settings found");
        }
        
        print.line();
    }
    
    /**
     * Check if a key contains sensitive information
     */
    private boolean function isSensitiveKey(required string key) {
        local.sensitivePatterns = ["password", "secret", "key", "token", "credential"];
        
        for (local.pattern in local.sensitivePatterns) {
            if (findNoCase(local.pattern, arguments.key)) {
                return true;
            }
        }
        
        return false;
    }
}