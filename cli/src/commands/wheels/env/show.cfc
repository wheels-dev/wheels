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
        arguments = reconstructArgs(arguments);
        try {
            // Check if we're in a Wheels project
            if (!directoryExists(resolvePath("app"))) {
                error("This command must be run from a Wheels project root directory");
            }
            
            print.greenBoldLine("Environment Variables Viewer").line();
            
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
            
            if (structIsEmpty(envVars)) {
                print.yellowLine("No environment variables found in #arguments.file#");
                return;
            }
            
            // Handle specific key request
            if (len(arguments.key)) {
                if (!structKeyExists(envVars, arguments.key)) {
                    print.yellowLine("Environment variable '#arguments.key#' not found in #arguments.file#");
                    print.line();
                    print.line("Available keys:");
                    for (var availKey in structKeyArray(envVars).sort("text")) {
                        print.line("  - #availKey#");
                    }
                    return;
                }
                
                // Found the key
                var displayValue = envVars[arguments.key];
                if (findNoCase("password", arguments.key) || findNoCase("secret", arguments.key) || findNoCase("key", arguments.key)) {
                    displayValue = repeatString("*", min(len(displayValue), 8));
                }
                
                if (arguments.format == "json") {
                    print.line(serializeJSON({
                        key: arguments.key,
                        value: displayValue,
                        source: arguments.file
                    }, true));
                } else {
                    var rows = [
                        { "Variable" = arguments.key, "Value" = displayValue, "Source" = arguments.file }
                    ];
                    print.table(rows);
                }
                
                return; // stop here, don’t print all vars
            }
            
            // Show all environment variables
            if (arguments.format == "json") {
                // Mask sensitive values in JSON output
                var maskedVars = {};
                for (var envKey in envVars) {
                    maskedVars[envKey] = envVars[envKey];
                    if (findNoCase("password", envKey) || findNoCase("secret", envKey) || findNoCase("key", envKey)) {
                        maskedVars[envKey] = repeatString("*", min(len(envVars[envKey]), 8));
                    }
                }
                print.line(maskedVars);
            } else if (arguments.format == "table") {
                // Build rows for table
                var rows = [];
                for (var envKey in envVars) {
                    var displayValue = envVars[envKey];
                    if (findNoCase("password", envKey) || findNoCase("secret", envKey) || findNoCase("key", envKey)) {
                        displayValue = repeatString("*", min(len(displayValue), 8));
                    }
                    arrayAppend(rows, {
                        "Variable" = envKey,
                        "Value"    = displayValue,
                        "Source"   = arguments.file
                    });
                }
                
                print.boldYellowLine("Environment Variables from #arguments.file#:");
                print.line();
                print.table(rows);
                print.line();
                print.greyLine("Tip: Access these in your app with application.env['KEY_NAME']");
                print.greyLine("Or use them in config files: set(dataSourceName=application.env['DB_NAME'])");
                print.greyLine("Wheels automatically loads .env on application start");
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
}