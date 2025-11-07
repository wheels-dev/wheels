/**
 * Set configuration values
 * 
 * {code:bash}
 * wheels config:set dataSourceName=myDB
 * wheels config:set reloadPassword=newPassword --environment=production
 * {code}
 */
component extends="../base" {

    /**
     * @setting Key=Value pair for the setting to update
     * @environment Environment to apply settings to (development, testing, production, all)
     * @encrypt Encrypt sensitive values
     */
    function run(
        required string setting,
        string environment="development",
        boolean encrypt=false
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(arguments);
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Configuration Manager");
        print.line();
        
        // Parse the key-value pair
        if (!find("=", arguments.setting)) {
            error("Setting must be in the format key=value");
        }
        
        local.key = trim(listFirst(arguments.setting, "="));
        local.value = trim(listRest(arguments.setting, "="));
        
        // Check if we need to encrypt the value
        if (arguments.encrypt || isSensitiveKey(local.key)) {
            if (!arguments.encrypt && isSensitiveKey(local.key)) {
                print.yellowLine("Note: The setting '#local.key#' appears to contain sensitive information.");
                if (confirm("Would you like to encrypt this value? [y/n]")) {
                    arguments.encrypt = true;
                }
            }
            
            if (arguments.encrypt) {
                print.yellowLine("Encrypting value for '#local.key#'...");
                // Note: The actual encryption would happen in the controller
                local.value = "encrypted:" & local.value;
            }
        }
        
        // Create URL parameters
        local.urlParams = "&command=configSet&key=#urlEncodedFormat(local.key)#&value=#urlEncodedFormat(local.value)#&environment=#arguments.environment#";
        
        if (arguments.encrypt) {
            local.urlParams &= "&encrypt=true";
        }
        
        // Send command to set configuration
        print.line("Setting configuration value...");
        local.result = $sendToCliCommand(urlstring=local.urlParams);
        
        // Display results
        if (structKeyExists(local.result, "success") && local.result.success) {
            print.boldGreenLine("Configuration value set successfully");
            print.yellowLine("Environment: #arguments.environment#");
            print.yellowLine("Key: #local.key#");
            
            // Don't show the actual value for sensitive information
            if (isSensitiveKey(local.key) && !arguments.encrypt) {
                print.yellowLine("Value: ********");
            } else {
                print.yellowLine("Value: #local.value#");
            }
            
            if (arguments.encrypt) {
                print.yellowLine("Encryption: Enabled");
            }
        } else {
            print.boldRedLine("Failed to set configuration value");
            if (structKeyExists(local.result, "message")) {
                print.redLine(local.result.message);
            }
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