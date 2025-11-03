component extends="commandbox.system.BaseCommand" {

    property name="configService" inject="ConfigService";
    
    /**
     * Check if current directory is a Wheels project
     */
    function isWheelsProject() {
        return fileExists(resolvePath("box.json")) && 
               (fileExists(resolvePath("Application.cfc")) || 
                fileExists(resolvePath("Application.cfm")));
    }
    
    /**
     * Get Wheels version from box.json
     */
    function getWheelsVersion() {
        var boxPath = resolvePath("box.json");
        if (fileExists(boxPath)) {
            var boxData = deserializeJSON(fileRead(boxPath));
            return boxData.dependencies.keyExists("wheels") ? 
                   boxData.dependencies.wheels : "unknown";
        }
        return "unknown";
    }
    
    /**
     * Display file generation summary
     */
    function displayGenerationSummary(files, options) {
        print.line()
             .greenBoldLine("🎉 Generated #files.len()# files:")
             .line();
        
        files.each(function(file) {
            print.greenLine("  ✓ #file#");
        });
        
        print.line()
             .yellowLine("Next steps:")
             .line("1. Review generated files")
             .line("2. Run tests: wheels test run")
             .line("3. Start server: server start");
    }
    
    /**
     * Run a command and return output
     */
    function runCommand(required string cmd) {
        return command(arguments.cmd).run(returnOutput = true);
    }
    
    /**
     * Open a file path in the default editor
     */
    function openPath(required string path) {
        if (shell.isWindows()) {
            runCommand("start #arguments.path#");
        } else if (shell.isMac()) {
            runCommand("open #arguments.path#");
        } else {
            runCommand("xdg-open #arguments.path#");
        }
    }
    
    /**
     * Check for migration changes in file list
     */
    function hasMigrationChanges(required array changes) {
        return changes.some(function(change) {
            return change.path contains "migrations" || 
                   change.path contains "db/schema";
        });
    }
    
    /**
     * Reload the Wheels framework
     */
    function reloadFramework() {
        var serverInfo = getServerInfo();
        var reloadURL = serverInfo.serverURL & "/?reload=true";
        
        http url=reloadURL timeout=5;
        print.greenLine("✅ Framework reloaded");
    }
    
    /**
     * Get current server information
     */
    function getServerInfo() {
        var serverService = getInstance("ServerService@commandbox-core");
        var serverDetails = serverService.resolveServerDetails(
            serverProps = { webroot = getCWD() }
        );

        return {
            host = serverDetails.serverInfo.host,
            port = serverDetails.serverInfo.port,
            serverURL = "http://" & serverDetails.serverInfo.host & ":" & serverDetails.serverInfo.port
        };
    }

    /**
     * Reconstruct arguments from CommandBox flag format
     * Now includes validation for required arguments and data type validation
     *
     * @argStruct The arguments struct passed to run() method
     * @functionName Name of the calling function (default: "run")
     * @componentObject The component instance (use 'this' when calling)
     * @validate Whether to validate required arguments (default: true)
     * @allowedValues Struct of argument names with allowed values (for enums)
     *                Example: {environment: ["development","production","testing"]}
     * @numericRanges Struct of argument names with min/max numeric ranges
     *                Example: {port: {min: 1, max: 65535}, timeout: {min: 0, max: 3600}}
     */
    function reconstructArgs(
        required struct argStruct,
        string functionName = "run",
        any componentObject = this,
        boolean validate = true,
        struct allowedValues = {},
        struct numericRanges = {}
    ) {
        local.result = {};

        // Step 1: Reconstruct arguments from flags
        for (local.key in arguments.argStruct) {
            if (find("=", local.key)) {
                // Split only on the first = to handle values with = signs
                local.equalPos = find("=", local.key);
                local.paramName = left(local.key, local.equalPos - 1);
                local.paramValue = mid(local.key, local.equalPos + 1, len(local.key));

                // Remove surrounding quotes if present (but keep quotes if they're part of the actual value)
                // This handles cases like: name="value" -> name=value
                if (len(local.paramValue) >= 2 && left(local.paramValue, 1) == '"' && right(local.paramValue, 1) == '"') {
                    local.paramValue = mid(local.paramValue, 2, len(local.paramValue) - 2);
                }

                // Convert ONLY explicit string boolean values to actual booleans
                // Do NOT convert numeric 0/1 to boolean (they should stay as numbers)
                if (lCase(trim(local.paramValue)) == "true") {
                    local.result[local.paramName] = true;
                } else if (lCase(trim(local.paramValue)) == "false") {
                    local.result[local.paramName] = false;
                } else {
                    local.result[local.paramName] = local.paramValue;
                }
            } else {
                local.result[local.key] = arguments.argStruct[local.key];
            }
        }

        // Step 2: Fix CommandBox boolean pre-conversion
        // CommandBox converts --flag=0 to flag=false and --flag=1 to flag=true
        // We need to convert these back to numeric when the parameter type expects numeric
        // BUT: If we parsed a numeric value from a flag (like "keep=4"), use that instead
        try {
            local.funcMetadata = getMetadata(arguments.componentObject[arguments.functionName]);
            if (structKeyExists(local.funcMetadata, "parameters")) {
                for (local.param in local.funcMetadata.parameters) {
                    local.paramName = local.param.name;
                    local.paramType = structKeyExists(local.param, "type") ? local.param.type : "any";

                    // If parameter expects numeric but received boolean, convert back
                    // ONLY if we didn't already parse a string/numeric value
                    if ((local.paramType == "numeric" || local.paramType == "integer")
                        && structKeyExists(local.result, local.paramName)
                        && isBoolean(local.result[local.paramName])
                        && !isNumeric(local.result[local.paramName])) {

                        // Convert boolean back to numeric: false->0, true->1
                        local.result[local.paramName] = local.result[local.paramName] ? 1 : 0;
                    }

                    // If we have a string that's numeric, convert it to actual numeric
                    if ((local.paramType == "numeric" || local.paramType == "integer")
                        && structKeyExists(local.result, local.paramName)
                        && isSimpleValue(local.result[local.paramName])
                        && isNumeric(local.result[local.paramName])) {

                        local.result[local.paramName] = val(local.result[local.paramName]);
                    }
                }
            }
        } catch (any e) {
            // If metadata extraction fails, continue without boolean conversion
        }

        // Step 3: Validation
        if (arguments.validate) {
            local.result = validateArguments(
                args = local.result,
                functionName = arguments.functionName,
                componentObject = arguments.componentObject,
                allowedValues = arguments.allowedValues,
                numericRanges = arguments.numericRanges
            );
        }

        return local.result;
    }

    /**
     * Validate arguments based on function metadata
     *
     * @args The reconstructed arguments struct
     * @functionName Name of function to get metadata from
     * @componentObject Component instance to get metadata from
     * @allowedValues Struct of allowed values per argument
     * @numericRanges Struct of argument names with min/max numeric ranges
     */
    private function validateArguments(
        required struct args,
        required string functionName,
        required any componentObject,
        struct allowedValues = {},
        struct numericRanges = {}
    ) {
        local.errors = [];
        local.warnings = [];

        try {
            // Get function metadata
            local.funcMetadata = getMetadata(arguments.componentObject[arguments.functionName]);
            if (!structKeyExists(local.funcMetadata, "parameters")) {
                return arguments.args;
            }

            // Loop through each parameter in function signature
            for (local.param in local.funcMetadata.parameters) {
                local.paramName = local.param.name;
                local.paramType = structKeyExists(local.param, "type") ? local.param.type : "any";
                local.isRequired = structKeyExists(local.param, "required") && local.param.required;
                local.hasDefault = structKeyExists(local.param, "default");
                local.hasHint = structKeyExists(local.param, "hint");
                local.displayName = local.hasHint ? local.param.hint : humanizeArgName(local.paramName);

                // Get actual argument value
                local.argValue = structKeyExists(arguments.args, local.paramName)
                    ? arguments.args[local.paramName]
                    : "";

                // VALIDATION 1: Required string arguments cannot be empty
                if (local.isRequired && local.paramType == "string") {
                    if (!len(trim(local.argValue))) {
                        arrayAppend(local.errors, "#local.displayName# is required and cannot be empty");
                    }
                }

                // VALIDATION 2: Arguments with default values cannot be explicitly set to empty
                // This catches cases where user does: --format="" or format=""
                // UNLESS the default value itself is empty (in which case empty is valid)
                if (!local.isRequired && local.hasDefault) {
                    // Get the default value
                    local.defaultValue = local.param.default;

                    // Only validate if the default value is NOT empty
                    // If default is "", then "" is a valid value
                    if (len(trim(local.defaultValue))) {
                        // Check if the argument was explicitly provided in the args struct
                        if (structKeyExists(arguments.args, local.paramName)) {
                            // If it was provided but is empty, that's an error
                            if (!len(trim(local.argValue))) {
                                arrayAppend(local.errors, "#local.displayName# cannot be empty. Either omit it to use the default value or provide a valid value");
                            }
                        }
                    }
                }

                // VALIDATION 3: Allowed values (enum-like validation)
                if (structKeyExists(arguments.allowedValues, local.paramName)) {
                    local.allowed = arguments.allowedValues[local.paramName];

                    if (isArray(local.allowed)) {
                        if (!arrayFindNoCase(local.allowed, local.argValue)) {
                            arrayAppend(local.errors,
                                "#local.displayName# must be one of: #arrayToList(local.allowed, ', ')#. You provided: '#local.argValue#'"
                            );
                        }
                    }
                }

                // VALIDATION 4: Data type validation for common types
                if (len(trim(local.argValue))) {
                    switch (local.paramType) {
                        case "numeric":
                        case "integer":
                            if (!isNumeric(local.argValue)) {
                                arrayAppend(local.errors, "#local.displayName# must be a number. You provided: '#local.argValue#'");
                            }
                            break;

                        case "boolean":
                            // Already converted by reconstructArgs, so this is just a safety check
                            if (!isBoolean(local.argValue)) {
                                arrayAppend(local.errors, "#local.displayName# must be true or false");
                            }
                            break;

                        case "array":
                            if (!isArray(local.argValue)) {
                                arrayAppend(local.errors, "#local.displayName# must be an array");
                            }
                            break;

                        case "struct":
                            if (!isStruct(local.argValue)) {
                                arrayAppend(local.errors, "#local.displayName# must be a struct");
                            }
                            break;
                    }
                }

                // VALIDATION 5: Path validation (if argument name contains 'path' or 'file')
                if (len(trim(local.argValue)) &&
                    (findNoCase("path", local.paramName) || findNoCase("file", local.paramName))) {

                    // Check for invalid path characters (Windows: <>:"|?* but we allow : for drive letters)
                    if (reFind("[<>""|?*]", local.argValue)) {
                        arrayAppend(local.errors,
                            "#local.displayName# contains invalid path characters: #local.argValue#"
                        );
                    }
                }

                // VALIDATION 6: Numeric range validation
                if (structKeyExists(arguments.numericRanges, local.paramName)) {
                    if (local.paramType == "numeric" || local.paramType == "integer") {
                        // Check if value exists and is numeric (handle both explicit and default values)
                        local.numericValue = "";
                        if (structKeyExists(arguments.args, local.paramName) && isNumeric(arguments.args[local.paramName])) {
                            local.numericValue = arguments.args[local.paramName];
                        } else if (local.hasDefault && isNumeric(local.param.default)) {
                            // Use default value if not explicitly provided
                            local.numericValue = local.param.default;
                        }

                        if (isNumeric(local.numericValue)) {
                            local.range = arguments.numericRanges[local.paramName];
                            if (structKeyExists(local.range, "min") && local.numericValue < local.range.min) {
                                arrayAppend(local.errors,
                                    "#local.displayName# must be at least #local.range.min#. You provided: #local.numericValue#"
                                );
                            }
                            if (structKeyExists(local.range, "max") && local.numericValue > local.range.max) {
                                arrayAppend(local.errors,
                                    "#local.displayName# must be at most #local.range.max#. You provided: #local.numericValue#"
                                );
                            }
                        }
                    }
                }
            }

            // Throw error if validation failed
            if (arrayLen(local.errors)) {
                // Format error message with proper line breaks and bullets
                local.errorMessage = chr(10) & chr(10);
                local.errorMessage &= repeatString("-", 60) & chr(10);

                for (local.i = 1; local.i <= arrayLen(local.errors); local.i++) {
                    local.errorMessage &= "  " & local.i & ". " & local.errors[local.i] & chr(10);
                }

                local.errorMessage &= repeatString("-", 60) & chr(10);

                print.red(local.errorMessage);
                error("Validation Error");
            }

            // Show warnings but don't stop execution
            if (arrayLen(local.warnings)) {
                for (local.warning in local.warnings) {
                    print.yellowLine("Warning: " & local.warning);
                }
            }

        } catch (any e) {
            // If metadata parsing fails, just return args without validation
            // This ensures commands still work even if validation fails
            if (findNoCase("validation error", e.message)) {
                rethrow;
            }
        }

        return arguments.args;
    }

    /**
     * Convert camelCase or PascalCase to human-readable format
     * Example: "dataSourceName" -> "Data Source Name"
     */
    private function humanizeArgName(required string argName) {
        // Add space before capital letters
        local.result = reReplace(arguments.argName, "([A-Z])", " \1", "all");

        // Capitalize first letter
        local.result = uCase(left(local.result, 1)) & right(local.result, len(local.result) - 1);

        return trim(local.result);
    }
}