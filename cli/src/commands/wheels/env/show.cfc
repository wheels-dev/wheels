/**
 * Show environment variables from .env file
 * 
 * This command displays environment variables from the .env file in your project root.
 * Wheels automatically loads these into application.env when the application starts.
 * 
 * Examples:
 * {code:bash}
 * wheels env show
 * wheels env show --key=DB_HOST
 * wheels env show --format=json
 * wheels env show --file=.env.production
 * {code}
 */
component extends="../base" {
    
    // Inject DetailOutputService
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @key.hint Specific environment variable key to show
     * @format.hint Output format: table (default) or json
     * @format.options table,json
     * @file.hint Specific .env file to read (default: .env)
     */
    function run(
        string key = "",
        string format = "table",
        string file = ".env"
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                format: ["table", "json", "list"]
            }
        );
        try {
            // Check if we're in a Wheels project
            if (!directoryExists(resolvePath("app"))) {
                detailOutput.error("This command must be run from a Wheels project root directory");
            }
            
            detailOutput.header("Environment Variables Viewer");
            
            // Read the .env file
            var envFile = resolvePath(arguments.file);
            if (!fileExists(envFile)) {
                detailOutput.statusWarning("No #arguments.file# file found in project root");
                detailOutput.line();
                detailOutput.subHeader("Create a .env file with key=value pairs, for example:");
                detailOutput.line();
                
                // Create example rows for table
                var exampleRows = [
                    { "Variable" = "## Database Configuration", "Value" = "", "Source" = "" },
                    { "Variable" = "DB_HOST", "Value" = "localhost", "Source" = ".env.example" },
                    { "Variable" = "DB_PORT", "Value" = "3306", "Source" = ".env.example" },
                    { "Variable" = "DB_NAME", "Value" = "myapp", "Source" = ".env.example" },
                    { "Variable" = "DB_USER", "Value" = "wheels", "Source" = ".env.example" },
                    { "Variable" = "DB_PASSWORD", "Value" = "secret", "Source" = ".env.example" },
                    { "Variable" = "## Application Settings", "Value" = "", "Source" = "" },
                    { "Variable" = "WHEELS_ENV", "Value" = "development", "Source" = ".env.example" },
                    { "Variable" = "WHEELS_RELOAD_PASSWORD", "Value" = "mypassword", "Source" = ".env.example" }
                ];
                
                print.table(exampleRows);
                detailOutput.line();
                detailOutput.statusInfo("Use 'wheels env set KEY=VALUE' to create environment variables");
                return;
            }
            
            // Parse the .env file
            var envVars = parseEnvFile(envFile);
            
            if (structIsEmpty(envVars)) {
                detailOutput.statusWarning("No environment variables found in #arguments.file#");
                return;
            }
            
            // Handle specific key request
            if (len(arguments.key)) {
                if (!structKeyExists(envVars, arguments.key)) {
                    detailOutput.statusWarning("Environment variable '#arguments.key#' not found in #arguments.file#");
                    
                    // Show available keys in a table
                    var availableRows = [];
                    for (var availKey in structKeyArray(envVars).sort("text")) {
                        arrayAppend(availableRows, {
                            "Available Variables" = availKey,
                            "Current Value" = maskSensitiveValue(availKey, envVars[availKey])
                        });
                    }
                    
                    if (arrayLen(availableRows)) {
                        detailOutput.line();
                        detailOutput.subHeader("Available Variables in #arguments.file#");
                        print.table(availableRows);
                    }
                    return;
                }
                
                // Found the key
                var displayValue = maskSensitiveValue(arguments.key, envVars[arguments.key]);
                
                if (arguments.format == "json") {
                    local.jsonData = serializeJSON({
                        Variable: arguments.key, 
                        Value: displayValue, 
                        Source: arguments.file
                    }, true);
                    detailOutput.code(deserializeJSON(local.jsonData), "json");
                } else {
                    var rows = [
                        { "Variable" = arguments.key, "Value" = displayValue, "Source" = arguments.file }
                    ];
                    detailOutput.subHeader("Environment Variable Details");
                    print.table(rows);
                    
                    // Add usage info
                    detailOutput.line();
                    detailOutput.statusInfo("Usage:");
                    detailOutput.output("- Access in app: application.env['#arguments.key#']", true);
                    detailOutput.output("- Use in config: set(value=application.env['#arguments.key#'])", true);
                }
                
                return; // stop here, don't print all vars
            }
            
            // Show all environment variables
            if (arguments.format == "json") {
                // Mask sensitive values in JSON output
                var maskedVars = {};
                for (var envKey in envVars) {
                    maskedVars[envKey] = maskSensitiveValue(envKey, envVars[envKey]);
                }
                detailOutput.code(serializeJSON(maskedVars, true), "json");
            } else if (arguments.format == "table") {
                // Build rows for table
                var rows = [];

                for (var envKey in envVars) {
                    var displayValue = maskSensitiveValue(envKey, envVars[envKey]);

                    var row = structNew("ordered");
                    row["Variable"] = envKey;
                    row["Value"]    = displayValue;
                    row["Source"]   = arguments.file;

                    arrayAppend(rows, row);
                }

                // Sort rows by Variable name
                rows.sort(function(a, b) {
                    return compareNoCase(a.Variable, b.Variable);
                });
                
                detailOutput.subHeader("Environment Variables from #arguments.file#");
                detailOutput.getPrint().table(rows);
                detailOutput.line();
                
                // Show summary and tips
                var sensitiveCount = 0;
                for (var envKey in envVars) {
                    if (isSensitiveKey(envKey)) {
                        sensitiveCount++;
                    }
                }
                
                detailOutput.metric("Total variables", "#structCount(envVars)#");
                if (sensitiveCount > 0) {
                    detailOutput.metric("Sensitive variables", "#sensitiveCount# (masked)");
                }
                detailOutput.line();
                detailOutput.statusInfo("Usage tips:");
                detailOutput.output("- Access in app: application.env['VARIABLE_NAME']", true);
                detailOutput.output("- Use in config: set(value=application.env['VARIABLE_NAME'])", true);
                detailOutput.output("- Wheels loads .env automatically on app start", true);
                detailOutput.output("- Update: wheels env set KEY=VALUE", true);
                
            } else if (arguments.format == "list") {
                detailOutput.subHeader("Environment Variables from #arguments.file#");
                for (var envKey in envVars) {
                    var displayValue = maskSensitiveValue(envKey, envVars[envKey]);
                    detailOutput.output("#envKey#=#displayValue#");
                }
            }
            
        } catch (any e) {
            detailOutput.error("Error showing environment variables: #e.message#");
        }
    }
    
    /**
     * Parse a .env file into a struct
     */
    private function parseEnvFile(required string filePath) {
        var envVars = {};
        var fileContent = fileRead(arguments.filePath);
        
        // Check if it's JSON format
        if (isJSON(fileContent)) {
            return deserializeJSON(fileContent);
        }
        
        // Parse as properties file format
        var lines = listToArray(fileContent, chr(10) & chr(13));
        
        for (var line in lines) {
            line = trim(line);
            
            // Skip empty lines and comments
            if (!len(line) || left(line, 1) == "##") {
                continue;
            }
            
            // Parse key=value pairs
            var equalsPos = find("=", line);
            if (equalsPos > 0) {
                var key = trim(left(line, equalsPos - 1));
                var value = trim(mid(line, equalsPos + 1, len(line)));
                
                // Remove surrounding quotes if present
                if (len(value) >= 2) {
                    if ((left(value, 1) == '"' && right(value, 1) == '"') ||
                        (left(value, 1) == "'" && right(value, 1) == "'")) {
                        value = mid(value, 2, len(value) - 2);
                    }
                }
                
                envVars[key] = value;
            }
        }
        
        return envVars;
    }
    
    /**
     * Mask sensitive values
     */
    private function maskSensitiveValue(required string key, required string value) {
        if (isSensitiveKey(arguments.key)) {
            return repeatString("*", min(len(arguments.value), 8));
        }
        return arguments.value;
    }
    
    /**
     * Check if a key is sensitive
     */
    private function isSensitiveKey(required string key) {
        return (
            findNoCase("password", arguments.key) || 
            findNoCase("secret", arguments.key)   || 
            findNoCase("key", arguments.key)      || 
            findNoCase("token", arguments.key)    ||
            findNoCase("auth", arguments.key)     ||
            findNoCase("credential", arguments.key)
        );
    }
}