/**
 * Search for Wheels plugins on ForgeBox
 * Examples:
 * wheels plugin search
 * wheels plugin search auth
 * wheels plugin search --format=json
 */
component aliases="wheels plugin search" extends="../base" {

    property name="forgebox" inject="ForgeBox";

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

        print.line()
             .boldCyanLine("===========================================================")
             .boldCyanLine("  Searching ForgeBox for Wheels Plugins")
             .boldCyanLine("===========================================================")
             .line();

        if (len(arguments.query)) {
            print.line("Search term: #arguments.query#")
                 .line();
        }

        // try {
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

            if (!arrayLen(results)) {
                print.yellowLine("No plugins found" & (len(arguments.query) ? " matching '#arguments.query#'" : ""))
                     .line()
                     .line("Try:")
                     .cyanLine("  wheels plugin search <different-keyword>")
                     .cyanLine("  wheels plugin list --available");
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
                print.boldLine("Found #arrayLen(results)# plugin#arrayLen(results) != 1 ? 's' : ''#:")
                     .line();

                // Calculate column widths
                var maxNameLength = 20;
                var maxVersionLength = 10;
                var maxDownloadsLength = 10;
                var maxDescLength = 40;

                for (var plugin in results) {
                    if (len(plugin.slug) > maxNameLength) {
                        maxNameLength = len(plugin.slug);
                    }
                    if (len(plugin.version) > maxVersionLength) {
                        maxVersionLength = len(plugin.version);
                    }
                    var dlStr = numberFormat(plugin.downloads ?: 0);
                    if (len(dlStr) > maxDownloadsLength) {
                        maxDownloadsLength = len(dlStr);
                    }
                }

                maxNameLength += 2;
                maxVersionLength += 2;
                maxDownloadsLength += 2;

                // Print table header
                print.boldText(padRight("Name", maxNameLength))
                     .boldText(padRight("Version", maxVersionLength))
                     .boldText(padRight("Downloads", maxDownloadsLength))
                     .boldLine("Description");

                print.line(repeatString("-", maxNameLength + maxVersionLength + maxDownloadsLength + maxDescLength));

                // Display results
                for (var plugin in results) {
                    var desc = plugin.description ?: "No description";
                    if (len(desc) > maxDescLength) {
                        desc = left(desc, maxDescLength - 3) & "...";
                    }

                    print.cyanText(padRight(plugin.slug, maxNameLength))
                         .greenText(padRight(plugin.version, maxVersionLength))
                         .yellowText(padRight(numberFormat(plugin.downloads ?: 0), maxDownloadsLength))
                         .line(desc);
                }

                print.line()
                     .boldLine("-----------------------------------------------------------")
                     .line()
                     .boldLine("Commands:")
                     .cyanLine("  wheels plugin install <name>    Install a plugin")
                     .cyanLine("  wheels plugin info <name>       View plugin details");
            }

        // } catch (any e) {
        //     print.line()
        //          .boldRedText("[ERROR] ")
        //          .redLine("Error searching for plugins")
        //          .line()
        //          .yellowLine("Error: #e.message#");
        //     setExitCode(1);
        // }
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