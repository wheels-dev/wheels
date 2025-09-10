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
     * @format.hint Output format: table (default) or json
     * @format.options table,json
     * @available.hint Show available plugins from ForgeBox
     */
    function run(
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
        var plugins = pluginService.list();
        
        if (arrayLen(plugins) == 0) {
            print.yellowLine("No plugins installed");
            print.line("Install plugins with: wheels plugins install <plugin-name>");
            print.line("See available plugins with: wheels plugins list --available");
            return;
        }
        
        if (arguments.format == "json") {
            // JSON format output
            var jsonOutput = {
                "plugins": plugins
            };
            print.line(jsonOutput);
        } else {
            // Table format output (matching the guide)
            print.line("Installed Wheels CLI Plugins")
                 .line();
            
            if (arrayLen(plugins) > 0) {
                // Calculate column widths dynamically
                var maxNameLength = 4; // minimum for "Name"
                var maxVersionLength = 7; // minimum for "Version"
                
                for (var plugin in plugins) {
                    if (len(plugin.name) > maxNameLength) {
                        maxNameLength = len(plugin.name);
                    }
                    if (len(plugin.version) > maxVersionLength) {
                        maxVersionLength = len(plugin.version);
                    }
                }
                
                // Add padding
                maxNameLength += 2;
                maxVersionLength += 2;
                
                // Print dynamic table header
                var headerLine = padRight("Name", maxNameLength) & padRight("Version", maxVersionLength) & "Description";
                var separatorLine = repeatString("-", len(headerLine));
                
                print.line(headerLine);
                print.line(separatorLine);
                
                // Display plugins in table format with full information
                for (var plugin in plugins) {
                    var name = padRight(plugin.name, maxNameLength);
                    var version = padRight(plugin.version, maxVersionLength);
                    var description = plugin.keyExists("description") && len(plugin.description) ? plugin.description : "";
                    
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
