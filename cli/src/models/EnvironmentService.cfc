component {

    property name="serverService" inject="ServerService";
    property name="templateService" inject="TemplateService@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * Setup a Wheels development environment
     */
    function setup(
        required string environment,
        required string rootPath,
        string template = "local",
        required string dbtype,
        string database = "",
        string datasource = "",
        string host = "",
        string port = "",
        string username = "",
        string password = "",
        string sid = "",
        boolean force = false,
        string base = "",
        boolean debug = false,
        boolean cache = false,
        string reloadPassword = "",
        boolean skipDatabase = false,
        boolean help = false,
        string updateMode = "create"
    ) {


        try {
            var projectRoot = arguments.rootPath;

            // Check if environment already exists
            var envFile = projectRoot & ".env." & arguments.environment;

            // Handle update mode for existing environments
            if (fileExists(envFile) && arguments.updateMode == "update") {
                // Update only database variables
                return updateDatabaseVariablesOnly(
                    envFile = envFile,
                    environment = arguments.environment,
                    dbtype = arguments.dbtype,
                    database = arguments.database,
                    datasource = arguments.datasource,
                    host = arguments.host,
                    port = arguments.port,
                    username = arguments.username,
                    password = arguments.password,
                    sid = arguments.sid
                );
            }

            if (fileExists(envFile) && !arguments.force && arguments.updateMode != "overwrite") {
                return {
                    success: false,
                    error: "Environment '" & arguments.environment & "' already exists. Use --force to overwrite."
                };
            }

            var result = {};
            
            // Check if base environment is specified
            if (len(trim(arguments.base))) {
                result = setupFromBaseEnvironment(argumentCollection = arguments, projectRoot = projectRoot);
            } else {
                // Setup based on template (existing logic)
                switch (arguments.template) {
                    case "docker":
                        result = setupDockerEnvironment(argumentCollection = arguments, projectRoot = projectRoot);
                        break;
                    case "vagrant":
                        result = setupVagrantEnvironment(argumentCollection = arguments, projectRoot = projectRoot);
                        break;
                    default:
                        result = setupLocalEnvironment(argumentCollection = arguments);
                }
            }

            if (result.success) {
                // Determine environment-specific settings based on environment type
                var envSettings = getEnvironmentSpecificSettings(arguments.environment, arguments.debug, arguments.cache);

                // Create environment file
                createEnvironmentFile(arguments.environment, result.config, projectRoot);
                createEnvironmentSettings(
                    environment = arguments.environment,
                    config = result.config,
                    rootPath = projectRoot,
                    debug = envSettings.debug,
                    cache = envSettings.cache,
                    reloadPassword = arguments.reloadPassword
                );

                // Write datasource to app.cfm with environment variables
                // Skip if skipDatabase=true (called from wheels db create) to avoid loading unresolved placeholders
                if (result.config.keyExists("datasourceInfo") && !arguments.skipDatabase) {
                    writeDatasourceToAppCfm(
                        arguments.environment,
                        result.config,
                        projectRoot
                    );
                }

                // Update server.json if needed
                updateServerConfig(arguments.environment, result.config, projectRoot);

                result.nextSteps = generateNextSteps(arguments.template, arguments.environment);

                // Add note if skipDatabase=true
                if (arguments.skipDatabase) {
                    if (!structKeyExists(result, "notes")) {
                        result.notes = [];
                    }
                    arrayAppend(result.notes, "Datasource configuration will be added to app.cfm after database is created successfully");
                }
            }

            return result;

        } catch (any e) {
            return {
                success: false,
                error: e.message
            };
        }
    }

    /**
    * List available environments with enhanced options
    */
    function list(
        required string rootPath,
        string format = "table",
        boolean verbose = false,
        boolean check = false,
        string filter = "All",
        string sort = "name",
        boolean help = false
    ) {
        // Show help information if requested
        if (arguments.help) {
            return getHelpInformation();
        }

        var environments = [];
        var projectRoot = arguments.rootPath;
        
        // Get current active environment
        var currentEnv = getCurrentEnvironment(projectRoot);

        // Look for .env.* files
        var envFiles = directoryList(
            projectRoot,
            false,
            "name",
            ".env.*"
        );

        for (var file in envFiles) {
            if (reFindNoCase("^\.env\.", file)) {
                var envName = listLast(file, ".");
                
                // Skip if it's just '.env' without extension
                if (envName == "env") continue;
                
                var config = loadEnvironmentConfig(envName, projectRoot);

                
                var envData = {
                    NAME: envName,
                    TYPE: determineEnvironmentType(envName),
                    TEMPLATE: structKeyExists(config, "WHEELS_TEMPLATE") ? config.WHEELS_TEMPLATE : "local",
                    DBTYPE: structKeyExists(config, "DB_TYPE") ? config.DB_TYPE : "unknown",
                    DATABASE: structKeyExists(config, "DB_DATABASE") ? config.DB_DATABASE : "unknown",
                    DATASOURCE: structKeyExists(config, "DB_DATASOURCE") ? config.DB_DATASOURCE : "wheels_#envName#",
                    CREATED: getFileInfo("#projectRoot#/#file#").lastModified,
                    SOURCE: "file",
                    PATH: "#projectRoot#/#file#",
                    ACTIVE: (envName == currentEnv),
                    STATUS: "valid"
                };

                // Add verbose data if requested
                if (arguments.verbose) {
                    envData.CONFIG = config;
                    envData.FILESIZE = getFileInfo("#projectRoot#/#file#").size;
                    envData.DEBUG = structKeyExists(config, "WHEELS_DEBUG") ? config.WHEELS_DEBUG : "unknown";
                    envData.CACHE = structKeyExists(config, "WHEELS_CACHE") ? config.WHEELS_CACHE : "unknown";
                    envData.CONFIGPATH = "/config/#envName#/settings.cfm";
                }

                // Check validation if requested
                if (arguments.check) {
                    var validation = validateEnvironment(config, projectRoot, envName);
                    envData.ISVALID = validation.isValid;
                    envData.VALIDATIONERRORS = validation.errors;
                    envData.STATUS = validation.isValid ? "valid" : "invalid";
                }

                arrayAppend(environments, envData);
            }
        }

        // Check server.json for environments
        var serverJsonPath = "#projectRoot#/server.json";
        if (fileExists(serverJsonPath)) {
            var serverJson = deserializeJSON(fileRead(serverJsonPath));
            if (structKeyExists(serverJson, "env") && isStruct(serverJson.env)) {
                for (var envName in serverJson.env) {
                    // Skip if already found as file
                    var alreadyExists = false;
                    for (var existingEnv in environments) {
                        if (existingEnv.NAME == envName) {
                            alreadyExists = true;
                            break;
                        }
                    }
                    
                    if (!alreadyExists) {
                        var envConfig = serverJson.env[envName];
                        var envData = {
                            NAME: envName,
                            TYPE: determineEnvironmentType(envName),
                            TEMPLATE: "server.json",
                            DBTYPE: structKeyExists(envConfig, "DB_TYPE") ? envConfig.DB_TYPE : "configured",
                            DATABASE: structKeyExists(envConfig, "DB_DATABASE") ? envConfig.DB_DATABASE : "configured",
                            DATASOURCE: structKeyExists(envConfig, "DB_DATASOURCE") ? envConfig.DB_DATASOURCE : "configured",
                            CREATED: getFileInfo(serverJsonPath).lastModified,
                            SOURCE: "server.json",
                            PATH: serverJsonPath,
                            ACTIVE: (envName == currentEnv),
                            STATUS: "valid"
                        };

                        if (arguments.verbose) {
                            envData.CONFIG = envConfig;
                            envData.FILESIZE = getFileInfo(serverJsonPath).size;
                        }

                        if (arguments.check) {
                            var validation = validateServerJsonEnvironment(envConfig);
                            envData.ISVALID = validation.isValid;
                            envData.VALIDATIONERRORS = validation.errors;
                            envData.STATUS = validation.isValid ? "valid" : "invalid";
                        }

                        arrayAppend(environments, envData);
                    }
                }
            }
        }

        // Apply filter
        if (arguments.filter != "All") {
            environments = filterEnvironments(environments, arguments.filter);
        }

        // Apply sorting
        environments = sortEnvironments(environments, arguments.sort);
        return environments;
    }

    /**
     * Switch to a different environment
     */
    function switch(required string environment, required string rootPath) {
        var projectRoot = arguments.rootPath;
        var envFile = "#projectRoot#/.env";
        var envBackupFile = "#projectRoot#/.env.backup-#dateTimeFormat(now(), 'yyyymmdd-HHmmss')#";
        
        // Check if .env file exists
        if (!fileExists(envFile)) {
            // Create new .env file with wheels_env variable
            fileWrite(envFile, "wheels_env=#arguments.environment#");
            return {
                success: true,
                message: "Created new .env file and set environment to '#arguments.environment#'",
                database: "",
                debug: false,
                cache: "unknown"
            };
        }
        
        // Read current .env file
        var envContent = fileRead(envFile);
        var envLines = listToArray(envContent, chr(10));
        var updatedLines = [];
        var envVarFound = false;
        var oldEnvironment = "";
        
        // Process each line to find and update environment variable
        for (var line in envLines) {
            var trimmedLine = trim(line);
            
            // Skip empty lines and comments
            if (len(trimmedLine) == 0 || left(trimmedLine, 1) == "##") {
                updatedLines.append(line);
                continue;
            }
            
            // Check for wheels_env or environment variable
            if (findNoCase("wheels_env=", trimmedLine) == 1) {
                oldEnvironment = listLast(trimmedLine, "=");
                updatedLines.append("wheels_env=#arguments.environment#");
                envVarFound = true;
            } else if (!envVarFound && findNoCase("environment=", trimmedLine) == 1) {
                oldEnvironment = listLast(trimmedLine, "=");
                // Replace environment with wheels_env
                updatedLines.append("wheels_env=#arguments.environment#");
                envVarFound = true;
            } else {
                updatedLines.append(line);
            }
        }
        
        // If no environment variable was found, add wheels_env
        if (!envVarFound) {
            updatedLines.append("wheels_env=#arguments.environment#");
        }
        
        // Write updated content back to .env file
        try {
            fileWrite(envFile, arrayToList(updatedLines, chr(10)));
        } catch (any e) {
            // Restore backup if write fails
            if (fileExists(envBackupFile)) {
                fileCopy(envBackupFile, envFile);
            }
            return {
                success: false,
                error: "Failed to update .env file: #e.message#"
            };
        }
        
        // Update server.json if it exists
        var serverJsonPath = "#projectRoot#/server.json";
        if (fileExists(serverJsonPath)) {
            try {
                var serverJson = deserializeJSON(fileRead(serverJsonPath));
                serverJson.profile = arguments.environment;
                fileWrite(serverJsonPath, serializeJSON(serverJson, true));
            } catch (any e) {
                // Non-critical error, continue
            }
        }

        // Update settings.cfm file to reflect the new environment
        updateEnvironmentInSettingsFile(arguments.environment, projectRoot);
        
        // Try to read additional environment-specific file if it exists
        var specificEnvFile = "#projectRoot#/.env.#arguments.environment#";
        var additionalConfig = {};
        if (fileExists(specificEnvFile)) {
            try {
                var specificContent = fileRead(specificEnvFile);
                var specificLines = listToArray(specificContent, chr(10));
                for (var line in specificLines) {
                    if (findNoCase("database=", line) == 1) {
                        additionalConfig.database = listLast(line, "=");
                    }
                    if (findNoCase("debug=", line) == 1) {
                        additionalConfig.debug = listLast(line, "=") == "true";
                    }
                    if (findNoCase("cache=", line) == 1) {
                        additionalConfig.cache = listLast(line, "=");
                    }
                }
            } catch (any e) {
                // Non-critical, continue
            }
        }
        
        return {
            success: true,
            message: "Successfully switched from '#oldEnvironment#' to '#arguments.environment#'",
            oldEnvironment: oldEnvironment,
            newEnvironment: arguments.environment,
            backupFile: envBackupFile,
            database: structKeyExists(additionalConfig, "database") ? additionalConfig.database : "default",
            debug: structKeyExists(additionalConfig, "debug") ? additionalConfig.debug : false,
            cache: structKeyExists(additionalConfig, "cache") ? additionalConfig.cache : "default"
        };
    }

    /**
    * Get current environment from .env file
    */
    function getCurrent(required string rootPath) {
        var envFile = "#arguments.rootPath#/.env";
        
        if (!fileExists(envFile)) {
            return "none";
        }
        
        var envContent = fileRead(envFile);
        var envLines = listToArray(envContent, chr(10));
        
        for (var line in envLines) {
            var trimmedLine = trim(line);
            
            // Check for wheels_env first
            if (findNoCase("wheels_env=", trimmedLine) == 1) {
                return trim(listLast(trimmedLine, "="));
            }
            // Fallback to environment
            if (findNoCase("environment=", trimmedLine) == 1) {
                return trim(listLast(trimmedLine, "="));
            }
        }
        
        return "none";
    }

    /**
     * Get environment-specific settings based on environment type
     * Determines debug, cache, and other settings appropriate for each environment
     */
    private function getEnvironmentSpecificSettings(
        required string environment,
        boolean debug = false,
        boolean cache = false
    ) {
        var envType = lCase(trim(arguments.environment));
        var settings = {
            debug: arguments.debug,
            cache: arguments.cache
        };

        // If user explicitly set debug or cache flags, respect them
        // Otherwise, apply environment-specific defaults
        var userSetDebug = structKeyExists(arguments, "debug") && arguments.debug != false;
        var userSetCache = structKeyExists(arguments, "cache") && arguments.cache != false;

        // Environment-specific defaults (only applied if user didn't explicitly set values)
        switch (envType) {
            case "development":
                if (!userSetDebug) settings.debug = true;
                if (!userSetCache) settings.cache = false;
                break;

            case "testing":
                if (!userSetDebug) settings.debug = true;
                if (!userSetCache) settings.cache = false;
                break;

            case "staging":
                if (!userSetDebug) settings.debug = false;
                if (!userSetCache) settings.cache = true;
                break;

            case "maintenance":
                if (!userSetDebug) settings.debug = false;
                if (!userSetCache) settings.cache = true;
                break;

            case "production":
                if (!userSetDebug) settings.debug = false;
                if (!userSetCache) settings.cache = true;
                break;

            default:
                // Custom environment names default to production-like settings
                if (!userSetDebug) settings.debug = false;
                if (!userSetCache) settings.cache = true;
                break;
        }

        return settings;
    }

    /**
     * Setup local development environment
     */
    private function setupLocalEnvironment(argumentCollection) {

        // Default database name if not provided
        var databaseName = len(trim(arguments.database)) ?
            arguments.database :
            "wheels_#arguments.environment#";
        var datasourceName = len(trim(arguments.datasource)) ?
            arguments.datasource :
            "wheels_#arguments.environment#";

        var config = {
            template: "local",
            dbtype: arguments.dbtype,
            database: databaseName,
            port: 8080,
            cfengine: "lucee5"
        };

        // Use provided values or defaults
        var dbHost = len(trim(arguments.host)) ? arguments.host : "localhost";
        var dbPort = len(trim(arguments.port)) ? arguments.port : getDatabasePort(arguments.dbtype);
        var dbUsername = len(trim(arguments.username)) ? arguments.username : getDefaultUsername(arguments.dbtype);
        var dbPassword = len(trim(arguments.password)) ? arguments.password : getDefaultPassword(arguments.dbtype);
        var dbSid = len(trim(arguments.sid)) ? arguments.sid : "ORCL";

        // Database-specific configuration
        switch (arguments.dbtype) {
            case "mysql":
                config.datasourceInfo = {
                    driver: "MySQL",
                    host: dbHost,
                    port: dbPort,
                    database: databaseName,
                    datasource: datasourceName,
                    username: dbUsername,
                    password: dbPassword
                };
                break;
            case "postgres":
                config.datasourceInfo = {
                    driver: "PostgreSQL",
                    host: dbHost,
                    port: dbPort,
                    database: databaseName,
                    datasource: datasourceName,
                    username: dbUsername,
                    password: dbPassword
                };
                break;
            case "mssql":
                config.datasourceInfo = {
                    driver: "MSSQL",
                    host: dbHost,
                    port: dbPort,
                    database: databaseName,
                    datasource: datasourceName,
                    username: dbUsername,
                    password: dbPassword
                };
                break;
            case "oracle":
                config.datasourceInfo = {
                    driver: "Oracle",
                    host: dbHost,
                    port: dbPort,
                    database: databaseName,
                    datasource: datasourceName,
                    username: dbUsername,
                    password: dbPassword,
                    sid: dbSid
                };
                break;
            case "sqlite":
                // SQLite requires absolute path - calculate it now
                var dbFileName = (len(trim(arguments.database)) && trim(arguments.database) != "") ?
                    "#trim(arguments.database)#.db" :
                    "wheels_#arguments.environment#.db";
                // Get absolute path to db directory - normalize path separators
                // Remove trailing separator from rootPath if it exists
                var cleanRootPath = arguments.rootPath;
                if (right(cleanRootPath, 1) == "\" || right(cleanRootPath, 1) == "/") {
                    cleanRootPath = left(cleanRootPath, len(cleanRootPath) - 1);
                }
                var pathSep = server.separator.file;
                var absoluteDbPath = cleanRootPath & pathSep & "db" & pathSep & dbFileName;

                // Ensure db directory exists for SQLite
                var dbDir = cleanRootPath & pathSep & "db";
                if (!directoryExists(dbDir)) {
                    directoryCreate(dbDir);
                }

                config.datasourceInfo = {
                    driver: "SQLite",
                    host: "",
                    port: "",
                    database: absoluteDbPath,
                    datasource: datasourceName,
                    username: "",
                    password: ""
                };
                break;
            default: // h2
                config.datasourceInfo = {
                    driver: "H2",
                    host:"",
                    port:"",
                    database: len(trim(arguments.database)) ?
                        "./db/#arguments.database#" :
                        "./db/wheels_#arguments.environment#",
                    datasource:datasourceName,
                    username: dbUsername,
                    password: dbPassword
                };
        }

        return {
            success: true,
            config: config
        };
    }

    /**
     * Get default username for database type
     */
    private string function getDefaultUsername(required string dbtype) {
        switch (arguments.dbtype) {
            case "mysql":
                return "wheels";
            case "postgres":
                return "wheels";
            case "mssql":
                return "sa";
            case "oracle":
                return "wheels";
            case "h2":
                return "sa";
            case "sqlite":
                return "";
            default:
                return "wheels";
        }
    }

    /**
     * Get default password for database type
     */
    private string function getDefaultPassword(required string dbtype) {
        switch (arguments.dbtype) {
            case "mysql":
                return "wheels_password";
            case "postgres":
                return "wheels_password";
            case "mssql":
                return "Wheels_Pass123!";
            case "oracle":
                return "wheels_password";
            case "h2":
                return "";
            case "sqlite":
                return "";
            default:
                return "wheels_password";
        }
    }

    /**
     * Setup Docker environment
     */
    private function setupDockerEnvironment(argumentCollection, rootPath) {
        // Default database name if not provided
        var databaseName = len(trim(arguments.database)) ? 
            arguments.database : 
            "wheels";
            
        var config = {
            template: "docker",
            dbtype: arguments.dbtype,
            database: databaseName,
            port: 8080
        };

        // Create docker-compose.yml
        var dockerComposeContent = generateDockerCompose(argumentCollection = arguments);
        fileWrite("#arguments.rootPath#docker-compose.#arguments.environment#.yml", dockerComposeContent);

        // Create Dockerfile if it doesn't exist
        var dockerfilePath = "#arguments.rootPath#Dockerfile";
        if (!fileExists(dockerfilePath)) {
            var dockerfileContent = generateDockerfile();
            fileWrite(dockerfilePath, dockerfileContent);
        }

        // Database configuration for Docker
        config.datasourceInfo = {
            driver: getDatabaseDriver(arguments.dbtype),
            host: "db",
            port: getDatabasePort(arguments.dbtype),
            database: databaseName,
            username: "wheels",
            password: "wheels_password"
        };

        return {
            success: true,
            config: config
        };
    }

    /**
     * Setup Vagrant environment
     */
    private function setupVagrantEnvironment(argumentCollection, rootPath) {
        // Default database name if not provided
        var databaseName = len(trim(arguments.database)) ? 
            arguments.database : 
            "wheels";
            
        var config = {
            template: "vagrant",
            dbtype: arguments.dbtype,
            database: databaseName,
            port: 8080
        };

        // Create Vagrantfile
        var vagrantContent = generateVagrantfile(argumentCollection = arguments);
        fileWrite("#arguments.rootPath#Vagrantfile.#arguments.environment#", vagrantContent);

        // Create provisioning script
        var provisionScript = generateProvisionScript(argumentCollection = arguments);
        var provisionDir = "#arguments.rootPath#vagrant";
        if (!directoryExists(provisionDir)) {
            directoryCreate(provisionDir);
        }
        fileWrite(provisionDir & "/provision-#arguments.environment#.sh", provisionScript);

        return {
            success: true,
            config: config
        };
    }

    /**
     * Create environment file
     */
    private function createEnvironmentFile(environment, config, rootPath) {
        var envContent = [];

        // Basic settings
        arrayAppend(envContent, "## Wheels Environment: #arguments.environment#");
        arrayAppend(envContent, "## Generated on: #dateTimeFormat(now(), 'yyyy-mm-dd HH:nn:ss')#");
        arrayAppend(envContent, "");
        arrayAppend(envContent, "## Application Settings");
        arrayAppend(envContent, "WHEELS_ENV=#arguments.environment#");
        arrayAppend(envContent, "WHEELS_RELOAD_PASSWORD=wheels#arguments.environment#");
        arrayAppend(envContent, "");

        // Database settings - Use GENERIC variable names for all database types
        if (arguments.config.keyExists("datasourceInfo")) {
            arrayAppend(envContent, "## Database Settings");

            // Use generic DB_* prefix for all database types
            arrayAppend(envContent, "DB_TYPE=#arguments.config.dbtype#");

            // Add host (if applicable - H2 doesn't use host)
            if (len(trim(arguments.config.datasourceInfo.host))) {
                arrayAppend(envContent, "DB_HOST=#arguments.config.datasourceInfo.host#");
            }

            // Add port (if applicable - H2 doesn't use port)
            if (len(trim(arguments.config.datasourceInfo.port))) {
                arrayAppend(envContent, "DB_PORT=#arguments.config.datasourceInfo.port#");
            }

            // Database name
            arrayAppend(envContent, "DB_DATABASE=#arguments.config.datasourceInfo.database#");

            // Credentials
            arrayAppend(envContent, "DB_USER=#arguments.config.datasourceInfo.username#");
            arrayAppend(envContent, "DB_PASSWORD=#arguments.config.datasourceInfo.password#");

            // Add Oracle SID if exists
            if (arguments.config.dbtype == "oracle" && structKeyExists(arguments.config.datasourceInfo, "sid")) {
                arrayAppend(envContent, "DB_SID=#arguments.config.datasourceInfo.sid#");
            }

            // Add datasource name
            if (structKeyExists(arguments.config.datasourceInfo, "datasource")) {
                arrayAppend(envContent, "DB_DATASOURCE=#arguments.config.datasourceInfo.datasource#");
            }

            arrayAppend(envContent, "");
        }

        // Server settings
        arrayAppend(envContent, "## Server Settings");
        arrayAppend(envContent, "SERVER_PORT=#arguments.config.port#");
        if (arguments.config.keyExists("cfengine")) {
            arrayAppend(envContent, "SERVER_CFENGINE=#arguments.config.cfengine#");
        }

        fileWrite("#arguments.rootPath#.env.#arguments.environment#", arrayToList(envContent, chr(10)));
    }

     /**
     * Create Settings file - Enhanced with debug, cache, and reload-password support
     */
    function createEnvironmentSettings(
        required string environment,
        required struct config,
        required string rootPath,
        boolean debug = true,
        boolean cache = false,
        string reloadPassword = ""
    ) {
        var projectRoot = arguments.rootPath;
        var envDir = projectRoot & "/config/#arguments.environment#";
        var settingsFile = envDir & "/settings.cfm";

        // Create directory if it doesn't exist
        if (!directoryExists(envDir)) {
            directoryCreate(envDir, true); // recursive = true
        }
        
        // Generate timestamp
        var now = dateFormat(now(), "yyyy-mm-dd") & " " & timeFormat(now(), "HH:mm:ss");
        
        // Get Datasource name from config
        var datasourceName = arguments.config.keyExists("datasourceInfo") && arguments.config.datasourceInfo.keyExists("datasource") ? 
            arguments.config.datasourceInfo.datasource : 
            "wheels_" & arguments.environment;
        
        // Determine reload password
        var reloadPass = len(trim(arguments.reloadPassword)) ?
            arguments.reloadPassword :
            "wheels" & arguments.environment;

        // Get environment-specific settings
        var envType = lCase(trim(arguments.environment));
        var isDevelopment = (envType == "development");
        var isTesting = (envType == "testing");
        var isStaging = (envType == "staging");
        var isMaintenance = (envType == "maintenance");
        var isProduction = (envType == "production" || !listFindNoCase("development,testing,staging,maintenance", envType));

        // Determine if production-like (staging, maintenance, production, or custom)
        var isProductionLike = (isProduction || isStaging || isMaintenance);

        // Define content with environment-specific settings
        var content = '<cfscript>
    // Environment: #arguments.environment#
    // Generated: #now#
    // Environment Type: #isProduction ? "Production/Custom" : (isDevelopment ? "Development" : (isTesting ? "Testing" : (isStaging ? "Staging" : "Maintenance")))#
    // Debug Mode: #arguments.debug ? "Enabled" : "Disabled"#
    // Cache Mode: #arguments.cache ? "Enabled" : "Disabled"#

    // Database settings
    set(dataSourceName="#datasourceName#");

    // Environment settings
    set(environment="#arguments.environment#");

    // Debug settings - #arguments.debug ? "enabled for debugging" : "disabled for performance"#
    set(showDebugInformation=#arguments.debug#);
    set(showErrorInformation=#arguments.debug#);

    // Caching settings - #arguments.cache ? "enabled for performance" : "disabled for development"#
    set(cacheFileChecking=#arguments.cache#);
    set(cacheImages=#arguments.cache#);
    set(cacheModelInitialization=#arguments.cache#);
    set(cacheControllerInitialization=#arguments.cache#);
    set(cacheRoutes=#arguments.cache#);
    set(cacheActions=#arguments.cache#);
    set(cachePages=#arguments.cache#);
    set(cachePartials=#arguments.cache#);
    set(cacheQueries=#arguments.cache#);

    // Security
    set(reloadPassword="#reloadPass#");

    // URLs
    set(urlRewriting="On");

    // Error handling - #isProductionLike ? "production mode" : "development mode"#
    set(sendEmailOnError=#isProductionLike ? "true" : "false"#);
    set(errorEmailAddress="dev-team@example.com");

    // Performance - #isProductionLike ? "optimized for production" : "optimized for development"#
    set(softDeleteProperty="deletedAt");
    set(setUpdatedAtOnCreate=true);

    // Request handling
    set(obfuscateUrls=#isProductionLike#);
    set(clearQueryCacheOnReload=true);
</cfscript>';

        // Write to settings.cfm
        fileWrite(settingsFile, content);
        
        return {
            success: true,
            message: "settings.cfm created at /config/#arguments.environment#/ with debug=#arguments.debug#, cache=#arguments.cache#"
        };
    }

    /**
     * Write datasource to app.cfm using environment variables
     * PUBLIC: Called from create.cfc after database creation
     */
    public function writeDatasourceToAppCfm(
        required string environment,
        required struct config,
        required string rootPath
    ) {
        try {
            var appCfmPath = arguments.rootPath & "/config/app.cfm";
            if (!fileExists(appCfmPath)) {
                return { success: false, message: "app.cfm not found" };
            }

            var content = fileRead(appCfmPath);
            var datasourceName = arguments.config.datasourceInfo.datasource;

            // Check if datasource already exists
            if (find('this.datasources["#datasourceName#"]', content)) {
                return { success: true, message: "Datasource already exists in app.cfm" };
            }

            // Build datasource configuration using GENERIC environment variables
            var dsConfig = getDatasourceConfigForEnvVars(arguments.config.dbtype);

            // Build datasource definition using generic DB_* environment variables
            var dsDefinition = chr(10) & chr(9) & "// #arguments.config.datasourceInfo.driver# Datasource - Uses generic DB_* environment variables" & chr(10);

            // For H2/SQLite (file-based), check DB_DATABASE; for others check DB_HOST
            var dbType = lCase(arguments.config.dbtype);
            var isFileBased = (dbType == "h2" || dbType == "sqlite");
            var conditionKey = isFileBased ? "DB_DATABASE" : "DB_HOST";

            dsDefinition &= chr(9) & "if (structKeyExists(this.env, ""#conditionKey#"") && len(trim(this.env.#conditionKey#))) {" & chr(10);
            dsDefinition &= chr(9) & chr(9) & 'this.datasources["#datasourceName#"] = {' & chr(10);
            dsDefinition &= chr(9) & chr(9) & chr(9) & 'class: "#dsConfig.class#",' & chr(10);
            dsDefinition &= chr(9) & chr(9) & chr(9) & 'bundleName: "#dsConfig.bundleName#",' & chr(10);
            dsDefinition &= chr(9) & chr(9) & chr(9) & 'connectionString: "#dsConfig.connectionString#",' & chr(10);
            dsDefinition &= chr(9) & chr(9) & chr(9) & 'username: "##this.env.DB_USER##",' & chr(10);
            dsDefinition &= chr(9) & chr(9) & chr(9) & 'password: "##this.env.DB_PASSWORD##",' & chr(10);
            dsDefinition &= chr(9) & chr(9) & chr(9) & 'connectionLimit: -1,' & chr(10);
            dsDefinition &= chr(9) & chr(9) & chr(9) & 'liveTimeout: 15,' & chr(10);
            dsDefinition &= chr(9) & chr(9) & chr(9) & 'validate: false' & chr(10);
            dsDefinition &= chr(9) & chr(9) & '};' & chr(10);
            dsDefinition &= chr(9) & '}' & chr(10);

            // Insert before CLI-Appends-Here marker or before closing cfscript tag
            if (find("// CLI-Appends-Here", content)) {
                content = replace(content, "// CLI-Appends-Here", dsDefinition & chr(9) & "// CLI-Appends-Here");
            } else {
                var closingTag = "<" & "/cfscript>";
                content = replace(content, closingTag, dsDefinition & closingTag);
            }

            fileWrite(appCfmPath, content);
            return { success: true, message: "Datasource added to app.cfm with environment variables" };

        } catch (any e) {
            return { success: false, message: "Error writing datasource to app.cfm: " & e.message };
        }
    }

    /**
     * Get datasource configuration template using GENERIC DB_* environment variables
     * All database types now use DB_HOST, DB_PORT, DB_DATABASE, DB_USER, DB_PASSWORD
     */
    private struct function getDatasourceConfigForEnvVars(required string dbtype) {
        var config = {};

        switch (lCase(arguments.dbtype)) {
            case "mysql":
                config = {
                    class: "com.mysql.cj.jdbc.Driver",
                    bundleName: "com.mysql.cj",
                    connectionString: "jdbc:mysql://##this.env.DB_HOST##:##this.env.DB_PORT##/##this.env.DB_DATABASE##?characterEncoding=UTF-8&serverTimezone=UTC&maxReconnects=3"
                };
                break;
            case "postgres":
            case "postgresql":
                config = {
                    class: "org.postgresql.Driver",
                    bundleName: "org.postgresql.jdbc",
                    connectionString: "jdbc:postgresql://##this.env.DB_HOST##:##this.env.DB_PORT##/##this.env.DB_DATABASE##"
                };
                break;
            case "mssql":
            case "mssqlserver":
                config = {
                    class: "com.microsoft.sqlserver.jdbc.SQLServerDriver",
                    bundleName: "org.lucee.mssql",
                    connectionString: "jdbc:sqlserver://##this.env.DB_HOST##:##this.env.DB_PORT##;DATABASENAME=##this.env.DB_DATABASE##;trustServerCertificate=true;SelectMethod=direct"
                };
                break;
            case "oracle":
                config = {
                    class: "oracle.jdbc.OracleDriver",
                    bundleName: "org.lucee.oracle",
                    connectionString: "jdbc:oracle:thin:@##this.env.DB_HOST##:##this.env.DB_PORT##:##this.env.DB_SID##"
                };
                break;
            case "sqlite":
                config = {
                    class: "org.sqlite.JDBC",
                    bundleName: "org.xerial.sqlite-jdbc",
                    connectionString: "jdbc:sqlite:##this.env.DB_DATABASE##"
                };
                break;
            case "h2":
                config = {
                    class: "org.h2.Driver",
                    bundleName: "org.h2",
                    connectionString: "jdbc:h2:./db/##this.env.DB_DATABASE##;MODE=MySQL"
                };
                break;
        }

        return config;
    }

    /**
     * Update server.json configuration
     */
    private function updateServerConfig(environment, config, rootPath) {
        var serverJsonPath = "#arguments.rootPath#server.json";
        var serverJson = {};

        if (fileExists(serverJsonPath)) {
            serverJson = deserializeJSON(fileRead(serverJsonPath));
        }

        // Initialize env section if needed
        if (!serverJson.keyExists("env")) {
            serverJson.env = {};
        }

        // Add environment-specific settings
        serverJson.env[arguments.environment] = {
            "WHEELS_ENV": arguments.environment,
            "SERVER_PORT": arguments.config.port
        };

        // Add datasource if configured
        if (arguments.config.keyExists("datasourceInfo")) {
            var ds = arguments.config.datasourceInfo;
            serverJson.env[arguments.environment]["DB_TYPE"] = arguments.config.dbtype;
            serverJson.env[arguments.environment]["DB_DRIVER"] = ds.driver;
            serverJson.env[arguments.environment]["DB_HOST"] = ds.host;
            // Only add port if it's not empty (H2 doesn't use ports)
            if (len(trim(ds.port))) {
                serverJson.env[arguments.environment]["DB_PORT"] = ds.port;
            }
            serverJson.env[arguments.environment]["DB_DATABASE"] = ds.database;
            serverJson.env[arguments.environment]["DB_USER"] = ds.username;
            serverJson.env[arguments.environment]["DB_PASSWORD"] = ds.password;
        }

        fileWrite(serverJsonPath, serializeJSON(serverJson, true));
    }

    /**
     * Generate Docker Compose configuration
     */
    private function generateDockerCompose(argumentCollection) {
        // Default database name if not provided
        var databaseName = len(trim(arguments.database)) ? 
            arguments.database : 
            "wheels";
            
        var compose = "version: '3.8'

services:
  app:
    build: .
    ports:
      - ""8080:8080""
    environment:
      - WHEELS_ENV=#arguments.environment#
      - DB_TYPE=#arguments.dbtype#
      - DB_HOST=db
      - DB_PORT=#getDatabasePort(arguments.dbtype)#
      - DB_DATABASE=#databaseName#
      - DB_USER=wheels
      - DB_PASSWORD=wheels_password
    volumes:
      - .:/app
    depends_on:
      - db

  db:
    image: #getDatabaseImage(arguments.dbtype)#
    ports:
      - ""##getDatabasePort(arguments.dbtype)##:##getDatabasePort(arguments.dbtype)##""
    environment:
      ##getDatabaseEnvironment(arguments.dbtype, databaseName)##
    volumes:
      - db_data:/var/lib/##getDatabaseVolumeDir(arguments.dbtype)##

volumes:
  db_data:";

        return compose;
    }

    /**
     * Generate Dockerfile
     */
    private function generateDockerfile() {
        return "FROM ortussolutions/commandbox:lucee5

## Copy application files
COPY . /app
WORKDIR /app

## Install dependencies
RUN box install

## Expose port
EXPOSE 8080

## Start server
CMD [""box"", ""server"", ""start"", ""--console""]";
    }

    /**
     * Generate Vagrantfile
     */
    private function generateVagrantfile(argumentCollection) {
        return "## -*- mode: ruby -*-
## vi: set ft=ruby :

Vagrant.configure(""2"") do |config|
  config.vm.box = ""ubuntu/focal64""

  config.vm.network ""forwarded_port"", guest: 8080, host: 8080
  config.vm.network ""private_network"", ip: ""192.168.56.10""

  config.vm.provider ""virtualbox"" do |vb|
    vb.memory = ""2048""
    vb.cpus = 2
  end

  config.vm.provision ""shell"", path: ""vagrant/provision-#arguments.environment#.sh""
end";
    }

    /**
     * Generate provisioning script
     */
    private function generateProvisionScript(argumentCollection) {
        return "##!/bin/bash

## Update system
apt-get update
apt-get upgrade -y

## Install Java
apt-get install -y openjdk-11-jdk

## Install CommandBox
curl -fsSl https://downloads.ortussolutions.com/debs/gpg | apt-key add -
echo ""deb https://downloads.ortussolutions.com/debs/noarch /"" | tee -a /etc/apt/sources.list.d/commandbox.list
apt-get update && apt-get install -y commandbox

## Install database
##getProvisionDatabase(arguments.dbtype)##

## Setup application
cd /vagrant
box install
box server start port=8080 host=0.0.0.0";
    }

    /**
    * Load environment configuration - UPDATED VERSION
    */
    private function loadEnvironmentConfig(environment, rootPath) {
        var config = {};
        var envFile = "#arguments.rootPath#/.env.#arguments.environment#";

        if (fileExists(envFile)) {
            var lines = fileRead(envFile).listToArray(chr(10));
            for (var line in lines) {
                line = trim(line);
                if (len(line) && !line.startsWith("##")) {
                    var parts = line.listToArray("=");
                    if (arrayLen(parts) >= 2) {
                        var key = trim(parts[1]);
                        var value = trim(parts[2]);
                        // Remove quotes if present
                        value = reReplace(value, "^[""']|[""']$", "", "all");
                        config[key] = value;
                    }
                }
            }
        }

        return config;
    }

    /**
     * Generate next steps based on template
     */
    private function generateNextSteps(template, environment) {
        var steps = [];

        switch (arguments.template) {
            case "docker":
                arrayAppend(steps, "1. Start Docker environment: docker-compose -f docker-compose.#arguments.environment#.yml up");
                arrayAppend(steps, "2. Access application at: http://localhost:8080");
                arrayAppend(steps, "3. Stop environment: docker-compose -f docker-compose.#arguments.environment#.yml down");
                break;
            case "vagrant":
                arrayAppend(steps, "1. Start Vagrant VM: vagrant up");
                arrayAppend(steps, "2. Access application at: http://localhost:8080 or http://192.168.56.10:8080");
                arrayAppend(steps, "3. SSH into VM: vagrant ssh");
                arrayAppend(steps, "4. Stop VM: vagrant halt");
                break;
            default:
                arrayAppend(steps, "1. Switch to environment: wheels env switch #arguments.environment#");
                arrayAppend(steps, "2. Start server: box server start");
                arrayAppend(steps, "3. Access application at: http://localhost:8080");
        }

        return steps;
    }

    /**
     * Database helper functions
     */
    private function getDatabaseDriver(dbtype) {
        switch (arguments.dbtype) {
            case "mysql": return "MySQL";
            case "postgres": return "PostgreSQL";
            case "mssql": return "MSSQL";
            case "oracle": return "Oracle";
            case "sqlite": return "SQLite";
            default: return "H2";
        }
    }

    private function getDatabasePort(dbtype) {
        switch (arguments.dbtype) {
            case "mysql": return 3306;
            case "postgres": return 5432;
            case "mssql": return 1433;
            case "oracle": return 1521;
            case "h2": return ""; // H2 is embedded, no port
            case "sqlite": return ""; // SQLite is file-based, no port
            default: return "";
        }
    }

    private function getDatabaseImage(dbtype) {
        switch (arguments.dbtype) {
            case "mysql": return "mysql:8";
            case "postgres": return "postgres:14";
            case "mssql": return "mcr.microsoft.com/mssql/server:2019-latest";
            case "oracle": return "gvenzl/oracle-xe:latest";
            default: return "oscarfonts/h2:latest";
        }
    }

    private function getDatabaseEnvironment(dbtype, databaseName = "wheels") {
        switch (arguments.dbtype) {
            case "mysql":
                return "MYSQL_ROOT_PASSWORD=root_password
      MYSQL_DATABASE=#arguments.databaseName#
      MYSQL_USER=wheels
      MYSQL_PASSWORD=wheels_password";
            case "postgres":
                return "POSTGRES_DB=#arguments.databaseName#
      POSTGRES_USER=wheels
      POSTGRES_PASSWORD=wheels_password";
            case "mssql":
                return "ACCEPT_EULA=Y
      SA_PASSWORD=Wheels_Pass123!";
            case "oracle":
                return "ORACLE_PASSWORD=wheels_password
      ORACLE_DATABASE=#arguments.databaseName#
      APP_USER=wheels
      APP_USER_PASSWORD=wheels_password";
            default:
                return "H2_OPTIONS=-ifNotExists";
        }
    }

    private function getDatabaseVolumeDir(dbtype) {
        switch (arguments.dbtype) {
            case "mysql": return "mysql";
            case "postgres": return "postgresql/data";
            case "mssql": return "mssql";
            case "oracle": return "oracle/oradata";
            default: return "h2";
        }
    }

    private function getProvisionDatabase(dbtype, databaseName = "wheels") {
        switch (arguments.dbtype) {
            case "mysql":
                return "apt-get install -y mysql-server
mysql -e ""CREATE DATABASE #arguments.databaseName#;""
mysql -e ""CREATE USER 'wheels'@'localhost' IDENTIFIED BY 'wheels_password';""
mysql -e ""GRANT ALL ON #arguments.databaseName#.* TO 'wheels'@'localhost';""";
            case "postgres":
                return "apt-get install -y postgresql postgresql-contrib
sudo -u postgres createdb #arguments.databaseName#
sudo -u postgres psql -c ""CREATE USER wheels WITH PASSWORD 'wheels_password';""
sudo -u postgres psql -c ""GRANT ALL PRIVILEGES ON DATABASE #arguments.databaseName# TO wheels;""";
            case "oracle":
                return "## Oracle database will be provisioned via Docker container
## User 'wheels' with password 'wheels_password' will be created automatically
## Connect to SID: ORCL or Service Name: XEPDB1";
            default:
                return "## H2 database will be created automatically";
        }
    }

    /**
     * Resolve a file path
     */
    private function resolvePath(path, baseDirectory = "") {
        // Prepend app/ to common paths if not already present
        var appPath = arguments.path;
        if (!findNoCase("app/", appPath) && !findNoCase("tests/", appPath)) {
            // Common app directories
            if (reFind("^(controllers|models|views|migrator)/", appPath)) {
                appPath = "app/" & appPath;
            }
        }

        // If path is already absolute, return it
        if (left(appPath, 1) == "/" || mid(appPath, 2, 1) == ":") {
            return appPath;
        }

        // Build absolute path from current working directory
        // Use provided base directory or fall back to expandPath
        var baseDir = len(arguments.baseDirectory) ? arguments.baseDirectory : expandPath(".");

        // Ensure we have a trailing slash
        if (right(baseDir, 1) != "/") {
            baseDir &= "/";
        }

        return baseDir & appPath;
    }
    
    // New function to handle base environment copying
    function setupFromBaseEnvironment(
        required string environment,
        required string rootPath,
        required string base,
        string template = "local",
        required string dbtype,
        string database = ""
    ) {
        try {
            var projectRoot = arguments.rootPath;
            var baseEnvFile = projectRoot & "/.env." & arguments.base;
            
            // Check if base environment exists
            if (!fileExists(baseEnvFile)) {
                return {
                    success: false,
                    error: "Base environment '" & arguments.base & "' does not exist."
                };
            }
            
            // Read base environment file
            var baseEnvContent = fileRead(baseEnvFile);
            var baseEnvConfig = parseEnvironmentFile(baseEnvContent);
            
            // Transform the parsed env config into the structure expected by createEnvironmentFile
            var newConfig = transformEnvConfigToExpectedFormat(
                baseEnvConfig, 
                arguments.environment, 
                arguments.dbtype,
                arguments.database
            );
            
            return {
                success: true,
                config: newConfig,
                message: "Environment '" & arguments.environment & "' created from base environment '" & arguments.base & "'"
            };
            
        } catch (any e) {
            return {
                success: false,
                error: "Error setting up environment from base '" & arguments.base & "': " & e.message
            };
        }
    }

    // Helper function to parse environment file content
    function parseEnvironmentFile(required string content) {
        var config = {};
        var lines = listToArray(arguments.content, chr(10));
        
        for (var line in lines) {
            line = trim(line);
            
            // Skip empty lines and comments
            if (len(line) == 0 || left(line, 1) == "##") {
                continue;
            }
            
            // Parse key=value pairs
            if (find("=", line)) {
                var key = trim(listFirst(line, "="));
                var value = trim(listRest(line, "="));
                
                // Remove quotes if present
                if ((left(value, 1) == '"' && right(value, 1) == '"') || 
                    (left(value, 1) == "'" && right(value, 1) == "'")) {
                    value = mid(value, 2, len(value) - 2);
                }
                
                config[key] = value;
            }
        }
        
        return config;
    }

    // Helper function to transform parsed env config to the format expected by createEnvironmentFile
    function transformEnvConfigToExpectedFormat(
        required struct envConfig,
        required string environment,
        required string dbtype,
        string database = ""
    ) {
        var config = {};

        // Set template type (default to local for base environments)
        config["template"] = "local";

        // Set database type and name
        config["dbtype"] = arguments.dbtype;

        // Use provided database name or fall back to base environment's name, then environment-based naming
        var databaseName = "";
        if (len(trim(arguments.database))) {
            databaseName = arguments.database;
        } else if (structKeyExists(arguments.envConfig, "DB_DATABASE")) {
            // Modify the base database name for the new environment
            var baseName = arguments.envConfig["DB_DATABASE"];
            // Replace any existing environment references with new environment
            if (find("_", baseName)) {
                databaseName = "wheels_" & arguments.environment;
            } else {
                databaseName = baseName & "_" & arguments.environment;
            }
        } else {
            databaseName = "wheels_" & arguments.environment;
        }

        config["database"] = databaseName;

        // Set port from SERVER_PORT or default
        config["port"] = structKeyExists(arguments.envConfig, "SERVER_PORT") ?
            val(arguments.envConfig["SERVER_PORT"]) : 8080;

        // Set cfengine if exists
        if (structKeyExists(arguments.envConfig, "SERVER_CFENGINE")) {
            config["cfengine"] = arguments.envConfig["SERVER_CFENGINE"];
        }

        // Create datasourceInfo structure (not "datasource") to match expected format
        if (structKeyExists(arguments.envConfig, "DB_DRIVER") ||
            structKeyExists(arguments.envConfig, "DB_HOST")) {

            config["datasourceInfo"] = {};
            config["datasourceInfo"]["driver"] = getDatabaseDriver(arguments.dbtype);
            config["datasourceInfo"]["host"] = structKeyExists(arguments.envConfig, "DB_HOST") ?
                arguments.envConfig["DB_HOST"] : "localhost";
            config["datasourceInfo"]["port"] = getDatabasePort(arguments.dbtype);
            config["datasourceInfo"]["database"] = databaseName;
            config["datasourceInfo"]["datasource"] = "wheels_" & arguments.environment;
            config["datasourceInfo"]["username"] = structKeyExists(arguments.envConfig, "DB_USER") ?
                arguments.envConfig["DB_USER"] : "wheels";
            config["datasourceInfo"]["password"] = structKeyExists(arguments.envConfig, "DB_PASSWORD") ?
                arguments.envConfig["DB_PASSWORD"] : "wheels_password";
        } else {
            // Create default datasource info based on dbtype
            config["datasourceInfo"] = {
                driver: getDatabaseDriver(arguments.dbtype),
                host: "localhost",
                port: getDatabasePort(arguments.dbtype),
                database: databaseName,
                datasource: "wheels_" & arguments.environment,
                username: "wheels",
                password: "wheels_password"
            };
        }

        return config;
    }


    /**
    * Determine environment type based on name
    */
    private function determineEnvironmentType(envName) {
        var name = lCase(arguments.envName);
        if (findNoCase("dev", name) || name == "development") return "Development";
        if (findNoCase("test", name) || name == "testing") return "Testing";
        if (findNoCase("stage", name) || name == "staging") return "Staging";
        if (findNoCase("prod", name) || name == "production") return "Production";
        if (findNoCase("qa", name)) return "QA";
        return "Custom";
    }

    /**
    * Filter environments based on criteria
    */
    private function filterEnvironments(environments, filter) {
        var filtered = [];
        var envName = lCase(arguments.filter);
        
        for (var env in arguments.environments) {
            var include = false;
            
            switch(envName) {
                case "local":
                    include = (env.TEMPLATE == "local");
                    break;
                case "development":
                    include = (env.TYPE == "Development");
                    break;
                case "testing":
                    include = (env.TYPE == "Testing");
                    break;
                case "staging":
                    include = (env.TYPE == "Staging");
                    break;
                case "production":
                    include = (env.TYPE == "Production");
                    break;
                case "qa":
                    include = (env.TYPE == "QA");
                    break;
                case "file":
                    include = (env.SOURCE == "file");
                    break;
                case "server.json":
                    include = (env.SOURCE == "server.json");
                    break;
                case "valid":
                    include = (env.STATUS == "valid");
                    break;
                case "issues":
                    include = (env.STATUS != "valid");
                    break;
                default:
                    // Pattern matching with wildcards - ColdFusion compatible
                    if (find("*", arguments.filter)) {
                        // Remove surrounding quotes if present
                        var cleanFilter = trim(arguments.filter);
                        if ((left(cleanFilter, 1) eq '"' and right(cleanFilter, 1) eq '"') or 
                            (left(cleanFilter, 1) eq "'" and right(cleanFilter, 1) eq "'")) {
                            cleanFilter = mid(cleanFilter, 2, len(cleanFilter) - 2);
                        }
                        
                        // Replace multiple consecutive asterisks with single asterisk first
                        cleanFilter = reReplace(cleanFilter, "\*+", "*", "all");
                        
                        // Then replace single asterisks with regex wildcard
                        var pattern = replace(cleanFilter, "*", ".*", "all");
                        
                        include = reFindNoCase(pattern, env.NAME) gt 0;
                    } else {
                        include = true;
                    }
            }
            
            if (include) {
                arrayAppend(filtered, env);
            }
        }
        
        return filtered;
    }
    /**
    * Sort environments
    */
    private function sortEnvironments(environments, sortBy) {
        var sorted = duplicate(arguments.environments);
        sortBy = arguments.sortBy;
        
        arraySort(sorted, function(a, b) {
            switch(lCase(sortBy)) {
                case "name":
                    return compareNoCase(a.NAME, b.NAME);
                case "type":
                    return compareNoCase(a.TYPE, b.TYPE);
                case "modified":
                case "created":
                    return dateCompare(b.CREATED, a.CREATED); // Newest first
                default:
                    return compareNoCase(a.NAME, b.NAME);
            }
        });
        
        return sorted;
    }






    /**
    * Validate environment configuration
    */
    private function validateEnvironment(config, rootPath, envName) {
        var errors = [];
        var isValid = true;
        
        // Check required fields
        var requiredFields = ["DB_TYPE", "DB_DATABASE"];
        for (var field in requiredFields) {
            if (!structKeyExists(arguments.config, field) || !len(trim(arguments.config[field]))) {
                arrayAppend(errors, "Missing required field: #field#");
                isValid = false;
            }
        }
        
        // Check database type
        if (structKeyExists(arguments.config, "DB_TYPE")) {
            var validTypes = ["mysql", "postgres", "mssql", "h2", "sqlite", "oracle"];
            var dbTypeFound = false;
            for (var validType in validTypes) {
                if (lCase(arguments.config.DB_TYPE) == validType) {
                    dbTypeFound = true;
                    break;
                }
            }
            if (!dbTypeFound) {
                arrayAppend(errors, "Invalid database type: #arguments.config.DB_TYPE#");
                isValid = false;
            }
        }
        
        // Check if settings file exists
        var settingsFile = "#arguments.rootPath#/config/#arguments.envName#/settings.cfm";
        if (!fileExists(settingsFile)) {
            arrayAppend(errors, "Settings file not found: /config/#arguments.envName#/settings.cfm");
        }
        
        return {
            isValid: isValid,
            errors: errors
        };
    }

    /**
    * Validate server.json environment
    */
    private function validateServerJsonEnvironment(envConfig) {
        var errors = [];
        var isValid = true;
        
        if (!isStruct(arguments.envConfig)) {
            arrayAppend(errors, "Environment configuration must be a struct");
            isValid = false;
        } else if (structCount(arguments.envConfig) == 0) {
            arrayAppend(errors, "Environment configuration is empty");
            isValid = false;
        }
        
        return {
            isValid: isValid,
            errors: errors
        };
    }

    /**
    * Get help information
    */
    private function getHelpInformation() {
        var help = [];
        arrayAppend(help, "wheels env list - List available environments");
        arrayAppend(help, "");
        arrayAppend(help, "Options:");
        arrayAppend(help, "  --format <format>       Output format (table, json, yaml) [default: table]");
        arrayAppend(help, "  --verbose              Show detailed configuration");
        arrayAppend(help, "  --check                Validate environment configurations");
        arrayAppend(help, "  --filter <type>        Filter by environment type");
        arrayAppend(help, "  --sort <field>         Sort by (name, type, modified) [default: name]");
        arrayAppend(help, "  --help                 Show this help information");
        arrayAppend(help, "");
        arrayAppend(help, "Filter options:");
        arrayAppend(help, "  All                    Show all environments (default)");
        arrayAppend(help, "  local                  Local environments only");
        arrayAppend(help, "  development            Development environments");
        arrayAppend(help, "  staging                Staging environments");
        arrayAppend(help, "  production             Production environments");
        arrayAppend(help, "  file                   File-based environments");
        arrayAppend(help, "  server.json            Server.json environments");
        arrayAppend(help, "  valid                  Valid environments only");
        arrayAppend(help, "  issues                 Environments with issues");
        arrayAppend(help, "");
        arrayAppend(help, "Examples:");
        arrayAppend(help, "  wheels env list");
        arrayAppend(help, "  wheels env list --verbose");
        arrayAppend(help, "  wheels env list --format json");
        arrayAppend(help, "  wheels env list --filter production --check");
        arrayAppend(help, "  wheels env list --sort modified --verbose");
        
        return arrayToList(help, chr(10));
    }


    /**
    * Gets the current environment using the same logic as Application.cfc
    * @projectRoot The root directory of the CFWheels project
    * @return String The current environment name, or empty string if not found
    */
    public function getCurrentEnvironment(projectRoot) {
        var currentEnv = "";

        // Use current directory if projectRoot not provided
        if (!len(projectRoot)) {
            projectRoot = getCurrentDirectory();
        }

        // First, try to read from .env file (same as this.env in Application.cfc)
        var envFilePath = projectRoot & "/.env";
        if (fileExists(envFilePath)) {
            var envContent = fileRead(envFilePath);
            var matches = reMatchNoCase("WHEELS_ENV\s*=\s*([^\r\n]+)", envContent);
            if (arrayLen(matches)) {
                currentEnv = trim(matches[1]);
                // Remove quotes if present and remove key name "wheels_env="
                currentEnv = reReplace(currentEnv, "^([""']|wheels_env=)|([""'])$", "", "all");
            }
        }

        return currentEnv;
    }

    /**
     * Update the environment value in /config/environment.cfm
     * This ensures set(environment="...") matches the current environment
     */
    private function updateEnvironmentInSettingsFile(required string environment, required string projectRoot) {
        try {
            var environmentFile = "#arguments.projectRoot#/config/environment.cfm";

            // Check if environment.cfm exists
            if (!fileExists(environmentFile)) {
                return; // File doesn't exist, nothing to update
            }

            // Read current environment.cfm content
            var content = fileRead(environmentFile);

            // Update the set(environment="...") line
            // Match both set(environment="...") and set(environment = "...")
            var pattern = 'set\s*\(\s*environment\s*=\s*[""'']([^""'']+)[""'']\s*\)';
            var replacement = 'set(environment="#arguments.environment#")';

            // Replace the environment setting
            content = reReplaceNoCase(content, pattern, replacement, "all");

            // Write back to file
            fileWrite(environmentFile, content);

        } catch (any e) {
            // Non-critical error - settings file update is optional
            // Don't throw, just continue
        }
    }

    /**
     * Update only database variables in an existing environment file
     * Preserves all other settings like WHEELS_DEBUG, WHEELS_CACHE, SERVER_PORT, etc.
     */
    private struct function updateDatabaseVariablesOnly(
        required string envFile,
        required string environment,
        required string dbtype,
        required string database,
        required string datasource,
        required string host,
        required string port,
        required string username,
        required string password,
        required string sid
    ) {
        try {
            // Read existing environment file
            var envContent = fileRead(arguments.envFile);
            var envLines = listToArray(envContent, chr(10));
            var updatedLines = [];
            var dbVarsFound = {
                DB_TYPE: false,
                DB_HOST: false,
                DB_PORT: false,
                DB_DATABASE: false,
                DB_USER: false,
                DB_PASSWORD: false,
                DB_SID: false,
                DB_DATASOURCE: false
            };
            var inDatabaseSection = false;
            var databaseSectionEnd = 0;

            // Process each line
            for (var i = 1; i <= arrayLen(envLines); i++) {
                var line = envLines[i];
                var trimmedLine = trim(line);

                // Track if we're in the database section
                if (findNoCase("## Database Settings", trimmedLine)) {
                    inDatabaseSection = true;
                    arrayAppend(updatedLines, line);
                    continue;
                }

                // Track when database section ends (next section starts)
                if (inDatabaseSection && findNoCase("##", trimmedLine) && !findNoCase("## Database", trimmedLine)) {
                    inDatabaseSection = false;
                    databaseSectionEnd = arrayLen(updatedLines);
                }

                // Update DB_TYPE
                if (findNoCase("DB_TYPE=", trimmedLine) == 1) {
                    dbVarsFound.DB_TYPE = true;
                    arrayAppend(updatedLines, "DB_TYPE=#arguments.dbtype#");
                    continue;
                }

                // Update DB_HOST
                if (findNoCase("DB_HOST=", trimmedLine) == 1) {
                    dbVarsFound.DB_HOST = true;
                    if (len(trim(arguments.host))) {
                        arrayAppend(updatedLines, "DB_HOST=#arguments.host#");
                    }
                    continue;
                }

                // Update DB_PORT
                if (findNoCase("DB_PORT=", trimmedLine) == 1) {
                    dbVarsFound.DB_PORT = true;
                    if (len(trim(arguments.port))) {
                        arrayAppend(updatedLines, "DB_PORT=#arguments.port#");
                    }
                    continue;
                }

                // Update DB_DATABASE
                if (findNoCase("DB_DATABASE=", trimmedLine) == 1) {
                    dbVarsFound.DB_DATABASE = true;
                    var dbName = len(trim(arguments.database)) ? arguments.database : "wheels_#arguments.environment#";
                    arrayAppend(updatedLines, "DB_DATABASE=#dbName#");
                    continue;
                }

                // Update DB_USER
                if (findNoCase("DB_USER=", trimmedLine) == 1) {
                    dbVarsFound.DB_USER = true;
                    arrayAppend(updatedLines, "DB_USER=#arguments.username#");
                    continue;
                }

                // Update DB_PASSWORD
                if (findNoCase("DB_PASSWORD=", trimmedLine) == 1) {
                    dbVarsFound.DB_PASSWORD = true;
                    arrayAppend(updatedLines, "DB_PASSWORD=#arguments.password#");
                    continue;
                }

                // Update DB_SID (Oracle only)
                if (findNoCase("DB_SID=", trimmedLine) == 1) {
                    dbVarsFound.DB_SID = true;
                    if (lCase(arguments.dbtype) == "oracle" && len(trim(arguments.sid))) {
                        arrayAppend(updatedLines, "DB_SID=#arguments.sid#");
                    }
                    continue;
                }

                // Update DB_DATASOURCE
                if (findNoCase("DB_DATASOURCE=", trimmedLine) == 1) {
                    dbVarsFound.DB_DATASOURCE = true;
                    var dsName = len(trim(arguments.datasource)) ? arguments.datasource : "wheels_#arguments.environment#";
                    arrayAppend(updatedLines, "DB_DATASOURCE=#dsName#");
                    continue;
                }

                // Preserve all other lines (including comments, blank lines, and other variables)
                arrayAppend(updatedLines, line);
            }

            // Add missing database variables after the database section
            var missingVars = [];

            if (!dbVarsFound.DB_TYPE) {
                arrayAppend(missingVars, "DB_TYPE=#arguments.dbtype#");
            }

            if (!dbVarsFound.DB_HOST && len(trim(arguments.host))) {
                arrayAppend(missingVars, "DB_HOST=#arguments.host#");
            }

            if (!dbVarsFound.DB_PORT && len(trim(arguments.port))) {
                arrayAppend(missingVars, "DB_PORT=#arguments.port#");
            }

            if (!dbVarsFound.DB_DATABASE) {
                var dbName = len(trim(arguments.database)) ? arguments.database : "wheels_#arguments.environment#";
                arrayAppend(missingVars, "DB_DATABASE=#dbName#");
            }

            if (!dbVarsFound.DB_USER) {
                arrayAppend(missingVars, "DB_USER=#arguments.username#");
            }

            if (!dbVarsFound.DB_PASSWORD) {
                arrayAppend(missingVars, "DB_PASSWORD=#arguments.password#");
            }

            if (!dbVarsFound.DB_SID && lCase(arguments.dbtype) == "oracle" && len(trim(arguments.sid))) {
                arrayAppend(missingVars, "DB_SID=#arguments.sid#");
            }

            if (!dbVarsFound.DB_DATASOURCE) {
                var dsName = len(trim(arguments.datasource)) ? arguments.datasource : "wheels_#arguments.environment#";
                arrayAppend(missingVars, "DB_DATASOURCE=#dsName#");
            }

            // Insert missing variables into the appropriate section
            if (arrayLen(missingVars) > 0) {
                // If we found a database section, add missing vars there
                if (databaseSectionEnd > 0) {
                    // Insert missing vars after database section header
                    for (var i = arrayLen(missingVars); i >= 1; i--) {
                        arrayInsertAt(updatedLines, databaseSectionEnd + 1, missingVars[i]);
                    }
                } else {
                    // No database section exists, create one before server settings
                    var insertPoint = 0;
                    for (var i = 1; i <= arrayLen(updatedLines); i++) {
                        if (findNoCase("## Server Settings", updatedLines[i])) {
                            insertPoint = i;
                            break;
                        }
                    }

                    if (insertPoint > 0) {
                        arrayInsertAt(updatedLines, insertPoint, "");
                        arrayInsertAt(updatedLines, insertPoint + 1, "## Database Settings");
                        var offset = 2;
                        for (var varLine in missingVars) {
                            arrayInsertAt(updatedLines, insertPoint + offset, varLine);
                            offset++;
                        }
                        arrayInsertAt(updatedLines, insertPoint + offset, "");
                    } else {
                        // Just append to end if no server section found
                        arrayAppend(updatedLines, "");
                        arrayAppend(updatedLines, "## Database Settings");
                        for (var varLine in missingVars) {
                            arrayAppend(updatedLines, varLine);
                        }
                        arrayAppend(updatedLines, "");
                    }
                }
            }

            // Write updated content back to file
            fileWrite(arguments.envFile, arrayToList(updatedLines, chr(10)));

            // Build datasource info for response
            var dbName = len(trim(arguments.database)) ? arguments.database : "wheels_#arguments.environment#";
            var dsName = len(trim(arguments.datasource)) ? arguments.datasource : "wheels_#arguments.environment#";

            return {
                success: true,
                message: "Database variables updated successfully in environment '#arguments.environment#'",
                config: {
                    datasourceInfo: {
                        database: dbName,
                        datasource: dsName,
                        dbtype: arguments.dbtype,
                        host: arguments.host,
                        port: arguments.port,
                        username: arguments.username
                    }
                },
                nextSteps: [
                    "Database credentials updated in .env.#arguments.environment#",
                    "Restart your server to apply changes: server restart"
                ]
            };

        } catch (any e) {
            return {
                success: false,
                error: "Failed to update database variables: #e.message#"
            };
        }
    }

}