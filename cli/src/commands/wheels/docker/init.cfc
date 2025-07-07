/**
 * Initialize Docker configuration for development
 *
 * {code:bash}
 * wheels docker:init
 * wheels docker:init --db=mysql
 * wheels docker:init --db=postgres --dbVersion=13
 * {code}
 */
component extends="../base" {

    /**
     * @db Database to use (h2, mysql, postgres, mssql)
     * @dbVersion Database version to use
     * @cfengine ColdFusion engine to use (lucee, adobe)
     * @cfVersion ColdFusion engine version
     */
    function run(
        string db="mysql",
        string dbVersion="",
        string cfengine="lucee",
        string cfVersion="6"
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Docker Configuration");
        print.line();

        // Validate database selection
        local.supportedDatabases = ["h2", "mysql", "postgres", "mssql"];
        if (!arrayContains(local.supportedDatabases, lCase(arguments.db))) {
            error("Unsupported database: #arguments.db#. Please choose from: #arrayToList(local.supportedDatabases)#");
        }

        // Validate CF engine
        local.supportedEngines = ["lucee", "adobe"];
        if (!arrayContains(local.supportedEngines, lCase(arguments.cfengine))) {
            error("Unsupported CF engine: #arguments.cfengine#. Please choose from: #arrayToList(local.supportedEngines)#");
        }
        
        // Get application port from existing server.json or use default
        local.appPort = getAppPortFromServerJson();
        setCFengine(arguments.cfengine, arguments.cfVersion);
        // Create Docker configuration files
        createDockerfile(arguments.cfengine, arguments.cfVersion, local.appPort, arguments.db);
        createDockerCompose(arguments.db, arguments.dbVersion, arguments.cfengine, arguments.cfVersion, local.appPort);
        createDockerIgnore();
        configureDatasource(arguments.db);

        print.line();
        print.greenLine("Docker configuration created successfully!");
        print.line();
        print.yellowLine("To start your Docker environment:");
        print.line("docker-compose up -d");
        print.line();
    }

    private function createDockerfile(string cfengine, string cfVersion, numeric appPort, string db) {
        local.dockerContent = '';

        local.H2extension = '';
        if (arguments.cfengine == "lucee" && lCase(arguments.db) eq 'h2') {
            local.H2extension = '
##Add the H2 extension
ADD https://ext.lucee.org/org.lucee.h2-2.1.214.0001L.lex /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy/org.lucee.h2-2.1.214.0001L.lex
            ';
        }
        local.dockerContent = 'FROM ortussolutions/commandbox:latest
#local.H2extension#
## Install curl and nano
RUN apt-get update && apt-get install -y curl nano

## Clean up the image
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

## Copy application files
COPY . /app
WORKDIR /app

## Install Dependencies
ENV BOX_INSTALL             TRUE

## Expose port
EXPOSE #arguments.appPort#

## Start the application
CMD ["box", "server", "start", "--console", "--force"]'

        file action='write' file='#fileSystemUtil.resolvePath("Dockerfile")#' mode='777' output='#trim(local.dockerContent)#';
        print.greenLine("Created Dockerfile");
    }

    private function createDockerCompose(string db, string dbVersion, string cfengine, string cfVersion, numeric appPort) {
        local.dbService = '';
        local.dbEnvironment = '';

        switch(arguments.db) {
            case "mysql":
                local.dbVersion = len(arguments.dbVersion) ? arguments.dbVersion : "8.0";
                local.dbService = '  db:
    image: mysql:#local.dbVersion#
    environment:
      MYSQL_ROOT_PASSWORD: wheels
      MYSQL_DATABASE: wheels
      MYSQL_USER: wheels
      MYSQL_PASSWORD: wheels
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql';
                local.dbEnvironment = '      DB_HOST: db
      DB_PORT: 3306
      DB_NAME: wheels
      DB_USER: wheels
      DB_PASSWORD: wheels';
                break;

            case "postgres":
                local.dbVersion = len(arguments.dbVersion) ? arguments.dbVersion : "15";
                local.dbService = '  db:
    image: postgres:#local.dbVersion#
    environment:
      POSTGRES_USER: wheels
      POSTGRES_PASSWORD: wheels
      POSTGRES_DB: wheels
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data';
                local.dbEnvironment = '      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: wheels
      DB_USER: wheels
      DB_PASSWORD: wheels';
                break;

            case "mssql":
                local.dbVersion = len(arguments.dbVersion) ? arguments.dbVersion : "2019-latest";
                local.dbService = '  db:
    image: mcr.microsoft.com/mssql/server:#local.dbVersion#
    environment:
      ACCEPT_EULA: Y
      SA_PASSWORD: Wheels123!
      MSSQL_DB: wheels
    ports:
      - "1433:1433"
    volumes:
      - db_data:/var/opt/mssql';
                local.dbEnvironment = '      DB_HOST: db
      DB_PORT: 1433
      DB_NAME: wheels
      DB_USER: sa
      DB_PASSWORD: Wheels123!';
                break;

            case "h2":
                // H2 runs embedded, no separate service needed
                local.dbService = '';
                local.dbEnvironment = '      DB_TYPE: h2';
                break;
        }

        local.composeContent = 'version: "3.8"

services:
  app:
    build: .
    ports:
      - "#arguments.appPort#:#arguments.appPort#"
    environment:
      ENVIRONMENT: development
#local.dbEnvironment#
    volumes:
      - .:/app
      - ../../../core/src/wheels:/app/core/wheels
      - /app/node_modules
    command: sh -c "box install && box server start --console --force"';

        if (len(local.dbService)) {
            local.composeContent &= '
    depends_on:
      - db

#local.dbService#';
        }

        local.composeContent &= '

volumes:
  db_data:';

        file action='write' file='#fileSystemUtil.resolvePath("docker-compose.yml")#' mode='777' output='#trim(local.composeContent)#';
        print.greenLine("Created docker-compose.yml");
    }

    private function createDockerIgnore() {
        local.ignoreContent = '.git
.gitignore
node_modules
.CommandBox
server.json
logs
tests
.env
*.log';

        file action='write' file='#fileSystemUtil.resolvePath(".dockerignore")#' mode='777' output='#trim(local.ignoreContent)#';
        print.greenLine("Created .dockerignore");
    }

    private function getAppPortFromServerJson() {
        local.serverJsonPath = fileSystemUtil.resolvePath("server.json");
        local.appPort = 8080; // Default port
        
        // Check if server.json exists
        if (fileExists(local.serverJsonPath)) {
            try {
                local.serverContent = fileRead(local.serverJsonPath);
                local.serverData = deserializeJSON(local.serverContent);
                
                // Extract port from server.json
                if (structKeyExists(local.serverData, "web") && 
                    structKeyExists(local.serverData.web, "http") && 
                    structKeyExists(local.serverData.web.http, "port")) {
                    local.appPort = val(local.serverData.web.http.port);
                    print.greenLine("Using port #local.appPort# from existing server.json");
                } else {
                    // Port not found, update server.json with default port
                    updateServerJsonPort(local.serverData, local.appPort);
                    print.yellowLine("Updated server.json with default port #local.appPort#");
                }
                
                // Check for CFConfigFile setting
                if (!structKeyExists(local.serverData, "CFConfigFile")) {
                    local.serverData["CFConfigFile"] = "CFConfig.json";
                    local.updatedContent = serializeJSON(local.serverData);
                    file action='write' file='#local.serverJsonPath#' mode='777' output='#local.updatedContent#';
                    print.greenLine("Added CFConfigFile setting to server.json");
                }
            } catch (any e) {
                print.redLine("Error reading server.json: #e.message#");
                print.yellowLine("Using default port #local.appPort#");
            }
        } else {
            print.yellowLine("server.json not found, using default port #local.appPort#");
        }
        
        return local.appPort;
    }
    
    private function updateServerJsonPort(struct serverData, numeric port) {
        // Ensure the structure exists
        if (!structKeyExists(arguments.serverData, "web")) {
            arguments.serverData.web = {};
        }
        if (!structKeyExists(arguments.serverData.web, "http")) {
            arguments.serverData.web.http = {};
        }
        
        // Set the port
        arguments.serverData.web.http.port = toString(arguments.port);
        
        // Write back to server.json
        local.serverJsonPath = fileSystemUtil.resolvePath("server.json");
        local.updatedContent = serializeJSON(arguments.serverData);
        file action='write' file='#local.serverJsonPath#' mode='777' output='#local.updatedContent#';
    }
    
    private function configureDatasource(string db) {
        local.cfconfigPath = fileSystemUtil.resolvePath("CFConfig.json");
        local.datasourceConfig = {};
        
        // Skip H2 as it's embedded and doesn't need container connection
        if (arguments.db == "h2") {
            print.yellowLine("Skipping datasource configuration for H2 (embedded database)");
            return;
        }
        
        // Read existing CFConfig.json or create new structure
        if (fileExists(local.cfconfigPath)) {
            try {
                local.cfconfigContent = fileRead(local.cfconfigPath);
                local.cfconfigData = deserializeJSON(local.cfconfigContent);
            } catch (any e) {
                print.redLine("Error reading CFConfig.json: #e.message#");
                local.cfconfigData = { "datasources": {} };
            }
        } else {
            local.cfconfigData = { "datasources": {} };
        }
        
        // Configure datasource based on database type
        switch(arguments.db) {
            case "mysql":
                local.datasourceConfig = {
                    "class":"com.mysql.cj.jdbc.Driver",
                    "connectionLimit":"-1",
                    "connectionTimeout":"1",
                    "database":"wheels",
                    "dbdriver":"MySQL",
                    "dsn":"jdbc:mysql://{host}:{port}/{database}",
                    "host":"db",
                    "password":"wheels",
                    "port":"3306",
                    "username":"wheels"
                };
                break;
                
            case "postgres":
                local.datasourceConfig = {
                    "class":"org.postgresql.Driver",
                    "connectionLimit":"-1",
                    "connectionTimeout":"1",
                    "database":"wheels",
                    "dbdriver":"PostgreSql",
                    "dsn":"jdbc:postgresql://{host}:{port}/{database}",
                    "host":"db",
                    "password":"wheels",
                    "port":"5433",
                    "username":"wheels"
                };
                break;
                
            case "mssql":
                local.datasourceConfig = {
                    "class":"com.microsoft.sqlserver.jdbc.SQLServerDriver",
                    "connectionLimit":"-1",
                    "connectionTimeout":"1",
                    "database":"wheels",
                    "dbdriver":"MSSQL",
                    "dsn":"jdbc:sqlserver://{host}:{port}",
                    "host":"db",
                    "password":"Wheels123!",
                    "port":"1433",
                    "username":"sa"
                };
                break;
        }
        
        // Add or update the 'wheels-dev' datasource
        local.cfconfigData.datasources["wheels-dev"] = local.datasourceConfig;
        
        // Write updated CFConfig.json
        local.updatedContent = serializeJSON(local.cfconfigData);
        file action='write' file='#local.cfconfigPath#' mode='777' output='#local.updatedContent#';
        print.greenLine("Updated CFConfig.json with #arguments.db# datasource configuration");
    }

    private function setCFengine(string cfengine, string cfVersion){
        local.serverJsonPath = fileSystemUtil.resolvePath("server.json");
        
        // Check if server.json exists
        if (fileExists(local.serverJsonPath)) {
            try {
                local.serverContent = deserializeJSON(fileRead(local.serverJsonPath));
                // Ensure the structure exists
                if (!structKeyExists(local.serverContent, "app")) {
                    local.serverContent.app = {};
                }
                // Set the cfengine
                local.serverContent.app.cfengine = "#arguments.cfengine#@#arguments.cfVersion#";
                local.updatedContent = serializeJSON(local.serverContent);
                file action='write' file='#local.serverJsonPath#' mode='777' output='#local.updatedContent#';
            } catch ( any e ){
                error("Not able to read server.json: #e.message#");
            }
        } else {
            error("server.json does not exist at #local.serverJsonPath#");
        }
    }
}