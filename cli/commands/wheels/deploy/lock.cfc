/**
 * Manage deployment locks to prevent concurrent deployments
 * 
 * {code:bash}
 * wheels deploy:lock acquire
 * wheels deploy:lock release
 * wheels deploy:lock status
 * {code}
 */
component extends="./base" {

    /**
     * @action Lock action (acquire, release, status)
     * @force Force acquire lock even if held by another process
     * @message Lock message/reason
     */
    function run(
        required string action,
        boolean force=false,
        string message=""
    ) {
        var deployConfig = loadDeployConfig();
        if (isNull(deployConfig)) {
            return;
        }
        
        // Get primary server for lock coordination
        var primaryServer = getPrimaryServer(deployConfig);
        if (!len(primaryServer)) {
            print.redLine("No servers configured for deployment!");
            return;
        }
        
        var sshUser = deployConfig.ssh.user ?: "root";
        var lockDir = "/opt/.kamal/lock";
        
        switch(arguments.action) {
            case "acquire":
                acquireLock(primaryServer, sshUser, lockDir, arguments.force, arguments.message);
                break;
                
            case "release":
                releaseLock(primaryServer, sshUser, lockDir);
                break;
                
            case "status":
                showLockStatus(primaryServer, sshUser, lockDir);
                break;
                
            default:
                print.redLine("Invalid action: #arguments.action#");
                print.line("Valid actions: acquire, release, status");
        }
    }
    
    private void function acquireLock(
        required string server,
        required string user,
        required string lockDir,
        required boolean force,
        required string message
    ) {
        print.line();
        print.boldMagentaLine("Acquiring Deployment Lock");
        print.line("=".repeatString(50));
        
        // Check if lock exists
        var checkResult = $execBash("ssh #arguments.user#@#arguments.server# 'test -d #arguments.lockDir# && echo EXISTS || echo FREE'");
        
        if (trim(checkResult.output) == "EXISTS" && !arguments.force) {
            // Lock exists, get info
            var lockInfo = getLockInfo(arguments.server, arguments.user, arguments.lockDir);
            
            print.redLine("✗ Deployment lock is already held!");
            print.line();
            
            if (!isNull(lockInfo)) {
                print.line("Lock held by: #lockInfo.user#@#lockInfo.host#");
                print.line("Acquired at: #lockInfo.timestamp#");
                if (len(lockInfo.message)) {
                    print.line("Message: #lockInfo.message#");
                }
            }
            
            print.line();
            print.line("Use --force to override the lock (use with caution!)");
            return;
        }
        
        // Create lock info
        var lockInfo = {
            "user": getSystemUser(),
            "host": getHostName(),
            "timestamp": dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            "pid": createUUID(),
            "message": arguments.message
        };
        
        var lockJson = serializeJSON(lockInfo);
        
        // Create lock directory atomically
        if (arguments.force) {
            $execBash("ssh #arguments.user#@#arguments.server# 'rm -rf #arguments.lockDir#'");
        }
        
        var createResult = $execBash("ssh #arguments.user#@#arguments.server# 'mkdir -p /opt/.kamal && mkdir #arguments.lockDir# && echo ''#replace(lockJson, "'", "'\''", "all")#'' > #arguments.lockDir#/info.json'");
        
        if (createResult.exitCode == 0) {
            print.greenLine("✓ Deployment lock acquired successfully");
            
            // Also log to audit
            auditLog("lock_acquired", lockInfo);
        } else {
            print.redLine("✗ Failed to acquire deployment lock");
            print.redLine("Another deployment may be in progress");
        }
    }
    
    private void function releaseLock(
        required string server,
        required string user,
        required string lockDir
    ) {
        print.line();
        print.boldMagentaLine("Releasing Deployment Lock");
        print.line("=".repeatString(50));
        
        // Check if lock exists
        var checkResult = $execBash("ssh #arguments.user#@#arguments.server# 'test -d #arguments.lockDir# && echo EXISTS || echo FREE'");
        
        if (trim(checkResult.output) != "EXISTS") {
            print.yellowLine("No deployment lock found");
            return;
        }
        
        // Get lock info before releasing
        var lockInfo = getLockInfo(arguments.server, arguments.user, arguments.lockDir);
        
        // Remove lock
        var removeResult = $execBash("ssh #arguments.user#@#arguments.server# 'rm -rf #arguments.lockDir#'");
        
        if (removeResult.exitCode == 0) {
            print.greenLine("✓ Deployment lock released successfully");
            
            // Log to audit
            auditLog("lock_released", lockInfo ?: {});
        } else {
            print.redLine("✗ Failed to release deployment lock");
        }
    }
    
    private void function showLockStatus(
        required string server,
        required string user,
        required string lockDir
    ) {
        print.line();
        print.boldMagentaLine("Deployment Lock Status");
        print.line("=".repeatString(50));
        
        // Check if lock exists
        var checkResult = $execBash("ssh #arguments.user#@#arguments.server# 'test -d #arguments.lockDir# && echo EXISTS || echo FREE'");
        
        if (trim(checkResult.output) != "EXISTS") {
            print.greenLine("✓ No deployment lock - deployments can proceed");
            return;
        }
        
        // Get lock info
        var lockInfo = getLockInfo(arguments.server, arguments.user, arguments.lockDir);
        
        if (!isNull(lockInfo)) {
            print.redLine("✗ Deployment lock is active");
            print.line();
            print.line("Lock held by: #lockInfo.user#@#lockInfo.host#");
            print.line("Acquired at: #lockInfo.timestamp#");
            
            if (structKeyExists(lockInfo, "pid")) {
                print.line("Process ID: #lockInfo.pid#");
            }
            
            if (len(lockInfo.message)) {
                print.line("Message: #lockInfo.message#");
            }
            
            // Calculate lock age
            try {
                var lockTime = parseDateTime(lockInfo.timestamp);
                var age = dateDiff("n", lockTime, now());
                
                if (age > 60) {
                    print.line();
                    print.yellowLine("⚠ Lock has been held for #int(age/60)# hours #age mod 60# minutes");
                    print.yellowLine("Consider using 'wheels deploy:lock release' if deployment is stuck");
                }
            } catch (any e) {
                // Ignore date parsing errors
            }
        } else {
            print.redLine("✗ Deployment lock exists but info unavailable");
        }
    }
    
    private any function getLockInfo(
        required string server,
        required string user,
        required string lockDir
    ) {
        var infoResult = $execBash("ssh #arguments.user#@#arguments.server# 'cat #arguments.lockDir#/info.json 2>/dev/null'");
        
        if (infoResult.exitCode == 0 && len(trim(infoResult.output))) {
            try {
                return deserializeJSON(infoResult.output);
            } catch (any e) {
                return;
            }
        }
        
        return;
    }
    
    private string function getPrimaryServer(required struct config) {
        if (structKeyExists(arguments.config, "servers") && structKeyExists(arguments.config.servers, "web") && !arrayIsEmpty(arguments.config.servers.web)) {
            return arguments.config.servers.web[1];
        }
        return "";
    }
    
    private string function getSystemUser() {
        var result = $execBash("whoami");
        return trim(result.output);
    }
    
    private string function getHostName() {
        var result = $execBash("hostname");
        return trim(result.output);
    }
    
    private void function auditLog(required string action, struct data={}) {
        // This will be implemented in the base class
        if (structKeyExists(variables, "deployAuditLog")) {
            variables.deployAuditLog(arguments.action, arguments.data);
        }
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
                timeout=30
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