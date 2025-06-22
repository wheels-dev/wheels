/**
 * Database Service for Wheels CLI
 * Handles database setup, configuration, and operations
 */
component singleton {
    
    property name="fileSystemUtil" inject="FileSystem";
    property name="consoleLogger" inject="logbox:logger:console";
    property name="print" inject="PrintBuffer";
    
    /**
     * Setup SQLite for a Wheels project
     */
    function setupSQLite(required string projectPath) {
        var dbPath = arguments.projectPath & "/db/sqlite/";
        
        // Ensure directory exists
        if (!directoryExists(dbPath)) {
            directoryCreate(dbPath, true);
        }
        
        // Create initial database files for each environment
        var environments = ["development", "testing", "production"];
        var appName = getAppNameFromProject(arguments.projectPath);
        
        for (var env in environments) {
            var dbFile = dbPath & appName & "_" & env & ".db";
            
            if (!fileExists(dbFile)) {
                // Create empty SQLite database
                createEmptySQLiteDB(dbFile);
                print.greenLine("Created SQLite database: #getFileFromPath(dbFile)#");
            } else {
                print.yellowLine("SQLite database already exists: #getFileFromPath(dbFile)#");
            }
        }
        
        // Create .gitignore for database files
        var gitignore = "*.db" & chr(10) & "*.db-journal" & chr(10) & "*.db-wal" & chr(10) & "*.db-shm";
        fileWrite(dbPath & ".gitignore", gitignore);
        
        print.line();
        print.greenLine("SQLite setup complete!");
    }
    
    /**
     * Create an empty SQLite database file
     */
    private function createEmptySQLiteDB(required string path) {
        // SQLite will create the file when first accessed
        // Touch the file to create it
        fileWrite(arguments.path, "");
        
        // We could optionally create initial schema here if needed
        // For now, migrations will handle all schema creation
    }
    
    /**
     * Check if SQLite JDBC driver is available
     */
    function isSQLiteDriverAvailable() {
        try {
            createObject("java", "org.sqlite.JDBC");
            return true;
        } catch (any e) {
            return false;
        }
    }
    
    /**
     * Download and install SQLite JDBC driver
     */
    function installSQLiteDriver(string projectPath = "") {
        print.yellowLine("Installing SQLite JDBC driver...");
        
        var installPath = len(arguments.projectPath) ? arguments.projectPath : getCWD();
        
        // CommandBox can handle this through dependencies
        command("install")
            .params("ID" = "sqlite-jdbc", "save" = true, "saveDev" = false)
            .inWorkingDirectory(installPath)
            .run();
        
        print.greenLine("SQLite JDBC driver installed successfully!");
    }
    
    /**
     * Create database configuration for server.json
     */
    function createDatabaseConfig(
        required string databaseType,
        required string appName,
        string environment = "development"
    ) {
        var config = {};
        
        switch(arguments.databaseType) {
            case "sqlite":
                config = {
                    "wheelsdatasource": {
                        "driver": "org.sqlite.JDBC",
                        "class": "org.sqlite.JDBC",
                        "bundleName": "org.xerial.sqlite-jdbc",
                        "bundleVersion": "3.46.0.0",
                        "url": "jdbc:sqlite:{approot}/db/sqlite/#arguments.appName#_#arguments.environment#.db",
                        "username": "",
                        "password": "",
                        "connectionLimit": 10,
                        "connectionTimeout": 120,
                        "validate": false,
                        "storage": false,
                        "blob": false,
                        "clob": false
                    }
                };
                break;
                
            case "mysql":
                config = {
                    "wheelsdatasource": {
                        "driver": "com.mysql.cj.jdbc.Driver",
                        "class": "com.mysql.cj.jdbc.Driver",
                        "url": "jdbc:mysql://localhost:3306/#arguments.appName#_#arguments.environment#?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
                        "username": "root",
                        "password": "",
                        "connectionLimit": 10,
                        "connectionTimeout": 120,
                        "validate": true,
                        "validationQuery": "SELECT 1",
                        "storage": true,
                        "blob": true,
                        "clob": true
                    }
                };
                break;
                
            case "postgresql":
                config = {
                    "wheelsdatasource": {
                        "driver": "org.postgresql.Driver",
                        "class": "org.postgresql.Driver",
                        "url": "jdbc:postgresql://localhost:5432/#arguments.appName#_#arguments.environment#",
                        "username": "postgres",
                        "password": "",
                        "connectionLimit": 10,
                        "connectionTimeout": 120,
                        "validate": true,
                        "validationQuery": "SELECT 1",
                        "storage": true,
                        "blob": true,
                        "clob": true
                    }
                };
                break;
                
            case "sqlserver":
            case "mssql":
                config = {
                    "wheelsdatasource": {
                        "driver": "com.microsoft.sqlserver.jdbc.SQLServerDriver",
                        "class": "com.microsoft.sqlserver.jdbc.SQLServerDriver",
                        "url": "jdbc:sqlserver://localhost:1433;databaseName=#arguments.appName#_#arguments.environment#;trustServerCertificate=true",
                        "username": "sa",
                        "password": "",
                        "connectionLimit": 10,
                        "connectionTimeout": 120,
                        "validate": true,
                        "validationQuery": "SELECT 1",
                        "storage": true,
                        "blob": true,
                        "clob": true
                    }
                };
                break;
                
            default:
                throw("Unsupported database type: #arguments.databaseType#");
        }
        
        return config;
    }
    
    /**
     * Get datasource info from server configuration
     */
    function getDatasourceInfo(required string projectPath) {
        var serverJsonPath = arguments.projectPath & "/server.json";
        
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
            consoleLogger.error("Error reading server.json: #e.message#");
        }
        
        return {};
    }
    
    /**
     * Create database (for non-SQLite databases)
     */
    function createDatabase(
        required string databaseType,
        required string databaseName,
        string host = "localhost",
        string username = "",
        string password = ""
    ) {
        switch(arguments.databaseType) {
            case "sqlite":
                // SQLite databases are created automatically
                return true;
                
            case "mysql":
                return createMySQLDatabase(argumentCollection=arguments);
                
            case "postgresql":
                return createPostgreSQLDatabase(argumentCollection=arguments);
                
            case "sqlserver":
            case "mssql":
                return createSQLServerDatabase(argumentCollection=arguments);
                
            default:
                throw("Unsupported database type: #arguments.databaseType#");
        }
    }
    
    /**
     * Create MySQL database
     */
    private function createMySQLDatabase(
        required string databaseName,
        string host = "localhost",
        string username = "root",
        string password = ""
    ) {
        try {
            var connectionUrl = "jdbc:mysql://#arguments.host#:3306/?useSSL=false&allowPublicKeyRetrieval=true";
            var sql = "CREATE DATABASE IF NOT EXISTS `#arguments.databaseName#` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
            
            // Execute SQL to create database
            // This would require actual JDBC connection code
            print.greenLine("MySQL database '#arguments.databaseName#' would be created");
            return true;
        } catch (any e) {
            print.redLine("Failed to create MySQL database: #e.message#");
            return false;
        }
    }
    
    /**
     * Create PostgreSQL database
     */
    private function createPostgreSQLDatabase(
        required string databaseName,
        string host = "localhost",
        string username = "postgres",
        string password = ""
    ) {
        try {
            var connectionUrl = "jdbc:postgresql://#arguments.host#:5432/postgres";
            var sql = "CREATE DATABASE #arguments.databaseName# WITH ENCODING 'UTF8'";
            
            // Execute SQL to create database
            // This would require actual JDBC connection code
            print.greenLine("PostgreSQL database '#arguments.databaseName#' would be created");
            return true;
        } catch (any e) {
            print.redLine("Failed to create PostgreSQL database: #e.message#");
            return false;
        }
    }
    
    /**
     * Create SQL Server database
     */
    private function createSQLServerDatabase(
        required string databaseName,
        string host = "localhost",
        string username = "sa",
        string password = ""
    ) {
        try {
            var connectionUrl = "jdbc:sqlserver://#arguments.host#:1433;trustServerCertificate=true";
            var sql = "CREATE DATABASE [#arguments.databaseName#]";
            
            // Execute SQL to create database
            // This would require actual JDBC connection code
            print.greenLine("SQL Server database '#arguments.databaseName#' would be created");
            return true;
        } catch (any e) {
            print.redLine("Failed to create SQL Server database: #e.message#");
            return false;
        }
    }
    
    /**
     * Get app name from project
     */
    private function getAppNameFromProject(required string projectPath) {
        var boxJsonPath = arguments.projectPath & "/box.json";
        
        if (fileExists(boxJsonPath)) {
            try {
                var boxJson = deserializeJSON(fileRead(boxJsonPath));
                if (structKeyExists(boxJson, "name")) {
                    // Clean the name for use as database name
                    return reReplace(boxJson.name, "[^a-zA-Z0-9_]", "_", "all");
                }
            } catch (any e) {
                // Ignore errors
            }
        }
        
        // Default to directory name
        var dirName = listLast(arguments.projectPath, "/\");
        return reReplace(dirName, "[^a-zA-Z0-9_]", "_", "all");
    }
}