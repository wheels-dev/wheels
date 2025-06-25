/**
 * Base component for deployment commands
 */
component extends="../base" {
    
    // Check if deployment is locked
    boolean function isDeploymentLocked() {
        var deployConfigPath = fileSystemUtil.resolvePath("deploy.json");
        if (!fileExists(deployConfigPath)) {
            return false;
        }
        
        try {
            var deployConfig = deserializeJSON(fileRead(deployConfigPath));
            var primaryServer = "";
            
            if (structKeyExists(deployConfig, "servers") && structKeyExists(deployConfig.servers, "web") && !arrayIsEmpty(deployConfig.servers.web)) {
                primaryServer = deployConfig.servers.web[1];
            }
            
            if (!len(primaryServer)) {
                return false;
            }
            
            var sshUser = deployConfig.ssh.user ?: "root";
            var lockDir = "/opt/.kamal/lock";
            
            var checkResult = $execBash("ssh -o ConnectTimeout=5 " & sshUser & "@" & primaryServer & " 'test -d " & lockDir & " && echo EXISTS || echo FREE'");
            
            return trim(checkResult.output) == "EXISTS";
        } catch (any e) {
            return false;
        }
    }
    
    // Require deployment lock for critical operations
    void function requireDeploymentLock(string customMessage="") {
        if (isDeploymentLocked()) {
            print.line();
            print.redLine("✗ Deployment is currently locked!");
            
            if (len(arguments.customMessage)) {
                print.line(arguments.customMessage);
            } else {
                print.line("Another deployment or maintenance operation is in progress.");
            }
            
            print.line();
            print.line("Run 'wheels deploy:lock status' to see lock details");
            print.line("Run 'wheels deploy:lock release' to force release (use with caution)");
            abort;
        }
    }
    
    // Acquire deployment lock automatically
    boolean function acquireDeploymentLock(string message="") {
        var deployConfig = loadDeployConfig();
        if (isNull(deployConfig)) {
            return false;
        }
        
        var primaryServer = getPrimaryServer(deployConfig);
        if (!len(primaryServer)) {
            return false;
        }
        
        var sshUser = deployConfig.ssh.user ?: "root";
        var lockDir = "/opt/.kamal/lock";
        
        // Create lock info
        var lockInfo = {
            "user": getSystemUser(),
            "host": getHostName(),
            "timestamp": dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            "pid": createUUID(),
            "message": arguments.message
        };
        
        var lockJson = serializeJSON(lockInfo);
        
        // Try to create lock directory atomically
        var createResult = $execBash("ssh " & sshUser & "@" & primaryServer & " 'mkdir -p /opt/.kamal && mkdir " & lockDir & " && echo ''" & replace(lockJson, "'", "'\''", "all") & "'' > " & lockDir & "/info.json'");
        
        if (createResult.exitCode == 0) {
            deployAuditLog("lock_acquired", lockInfo);
            return true;
        }
        
        return false;
    }
    
    // Release deployment lock
    void function releaseDeploymentLock() {
        var deployConfig = loadDeployConfig();
        if (isNull(deployConfig)) {
            return;
        }
        
        var primaryServer = getPrimaryServer(deployConfig);
        if (!len(primaryServer)) {
            return;
        }
        
        var sshUser = deployConfig.ssh.user ?: "root";
        var lockDir = "/opt/.kamal/lock";
        
        // Remove lock
        $execBash("ssh " & sshUser & "@" & primaryServer & " 'rm -rf " & lockDir & "'");
        
        deployAuditLog("lock_released", {});
    }
    
    // Log deployment actions to audit trail
    void function deployAuditLog(required string action, struct data={}) {
        var auditDir = fileSystemUtil.resolvePath(".kamal");
        var auditFile = auditDir & "/deploy-audit.log";
        
        // Create directory if it doesn't exist
        if (!directoryExists(auditDir)) {
            directoryCreate(auditDir);
        }
        
        // Build audit entry
        var entry = {
            "timestamp": dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            "action": arguments.action,
            "user": getSystemUser(),
            "host": getHostName(),
            "data": arguments.data
        };
        
        // Append to log file
        var logLine = serializeJSON(entry) & chr(10);
        
        if (fileExists(auditFile)) {
            fileAppend(auditFile, logLine);
        } else {
            fileWrite(auditFile, logLine);
        }
    }
    
    // Load deployment configuration
    any function loadDeployConfig(string environment="") {
        var configFiles = [];
        
        // Check for environment from system setting if not provided
        if (!len(arguments.environment)) {
            arguments.environment = systemSettings.getSystemSetting("WHEELS_DEPLOY_DESTINATION", "");
        }
        
        // Build list of config files to check
        if (len(arguments.environment)) {
            // Environment-specific config
            configFiles.append("deploy." & arguments.environment & ".json");
        }
        
        // Base config
        configFiles.append("deploy.json");
        
        // Try to load and merge configs
        var deployConfig = {};
        var loadedFiles = [];
        
        for (var configFile in configFiles) {
            var configPath = fileSystemUtil.resolvePath(configFile);
            
            if (fileExists(configPath)) {
                try {
                    var config = deserializeJSON(fileRead(configPath));
                    
                    // Merge with existing config
                    deployConfig = mergeConfigs(deployConfig, config);
                    loadedFiles.append(configFile);
                } catch (any e) {
                    print.redLine("Error reading #configFile#: #e.message#");
                    return;
                }
            }
        }
        
        if (structIsEmpty(deployConfig)) {
            print.redLine("No deployment configuration found! Run 'wheels deploy:init' first.");
            return;
        }
        
        // Store the environment in the config for reference
        if (len(arguments.environment)) {
            deployConfig["_environment"] = arguments.environment;
        }
        
        // Log which configs were loaded
        if (arrayLen(loadedFiles) > 1) {
            print.line("Loaded configuration from: " & arrayToList(loadedFiles, ", "));
        }
        
        return deployConfig;
    }
    
    // Merge two configuration structs
    private struct function mergeConfigs(required struct base, required struct override) {
        var result = duplicate(arguments.base);
        
        for (var key in arguments.override) {
            if (structKeyExists(result, key) && isStruct(result[key]) && isStruct(arguments.override[key])) {
                // Recursively merge nested structs
                result[key] = mergeConfigs(result[key], arguments.override[key]);
            } else {
                // Override value
                result[key] = arguments.override[key];
            }
        }
        
        return result;
    }
    
    // Get primary server for coordination
    string function getPrimaryServer(required struct config) {
        if (structKeyExists(arguments.config, "servers") && structKeyExists(arguments.config.servers, "web") && !arrayIsEmpty(arguments.config.servers.web)) {
            return arguments.config.servers.web[1];
        }
        return "";
    }
    
    // Get current system user
    string function getSystemUser() {
        var result = $execBash("whoami");
        return trim(result.output);
    }
    
    // Get current hostname
    string function getHostName() {
        var result = $execBash("hostname");
        return trim(result.output);
    }
    
    // Execute bash command helper
    struct function $execBash(required string command) {
        try {
            var result = runCommand(
                name="bash",
                arguments="-c ""#arguments.command#""",
                timeout=arguments.timeout ?: 30
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