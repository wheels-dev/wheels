/**
 * Initialize deployment configuration for your Wheels application
 * 
 * {code:bash}
 * wheels deploy:init
 * wheels deploy:init --provider=digitalocean
 * wheels deploy:init --servers=192.168.1.100,192.168.1.101
 * {code}
 */
component extends="../../base" {

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
            
            var envContent = "# Production Environment Variables
DB_HOST=db
DB_PORT=#getDBPort(arguments.db)#
DB_NAME=#arguments.appName#_production
DB_USERNAME=#arguments.appName#_user
DB_PASSWORD=change_me_to_secure_password

WHEELS_ENV=production
WHEELS_RELOAD_PASSWORD=change_me_to_secure_password
SECRET_KEY_BASE=#generateSecretKey()#

# Additional configuration
APP_URL=https://#arguments.domain#
";
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
            dockerfile = "FROM lucee/lucee:5.4

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www

# Copy application files
COPY . /var/www/

# Install CommandBox for dependency management
RUN curl -fsSl https://downloads.ortussolutions.com/debs/gpg | apt-key add -
RUN echo "deb https://downloads.ortussolutions.com/debs/noarch /" | tee -a /etc/apt/sources.list.d/commandbox.list
RUN apt-get update && apt-get install -y commandbox

# Install dependencies
RUN box install

# Configure Lucee
COPY deploy/lucee-config.xml /opt/lucee/web/lucee-web.xml.cfm

# Expose port
EXPOSE 3000

# Start command
CMD ["box", "server", "start", "--console", "--force", "port=3000"]";
        } else {
            dockerfile = "FROM adobecoldfusion/coldfusion:latest

# Set working directory  
WORKDIR /app

# Copy application files
COPY . /app/

# Install CommandBox for dependency management
RUN curl -fsSl https://www.ortussolutions.com/parent/download/commandbox/type/bin -o /tmp/box && \
    chmod +x /tmp/box && \
    mv /tmp/box /usr/local/bin/box

# Install dependencies
RUN box install

# Expose port
EXPOSE 3000

# Start command
CMD ["box", "server", "start", "--console", "--force", "cfengine=adobe@2023", "port=3000"]";
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