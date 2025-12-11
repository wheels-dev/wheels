/**
 * Generate a controller in /controllers/NAME.cfc
 *
 * Examples:
 * wheels generate controller Users
 * wheels generate controller Users --crud
 * wheels generate controller Users --actions=index,show,custom
 * wheels generate controller Users --api
 * wheels generate controller Users --crud --actions=dashboard
 * wheels generate controller Users --actions=dashboard --noViews
 */
component aliases="wheels g controller" extends="../base" {

    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @name.hint Name of the controller to create (usually plural)
     * @actions.hint Actions to generate (comma-delimited) - HIGHEST PRIORITY, overrides --crud
     * @crud.hint Generate CRUD controller with actions (index, show, new, create, edit, update, delete) and views (like scaffold)
     * @api.hint Generate API controller (no views generated, only JSON/XML endpoints)
     * @noViews.hint Skip view generation (only generate controller)
     * @description.hint Controller description
     * @force.hint Overwrite existing files
     */
    function run(
        required string name,
        string actions = "index",
        boolean crud = false,
        boolean api = false,
        boolean noViews = false,
        string description = "",
        boolean force = false
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(argStruct=arguments);

        // Handle API flag implies CRUD and no views
        if (arguments.api) {
            arguments.crud = true;
            arguments.noViews = true;
        }
        
        // Validate controller name
        var validation = codeGenerationService.validateName(listLast(arguments.name, "/"), "controller");
        if (!validation.valid) {
            detailOutput.error("Invalid controller name: " & arrayToList(validation.errors, ", "));
            return;
        }
        
        detailOutput.header("Generating controller: #arguments.name#");
        
        // Parse actions - PRIORITY: --actions > --crud > --api > default
        var actionList = [];
        var hasCustomActions = (arguments.actions != "index"); // Check if user provided custom actions

        if (hasCustomActions) {
            // HIGHEST PRIORITY: Custom actions specified
            actionList = listToArray(arguments.actions);
        } else if (arguments.crud) {
            if (arguments.api) {
                // API: No form actions (new, edit)
                actionList = ["index", "show", "create", "update", "delete"];
            } else {
                // CRUD: All CRUD actions with forms
                actionList = ["index", "show", "new", "create", "edit", "update", "delete"];
            }
        } else {
            // Default: Only index
            actionList = ["index"];
        }

        // Generate controller
        var result = codeGenerationService.generateController(
            name = arguments.name,
            description = arguments.description,
            crud = arguments.crud,
            api = arguments.api,
            force = arguments.force,
            actions = actionList,
            baseDirectory = getCWD()
        );

        if (result.success) {
            detailOutput.create(result.path);

            // Initialize viewsCreated outside the conditional block
            var viewsCreated = 0;

            // Generate views (unless --api or --noViews is specified)
            if (!arguments.api && !arguments.noViews) {
                detailOutput.invoke("views");

                // Determine which views to generate based on priority
                var viewActions = [];

                if (hasCustomActions) {
                    // HIGHEST PRIORITY: Custom actions specified - generate views for those actions only
                    viewActions = actionList;
                } else if (arguments.crud) {
                    // CRUD: Generate scaffold-style views (index, show, new, edit, _form)
                    viewActions = ["index", "show", "new", "edit", "_form"];
                } else {
                    // Default: Generate views for actions in the action list
                    viewActions = actionList;
                }

                // Generate views for determined actions
                for (var action in viewActions) {
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

            // Show next steps
            var nextSteps = [
                "Review the generated controller at #result.path#",
                "Implement action logic for #arrayToList(actionList, ', ')#"
            ];

            if (arguments.crud) {
                arrayAppend(nextSteps, "Add route to config/routes.cfm: .resources('" & lCase(arguments.name) & "')");
            } else {
                arrayAppend(nextSteps, "Add routes to config/routes.cfm for each action");
            }

            if (viewsCreated > 0) {
                arrayAppend(nextSteps, "Customize the #viewsCreated# generated view" & (viewsCreated > 1 ? "s" : "") & " as needed");
            }
            
            detailOutput.success("Controller generation complete!");
            detailOutput.nextSteps(nextSteps);
        } else {
            detailOutput.error("Failed to generate controller: #result.error#");
            setExitCode(1);
        }
    }
}
