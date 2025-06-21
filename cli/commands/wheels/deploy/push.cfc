/**
 * Deploy your Wheels application to configured servers
 * 
 * {code:bash}
 * wheels deploy:push
 * wheels deploy:push tag=v1.0.0
 * wheels deploy:push build=false rolling=true
 * {code}
 */
component extends="./base" {

    /**
     * @tag Docker image tag (defaults to timestamp)
     * @build Build Docker image locally
     * @push Push image to registry
     * @rolling Use rolling deployment
     * @servers Deploy to specific servers (comma-separated)
     * @destination Deployment destination/environment
     * @timeout Deployment timeout in seconds
     * @healthTimeout Health check timeout in seconds
     */
    function run(
        string tag="",
        boolean build=true,
        boolean push=true,
        boolean rolling=true,
        string servers="",
        string destination="",
        numeric timeout=600,
        numeric healthTimeout=300
    ) {
        var deployConfig = loadDeployConfig(arguments.destination);
        if (isNull(deployConfig)) {
            return;
        }
        
        // Check for existing lock
        requireDeploymentLock();
        
        print.line();
        print.boldMagentaLine("Wheels Application Deployment");
        print.line("=".repeatString(50));
        
        // Acquire deployment lock
        print.yellowLine("Acquiring deployment lock...");
        if (!acquireDeploymentLock("Deploying application")) {
            print.redLine("✗ Failed to acquire deployment lock");
            print.line("Another deployment may be in progress");
            return;
        }
        
        print.greenLine("✓ Deployment lock acquired");
        
        // Log deployment start
        deployAuditLog("deployment_started", {
            "tag": arguments.tag,
            "build": arguments.build,
            "rolling": arguments.rolling,
            "servers": arguments.servers
        });
        
        try {
        
        // Run pre-connect hook
        var hooks = new hooks();
        var hookEnv = {
            "KAMAL_VERSION": arguments.tag,
            "KAMAL_DESTINATION": structKeyExists(deployConfig, "_environment") ? deployConfig._environment : "production"
        };
        hooks.executeHook("pre-connect", hookEnv);
        
        // Generate tag if not provided
        if (!len(arguments.tag)) {
            arguments.tag = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
        }
        
        var imageName = deployConfig.registry.server & "/" & deployConfig.registry.username & "/" & deployConfig.image & ":" & arguments.tag;
        
        print.line("Deploying: #imageName#");
        print.line();
        
        // Run pre-build hook
        hooks.executeHook("pre-build", {
            "KAMAL_VERSION": arguments.tag
        });
        
        // Build Docker image
        if (arguments.build) {
            print.boldLine("Building Docker image...");
            print.line();
            
            var buildResult = $execBash("docker build -t #deployConfig.image#:#arguments.tag# -t #imageName# .");
            
            if (buildResult.exitCode != 0) {
                print.redLine("✗ Docker build failed!");
                print.redLine(buildResult.error);
                return;
            }
            
            print.greenLine("✓ Docker image built successfully");
            print.line();
        }
        
        // Push to registry
        if (arguments.push) {
            print.boldLine("Pushing image to registry...");
            
            // Login to registry
            print.yellowLine("Logging into registry...");
            var loginResult = $execBash("docker login #deployConfig.registry.server# -u #deployConfig.registry.username#");
            
            if (loginResult.exitCode != 0) {
                print.redLine("✗ Registry login failed!");
                print.line("Make sure you have configured registry credentials");
                return;
            }
            
            // Push image
            var pushResult = $execBash("docker push #imageName#");
            
            if (pushResult.exitCode != 0) {
                print.redLine("✗ Image push failed!");
                print.redLine(pushResult.error);
                return;
            }
            
            print.greenLine("✓ Image pushed to registry");
            print.line();
        }
        
        // Determine target servers
        var targetServers = [];
        if (len(arguments.servers)) {
            targetServers = listToArray(arguments.servers);
        } else if (structKeyExists(deployConfig, "servers") && structKeyExists(deployConfig.servers, "web")) {
            targetServers = deployConfig.servers.web;
        }
        
        if (arrayIsEmpty(targetServers)) {
            print.redLine("No servers configured for deployment!");
            return;
        }
        
        print.boldLine("Deploying to #arrayLen(targetServers)# server(s)...");
        print.line();
        
        // Run pre-deploy hook
        hooks.executeHook("pre-deploy", {
            "KAMAL_VERSION": arguments.tag,
            "KAMAL_HOSTS": arrayToList(targetServers)
        });
        
        var sshUser = deployConfig.ssh.user ?: "root";
        var serviceName = deployConfig.service;
        
        // Deploy to each server
        for (var server in targetServers) {
            print.boldLine("Deploying to: #server#");
            print.line("-".repeatString(30));
            
            // Create environment file on server
            print.yellowLine("Copying environment configuration...");
            var envPath = fileSystemUtil.resolvePath(".env.deploy");
            if (fileExists(envPath)) {
                $execBash("scp #envPath# #sshUser#@#server#:/opt/#serviceName#/.env");
            }
            
            // Create docker-compose file for the application
            var composeContent = generateDockerCompose(deployConfig, imageName);
            
            // Write compose file to server
            $execBash("ssh #sshUser#@#server# 'cat > /opt/#serviceName#/docker-compose.yml << EOF
#composeContent#
EOF'");
            
            // Pull new image
            print.yellowLine("Pulling new image...");
            var pullResult = $execBash("ssh #sshUser#@#server# 'docker pull #imageName#'");
            
            if (pullResult.exitCode != 0) {
                print.redLine("✗ Failed to pull image on #server#");
                continue;
            }
            
            // Deploy with zero-downtime if rolling
            if (arguments.rolling) {
                print.yellowLine("Performing rolling deployment...");
                
                // Start new container with temporary name
                $execBash("ssh #sshUser#@#server# 'cd /opt/#serviceName# && docker compose up -d --no-deps --scale #serviceName#=2 #serviceName#'");
                
                // Wait for health check
                print.yellowLine("Waiting for health check...");
                var healthy = waitForHealthCheck(server, deployConfig, arguments.healthTimeout);
                
                if (healthy) {
                    print.greenLine("✓ Health check passed");
                    
                    // Remove old container
                    $execBash("ssh #sshUser#@#server# 'cd /opt/#serviceName# && docker compose up -d --no-deps --remove-orphans #serviceName#'");
                } else {
                    print.redLine("✗ Health check failed, rolling back...");
                    $execBash("ssh #sshUser#@#server# 'cd /opt/#serviceName# && docker compose down'");
                    continue;
                }
            } else {
                // Simple restart
                print.yellowLine("Restarting application...");
                $execBash("ssh #sshUser#@#server# 'cd /opt/#serviceName# && docker compose down && docker compose up -d'");
            }
            
            // Clean up old images
            print.yellowLine("Cleaning up old images...");
            $execBash("ssh #sshUser#@#server# 'docker image prune -f'");
            
            print.greenLine("✓ Deployment to #server# completed");
            print.line();
        }
        
        print.line();
        print.boldGreenLine("Deployment completed successfully!");
        print.line();
        print.line("Image deployed: #imageName#");
        print.line();
        
        // Log deployment completion
        deployAuditLog("deployment_completed", {
            "tag": arguments.tag,
            "image": imageName,
            "servers": targetServers
        });
        
        // Run post-deploy hook
        hooks.executeHook("post-deploy", {
            "KAMAL_VERSION": arguments.tag,
            "KAMAL_HOSTS": arrayToList(targetServers)
        });
        
        } catch (any e) {
            // Log deployment failure
            deployAuditLog("deployment_failed", {
                "tag": arguments.tag,
                "error": e.message
            });
            
            print.line();
            print.redLine("✗ Deployment failed: #e.message#");
            
            // Always release lock
            releaseDeploymentLock();
            rethrow;
        }
        
        // Release deployment lock
        releaseDeploymentLock();
        
        // Show status
        print.line("Run 'wheels deploy:status' to check deployment status");
        print.line();
    }
    
    private string function generateDockerCompose(required struct config, required string image) {
        var compose = "version: '3.8'

services:
  #config.service#:
    image: #arguments.image#
    container_name: #config.service#
    restart: unless-stopped
    env_file:
      - .env
    environment:";
        
        // Add clear environment variables
        if (structKeyExists(config.env, "clear")) {
            for (var key in config.env.clear) {
                compose &= "
      - #key#=#config.env.clear[key]#";
            }
        }
        
        compose &= "
    ports:
      - '3000:3000'
    volumes:
      - ./storage:/app/storage
      - ./logs:/app/logs";
        
        // Add healthcheck
        if (structKeyExists(config, "healthcheck")) {
            compose &= "
    healthcheck:
      test: [""CMD"", ""curl"", ""-f"", ""http://localhost:#config.healthcheck.port##config.healthcheck.path#""]
      interval: #config.healthcheck.interval#s
      timeout: 10s
      retries: 3";
        }
        
        // Add Traefik labels if enabled
        if (structKeyExists(config, "traefik") && config.traefik.enabled) {
            compose &= "
    labels:
      - traefik.enable=true";
            
            for (var label in config.traefik.labels) {
                compose &= "
      - #label#=#config.traefik.labels[label]#";
            }
            
            compose &= "
    networks:
      - default
      - traefik";
        }
        
        // Add database service if configured
        if (structKeyExists(config, "accessories") && structKeyExists(config.accessories, "db")) {
            var db = config.accessories.db;
            compose &= "

  db:
    image: #db.image#
    container_name: #config.service#_db
    restart: unless-stopped
    environment:";
            
            // Add database-specific environment
            if (db.image contains "mysql") {
                compose &= "
      - MYSQL_ROOT_PASSWORD=${DB_PASSWORD}
      - MYSQL_DATABASE=${DB_NAME}
      - MYSQL_USER=${DB_USERNAME}
      - MYSQL_PASSWORD=${DB_PASSWORD}";
            } else if (db.image contains "postgres") {
                compose &= "
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USERNAME}";
            } else if (db.image contains "mssql") {
                compose &= "
      - ACCEPT_EULA=Y
      - SA_PASSWORD=${DB_PASSWORD}";
            }
            
            compose &= "
    volumes:";
            for (var volume in db.volumes) {
                compose &= "
      - #volume#";
            }
        }
        
        // Add networks section if using Traefik
        if (structKeyExists(config, "traefik") && config.traefik.enabled) {
            compose &= "

networks:
  traefik:
    external: true";
        }
        
        return compose;
    }
    
    private boolean function waitForHealthCheck(
        required string server,
        required struct config,
        required numeric timeout
    ) {
        var sshUser = config.ssh.user ?: "root";
        var startTime = getTickCount();
        var checkUrl = "http://#server#:#config.healthcheck.port##config.healthcheck.path#";
        
        while ((getTickCount() - startTime) < (arguments.timeout * 1000)) {
            var result = $execBash("ssh #sshUser#@#arguments.server# 'curl -f -s -o /dev/null -w ""%{http_code}"" #checkUrl#'");
            
            if (result.exitCode == 0 && trim(result.output) == "200") {
                return true;
            }
            
            sleep(5000); // Wait 5 seconds between checks
        }
        
        return false;
    }
}