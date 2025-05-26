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
        
        print.yellowLine("🎮 Generating controller: #arguments.name#")
             .line();
        
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
            force = arguments.force,
            actions = actionList,
            baseDirectory = getCWD()
        );
        
        if (result.success) {
            print.greenLine("✅ Created controller: #result.path#");
            
            // Generate views for non-API controllers
            if (!arguments.api && arguments.rest) {
                print.line()
                     .yellowLine("📄 Creating views...");
                
                var viewActions = ["index", "show", "new", "edit"];
                var viewsCreated = 0;
                
                for (var action in viewActions) {
                    if (arrayFindNoCase(actionList, action)) {
                        var viewResult = codeGenerationService.generateView(
                            name = arguments.name,
                            action = action,
                            force = arguments.force,
                            baseDirectory = getCWD()
                        );
                        
                        if (viewResult.success) {
                            viewsCreated++;
                        }
                    }
                }
                
                if (viewsCreated > 0) {
                    print.greenLine("✅ Created #viewsCreated# view files");
                }
            }
            
            // Show next steps
            print.line()
                 .yellowLine("📋 Next steps:")
                 .line("1. Review the generated controller")
                 .line("2. Implement action logic");
            
            if (arguments.rest) {
                print.line("3. Add route resources to config/routes.cfm:")
                     .line("   resources('" & lCase(arguments.name) & "');");
            } else {
                print.line("3. Add routes to config/routes.cfm");
            }
            
            if (!arguments.api) {
                print.line("4. Customize the views as needed");
            }
        } else {
            print.redLine("❌ Failed to generate controller: #result.error#");
            setExitCode(1);
        }
    }
}
