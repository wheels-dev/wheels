/**
 * List installed Wheels plugins
 * Examples:
 * wheels plugins list
 * wheels plugins list --format=json
 * wheels plugins list --available
 */
component aliases="wheels plugin list" extends="../base" {
    property name="forgebox" inject="ForgeBox";
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
            detailOutput.output("Searching, please wait...");
            detailOutput.line();

            // Get list of all cfwheels plugins slugs
            var forgeboxResult = command('forgebox show')
                .params(type='cfwheels-plugins')
                .run(returnOutput=true);

            var results = [];

            if (len(forgeboxResult)) {
                var lines = listToArray(forgeboxResult, chr(10) & chr(13));

                for (var i = 1; i <= arrayLen(lines); i++) {
                    var line = trim(lines[i]);

                    // Check if this is a slug line: Slug: "slug-name"
                    if (findNoCase('Slug:', line)) {
                        // Extract slug from quotes
                        var slugMatch = reFind('Slug:\s*"([^"]+)"', line, 1, true);
                        if (slugMatch.pos[1] > 0) {
                            var slug = mid(line, slugMatch.pos[2], slugMatch.len[2]);

                            try {
                                var pluginInfo = forgebox.getEntry(slug);

                                if (isStruct(pluginInfo) && structKeyExists(pluginInfo, "slug")) {
                                    // Extract version from latestVersion structure
                                    var version = "N/A";
                                    if (structKeyExists(pluginInfo, "latestVersion") &&
                                        isStruct(pluginInfo.latestVersion) &&
                                        structKeyExists(pluginInfo.latestVersion, "version")) {
                                        version = pluginInfo.latestVersion.version;
                                    }

                                    // Extract author from user structure
                                    var author = "Unknown";
                                    if (structKeyExists(pluginInfo, "user") &&
                                        isStruct(pluginInfo.user) &&
                                        structKeyExists(pluginInfo.user, "username")) {
                                        author = pluginInfo.user.username;
                                    }

                                    arrayAppend(results, {
                                        name: pluginInfo.title ?: slug,
                                        slug: slug,
                                        version: version,
                                        description: pluginInfo.summary ?: pluginInfo.description ?: "",
                                        author: author,
                                        downloads: pluginInfo.hits ?: 0,
                                        updateDate: pluginInfo.updatedDate ?: ""
                                    });
                                }
                            } catch (any e) {
                                // Skip plugins that can't be retrieved
                            }
                        }
                    }
                }
            }

            results.sort(function(a, b) {
                return compareNoCase(a.name, b.name);
            });

            if (arguments.format == "json") {
                var jsonOutput = {
                    "plugins": results,
                    "count": arrayLen(results)
                };
                print.line(jsonOutput).toConsole();
            } else {
                detailOutput.subHeader("Found #arrayLen(results)# plugin(s)");
                detailOutput.line();

                // Create table for results
                var rows = [];

                for (var plugin in results) {
                    // use ordered struct so JSON keeps key order
                    var row = structNew("ordered");

                    row["Name"]        = plugin.name;
                    row["Slug"]        = plugin.slug;
                    row["Version"]     = plugin.version;
                    row["Downloads"]   = numberFormat(plugin.downloads ?: 0);
                    row["Description"] = plugin.description ?: "No description";

                    // Truncate long descriptions
                    if (len(row["Description"]) > 50) {
                        row["Description"] = left(row["Description"], 47) & "...";
                    }

                    arrayAppend(rows, row);
                }

                // Display the table
                detailOutput.getPrint().table(rows).toConsole();
                
                detailOutput.line();
                detailOutput.divider();
                detailOutput.line();

                // Show summary
                detailOutput.metric("Total plugins found", "#arrayLen(results)#");
                detailOutput.line();

                // Show commands
                detailOutput.subHeader("Commands");
                detailOutput.output("- Install: wheels plugin install <name>", true);
                detailOutput.output("- Details: wheels plugin info <name>", true);
                detailOutput.output("- Add --format=json for JSON output", true);
                detailOutput.line();
            }
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
            print.line(jsonOutput).toConsole();
        } else {
            // Table format output
            detailOutput.header("Installed Wheels Plugins (#arrayLen(plugins)#)");

            // Create table rows
            var rows = [];
            for (var plugin in plugins) {
                var row = {
                    "Plugin Name": plugin.name,
                    "Slug"        :plugin.slug,
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
            detailOutput.getPrint().table(rows);
            
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