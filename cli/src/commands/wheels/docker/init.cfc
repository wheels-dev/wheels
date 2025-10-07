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
     * @port Application port (overrides server.json)
     * @force Overwrite existing Docker files without confirmation
     * @production Generate production-ready configuration
     * @nginx Include Nginx reverse proxy
     */
    function run(
        string db="mysql",
        string dbVersion="",
        string cfengine="lucee",
        string cfVersion="6",
        string port="",
        boolean force=false,
        boolean production=false,
        boolean nginx=false
    ) {

        arguments = reconstructArgs(arguments);
        // Check for existing files if force is not set
        if (!arguments.force) {
            local.existingFiles = [];
            if (fileExists(fileSystemUtil.resolvePath("Dockerfile"))) {
                arrayAppend(local.existingFiles, "Dockerfile");
            }
            if (fileExists(fileSystemUtil.resolvePath("docker-compose.yml"))) {
                arrayAppend(local.existingFiles, "docker-compose.yml");
            }
            if (fileExists(fileSystemUtil.resolvePath(".dockerignore"))) {
                arrayAppend(local.existingFiles, ".dockerignore");
            }

            if (arrayLen(local.existingFiles)) {
                print.line();
                print.yellowLine("The following Docker files already exist:");
                for (local.file in local.existingFiles) {
                    print.line("  - #local.file#");
                }
                print.line();

                if (!confirm("Do you want to overwrite these files? [y/n]")) {
                    print.redLine("Operation cancelled.");
                    return;
                }
            }
        }

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

        // Get application port - priority: command argument > server.json > default
        if (len(arguments.port) && isNumeric(arguments.port)) {
            local.appPort = val(arguments.port);
            print.greenLine("Using port #local.appPort# from command argument");
        } else {
            local.appPort = getAppPortFromServerJson();
        }

        setCFengine(arguments.cfengine, arguments.cfVersion);
        // Create Docker configuration files
        createDockerfile(arguments.cfengine, arguments.cfVersion, local.appPort, arguments.db, arguments.production);
        createDockerCompose(arguments.db, arguments.dbVersion, arguments.cfengine, arguments.cfVersion, local.appPort, arguments.production, arguments.nginx);
        createDockerIgnore(arguments.production);
        configureDatasource(arguments.db);

        // Create Nginx configuration if requested
        if (arguments["nginx"]) {
            createNginxConfig(local.appPort, arguments.production);
        }

        print.line();
        print.greenLine("Docker configuration created successfully!");
        print.line();
        print.yellowLine("To start your Docker environment:");
        print.line("docker-compose up -d");
        print.line();
    }

    private function createDockerfile(string cfengine, string cfVersion, numeric appPort, string db, boolean production=false) {
        local.dockerContent = '';

        local.H2extension = '';
        if (arguments.cfengine == "lucee" && lCase(arguments.db) eq 'h2') {
            local.H2extension = '
##Add the H2 extension
ADD https://ext.lucee.org/org.lucee.h2-2.1.214.0001L.lex /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy/org.lucee.h2-2.1.214.0001L.lex
            ';
        }
        if (arguments.production) {
            // Production Dockerfile with optimizations
            local.dockerContent = 'FROM ortussolutions/commandbox:latest
#local.H2extension#
## Install required packages
RUN apt-get update && apt-get install -y curl nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## Copy application files
COPY . /app
WORKDIR /app

## Install Dependencies
RUN box install --production

## Production optimizations
ENV ENVIRONMENT             production
ENV BOX_SERVER_PROFILE      production

## Security: Run as non-root user
RUN useradd -m -u 1001 appuser && \
    chown -R appuser:appuser /app
USER appuser

## Expose port
EXPOSE #arguments.appPort#

## Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://127.0.0.1:#arguments.appPort#/ || exit 1

## Start the application
CMD ["box", "server", "start", "--console"]';
        } else {
            // Development Dockerfile
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

## Set Healthcheck URI
ENV HEALTHCHECK_URI         "http://127.0.0.1:#arguments.appPort#/"

## Start the application
CMD ["box", "server", "start", "--console", "--force"]';
        }

        file action='write' file='#fileSystemUtil.resolvePath("Dockerfile")#' mode='777' output='#trim(local.dockerContent)#';
        print.greenLine("Created Dockerfile");
    }

    private function createDockerCompose(string db, string dbVersion, string cfengine, string cfVersion, numeric appPort, boolean production=false, boolean nginx=false) {
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
                local.dbEnvironment = '      
      DB_HOST: db
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
                local.dbEnvironment = '      
      DB_HOST: db
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
                local.dbEnvironment = '      
      DB_HOST: db
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

        // Determine environment and volumes based on production mode
        local.envMode = arguments.production ? "production" : "development";
        local.restartPolicy = arguments.production ? '
    restart: always' : '';

        // Configure app service ports based on nginx presence
        local.appPorts = '';
        if (!arguments.nginx) {
            // Expose app port directly if no nginx
            local.appPorts = '
    ports:
      - "#arguments.appPort#:#arguments.appPort#"';
        } else {
            // Only expose internally if using nginx
            local.appPorts = '
    expose:
      - #arguments.appPort#';
        }

        // Configure volumes based on mode
        local.volumes = '';
        if (arguments.production) {
            // Production: no source volume mounts
            local.volumes = '';
        } else {
            // Development: mount source for hot reload
            local.volumes = '
    volumes:
      - .:/app
      - ../../../core/src/wheels:/app/vendor/wheels
      - ../../../docs:/app/vendor/wheels/docs
      - ../../../tests:/app/tests';
        }

        // Build app service
        local.composeContent = 'version: "3.8"

services:
  app:
    build: .#local.appPorts#
    environment:
      ENVIRONMENT: #local.envMode##local.dbEnvironment##local.volumes##local.restartPolicy#';

        if (!arguments.production) {
            local.composeContent &= '
    command: sh -c "box install && box server start --console --force"';
        }

        // Add nginx service if requested
        if (arguments.nginx) {
            local.nginxPort = arguments.production ? '80' : '8080';
            local.composeContent &= '

  nginx:
    image: nginx:alpine
    ports:
      - "#local.nginxPort#:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro#local.restartPolicy#
    depends_on:
      - app';
        }

        // Add database dependencies
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

    private function createDockerIgnore(boolean production=false) {
        local.ignoreContent = '.git
.gitignore
node_modules
.CommandBox
server.json
logs
tests
.env
*.log';

        if (arguments.production) {
            // Additional exclusions for production
            local.ignoreContent &= '
README.md
*.md
.vscode
.idea
.DS_Store';
        }

        file action='write' file='#fileSystemUtil.resolvePath(".dockerignore")#' mode='777' output='#trim(local.ignoreContent)#';
        print.greenLine("Created .dockerignore");
    }

    private function createNginxConfig(numeric appPort, boolean production=false) {
        local.sslConfig = '';
        local.productionHeaders = '';

        if (arguments.production) {
            local.productionHeaders = '
        ## Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;

        ## Gzip compression
        gzip on;
        gzip_vary on;
        gzip_min_length 1024;
        gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;';
        }

        local.nginxContent = 'events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ## Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    ## Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    upstream app_backend {
        server app:#arguments.appPort#;
    }

    server {
        listen 80;
        server_name _;

        ## Max upload size
        client_max_body_size 100M;
#local.productionHeaders#

        location / {
            proxy_pass http://app_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            ## WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            ## Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        ## Static assets caching
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            proxy_pass http://app_backend;
            proxy_cache_valid 200 1d;
            expires 1d;
            add_header Cache-Control "public, immutable";
        }

        ## Health check endpoint
        location /health {
            access_log off;
            proxy_pass http://app_backend;
        }
    }
}';

        file action='write' file='#fileSystemUtil.resolvePath("nginx.conf")#' mode='777' output='#trim(local.nginxContent)#';
        print.greenLine("Created nginx.conf");
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
                if ( len( local.cfconfigContent ) ) {
                    local.cfconfigData = deserializeJSON(local.cfconfigContent);
                } else {
                    local.cfconfigData = {};
                }
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