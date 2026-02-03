/**
 * List outdated Wheels plugins that have newer versions available
 * Examples:
 * wheels plugin outdated
 * wheels plugin outdated --format=json
 */
component aliases="wheels plugin outdated,wheels plugins outdated" extends="../base" {
    
    property name="pluginService" inject="PluginService@wheels-cli";
    property name="forgebox" inject="ForgeBox";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @format.hint Output format: table (default) or json
     * @format.options table,json
     */
    function run(
        string format = "table"
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                format=["table", "json"]
            }
        );
        try {
            detailOutput.header("Checking for Plugin Updates");
            detailOutput.line();

            // Get list of installed plugins from /plugins folder
            var plugins = pluginService.list();

            if (arrayLen(plugins) == 0) {
                detailOutput.statusWarning("No plugins installed in /plugins folder");
                detailOutput.line();
                detailOutput.subHeader("Install plugins with");
                detailOutput.output("- wheels plugin install <plugin-name>", true);
                return;
            }

            var outdatedPlugins = [];
            var checkErrors = [];

            detailOutput.output("Checking #arrayLen(plugins)# installed plugin(s)...");
            detailOutput.line();

            // Check each plugin
            for (var plugin in plugins) {
                try {
                    var pluginSlug = plugin.slug ?: plugin.name;
                    var displayName = plugin.name;

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
                        arrayAppend(outdatedPlugins, {
                            name: plugin.name,
                            slug: pluginSlug,
                            currentVersion: currentVersion,
                            latestVersion: latestVersion
                        });
                        detailOutput.update(displayName, true);
                    } else {
                        detailOutput.identical("#displayName#:v#currentVersion# (up to date)", true);
                    }

                } catch (any e) {
                    detailOutput.conflict(displayName, true);
                    arrayAppend(checkErrors, plugin.name);
                }
            }

            detailOutput.line();
            detailOutput.divider("=", 60);
            detailOutput.line();

            // Handle no outdated plugins
            if (arrayLen(outdatedPlugins) == 0) {
                detailOutput.statusSuccess("All plugins are up to date!");
                detailOutput.line();

                if (arrayLen(checkErrors) > 0) {
                    detailOutput.statusWarning("Could not check #arrayLen(checkErrors)# plugin(s)");
                    for (var errorPlugin in checkErrors) {
                        detailOutput.output("- #errorPlugin#: ", true);
                    }
                    detailOutput.line();
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
                detailOutput.subHeader("Found #arrayLen(outdatedPlugins)# outdated plugin(s)");
                detailOutput.line();

                // Create table for outdated plugins
                var rows = [];
                for (var plugin in outdatedPlugins) {
                    arrayAppend(rows, {
                        "Plugin": plugin.name,
                        "Current": plugin.currentVersion,
                        "Latest": plugin.latestVersion
                    });
                }

                // Display the table
                print.table(rows).toConsole();
                
                detailOutput.line();
                detailOutput.divider("-", 60);
                detailOutput.line();

                if (arrayLen(checkErrors) > 0) {
                    detailOutput.statusWarning("Could not check #arrayLen(checkErrors)# plugin(s)");
                    for (var errorPlugin in checkErrors) {
                        detailOutput.output("- #errorPlugin#", true);
                    }
                    detailOutput.line();
                }

                // Show summary
                detailOutput.metric("Total plugins checked", "#arrayLen(plugins)#");
                detailOutput.metric("Outdated plugins", "#arrayLen(outdatedPlugins)#");
                detailOutput.metric("Up to date", "#arrayLen(plugins) - arrayLen(outdatedPlugins)#");
                detailOutput.line();

                // Show update commands
                detailOutput.subHeader("Update Commands");

                if (arrayLen(outdatedPlugins) == 1) {
                    detailOutput.output("- Update this plugin:", true);
                    detailOutput.output("  wheels plugin update #outdatedPlugins[1].name#", true);
                } else {
                    detailOutput.output("- Update all outdated plugins:", true);
                    detailOutput.output("  wheels plugin update:all", true);
                    detailOutput.output("- Update specific plugin:", true);
                    detailOutput.output("  wheels plugin update <plugin-name>", true);
                }
                
                detailOutput.line();
                
                // Add helpful tip
                detailOutput.statusInfo("Tip");
                detailOutput.output("Add --format=json for JSON output", true);
                detailOutput.line();
            }
            
        } catch (any e) {
            detailOutput.error("Error checking for outdated plugins: #e.message#");
            return;
        }
    }
}