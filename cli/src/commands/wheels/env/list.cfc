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
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
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
        string sort = "name"
    ) {
        try{
            requireWheelsApp(getCWD());
            arguments = reconstructArgs(
                argStruct=arguments,
                allowedValues={
                    format: ["table", "json", "yaml"],
                    sort: ["name", "modified", "type"]
                }
            );
            var projectRoot = resolvePath(".");
            arguments.rootPath = projectRoot;
            var currentEnv = environmentService.getCurrentEnvironment(projectRoot);
            
            print.line("Checking for available environments...").toConsole();
            
            var environments = environmentService.list(argumentCollection=arguments);
            
            // Handle different format outputs
            if (arguments.format == "json") {
                var jsonOutput = formatAsJSON(environments, currentEnv);
                print.line(jsonOutput).toConsole();
            } else if (arguments.format == "yaml") {
                var yamlOutput = formatAsYAML(environments, currentEnv);
                print.line(yamlOutput).toConsole();
            } else {
                // Table format using detailOutput functions
                formatAsTable(environments, arguments.verbose, currentEnv);
            }
        } catch (any e) {
            detailOutput.error("#e.message#");
            setExitCode(1);
        }
    }

    /**
    * Format as JSON
    */
    private function formatAsJSON(environments, currentEnv) {
        var output = {
            environments: [],
            current: arguments.currentEnv,
            total: arrayLen(arguments.environments)
        };
        
        for (var env in arguments.environments) {
            var envData = {
                name: env.NAME,
                type: env.TYPE,
                active: env.ACTIVE,
                database: env.DATABASE,
                datasource: env.DATASOURCE,
                template: env.TEMPLATE,
                dbtype: env.DBTYPE,
                lastModified: dateTimeFormat(env.CREATED, "yyyy-mm-dd'T'HH:nn:ss'Z'"),
                status: env.STATUS,
                source: env.SOURCE
            };
            
            if (structKeyExists(env, "DEBUG")) {
                envData.debug = env.DEBUG;
            }
            if (structKeyExists(env, "CACHE")) {
                envData.cache = env.CACHE;
            }
            if (structKeyExists(env, "CONFIGPATH")) {
                envData.configPath = env.CONFIGPATH;
            }
            if (structKeyExists(env, "VALIDATIONERRORS") && arrayLen(env.VALIDATIONERRORS)) {
                envData.errors = env.VALIDATIONERRORS;
            }
            
            arrayAppend(output.environments, envData);
        }
        
        return serializeJSON(output);
    }

    /**
    * Format as YAML
    */
    private function formatAsYAML(environments, currentEnv) {
        var yaml = [];
        arrayAppend(yaml, "environments:");
        
        for (var env in arguments.environments) {
            arrayAppend(yaml, "  - name: #env.NAME#");
            arrayAppend(yaml, "    type: #env.TYPE#");
            arrayAppend(yaml, "    active: #env.ACTIVE#");
            arrayAppend(yaml, "    template: #env.TEMPLATE#");
            arrayAppend(yaml, "    database: #env.DATABASE#");
            arrayAppend(yaml, "    dbtype: #env.DBTYPE#");
            arrayAppend(yaml, "    created: #dateTimeFormat(env.CREATED, 'yyyy-mm-dd HH:nn:ss')#");
            arrayAppend(yaml, "    source: #env.SOURCE#");
            arrayAppend(yaml, "    status: #env.STATUS#");
            
            if (structKeyExists(env, "VALIDATIONERRORS") && arrayLen(env.VALIDATIONERRORS)) {
                arrayAppend(yaml, "    errors:");
                for (var error in env.VALIDATIONERRORS) {
                    arrayAppend(yaml, "      - #error#");
                }
            }
        }
        
        arrayAppend(yaml, "");
        arrayAppend(yaml, "current: #arguments.currentEnv#");
        arrayAppend(yaml, "total: #arrayLen(arguments.environments)#");
        
        return arrayToList(yaml, chr(10));
    }

    
    /**
    * Format as table using detailOutput functions
    */
    private function formatAsTable(environments, verbose, currentEnv) {
        if (arrayLen(arguments.environments) == 0) {
            detailOutput.statusWarning("No environments configured");
            detailOutput.statusInfo("Create an environment with: wheels env setup <environment>");
            return;
        }

        detailOutput.header("Available Environments");
        
        if (arguments.verbose) {
            // Verbose format using detailOutput functions
            detailOutput.metric("Total Environments", "#arrayLen(arguments.environments)#");
            detailOutput.metric("Current Environment", "#arguments.currentEnv#");
            detailOutput.line();
            
            for (var env in arguments.environments) {
                var envName = env.NAME;
                if (env.ACTIVE) {
                    envName &= " * [Active]";
                }
                
                detailOutput.subHeader(envName);
                detailOutput.metric("Type", env.TYPE);
                detailOutput.metric("Database", env.DATABASE);
                detailOutput.metric("Datasource", env.DATASOURCE);
                detailOutput.metric("Template", env.TEMPLATE);
                detailOutput.metric("DB Type", env.DBTYPE);
                
                if (structKeyExists(env, "DEBUG")) {
                    var debugStatus = env.DEBUG == 'true' ? 'Enabled' : 'Disabled';
                    detailOutput.metric("Debug", debugStatus);
                }
                if (structKeyExists(env, "CACHE")) {
                    var cacheStatus = env.CACHE == 'true' ? 'Enabled' : 'Disabled';
                    detailOutput.metric("Cache", cacheStatus);
                }
                if (structKeyExists(env, "CONFIGPATH")) {
                    detailOutput.metric("Config", env.CONFIGPATH);
                }
                
                detailOutput.metric("Modified", dateTimeFormat(env.CREATED, "yyyy-mm-dd HH:nn:ss"));
                detailOutput.metric("Source", env.SOURCE);
                
                // Status with appropriate color
                if (env.STATUS == "valid") {
                    detailOutput.metric("Status", "[OK] Valid");
                } else {
                    detailOutput.metric("Status", "[WARN] #env.STATUS#");
                }
                
                if (structKeyExists(env, "VALIDATIONERRORS") && arrayLen(env.VALIDATIONERRORS)) {
                    detailOutput.statusWarning("Issues:");
                    for (var error in env.VALIDATIONERRORS) {
                        detailOutput.output("  - #error#", true);
                    }
                }
                
                detailOutput.line();
            }
        } else {
            // In the formatAsTable function - compact table section
            detailOutput.line();

            // Prepare data for the table
            var tableData = [];
            var headers = ["Name", "Type", "Database", "Status", "Active", "DB Type"];

            // make sure tableData is an array
            if (!isArray(tableData)) {
                tableData = [];
            }

            for (var i = 1; i <= arrayLen(arguments.environments); i++) {
                var env = arguments.environments[i];

                var activeIndicator = env.ACTIVE ? "YES *" : "NO";
                var statusText = env.STATUS == "valid" ? "[OK] Valid" : "[WARN] " & env.STATUS;

                // create an ordered struct so JSON keeps this key order
                var row = structNew("ordered");
                row["Name"]     = env.NAME;
                row["Type"]     = env.TYPE;
                row["Database"] = env.DATABASE;
                row["Status"]   = statusText;
                row["Active"]   = activeIndicator;
                row["DB Type"]  = env.DBTYPE;

                arrayAppend(tableData, row);
            }

            // Display the table
            detailOutput.getPrint().table(
                data = tableData,
                headers = headers
            ).toConsole();
            
            detailOutput.line();
            detailOutput.line();
            detailOutput.metric("Total Environments", "#arrayLen(arguments.environments)#");
            detailOutput.metric("Current Environment", "#arguments.currentEnv#");
            detailOutput.statusInfo("* = Currently active environment");
            detailOutput.statusInfo("Use 'wheels env list --verbose' for detailed information");
        }
    }
}