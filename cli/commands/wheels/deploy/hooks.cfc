/**
 * Manage deployment hooks for custom lifecycle actions
 * 
 * {code:bash}
 * wheels deploy:hooks create pre-deploy
 * wheels deploy:hooks list
 * wheels deploy:hooks edit pre-deploy
 * wheels deploy:hooks run pre-deploy
 * {code}
 */
component extends="base" {

    /**
     * @action Hook action (create, list, edit, run, remove)
     * @hook Hook name (pre-connect, pre-build, pre-deploy, post-deploy, rollback)
     * @template Template to use for creation (bash, cfml)
     */
    function run(
        required string action,
        string hook="",
        string template="bash"
    ) {
        print.line();
        print.boldMagentaLine("Wheels Deploy Hooks Management");
        print.line("=".repeatString(50));
        
        switch(arguments.action) {
            case "create":
                if (!len(arguments.hook)) {
                    print.redLine("Hook name is required for create action");
                    return;
                }
                createHook(arguments.hook, arguments.template);
                break;
                
            case "list":
                listHooks();
                break;
                
            case "edit":
                if (!len(arguments.hook)) {
                    print.redLine("Hook name is required for edit action");
                    return;
                }
                editHook(arguments.hook);
                break;
                
            case "run":
                if (!len(arguments.hook)) {
                    print.redLine("Hook name is required for run action");
                    return;
                }
                runHook(arguments.hook);
                break;
                
            case "remove":
                if (!len(arguments.hook)) {
                    print.redLine("Hook name is required for remove action");
                    return;
                }
                removeHook(arguments.hook);
                break;
                
            default:
                print.redLine("Invalid action: #arguments.action#");
                print.line("Valid actions: create, list, edit, run, remove");
        }
    }
    
    private void function createHook(required string hookName, required string template) {
        // Validate hook name
        var validHooks = ["pre-connect", "pre-build", "pre-deploy", "post-deploy", "rollback"];
        if (!arrayFindNoCase(validHooks, arguments.hookName)) {
            print.redLine("Invalid hook name: #arguments.hookName#");
            print.line("Valid hooks: " & arrayToList(validHooks, ", "));
            return;
        }
        
        // Create hooks directory
        var hooksDir = fileSystemUtil.resolvePath(".kamal/hooks");
        if (!directoryExists(hooksDir)) {
            directoryCreate(hooksDir);
        }
        
        var hookFile = hooksDir & "/" & arguments.hookName;
        
        if (fileExists(hookFile)) {
            print.redLine("Hook '#arguments.hookName#' already exists!");
            print.line("Use 'wheels deploy:hooks edit #arguments.hookName#' to modify it");
            return;
        }
        
        // Create hook content based on template
        var content = "";
        
        if (arguments.template == "cfml") {
            content = "#!/usr/bin/env box

/**
 * Deployment hook: #arguments.hookName#
 * 
 * Available environment variables:
 * - KAMAL_VERSION - Current deployment version/tag
 * - KAMAL_SERVICE_NAME - Service name from deploy.json
 * - KAMAL_HOSTS - Comma-separated list of deployment hosts
 * - KAMAL_COMMAND - The command being run
 * - KAMAL_SUBCOMMAND - The subcommand being run
 * - KAMAL_ROLE - Current role (web, worker, etc.)
 * - KAMAL_DESTINATION - Deployment destination/environment
 */

// Your custom logic here
print.line(""Running #arguments.hookName# hook..."");

// Example: Validate deployment
if (arguments.hookName == ""pre-deploy"") {
    // Run tests
    command(""wheels test app"").run();
    
    // Check for uncommitted changes
    var gitStatus = command(""git status --porcelain"").run(returnOutput=true);
    if (len(trim(gitStatus))) {
        print.redLine(""Uncommitted changes detected!"");
        print.line(gitStatus);
        abort;
    }
}

// Example: Notify deployment
if (arguments.hookName == ""post-deploy"") {
    var version = systemSettings.getSystemSetting(""KAMAL_VERSION"", """");
    print.greenLine(""Successfully deployed version: "" & version);
    
    // Send notification (Slack, email, etc.)
    // http.post(""https://hooks.slack.com/..."", {text: ""Deployed "" & version});
}

print.greenLine(""✓ Hook completed successfully"");";
        } else {
            content = "#!/usr/bin/env bash

# Deployment hook: #arguments.hookName#
#
# Available environment variables:
# - KAMAL_VERSION - Current deployment version/tag
# - KAMAL_SERVICE_NAME - Service name from deploy.json
# - KAMAL_HOSTS - Comma-separated list of deployment hosts
# - KAMAL_COMMAND - The command being run
# - KAMAL_SUBCOMMAND - The subcommand being run
# - KAMAL_ROLE - Current role (web, worker, etc.)
# - KAMAL_DESTINATION - Deployment destination/environment

set -e

echo ""Running #arguments.hookName# hook...""

# Your custom logic here
case ""#arguments.hookName#"" in
    pre-connect)
        # Example: Test SSH connectivity
        echo ""Testing SSH connectivity...""
        for host in ${KAMAL_HOSTS//,/ }; do
            ssh -o ConnectTimeout=5 root@$host 'echo ""Connected to $(hostname)""' || exit 1
        done
        ;;
        
    pre-build)
        # Example: Run tests before building
        echo ""Running tests...""
        wheels test app || exit 1
        
        # Check for uncommitted changes
        if [ -n ""$(git status --porcelain)"" ]; then
            echo ""ERROR: Uncommitted changes detected!""
            git status --short
            exit 1
        fi
        ;;
        
    pre-deploy)
        # Example: Backup database
        echo ""Creating database backup...""
        # mysqldump -h db.example.com -u user -p database > backup-$(date +%Y%m%d-%H%M%S).sql
        ;;
        
    post-deploy)
        # Example: Clear caches, notify team
        echo ""Deployment completed for version: $KAMAL_VERSION""
        
        # Clear application caches
        # wheels reload
        
        # Send notification
        # curl -X POST https://hooks.slack.com/... -d '{""text"":""Deployed version '$KAMAL_VERSION'""}'
        ;;
        
    rollback)
        # Example: Restore from backup
        echo ""Rolling back deployment...""
        # Restore database, clear caches, etc.
        ;;
esac

echo ""✓ Hook completed successfully""";
        }
        
        // Write hook file
        fileWrite(hookFile, content);
        
        // Make executable
        if (arguments.template == "bash") {
            $execBash("chmod +x #hookFile#");
        }
        
        print.greenLine("✓ Created hook: #arguments.hookName#");
        print.line();
        print.line("Edit the hook file at: .kamal/hooks/#arguments.hookName#");
        print.line("Run with: wheels deploy:hooks run #arguments.hookName#");
        
        // Log action
        deployAuditLog("hook_created", {
            "hook": arguments.hookName,
            "template": arguments.template
        });
    }
    
    private void function listHooks() {
        var hooksDir = fileSystemUtil.resolvePath(".kamal/hooks");
        
        if (!directoryExists(hooksDir)) {
            print.yellowLine("No hooks directory found");
            print.line("Create your first hook with: wheels deploy:hooks create pre-deploy");
            return;
        }
        
        var hooks = directoryList(hooksDir, false, "name");
        
        if (arrayIsEmpty(hooks)) {
            print.yellowLine("No hooks found");
            print.line("Create your first hook with: wheels deploy:hooks create pre-deploy");
            return;
        }
        
        print.boldLine("Available Hooks:");
        print.line();
        
        var validHooks = ["pre-connect", "pre-build", "pre-deploy", "post-deploy", "rollback"];
        
        for (var hookName in validHooks) {
            if (arrayFindNoCase(hooks, hookName)) {
                var hookFile = hooksDir & "/" & hookName;
                var info = getFileInfo(hookFile);
                
                print.greenLine("✓ #hookName#");
                print.line("  Modified: #dateTimeFormat(info.lastModified, 'yyyy-mm-dd HH:nn:ss')#");
                print.line("  Size: #numberFormat(info.size)# bytes");
                
                // Check if executable
                if (fileGetAttribute(hookFile, "execute")) {
                    print.line("  Type: Executable script");
                } else {
                    print.line("  Type: CommandBox script");
                }
            } else {
                print.line("○ #hookName# (not created)");
            }
            print.line();
        }
    }
    
    private void function editHook(required string hookName) {
        var hookFile = fileSystemUtil.resolvePath(".kamal/hooks/#arguments.hookName#");
        
        if (!fileExists(hookFile)) {
            print.redLine("Hook '#arguments.hookName#' not found!");
            print.line("Create it with: wheels deploy:hooks create #arguments.hookName#");
            return;
        }
        
        // Open in default editor
        var editor = systemSettings.getSystemSetting("EDITOR", "");
        
        if (len(editor)) {
            runCommand(name=editor, arguments=hookFile);
        } else {
            // Try common editors
            var editors = ["code", "vim", "nano", "notepad"];
            var editorFound = false;
            
            for (var ed in editors) {
                try {
                    runCommand(name=ed, arguments=hookFile);
                    editorFound = true;
                    break;
                } catch (any e) {
                    // Try next editor
                }
            }
            
            if (!editorFound) {
                print.yellowLine("No editor found. Please edit manually:");
                print.line(hookFile);
            }
        }
    }
    
    private void function runHook(required string hookName, struct environment={}) {
        var hookFile = fileSystemUtil.resolvePath(".kamal/hooks/#arguments.hookName#");
        
        if (!fileExists(hookFile)) {
            // Silently skip if hook doesn't exist (normal behavior)
            return;
        }
        
        print.line();
        print.yellowLine("Running hook: #arguments.hookName#");
        print.line("-".repeatString(40));
        
        // Set up environment variables
        var deployConfig = loadDeployConfig();
        var env = duplicate(arguments.environment);
        
        // Add standard KAMAL environment variables
        env["KAMAL_VERSION"] = env.KAMAL_VERSION ?: "";
        env["KAMAL_SERVICE_NAME"] = deployConfig.service ?: "";
        env["KAMAL_HOSTS"] = structKeyExists(deployConfig, "servers") && structKeyExists(deployConfig.servers, "web") 
            ? arrayToList(deployConfig.servers.web) : "";
        env["KAMAL_COMMAND"] = "deploy";
        env["KAMAL_SUBCOMMAND"] = arguments.hookName;
        env["KAMAL_ROLE"] = "web";
        env["KAMAL_DESTINATION"] = env.KAMAL_DESTINATION ?: "production";
        
        try {
            // Check if it's executable (bash script)
            if (fileGetAttribute(hookFile, "execute")) {
                // Run as bash script
                var result = runCommand(
                    name=hookFile,
                    environment=env
                );
            } else {
                // Run as CommandBox script
                var result = runCommand(
                    name="box",
                    arguments=hookFile,
                    environment=env
                );
            }
            
            print.greenLine("✓ Hook completed successfully");
            
            // Log hook execution
            deployAuditLog("hook_executed", {
                "hook": arguments.hookName,
                "success": true
            });
        } catch (any e) {
            print.redLine("✗ Hook failed: #e.message#");
            
            // Log hook failure
            deployAuditLog("hook_failed", {
                "hook": arguments.hookName,
                "error": e.message
            });
            
            // Re-throw to stop deployment
            throw(message="Hook '#arguments.hookName#' failed: #e.message#", type="HookExecutionError");
        }
        
        print.line("-".repeatString(40));
    }
    
    private void function removeHook(required string hookName) {
        var hookFile = fileSystemUtil.resolvePath(".kamal/hooks/#arguments.hookName#");
        
        if (!fileExists(hookFile)) {
            print.redLine("Hook '#arguments.hookName#' not found!");
            return;
        }
        
        var confirm = ask("Are you sure you want to remove the '#arguments.hookName#' hook? (yes/no): ");
        
        if (lCase(trim(confirm)) == "yes") {
            fileDelete(hookFile);
            print.greenLine("✓ Hook '#arguments.hookName#' removed");
            
            // Log action
            deployAuditLog("hook_removed", {
                "hook": arguments.hookName
            });
        } else {
            print.line("Removal cancelled");
        }
    }
    
    // Public function to run hooks from other commands
    public void function executeHook(required string hookName, struct environment={}) {
        runHook(arguments.hookName, arguments.environment);
    }
}