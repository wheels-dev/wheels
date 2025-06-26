/**
 * Update a specific Wheels plugin to the latest version
 * Examples:
 * wheels plugin update wheels-auth
 * wheels plugin update wheels-api-builder --version=2.0.0
 */
component aliases="wheels plugin update" extends="../base" {
    
    property name="pluginService" inject="PluginService@wheels-cli";
    property name="packageService" inject="PackageService@commandbox-core";
    
    /**
     * @name.hint Name of the plugin to update
     * @version.hint Specific version to update to (optional)
     * @force.hint Force update even if already at latest version
     */
    function run(
        required string name,
        string version = "",
        boolean force = false
    ) {
        try {
            print.greenBoldLine("🔄 Updating plugin: #arguments.name#")
                 .line();
            
            // Check if plugin is installed
            var boxJsonPath = resolvePath("box.json");
            if (!fileExists(boxJsonPath)) {
                error("No box.json found. Are you in a Wheels application directory?");
                return;
            }
            
            var boxJson = deserializeJSON(fileRead(boxJsonPath));
            var isInstalled = false;
            var isDev = false;
            var currentVersion = "";
            
            // Check dependencies
            if (boxJson.keyExists("dependencies") && boxJson.dependencies.keyExists(arguments.name)) {
                isInstalled = true;
                isDev = false;
                currentVersion = boxJson.dependencies[arguments.name];
            }
            
            // Check devDependencies
            if (boxJson.keyExists("devDependencies") && boxJson.devDependencies.keyExists(arguments.name)) {
                isInstalled = true;
                isDev = true;
                currentVersion = boxJson.devDependencies[arguments.name];
            }
            
            if (!isInstalled) {
                error("Plugin '#arguments.name#' is not installed. Use 'wheels plugin install #arguments.name#' to install it.");
                return;
            }
            
            print.line("Current version: #currentVersion#");
            
            // Determine target version
            var targetVersion = len(arguments.version) ? arguments.version : "latest";
            
            // Check if update is needed
            if (!arguments.force && targetVersion == "latest") {
                try {
                    var packageInfo = packageService.getPackage(arguments.name);
                    if (packageInfo.keyExists("version") && currentVersion == packageInfo.version) {
                        print.yellowLine("Plugin is already at the latest version (#packageInfo.version#)");
                        print.line("Use force=true to reinstall anyway");
                        return;
                    }
                } catch (any e) {
                    // Continue with update if we can't check the version
                }
            }
            
            print.line("Updating to: #targetVersion#")
                 .line();
            
            // Prepare the package spec
            var packageSpec = arguments.name;
            if (len(arguments.version)) {
                packageSpec &= "@" & arguments.version;
            }
            
            // Update the plugin
            print.line("Installing update...");
            
            packageService.installPackage(
                ID = packageSpec,
                save = true,
                saveDev = isDev,
                force = arguments.force
            );
            
            // Update box.json with new version
            var depType = isDev ? "devDependencies" : "dependencies";
            boxJson[depType][arguments.name] = packageSpec;
            fileWrite(boxJsonPath, serializeJSON(boxJson, true));
            
            print.greenLine()
                 .greenLine("✅ Plugin '#arguments.name#' updated successfully!")
                 .line();
            
            // Show post-update info
            print.line("To see plugin info:")
                 .yellowLine("  wheels plugin info #arguments.name#")
                 .line()
                 .line("To see all installed plugins:")
                 .yellowLine("  wheels plugin list");
            
        } catch (any e) {
            error("Error updating plugin: #e.message#");
        }
    }
    
    /**
     * Resolve a file path
     */
    private function resolvePath(path) {
        if (left(arguments.path, 1) == "/" || mid(arguments.path, 2, 1) == ":") {
            return arguments.path;
        }
        return expandPath(".") & "/" & arguments.path;
    }
}