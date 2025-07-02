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
        string cfVersion="5.3"
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

        // Create Docker configuration files
        createDockerfile(arguments.cfengine, arguments.cfVersion, local.appPort);
        createDockerCompose(arguments.db, arguments.dbVersion, arguments.cfengine, arguments.cfVersion, local.appPort);
        createDockerIgnore();

        print.line();
        print.greenLine("Docker configuration created successfully!");
        print.line();
        print.yellowLine("To start your Docker environment:");
        print.line("docker-compose up -d");
        print.line();
    }

    private function createDockerfile(string cfengine, string cfVersion, numeric appPort) {
        local.dockerContent = '';

        if (arguments.cfengine == "lucee") {
            local.dockerContent = 'FROM lucee/lucee:#arguments.cfVersion#

## Install CommandBox
RUN apt-get update && apt-get install -y curl unzip gnupg \
    && curl -fsSl https://downloads.ortussolutions.com/debs/gpg | apt-key add - \
    && echo "deb https://downloads.ortussolutions.com/debs/noarch /" | tee -a /etc/apt/sources.list.d/commandbox.list \
    && apt-get update && apt-get install -y commandbox \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

## Copy application files
COPY . /app
WORKDIR /app

## Install dependencies
RUN box install

## Expose port
EXPOSE #arguments.appPort#

## Start the application
CMD ["box", "server", "start", "--console", "--force"]';
        } else {
            local.dockerContent = 'FROM ortussolutions/commandbox:adobe#arguments.cfVersion#

## Copy application files
COPY . /app
WORKDIR /app

## Install dependencies
RUN box install

## Expose port
EXPOSE #arguments.appPort#

## Start the application
CMD ["box", "server", "start", "--console", "--force"]';
        }

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
}
