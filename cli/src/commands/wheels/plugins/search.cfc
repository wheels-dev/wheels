/**
 * Search for Wheels plugins on ForgeBox
 * Examples:
 * wheels plugin search
 * wheels plugin search auth
 * wheels plugin search --format=json
 */
component aliases="wheels plugin search" extends="../base" {

    property name="forgebox" inject="ForgeBox";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @query.hint Search term to filter plugins
     * @format.hint Output format: table (default) or json
     * @format.options table,json
     * @orderBy.hint Sort results by: name, downloads, updated
     * @orderBy.options name,downloads,updated
     */
    function run(
        string query = "",
        string format = "table",
        string orderBy = "downloads"
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                format=["table", "json"],
                orderBy=["name", "downloads", "updated"]
            }
        );

        detailOutput.header("Searching ForgeBox for Wheels Plugins");
        detailOutput.line();

        if (len(arguments.query)) {
            detailOutput.metric("Search term", arguments.query);
            detailOutput.line();
        }

        try {
            detailOutput.output("Searching, please wait...");
            detailOutput.line();

            // Use forgebox show command to get all cfwheels-plugins
            var forgeboxResult = command('forgebox show')
                .params(type='cfwheels-plugins')
                .run(returnOutput=true);

            var results = [];

            // Parse the output - ForgeBox returns formatted output like:
            // PluginName    ( Author )
            // Type: CFWheels Plugins
            // Slug: "slug-name"
            // Description text
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

                            // If we have a query, filter by slug
                            if (len(arguments.query) == 0 || findNoCase(arguments.query, slug)) {
                                // Get detailed info from ForgeBox
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
            }

            detailOutput.line();

            if (!arrayLen(results)) {
                detailOutput.statusWarning("No plugins found" & (len(arguments.query) ? " matching '#arguments.query#'" : ""));
                detailOutput.line();
                detailOutput.subHeader("Try");
                detailOutput.output("- wheels plugin search <different-keyword>", true);
                detailOutput.output("- wheels plugin list --available", true);
                return;
            }

            // Sort results
            if (arguments.orderBy == "downloads") {
                results.sort(function(a, b) {
                    return b.downloads - a.downloads;
                });
            } else if (arguments.orderBy == "updated") {
                results.sort(function(a, b) {
                    return dateCompare(b.updateDate ?: "1900-01-01", a.updateDate ?: "1900-01-01");
                });
            } else {
                results.sort(function(a, b) {
                    return compareNoCase(a.name, b.name);
                });
            }

            if (arguments.format == "json") {
                var jsonOutput = {
                    "plugins": results,
                    "count": arrayLen(results),
                    "query": arguments.query
                };
                print.line(serializeJSON(jsonOutput, true));
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
                detailOutput.metric("Sort order", arguments.orderBy);
                if (arguments.orderBy == "downloads" && arrayLen(results) > 0) {
                    detailOutput.metric("Most popular", "#results[1].name# (#numberFormat(results[1].downloads)# downloads)");
                }
                detailOutput.line();

                // Show commands
                detailOutput.subHeader("Commands");
                detailOutput.output("- Install: wheels plugin install <name>", true);
                detailOutput.output("- Details: wheels plugin info <name>", true);
                detailOutput.output("- List installed: wheels plugin list", true);
                detailOutput.line();
                
                // Add tip about JSON format
                detailOutput.statusInfo("Tip");
                detailOutput.output("Add --format=json for JSON output", true);
                detailOutput.output("Sort with --orderBy=name,downloads,updated", true);
                detailOutput.line();
            }

        } catch (any e) {
            detailOutput.error("Error searching for plugins: #e.message#");
            setExitCode(1);
        }
    }
}