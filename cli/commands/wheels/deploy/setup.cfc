/**
 * Setup and provision servers for deployment
 * 
 * {code:bash}
 * wheels deploy:setup
 * wheels deploy:setup --skip-docker
 * wheels deploy:setup --servers=192.168.1.100
 * {code}
 */
component extends="./base" {

    /**
     * @servers Specific servers to setup (comma-separated IPs)
     * @skipDocker Skip Docker installation
     * @skipTraefik Skip Traefik setup
     * @sshKey Path to SSH private key
     * @force Force reinstall of components
     */
    function run(
        string servers="",
        boolean skipDocker=false,
        boolean skipTraefik=false,
        string sshKey="",
        boolean force=false
    ) {
        var deployConfig = loadDeployConfig();
        if (isNull(deployConfig)) {
            return;
        }
        
        print.line();
        print.boldMagentaLine("Wheels Deploy Server Setup");
        print.line("=".repeatString(50));
        
        // Determine which servers to setup
        var serversToSetup = [];
        if (len(arguments.servers)) {
            serversToSetup = listToArray(arguments.servers);
        } else if (structKeyExists(deployConfig, "servers") && structKeyExists(deployConfig.servers, "web")) {
            serversToSetup = deployConfig.servers.web;
        } else {
            print.redLine("No servers configured! Run 'wheels deploy:init' first.");
            return;
        }
        
        print.line("Setting up #arrayLen(serversToSetup)# server(s)...");
        print.line();
        
        // Build SSH options
        var sshOptions = "";
        if (len(arguments.sshKey)) {
            sshOptions = "-i #arguments.sshKey#";
        }
        
        var sshUser = deployConfig.ssh.user ?: "root";
        
        // Setup each server
        for (var server in serversToSetup) {
            print.boldLine("Server: #server#");
            print.line("-".repeatString(30));
            
            // Test SSH connection
            print.yellowLine("Testing SSH connection...");
            var result = $execBash("ssh #sshOptions# -o ConnectTimeout=10 -o StrictHostKeyChecking=no #sshUser#@#server# 'echo Connection successful'");
            
            if (result.exitCode != 0) {
                print.redLine("✗ Failed to connect to #server#");
                print.redLine("  Error: #result.error#");
                continue;
            }
            print.greenLine("✓ SSH connection successful");
            
            // Install Docker if needed
            if (!arguments.skipDocker) {
                print.yellowLine("Installing Docker...");
                
                var dockerCommands = [
                    "apt-get update",
                    "apt-get install -y ca-certificates curl gnupg",
                    "install -m 0755 -d /etc/apt/keyrings",
                    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
                    "chmod a+r /etc/apt/keyrings/docker.gpg",
                    'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null',
                    "apt-get update",
                    "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
                    "systemctl enable docker",
                    "systemctl start docker"
                ];
                
                for (var cmd in dockerCommands) {
                    result = $execBash("ssh #sshOptions# #sshUser#@#server# '#cmd#'");
                    if (result.exitCode != 0 && !arguments.force) {
                        print.redLine("✗ Docker installation failed");
                        break;
                    }
                }
                
                // Verify Docker installation
                result = $execBash("ssh #sshOptions# #sshUser#@#server# 'docker --version'");
                if (result.exitCode == 0) {
                    print.greenLine("✓ Docker installed successfully");
                }
            }
            
            // Setup directories
            print.yellowLine("Creating deployment directories...");
            var directories = [
                "/opt/#deployConfig.service#",
                "/opt/#deployConfig.service#/config",
                "/opt/#deployConfig.service#/storage",
                "/opt/#deployConfig.service#/logs"
            ];
            
            for (var dir in directories) {
                $execBash("ssh #sshOptions# #sshUser#@#server# 'mkdir -p #dir#'");
            }
            print.greenLine("✓ Directories created");
            
            // Setup Traefik if enabled
            if (!arguments.skipTraefik && structKeyExists(deployConfig, "traefik") && deployConfig.traefik.enabled) {
                print.yellowLine("Setting up Traefik...");
                
                // Create Traefik network
                $execBash("ssh #sshOptions# #sshUser#@#server# 'docker network create traefik || true'");
                
                // Create Traefik directories
                $execBash("ssh #sshOptions# #sshUser#@#server# 'mkdir -p /opt/traefik /opt/traefik/letsencrypt'");
                
                // Create Traefik config
                var traefikConfig = "version: '3.8'

services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /opt/traefik/letsencrypt:/letsencrypt
    command:
      - --api.dashboard=false
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --entrypoints.web.http.redirections.entrypoint.to=websecure
      - --entrypoints.web.http.redirections.entrypoint.scheme=https
      - --certificatesresolvers.letsencrypt.acme.email=admin@#deployConfig.traefik.args['certificatesresolvers.letsencrypt.acme.email']#
      - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json
      - --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web
    networks:
      - traefik

networks:
  traefik:
    external: true";
                
                // Write Traefik config to server
                $execBash("ssh #sshOptions# #sshUser#@#server# 'cat > /opt/traefik/docker-compose.yml << EOF
#traefikConfig#
EOF'");
                
                // Start Traefik
                result = $execBash("ssh #sshOptions# #sshUser#@#server# 'cd /opt/traefik && docker compose up -d'");
                
                if (result.exitCode == 0) {
                    print.greenLine("✓ Traefik setup completed");
                } else {
                    print.redLine("✗ Traefik setup failed");
                }
            }
            
            // Configure firewall
            print.yellowLine("Configuring firewall...");
            var firewallCommands = [
                "ufw allow 22/tcp",
                "ufw allow 80/tcp", 
                "ufw allow 443/tcp",
                "ufw --force enable"
            ];
            
            for (var cmd in firewallCommands) {
                $execBash("ssh #sshOptions# #sshUser#@#server# '#cmd#' || true");
            }
            print.greenLine("✓ Firewall configured");
            
            print.line();
            print.greenLine("✓ Server #server# setup completed!");
            print.line();
        }
        
        print.boldGreenLine("Server setup completed!");
        print.line();
        print.line("Next step: Run 'wheels deploy:push' to deploy your application");
        print.line();
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