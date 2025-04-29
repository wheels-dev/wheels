/**
 * Manage Wheels-specific dependencies and plugins
 * 
 * {code:bash}
 * wheels deps list
 * wheels deps install PluginName
 * wheels deps update PluginName
 * wheels deps remove PluginName
 * wheels deps report
 * {code}
 */
component extends="base" {

    /**
     * @action Action to perform (list, install, update, remove, report)
     * @name Name of the plugin or dependency (required for install, update, remove)
     * @version Version to install (optional, for install action)
     */
    function run(
        required string action,
        string name="",
        string version=""
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Dependency Manager");
        print.line();
        
        // Validate action
        local.validActions = ["list", "install", "update", "remove", "report"];
        if (!arrayContains(local.validActions, lCase(arguments.action))) {
            error("Invalid action: #arguments.action#. Please choose from: #arrayToList(local.validActions)#");
        }
        
        // Handle different actions
        switch (lCase(arguments.action)) {
            case "list":
                listDependencies();
                break;
            case "install":
                if (len(trim(arguments.name)) == 0) {
                    error("Name parameter is required for install action");
                }
                installDependency(arguments.name, arguments.version);
                break;
            case "update":
                if (len(trim(arguments.name)) == 0) {
                    error("Name parameter is required for update action");
                }
                updateDependency(arguments.name);
                break;
            case "remove":
                if (len(trim(arguments.name)) == 0) {
                    error("Name parameter is required for remove action");
                }
                removeDependency(arguments.name);
                break;
            case "report":
                generateDependencyReport();
                break;
        }
        
        print.line();
    }
    
    /**
     * List installed dependencies and plugins
     */
    private void function listDependencies() {
        print.line("Retrieving installed dependencies and plugins...");
        
        // Send command to get dependencies
        local.result = $sendToCliCommand(urlstring="&command=pluginsList");
        
        // Display results
        if (structKeyExists(local.result, "plugins") && isArray(local.result.plugins)) {
            if (arrayLen(local.result.plugins) == 0) {
                print.yellowLine("No plugins installed");
            } else {
                print.boldYellowLine("Installed Plugins:");
                print.line();
                
                local.pluginsTable = [];
                
                for (local.plugin in local.result.plugins) {
                    local.version = structKeyExists(local.plugin, "version") ? local.plugin.version : "Unknown";
                    local.author = structKeyExists(local.plugin, "author") ? local.plugin.author : "Unknown";
                    local.status = structKeyExists(local.plugin, "enabled") && local.plugin.enabled ? "Enabled" : "Disabled";
                    
                    arrayAppend(local.pluginsTable, [local.plugin.name, local.version, local.author, local.status]);
                }
                
                print.table(local.pluginsTable, ["Plugin", "Version", "Author", "Status"]);
            }
        } else {
            print.boldRedLine("Failed to retrieve plugins");
        }
    }
    
    /**
     * Install a dependency or plugin
     */
    private void function installDependency(
        required string name,
        string version=""
    ) {
        print.line("Installing #arguments.name#...");
        
        // Create URL parameters
        local.urlParams = "&command=pluginInstall&name=#urlEncodedFormat(arguments.name)#";
        
        if (len(trim(arguments.version))) {
            local.urlParams &= "&version=#urlEncodedFormat(arguments.version)#";
        }
        
        // Send command to install dependency
        local.result = $sendToCliCommand(urlstring=local.urlParams);
        
        // Display results
        if (structKeyExists(local.result, "success") && local.result.success) {
            print.boldGreenLine("#arguments.name# installed successfully");
            
            if (structKeyExists(local.result, "version")) {
                print.yellowLine("Version: #local.result.version#");
            }
            
            if (structKeyExists(local.result, "message")) {
                print.line(local.result.message);
            }
        } else {
            print.boldRedLine("Failed to install #arguments.name#");
            if (structKeyExists(local.result, "message")) {
                print.redLine(local.result.message);
            }
        }
    }
    
    /**
     * Update a dependency or plugin
     */
    private void function updateDependency(required string name) {
        print.line("Updating #arguments.name#...");
        
        // Create URL parameters
        local.urlParams = "&command=pluginUpdate&name=#urlEncodedFormat(arguments.name)#";
        
        // Send command to update dependency
        local.result = $sendToCliCommand(urlstring=local.urlParams);
        
        // Display results
        if (structKeyExists(local.result, "success") && local.result.success) {
            print.boldGreenLine("#arguments.name# updated successfully");
            
            if (structKeyExists(local.result, "oldVersion") && structKeyExists(local.result, "newVersion")) {
                print.yellowLine("Updated from version #local.result.oldVersion# to #local.result.newVersion#");
            }
            
            if (structKeyExists(local.result, "message")) {
                print.line(local.result.message);
            }
        } else {
            print.boldRedLine("Failed to update #arguments.name#");
            if (structKeyExists(local.result, "message")) {
                print.redLine(local.result.message);
            }
        }
    }
    
    /**
     * Remove a dependency or plugin
     */
    private void function removeDependency(required string name) {
        if (!confirm("Are you sure you want to remove #arguments.name#? [y/n]")) {
            print.line("Aborted");
            return;
        }
        
        print.line("Removing #arguments.name#...");
        
        // Create URL parameters
        local.urlParams = "&command=pluginRemove&name=#urlEncodedFormat(arguments.name)#";
        
        // Send command to remove dependency
        local.result = $sendToCliCommand(urlstring=local.urlParams);
        
        // Display results
        if (structKeyExists(local.result, "success") && local.result.success) {
            print.boldGreenLine("#arguments.name# removed successfully");
            
            if (structKeyExists(local.result, "message")) {
                print.line(local.result.message);
            }
        } else {
            print.boldRedLine("Failed to remove #arguments.name#");
            if (structKeyExists(local.result, "message")) {
                print.redLine(local.result.message);
            }
        }
    }
    
    /**
     * Generate dependency report
     */
    private void function generateDependencyReport() {
        print.line("Generating dependency report...");
        
        // Send command to get dependency report
        local.result = $sendToCliCommand(urlstring="&command=dependencyReport");
        
        // Display results
        if (structKeyExists(local.result, "report")) {
            print.boldYellowLine("Dependency Report:");
            print.line();
            
            if (structKeyExists(local.result.report, "plugins") && isArray(local.result.report.plugins)) {
                print.yellowLine("Plugins:");
                
                local.pluginsTable = [];
                
                for (local.plugin in local.result.report.plugins) {
                    local.version = structKeyExists(local.plugin, "version") ? local.plugin.version : "Unknown";
                    local.author = structKeyExists(local.plugin, "author") ? local.plugin.author : "Unknown";
                    local.dependencies = structKeyExists(local.plugin, "dependencies") ? arrayToList(local.plugin.dependencies) : "None";
                    
                    arrayAppend(local.pluginsTable, [local.plugin.name, local.version, local.dependencies]);
                }
                
                print.table(local.pluginsTable, ["Plugin", "Version", "Dependencies"]);
                print.line();
            }
            
            if (structKeyExists(local.result.report, "compatibility")) {
                print.yellowLine("Compatibility:");
                
                local.compatibilityTable = [];
                
                for (local.item in local.result.report.compatibility) {
                    local.status = structKeyExists(local.item, "compatible") && local.item.compatible ? "Compatible" : "Incompatible";
                    local.notes = structKeyExists(local.item, "notes") ? local.item.notes : "";
                    
                    arrayAppend(local.compatibilityTable, [local.item.name, local.item.version, local.status, local.notes]);
                }
                
                print.table(local.compatibilityTable, ["Component", "Version", "Status", "Notes"]);
            }
            
            // Export report to file if it exists
            if (structKeyExists(local.result, "reportPath")) {
                print.line();
                print.greenLine("Full report exported to: #local.result.reportPath#");
            }
        } else {
            print.boldRedLine("Failed to generate dependency report");
            if (structKeyExists(local.result, "message")) {
                print.redLine(local.result.message);
            }
        }
    }
}