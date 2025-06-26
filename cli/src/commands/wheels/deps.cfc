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
     * @dev Install as dev dependency (optional, for install action)
     */
    function run(
        required string action,
        string name="",
        string version="",
        boolean dev=false
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
                installDependency(arguments.name, arguments.version, arguments.dev);
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
     * List installed dependencies from box.json
     */
    private void function listDependencies() {
        print.line("Retrieving dependencies from box.json...");
        
        try {
            local.boxJsonPath = fileSystemUtil.resolvePath("box.json");
            
            if (!fileExists(local.boxJsonPath)) {
                print.boldRedLine("No box.json file found");
                print.line("Run 'box init' to create a box.json file");
                return;
            }
            
            local.boxJson = deserializeJSON(fileRead(local.boxJsonPath));
            local.hasDeps = false;
            
            // List regular dependencies
            if (structKeyExists(local.boxJson, "dependencies") && structCount(local.boxJson.dependencies) > 0) {
                print.boldYellowLine("Dependencies:");
                local.depsTable = [];
                
                for (local.dep in local.boxJson.dependencies) {
                    local.version = local.boxJson.dependencies[local.dep];
                    local.installed = checkIfInstalled(local.dep);
                    local.status = local.installed ? "Installed" : "Not Installed";
                    
                    arrayAppend(local.depsTable, [local.dep, local.version, "Production", local.status]);
                }
                
                // print.table(local.depsTable, ["Package", "Version", "Type", "Status"]);
                for (local.row in local.depsTable) {
                    print.line("  " & local.row[1] & " @ " & local.row[2] & " (" & local.row[3] & ") - " & local.row[4]);
                }
                local.hasDeps = true;
            }
            
            // List dev dependencies
            if (structKeyExists(local.boxJson, "devDependencies") && structCount(local.boxJson.devDependencies) > 0) {
                if (local.hasDeps) print.line();
                
                print.boldYellowLine("Dev Dependencies:");
                local.devDepsTable = [];
                
                for (local.dep in local.boxJson.devDependencies) {
                    local.version = local.boxJson.devDependencies[local.dep];
                    local.installed = checkIfInstalled(local.dep);
                    local.status = local.installed ? "Installed" : "Not Installed";
                    
                    arrayAppend(local.devDepsTable, [local.dep, local.version, "Development", local.status]);
                }
                
                // print.table(local.devDepsTable, ["Package", "Version", "Type", "Status"]);
                for (local.row in local.devDepsTable) {
                    print.line("  " & local.row[1] & " @ " & local.row[2] & " (" & local.row[3] & ") - " & local.row[4]);
                }
                local.hasDeps = true;
            }
            
            if (!local.hasDeps) {
                print.yellowLine("No dependencies found in box.json");
                print.line("Use 'wheels deps install <package>' to add dependencies");
            }
            
        } catch (any e) {
            print.boldRedLine("Error reading dependencies: #e.message#");
        }
    }
    
    /**
     * Install a dependency
     */
    private void function installDependency(
        required string name,
        string version="",
        boolean dev=false
    ) {
        print.line("Installing #arguments.name#...");
        
        try {
            // Prepare install command
            local.installCmd = "install #arguments.name#";
            
            if (len(trim(arguments.version))) {
                local.installCmd &= "@#arguments.version#";
            }
            
            if (arguments.dev) {
                local.installCmd &= " --dev";
            }
            
            // Run CommandBox install
            print.line("Running: box #local.installCmd#");
            command(local.installCmd).run();
            
            print.boldGreenLine("#arguments.name# installed successfully");
            
            // Show post-install information
            local.boxJsonPath = fileSystemUtil.resolvePath("box.json");
            if (fileExists(local.boxJsonPath)) {
                local.boxJson = deserializeJSON(fileRead(local.boxJsonPath));
                local.depType = arguments.dev ? "devDependencies" : "dependencies";
                
                if (structKeyExists(local.boxJson, local.depType) && 
                    structKeyExists(local.boxJson[local.depType], arguments.name)) {
                    print.yellowLine("Added to #local.depType#: #arguments.name# @ #local.boxJson[local.depType][arguments.name]#");
                }
            }
            
        } catch (any e) {
            print.boldRedLine("Failed to install #arguments.name#");
            print.redLine("Error: #e.message#");
        }
    }
    
    /**
     * Update a dependency
     */
    private void function updateDependency(required string name) {
        print.line("Updating #arguments.name#...");
        
        try {
            // Check if dependency exists in box.json
            local.boxJsonPath = fileSystemUtil.resolvePath("box.json");
            if (!fileExists(local.boxJsonPath)) {
                print.boldRedLine("No box.json file found");
                return;
            }
            
            local.boxJson = deserializeJSON(fileRead(local.boxJsonPath));
            local.isDev = false;
            local.found = false;
            
            // Check regular dependencies
            if (structKeyExists(local.boxJson, "dependencies") && 
                structKeyExists(local.boxJson.dependencies, arguments.name)) {
                local.found = true;
                local.currentVersion = local.boxJson.dependencies[arguments.name];
            }
            
            // Check dev dependencies
            if (!local.found && structKeyExists(local.boxJson, "devDependencies") && 
                structKeyExists(local.boxJson.devDependencies, arguments.name)) {
                local.found = true;
                local.isDev = true;
                local.currentVersion = local.boxJson.devDependencies[arguments.name];
            }
            
            if (!local.found) {
                print.boldRedLine("Dependency '#arguments.name#' not found in box.json");
                print.line("Use 'wheels deps list' to see available dependencies");
                return;
            }
            
            // Update the dependency
            print.yellowLine("Current version: #local.currentVersion#");
            
            local.updateCmd = "update #arguments.name#";
            if (local.isDev) {
                local.updateCmd &= " --dev";
            }
            
            print.line("Running: box #local.updateCmd#");
            command(local.updateCmd).run();
            
            print.boldGreenLine("#arguments.name# updated successfully");
            
            // Show new version
            local.boxJson = deserializeJSON(fileRead(local.boxJsonPath));
            local.depType = local.isDev ? "devDependencies" : "dependencies";
            
            if (structKeyExists(local.boxJson, local.depType) && 
                structKeyExists(local.boxJson[local.depType], arguments.name)) {
                local.newVersion = local.boxJson[local.depType][arguments.name];
                if (local.currentVersion != local.newVersion) {
                    print.yellowLine("Updated from #local.currentVersion# to #local.newVersion#");
                }
            }
            
        } catch (any e) {
            print.boldRedLine("Failed to update #arguments.name#");
            print.redLine("Error: #e.message#");
        }
    }
    
    /**
     * Remove a dependency
     */
    private void function removeDependency(required string name) {
        if (!confirm("Are you sure you want to remove #arguments.name#? [y/n]")) {
            print.line("Aborted");
            return;
        }
        
        print.line("Removing #arguments.name#...");
        
        try {
            // Check if dependency exists in box.json
            local.boxJsonPath = fileSystemUtil.resolvePath("box.json");
            if (!fileExists(local.boxJsonPath)) {
                print.boldRedLine("No box.json file found");
                return;
            }
            
            local.boxJson = deserializeJSON(fileRead(local.boxJsonPath));
            local.isDev = false;
            local.found = false;
            
            // Check regular dependencies
            if (structKeyExists(local.boxJson, "dependencies") && 
                structKeyExists(local.boxJson.dependencies, arguments.name)) {
                local.found = true;
            }
            
            // Check dev dependencies
            if (!local.found && structKeyExists(local.boxJson, "devDependencies") && 
                structKeyExists(local.boxJson.devDependencies, arguments.name)) {
                local.found = true;
                local.isDev = true;
            }
            
            if (!local.found) {
                print.boldRedLine("Dependency '#arguments.name#' not found in box.json");
                print.line("Use 'wheels deps list' to see available dependencies");
                return;
            }
            
            // Remove the dependency
            local.uninstallCmd = "uninstall #arguments.name#";
            
            print.line("Running: box #local.uninstallCmd#");
            command(local.uninstallCmd).run();
            
            print.boldGreenLine("#arguments.name# removed successfully");
            
            if (local.isDev) {
                print.yellowLine("Removed from devDependencies");
            } else {
                print.yellowLine("Removed from dependencies");
            }
            
        } catch (any e) {
            print.boldRedLine("Failed to remove #arguments.name#");
            print.redLine("Error: #e.message#");
        }
    }
    
    /**
     * Generate dependency report
     */
    private void function generateDependencyReport() {
        print.line("Generating dependency report...");
        
        try {
            local.report = {
                "timestamp": now(),
                "project": "",
                "wheelsVersion": "",
                "cfmlEngine": server.coldfusion.productName & " " & server.coldfusion.productVersion,
                "dependencies": {},
                "devDependencies": {},
                "installedModules": [],
                "outdated": []
            };
            
            // Get project info from box.json
            local.boxJsonPath = fileSystemUtil.resolvePath("box.json");
            if (fileExists(local.boxJsonPath)) {
                local.boxJson = deserializeJSON(fileRead(local.boxJsonPath));
                
                if (structKeyExists(local.boxJson, "name")) {
                    local.report.project = local.boxJson.name;
                }
                
                if (structKeyExists(local.boxJson, "version")) {
                    local.report.projectVersion = local.boxJson.version;
                }
                
                if (structKeyExists(local.boxJson, "dependencies")) {
                    local.report.dependencies = local.boxJson.dependencies;
                }
                
                if (structKeyExists(local.boxJson, "devDependencies")) {
                    local.report.devDependencies = local.boxJson.devDependencies;
                }
            }
            
            // Get Wheels version
            try {
                local.versionInfo = $sendToCliCommand(urlstring="&command=info");
                if (structKeyExists(local.versionInfo, "wheelsVersion")) {
                    local.report.wheelsVersion = local.versionInfo.wheelsVersion;
                }
            } catch (any e) {
                // Ignore
            }
            
            // Check installed modules
            local.modulesPath = fileSystemUtil.resolvePath("modules");
            if (directoryExists(local.modulesPath)) {
                local.modules = directoryList(local.modulesPath, false, "query");
                for (local.module in local.modules) {
                    if (local.module.type == "Dir") {
                        local.moduleInfo = {
                            "name": local.module.name,
                            "path": local.modulesPath & "/" & local.module.name
                        };
                        
                        // Check for module box.json
                        local.moduleBoxPath = local.moduleInfo.path & "/box.json";
                        if (fileExists(local.moduleBoxPath)) {
                            try {
                                local.moduleBox = deserializeJSON(fileRead(local.moduleBoxPath));
                                if (structKeyExists(local.moduleBox, "version")) {
                                    local.moduleInfo.version = local.moduleBox.version;
                                }
                            } catch (any e) {
                                // Ignore
                            }
                        }
                        
                        arrayAppend(local.report.installedModules, local.moduleInfo);
                    }
                }
            }
            
            // Display report
            print.boldYellowLine("Dependency Report:");
            print.line();
            print.yellowLine("Generated: #dateTimeFormat(local.report.timestamp, 'yyyy-mm-dd HH:nn:ss')#");
            if (len(local.report.project)) {
                print.yellowLine("Project: #local.report.project#");
            }
            if (structKeyExists(local.report, "projectVersion")) {
                print.yellowLine("Project Version: #local.report.projectVersion#");
            }
            print.yellowLine("Wheels Version: #local.report.wheelsVersion#");
            print.yellowLine("CFML Engine: #local.report.cfmlEngine#");
            print.line();
            
            // Display dependencies
            if (structCount(local.report.dependencies) > 0) {
                print.yellowLine("Dependencies:");
                local.depsTable = [];
                for (local.dep in local.report.dependencies) {
                    local.installed = checkIfInstalled(local.dep);
                    arrayAppend(local.depsTable, [
                        local.dep, 
                        local.report.dependencies[local.dep], 
                        local.installed ? "Yes" : "No"
                    ]);
                }
                // print.table(local.depsTable, ["Package", "Version", "Installed"]);
                for (local.row in local.depsTable) {
                    print.line("  " & local.row[1] & " @ " & local.row[2] & " - Installed: " & local.row[3]);
                }
                print.line();
            }
            
            // Display dev dependencies
            if (structCount(local.report.devDependencies) > 0) {
                print.yellowLine("Dev Dependencies:");
                local.devDepsTable = [];
                for (local.dep in local.report.devDependencies) {
                    local.installed = checkIfInstalled(local.dep);
                    arrayAppend(local.devDepsTable, [
                        local.dep, 
                        local.report.devDependencies[local.dep],
                        local.installed ? "Yes" : "No"
                    ]);
                }
                // print.table(local.devDepsTable, ["Package", "Version", "Installed"]);
                for (local.row in local.devDepsTable) {
                    print.line("  " & local.row[1] & " @ " & local.row[2] & " - Installed: " & local.row[3]);
                }
                print.line();
            }
            
            // Display installed modules
            if (arrayLen(local.report.installedModules) > 0) {
                print.yellowLine("Installed Modules:");
                local.modulesTable = [];
                for (local.module in local.report.installedModules) {
                    local.version = structKeyExists(local.module, "version") ? local.module.version : "Unknown";
                    arrayAppend(local.modulesTable, [local.module.name, local.version]);
                }
                // print.table(local.modulesTable, ["Module", "Version"]);
                for (local.row in local.modulesTable) {
                    print.line("  " & local.row[1] & " (" & local.row[2] & ")");
                }
                print.line();
            }
            
            // Check for outdated packages
            print.yellowLine("Checking for outdated packages...");
            try {
                local.outdatedResult = command("outdated").run(returnOutput=true);
                if (len(trim(local.outdatedResult))) {
                    print.line(local.outdatedResult);
                } else {
                    print.greenLine("All packages are up to date!");
                }
            } catch (any e) {
                print.line("Unable to check for outdated packages");
            }
            
            // Save report to file
            local.reportPath = fileSystemUtil.resolvePath("dependency-report-#dateTimeFormat(now(), 'yyyymmdd-HHnnss')#.json");
            fileWrite(local.reportPath, serializeJSON(local.report, true));
            print.line();
            print.greenLine("Full report exported to: #local.reportPath#");
            
        } catch (any e) {
            print.boldRedLine("Error generating report: #e.message#");
        }
    }
    
    /**
     * Check if a module is installed
     */
    private boolean function checkIfInstalled(required string packageName) {
        // Check modules directory
        local.modulesPath = fileSystemUtil.resolvePath("modules");
        if (directoryExists(local.modulesPath)) {
            // Simple name check
            local.simpleName = listLast(arguments.packageName, ":");
            local.modulePath = local.modulesPath & "/" & local.simpleName;
            if (directoryExists(local.modulePath)) {
                return true;
            }
            
            // Check with package name variations
            local.variations = [
                arguments.packageName,
                replace(arguments.packageName, ":", "-", "all"),
                replace(arguments.packageName, "@", "-", "all")
            ];
            
            for (local.variation in local.variations) {
                local.modulePath = local.modulesPath & "/" & local.variation;
                if (directoryExists(local.modulePath)) {
                    return true;
                }
            }
        }
        
        return false;
    }
}