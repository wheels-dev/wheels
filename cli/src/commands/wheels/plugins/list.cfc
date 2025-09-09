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
        arguments = reconstructArgs(arguments);
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
            // JSON format output
            var jsonOutput = {
                "plugins": plugins
            };
            print.line(serializeJSON(jsonOutput, true));
        } else {
            // Table format output (matching the guide)
            print.line("Installed Wheels CLI Plugins" & (arguments.global ? " (Global)" : ""))
                 .line();
            
            if (arrayLen(plugins) > 0) {
                // Print table header
                print.line("Name                Version    Description");
                print.line("---------------------------------------------");
                
                // Display plugins in table format
                for (var plugin in plugins) {
                    var name = padRight(plugin.name, 20);
                    var version = padRight(plugin.version, 11);
                    var description = plugin.keyExists("description") && len(plugin.description) ? plugin.description : "";
                    
                    // Truncate description if too long
                    if (len(description) > 40) {
                        description = left(description, 37) & "...";
                    }
                    
                    print.line("#name##version##description#");
                }
                
                print.line();
                print.yellowLine("Total: #arrayLen(plugins)# plugin" & (arrayLen(plugins) != 1 ? "s" : ""));
            }
        }
    }
    
    /**
     * Pad string to right with spaces
     */
    private function padRight(required string text, required numeric length) {
        if (len(arguments.text) >= arguments.length) {
            return left(arguments.text, arguments.length);
        }
        return arguments.text & repeatString(" ", arguments.length - len(arguments.text));
    }
}
