/**
 * List installed Wheels plugins
 * Examples:
 * wheels plugins list
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
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                format=["table", "json"]
            }
        );

        if (arguments.available) {
            // Show available plugins from ForgeBox
            print.line()
                 .boldCyanLine("===========================================================")
                 .boldCyanLine("  Available Wheels Plugins on ForgeBox")
                 .boldCyanLine("===========================================================")
                 .line();
            command('forgebox show').params(type="cfwheels-plugins").run();
            return;
        }

        // Show installed plugins
        var plugins = pluginService.list();

        if (arrayLen(plugins) == 0) {
            print.line()
                 .boldCyanLine("===========================================================")
                 .boldCyanLine("  Installed Wheels Plugins")
                 .boldCyanLine("===========================================================")
                 .line();
            print.yellowLine("No plugins installed in /plugins folder")
                 .line();
            print.line("Install plugins with:")
                 .cyanLine("  wheels plugin install <plugin-name>")
                 .line();
            print.line("See available plugins:")
                 .cyanLine("  wheels plugin list --available");
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
            print.line()
                 .boldCyanLine("===========================================================")
                 .boldCyanLine("  Installed Wheels Plugins (#arrayLen(plugins)#)")
                 .boldCyanLine("===========================================================")
                 .line();

            // Calculate column widths dynamically
            var maxNameLength = 20; // minimum width
            var maxVersionLength = 10; // minimum width

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

            // Print table header
            print.boldText(padRight("Plugin Name", maxNameLength))
                 .boldText(padRight("Version", maxVersionLength))
                 .boldLine("Description");

            print.line(repeatString("-", maxNameLength + maxVersionLength + 40));

            // Display plugins in table format
            for (var plugin in plugins) {
                var name = padRight(plugin.name, maxNameLength);
                var version = padRight(plugin.version, maxVersionLength);
                var description = plugin.keyExists("description") && len(plugin.description) ?
                                left(plugin.description, 40) : "";

                print.cyanText(name)
                     .greenText(version)
                     .line(description);
            }

            print.line()
                 .boldLine("-----------------------------------------------------------")
                 .line();

            print.boldGreenText("[OK] ")
                 .line("#arrayLen(plugins)# plugin#arrayLen(plugins) != 1 ? 's' : ''# installed")
                 .line();

            print.line("Commands:")
                 .cyanLine("  wheels plugin info <name>      View plugin details")
                 .cyanLine("  wheels plugin update:all       Update all plugins")
                 .cyanLine("  wheels plugin outdated         Check for updates");
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
