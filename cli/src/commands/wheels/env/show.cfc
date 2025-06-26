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
        try {
            // Check if we're in a Wheels project
            if (!directoryExists(resolvePath("app"))) {
                return error("This command must be run from a Wheels project root directory");
            }
            
            print.greenBoldLine("🔧 Environment Variables Viewer")
                 .line();
            
            // Read the .env file
            var envFile = resolvePath(arguments.file);
            if (!fileExists(envFile)) {
                print.yellowLine("No #arguments.file# file found in project root");
                print.line();
                print.line("Create a .env file with key=value pairs, for example:");
                print.line();
                print.cyanLine("## Database Configuration");
                print.cyanLine("DB_HOST=localhost");
                print.cyanLine("DB_PORT=3306");
                print.cyanLine("DB_NAME=myapp");
                print.cyanLine("DB_USER=wheels");
                print.cyanLine("DB_PASSWORD=secret");
                print.line();
                print.cyanLine("## Application Settings");
                print.cyanLine("WHEELS_ENV=development");
                print.cyanLine("WHEELS_RELOAD_PASSWORD=mypassword");
                return;
            }
            
            // Parse the .env file
            var envVars = parseEnvFile(envFile);
            
            // Handle specific key request
            if (len(arguments.key)) {
                if (structKeyExists(envVars, arguments.key)) {
                    if (arguments.format == "json") {
                        print.line(serializeJSON({
                            key: arguments.key,
                            value: envVars[arguments.key],
                            source: arguments.file
                        }, true));
                    } else {
                        print.boldYellowLine("Environment Variable: #arguments.key#");
                        var displayValue = envVars[arguments.key];
                        if (findNoCase("password", arguments.key) || findNoCase("secret", arguments.key) || findNoCase("key", arguments.key)) {
                            displayValue = repeatString("*", min(len(displayValue), 8));
                        }
                        print.line("Value: #displayValue#");
                        print.line("Source: #arguments.file#");
                    }
                } else {
                    print.yellowLine("Environment variable '#arguments.key#' not found");
                    print.line();
                    if (structCount(envVars)) {
                        print.line("Available keys in #arguments.file#:");
                        for (var availKey in structKeyArray(envVars).sort("text")) {
                            print.line("  - #availKey#");
                        }
                    }
                }
                return;
            }
            
            // Show all environment variables
            if (structIsEmpty(envVars)) {
                print.yellowLine("No environment variables found in #arguments.file#");
                return;
            }
            
            if (arguments.format == "json") {
                // Mask sensitive values in JSON output
                var maskedVars = {};
                for (var envKey in envVars) {
                    maskedVars[envKey] = envVars[envKey];
                    if (findNoCase("password", envKey) || findNoCase("secret", envKey) || findNoCase("key", envKey)) {
                        maskedVars[envKey] = repeatString("*", min(len(envVars[envKey]), 8));
                    }
                }
                print.line(serializeJSON(maskedVars, true));
            } else {
                print.boldYellowLine("Environment Variables from #arguments.file#:");
                print.line();
                
                // Group variables by prefix
                var grouped = {};
                var ungrouped = [];
                
                for (var envKey in envVars) {
                    var prefix = listFirst(envKey, "_");
                    if (listLen(envKey, "_") > 1 && len(prefix) <= 10) {
                        if (!structKeyExists(grouped, prefix)) {
                            grouped[prefix] = [];
                        }
                        arrayAppend(grouped[prefix], {
                            key: envKey,
                            value: envVars[envKey]
                        });
                    } else {
                        arrayAppend(ungrouped, {
                            key: envKey,
                            value: envVars[envKey]
                        });
                    }
                }
                
                // Display grouped variables
                for (var group in structKeyArray(grouped).sort("text")) {
                    print.boldLine("#group#_* Variables:");
                    for (var item in grouped[group]) {
                        // Mask sensitive values
                        var displayValue = item.value;
                        if (findNoCase("password", item.key) || findNoCase("secret", item.key) || findNoCase("key", item.key)) {
                            displayValue = repeatString("*", min(len(item.value), 8));
                        }
                        print.line("  #item.key# = #displayValue#");
                    }
                    print.line();
                }
                
                // Display ungrouped variables
                if (arrayLen(ungrouped)) {
                    print.boldLine("Other Variables:");
                    for (var item in ungrouped) {
                        var displayValue = item.value;
                        if (findNoCase("password", item.key) || findNoCase("secret", item.key) || findNoCase("key", item.key)) {
                            displayValue = repeatString("*", min(len(item.value), 8));
                        }
                        print.line("  #item.key# = #displayValue#");
                    }
                    print.line();
                }
                
                print.line();
                print.greyLine("💡 Tip: Access these in your app with application.env['KEY_NAME']");
                print.greyLine("💡 Or use them in config files: set(dataSourceName=application.env['DB_NAME'])");
                print.greyLine("💡 Wheels automatically loads .env on application start");
            }
            
        } catch (any e) {
            error("Error showing environment variables: #e.message#");
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
     * Resolve a file path
     */
    private function resolvePath(path) {
        if (left(arguments.path, 1) == "/" || mid(arguments.path, 2, 1) == ":") {
            return arguments.path;
        }
        return expandPath(arguments.path);
    }
}