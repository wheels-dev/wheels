/**
 * Create view files
 */
component extends="commands.wheels.BaseCommand" {
    
    /**
     * Create view files for a controller action
     * 
     * @name Controller name (e.g., Users, Posts)
     * @action Action name or comma-delimited list (e.g., index, show, edit)
     * @model Model name (defaults to singular of controller)
     * @partial Generate a partial view (prefixed with _)
     * @layout Generate a layout file
     * @template View template style (default, bootstrap5, tailwind)
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
        required string template,
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
        
        var partialContent = '<cfoutput>
<!--- Partial: #partialName# --->
<!--- Generated: #dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")# --->

<div class="partial-#replace(partialName, "_", "", "one")#">
    <!--- Add your partial content here --->
    <p>This is the #partialName# partial.</p>
    
    <!--- Access passed variables like this: --->
    <!--- ##variables.someVariable## --->
</div>
</cfoutput>';
        
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
        
        var layoutContent = '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><cfoutput>##contentForLayout("title")## - ##application.applicationName##</cfoutput></title>
    
    <!--- CSS --->
    <cfoutput>##styleSheetLinkTag("app")##</cfoutput>
    
    <!--- Additional head content --->
    <cfoutput>##contentForLayout("head")##</cfoutput>
</head>
<body>
    <header>
        <nav>
            <h1><cfoutput>##application.applicationName##</cfoutput></h1>
            <!--- Add navigation here --->
        </nav>
    </header>
    
    <main>
        <!--- Flash messages --->
        <cfif flashKeyExists("success")>
            <div class="alert alert-success">
                <cfoutput>##flash("success")##</cfoutput>
            </div>
        </cfif>
        
        <cfif flashKeyExists("error")>
            <div class="alert alert-error">
                <cfoutput>##flash("error")##</cfoutput>
            </div>
        </cfif>
        
        <cfif flashKeyExists("notice")>
            <div class="alert alert-notice">
                <cfoutput>##flash("notice")##</cfoutput>
            </div>
        </cfif>
        
        <!--- Main content --->
        <cfoutput>##contentForLayout()##</cfoutput>
    </main>
    
    <footer>
        <p>&copy; #year(now())# <cfoutput>##application.applicationName##</cfoutput></p>
    </footer>
    
    <!--- JavaScript --->
    <cfoutput>##javaScriptIncludeTag("app")##</cfoutput>
    
    <!--- Additional scripts --->
    <cfoutput>##contentForLayout("scripts")##</cfoutput>
</body>
</html>';
        
        fileWrite(layoutFile, layoutContent);
        print.greenLine("✓ Created layout: app/views/layout/#arguments.name#.cfm");
        
        print.line();
        print.yellowLine("To use this layout in a controller:");
        print.indentedLine("usesLayout(""#arguments.name#"");");
    }
    
    /**
     * Generate view content based on action and template
     */
    private function generateViewContent(
        required string controller,
        required string action,
        required string model,
        required string template
    ) {
        var content = "";
        var modelLower = lCase(arguments.model);
        var modelsLower = lCase(pluralize(arguments.model));
        
        // Generate content based on action
        switch(arguments.action) {
            case "index":
                content = generateIndexView(arguments.controller, arguments.model, arguments.template);
                break;
                
            case "show":
                content = generateShowView(arguments.controller, arguments.model, arguments.template);
                break;
                
            case "new":
                content = generateNewView(arguments.controller, arguments.model, arguments.template);
                break;
                
            case "edit":
                content = generateEditView(arguments.controller, arguments.model, arguments.template);
                break;
                
            default:
                content = generateDefaultView(arguments.controller, arguments.action, arguments.model);
        }
        
        return content;
    }
    
    /**
     * Generate index view
     */
    private function generateIndexView(controller, model, template) {
        var modelLower = lCase(model);
        var modelsLower = lCase(pluralize(model));
        
        return '<cfoutput>

##contentFor(title="#pluralize(model)#")##

<div class="page-header">
    <h1>#pluralize(model)#</h1>
    ##linkTo(route="new#model#", text="New #model#", class="btn btn-primary")##
</div>

<cfif #modelsLower#.recordCount>
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <!--- Add more columns here based on your model --->
                <th>Created</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <cfloop query="#modelsLower#">
                <tr>
                    <td>###modelsLower#.id##</td>
                    <!--- Add more columns here --->
                    <td>##dateFormat(#modelsLower#.createdAt, "mm/dd/yyyy")##</td>
                    <td>
                        ##linkTo(route="#modelLower#", key=#modelsLower#.id, text="View")##
                        ##linkTo(route="edit#model#", key=#modelsLower#.id, text="Edit")##
                        ##linkTo(route="#modelLower#", key=#modelsLower#.id, text="Delete", method="delete", confirm="Are you sure?")##
                    </td>
                </tr>
            </cfloop>
        </tbody>
    </table>
<cfelse>
    <p>No #lCase(pluralize(model))# found.</p>
</cfif>

</cfoutput>';
    }
    
    /**
     * Generate show view
     */
    private function generateShowView(controller, model, template) {
        var modelLower = lCase(model);
        
        return '<cfoutput>

##contentFor(title="#model# Details")##

<div class="page-header">
    <h1>#model# Details</h1>
</div>

<dl class="dl-horizontal">
    <dt>ID:</dt>
    <dd>###modelLower#.id##</dd>
    
    <!--- Add more fields here based on your model --->
    
    <dt>Created:</dt>
    <dd>##dateFormat(#modelLower#.createdAt, "mm/dd/yyyy")##</dd>
    
    <dt>Updated:</dt>
    <dd>##dateFormat(#modelLower#.updatedAt, "mm/dd/yyyy")##</dd>
</dl>

<div class="form-actions">
    ##linkTo(route="edit#model#", key=#modelLower#.id, text="Edit", class="btn btn-primary")##
    ##linkTo(route="#lCase(pluralize(model))#", text="Back to List", class="btn")##
</div>

</cfoutput>';
    }
    
    /**
     * Generate new view
     */
    private function generateNewView(controller, model, template) {
        var modelLower = lCase(model);
        
        return '<cfoutput>

##contentFor(title="New #model#")##

<div class="page-header">
    <h1>New #model#</h1>
</div>

##startFormTag(route="#lCase(pluralize(model))#", method="post")##
    
    ##includePartial("form")##
    
    <div class="form-actions">
        ##submitTag("Create #model#", class="btn btn-primary")##
        ##linkTo(route="#lCase(pluralize(model))#", text="Cancel", class="btn")##
    </div>
    
##endFormTag()##

</cfoutput>';
    }
    
    /**
     * Generate edit view
     */
    private function generateEditView(controller, model, template) {
        var modelLower = lCase(model);
        
        return '<cfoutput>

##contentFor(title="Edit #model#")##

<div class="page-header">
    <h1>Edit #model#</h1>
</div>

##startFormTag(route="#modelLower#", key=#modelLower#.id, method="patch")##
    
    ##includePartial("form")##
    
    <div class="form-actions">
        ##submitTag("Update #model#", class="btn btn-primary")##
        ##linkTo(route="#modelLower#", key=#modelLower#.id, text="Cancel", class="btn")##
    </div>
    
##endFormTag()##

</cfoutput>';
    }
    
    /**
     * Generate default view
     */
    private function generateDefaultView(controller, action, model) {
        return '<cfoutput>

##contentFor(title="#action#")##

<div class="page-header">
    <h1>#action#</h1>
</div>

<p>This is the #action# view for the #controller# controller.</p>

<!--- Add your view content here --->

</cfoutput>';
    }
}