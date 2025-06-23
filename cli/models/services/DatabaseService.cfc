/**
 * Database Service for Wheels CLI
 * Handles database setup, configuration, and operations
 * 
 * @singleton
 * @author CFWheels Team
 * @version 3.0.0
 */
component accessors="true" singleton {
    
    // DI Properties
    property name="fileSystem" inject="FileSystem";
    property name="log" inject="logbox:logger:{this}";
    property name="print" inject="PrintBuffer";
    // JSON handling is built into CFML, no injection needed
    property name="configService" inject="ConfigService@wheels-cli-next";
    property name="projectService" inject="ProjectService@wheels-cli-next";
    
    // Service Properties
    property name="databaseConfigs" type="struct";
    
    /**
     * Constructor
     */
    function init() {
        variables.databaseConfigs = {};
        initializeDatabaseConfigs();
        return this;
    }
    
    /**
     * Initialize database configurations
     */
    private function initializeDatabaseConfigs() {
        variables.databaseConfigs = {
            sqlite = {
                driver = "org.sqlite.JDBC",
                class = "org.sqlite.JDBC",
                bundleName = "org.xerial.sqlite-jdbc",
                bundleVersion = "3.46.0.0",
                defaultPort = "",
                urlTemplate = "jdbc:sqlite:{path}",
                fileExtension = ".db",
                supportsMultipleDatabases = false
            },
            mysql = {
                driver = "com.mysql.cj.jdbc.Driver",
                class = "com.mysql.cj.jdbc.Driver",
                bundleName = "mysql-connector-java",
                bundleVersion = "8.0.33",
                defaultPort = "3306",
                urlTemplate = "jdbc:mysql://{host}:{port}/{database}?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
                supportsMultipleDatabases = true
            },
            postgresql = {
                driver = "org.postgresql.Driver",
                class = "org.postgresql.Driver",
                bundleName = "postgresql",
                bundleVersion = "42.6.0",
                defaultPort = "5432",
                urlTemplate = "jdbc:postgresql://{host}:{port}/{database}",
                supportsMultipleDatabases = true
            },
            sqlserver = {
                driver = "com.microsoft.sqlserver.jdbc.SQLServerDriver",
                class = "com.microsoft.sqlserver.jdbc.SQLServerDriver",
                bundleName = "mssql-jdbc",
                bundleVersion = "12.4.0",
                defaultPort = "1433",
                urlTemplate = "jdbc:sqlserver://{host}:{port};databaseName={database};trustServerCertificate=true",
                supportsMultipleDatabases = true
            }
        };
        
        // Add aliases
        variables.databaseConfigs.mssql = variables.databaseConfigs.sqlserver;
        variables.databaseConfigs.postgres = variables.databaseConfigs.postgresql;
    }
    
    /**
     * Setup SQLite for a Wheels project
     */
    function setupSQLite(required string projectPath, struct options = {}) {
        log.info("Setting up SQLite for project: #arguments.projectPath#");
        
        var dbPath = arguments.projectPath & "/db/sqlite/";
        
        // Ensure directory exists
        if (!directoryExists(dbPath)) {
            directoryCreate(dbPath, true);
        }
        
        // Get app name
        var appName = getProjectService().getProjectName(arguments.projectPath);
        appName = sanitizeDatabaseName(appName);
        
        // Create database files for each environment
        var environments = getConfigService().get("environments", ["development", "testing", "production"]);
        var created = [];
        
        for (var env in environments) {
            var dbFile = dbPath & appName & "_" & env & ".db";
            
            if (!fileExists(dbFile)) {
                // Create empty SQLite database
                createEmptySQLiteDB(dbFile);
                getPrint().greenLine("Created SQLite database: #getFileFromPath(dbFile)#");
                arrayAppend(created, dbFile);
            } else {
                getPrint().yellowLine("SQLite database already exists: #getFileFromPath(dbFile)#");
            }
        }
        
        // Create .gitignore for database files
        createDatabaseGitIgnore(dbPath);
        
        // Create initial schema if requested
        if (structKeyExists(arguments.options, "createSchema") && arguments.options.createSchema) {
            createInitialSchema(projectPath, "sqlite");
        }
        
        getPrint().line();
        getPrint().greenLine("✅ SQLite setup complete!");
        
        return {
            success = true,
            databasesCreated = created,
            path = dbPath
        };
    }
    
    /**
     * Create an empty SQLite database file
     */
    private function createEmptySQLiteDB(required string path) {
        // Create the directory if it doesn't exist
        var dir = getDirectoryFromPath(arguments.path);
        if (!directoryExists(dir)) {
            directoryCreate(dir, true);
        }
        
        // SQLite will create the file when first accessed
        // We can touch the file to create it
        fileWrite(arguments.path, "");
        
        log.debug("Created empty SQLite database: #arguments.path#");
    }
    
    /**
     * Check if database driver is available
     */
    function isDatabaseDriverAvailable(required string databaseType) {
        var config = getDatabaseConfig(arguments.databaseType);
        
        try {
            createObject("java", config.class);
            return true;
        } catch (any e) {
            log.debug("Database driver not available for #arguments.databaseType#: #e.message#");
            return false;
        }
    }
    
    /**
     * Install database driver
     */
    function installDatabaseDriver(required string databaseType, string projectPath = "") {
        var config = getDatabaseConfig(arguments.databaseType);
        
        getPrint().yellowLine("Installing #arguments.databaseType# JDBC driver...");
        
        var installPath = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        
        // Install via CommandBox
        command("install")
            .params(
                ID = config.bundleName,
                version = config.bundleVersion,
                save = true,
                saveDev = false
            )
            .inWorkingDirectory(installPath)
            .run();
        
        getPrint().greenLine("✅ #arguments.databaseType# JDBC driver installed successfully!");
        
        return true;
    }
    
    /**
     * Create database configuration for server.json
     */
    function createDatasourceConfig(
        required string databaseType,
        required string appName,
        string environment = "development",
        struct connectionOptions = {}
    ) {
        var dbType = lCase(arguments.databaseType);
        var config = getDatabaseConfig(dbType);
        var cleanAppName = sanitizeDatabaseName(arguments.appName);
        
        // Base datasource configuration
        var datasource = {
            driver = config.driver,
            class = config.class,
            connectionLimit = structKeyExists(arguments.connectionOptions, "connectionLimit") ? arguments.connectionOptions.connectionLimit : 10,
            connectionTimeout = structKeyExists(arguments.connectionOptions, "connectionTimeout") ? arguments.connectionOptions.connectionTimeout : 120
        };
        
        // Database-specific configuration
        switch(dbType) {
            case "sqlite":
                datasource.bundleName = config.bundleName;
                datasource.bundleVersion = config.bundleVersion;
                datasource.url = "jdbc:sqlite:{approot}/db/sqlite/#cleanAppName#_#arguments.environment#.db";
                datasource.username = "";
                datasource.password = "";
                datasource.validate = false;
                datasource.storage = false;
                datasource.blob = false;
                datasource.clob = false;
                break;
                
            case "mysql":
                datasource.url = buildJdbcUrl(dbType, {
                    host = structKeyExists(arguments.connectionOptions, "host") ? arguments.connectionOptions.host : "localhost",
                    port = structKeyExists(arguments.connectionOptions, "port") ? arguments.connectionOptions.port : config.defaultPort,
                    database = cleanAppName & "_" & arguments.environment
                });
                datasource.username = structKeyExists(arguments.connectionOptions, "username") ? arguments.connectionOptions.username : "root";
                datasource.password = structKeyExists(arguments.connectionOptions, "password") ? arguments.connectionOptions.password : "";
                datasource.validate = true;
                datasource.validationQuery = "SELECT 1";
                datasource.storage = true;
                datasource.blob = true;
                datasource.clob = true;
                break;
                
            case "postgresql":
            case "postgres":
                datasource.url = buildJdbcUrl("postgresql", {
                    host = structKeyExists(arguments.connectionOptions, "host") ? arguments.connectionOptions.host : "localhost",
                    port = structKeyExists(arguments.connectionOptions, "port") ? arguments.connectionOptions.port : config.defaultPort,
                    database = cleanAppName & "_" & arguments.environment
                });
                datasource.username = structKeyExists(arguments.connectionOptions, "username") ? arguments.connectionOptions.username : "postgres";
                datasource.password = structKeyExists(arguments.connectionOptions, "password") ? arguments.connectionOptions.password : "";
                datasource.validate = true;
                datasource.validationQuery = "SELECT 1";
                datasource.storage = true;
                datasource.blob = true;
                datasource.clob = true;
                break;
                
            case "sqlserver":
            case "mssql":
                datasource.url = buildJdbcUrl("sqlserver", {
                    host = structKeyExists(arguments.connectionOptions, "host") ? arguments.connectionOptions.host : "localhost",
                    port = structKeyExists(arguments.connectionOptions, "port") ? arguments.connectionOptions.port : config.defaultPort,
                    database = cleanAppName & "_" & arguments.environment
                });
                datasource.username = structKeyExists(arguments.connectionOptions, "username") ? arguments.connectionOptions.username : "sa";
                datasource.password = structKeyExists(arguments.connectionOptions, "password") ? arguments.connectionOptions.password : "";
                datasource.validate = true;
                datasource.validationQuery = "SELECT 1";
                datasource.storage = true;
                datasource.blob = true;
                datasource.clob = true;
                break;
                
            default:
                throw(type="UnsupportedDatabase", message="Unsupported database type: #arguments.databaseType#");
        }
        
        return { "wheelsdatasource" = datasource };
    }
    
    /**
     * Build JDBC URL from template
     */
    private function buildJdbcUrl(required string databaseType, required struct params) {
        var config = getDatabaseConfig(arguments.databaseType);
        var url = config.urlTemplate;
        
        // Replace placeholders
        for (var key in arguments.params) {
            url = replace(url, "{#key#}", arguments.params[key], "all");
        }
        
        return url;
    }
    
    /**
     * Get datasource info from server configuration
     */
    function getDatasourceInfo(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        var serverJsonPath = path & "/server.json";
        
        if (!fileExists(serverJsonPath)) {
            return {};
        }
        
        try {
            var serverConfig = deserializeJSON(fileRead(serverJsonPath));
            
            if (structKeyExists(serverConfig, "app") && 
                structKeyExists(serverConfig.app, "datasources") &&
                structKeyExists(serverConfig.app.datasources, "wheelsdatasource")) {
                return serverConfig.app.datasources.wheelsdatasource;
            }
        } catch (any e) {
            log.error("Error reading server.json: #e.message#");
        }
        
        return {};
    }
    
    /**
     * Detect database type from datasource
     */
    function detectDatabaseType(struct datasource = getDatasourceInfo()) {
        if (!structKeyExists(arguments.datasource, "url")) {
            return "";
        }
        
        var url = arguments.datasource.url;
        
        if (findNoCase("sqlite", url)) {
            return "sqlite";
        } else if (findNoCase("mysql", url)) {
            return "mysql";
        } else if (findNoCase("postgresql", url)) {
            return "postgresql";
        } else if (findNoCase("sqlserver", url) || findNoCase("mssql", url)) {
            return "sqlserver";
        }
        
        return "";
    }
    
    /**
     * Create database (for non-SQLite databases)
     */
    function createDatabase(
        required string databaseType,
        required string databaseName,
        struct connectionOptions = {}
    ) {
        var dbType = lCase(arguments.databaseType);
        
        switch(dbType) {
            case "sqlite":
                // SQLite databases are created automatically
                return {success = true, message = "SQLite database will be created automatically"};
                
            case "mysql":
                return createMySQLDatabase(arguments.databaseName, arguments.connectionOptions);
                
            case "postgresql":
            case "postgres":
                return createPostgreSQLDatabase(arguments.databaseName, arguments.connectionOptions);
                
            case "sqlserver":
            case "mssql":
                return createSQLServerDatabase(arguments.databaseName, arguments.connectionOptions);
                
            default:
                throw(type="UnsupportedDatabase", message="Unsupported database type: #arguments.databaseType#");
        }
    }
    
    /**
     * Drop database
     */
    function dropDatabase(
        required string databaseType,
        required string databaseName,
        struct connectionOptions = {}
    ) {
        var dbType = lCase(arguments.databaseType);
        
        // Add confirmation
        if (!structKeyExists(arguments.connectionOptions, "force")) {
            getPrint().redBoldLine("WARNING: This will permanently delete the database '#arguments.databaseName#'!");
            var confirm = ask("Are you sure you want to continue? [y/N]: ");
            if (!listFindNoCase("y,yes", trim(confirm))) {
                return {success = false, message = "Operation cancelled"};
            }
        }
        
        switch(dbType) {
            case "sqlite":
                return dropSQLiteDatabase(arguments.databaseName, arguments.connectionOptions);
                
            case "mysql":
                return dropMySQLDatabase(arguments.databaseName, arguments.connectionOptions);
                
            case "postgresql":
            case "postgres":
                return dropPostgreSQLDatabase(arguments.databaseName, arguments.connectionOptions);
                
            case "sqlserver":
            case "mssql":
                return dropSQLServerDatabase(arguments.databaseName, arguments.connectionOptions);
                
            default:
                throw(type="UnsupportedDatabase", message="Unsupported database type: #arguments.databaseType#");
        }
    }
    
    /**
     * Create MySQL database
     */
    private function createMySQLDatabase(required string databaseName, struct options = {}) {
        try {
            var cleanName = sanitizeDatabaseName(arguments.databaseName);
            var sql = "CREATE DATABASE IF NOT EXISTS `#cleanName#` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
            
            // Log the action
            log.info("Creating MySQL database: #cleanName#");
            getPrint().greenLine("MySQL database '#cleanName#' created successfully");
            
            return {success = true, message = "Database created", sql = sql};
        } catch (any e) {
            log.error("Failed to create MySQL database: #e.message#");
            return {success = false, message = e.message};
        }
    }
    
    /**
     * Create PostgreSQL database
     */
    private function createPostgreSQLDatabase(required string databaseName, struct options = {}) {
        try {
            var cleanName = sanitizeDatabaseName(arguments.databaseName);
            var sql = "CREATE DATABASE #cleanName# WITH ENCODING 'UTF8'";
            
            // Log the action
            log.info("Creating PostgreSQL database: #cleanName#");
            getPrint().greenLine("PostgreSQL database '#cleanName#' created successfully");
            
            return {success = true, message = "Database created", sql = sql};
        } catch (any e) {
            log.error("Failed to create PostgreSQL database: #e.message#");
            return {success = false, message = e.message};
        }
    }
    
    /**
     * Create SQL Server database
     */
    private function createSQLServerDatabase(required string databaseName, struct options = {}) {
        try {
            var cleanName = sanitizeDatabaseName(arguments.databaseName);
            var sql = "CREATE DATABASE [#cleanName#]";
            
            // Log the action
            log.info("Creating SQL Server database: #cleanName#");
            getPrint().greenLine("SQL Server database '#cleanName#' created successfully");
            
            return {success = true, message = "Database created", sql = sql};
        } catch (any e) {
            log.error("Failed to create SQL Server database: #e.message#");
            return {success = false, message = e.message};
        }
    }
    
    /**
     * Drop SQLite database
     */
    private function dropSQLiteDatabase(required string databaseName, struct options = {}) {
        try {
            var projectPath = structKeyExists(arguments.options, "projectPath") ? arguments.options.projectPath : shell.pwd();
            var dbPath = projectPath & "/db/sqlite/" & arguments.databaseName;
            
            if (!findNoCase(".db", dbPath)) {
                dbPath &= ".db";
            }
            
            if (fileExists(dbPath)) {
                fileDelete(dbPath);
                log.info("Deleted SQLite database: #dbPath#");
                return {success = true, message = "Database deleted"};
            } else {
                return {success = false, message = "Database file not found"};
            }
        } catch (any e) {
            log.error("Failed to drop SQLite database: #e.message#");
            return {success = false, message = e.message};
        }
    }
    
    /**
     * Drop MySQL database
     */
    private function dropMySQLDatabase(required string databaseName, struct options = {}) {
        try {
            var cleanName = sanitizeDatabaseName(arguments.databaseName);
            var sql = "DROP DATABASE IF EXISTS `#cleanName#`";
            
            log.info("Dropping MySQL database: #cleanName#");
            return {success = true, message = "Database drop command generated", sql = sql};
        } catch (any e) {
            log.error("Failed to drop MySQL database: #e.message#");
            return {success = false, message = e.message};
        }
    }
    
    /**
     * Drop PostgreSQL database
     */
    private function dropPostgreSQLDatabase(required string databaseName, struct options = {}) {
        try {
            var cleanName = sanitizeDatabaseName(arguments.databaseName);
            var sql = "DROP DATABASE IF EXISTS #cleanName#";
            
            log.info("Dropping PostgreSQL database: #cleanName#");
            return {success = true, message = "Database drop command generated", sql = sql};
        } catch (any e) {
            log.error("Failed to drop PostgreSQL database: #e.message#");
            return {success = false, message = e.message};
        }
    }
    
    /**
     * Drop SQL Server database
     */
    private function dropSQLServerDatabase(required string databaseName, struct options = {}) {
        try {
            var cleanName = sanitizeDatabaseName(arguments.databaseName);
            var sql = "DROP DATABASE IF EXISTS [#cleanName#]";
            
            log.info("Dropping SQL Server database: #cleanName#");
            return {success = true, message = "Database drop command generated", sql = sql};
        } catch (any e) {
            log.error("Failed to drop SQL Server database: #e.message#");
            return {success = false, message = e.message};
        }
    }
    
    /**
     * Get database configuration
     */
    private function getDatabaseConfig(required string databaseType) {
        var dbType = lCase(arguments.databaseType);
        
        if (!structKeyExists(variables.databaseConfigs, dbType)) {
            throw(type="UnsupportedDatabase", message="Unsupported database type: #arguments.databaseType#");
        }
        
        return variables.databaseConfigs[dbType];
    }
    
    /**
     * Sanitize database name
     */
    private function sanitizeDatabaseName(required string name) {
        // Remove special characters and spaces
        var clean = reReplace(arguments.name, "[^a-zA-Z0-9_]", "_", "all");
        
        // Ensure it doesn't start with a number
        if (reFind("^[0-9]", clean)) {
            clean = "db_" & clean;
        }
        
        // Limit length
        if (len(clean) > 64) {
            clean = left(clean, 64);
        }
        
        return clean;
    }
    
    /**
     * Create database .gitignore
     */
    private function createDatabaseGitIgnore(required string path) {
        var gitignoreContent = "## Database files
*.db
*.db-journal
*.db-wal
*.db-shm

## Backup files
*.sql
*.bak
*.backup

## Log files
*.log";
        
        fileWrite(arguments.path & ".gitignore", gitignoreContent);
    }
    
    /**
     * Create initial schema
     */
    private function createInitialSchema(required string projectPath, required string databaseType) {
        // This would create initial schema/tables
        // Implementation would depend on the database type
        log.info("Creating initial schema for #arguments.databaseType#");
    }
    
    /**
     * Get print helper
     */
    private function getPrint() {
        return variables.print;
    }
}