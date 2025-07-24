component {

    property name="serverService" inject="ServerService";
    property name="templateService" inject="TemplateService@wheels-cli";

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
        boolean force = false,
        string base = "",
        boolean debug = false,
        boolean cache = false,
        string reloadPassword = "",
        boolean help = false
    ) {


        try {
            var projectRoot = arguments.rootPath;

            // Check if environment already exists
            var envFile = projectRoot & ".env." & arguments.environment;
            
            if (fileExists(envFile) && !arguments.force) {
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
                // Create environment file
                createEnvironmentFile(arguments.environment, result.config, projectRoot);
                createEnvironmentSettings(argumentCollection = arguments, config = result.config, rootPath = projectRoot);

                // Update server.json if needed
                updateServerConfig(arguments.environment, result.config, projectRoot);

                result.nextSteps = generateNextSteps(arguments.template, arguments.environment);
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
                    DATABASE: structKeyExists(config, "DB_NAME") ? config.DB_NAME : "unknown",
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
                            DATABASE: structKeyExists(envConfig, "DB_NAME") ? envConfig.DB_NAME : "configured",
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

        // Format output based on requested format
        return formatEnvironmentOutput(environments, arguments.format, arguments.verbose, currentEnv);
    }

    /**
     * Switch to a different environment
     */
    function switch(required string environment, required string rootPath) {
        var projectRoot = arguments.rootPath;
        var envFile = "#projectRoot#.env.#arguments.environment#";

        if (!fileExists(envFile)) {
            return {
                success: false,
                error: "Environment '#arguments.environment#' not found"
            };
        }

        // Copy environment file to .env
        fileCopy(envFile, "#projectRoot#.env");

        // Update server.json default environment
        var serverJsonPath = "#projectRoot#server.json";
        if (fileExists(serverJsonPath)) {
            var serverJson = deserializeJSON(fileRead(serverJsonPath));
            serverJson.profile = arguments.environment;
            fileWrite(serverJsonPath, serializeJSON(serverJson, true));
        }

        return {
            success: true,
            message: "Switched to '#arguments.environment#' environment"
        };
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

        // Database-specific configuration
        switch (arguments.dbtype) {
            case "mysql":
                config.datasourceInfo = {
                    driver: "MySQL",
                    host: "localhost",
                    port: 3306,
                    database: databaseName,
                    datasource: datasourceName,
                    username: "wheels",
                    password: "wheels_password"
                };
                break;
            case "postgres":
                config.datasourceInfo = {
                    driver: "PostgreSQL",
                    host: "localhost",
                    port: 5432,
                    database: databaseName,
                    datasource: datasourceName,
                    username: "wheels",
                    password: "wheels_password"
                };
                break;
            case "mssql":
                config.datasourceInfo = {
                    driver: "MSSQL",
                    host: "localhost",
                    port: 1433,
                    database: databaseName,
                    datasource: datasourceName,
                    username: "sa",
                    password: "Wheels_Pass123!"
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
                    username: "sa",
                    password: ""
                };
        }

        return {
            success: true,
            config: config
        };
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

        // Database settings
        if (arguments.config.keyExists("datasourceInfo")) {
            arrayAppend(envContent, "## Database Settings");
            arrayAppend(envContent, "DB_TYPE=#arguments.config.dbtype#");
            arrayAppend(envContent, "DB_DRIVER=#arguments.config.datasourceInfo.driver#");
            arrayAppend(envContent, "DB_HOST=#arguments.config.datasourceInfo.host#");
            arrayAppend(envContent, "DB_PORT=#arguments.config.datasourceInfo.port#");
            arrayAppend(envContent, "DB_NAME=#arguments.config.datasourceInfo.database#");
            arrayAppend(envContent, "DB_USER=#arguments.config.datasourceInfo.username#");
            arrayAppend(envContent, "DB_PASSWORD=#arguments.config.datasourceInfo.password#");
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

        // Define content with dynamic debug/cache settings
        var content = '<cfscript>
    // Environment: #arguments.environment#
    // Generated: #now#
    // Debug Mode: #arguments.debug ? "Enabled" : "Disabled"#
    // Cache Mode: #arguments.cache ? "Enabled" : "Disabled"#

    // Database settings
    set(dataSourceName="#datasourceName#");

    // Environment settings
    set(environment="#arguments.environment#");
    
    // Debug settings - controlled by debug argument
    set(showDebugInformation=#arguments.debug#);
    set(showErrorInformation=#arguments.debug#);

    // Caching settings - controlled by cache argument
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
    set(urlRewriting="partial");

    // Environment-specific settings
    set(sendEmailOnError=#arguments.debug ? "false" : "true"#);
    set(errorEmailAddress="dev-team@example.com");
</cfscript>';

        // Write to settings.cfm
        fileWrite(settingsFile, content);
        
        return {
            success: true,
            message: "settings.cfm created at /config/#arguments.environment#/ with debug=#arguments.debug#, cache=#arguments.cache#"
        };
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
            serverJson.env[arguments.environment]["DB_PORT"] = ds.port;
            serverJson.env[arguments.environment]["DB_NAME"] = ds.database;
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
      - DB_NAME=#databaseName#
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
            default: return "H2";
        }
    }

    private function getDatabasePort(dbtype) {
        switch (arguments.dbtype) {
            case "mysql": return 3306;
            case "postgres": return 5432;
            case "mssql": return 1433;
            default: return 9092;
        }
    }

    private function getDatabaseImage(dbtype) {
        switch (arguments.dbtype) {
            case "mysql": return "mysql:8";
            case "postgres": return "postgres:14";
            case "mssql": return "mcr.microsoft.com/mssql/server:2019-latest";
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
            default:
                return "H2_OPTIONS=-ifNotExists";
        }
    }

    private function getDatabaseVolumeDir(dbtype) {
        switch (arguments.dbtype) {
            case "mysql": return "mysql";
            case "postgres": return "postgresql/data";
            case "mssql": return "mssql";
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
            var baseEnvFile = projectRoot & ".env." & arguments.base;
            
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
                error: e
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
        
        // Set database type and name
        config["dbtype"] = arguments.dbtype;
        
        // Use provided database name or fall back to environment-based naming
        var databaseName = len(trim(arguments.database)) ? 
            arguments.database : 
            (structKeyExists(arguments.envConfig, "DB_NAME") ? 
                arguments.envConfig["DB_NAME"] : 
                arguments.environment & "_db");
                
        config["database"] = databaseName;
        
        // Set port from SERVER_PORT or default
        config["port"] = structKeyExists(arguments.envConfig, "SERVER_PORT") ? 
            val(arguments.envConfig["SERVER_PORT"]) : 8080;
        
        // Add unique offset to avoid port conflicts
        var envHash = 0;
        for (var i = 1; i <= len(arguments.environment); i++) {
            envHash += asc(mid(arguments.environment, i, 1));
        }
        envHash = envHash mod 1000;
        config["port"] = config["port"] + envHash;
        
        // Set cfengine if exists
        if (structKeyExists(arguments.envConfig, "SERVER_CFENGINE")) {
            config["cfengine"] = arguments.envConfig["SERVER_CFENGINE"];
        }
        
        // Create datasource structure if database keys exist
        if (structKeyExists(arguments.envConfig, "DB_DRIVER") || 
            structKeyExists(arguments.envConfig, "DB_HOST")) {
            
            config["datasource"] = {};
            config["datasource"]["driver"] = getDatabaseDriver(arguments.dbtype);
            config["datasource"]["host"] = structKeyExists(arguments.envConfig, "DB_HOST") ? 
                arguments.envConfig["DB_HOST"] : "localhost";
            config["datasource"]["port"] = getDatabasePort(arguments.dbtype);
            config["datasource"]["database"] = databaseName;
            config["datasource"]["username"] = structKeyExists(arguments.envConfig, "DB_USER") ? 
                arguments.envConfig["DB_USER"] : "wheels";
            config["datasource"]["password"] = structKeyExists(arguments.envConfig, "DB_PASSWORD") ? 
                arguments.envConfig["DB_PASSWORD"] : "wheels_password";
        }
        
        // Add any other keys that don't follow the standard patterns
        for (var key in arguments.envConfig) {
            // Skip keys we've already processed
            if (!listFindNoCase("SERVER_PORT,SERVER_CFENGINE,DB_TYPE,DB_DRIVER,DB_HOST,DB_PORT,DB_NAME,DB_USER,DB_PASSWORD,WHEELS_ENV,WHEELS_RELOAD_PASSWORD", key)) {
                config[key] = arguments.envConfig[key];
            }
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
    * Format environment output
    */
    private function formatEnvironmentOutput(environments, format, verbose, currentEnv) {
        switch(lCase(arguments.format)) {
            case "json":
                return formatAsJSON(arguments.environments, arguments.currentEnv);
            
            case "yaml":
                return formatAsYAML(arguments.environments, arguments.currentEnv);
            
            case "table":
            default:
                return formatAsTable(arguments.environments, arguments.verbose, arguments.currentEnv);
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
    * Format as table
    */
    private function formatAsTable(environments, verbose, currentEnv) {
        var output = [];
        
        // Title
        arrayAppend(output, "Available Environments");
        arrayAppend(output, "=====================");
        arrayAppend(output, "");
        
        if (arrayLen(arguments.environments) == 0) {
            arrayAppend(output, "No environments configured");
            arrayAppend(output, "Create an environment with: wheels env setup <environment>");
            return arrayToList(output, chr(10));
        }
        
        if (arguments.verbose) {
            // Verbose format
            for (var env in arguments.environments) {
                var marker = env.ACTIVE ? " * " : "";
                var status = env.ACTIVE ? "[Active]" : "";
                
                arrayAppend(output, "#env.NAME##marker##status#");
                arrayAppend(output, "  Type:        #env.TYPE#");
                arrayAppend(output, "  Database:    #env.DATABASE#");
                arrayAppend(output, "  Datasource:  #env.DATASOURCE#");
                if (structKeyExists(env, "DEBUG")) {
                    arrayAppend(output, "  Debug:       #env.DEBUG == 'true' ? 'Enabled' : 'Disabled'#");
                }
                if (structKeyExists(env, "CACHE")) {
                    arrayAppend(output, "  Cache:       #env.CACHE == 'true' ? 'Enabled' : 'Disabled'#");
                }
                if (structKeyExists(env, "CONFIGPATH")) {
                    arrayAppend(output, "  Config:      #env.CONFIGPATH#");
                }
                arrayAppend(output, "  Modified:    #dateTimeFormat(env.CREATED, 'yyyy-mm-dd HH:nn:ss')#");
                if (structKeyExists(env, "VALIDATIONERRORS") && arrayLen(env.VALIDATIONERRORS)) {
                    arrayAppend(output, "  Issues:      #arrayToList(env.VALIDATIONERRORS, ', ')#");
                }
                arrayAppend(output, "");
            }
        } else {
            // Table format
            arrayAppend(output, "  NAME          TYPE         DATABASE           STATUS");
            for (var env in arguments.environments) {
                var name = env.NAME;
                var marker = env.ACTIVE ? " *" : "";
                var statusIcon = env.STATUS == "valid" ? "OK" : "WARN";
                var statusText = env.ACTIVE ? "#statusIcon# Active" : "#statusIcon# #uCase(left(env.STATUS, 1))##right(env.STATUS, len(env.STATUS) - 1)#";
                
                // Pad columns for alignment
                name = left(name & repeatString(" ", 14), 14);
                var type = left(env.TYPE & repeatString(" ", 13), 13);
                var database = left(env.DATABASE & repeatString(" ", 19), 19);
                
                arrayAppend(output, "  #name##type##database##statusText#");
            }
        }
        
        arrayAppend(output, "");
        arrayAppend(output, "* = Current environment");
        
        return arrayToList(output, chr(10));
    }

    /**
    * Validate environment configuration
    */
    private function validateEnvironment(config, rootPath, envName) {
        var errors = [];
        var isValid = true;
        
        // Check required fields
        var requiredFields = ["DB_TYPE", "DB_NAME"];
        for (var field in requiredFields) {
            if (!structKeyExists(arguments.config, field) || !len(trim(arguments.config[field]))) {
                arrayAppend(errors, "Missing required field: #field#");
                isValid = false;
            }
        }
        
        // Check database type
        if (structKeyExists(arguments.config, "DB_TYPE")) {
            var validTypes = ["mysql", "postgres", "mssql", "h2"];
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
    function getCurrentEnvironment(projectRoot) {
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
                // Remove quotes if present
                currentEnv = reReplace(currentEnv, "^[""']|[""']$", "", "all");
            }
        }

        return currentEnv;
    }

}