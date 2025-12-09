/**
 * Manage environment-specific settings
 * 
 * {code:bash}
 * wheels config:env list
 * wheels config:env create production
 * wheels config:env copy development production
 * {code}
 */
component extends="../base" {

    /**
     * @action Action to perform (list, create, copy)
     * @source Source environment for copy action
     * @target Target environment for create or copy action
     */
    function run(
        required string action,
        string source="",
        string target=""
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(arguments);
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Environment Manager");
        print.line();
        
        // Handle different actions
        switch (lCase(arguments.action)) {
            case "list":
                listEnvironments();
                break;
            case "create":
                if (len(trim(arguments.target)) == 0) {
                    error("Target environment is required for create action");
                }
                createEnvironment(arguments.target);
                break;
            case "copy":
                if (len(trim(arguments.source)) == 0 || len(trim(arguments.target)) == 0) {
                    error("Source and target environments are required for copy action");
                }
                copyEnvironment(arguments.source, arguments.target);
                break;
            default:
                error("Invalid action. Choose from: list, create, copy");
                break;
        }
        
        print.line();
    }
    
    /**
     * List available environments
     */
    private void function listEnvironments() {
        print.line("Retrieving available environments...");
        
        // Send command to get environments
        local.result = $sendToCliCommand(urlstring="&command=environmentList");
        if(!local.result.success){
			return;
		}
        
        // Display results
        if (structKeyExists(local.result, "environments") && isArray(local.result.environments)) {
            print.boldYellowLine("Available Environments:");
            print.line();
            
            for (local.env in local.result.environments) {
                if (local.env == local.result.currentEnvironment) {
                    print.greenLine(" * #local.env# (current)");
                } else {
                    print.line("   #local.env#");
                }
            }
        } else {
            print.boldRedLine("No environments found");
        }
    }
    
    /**
     * Create a new environment
     */
    private void function createEnvironment(required string environment) {
        print.line("Creating environment '#arguments.environment#'...");
        
        // Send command to create environment
        local.result = $sendToCliCommand(urlstring="&command=environmentCreate&environment=#urlEncodedFormat(arguments.environment)#");
        if(!local.result.success){
			return;
		}
        // Display results
        if (structKeyExists(local.result, "success") && local.result.success) {
            print.boldGreenLine("Environment '#arguments.environment#' created successfully");
            
            if (structKeyExists(local.result, "configPath")) {
                print.yellowLine("Configuration file created at: #local.result.configPath#");
            }
            
            print.line();
            print.line("To switch to this environment:");
            print.yellowLine("1. Update your server.json to set environment=#arguments.environment#");
            print.yellowLine("2. Restart your server");
        } else {
            print.boldRedLine("Failed to create environment");
            if (structKeyExists(local.result, "message")) {
                print.redLine(local.result.message);
            }
        }
    }
    
    /**
     * Copy environment settings from one to another
     */
    private void function copyEnvironment(required string source, required string target) {
        print.line("Copying environment settings from '#arguments.source#' to '#arguments.target#'...");
        
        // Send command to copy environment
        local.result = $sendToCliCommand(urlstring="&command=environmentCopy&sourceEnvironment=#urlEncodedFormat(arguments.source)#&targetEnvironment=#urlEncodedFormat(arguments.target)#");
        if(!local.result.success){
			return;
		}
        // Display results
        if (structKeyExists(local.result, "success") && local.result.success) {
            print.boldGreenLine("Environment settings copied successfully");
            
            if (structKeyExists(local.result, "configPath")) {
                print.yellowLine("Configuration file created/updated at: #local.result.configPath#");
            }
            
            print.line();
            print.line("To switch to the new environment:");
            print.yellowLine("1. Update your server.json to set environment=#arguments.target#");
            print.yellowLine("2. Restart your server");
        } else {
            print.boldRedLine("Failed to copy environment settings");
            if (structKeyExists(local.result, "message")) {
                print.redLine(local.result.message);
            }
        }
    }
}