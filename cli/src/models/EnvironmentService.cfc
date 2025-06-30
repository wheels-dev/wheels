component {

    property name="serverService" inject="ServerService@commandbox-core";
    property name="templateService" inject="TemplateService@wheels-cli";

    /**
     * Setup a Wheels development environment
     */
    function setup(
        required string environment,
        string template = "local",
        string database = "h2",
        boolean force = false
    ) {
        try {
            var projectRoot = resolvePath(".");

            // Check if environment already exists
            var envFile = projectRoot & "/.env.#arguments.environment#";
            if (fileExists(envFile) && !arguments.force) {
                return {
                    success: false,
                    error: "Environment '#arguments.environment#' already exists. Use --force to overwrite."
                };
            }

            // Setup based on template
            var result = {};
            switch (arguments.template) {
                case "docker":
                    result = setupDockerEnvironment(argumentCollection = arguments);
                    break;
                case "vagrant":
                    result = setupVagrantEnvironment(argumentCollection = arguments);
                    break;
                default:
                    result = setupLocalEnvironment(argumentCollection = arguments);
            }

            if (result.success) {
                // Create environment file
                createEnvironmentFile(arguments.environment, result.config);

                // Update server.json if needed
                updateServerConfig(arguments.environment, result.config);

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
     * List available environments
     */
    function list() {
        var environments = [];
        var projectRoot = resolvePath(".");

        // Look for .env.* files
        var envFiles = directoryList(
            projectRoot,
            false,
            "name",
            "*.env.*"
        );

        for (var file in envFiles) {
            if (reFindNoCase("^\.env\.", file)) {
                var envName = listLast(file, ".");
                var config = loadEnvironmentConfig(envName);

                arrayAppend(environments, {
                    name: envName,
                    template: config.template ?: "local",
                    database: config.database ?: "unknown",
                    created: getFileInfo(projectRoot & "/" & file).lastModified
                });
            }
        }

        // Check server.json for environments
        var serverJsonPath = projectRoot & "/server.json";
        if (fileExists(serverJsonPath)) {
            var serverJson = deserializeJSON(fileRead(serverJsonPath));
            if (serverJson.keyExists("env") && isStruct(serverJson.env)) {
                for (var envName in serverJson.env) {
                    if (!arrayFindNoCase(environments, function(e) { return e.name == envName; })) {
                        arrayAppend(environments, {
                            name: envName,
                            template: "server.json",
                            database: "configured",
                            created: getFileInfo(serverJsonPath).lastModified
                        });
                    }
                }
            }
        }

        return environments;
    }

    /**
     * Switch to a different environment
     */
    function switch(required string environment) {
        var envFile = resolvePath(".env.#arguments.environment#");

        if (!fileExists(envFile)) {
            return {
                success: false,
                error: "Environment '#arguments.environment#' not found"
            };
        }

        // Copy environment file to .env
        fileCopy(envFile, resolvePath(".env"));

        // Update server.json default environment
        var serverJsonPath = resolvePath("server.json");
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
        var config = {
            template: "local",
            database: arguments.database,
            port: 8080,
            cfengine: "lucee5"
        };

        // Database-specific configuration
        switch (arguments.database) {
            case "mysql":
                config.datasource = {
                    driver: "MySQL",
                    host: "localhost",
                    port: 3306,
                    database: "wheels_#arguments.environment#",
                    username: "wheels",
                    password: "wheels_password"
                };
                break;
            case "postgres":
                config.datasource = {
                    driver: "PostgreSQL",
                    host: "localhost",
                    port: 5432,
                    database: "wheels_#arguments.environment#",
                    username: "wheels",
                    password: "wheels_password"
                };
                break;
            case "mssql":
                config.datasource = {
                    driver: "MSSQL",
                    host: "localhost",
                    port: 1433,
                    database: "wheels_#arguments.environment#",
                    username: "sa",
                    password: "Wheels_Pass123!"
                };
                break;
            default: // h2
                config.datasource = {
                    driver: "H2",
                    database: "./db/wheels_#arguments.environment#",
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
    private function setupDockerEnvironment(argumentCollection) {
        var config = {
            template: "docker",
            database: arguments.database,
            port: 8080
        };

        // Create docker-compose.yml
        var dockerComposeContent = generateDockerCompose(argumentCollection = arguments);
        fileWrite(resolvePath("docker-compose.#arguments.environment#.yml"), dockerComposeContent);

        // Create Dockerfile if it doesn't exist
        var dockerfilePath = resolvePath("Dockerfile");
        if (!fileExists(dockerfilePath)) {
            var dockerfileContent = generateDockerfile();
            fileWrite(dockerfilePath, dockerfileContent);
        }

        // Database configuration for Docker
        config.datasource = {
            driver: getDatabaseDriver(arguments.database),
            host: "db",
            port: getDatabasePort(arguments.database),
            database: "wheels",
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
    private function setupVagrantEnvironment(argumentCollection) {
        var config = {
            template: "vagrant",
            database: arguments.database,
            port: 8080
        };

        // Create Vagrantfile
        var vagrantContent = generateVagrantfile(argumentCollection = arguments);
        fileWrite(resolvePath("Vagrantfile.#arguments.environment#"), vagrantContent);

        // Create provisioning script
        var provisionScript = generateProvisionScript(argumentCollection = arguments);
        var provisionDir = resolvePath("vagrant");
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
    private function createEnvironmentFile(environment, config) {
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
        if (arguments.config.keyExists("datasource")) {
            arrayAppend(envContent, "## Database Settings");
            arrayAppend(envContent, "DB_DRIVER=#arguments.config.datasource.driver#");
            arrayAppend(envContent, "DB_HOST=#arguments.config.datasource.host#");
            arrayAppend(envContent, "DB_PORT=#arguments.config.datasource.port#");
            arrayAppend(envContent, "DB_NAME=#arguments.config.datasource.database#");
            arrayAppend(envContent, "DB_USER=#arguments.config.datasource.username#");
            arrayAppend(envContent, "DB_PASSWORD=#arguments.config.datasource.password#");
            arrayAppend(envContent, "");
        }

        // Server settings
        arrayAppend(envContent, "## Server Settings");
        arrayAppend(envContent, "SERVER_PORT=#arguments.config.port#");
        if (arguments.config.keyExists("cfengine")) {
            arrayAppend(envContent, "SERVER_CFENGINE=#arguments.config.cfengine#");
        }

        fileWrite(resolvePath(".env.#arguments.environment#"), arrayToList(envContent, chr(10)));
    }

    /**
     * Update server.json configuration
     */
    private function updateServerConfig(environment, config) {
        var serverJsonPath = resolvePath("server.json");
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
        if (arguments.config.keyExists("datasource")) {
            var ds = arguments.config.datasource;
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
        var compose = "version: '3.8'

services:
  app:
    build: .
    ports:
      - ""8080:8080""
    environment:
      - WHEELS_ENV=#arguments.environment#
      - DB_HOST=db
      - DB_PORT=#getDatabasePort(arguments.database)#
      - DB_NAME=wheels
      - DB_USER=wheels
      - DB_PASSWORD=wheels_password
    volumes:
      - .:/app
    depends_on:
      - db

  db:
    image: #getDatabaseImage(arguments.database)#
    ports:
      - ""##getDatabasePort(arguments.database)##:##getDatabasePort(arguments.database)##""
    environment:
      ##getDatabaseEnvironment(arguments.database)##
    volumes:
      - db_data:/var/lib/##getDatabaseVolumeDir(arguments.database)##

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
##getProvisionDatabase(arguments.database)##

## Setup application
cd /vagrant
box install
box server start port=8080 host=0.0.0.0";
    }

    /**
     * Load environment configuration
     */
    private function loadEnvironmentConfig(environment) {
        var config = {};
        var envFile = resolvePath(".env.#arguments.environment#");

        if (fileExists(envFile)) {
            var lines = fileRead(envFile).listToArray(chr(10));
            for (var line in lines) {
                line = trim(line);
                if (len(line) && !line.startsWith("####")) {
                    var parts = line.listToArray("=");
                    if (arrayLen(parts) >= 2) {
                        var key = trim(parts[1]);
                        var value = trim(arrayToList(parts.subList(2, arrayLen(parts)), "="));
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
    private function getDatabaseDriver(database) {
        switch (arguments.database) {
            case "mysql": return "MySQL";
            case "postgres": return "PostgreSQL";
            case "mssql": return "MSSQL";
            default: return "H2";
        }
    }

    private function getDatabasePort(database) {
        switch (arguments.database) {
            case "mysql": return 3306;
            case "postgres": return 5432;
            case "mssql": return 1433;
            default: return 9092;
        }
    }

    private function getDatabaseImage(database) {
        switch (arguments.database) {
            case "mysql": return "mysql:8";
            case "postgres": return "postgres:14";
            case "mssql": return "mcr.microsoft.com/mssql/server:2019-latest";
            default: return "oscarfonts/h2:latest";
        }
    }

    private function getDatabaseEnvironment(database) {
        switch (arguments.database) {
            case "mysql":
                return "MYSQL_ROOT_PASSWORD=root_password
      MYSQL_DATABASE=wheels
      MYSQL_USER=wheels
      MYSQL_PASSWORD=wheels_password";
            case "postgres":
                return "POSTGRES_DB=wheels
      POSTGRES_USER=wheels
      POSTGRES_PASSWORD=wheels_password";
            case "mssql":
                return "ACCEPT_EULA=Y
      SA_PASSWORD=Wheels_Pass123!";
            default:
                return "H2_OPTIONS=-ifNotExists";
        }
    }

    private function getDatabaseVolumeDir(database) {
        switch (arguments.database) {
            case "mysql": return "mysql";
            case "postgres": return "postgresql/data";
            case "mssql": return "mssql";
            default: return "h2";
        }
    }

    private function getProvisionDatabase(database) {
        switch (arguments.database) {
            case "mysql":
                return "apt-get install -y mysql-server
mysql -e ""CREATE DATABASE wheels;""
mysql -e ""CREATE USER 'wheels'@'localhost' IDENTIFIED BY 'wheels_password';""
mysql -e ""GRANT ALL ON wheels.* TO 'wheels'@'localhost';""";
            case "postgres":
                return "apt-get install -y postgresql postgresql-contrib
sudo -u postgres createdb wheels
sudo -u postgres psql -c ""CREATE USER wheels WITH PASSWORD 'wheels_password';""
sudo -u postgres psql -c ""GRANT ALL PRIVILEGES ON DATABASE wheels TO wheels;""";
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
}
