/**
 * Create view files
 */
component extends="../base" {
    
    property name="snippetService" inject="SnippetService@wheelscli";
    
    /**
     * Create view files for a controller action
     * 
     * @name Controller name (e.g., Users, Posts)
     * @action Action name or comma-delimited list (e.g., index, show, edit)
     * @model Model name (defaults to singular of controller)
     * @partial Generate a partial view (prefixed with _)
     * @layout Generate a layout file
     * @template View snippet style (default, bootstrap5, tailwind)
     * @force Overwrite existing files
     * @help Generate view files for controller actions
     * 
     * Examples:
     * wheels create view Users index
     * wheels create view Posts index,show,new,edit
     * wheels create view Shared _navigation --partial
     * wheels create view Layout admin --layout
     */
    function run(
        required string name,
        string action = "index",
        string model = "",
        boolean partial = false,
        boolean layout = false,
        string template = "default",
        boolean force = false
    ) {
        ensureWheelsProject();
        
        print.line();
        
        if (arguments.layout) {
            createLayoutFile(arguments.name, arguments.force);
            return;
        }
        
        if (arguments.partial) {
            createPartialFile(arguments.name, arguments.action, arguments.force);
            return;
        }
        
        print.boldBlueLine("Creating view(s) for controller: #arguments.name#");
        
        // Determine model name
        if (!len(arguments.model)) {
            var baseName = listLast(arguments.name, "/");
            arguments.model = singularize(baseName);
        }
        
        // Parse actions
        var actions = listToArray(arguments.action);
        
        // Create views for each action
        for (var actionName in actions) {
            createViewFile(
                arguments.name,
                actionName,
                arguments.model,
                arguments.template,
                arguments.force
            );
        }
        
        print.line();
        print.boldLine("Next steps:");
        print.indentedLine("1. Customize the generated view files");
        print.indentedLine("2. Add any necessary CSS/JavaScript");
        
        if (arguments.template == "default") {
            print.indentedLine("3. Consider using a CSS framework:");
            print.indentedLine("   wheels create view #arguments.name# #arguments.action# --template=bootstrap5");
        }
    }
    
    /**
     * Create a view file
     */
    private function createViewFile(
        required string controller,
        required string action,
        required string model,
        required string snippet,
        boolean force = false
    ) {
        var viewsPath = getAppPath("views");
        var viewDir = viewsPath & lCase(arguments.controller);
        
        // Handle namespaced controllers
        if (find("/", arguments.controller)) {
            viewDir = viewsPath & lCase(replace(arguments.controller, "/", "/", "all"));
        }
        
        // Ensure view directory exists
        if (!directoryExists(viewDir)) {
            directoryCreate(viewDir, true);
        }
        
        var viewFile = viewDir & "/" & arguments.action & ".cfm";
        
        if (fileExists(viewFile) && !arguments.force) {
            if (!confirm("View '#arguments.controller#/#arguments.action#' already exists. Overwrite?")) {
                print.yellowLine("Skipping: #arguments.action#.cfm");
                return;
            }
        }
        
        // Generate view content
        var viewContent = generateViewContent(
            arguments.controller,
            arguments.action,
            arguments.model,
            arguments.template
        );
        
        fileWrite(viewFile, viewContent);
        print.greenLine("✓ Created view: app/views/#lCase(arguments.controller)#/#arguments.action#.cfm");
    }
    
    /**
     * Create a partial file
     */
    private function createPartialFile(
        required string name,
        required string partial,
        boolean force = false
    ) {
        print.boldBlueLine("Creating partial: _#arguments.partial#");
        
        var viewsPath = getAppPath("views");
        var partialDir = viewsPath & lCase(arguments.name);
        
        if (!directoryExists(partialDir)) {
            directoryCreate(partialDir, true);
        }
        
        // Ensure partial name starts with underscore
        var partialName = arguments.partial;
        if (left(partialName, 1) != "_") {
            partialName = "_" & partialName;
        }
        
        var partialFile = partialDir & "/" & partialName & ".cfm";
        
        if (fileExists(partialFile) && !arguments.force) {
            if (!confirm("Partial '#arguments.name#/#partialName#' already exists. Overwrite?")) {
                print.yellowLine("Partial creation cancelled.");
                return;
            }
        }
        
        var partialContent = snippetService.getSnippet("view", "_partial.cfm");
        partialContent = snippetService.render(partialContent, {
            PARTIAL_NAME = partialName,
            PARTIAL_CLASS = replace(partialName, "_", "", "one"),
            GENERATED_DATE = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
        });
        
        fileWrite(partialFile, partialContent);
        print.greenLine("✓ Created partial: app/views/#lCase(arguments.name)#/#partialName#.cfm");
        
        print.line();
        print.yellowLine("Usage in views:");
        print.indentedLine("##includePartial(""#partialName#"")##");
        print.indentedLine("##includePartial(partial=""#partialName#"", someVariable=""value"")##");
    }
    
    /**
     * Create a layout file
     */
    private function createLayoutFile(
        required string name,
        boolean force = false
    ) {
        print.boldBlueLine("Creating layout: #arguments.name#");
        
        var layoutPath = getAppPath("views") & "layout/";
        
        if (!directoryExists(layoutPath)) {
            directoryCreate(layoutPath, true);
        }
        
        var layoutFile = layoutPath & arguments.name & ".cfm";
        
        if (fileExists(layoutFile) && !arguments.force) {
            if (!confirm("Layout '#arguments.name#' already exists. Overwrite?")) {
                print.yellowLine("Layout creation cancelled.");
                return;
            }
        }
        
        var layoutContent = snippetService.getSnippet("layout", "custom.cfm");
        layoutContent = snippetService.render(layoutContent, {
            CURRENT_YEAR = year(now())
        });
        
        fileWrite(layoutFile, layoutContent);
        print.greenLine("✓ Created layout: app/views/layout/#arguments.name#.cfm");
        
        print.line();
        print.yellowLine("To use this layout in a controller:");
        print.indentedLine("usesLayout(""#arguments.name#"");");
    }
    
    /**
     * Generate view content based on action and snippet
     */
    private function generateViewContent(
        required string controller,
        required string action,
        required string model,
        required string snippet
    ) {
        var content = "";
        var modelLower = lCase(arguments.model);
        var modelsLower = lCase(pluralize(arguments.model));
        
        // Generate content based on action
        switch(arguments.action) {
            case "index":
                content = generateIndexView(arguments.controller, arguments.model, arguments.snippet);
                break;
                
            case "show":
                content = generateShowView(arguments.controller, arguments.model, arguments.snippet);
                break;
                
            case "new":
                content = generateNewView(arguments.controller, arguments.model, arguments.snippet);
                break;
                
            case "edit":
                content = generateEditView(arguments.controller, arguments.model, arguments.snippet);
                break;
                
            default:
                content = generateDefaultView(arguments.controller, arguments.action, arguments.model);
        }
        
        return content;
    }
    
    /**
     * Generate index view
     */
    private function generateIndexView(controller, model, snippet) {
        var content = snippetService.getSnippet("view", "index.cfm");
        return snippetService.render(content, {
            MODEL = model,
            MODEL_PLURAL = pluralize(model),
            MODEL_LOWER = lCase(model),
            MODELS_LOWER = lCase(pluralize(model))
        });
    }
    
    /**
     * Generate show view
     */
    private function generateShowView(controller, model, snippet) {
        var content = snippetService.getSnippet("view", "show.cfm");
        return snippetService.render(content, {
            MODEL = model,
            MODEL_LOWER = lCase(model),
            MODELS_LOWER = lCase(pluralize(model))
        });
    }
    
    /**
     * Generate new view
     */
    private function generateNewView(controller, model, snippet) {
        var content = snippetService.getSnippet("view", "new.cfm");
        return snippetService.render(content, {
            MODEL = model,
            MODELS_LOWER = lCase(pluralize(model))
        });
    }
    
    /**
     * Generate edit view
     */
    private function generateEditView(controller, model, snippet) {
        var content = snippetService.getSnippet("view", "edit.cfm");
        return snippetService.render(content, {
            MODEL = model,
            MODEL_LOWER = lCase(model)
        });
    }
    
    /**
     * Generate default view
     */
    private function generateDefaultView(controller, action, model) {
        var content = snippetService.getSnippet("view", "default.cfm");
        return snippetService.render(content, {
            ACTION = action,
            CONTROLLER = controller
        });
    }
}