/**
 * Initialize deployment configuration for your Wheels application
 * 
 * {code:bash}
 * wheels deploy:init
 * wheels deploy:init --provider=digitalocean
 * wheels deploy:init --servers=192.168.1.100,192.168.1.101
 * {code}
 */
component extends="./base" {

    /**
     * @provider Cloud provider (digitalocean, aws, linode, custom)
     * @servers Comma-separated list of server IPs for custom provider
     * @domain Primary domain for the application
     * @appName Application name for deployment
     * @db Database type (mysql, postgres, mssql)
     * @cfengine CF engine (lucee, adobe)
     * @environment Environment name (production, staging, etc.)
     * @force Overwrite existing deploy.json
     */
    function run(
        string provider="custom",
        string servers="",
        string domain="",
        string appName="",
        string db="mysql",
        string cfengine="lucee",
        string environment="",
        boolean force=false
    ) {
        // Determine config file path based on environment
        var configFileName = "deploy.json";
        if (len(arguments.environment)) {
            configFileName = "deploy.#arguments.environment#.json";
        }
        
        var deployConfigPath = fileSystemUtil.resolvePath(configFileName);
        
        if (fileExists(deployConfigPath) && !arguments.force) {
            print.redLine("#configFileName# already exists! Use --force to overwrite.");
            return;
        }
        
        print.line();
        print.boldMagentaLine("Wheels Deploy Configuration");
        print.line("=".repeatString(50));
        
        // Get app name from server.json if not provided
        if (!len(arguments.appName)) {
            var serverJSON = fileSystemUtil.resolvePath("server.json");
            if (fileExists(serverJSON)) {
                try {
                    var serverConfig = deserializeJSON(fileRead(serverJSON));
                    arguments.appName = serverConfig.name ?: "wheels-app";
                } catch (any e) {
                    arguments.appName = "wheels-app";
                }
            } else {
                arguments.appName = ask("Application name: ");
            }
        }
        
        // Get domain if not provided
        if (!len(arguments.domain)) {
            arguments.domain = ask("Primary domain (e.g., myapp.com): ");
        }
        
        // Get servers for custom provider
        if (arguments.provider == "custom" && !len(arguments.servers)) {
            arguments.servers = ask("Server IPs (comma-separated): ");
        }
        
        var deployConfig = {
            "service": arguments.appName,
            "image": arguments.appName,
            "servers": {
                "web": listToArray(arguments.servers)
            },
            "registry": {
                "server": "ghcr.io",
                "username": "your-github-username"
            },
            "env": {
                "clear": {
                    "CFENGINE": arguments.cfengine,
                    "DB_TYPE": arguments.db,
                    "WHEELS_ENV": "production"
                },
                "secret": [
                    "DB_PASSWORD",
                    "WHEELS_RELOAD_PASSWORD",
                    "SECRET_KEY_BASE"
                ]
            },
            "ssh": {
                "user": "root"
            },
            "builder": {
                "multiarch": false
            },
            "healthcheck": {
                "path": "/",
                "port": 3000,
                "interval": 30
            },
            "accessories": {
                "db": {
                    "image": arguments.db == "mysql" ? "mysql:8" : 
                            arguments.db == "postgres" ? "postgres:15" : 
                            "mcr.microsoft.com/mssql/server:2022-latest",
                    "host": "db",
                    "port": arguments.db == "mysql" ? 3306 : 
                            arguments.db == "postgres" ? 5432 : 
                            1433,
                    "env": {
                        "clear": {},
                        "secret": []
                    },
                    "volumes": [
                        "/var/lib/" & arguments.db & ":/var/lib/" & arguments.db
                    ]
                }
            },
            "traefik": {
                "enabled": true,
                "options": {
                    "publish": ["443:443"],
                    "volume": []
                },
                "args": {
                    "entryPoints.web.address": ":80",
                    "entryPoints.websecure.address": ":443",
                    "entryPoints.web.http.redirections.entryPoint.to": "websecure",
                    "entryPoints.web.http.redirections.entryPoint.scheme": "https",
                    "certificatesresolvers.letsencrypt.acme.email": "admin@" & arguments.domain,
                    "certificatesresolvers.letsencrypt.acme.storage": "/letsencrypt/acme.json",
                    "certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint": "web"
                },
                "labels": {
                    "traefik.http.routers.#arguments.appName#.rule": "Host(`#arguments.domain#`)",
                    "traefik.http.routers.#arguments.appName#.entrypoints": "websecure",
                    "traefik.http.routers.#arguments.appName#.tls.certresolver": "letsencrypt"
                }
            }
        };
        
        // Add provider-specific configuration
        if (arguments.provider != "custom") {
            deployConfig["provider"] = arguments.provider;
        }
        
        // Write configuration
        fileWrite(deployConfigPath, serializeJSON(deployConfig, false, true));
        
        // Create Dockerfile if it doesn't exist
        var dockerfilePath = fileSystemUtil.resolvePath("Dockerfile");
        if (!fileExists(dockerfilePath)) {
            print.line();
            print.yellowLine("Creating Dockerfile...");
            
            var dockerfileContent = generateDockerfile(arguments.cfengine, arguments.db);
            fileWrite(dockerfilePath, dockerfileContent);
        }
        
        // Create .env.deploy if it doesn't exist
        var envPath = fileSystemUtil.resolvePath(".env.deploy");
        if (!fileExists(envPath)) {
            print.yellowLine("Creating .env.deploy template...");
            
            // Generate a random secret key
            var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
            var secretKey = "";
            for (var i = 1; i <= 64; i++) {
                secretKey &= mid(chars, randRange(1, len(chars)), 1);
            }
            savecontent variable="envContent" {
                writeOutput("## Production Environment Variables" & chr(10));
                writeOutput("DB_HOST=db" & chr(10));
                writeOutput("DB_PORT=#getDBPort(arguments.db)#" & chr(10));
                writeOutput("DB_NAME=#arguments.appName#_production" & chr(10));
                writeOutput("DB_USERNAME=#arguments.appName#_user" & chr(10));
                writeOutput("DB_PASSWORD=change_me_to_secure_password" & chr(10) & chr(10));
                writeOutput("WHEELS_ENV=production" & chr(10));
                writeOutput("WHEELS_RELOAD_PASSWORD=change_me_to_secure_password" & chr(10));
                writeOutput("SECRET_KEY_BASE=#secretKey#" & chr(10) & chr(10));
                writeOutput("## Additional configuration" & chr(10));
                writeOutput("APP_URL=https://#arguments.domain#" & chr(10));
            };
            fileWrite(envPath, envContent);
        }
        
        print.line();
        print.greenLine("✓ Deployment configuration created successfully!");
        print.line();
        print.boldLine("Next steps:");
        print.line("1. Review and update deploy.json");
        print.line("2. Update .env.deploy with production values");
        print.line("3. Ensure your servers have SSH access configured");
        print.line("4. Run 'wheels deploy:setup' to provision servers");
        print.line("5. Run 'wheels deploy:push' to deploy your application");
        print.line();
    }
    
    private string function generateDockerfile(required string cfengine, required string db) {
        var dockerfile = "";
        
        if (arguments.cfengine == "lucee") {
            savecontent variable="dockerfile" {
                writeOutput("FROM lucee/lucee:5.4" & chr(10) & chr(10));
                writeOutput("## Install additional dependencies" & chr(10));
                writeOutput("RUN apt-get update && apt-get install -y \" & chr(10));
                writeOutput("    curl \" & chr(10));
                writeOutput("    git \" & chr(10));
                writeOutput("    && rm -rf /var/lib/apt/lists/*" & chr(10) & chr(10));
                writeOutput("## Set working directory" & chr(10));
                writeOutput("WORKDIR /var/www" & chr(10) & chr(10));
                writeOutput("## Copy application files" & chr(10));
                writeOutput("COPY . /var/www/" & chr(10) & chr(10));
                writeOutput("## Install CommandBox for dependency management" & chr(10));
                writeOutput("RUN curl -fsSl https://downloads.ortussolutions.com/debs/gpg | apt-key add -" & chr(10));
                writeOutput("RUN echo ""deb https://downloads.ortussolutions.com/debs/noarch /"" | tee -a /etc/apt/sources.list.d/commandbox.list" & chr(10));
                writeOutput("RUN apt-get update && apt-get install -y commandbox" & chr(10) & chr(10));
                writeOutput("## Install dependencies" & chr(10));
                writeOutput("RUN box install" & chr(10) & chr(10));
                writeOutput("## Configure Lucee" & chr(10));
                writeOutput("COPY deploy/lucee-config.xml /opt/lucee/web/lucee-web.xml.cfm" & chr(10) & chr(10));
                writeOutput("## Expose port" & chr(10));
                writeOutput("EXPOSE 3000" & chr(10) & chr(10));
                writeOutput("## Start command" & chr(10));
                writeOutput("CMD [""box"", ""server"", ""start"", ""--console"", ""--force"", ""port=3000""]");
            };
        } else {
            savecontent variable="dockerfile" {
                writeOutput("FROM adobecoldfusion/coldfusion:latest" & chr(10) & chr(10));
                writeOutput("## Set working directory" & chr(10));
                writeOutput("WORKDIR /app" & chr(10) & chr(10));
                writeOutput("## Copy application files" & chr(10));
                writeOutput("COPY . /app/" & chr(10) & chr(10));
                writeOutput("## Install CommandBox for dependency management" & chr(10));
                writeOutput("RUN curl -fsSl https://www.ortussolutions.com/parent/download/commandbox/type/bin -o /tmp/box && \" & chr(10));
                writeOutput("    chmod +x /tmp/box && \" & chr(10));
                writeOutput("    mv /tmp/box /usr/local/bin/box" & chr(10) & chr(10));
                writeOutput("## Install dependencies" & chr(10));
                writeOutput("RUN box install" & chr(10) & chr(10));
                writeOutput("## Expose port" & chr(10));
                writeOutput("EXPOSE 3000" & chr(10) & chr(10));
                writeOutput("## Start command" & chr(10));
                writeOutput("CMD [""box"", ""server"", ""start"", ""--console"", ""--force"", ""cfengine=adobe@2023"", ""port=3000""]");
            };
        }
        
        return dockerfile;
    }
    
    private numeric function getDBPort(required string db) {
        switch(arguments.db) {
            case "mysql": return 3306;
            case "postgres": return 5432;
            case "mssql": return 1433;
            default: return 3306;
        }
    }
    
    private string function generateSecretKey() {
        var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        var key = "";
        
        for (var i = 1; i <= 64; i++) {
            key &= mid(chars, randRange(1, len(chars)), 1);
        }
        
        return key;
    }
}