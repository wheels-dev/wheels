/**
 * Manage zero-downtime deployment proxy
 * 
 * {code:bash}
 * wheels deploy:proxy boot
 * wheels deploy:proxy status
 * wheels deploy:proxy reboot
 * wheels deploy:proxy remove
 * {code}
 */
component extends="./base" {

    /**
     * @action Proxy action (boot, status, reboot, remove, details)
     * @servers Specific servers to manage proxy on
     * @force Force action without confirmation
     */
    function run(
        required string action,
        string servers="",
        boolean force=false
    ) {
        var deployConfig = loadDeployConfig();
        if (isNull(deployConfig)) {
            return;
        }
        
        print.line();
        print.boldMagentaLine("Wheels Deploy Proxy Management");
        print.line("=".repeatString(50));
        
        switch(arguments.action) {
            case "boot":
                bootProxy(deployConfig, arguments.servers);
                break;
                
            case "status":
                proxyStatus(deployConfig, arguments.servers);
                break;
                
            case "reboot":
                rebootProxy(deployConfig, arguments.servers, arguments.force);
                break;
                
            case "remove":
                removeProxy(deployConfig, arguments.servers, arguments.force);
                break;
                
            case "details":
                proxyDetails(deployConfig, arguments.servers);
                break;
                
            default:
                print.redLine("Invalid action: #arguments.action#");
                print.line("Valid actions: boot, status, reboot, remove, details");
        }
    }
    
    private void function bootProxy(required struct config, required string servers) {
        print.boldLine("Booting deployment proxy...");
        print.line();
        
        var targetServers = getTargetServers(arguments.config, arguments.servers);
        if (arrayIsEmpty(targetServers)) {
            return;
        }
        
        var sshUser = arguments.config.ssh.user ?: "root";
        
        for (var server in targetServers) {
            print.yellowLine("Booting proxy on #server#...");
            
            // Create proxy directory
            $execBash("ssh #sshUser#@#server# 'mkdir -p /opt/wheels-proxy'");
            
            // Create proxy configuration
            var proxyConfig = generateProxyConfig(arguments.config, server);
            
            // Write configuration
            $execBash("ssh #sshUser#@#server# 'cat > /opt/wheels-proxy/docker-compose.yml << EOF
#proxyConfig#
EOF'");
            
            // Start proxy
            var result = $execBash("ssh #sshUser#@#server# 'cd /opt/wheels-proxy && docker compose up -d'");
            
            if (result.exitCode == 0) {
                print.greenLine("✓ Proxy booted on #server#");
                
                // Wait for proxy to be ready
                sleep(2000);
                
                // Configure health check endpoint
                configureHealthCheck(server, sshUser);
            } else {
                print.redLine("✗ Failed to boot proxy on #server#");
                if (len(result.error)) {
                    print.redLine("Error: #result.error#");
                }
            }
        }
        
        // Log action
        deployAuditLog("proxy_booted", {
            "servers": targetServers
        });
        
        print.line();
        print.greenLine("✓ Proxy boot completed");
    }
    
    private void function proxyStatus(required struct config, required string servers) {
        print.boldLine("Checking proxy status...");
        print.line();
        
        var targetServers = getTargetServers(arguments.config, arguments.servers);
        if (arrayIsEmpty(targetServers)) {
            return;
        }
        
        var sshUser = arguments.config.ssh.user ?: "root";
        var allHealthy = true;
        
        for (var server in targetServers) {
            print.boldLine("Server: #server#");
            print.line("-".repeatString(30));
            
            // Check if proxy container is running
            var result = $execBash("ssh #sshUser#@#server# 'docker ps --filter name=wheels-proxy --format ""{{.Status}}""'");
            
            if (result.exitCode == 0 && len(trim(result.output))) {
                if (result.output contains "Up") {
                    print.greenLine("✓ Proxy Running");
                    print.line("  Status: #trim(result.output)#");
                    
                    // Check proxy health
                    var healthResult = $execBash("ssh #sshUser#@#server# 'docker exec wheels-proxy wget -qO- http://localhost/health || echo FAILED'");
                    
                    if (trim(healthResult.output) != "FAILED") {
                        print.greenLine("✓ Health Check Passed");
                    } else {
                        print.redLine("✗ Health Check Failed");
                        allHealthy = false;
                    }
                } else {
                    print.redLine("✗ Proxy Not Healthy");
                    print.line("  Status: #trim(result.output)#");
                    allHealthy = false;
                }
            } else {
                print.redLine("✗ Proxy Not Found");
                allHealthy = false;
            }
            
            print.line();
        }
        
        if (allHealthy) {
            print.boldGreenLine("Overall Status: ✓ All Proxies Healthy");
        } else {
            print.boldRedLine("Overall Status: ✗ Issues Detected");
        }
    }
    
    private void function rebootProxy(required struct config, required string servers, required boolean force) {
        if (!arguments.force) {
            print.yellowLine("WARNING: This will restart the proxy and may cause brief downtime");
            var confirm = ask("Are you sure you want to continue? (yes/no): ");
            
            if (lCase(trim(confirm)) != "yes") {
                print.line("Operation cancelled");
                return;
            }
        }
        
        print.boldLine("Rebooting proxy...");
        print.line();
        
        var targetServers = getTargetServers(arguments.config, arguments.servers);
        if (arrayIsEmpty(targetServers)) {
            return;
        }
        
        var sshUser = arguments.config.ssh.user ?: "root";
        
        for (var server in targetServers) {
            print.yellowLine("Rebooting proxy on #server#...");
            
            var result = $execBash("ssh #sshUser#@#server# 'cd /opt/wheels-proxy && docker compose restart'");
            
            if (result.exitCode == 0) {
                print.greenLine("✓ Proxy rebooted on #server#");
            } else {
                print.redLine("✗ Failed to reboot proxy on #server#");
            }
        }
        
        // Log action
        deployAuditLog("proxy_rebooted", {
            "servers": targetServers
        });
        
        print.line();
        print.greenLine("✓ Proxy reboot completed");
    }
    
    private void function removeProxy(required struct config, required string servers, required boolean force) {
        if (!arguments.force) {
            print.redLine("WARNING: This will remove the proxy and disable zero-downtime deployments");
            var confirm = ask("Are you sure you want to continue? (yes/no): ");
            
            if (lCase(trim(confirm)) != "yes") {
                print.line("Operation cancelled");
                return;
            }
        }
        
        print.boldLine("Removing proxy...");
        print.line();
        
        var targetServers = getTargetServers(arguments.config, arguments.servers);
        if (arrayIsEmpty(targetServers)) {
            return;
        }
        
        var sshUser = arguments.config.ssh.user ?: "root";
        
        for (var server in targetServers) {
            print.yellowLine("Removing proxy from #server#...");
            
            var result = $execBash("ssh #sshUser#@#server# 'cd /opt/wheels-proxy && docker compose down -v && rm -rf /opt/wheels-proxy'");
            
            if (result.exitCode == 0) {
                print.greenLine("✓ Proxy removed from #server#");
            } else {
                print.redLine("✗ Failed to remove proxy from #server#");
            }
        }
        
        // Log action
        deployAuditLog("proxy_removed", {
            "servers": targetServers
        });
        
        print.line();
        print.greenLine("✓ Proxy removal completed");
    }
    
    private void function proxyDetails(required struct config, required string servers) {
        print.boldLine("Proxy Configuration Details");
        print.line();
        
        var targetServers = getTargetServers(arguments.config, arguments.servers);
        if (arrayIsEmpty(targetServers)) {
            return;
        }
        
        var sshUser = arguments.config.ssh.user ?: "root";
        
        for (var server in targetServers) {
            print.boldLine("Server: #server#");
            print.line("-".repeatString(30));
            
            // Get proxy configuration
            var configResult = $execBash("ssh #sshUser#@#server# 'cat /opt/wheels-proxy/docker-compose.yml 2>/dev/null'");
            
            if (configResult.exitCode == 0) {
                print.line("Configuration:");
                print.line(configResult.output);
            } else {
                print.redLine("No proxy configuration found");
            }
            
            // Get container details
            var detailsResult = $execBash("ssh #sshUser#@#server# 'docker inspect wheels-proxy --format ""Name: {{.Name}}\nCreated: {{.Created}}\nState: {{.State.Status}}\nRestarts: {{.RestartCount}}""'");
            
            if (detailsResult.exitCode == 0) {
                print.line();
                print.line("Container Details:");
                print.line(detailsResult.output);
            }
            
            print.line();
        }
    }
    
    private string function generateProxyConfig(required struct config, required string server) {
        savecontent variable="compose" {
            writeOutput("version: '3.8'" & chr(10));
            writeOutput(chr(10));
            writeOutput("services:" & chr(10));
            writeOutput("  wheels-proxy:" & chr(10));
            writeOutput("    image: traefik:v3.0" & chr(10));
            writeOutput("    container_name: wheels-proxy" & chr(10));
            writeOutput("    restart: unless-stopped" & chr(10));
            writeOutput("    ports:" & chr(10));
            writeOutput("      - '80:80'" & chr(10));
            writeOutput("      - '443:443'" & chr(10));
            writeOutput("    volumes:" & chr(10));
            writeOutput("      - /var/run/docker.sock:/var/run/docker.sock:ro" & chr(10));
            writeOutput("      - ./letsencrypt:/letsencrypt" & chr(10));
            writeOutput("      - ./config:/config" & chr(10));
            writeOutput("    command:" & chr(10));
            writeOutput("      ## API" & chr(10));
            writeOutput("      - --api.dashboard=false" & chr(10));
            writeOutput("      " & chr(10));
            writeOutput("      ## Docker provider" & chr(10));
            writeOutput("      - --providers.docker=true" & chr(10));
            writeOutput("      - --providers.docker.exposedbydefault=false" & chr(10));
            writeOutput("      - --providers.docker.network=wheels" & chr(10));
            writeOutput("      " & chr(10));
            writeOutput("      ## Entrypoints" & chr(10));
            writeOutput("      - --entrypoints.web.address=:80" & chr(10));
            writeOutput("      - --entrypoints.websecure.address=:443" & chr(10));
            writeOutput("      " & chr(10));
            writeOutput("      ## HTTP to HTTPS redirect" & chr(10));
            writeOutput("      - --entrypoints.web.http.redirections.entrypoint.to=websecure" & chr(10));
            writeOutput("      - --entrypoints.web.http.redirections.entrypoint.scheme=https" & chr(10));
            writeOutput("      " & chr(10));
            writeOutput("      ## Let's Encrypt" & chr(10));
            writeOutput("      - --certificatesresolvers.letsencrypt.acme.email=admin@#arguments.config.domain ?: 'example.com'#" & chr(10));
            writeOutput("      - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json" & chr(10));
            writeOutput("      - --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web" & chr(10));
            writeOutput("      " & chr(10));
            writeOutput("      ## Logging" & chr(10));
            writeOutput("      - --log.level=INFO" & chr(10));
            writeOutput("      - --accesslog=true" & chr(10));
            writeOutput("    networks:" & chr(10));
            writeOutput("      - wheels" & chr(10));
            writeOutput("    labels:" & chr(10));
            writeOutput("      - traefik.enable=true" & chr(10));
            writeOutput("      - traefik.http.routers.api.service=noop@internal" & chr(10));
            writeOutput(chr(10));
            writeOutput("networks:" & chr(10));
            writeOutput("  wheels:" & chr(10));
            writeOutput("    external: true");
        };
        
        return compose;
    }
    
    private void function configureHealthCheck(required string server, required string user) {
        // Create wheels network if it doesn't exist
        $execBash("ssh #arguments.user#@#arguments.server# 'docker network create wheels || true'");
        
        // Create a simple health check response
        var healthConfig = "events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        location /health {
            return 200 'OK';
        }
    }
}";
        
        $execBash("ssh #arguments.user#@#arguments.server# 'mkdir -p /opt/wheels-proxy/config && cat > /opt/wheels-proxy/config/nginx.conf << EOF
#healthConfig#
EOF'");
    }
    
    private array function getTargetServers(required struct config, required string servers) {
        var targetServers = [];
        
        if (len(arguments.servers)) {
            targetServers = listToArray(arguments.servers);
        } else if (structKeyExists(arguments.config, "servers") && structKeyExists(arguments.config.servers, "web")) {
            targetServers = arguments.config.servers.web;
        }
        
        if (arrayIsEmpty(targetServers)) {
            print.redLine("No servers configured!");
        }
        
        return targetServers;
    }
}