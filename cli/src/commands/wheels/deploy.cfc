/**
 * Deploy Wheels applications to production servers
 * 
 * {code:bash}
 * wheels deploy
 * wheels deploy --help
 * {code}
 */
component extends="base" {

    /**
     * @help Show deployment help and available commands
     */
    function run(
        boolean help=true
    ) {
        print.line();
        print.boldMagentaLine("Wheels Deploy - Production Deployment System");
        print.line("=".repeatString(60));
        print.line();
        print.line("Deploy your Wheels applications to any server with zero-downtime deployments,");
        print.line("automatic SSL certificates, and built-in database management.");
        print.line();
        
        print.boldLine("Available Commands:");
        print.line();
        
        // Initialize
        print.greenLine("  wheels deploy:init");
        print.line("    Initialize deployment configuration for your project");
        print.line("    Creates deploy.json, Dockerfile, and .env.deploy files");
        print.line();
        
        // Setup
        print.greenLine("  wheels deploy:setup");
        print.line("    Provision and prepare servers for deployment");
        print.line("    Installs Docker, creates directories, and configures Traefik");
        print.line();
        
        // Push
        print.greenLine("  wheels deploy:push");
        print.line("    Build and deploy your application to configured servers");
        print.line("    Supports zero-downtime rolling deployments");
        print.line();
        
        // Status
        print.greenLine("  wheels deploy:status");
        print.line("    Check deployment status across all servers");
        print.line("    Shows container health, uptime, and system status");
        print.line();
        
        // Logs
        print.greenLine("  wheels deploy:logs");
        print.line("    View application logs from deployed containers");
        print.line("    Supports live streaming with --follow");
        print.line();
        
        // Rollback
        print.greenLine("  wheels deploy:rollback");
        print.line("    Rollback to a previous deployment version");
        print.line("    Lists available versions for easy selection");
        print.line();
        
        // Exec
        print.greenLine("  wheels deploy:exec");
        print.line("    Execute commands inside deployed containers");
        print.line("    Useful for maintenance tasks and debugging");
        print.line();
        
        // Stop
        print.greenLine("  wheels deploy:stop");
        print.line("    Stop deployed containers on servers");
        print.line("    Use --remove to completely remove containers");
        print.line();
        
        // Lock
        print.greenLine("  wheels deploy:lock [action]");
        print.line("    Manage deployment locks (acquire, release, status)");
        print.line("    Prevents concurrent deployments");
        print.line();
        
        // Secrets
        print.greenLine("  wheels deploy:secrets [action]");
        print.line("    Manage deployment secrets (push, pull, set, list)");
        print.line("    Integrates with password managers");
        print.line();
        
        // Hooks
        print.greenLine("  wheels deploy:hooks [action]");
        print.line("    Manage deployment lifecycle hooks");
        print.line("    Create custom pre/post deployment scripts");
        print.line();
        
        // Proxy
        print.greenLine("  wheels deploy:proxy [action]");
        print.line("    Manage zero-downtime deployment proxy");
        print.line("    Handles traffic during deployments");
        print.line();
        
        // Audit
        print.greenLine("  wheels deploy:audit");
        print.line("    View deployment audit trail");
        print.line("    Track all deployment actions");
        print.line();
        
        print.boldLine("Quick Start:");
        print.line();
        print.yellowLine("  1. wheels deploy:init                    ## Create deployment config");
        print.yellowLine("  2. Edit deploy.json and .env.deploy     ## Configure your deployment");
        print.yellowLine("  3. wheels deploy:setup                   ## Prepare your servers");
        print.yellowLine("  4. wheels deploy:push                    ## Deploy your application");
        print.line();
        
        print.boldLine("Example Workflow:");
        print.line();
        print.line("  ## Initialize with DigitalOcean");
        print.cyanLine("  wheels deploy:init --provider=digitalocean --domain=myapp.com");
        print.line();
        print.line("  ## Initialize staging environment");
        print.cyanLine("  wheels deploy:init --environment=staging --servers=192.168.1.50");
        print.line();
        print.line("  ## Setup servers with custom SSH key");
        print.cyanLine("  wheels deploy:setup --sshKey=~/.ssh/deploy_key");
        print.line();
        print.line("  ## Set secrets from password manager");
        print.cyanLine("  wheels deploy:secrets pull --manager=1password");
        print.cyanLine("  wheels deploy:secrets push");
        print.line();
        print.line("  ## Create deployment hooks");
        print.cyanLine("  wheels deploy:hooks create pre-deploy");
        print.cyanLine("  wheels deploy:hooks create post-deploy");
        print.line();
        print.line("  ## Boot zero-downtime proxy");
        print.cyanLine("  wheels deploy:proxy boot");
        print.line();
        print.line("  ## Deploy with custom tag");
        print.cyanLine("  wheels deploy:push --tag=v1.0.0");
        print.line();
        print.line("  ## Deploy to staging");
        print.cyanLine("  wheels deploy:push --destination=staging");
        print.line();
        print.line("  ## Check deployment status");
        print.cyanLine("  wheels deploy:status --detailed");
        print.line();
        print.line("  ## View audit trail");
        print.cyanLine("  wheels deploy:audit --lines=50");
        print.line();
        print.line("  ## View live logs");
        print.cyanLine("  wheels deploy:logs --follow --tail=100");
        print.line();
        
        print.boldLine("Configuration (deploy.json):");
        print.line();
        print.line("  The deploy.json file controls all aspects of deployment:");
        print.line("  - Server configuration and SSH settings");
        print.line("  - Docker registry and image settings");
        print.line("  - Environment variables and secrets");
        print.line("  - Health check and monitoring configuration");
        print.line("  - SSL/TLS certificate automation via Traefik");
        print.line("  - Database and accessory services");
        print.line();
        
        print.boldLine("Advanced Features:");
        print.line();
        print.line("  🔒 Deployment Locking - Prevents concurrent deployments");
        print.line("  🔐 Secrets Management - Integration with 1Password, Bitwarden, LastPass");
        print.line("  🪝 Lifecycle Hooks - Custom scripts for pre/post deployment actions");
        print.line("  🌍 Multi-Environment - Separate configs for staging/production");
        print.line("  📊 Audit Trail - Complete history of all deployment actions");
        print.line("  🚀 Zero-Downtime - Traffic management during deployments");
        print.line();
        
        print.line("For more information on a specific command, run:");
        print.greenLine("  wheels help deploy:[command]");
        print.line();
    }
}