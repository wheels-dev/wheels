/**
 * Create the database
 */
component extends="../base" {
    
    property name="databaseService" inject="DatabaseService@wheelscli";
    
    /**
     * Create the database for the current environment
     * 
     * @environment Environment to create database for (development, testing, production)
     * @force Force creation even if database exists
     * @help Create the database configured in server.json
     */
    function run(
        string environment = "development",
        boolean force = false
    ) {
        ensureWheelsProject();
        
        print.line();
        print.boldBlueLine("Creating database for #arguments.environment# environment");
        
        // Get datasource configuration
        var dsInfo = databaseService.getDatasourceInfo(getCWD());
        
        if (structIsEmpty(dsInfo)) {
            error("No datasource configuration found in server.json");
        }
        
        // Parse database info from connection URL
        var dbInfo = parseDatabaseInfo(dsInfo, arguments.environment);
        
        print.yellowLine("Database: #dbInfo.name#");
        print.yellowLine("Type: #dbInfo.type#");
        
        if (dbInfo.type == "sqlite") {
            // SQLite database creation
            var dbPath = expandPath(getCWD() & "/db/sqlite/");
            var dbFile = dbPath & dbInfo.name & ".db";
            
            if (fileExists(dbFile) && !arguments.force) {
                print.line();
                print.yellowLine("Database already exists: #dbInfo.name#.db");
                
                if (confirm("Do you want to recreate it? This will delete all data!")) {
                    fileDelete(dbFile);
                    print.redLine("Deleted existing database.");
                } else {
                    print.line("Database creation cancelled.");
                    return;
                }
            }
            
            // Create SQLite database
            if (!directoryExists(dbPath)) {
                directoryCreate(dbPath, true);
            }
            
            fileWrite(dbFile, "");
            print.greenLine("✓ Created SQLite database: #dbInfo.name#.db");
            
        } else {
            // Other database types
            print.line();
            
            var created = databaseService.createDatabase(
                databaseType = dbInfo.type,
                databaseName = dbInfo.name,
                host = dbInfo.host ?: "localhost",
                username = dsInfo.username ?: "",
                password = dsInfo.password ?: ""
            );
            
            if (created) {
                print.greenLine("✓ Database created successfully!");
            } else {
                print.redLine("Failed to create database. It may already exist or you may not have permissions.");
            }
        }
        
        print.line();
        print.boldLine("Next steps:");
        print.indentedLine("1. Run 'wheels db migrate' to set up the schema");
        print.indentedLine("2. Run 'wheels db seed' to load sample data (if available)");
    }
    
    /**
     * Parse database info from datasource configuration
     */
    private function parseDatabaseInfo(required struct dsInfo, required string environment) {
        var info = {
            type = "unknown",
            name = "",
            host = "localhost",
            port = ""
        };
        
        // Determine database type from driver
        if (structKeyExists(arguments.dsInfo, "driver")) {
            if (findNoCase("sqlite", arguments.dsInfo.driver)) {
                info.type = "sqlite";
            } else if (findNoCase("mysql", arguments.dsInfo.driver)) {
                info.type = "mysql";
                info.port = "3306";
            } else if (findNoCase("postgresql", arguments.dsInfo.driver)) {
                info.type = "postgresql";
                info.port = "5432";
            } else if (findNoCase("sqlserver", arguments.dsInfo.driver)) {
                info.type = "sqlserver";
                info.port = "1433";
            }
        }
        
        // Parse connection URL
        if (structKeyExists(arguments.dsInfo, "url")) {
            var url = arguments.dsInfo.url;
            
            if (info.type == "sqlite") {
                // Extract database name from SQLite path
                var matches = reFindNoCase("([^/\\]+)\.db", url, 1, true);
                if (matches.pos[1]) {
                    info.name = mid(url, matches.pos[2], matches.len[2]);
                } else {
                    // Try to get app name from path
                    var appName = getAppNameFromBoxJson(getCWD());
                    info.name = appName & "_" & arguments.environment;
                }
            } else {
                // Parse JDBC URL for other databases
                // Format: jdbc:type://host:port/database
                var urlPattern = "jdbc:[^:]+://([^:/]+)(?::(\d+))?/([^?]+)";
                var matches = reFindNoCase(urlPattern, url, 1, true);
                
                if (matches.pos[1]) {
                    info.host = mid(url, matches.pos[2], matches.len[2]);
                    if (matches.pos[3]) {
                        info.port = mid(url, matches.pos[3], matches.len[3]);
                    }
                    if (matches.pos[4]) {
                        info.name = mid(url, matches.pos[4], matches.len[4]);
                    }
                }
            }
        }
        
        return info;
    }
}