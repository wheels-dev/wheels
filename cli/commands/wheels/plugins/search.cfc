/**
 * Search for Wheels plugins on ForgeBox
 * Examples:
 * wheels plugin search
 * wheels plugin search auth
 * wheels plugin search --format=json
 */
component aliases="wheels plugin search" extends="../base" {
    
    property name="pluginService" inject="PluginService@wheels-cli";
    property name="forgebox" inject="ForgeBox@commandbox-core";
    
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
        print.greenBoldLine("🔍 Searching ForgeBox for Wheels plugins...")
             .line();
        
        try {
            // Search ForgeBox for wheels plugins
            var searchParams = {
                type: "cfwheels-plugins",
                max: 50
            };
            
            if (len(arguments.query)) {
                searchParams.searchTerm = arguments.query;
            }
            
            // Get results from ForgeBox API
            var results = forgebox.search(argumentCollection=searchParams);
            
            if (!arrayLen(results)) {
                print.yellowLine("No plugins found matching '#arguments.query#'");
                print.line("Try searching with different keywords or browse all plugins:");
                print.line("  wheels plugin search");
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
                print.line(serializeJSON(results, true));
            } else {
                // Display results in table format
                print.table(
                    data = results.map(function(plugin) {
                        return {
                            "Name": plugin.slug ?: plugin.name,
                            "Version": plugin.version ?: "N/A",
                            "Downloads": numberFormat(plugin.downloads ?: 0),
                            "Updated": plugin.updateDate ? dateFormat(plugin.updateDate, "yyyy-mm-dd") : "N/A",
                            "Description": left(plugin.summary ?: "No description", 50) & (len(plugin.summary ?: "") > 50 ? "..." : "")
                        };
                    }),
                    headers = ["Name", "Version", "Downloads", "Updated", "Description"]
                );
                
                print.line()
                     .yellowLine("Found #arrayLen(results)# plugin#arrayLen(results) != 1 ? 's' : ''#")
                     .line()
                     .line("To install a plugin, use:")
                     .line("  wheels plugin install <plugin-name>");
            }
            
        } catch (any e) {
            error("Error searching for plugins: #e.message#");
        }
    }
}