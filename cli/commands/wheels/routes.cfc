/**
 * Display application routes
 */
component extends="base" {
    
    property name="wheelsService" inject="WheelsService@wheels-cli-next";
    
    /**
     * Display all configured routes for the application
     * 
     * @format.hint Output format
     * @format.optionsUDF completeFormatTypes
     * @filter.hint Filter routes by pattern or name
     * @verbose.hint Show additional route details
     * @verbose.options true,false
     * @help Display all application routes
     */
    function run(
        string format = "text",
        string filter = "",
        boolean verbose = false
    ) {
        return runCommand(function() {
            ensureWheelsProject();
            
            var result = {
                routes = [],
                totalRoutes = 0,
                filteredRoutes = 0
            };
            
            if (variables.commandMetadata.outputFormat == "text") {
                printHeader("Wheels Application Routes");
            }
            
            // Get routes from the application
            var routes = runWithSpinner("Loading routes", function() {
                // In a real implementation, this would load actual routes
                // For now, using sample data
                return getSampleRoutes();
            });
            
            result.totalRoutes = arrayLen(routes);
            
            // Filter routes if requested
            if (len(arguments.filter)) {
                routes = arrayFilter(routes, function(route) {
                    return findNoCase(filter, route.name) || 
                           findNoCase(filter, route.pattern) ||
                           findNoCase(filter, route.controller) ||
                           findNoCase(filter, route.action);
                });
            }
            
            result.filteredRoutes = arrayLen(routes);
            result.routes = routes;
            
            // Display based on format
            if (variables.commandMetadata.outputFormat == "text") {
                if (!arrayLen(routes)) {
                    printWarning("No routes found matching filter: #arguments.filter#");
                } else {
                    // Prepare table data
                    var tableData = [];
                    for (var route in routes) {
                        var routeData = {
                            name = route.name,
                            method = route.method,
                            pattern = route.pattern,
                            target = route.controller & "##" & route.action
                        };
                        
                        if (arguments.verbose) {
                            routeData.options = "";
                            if (structKeyExists(route, "constraints") && !structIsEmpty(route.constraints)) {
                                routeData.options &= "constraints ";
                            }
                            if (structKeyExists(route, "formats") && len(route.formats)) {
                                routeData.options &= "formats:" & route.formats;
                            }
                        }
                        
                        arrayAppend(tableData, routeData);
                    }
                    
                    // Display table
                    if (arguments.verbose) {
                        printTable(
                            data = tableData,
                            headers = ["Name", "Method", "Pattern", "Target", "Options"],
                            columns = ["name", "method", "pattern", "target", "options"]
                        );
                    } else {
                        printTable(
                            data = tableData,
                            headers = ["Name", "Method", "Pattern", "Target"],
                            columns = ["name", "method", "pattern", "target"]
                        );
                    }
                }
                
                // Summary
                print.line();
                printInfo("Total routes: #result.totalRoutes#");
                
                if (len(arguments.filter)) {
                    printInfo("Showing: #result.filteredRoutes# (filtered by '#arguments.filter#')");
                }
                
                // Tips
                if (arguments.verbose) {
                    print.line();
                    printSection("Route Details");
                    print.line("Constraints limit route parameters to specific patterns.");
                    print.line("Formats specify accepted response formats (html, json, xml, etc.).");
                }
            } else {
                output(result, arguments.format);
            }
        }, argumentCollection=arguments);
    }
    
    /**
     * Get sample routes for display
     */
    private function getSampleRoutes() {
        // In a real implementation, this would load actual routes from the application
        return [
            {
                name = "root",
                method = "GET",
                pattern = "/",
                controller = "main",
                action = "index"
            },
            {
                name = "users",
                method = "GET",
                pattern = "/users",
                controller = "users",
                action = "index"
            },
            {
                name = "user",
                method = "GET",
                pattern = "/users/:key",
                controller = "users",
                action = "show",
                constraints = {key = "[0-9]+"}
            },
            {
                name = "newUser",
                method = "GET",
                pattern = "/users/new",
                controller = "users",
                action = "new"
            },
            {
                name = "createUser",
                method = "POST",
                pattern = "/users",
                controller = "users",
                action = "create"
            },
            {
                name = "editUser",
                method = "GET",
                pattern = "/users/:key/edit",
                controller = "users",
                action = "edit",
                constraints = {key = "[0-9]+"}
            },
            {
                name = "updateUser",
                method = "PATCH",
                pattern = "/users/:key",
                controller = "users",
                action = "update",
                constraints = {key = "[0-9]+"},
                formats = "html,json"
            },
            {
                name = "deleteUser",
                method = "DELETE",
                pattern = "/users/:key",
                controller = "users",
                action = "delete",
                constraints = {key = "[0-9]+"},
                formats = "html,json"
            },
            {
                name = "api.v1.posts",
                method = "GET",
                pattern = "/api/v1/posts",
                controller = "api.v1.posts",
                action = "index",
                formats = "json"
            },
            {
                name = "api.v1.post",
                method = "GET",
                pattern = "/api/v1/posts/:id",
                controller = "api.v1.posts",
                action = "show",
                constraints = {id = "[0-9]+"},
                formats = "json"
            }
        ];
    }
}