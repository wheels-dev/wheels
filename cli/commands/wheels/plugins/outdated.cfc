/**
 * List outdated Wheels plugins that have newer versions available
 * Examples:
 * wheels plugin outdated
 * wheels plugin outdated --format=json
 */
component aliases="wheels plugin outdated,wheels plugins outdated" extends="../base" {
    
    property name="pluginService" inject="PluginService@wheels-cli";
    property name="forgebox" inject="ForgeBox@commandbox-core";
    
    /**
     * @format.hint Output format: table (default) or json
     * @format.options table,json
     */
    function run(
        string format = "table"
    ) {
        try {
            print.greenBoldLine("📊 Checking for outdated plugins...")
                 .line();
            
            // Get list of installed plugins
            var plugins = pluginService.list(global = false);
            
            if (arrayLen(plugins) == 0) {
                print.yellowLine("No plugins installed locally");
                print.line("Install plugins with: wheels plugin install <plugin-name>");
                return;
            }
            
            var outdatedPlugins = [];
            var checkErrors = [];
            
            // Check each plugin
            for (var plugin in plugins) {
                try {
                    print.text("Checking #plugin.name#... ");
                    
                    // Get latest version from ForgeBox
                    var packageInfo = forgebox.getPackage(plugin.name);
                    var latestVersion = packageInfo.version ?: "unknown";
                    var currentVersion = plugin.version;
                    
                    // Compare versions
                    if (currentVersion != latestVersion && latestVersion != "unknown") {
                        print.yellowLine("outdated");
                        
                        arrayAppend(outdatedPlugins, {
                            name: plugin.name,
                            currentVersion: currentVersion,
                            latestVersion: latestVersion,
                            isDev: plugin.dev ?: false,
                            updateDate: packageInfo.updateDate ?: "",
                            author: packageInfo.author.name ?: "Unknown"
                        });
                    } else {
                        print.greenLine("up to date");
                    }
                    
                } catch (any e) {
                    print.redLine("error");
                    arrayAppend(checkErrors, plugin.name);
                }
            }
            
            print.line();
            
            // Handle no outdated plugins
            if (arrayLen(outdatedPlugins) == 0) {
                print.greenLine("✅ All plugins are up to date!");
                
                if (arrayLen(checkErrors) > 0) {
                    print.line()
                         .yellowLine("⚠️  Could not check #arrayLen(checkErrors)# plugin#arrayLen(checkErrors) != 1 ? 's' : ''#:");
                    for (var errorPlugin in checkErrors) {
                        print.line("  • #errorPlugin#");
                    }
                }
                
                return;
            }
            
            // Display outdated plugins
            if (arguments.format == "json") {
                print.line(serializeJSON(outdatedPlugins, true));
            } else {
                print.boldLine("Outdated Plugins:")
                     .line();
                
                // Display as table
                print.table(
                    data = outdatedPlugins.map(function(plugin) {
                        return {
                            "Plugin": plugin.name,
                            "Current": plugin.currentVersion,
                            "Latest": plugin.latestVersion,
                            "Type": plugin.isDev ? "dev" : "prod",
                            "Updated": plugin.updateDate ? dateFormat(plugin.updateDate, "yyyy-mm-dd") : "N/A"
                        };
                    }),
                    headers = ["Plugin", "Current", "Latest", "Type", "Updated"]
                );
                
                print.line()
                     .yellowLine("Found #arrayLen(outdatedPlugins)# outdated plugin#arrayLen(outdatedPlugins) != 1 ? 's' : ''#");
                
                if (arrayLen(checkErrors) > 0) {
                    print.line()
                         .yellowLine("⚠️  Could not check #arrayLen(checkErrors)# plugin#arrayLen(checkErrors) != 1 ? 's' : ''#");
                }
                
                // Show update commands
                print.line()
                     .boldLine("Update Commands:")
                     .line();
                
                if (arrayLen(outdatedPlugins) == 1) {
                    print.line("Update this plugin:")
                         .yellowLine("  wheels plugin update #outdatedPlugins[1].name#");
                } else {
                    print.line("Update all plugins:")
                         .yellowLine("  wheels plugin update:all")
                         .line()
                         .line("Update specific plugin:")
                         .yellowLine("  wheels plugin update <plugin-name>");
                }
                
                print.line()
                     .line("Preview updates without installing:")
                     .yellowLine("  wheels plugin update:all --dry-run");
            }
            
        } catch (any e) {
            error("Error checking for outdated plugins: #e.message#");
        }
    }
}