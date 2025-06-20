/**
 * Generate a controller in /controllers/NAME.cfc
 * 
 * Examples:
 * wheels generate controller Users
 * wheels generate controller Users --rest
 * wheels generate controller Users --actions=index,show,custom
 * wheels generate controller Api/V1/Users --api
 */
component aliases="wheels g controller" extends="../base" {
    
    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @name.hint Name of the controller to create (usually plural)
     * @actions.hint Actions to generate (comma-delimited, default: CRUD for REST)
     * @rest.hint Generate RESTful controller with CRUD actions
     * @api.hint Generate API controller (no view-related actions)
     * @description.hint Controller description
     * @force.hint Overwrite existing files
     */
    function run(
        required string name,
        string actions = "",
        boolean rest = false,
        boolean api = false,
        string description = "",
        boolean force = false
    ) {
        // Handle API flag implies REST
        if (arguments.api) {
            arguments.rest = true;
        }
        
        // Validate controller name
        var validation = codeGenerationService.validateName(listLast(arguments.name, "/"), "controller");
        if (!validation.valid) {
            error("Invalid controller name: " & arrayToList(validation.errors, ", "));
            return;
        }
        
        detailOutput.header("🎮", "Generating controller: #arguments.name#");
        
        // Parse actions
        var actionList = [];
        if (len(arguments.actions)) {
            actionList = listToArray(arguments.actions);
        } else if (arguments.rest) {
            if (arguments.api) {
                actionList = ["index", "show", "create", "update", "delete"];
            } else {
                actionList = ["index", "show", "new", "create", "edit", "update", "delete"];
            }
        } else {
            actionList = ["index"];
        }
        
        // Generate controller
        var result = codeGenerationService.generateController(
            name = arguments.name,
            description = arguments.description,
            rest = arguments.rest,
            api = arguments.api,
            force = arguments.force,
            actions = actionList,
            baseDirectory = getCWD()
        );
        
        if (result.success) {
            detailOutput.create(result.path);
            
            // Initialize viewsCreated outside the conditional block
            var viewsCreated = 0;
            
            // Generate views for non-API controllers
            if (!arguments.api && arguments.rest) {
                detailOutput.invoke("views");
                
                var viewActions = ["index", "show", "new", "edit"];
                
                for (var action in viewActions) {
                    if (arrayFindNoCase(actionList, action)) {
                        var viewResult = codeGenerationService.generateView(
                            name = arguments.name,
                            action = action,
                            force = arguments.force,
                            baseDirectory = getCWD()
                        );
                        
                        if (viewResult.success) {
                            detailOutput.create(viewResult.path, true);
                            viewsCreated++;
                        }
                    }
                }
            }
            
            // Show next steps
            var nextSteps = [
                "Review the generated controller at #result.path#",
                "Implement action logic for #arrayToList(actionList, ', ')#"
            ];
            
            if (arguments.rest) {
                arrayAppend(nextSteps, "Add route to config/routes.cfm: resources('" & lCase(arguments.name) & "');");
            } else {
                arrayAppend(nextSteps, "Add routes to config/routes.cfm");
            }
            
            if (!arguments.api && viewsCreated > 0) {
                arrayAppend(nextSteps, "Customize the views as needed");
            }
            
            detailOutput.success("Controller generation complete!");
            detailOutput.nextSteps(nextSteps);
        } else {
            detailOutput.error("Failed to generate controller: #result.error#");
            setExitCode(1);
        }
    }
}
