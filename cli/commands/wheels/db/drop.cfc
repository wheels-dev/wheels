/**
 * Drop the database
 */
component extends="../base" {
    
    property name="databaseService" inject="DatabaseService@wheelscli";
    
    /**
     * Drop the database for the current environment
     * 
     * @environment Environment to drop database for (development, testing, production)
     * @force Skip confirmation prompt
     * @help Drop the database configured in server.json
     */
    function run(
        string environment = "development",
        boolean force = false
    ) {
        ensureWheelsProject();
        
        print.line();
        print.boldRedLine("⚠️  Dropping database for #arguments.environment# environment");
        
        // Get datasource configuration
        var dsInfo = databaseService.getDatasourceInfo(getCWD());
        
        if (structIsEmpty(dsInfo)) {
            error("No datasource configuration found in server.json");
        }
        
        // Parse database info
        var dbInfo = parseDatabaseInfo(dsInfo, arguments.environment);
        
        print.yellowLine("Database: #dbInfo.name#");
        print.yellowLine("Type: #dbInfo.type#");
        print.line();
        
        if (!arguments.force) {
            print.redBoldLine("WARNING: This will permanently delete all data!");
            if (!confirm("Are you sure you want to drop the database '#dbInfo.name#'?")) {
                print.line("Database drop cancelled.");
                return;
            }
        }
        
        if (dbInfo.type == "sqlite") {
            // SQLite database deletion
            var dbPath = expandPath(getCWD() & "/db/sqlite/");
            var dbFile = dbPath & dbInfo.name & ".db";
            
            if (!fileExists(dbFile)) {
                print.yellowLine("Database does not exist: #dbInfo.name#.db");
                return;
            }
            
            try {
                fileDelete(dbFile);
                
                // Also delete journal and wal files if they exist
                if (fileExists(dbFile & "-journal")) {
                    fileDelete(dbFile & "-journal");
                }
                if (fileExists(dbFile & "-wal")) {
                    fileDelete(dbFile & "-wal");
                }
                if (fileExists(dbFile & "-shm")) {
                    fileDelete(dbFile & "-shm");
                }
                
                print.greenLine("✓ Dropped SQLite database: #dbInfo.name#.db");
            } catch (any e) {
                print.redLine("Failed to drop database: #e.message#");
                print.line("The database file may be in use. Close all connections and try again.");
            }
            
        } else {
            // Other database types
            print.yellowLine("For non-SQLite databases, please use your database tools to drop the database.");
            print.line();
            print.line("Example commands:");
            
            switch(dbInfo.type) {
                case "mysql":
                    print.indentedLine("mysql -u root -p -e 'DROP DATABASE IF EXISTS `#dbInfo.name#`;'");
                    break;
                case "postgresql":
                    print.indentedLine("dropdb #dbInfo.name#");
                    break;
                case "sqlserver":
                    print.indentedLine("sqlcmd -S #dbInfo.host# -Q 'DROP DATABASE IF EXISTS [#dbInfo.name#];'");
                    break;
            }
        }
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
                    var appName = getAppNameFromBoxJson(getCWD());
                    info.name = appName & "_" & arguments.environment;
                }
            } else {
                // Parse JDBC URL for other databases
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