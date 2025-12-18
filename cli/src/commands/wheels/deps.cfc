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
    
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

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
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                action=["list", "install", "update", "remove", "report"]
            }
        );

        // Welcome message
        detailOutput.header("Wheels Dependency Manager");
        
        // Handle different actions
        switch (lCase(arguments.action)) {
            case "list":
                listDependencies();
                break;
            case "install":
                if (len(trim(arguments.name)) == 0) {
                    detailOutput.error("Name parameter is required for install action");
                    return;
                }
                installDependency(arguments.name, arguments.version, arguments.dev);
                break;
            case "update":
                if (len(trim(arguments.name)) == 0) {
                    detailOutput.error("Name parameter is required for update action");
                    return;
                }
                updateDependency(arguments.name);
                break;
            case "remove":
                if (len(trim(arguments.name)) == 0) {
                    detailOutput.error("Name parameter is required for remove action");
                    return;
                }
                removeDependency(arguments.name);
                break;
            case "report":
                generateDependencyReport();
                break;
        }
        
        detailOutput.line();
    }
    
    /**
     * List installed dependencies from box.json
     */
    private void function listDependencies() {
        detailOutput.output("Retrieving dependencies from box.json...");
        
        try {
            local.boxJsonPath = fileSystemUtil.resolvePath("box.json");
            
            if (!fileExists(local.boxJsonPath)) {
                detailOutput.error("No box.json file found");
                detailOutput.output("Run 'box init' to create a box.json file");
                return;
            }
            
            local.boxJson = deserializeJSON(fileRead(local.boxJsonPath));
            local.hasDeps = false;
            
            // List regular dependencies
            if (structKeyExists(local.boxJson, "dependencies") && structCount(local.boxJson.dependencies) > 0) {
                detailOutput.subHeader("Dependencies");
                local.depsTable = [];
                
                for (local.dep in local.boxJson.dependencies) {
                    local.version = local.boxJson.dependencies[local.dep];
                    local.installed = checkIfInstalled(local.dep);
                    local.status = local.installed ? "Installed" : "Not Installed";
                    
                    arrayAppend(local.depsTable, [local.dep, local.version, "Production", local.status]);
                }
                
                for (local.row in local.depsTable) {
                    detailOutput.output("  " & local.row[1] & " @ " & local.row[2] & " (" & local.row[3] & ") - " & local.row[4], true);
                }
                local.hasDeps = true;
            }
            
            // List dev dependencies
            if (structKeyExists(local.boxJson, "devDependencies") && structCount(local.boxJson.devDependencies) > 0) {
                detailOutput.line();
                detailOutput.subHeader("Dev Dependencies");
                local.devDepsTable = [];
                
                for (local.dep in local.boxJson.devDependencies) {
                    local.version = local.boxJson.devDependencies[local.dep];
                    local.installed = checkIfInstalled(local.dep);
                    local.status = local.installed ? "Installed" : "Not Installed";
                    
                    arrayAppend(local.devDepsTable, [local.dep, local.version, "Development", local.status]);
                }
                
                for (local.row in local.devDepsTable) {
                    detailOutput.output("  " & local.row[1] & " @ " & local.row[2] & " (" & local.row[3] & ") - " & local.row[4], true);
                }
                local.hasDeps = true;
            }
            
            if (!local.hasDeps) {
                detailOutput.statusWarning("No dependencies found in box.json");
                detailOutput.output("Use 'wheels deps install <package>' to add dependencies");
            }
            
        } catch (any e) {
            detailOutput.statusFailed("Error reading dependencies: #e.message#");
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
        detailOutput.output("Installing #arguments.name#...");
        
        try {
            // Prepare install command
            local.installCmd = "install #arguments.name#";
            
            if (len(trim(arguments.version))) {
                local.installCmd &= "@#arguments.version#";
            }
            
            if (arguments.dev) {
                local.installCmd &= " --saveDev";
            }
            
            // Run CommandBox install
            detailOutput.output("Running: box #local.installCmd#");
            command(local.installCmd).run();
            
            detailOutput.statusSuccess("#arguments.name# installed successfully");
            
            // Show post-install information
            local.boxJsonPath = fileSystemUtil.resolvePath("box.json");
            if (fileExists(local.boxJsonPath)) {
                local.boxJson = deserializeJSON(fileRead(local.boxJsonPath));
                local.depType = arguments.dev ? "devDependencies" : "dependencies";
                
                if (structKeyExists(local.boxJson, local.depType) && 
                    structKeyExists(local.boxJson[local.depType], arguments.name)) {
                    detailOutput.statusInfo("Added to #local.depType#: #arguments.name# @ #local.boxJson[local.depType][arguments.name]#");
                }
            }
            
        } catch (any e) {
            detailOutput.statusFailed("Failed to install #arguments.name#");
            detailOutput.error("Error: #e.message#");
            return;
        }
    }
    
    /**
     * Update a dependency
     */
    private void function updateDependency(required string name) {
        detailOutput.output("Updating #arguments.name#...");
        
        try {
            // Check if dependency exists in box.json
            local.boxJsonPath = fileSystemUtil.resolvePath("box.json");
            if (!fileExists(local.boxJsonPath)) {
                detailOutput.error("No box.json file found");
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
                detailOutput.statusFailed("Dependency '#arguments.name#' not found in box.json");
                detailOutput.statusInfo("Use 'wheels deps list' to see available dependencies");
                return;
            }
            
            // Update the dependency
            detailOutput.statusInfo("Current version: #local.currentVersion#");
            
            local.updateCmd = "update #arguments.name#";
            if (local.isDev) {
                local.updateCmd &= " --dev";
            }
            
            detailOutput.output("Running: box #local.updateCmd#");
            command(local.updateCmd).run();
            
            detailOutput.statusSuccess("#arguments.name# updated successfully");
            
            // Show new version
            local.boxJson = deserializeJSON(fileRead(local.boxJsonPath));
            local.depType = local.isDev ? "devDependencies" : "dependencies";
            
            if (structKeyExists(local.boxJson, local.depType) && 
                structKeyExists(local.boxJson[local.depType], arguments.name)) {
                local.newVersion = local.boxJson[local.depType][arguments.name];
                if (local.currentVersion != local.newVersion) {
                    detailOutput.statusInfo("Updated from #local.currentVersion# to #local.newVersion#");
                }
            }
            
        } catch (any e) {
            detailOutput.statusFailed("Failed to update #arguments.name#");
            detailOutput.error("Error: #e.message#");
            return;
        }
    }
    
    /**
     * Remove a dependency
     */
    private void function removeDependency(required string name) {
        if (!confirm("Are you sure you want to remove #arguments.name#? [y/n]")) {
            detailOutput.output("Aborted");
            return;
        }
        
        detailOutput.output("Removing #arguments.name#...");
        
        try {
            // Check if dependency exists in box.json
            local.boxJsonPath = fileSystemUtil.resolvePath("box.json");
            if (!fileExists(local.boxJsonPath)) {
                detailOutput.error("No box.json file found");
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
                detailOutput.statusFailed("Dependency '#arguments.name#' not found in box.json");
                detailOutput.output("Use 'wheels deps list' to see available dependencies");
                return;
            }
            
            // Remove the dependency
            local.uninstallCmd = "uninstall #arguments.name#";
            
            detailOutput.output("Running: box #local.uninstallCmd#");
            command(local.uninstallCmd).run();
            
            detailOutput.statusSuccess("#arguments.name# removed successfully");
            
            if (local.isDev) {
                detailOutput.statusInfo("Removed from devDependencies");
            } else {
                detailOutput.statusInfo("Removed from dependencies");
            }
            
        } catch (any e) {
            detailOutput.statusFailed("Failed to remove #arguments.name#");
            detailOutput.error("Error: #e.message#");
            return;
        }
    }
    
    /**
     * Generate dependency report
     */
    private void function generateDependencyReport() {
        detailOutput.output("Generating dependency report...");
        
        try {
            local.report = {
                "timestamp": now(),
                "project": "",
                "wheelsVersion": "",
                "cfmlEngine": getCFMLEngineInfo(),
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
            
            // Try to get Wheels version from vendor/wheels/box.json
            local.wheelsBoxPath = fileSystemUtil.resolvePath("vendor/wheels/box.json");
            if (fileExists(local.wheelsBoxPath)) {
                try {
                    local.wheelsBox = deserializeJSON(fileRead(local.wheelsBoxPath));
                    if (structKeyExists(local.wheelsBox, "version")) {
                        local.report.wheelsVersion = local.wheelsBox.version;
                    }
                } catch (any e) {
                    // Try fallback method
                    try {
                        local.report.wheelsVersion = $getWheelsVersion();
                    } catch (any e2) {
                        local.report.wheelsVersion = "Unknown";
                    }
                }
            } else {
                // Try fallback method
                try {
                    local.report.wheelsVersion = $getWheelsVersion();
                } catch (any e) {
                    local.report.wheelsVersion = "Unknown";
                }
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
            detailOutput.header("Dependency Report");
            detailOutput.metric("Generated", dateTimeFormat(local.report.timestamp, 'yyyy-mm-dd HH:nn:ss'));
            if (len(local.report.project)) {
                detailOutput.metric("Project", local.report.project);
            }
            if (structKeyExists(local.report, "projectVersion")) {
                detailOutput.metric("Project Version", local.report.projectVersion);
            }
            detailOutput.metric("Wheels Version", local.report.wheelsVersion);
            detailOutput.metric("CFML Engine", local.report.cfmlEngine);
            detailOutput.line();
            
            // Display dependencies
            if (structCount(local.report.dependencies) > 0) {
                detailOutput.subHeader("Dependencies");
                local.depsTable = [];
                for (local.dep in local.report.dependencies) {
                    local.installed = checkIfInstalled(local.dep);
                    arrayAppend(local.depsTable, [
                        local.dep, 
                        local.report.dependencies[local.dep], 
                        local.installed ? "Yes" : "No"
                    ]);
                }
                for (local.row in local.depsTable) {
                    detailOutput.output("  " & local.row[1] & " @ " & local.row[2] & " - Installed: " & local.row[3], true);
                }
                detailOutput.line();
            }
            
            // Display dev dependencies
            if (structCount(local.report.devDependencies) > 0) {
                detailOutput.subHeader("Dev Dependencies");
                local.devDepsTable = [];
                for (local.dep in local.report.devDependencies) {
                    local.installed = checkIfInstalled(local.dep);
                    arrayAppend(local.devDepsTable, [
                        local.dep, 
                        local.report.devDependencies[local.dep],
                        local.installed ? "Yes" : "No"
                    ]);
                }
                for (local.row in local.devDepsTable) {
                    detailOutput.output("  " & local.row[1] & " @ " & local.row[2] & " - Installed: " & local.row[3], true);
                }
                detailOutput.line();
            }
            
            // Display installed modules
            if (arrayLen(local.report.installedModules) > 0) {
                detailOutput.subHeader("Installed Modules");
                local.modulesTable = [];
                for (local.module in local.report.installedModules) {
                    local.version = structKeyExists(local.module, "version") ? local.module.version : "Unknown";
                    arrayAppend(local.modulesTable, [local.module.name, local.version]);
                }
                for (local.row in local.modulesTable) {
                    detailOutput.output("  " & local.row[1] & " (" & local.row[2] & ")", true);
                }
                detailOutput.line();
            }
            
            // Check for outdated packages
            detailOutput.output("Checking for outdated packages...");
            try {
                local.outdatedResult = command("outdated").run(returnOutput=true);
                if (len(trim(local.outdatedResult))) {
                    detailOutput.code(local.outdatedResult);
                } else {
                    detailOutput.statusSuccess("All packages are up to date!");
                }
            } catch (any e) {
                detailOutput.statusWarning("Unable to check for outdated packages");
            }
            
            // Save report to file
            local.reportPath = fileSystemUtil.resolvePath("dependency-report-#dateTimeFormat(now(), 'yyyymmdd-HHnnss')#.json");
            fileWrite(local.reportPath, serializeJSON(local.report, true));
            detailOutput.line();
            detailOutput.statusSuccess("Full report exported to: #local.reportPath#");
            
        } catch (any e) {
            detailOutput.statusFailed("Error generating report: #e.message#");
        }
    }
    
    /**
     * Get CFML engine information
     */
    private string function getCFMLEngineInfo() {
        try {
            if (StructKeyExists(server, "lucee")) {
                return "Lucee " & server.lucee.version;
            } else if (StructKeyExists(server, "coldfusion")) {
                return server.coldfusion.productname & " " & server.coldfusion.productversion;
            }
        } catch (any e) {
            // Continue to fallback
        }
        return "Unknown";
    }

    /**
     * Check if a module is installed
     */
    private boolean function checkIfInstalled(required string packageName) {
        // First check if we have install paths in box.json
        try {
            local.boxJsonPath = fileSystemUtil.resolvePath("box.json");
            if (fileExists(local.boxJsonPath)) {
                local.boxJson = deserializeJSON(fileRead(local.boxJsonPath));

                // Check installPaths first (most reliable)
                if (structKeyExists(local.boxJson, "installPaths") &&
                    structKeyExists(local.boxJson.installPaths, arguments.packageName)) {
                    local.installPath = fileSystemUtil.resolvePath(local.boxJson.installPaths[arguments.packageName]);
                    return directoryExists(local.installPath);
                }
            }
        } catch (any e) {
            // Continue to fallback methods
        }

        // Fallback: Check standard locations
        local.standardPaths = [
            "modules/#arguments.packageName#",
            "modules/#listLast(arguments.packageName, ':')#",
            arguments.packageName,
            listLast(arguments.packageName, ":")
        ];

        for (local.path in local.standardPaths) {
            local.fullPath = fileSystemUtil.resolvePath(local.path);
            if (directoryExists(local.fullPath)) {
                return true;
            }
        }

        return false;
    }
}