/**
 * Manage deployment secrets with password manager integration
 * 
 * {code:bash}
 * wheels deploy:secrets push
 * wheels deploy:secrets pull
 * wheels deploy:secrets set DB_PASSWORD
 * wheels deploy:secrets list
 * {code}
 */
component extends="./base" {

    /**
     * @action Action to perform (push, pull, set, list, remove)
     * @key Secret key name (for set/remove actions)
     * @value Secret value (for set action, optional - will prompt if not provided)
     * @manager Password manager to use (1password, bitwarden, lastpass, env)
     * @vault Vault/collection name in password manager
     */
    function run(
        required string action,
        string key="",
        string value="",
        string manager="env",
        string vault=""
    ) {
        var deployConfig = loadDeployConfig();
        if (isNull(deployConfig)) {
            return;
        }
        
        print.line();
        print.boldMagentaLine("Wheels Deploy Secrets Management");
        print.line("=".repeatString(50));
        
        switch(arguments.action) {
            case "push":
                pushSecrets(deployConfig, arguments.manager, arguments.vault);
                break;
                
            case "pull":
                pullSecrets(deployConfig, arguments.manager, arguments.vault);
                break;
                
            case "set":
                if (!len(arguments.key)) {
                    print.redLine("Secret key is required for set action");
                    return;
                }
                setSecret(arguments.key, arguments.value, arguments.manager, arguments.vault);
                break;
                
            case "list":
                listSecrets(deployConfig);
                break;
                
            case "remove":
                if (!len(arguments.key)) {
                    print.redLine("Secret key is required for remove action");
                    return;
                }
                removeSecret(arguments.key);
                break;
                
            default:
                print.redLine("Invalid action: #arguments.action#");
                print.line("Valid actions: push, pull, set, list, remove");
        }
    }
    
    private void function pushSecrets(
        required struct config,
        required string manager,
        required string vault
    ) {
        print.boldLine("Pushing secrets to servers...");
        print.line();
        
        // Load secrets from manager
        var secrets = loadSecretsFromManager(arguments.manager, arguments.vault, arguments.config);
        
        if (structIsEmpty(secrets)) {
            print.yellowLine("No secrets found to push");
            return;
        }
        
        // Get target servers
        var targetServers = [];
        if (structKeyExists(arguments.config, "servers") && structKeyExists(arguments.config.servers, "web")) {
            targetServers = arguments.config.servers.web;
        }
        
        if (arrayIsEmpty(targetServers)) {
            print.redLine("No servers configured!");
            return;
        }
        
        var sshUser = arguments.config.ssh.user ?: "root";
        var serviceName = arguments.config.service;
        
        // Create .kamal/secrets content
        var secretsContent = "";
        for (var key in secrets) {
            secretsContent &= key & "=" & secrets[key] & chr(10);
        }
        
        // Push to each server
        for (var server in targetServers) {
            print.yellowLine("Pushing to #server#...");
            
            // Create .kamal directory
            $execBash("ssh #sshUser#@#server# 'mkdir -p /opt/#serviceName#/.kamal'");
            
            // Write secrets file
            var result = $execBash("ssh #sshUser#@#server# 'cat > /opt/#serviceName#/.kamal/secrets << EOF
#secretsContent#
EOF && chmod 600 /opt/#serviceName#/.kamal/secrets'");
            
            if (result.exitCode == 0) {
                print.greenLine("✓ Secrets pushed to #server#");
            } else {
                print.redLine("✗ Failed to push secrets to #server#");
            }
        }
        
        // Log action
        deployAuditLog("secrets_pushed", {
            "servers": targetServers,
            "keys": structKeyArray(secrets)
        });
        
        print.line();
        print.greenLine("✓ Secrets push completed");
    }
    
    private void function pullSecrets(
        required struct config,
        required string manager,
        required string vault
    ) {
        print.boldLine("Pulling secrets from password manager...");
        print.line();
        
        // Create local .kamal directory
        var kamalDir = fileSystemUtil.resolvePath(".kamal");
        if (!directoryExists(kamalDir)) {
            directoryCreate(kamalDir);
        }
        
        // Load secrets from manager
        var secrets = loadSecretsFromManager(arguments.manager, arguments.vault, arguments.config);
        
        if (structIsEmpty(secrets)) {
            print.yellowLine("No secrets found in password manager");
            return;
        }
        
        // Write to local .env.deploy
        var envPath = fileSystemUtil.resolvePath(".env.deploy");
        var envContent = "";
        
        // Read existing .env.deploy if it exists
        if (fileExists(envPath)) {
            envContent = fileRead(envPath);
        }
        
        // Update or add secrets
        for (var key in secrets) {
            if (envContent contains key & "=") {
                // Replace existing value
                envContent = reReplace(envContent, key & "=.*", key & "=" & secrets[key], "all");
            } else {
                // Add new secret
                envContent &= chr(10) & key & "=" & secrets[key];
            }
        }
        
        // Write updated file
        fileWrite(envPath, trim(envContent));
        
        print.line();
        print.greenLine("✓ Pulled #structCount(secrets)# secrets to .env.deploy");
        
        // Log action
        deployAuditLog("secrets_pulled", {
            "keys": structKeyArray(secrets)
        });
    }
    
    private void function setSecret(
        required string key,
        required string value,
        required string manager,
        required string vault
    ) {
        // Get value if not provided
        var secretValue = arguments.value;
        if (!len(secretValue)) {
            secretValue = askSecret("Enter value for #arguments.key#: ");
        }
        
        // Store in password manager
        if (arguments.manager != "env") {
            if (storeInPasswordManager(arguments.key, secretValue, arguments.manager, arguments.vault)) {
                print.greenLine("✓ Secret stored in #arguments.manager#");
            } else {
                print.redLine("✗ Failed to store secret in password manager");
                return;
            }
        }
        
        // Also update local .env.deploy
        var envPath = fileSystemUtil.resolvePath(".env.deploy");
        var envContent = "";
        
        if (fileExists(envPath)) {
            envContent = fileRead(envPath);
        }
        
        if (envContent contains arguments.key & "=") {
            envContent = reReplace(envContent, arguments.key & "=.*", arguments.key & "=" & secretValue, "all");
        } else {
            envContent &= chr(10) & arguments.key & "=" & secretValue;
        }
        
        fileWrite(envPath, trim(envContent));
        
        print.greenLine("✓ Secret '#arguments.key#' has been set");
        
        // Log action (without value for security)
        deployAuditLog("secret_set", {
            "key": arguments.key,
            "manager": arguments.manager
        });
    }
    
    private void function listSecrets(required struct config) {
        print.boldLine("Configured Secrets:");
        print.line();
        
        // Get secrets from config
        var secretKeys = [];
        
        if (structKeyExists(arguments.config, "env") && structKeyExists(arguments.config.env, "secret")) {
            secretKeys = arguments.config.env.secret;
        }
        
        if (arrayIsEmpty(secretKeys)) {
            print.yellowLine("No secrets configured in deploy.json");
            return;
        }
        
        // Check which secrets are set
        var envPath = fileSystemUtil.resolvePath(".env.deploy");
        var envSecrets = {};
        
        if (fileExists(envPath)) {
            var envContent = fileRead(envPath);
            var lines = listToArray(envContent, chr(10));
            
            for (var line in lines) {
                if (Find("=", line) && Left(Trim(line), 1) != "##") {
                    var key = listFirst(line, "=");
                    envSecrets[key] = true;
                }
            }
        }
        
        // Display secrets
        for (var key in secretKeys) {
            if (structKeyExists(envSecrets, key)) {
                print.greenLine("✓ #key# (set)");
            } else {
                print.redLine("✗ #key# (not set)");
            }
        }
        
        print.line();
        print.line("Use 'wheels deploy:secrets set KEY' to set a secret");
    }
    
    private void function removeSecret(required string key) {
        // Remove from .env.deploy
        var envPath = fileSystemUtil.resolvePath(".env.deploy");
        
        if (fileExists(envPath)) {
            var envContent = fileRead(envPath);
            var lines = listToArray(envContent, chr(10));
            var newContent = [];
            
            for (var line in lines) {
                if (!(Left(line, Len(arguments.key & "=")) == arguments.key & "=")) {
                    newContent.append(line);
                }
            }
            
            fileWrite(envPath, arrayToList(newContent, chr(10)));
            print.greenLine("✓ Secret '#arguments.key#' removed from .env.deploy");
        }
        
        // Log action
        deployAuditLog("secret_removed", {
            "key": arguments.key
        });
    }
    
    private struct function loadSecretsFromManager(
        required string manager,
        required string vault,
        required struct config
    ) {
        var secrets = {};
        
        // Get list of required secrets from config
        var secretKeys = [];
        if (structKeyExists(arguments.config, "env") && structKeyExists(arguments.config.env, "secret")) {
            secretKeys = arguments.config.env.secret;
        }
        
        switch(arguments.manager) {
            case "1password":
                secrets = load1PasswordSecrets(secretKeys, arguments.vault);
                break;
                
            case "bitwarden":
                secrets = loadBitwardenSecrets(secretKeys, arguments.vault);
                break;
                
            case "lastpass":
                secrets = loadLastPassSecrets(secretKeys, arguments.vault);
                break;
                
            case "env":
            default:
                // Load from .env.deploy
                var envPath = fileSystemUtil.resolvePath(".env.deploy");
                if (fileExists(envPath)) {
                    var envContent = fileRead(envPath);
                    var lines = listToArray(envContent, chr(10));
                    
                    for (var line in lines) {
                        if (Find("=", line) && Left(Trim(line), 1) != "##") {
                            var key = trim(listFirst(line, "="));
                            var value = listRest(line, "=");
                            
                            if (arrayFindNoCase(secretKeys, key)) {
                                secrets[key] = value;
                            }
                        }
                    }
                }
                break;
        }
        
        return secrets;
    }
    
    private struct function load1PasswordSecrets(required array keys, required string vault) {
        var secrets = {};
        var vaultArg = len(arguments.vault) ? "--vault=#arguments.vault#" : "";
        
        for (var key in arguments.keys) {
            var result = $execBash("op item get #key# #vaultArg# --fields password 2>/dev/null");
            
            if (result.exitCode == 0 && len(trim(result.output))) {
                secrets[key] = trim(result.output);
            }
        }
        
        return secrets;
    }
    
    private struct function loadBitwardenSecrets(required array keys, required string vault) {
        var secrets = {};
        
        // Ensure logged in
        var statusResult = $execBash("bw status | jq -r .status");
        if (trim(statusResult.output) != "unlocked") {
            print.yellowLine("Please unlock Bitwarden first: bw unlock");
            return secrets;
        }
        
        for (var key in arguments.keys) {
            var result = $execBash("bw get password #key# 2>/dev/null");
            
            if (result.exitCode == 0 && len(trim(result.output))) {
                secrets[key] = trim(result.output);
            }
        }
        
        return secrets;
    }
    
    private struct function loadLastPassSecrets(required array keys, required string vault) {
        var secrets = {};
        
        for (var key in arguments.keys) {
            var result = $execBash("lpass show --password #key# 2>/dev/null");
            
            if (result.exitCode == 0 && len(trim(result.output))) {
                secrets[key] = trim(result.output);
            }
        }
        
        return secrets;
    }
    
    private boolean function storeInPasswordManager(
        required string key,
        required string value,
        required string manager,
        required string vault
    ) {
        switch(arguments.manager) {
            case "1password":
                var vaultArg = len(arguments.vault) ? "--vault=#arguments.vault#" : "";
                var result = $execBash("op item create --category=password --title=#arguments.key# password=#arguments.value# #vaultArg#");
                return result.exitCode == 0;
                
            case "bitwarden":
                var result = $execBash("bw create item '{""name"":""#arguments.key#"",""type"":2,""secureNote"":{""type"":0},""notes"":""#arguments.value#""}'");
                return result.exitCode == 0;
                
            case "lastpass":
                var result = $execBash("echo '#arguments.value#' | lpass add --non-interactive --password #arguments.key#");
                return result.exitCode == 0;
        }
        
        return false;
    }
    
    private string function askSecret(required string prompt) {
        // Use CommandBox's askSecret for masked input
        return trim(ask(arguments.prompt, "*"));
    }
}