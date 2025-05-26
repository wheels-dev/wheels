/**
 * List installed Wheels CLI plugins
 * Examples:
 * wheels plugins list
 * wheels plugins list --global
 * wheels plugins list --format=json
 * wheels plugins list --available
 */
component aliases="wheels plugin list" extends="../base" {
    
    property name="pluginService" inject="PluginService@wheels-cli";
    
    /**
     * @global.hint Show globally installed plugins
     * @format.hint Output format: table (default) or json
     * @format.options table,json
     * @available.hint Show available plugins from ForgeBox
     */
    function run(
        boolean global = false,
        string format = "table",
        boolean available = false
    ) {
        if (arguments.available) {
            // Show available plugins from ForgeBox
            print.greenBoldLine("================ Available Wheels Plugins From ForgeBox ======================");
            command('forgebox show').params(type="cfwheels-plugins").run();
            print.greenBoldLine("=============================================================================");
            return;
        }
        
        // Show installed plugins
        var plugins = pluginService.list(global = arguments.global);
        
        if (arrayLen(plugins) == 0) {
            print.yellowLine("No plugins installed" & (arguments.global ? " globally" : " locally"));
            print.line("Install plugins with: wheels plugins install <plugin-name>");
            print.line("See available plugins with: wheels plugins list --available");
            return;
        }
        
        if (arguments.format == "json") {
            print.line(serializeJSON(plugins, true));
        } else {
            print.greenBoldLine("🔌 Installed Wheels CLI Plugins" & (arguments.global ? " (Global)" : ""))
                 .line();
            
            // Display plugins in a formatted way
            for (var plugin in plugins) {
                print.line("📦 #plugin.name# (#plugin.version#)");
                
                if (plugin.keyExists("dev") && plugin.dev) {
                    print.text("   📌 Dev Dependency");
                }
                
                if (plugin.keyExists("description") && len(plugin.description)) {
                    print.line("   📝 #plugin.description#");
                }
                
                print.line();
            }
            
            print.yellowLine("Total plugins: #arrayLen(plugins)#");
        }
    }
}
