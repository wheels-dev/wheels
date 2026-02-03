/**
 * List installed Wheels plugins
 * Examples:
 * wheels plugins list
 * wheels plugins list --format=json
 * wheels plugins list --available
 */
component aliases="wheels plugin list" extends="../base" {

    property name="pluginService" inject="PluginService@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @format.hint Output format: table (default) or json
     * @format.options table,json
     * @available.hint Show available plugins from ForgeBox
     */
    function run(
        string format = "table",
        boolean available = false
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                format=["table", "json"]
            }
        );

        if (arguments.available) {
            // Show available plugins from ForgeBox
            detailOutput.header("Available Wheels Plugins on ForgeBox");
            detailOutput.line();
            command('forgebox show').params(type="cfwheels-plugins").run();
            return;
        }

        // Show installed plugins
        var plugins = pluginService.list();

        if (arrayLen(plugins) == 0) {
            detailOutput.header("Installed Wheels Plugins");
            detailOutput.line();
            detailOutput.statusWarning("No plugins installed in /plugins folder");
            detailOutput.line();
            detailOutput.subHeader("Install plugins with");
            detailOutput.output("- wheels plugin install <plugin-name>", true);
            detailOutput.line();
            detailOutput.subHeader("See available plugins");
            detailOutput.output("- wheels plugin list --available", true);
            detailOutput.output("- wheels plugin search <keyword>", true);
            return;
        }

        if (arguments.format == "json") {
            // JSON format output
            var jsonOutput = {
                "plugins": plugins,
                "count": arrayLen(plugins)
            };
            print.line(serializeJSON(jsonOutput, true));
        } else {
            // Table format output
            detailOutput.header("Installed Wheels Plugins (#arrayLen(plugins)#)");
            detailOutput.line();

            // Create table rows
            var rows = [];
            for (var plugin in plugins) {
                var row = {
                    "Plugin Name": plugin.name,
                    "Version": plugin.version
                };
                
                if (plugin.keyExists("description") && len(plugin.description)) {
                    row["Description"] = left(plugin.description, 50);
                } else {
                    row["Description"] = "";
                }
                
                // Add author if available
                if (plugin.keyExists("author") && len(plugin.author)) {
                    row["Author"] = left(plugin.author, 20);
                }
                
                arrayAppend(rows, row);
            }

            // Display the table
            detailOutput.getPrint().table(rows).toConsole();
            
            detailOutput.line();
            detailOutput.divider("-", 60);
            detailOutput.line();

            // Show summary
            detailOutput.metric("Total plugins", "#arrayLen(plugins)#");
            var devPlugins = 0;
            for (var plugin in plugins) {
                if (plugin.keyExists("type") && findNoCase("dev", plugin.type)) {
                    devPlugins++;
                }
            }
            if (devPlugins > 0) {
                detailOutput.metric("Development plugins", "#devPlugins#");
            }
            
            // Show most recent plugin if available
            if (arrayLen(plugins) > 0) {
                var recentPlugin = plugins[1]; // Assuming first is most recent
                detailOutput.metric("Latest plugin", "#recentPlugin.name# (#recentPlugin.version#)");
            }
            
            detailOutput.line();

            // Show commands
            detailOutput.subHeader("Commands");
            detailOutput.output("- wheels plugin info <name>      View plugin details", true);
            detailOutput.output("- wheels plugin update:all       Update all plugins", true);
            detailOutput.output("- wheels plugin outdated         Check for updates", true);
            detailOutput.output("- wheels plugin install <name>   Install new plugin", true);
            detailOutput.output("- wheels plugin remove <name>    Remove a plugin", true);
            detailOutput.line();
            
            // Add tip
            detailOutput.statusInfo("Tip");
            detailOutput.output("Add --format=json for JSON output", true);
        }
    }
}