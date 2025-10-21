/**
 * List outdated Wheels plugins that have newer versions available
 * Examples:
 * wheels plugin outdated
 * wheels plugin outdated --format=json
 */
component aliases="wheels plugin outdated,wheels plugins outdated" extends="../base" {
    
    property name="pluginService" inject="PluginService@wheels-cli";
    property name="forgebox" inject="ForgeBox";
    
    /**
     * @format.hint Output format: table (default) or json
     * @format.options table,json
     */
    function run(
        string format = "table"
    ) {

        // Reconstruct arguments to handle prefix (--)
        arguments = reconstructArgs(arguments);
        try {
            print.line()
                 .boldCyanLine("===========================================================")
                 .boldCyanLine("  Checking for Plugin Updates")
                 .boldCyanLine("===========================================================")
                 .line();

            // Get list of installed plugins from /plugins folder
            var plugins = pluginService.list();

            if (arrayLen(plugins) == 0) {
                print.yellowLine("No plugins installed in /plugins folder")
                     .line()
                     .line("Install plugins with:")
                     .cyanLine("  wheels plugin install <plugin-name>");
                return;
            }

            var outdatedPlugins = [];
            var checkErrors = [];

            // Check each plugin
            for (var plugin in plugins) {
                try {
                    var pluginSlug = plugin.slug ?: plugin.name;
                    var displayName = plugin.name;
                    var padding = repeatString(" ", max(40 - len(displayName), 1));

                    print.text("  " & displayName & padding);

                    // Get latest version using forgebox show command for fresh data
                    var forgeboxResult = command('forgebox show')
                        .params(pluginSlug)
                        .run(returnOutput=true);

                    var latestVersion = "unknown";
                    var versionMatch = reFind("Versions\s*:\s*([0-9\.]+)", forgeboxResult, 1, true);
                    if (versionMatch.pos[1] > 0) {
                        latestVersion = mid(forgeboxResult, versionMatch.pos[2], versionMatch.len[2]);
                    }

                    var currentVersion = plugin.version;

                    // Clean versions for comparison
                    var cleanCurrent = trim(reReplace(currentVersion, "[^0-9\.]", "", "ALL"));
                    var cleanLatest = trim(reReplace(latestVersion, "[^0-9\.]", "", "ALL"));

                    // Compare versions
                    if (cleanCurrent != cleanLatest && latestVersion != "unknown") {
                        print.yellowBoldText("[OUTDATED] ")
                             .yellowLine("#currentVersion# -> #latestVersion#");

                        arrayAppend(outdatedPlugins, {
                            name: plugin.name,
                            slug: pluginSlug,
                            currentVersion: currentVersion,
                            latestVersion: latestVersion
                        });
                    } else {
                        print.greenBoldText("[OK] ")
                             .greenLine("v#currentVersion#");
                    }

                } catch (any e) {
                    print.redBoldText("[ERROR] ")
                         .redLine("Could not check version");
                    arrayAppend(checkErrors, plugin.name);
                }
            }

            print.line()
                 .boldCyanLine("===========================================================")
                 .line();

            // Handle no outdated plugins
            if (arrayLen(outdatedPlugins) == 0) {
                print.boldGreenText("[OK] ")
                     .greenLine("All plugins are up to date!")
                     .line();

                if (arrayLen(checkErrors) > 0) {
                    print.yellowLine("Could not check #arrayLen(checkErrors)# plugin#arrayLen(checkErrors) != 1 ? 's' : ''#:")
                         .line();
                    for (var errorPlugin in checkErrors) {
                        print.yellowLine("  - #errorPlugin#");
                    }
                    print.line();
                }

                return;
            }

            // Display outdated plugins
            if (arguments.format == "json") {
                var jsonOutput = {
                    "outdated": outdatedPlugins,
                    "count": arrayLen(outdatedPlugins),
                    "errors": checkErrors
                };
                print.line(serializeJSON(jsonOutput, true));
            } else {
                print.boldYellowLine("Found #arrayLen(outdatedPlugins)# outdated plugin#arrayLen(outdatedPlugins) != 1 ? 's' : ''#:")
                     .line();

                // Calculate column widths
                var maxNameLength = 20;
                var maxCurrentLength = 10;
                var maxLatestLength = 10;

                for (var plugin in outdatedPlugins) {
                    if (len(plugin.name) > maxNameLength) {
                        maxNameLength = len(plugin.name);
                    }
                    if (len(plugin.currentVersion) > maxCurrentLength) {
                        maxCurrentLength = len(plugin.currentVersion);
                    }
                    if (len(plugin.latestVersion) > maxLatestLength) {
                        maxLatestLength = len(plugin.latestVersion);
                    }
                }

                maxNameLength += 2;
                maxCurrentLength += 2;
                maxLatestLength += 2;

                // Print table header
                print.boldText(padRight("Plugin", maxNameLength))
                     .boldText(padRight("Current", maxCurrentLength))
                     .boldLine(padRight("Latest", maxLatestLength));

                print.line(repeatString("-", maxNameLength + maxCurrentLength + maxLatestLength));

                // Display outdated plugins
                for (var plugin in outdatedPlugins) {
                    print.cyanText(padRight(plugin.name, maxNameLength))
                         .yellowText(padRight(plugin.currentVersion, maxCurrentLength))
                         .greenLine(padRight(plugin.latestVersion, maxLatestLength));
                }

                print.line()
                     .boldLine("-----------------------------------------------------------")
                     .line();

                if (arrayLen(checkErrors) > 0) {
                    print.yellowLine("Could not check #arrayLen(checkErrors)# plugin#arrayLen(checkErrors) != 1 ? 's' : ''#:")
                         .line();
                    for (var errorPlugin in checkErrors) {
                        print.yellowLine("  - #errorPlugin#");
                    }
                    print.line();
                }

                // Show update commands
                print.boldLine("Commands:")
                     .line();

                if (arrayLen(outdatedPlugins) == 1) {
                    print.cyanLine("  wheels plugin update #outdatedPlugins[1].name#");
                } else {
                    print.line("Update all outdated plugins:")
                         .cyanLine("  wheels plugin update:all")
                         .line()
                         .line("Update specific plugin:")
                         .cyanLine("  wheels plugin update <plugin-name>");
                }
            }
            
        } catch (any e) {
            error("Error checking for outdated plugins: #e.message#");
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