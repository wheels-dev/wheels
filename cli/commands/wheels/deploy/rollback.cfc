/**
 * Rollback to a previous deployment
 * 
 * {code:bash}
 * wheels deploy:rollback
 * wheels deploy:rollback tag=v1.0.0
 * wheels deploy:rollback servers=192.168.1.100
 * {code}
 */
component extends="./base" {

    /**
     * @tag Specific tag to rollback to
     * @servers Rollback specific servers (comma-separated)
     * @force Skip confirmation prompt
     */
    function run(
        string tag="",
        string servers="",
        boolean force=false
    ) {
        var deployConfig = loadDeployConfig();
        if (isNull(deployConfig)) {
            return;
        }
        
        print.line();
        print.boldMagentaLine("Wheels Deployment Rollback");
        print.line("=".repeatString(50));
        
        // Determine target servers
        var targetServers = [];
        if (len(arguments.servers)) {
            targetServers = listToArray(arguments.servers);
        } else if (structKeyExists(deployConfig, "servers") && structKeyExists(deployConfig.servers, "web")) {
            targetServers = deployConfig.servers.web;
        }
        
        if (arrayIsEmpty(targetServers)) {
            print.redLine("No servers configured!");
            return;
        }
        
        var sshUser = deployConfig.ssh.user ?: "root";
        var serviceName = deployConfig.service;
        
        // If no tag specified, show available images and let user choose
        if (!len(arguments.tag)) {
            print.line("Fetching available images from servers...");
            print.line();
            
            var availableImages = [];
            var imagePattern = deployConfig.registry.server & "/" & deployConfig.registry.username & "/" & deployConfig.image;
            
            // Get images from first server
            var server = targetServers[1];
            var result = $execBash("ssh #sshUser#@#server# 'docker images #imagePattern# --format ""{{.Tag}}\t{{.CreatedAt}}""'");
            
            if (result.exitCode == 0 && len(trim(result.output))) {
                var lines = listToArray(result.output, chr(10));
                
                print.boldLine("Available versions:");
                print.line("-".repeatString(50));
                
                var index = 0;
                for (var line in lines) {
                    if (len(trim(line))) {
                        index++;
                        var parts = listToArray(line, chr(9));
                        if (arrayLen(parts) >= 2) {
                            availableImages.append(parts[1]);
                            print.line("#index#. Tag: #parts[1]# (Created: #parts[2]#)");
                        }
                    }
                }
                
                if (arrayIsEmpty(availableImages)) {
                    print.redLine("No previous images found!");
                    return;
                }
                
                print.line();
                var selection = ask("Select version to rollback to (1-#arrayLen(availableImages)#): ");
                
                if (isNumeric(selection) && selection >= 1 && selection <= arrayLen(availableImages)) {
                    arguments.tag = availableImages[selection];
                } else {
                    print.redLine("Invalid selection!");
                    return;
                }
            } else {
                print.redLine("Failed to fetch available images!");
                return;
            }
        }
        
        var imageName = deployConfig.registry.server & "/" & deployConfig.registry.username & "/" & deployConfig.image & ":" & arguments.tag;
        
        // Confirm rollback
        if (!arguments.force) {
            print.line();
            print.yellowLine("WARNING: This will rollback to version: #arguments.tag#");
            print.yellowLine("Target servers: #arrayToList(targetServers)#");
            print.line();
            
            var confirm = ask("Are you sure you want to continue? (yes/no): ");
            if (lCase(trim(confirm)) != "yes") {
                print.line("Rollback cancelled.");
                return;
            }
        }
        
        print.line();
        print.boldLine("Rolling back to: #imageName#");
        print.line();
        
        // Perform rollback on each server
        for (var server in targetServers) {
            print.boldLine("Rolling back: #server#");
            print.line("-".repeatString(30));
            
            // Check if image exists locally
            print.yellowLine("Checking for image...");
            var checkResult = $execBash("ssh #sshUser#@#server# 'docker images -q #imageName#'");
            
            if (!len(trim(checkResult.output))) {
                // Need to pull the image
                print.yellowLine("Image not found locally, pulling from registry...");
                var pullResult = $execBash("ssh #sshUser#@#server# 'docker pull #imageName#'");
                
                if (pullResult.exitCode != 0) {
                    print.redLine("✗ Failed to pull image on #server#");
                    continue;
                }
            }
            
            // Update docker-compose with new image
            print.yellowLine("Updating configuration...");
            var composeContent = generateDockerCompose(deployConfig, imageName);
            
            $execBash("ssh #sshUser#@#server# 'cat > /opt/#serviceName#/docker-compose.yml << EOF
#composeContent#
EOF'");
            
            // Perform rolling restart
            print.yellowLine("Performing rollback...");
            
            // Stop current container
            $execBash("ssh #sshUser#@#server# 'cd /opt/#serviceName# && docker compose down'");
            
            // Start with rollback image
            var startResult = $execBash("ssh #sshUser#@#server# 'cd /opt/#serviceName# && docker compose up -d'");
            
            if (startResult.exitCode != 0) {
                print.redLine("✗ Rollback failed on #server#");
                print.redLine(startResult.error);
                continue;
            }
            
            // Wait for health check
            print.yellowLine("Waiting for health check...");
            var healthy = waitForHealthCheck(server, deployConfig, 60);
            
            if (healthy) {
                print.greenLine("✓ Rollback successful on #server#");
            } else {
                print.redLine("✗ Health check failed after rollback on #server#");
            }
            
            print.line();
        }
        
        print.line();
        print.boldGreenLine("Rollback completed!");
        print.line();
        print.line("Rolled back to: #imageName#");
        print.line();
    }
    
    private string function generateDockerCompose(required struct config, required string image) {
        // Reuse the same function from push.cfc
        var compose = "version: '3.8'

services:
  #config.service#:
    image: #arguments.image#
    container_name: #config.service#
    restart: unless-stopped
    env_file:
      - .env
    environment:";
        
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
        
        if (structKeyExists(config, "healthcheck")) {
            compose &= "
    healthcheck:
      test: [""CMD"", ""curl"", ""-f"", ""http://localhost:#config.healthcheck.port##config.healthcheck.path#""]
      interval: #config.healthcheck.interval#s
      timeout: 10s
      retries: 3";
        }
        
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
        
        if (structKeyExists(config, "accessories") && structKeyExists(config.accessories, "db")) {
            var db = config.accessories.db;
            compose &= "

  db:
    image: #db.image#
    container_name: #config.service#_db
    restart: unless-stopped
    volumes:";
            for (var volume in db.volumes) {
                compose &= "
      - #volume#";
            }
        }
        
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
        var checkUrl = "http://localhost:#config.healthcheck.port##config.healthcheck.path#";
        
        while ((getTickCount() - startTime) < (arguments.timeout * 1000)) {
            var result = $execBash("ssh #sshUser#@#arguments.server# 'docker exec #config.service# curl -f -s -o /dev/null -w ""%{http_code}"" #checkUrl#'");
            
            if (result.exitCode == 0 && trim(result.output) == "200") {
                return true;
            }
            
            sleep(5000);
        }
        
        return false;
    }
    
    private any function loadDeployConfig() {
        var deployConfigPath = fileSystemUtil.resolvePath("deploy.json");
        
        if (!fileExists(deployConfigPath)) {
            print.redLine("deploy.json not found! Run 'wheels deploy:init' first.");
            return;
        }
        
        try {
            return deserializeJSON(fileRead(deployConfigPath));
        } catch (any e) {
            print.redLine("Error reading deploy.json: #e.message#");
            return;
        }
    }
    
    private struct function $execBash(required string command) {
        try {
            var result = runCommand(
                name="bash",
                arguments="-c ""#arguments.command#""",
                timeout=300
            );
            
            return {
                exitCode: result.status ?: 0,
                output: result.output ?: "",
                error: result.error ?: ""
            };
        } catch (any e) {
            return {
                exitCode: 1,
                output: "",
                error: e.message
            };
        }
    }
}