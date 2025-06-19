/**
 * Update all installed Wheels plugins to their latest versions
 * Examples:
 * wheels plugin update:all
 * wheels plugin update:all --dry-run
 */
component aliases="wheels plugin update:all,wheels plugins update:all" extends="../base" {
    
    property name="pluginService" inject="PluginService@wheels-cli";
    property name="packageService" inject="PackageService@commandbox-core";
    property name="forgebox" inject="ForgeBox@commandbox-core";
    
    /**
     * @dryRun.hint Show what would be updated without actually updating
     * @force.hint Force update even if already at latest version
     */
    function run(
        boolean dryRun = false,
        boolean force = false
    ) {
        try {
            print.greenBoldLine("🔄 Checking for plugin updates...")
                 .line();
            
            // Get list of installed plugins
            var plugins = pluginService.list(global = false);
            
            if (arrayLen(plugins) == 0) {
                print.yellowLine("No plugins installed locally");
                print.line("Install plugins with: wheels plugin install <plugin-name>");
                return;
            }
            
            var updatesAvailable = [];
            var upToDate = [];
            var errors = [];
            
            // Check each plugin for updates
            for (var plugin in plugins) {
                try {
                    print.text("Checking #plugin.name#... ");
                    
                    // Get latest version from ForgeBox
                    var packageInfo = forgebox.getPackage(plugin.name);
                    var latestVersion = packageInfo.version ?: "unknown";
                    var currentVersion = plugin.version;
                    
                    // Compare versions
                    if (currentVersion != latestVersion && latestVersion != "unknown") {
                        print.yellowLine("update available (#currentVersion# → #latestVersion#)");
                        arrayAppend(updatesAvailable, {
                            name: plugin.name,
                            currentVersion: currentVersion,
                            latestVersion: latestVersion,
                            isDev: plugin.dev ?: false
                        });
                    } else {
                        print.greenLine("up to date (#currentVersion#)");
                        arrayAppend(upToDate, plugin.name);
                    }
                    
                } catch (any e) {
                    print.redLine("error checking");
                    arrayAppend(errors, {
                        name: plugin.name,
                        error: e.message
                    });
                }
            }
            
            print.line();
            
            // Show summary
            if (arrayLen(updatesAvailable) == 0) {
                print.greenLine("✅ All plugins are up to date!");
                return;
            }
            
            // Show available updates
            print.boldLine("Updates available:")
                 .line();
            
            for (var update in updatesAvailable) {
                print.line("  📦 #update.name#: #update.currentVersion# → #update.latestVersion#");
            }
            
            print.line();
            
            if (arguments.dryRun) {
                print.yellowLine("Dry run mode - no updates will be performed");
                print.line("Remove --dry-run to actually update plugins");
                return;
            }
            
            // Confirm updates
            if (!arguments.force) {
                var continue = ask("Update #arrayLen(updatesAvailable)# plugin#arrayLen(updatesAvailable) != 1 ? 's' : ''#? (y/N): ");
                if (lCase(continue) != "y") {
                    print.yellowLine("Update cancelled");
                    return;
                }
            }
            
            print.line();
            
            // Perform updates
            var successCount = 0;
            var failCount = 0;
            
            for (var update in updatesAvailable) {
                try {
                    print.line("Updating #update.name#...");
                    
                    // Update the plugin
                    packageService.installPackage(
                        ID = update.name & "@" & update.latestVersion,
                        save = true,
                        saveDev = update.isDev,
                        force = true
                    );
                    
                    // Update box.json
                    var boxJsonPath = resolvePath("box.json");
                    var boxJson = deserializeJSON(fileRead(boxJsonPath));
                    var depType = update.isDev ? "devDependencies" : "dependencies";
                    
                    boxJson[depType][update.name] = update.name & "@" & update.latestVersion;
                    fileWrite(boxJsonPath, serializeJSON(boxJson, true));
                    
                    print.greenLine("  ✅ Updated successfully!");
                    successCount++;
                    
                } catch (any e) {
                    print.redLine("  ❌ Update failed: #e.message#");
                    failCount++;
                }
            }
            
            // Show final summary
            print.line()
                 .boldLine("Update Summary:")
                 .line();
            
            if (successCount > 0) {
                print.greenLine("✅ #successCount# plugin#successCount != 1 ? 's' : ''# updated successfully");
            }
            
            if (failCount > 0) {
                print.redLine("❌ #failCount# plugin#failCount != 1 ? 's' : ''# failed to update");
            }
            
            if (arrayLen(errors) > 0) {
                print.yellowLine("⚠️  #arrayLen(errors)# plugin#arrayLen(errors) != 1 ? 's' : ''# could not be checked");
            }
            
            print.line()
                 .line("To see all installed plugins:")
                 .yellowLine("  wheels plugin list");
            
        } catch (any e) {
            error("Error updating plugins: #e.message#");
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