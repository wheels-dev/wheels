/**
 * Create a new Wheels controller
 */
component extends="../base" {
    
    /**
     * Create a new Wheels controller
     * 
     * @name Name of the controller (typically plural, e.g., Users, Posts)
     * @actions Comma-delimited list of actions to generate
     * @model Associated model name (defaults to singular of controller name)
     * @resource Generate RESTful resource controller with standard CRUD actions
     * @api Generate API controller without view rendering
     * @views Generate view files for each action
     * @template Controller snippet to use (Controller, ResourceController, ApiController)
     * @force Overwrite existing files
     * @help Generate a controller file with optional views
     * 
     * Examples:
     * wheels create controller Users
     * wheels create controller Posts --resource --views
     * wheels create controller API/Users --api
     * wheels create controller Products index,show,search --views
     */
    function run(
        required string name,
        string actions = "",
        string model = "",
        boolean resource = false,
        boolean api = false,
        boolean views = true,
        string template = "",
        boolean force = false
    ) {
        ensureWheelsProject();
        
        // Validate controller name
        if (!reFind("^[A-Z/][a-zA-Z0-9/]*$", arguments.name)) {
            error("Invalid controller name. Controller names must start with a capital letter and contain only letters, numbers, and forward slashes for namespacing.");
        }
        
        print.line();
        print.boldBlueLine("Creating controller: #arguments.name#");
        
        // Determine model name
        if (!len(arguments.model)) {
            // Extract base name without namespace
            var baseName = listLast(arguments.name, "/");
            arguments.model = singularize(baseName);
        }
        
        // Determine snippet
        if (!len(arguments.template)) {
            if (arguments.api) {
                arguments.template = "ApiController";
            } else if (arguments.resource) {
                arguments.template = "ResourceController";
            } else {
                arguments.template = "Controller";
            }
        }
        
        // Check snippet exists
        var snippetPath = "controller/#arguments.template#.cfc";
        if (!fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & "../../../snippets/" & snippetPath)) {
            error("Snippet not found: #arguments.template#");
        }
        
        var snippet = getSnippet("controller", arguments.template);
        
        // Check if using custom snippet
        if (isUsingCustomSnippet(snippetPath)) {
            print.yellowLine("Using custom controller snippet: #arguments.template#");
        }
        
        // Parse actions
        var actionList = [];
        if (arguments.resource) {
            actionList = ["index", "show", "new", "create", "edit", "update", "delete"];
        } else if (len(arguments.actions)) {
            actionList = listToArray(arguments.actions);
        } else if (!arguments.api) {
            actionList = ["index"];
        }
        
        // Generate controller file
        var controllerContent = renderControllerContent(
            arguments.name,
            arguments.model,
            actionList,
            snippet,
            arguments.api
        );
        
        // Create controller file
        var controllersPath = getAppPath("controllers");
        var controllerFile = controllersPath;
        
        // Handle namespaced controllers
        if (find("/", arguments.name)) {
            var namespace = getDirectoryFromPath(arguments.name);
            var fileName = getFileFromPath(arguments.name);
            
            controllerFile = controllersPath & namespace;
            if (!directoryExists(controllerFile)) {
                directoryCreate(controllerFile, true);
            }
            
            controllerFile &= fileName & ".cfc";
        } else {
            controllerFile &= arguments.name & ".cfc";
        }
        
        if (fileExists(controllerFile) && !arguments.force) {
            if (!confirm("Controller '#arguments.name#' already exists. Overwrite?")) {
                print.yellowLine("Controller creation cancelled.");
                return;
            }
        }
        
        fileWrite(controllerFile, controllerContent);
        print.greenLine("✓ Created controller: app/controllers/#replace(arguments.name, '/', '/', 'all')#.cfc");
        
        // Generate views if requested
        if (arguments.views && !arguments.api && arrayLen(actionList)) {
            print.line();
            print.yellowLine("Creating views...");
            
            for (var action in actionList) {
                // Skip actions that don't typically have views
                if (!listFindNoCase("create,update,delete", action)) {
                    command("wheels create view")
                        .params(
                            name = arguments.name,
                            action = action,
                            model = arguments.model,
                            force = arguments.force
                        )
                        .run();
                }
            }
        }
        
        // Add routes hint
        print.line();
        print.boldLine("Next steps:");
        print.indentedLine("1. Add routes to config/routes.cfm:");
        
        if (arguments.resource) {
            var routeName = lCase(listLast(arguments.name, "/"));
            print.indentedLine("   resources(""#routeName#"");");
        } else {
            print.indentedLine("   get(name=""#lCase(arguments.name)#"", pattern=""/#lCase(arguments.name)#"", to=""#arguments.name###index"");");
        }
        
        print.indentedLine("2. Implement your controller actions");
        
        if (!arguments.views && !arguments.api) {
            print.indentedLine("3. Create views with 'wheels create view #arguments.name# <action>'");
        }
    }
    
    /**
     * Generate controller content
     */
    private function renderControllerContent(
        required string name,
        required string model,
        required array actions,
        required string snippet,
        boolean api = false
    ) {
        var data = {
            controllerName = arguments.name,
            modelName = arguments.model,
            singularLowerName = lCase(arguments.model),
            pluralLowerName = lCase(pluralize(arguments.model)),
            pluralName = pluralize(arguments.model),
            actions = arguments.actions,
            timestamp = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            generatedBy = "Wheels CLI v3.0.0-beta.1"
        };
        
        return renderSnippet(arguments.snippet, data);
    }
}