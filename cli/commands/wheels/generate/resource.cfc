/**
 * Generate a complete RESTful resource
 * Examples:
 * wheels generate resource User --api --tests
 * wheels generate resource Post --belongs-to=User --has-many=Comments
 */
component aliases='wheels g resource' extends="../base" {
    
    property name="templateService" inject="TemplateService@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @name.hint Resource name (singular)
     * @api.hint Generate API-only resource (no views)
     * @tests.hint Generate associated tests
     * @migration.hint Generate database migration
     * @belongs-to.hint Parent model relationships (comma-separated)
     * @has-many.hint Child model relationships (comma-separated)
     * @attributes.hint Model attributes (name:type,email:string)
     * @open.hint Open generated files
     * @scaffold.hint Generate with full CRUD operations
     */
    function run(
        required string name,
        boolean api = false,
        boolean tests = true,
        boolean migration = true,
        string belongsTo = "",
        string hasMany = "",
        string attributes = "",
        boolean open = false,
        boolean scaffold = true
    ) {
        // Validate we're in a Wheels project
        if (!directoryExists(fileSystemUtil.resolvePath("vendor/wheels"))) {
            error("This command must be run from the root of a Wheels application.");
            return;
        }
        
        var obj = helpers.getNameVariants(arguments.name);
        var generatedFiles = [];
        
        detailOutput.header("🚀", "Generating resource: #arguments.name#");
        
        // Generate model
        var modelPath = generateModel(obj, arguments);
        arrayAppend(generatedFiles, modelPath);
        detailOutput.create(modelPath);
        
        // Generate controller
        var controllerPath = generateController(obj, arguments);
        arrayAppend(generatedFiles, controllerPath);
        detailOutput.create(controllerPath);
        
        // Generate views (unless API-only)
        if (!arguments.api) {
            var viewPaths = generateViews(obj, arguments);
            generatedFiles.addAll(viewPaths);
            for (var viewPath in viewPaths) {
                detailOutput.create(viewPath);
            }
        }
        
        // Generate routes
        var routesAdded = addRoutes(obj, arguments);
        if (routesAdded) {
            var routeType = arguments.api ? "apiResource" : "resources";
            detailOutput.route(routeType & "('" & lCase(arguments.name) & "')");
        }
        
        // Generate tests
        if (arguments.tests) {
            detailOutput.invoke("test");
            var testPaths = generateTests(obj, arguments);
            generatedFiles.addAll(testPaths);
            for (var testPath in testPaths) {
                detailOutput.create(testPath, true);
            }
        }
        
        // Generate migration
        if (arguments.migration) {
            detailOutput.invoke("dbmigrate");
            var migrationPath = generateMigration(obj, arguments);
            arrayAppend(generatedFiles, migrationPath);
            detailOutput.create(migrationPath, true);
        }
        
        // Display summary
        displayGenerationSummary(generatedFiles, arguments);
        
        if (arguments.open) {
            generatedFiles.each(function(file) {
                openPath(file);
            });
        }
    }
    
    private function generateModel(obj, options) {
        var modelPath = "app/models/#obj.objectNameSingularC#.cfc";
        var modelContent = generateModelContent(obj, options);
        
        var fullPath = fileSystemUtil.resolvePath(modelPath);
        file action='write' file='#fullPath#' mode='777' output='#trim(modelContent)#';
        
        return modelPath;
    }
    
    private function generateModelContent(obj, options) {
        var content = 'component extends="wheels.Model" {' & chr(10) & chr(10);
        content &= '    function config() {' & chr(10);
        
        // Add table name if different from convention
        content &= '        table("' & obj.objectNamePlural & '");' & chr(10);
        
        // Add relationships
        if (len(options.belongsTo)) {
            var belongsToList = listToArray(options.belongsTo);
            for (var parent in belongsToList) {
                content &= '        belongsTo("' & trim(parent) & '");' & chr(10);
            }
        }
        
        if (len(options.hasMany)) {
            var hasManyList = listToArray(options.hasMany);
            for (var child in hasManyList) {
                content &= '        hasMany("' & trim(child) & '");' & chr(10);
            }
        }
        
        // Add validations based on attributes
        if (len(options.attributes)) {
            content &= chr(10);
            var attrs = parseAttributes(options.attributes);
            for (var attr in attrs) {
                if (attrs[attr] == "email") {
                    content &= '        validatesFormatOf(property="' & attr & '", type="email");' & chr(10);
                } else if (attrs[attr] == "numeric" || attrs[attr] == "integer") {
                    content &= '        validatesNumericalityOf(property="' & attr & '");' & chr(10);
                } else {
                    content &= '        validatesPresenceOf(property="' & attr & '");' & chr(10);
                }
            }
        }
        
        content &= '    }' & chr(10);
        content &= '}' & chr(10);
        
        return content;
    }
    
    private function generateController(obj, options) {
        var controllerName = options.api ? obj.objectNamePluralC & "Api" : obj.objectNamePluralC;
        var controllerPath = "app/controllers/#controllerName#.cfc";
        var controllerContent = generateControllerContent(obj, options);
        
        var fullPath = fileSystemUtil.resolvePath(controllerPath);
        file action='write' file='#fullPath#' mode='777' output='#trim(controllerContent)#';
        
        return controllerPath;
    }
    
    private function generateControllerContent(obj, options) {
        var content = 'component extends="wheels.Controller" {' & chr(10) & chr(10);
        
        if (options.scaffold) {
            // Index action
            content &= '    function index() {' & chr(10);
            content &= '        #obj.objectNamePlural# = model("' & obj.objectNameSingular & '").findAll();' & chr(10);
            if (options.api) {
                content &= '        renderWith(#obj.objectNamePlural#);' & chr(10);
            }
            content &= '    }' & chr(10) & chr(10);
            
            // Show action
            content &= '    function show() {' & chr(10);
            content &= '        #obj.objectNameSingular# = model("' & obj.objectNameSingular & '").findByKey(params.key);' & chr(10);
            if (options.api) {
                content &= '        renderWith(#obj.objectNameSingular#);' & chr(10);
            }
            content &= '    }' & chr(10) & chr(10);
            
            if (!options.api) {
                // New action
                content &= '    function new() {' & chr(10);
                content &= '        #obj.objectNameSingular# = model("' & obj.objectNameSingular & '").new();' & chr(10);
                content &= '    }' & chr(10) & chr(10);
            }
            
            // Create action
            content &= '    function create() {' & chr(10);
            content &= '        #obj.objectNameSingular# = model("' & obj.objectNameSingular & '").create(params.#obj.objectNameSingular#);' & chr(10);
            content &= '        if (#obj.objectNameSingular#.save()) {' & chr(10);
            if (options.api) {
                content &= '            renderWith(#obj.objectNameSingular#);' & chr(10);
            } else {
                content &= '            flashInsert(success="' & obj.objectNameSingularC & ' was created successfully.");' & chr(10);
                content &= '            redirectTo(route="' & obj.objectNameSingular & '", key=#obj.objectNameSingular#.key());' & chr(10);
            }
            content &= '        } else {' & chr(10);
            if (options.api) {
                content &= '            renderWith(#obj.objectNameSingular#);' & chr(10);
            } else {
                content &= '            renderPage(action="new");' & chr(10);
            }
            content &= '        }' & chr(10);
            content &= '    }' & chr(10) & chr(10);
            
            if (!options.api) {
                // Edit action
                content &= '    function edit() {' & chr(10);
                content &= '        #obj.objectNameSingular# = model("' & obj.objectNameSingular & '").findByKey(params.key);' & chr(10);
                content &= '    }' & chr(10) & chr(10);
            }
            
            // Update action
            content &= '    function update() {' & chr(10);
            content &= '        #obj.objectNameSingular# = model("' & obj.objectNameSingular & '").findByKey(params.key);' & chr(10);
            content &= '        if (#obj.objectNameSingular#.update(params.#obj.objectNameSingular#)) {' & chr(10);
            if (options.api) {
                content &= '            renderWith(#obj.objectNameSingular#);' & chr(10);
            } else {
                content &= '            flashInsert(success="' & obj.objectNameSingularC & ' was updated successfully.");' & chr(10);
                content &= '            redirectTo(route="' & obj.objectNameSingular & '", key=#obj.objectNameSingular#.key());' & chr(10);
            }
            content &= '        } else {' & chr(10);
            if (options.api) {
                content &= '            renderWith(#obj.objectNameSingular#);' & chr(10);
            } else {
                content &= '            renderPage(action="edit");' & chr(10);
            }
            content &= '        }' & chr(10);
            content &= '    }' & chr(10) & chr(10);
            
            // Delete action
            content &= '    function delete() {' & chr(10);
            content &= '        #obj.objectNameSingular# = model("' & obj.objectNameSingular & '").findByKey(params.key);' & chr(10);
            content &= '        #obj.objectNameSingular#.delete();' & chr(10);
            if (options.api) {
                content &= '            renderWith({message="Deleted successfully"});' & chr(10);
            } else {
                content &= '        flashInsert(success="' & obj.objectNameSingularC & ' was deleted successfully.");' & chr(10);
                content &= '        redirectTo(route="' & obj.objectNamePlural & '");' & chr(10);
            }
            content &= '    }' & chr(10);
        }
        
        content &= '}' & chr(10);
        
        return content;
    }
    
    private function generateViews(obj, options) {
        var viewPaths = [];
        var viewDir = fileSystemUtil.resolvePath("app/views/#obj.objectNamePlural#");
        
        if (!directoryExists(viewDir)) {
            directoryCreate(viewDir);
        }
        
        if (options.scaffold) {
            // Generate index view
            var indexPath = "#viewDir#/index.cfm";
            var indexContent = generateIndexView(obj, options);
            fileWrite(indexPath, indexContent);
            arrayAppend(viewPaths, "app/views/#obj.objectNamePlural#/index.cfm");
            
            // Generate show view
            var showPath = "#viewDir#/show.cfm";
            var showContent = generateShowView(obj, options);
            fileWrite(showPath, showContent);
            arrayAppend(viewPaths, "app/views/#obj.objectNamePlural#/show.cfm");
            
            // Generate new view
            var newPath = "#viewDir#/new.cfm";
            var newContent = generateNewView(obj, options);
            fileWrite(newPath, newContent);
            arrayAppend(viewPaths, "app/views/#obj.objectNamePlural#/new.cfm");
            
            // Generate edit view
            var editPath = "#viewDir#/edit.cfm";
            var editContent = generateEditView(obj, options);
            fileWrite(editPath, editContent);
            arrayAppend(viewPaths, "app/views/#obj.objectNamePlural#/edit.cfm");
            
            // Generate form partial
            var formPath = "#viewDir#/_form.cfm";
            var formContent = generateFormPartial(obj, options);
            fileWrite(formPath, formContent);
            arrayAppend(viewPaths, "app/views/#obj.objectNamePlural#/_form.cfm");
        }
        
        return viewPaths;
    }
    
    private function generateIndexView(obj, options) {
        var content = '<h1>#obj.objectNamePluralC#</h1>' & chr(10) & chr(10);
        content &= '<p>##linkTo(text="New #obj.objectNameSingularC#", route="new#obj.objectNameSingularC#")##</p>' & chr(10) & chr(10);
        content &= '<table>' & chr(10);
        content &= '    <thead>' & chr(10);
        content &= '        <tr>' & chr(10);
        content &= '            <th>ID</th>' & chr(10);
        content &= '            <th>Actions</th>' & chr(10);
        content &= '        </tr>' & chr(10);
        content &= '    </thead>' & chr(10);
        content &= '    <tbody>' & chr(10);
        content &= '        <cfloop query="#obj.objectNamePlural#">' & chr(10);
        content &= '            <tr>' & chr(10);
        content &= '                <td>###obj.objectNamePlural#.id##</td>' & chr(10);
        content &= '                <td>' & chr(10);
        content &= '                    ##linkTo(text="Show", route="#obj.objectNameSingular#", key=#obj.objectNamePlural#.id)##' & chr(10);
        content &= '                    ##linkTo(text="Edit", route="edit#obj.objectNameSingularC#", key=#obj.objectNamePlural#.id)##' & chr(10);
        content &= '                    ##linkTo(text="Delete", route="#obj.objectNameSingular#", key=#obj.objectNamePlural#.id, method="delete", confirm="Are you sure?")##' & chr(10);
        content &= '                </td>' & chr(10);
        content &= '            </tr>' & chr(10);
        content &= '        </cfloop>' & chr(10);
        content &= '    </tbody>' & chr(10);
        content &= '</table>' & chr(10);
        
        return content;
    }
    
    private function generateShowView(obj, options) {
        var content = '<h1>##encodeForHTML(#obj.objectNameSingular#.id)##</h1>' & chr(10) & chr(10);
        content &= '<p>' & chr(10);
        content &= '    ##linkTo(text="Edit", route="edit#obj.objectNameSingularC#", key=#obj.objectNameSingular#.key())##' & chr(10);
        content &= '    ##linkTo(text="Back to List", route="#obj.objectNamePlural#")##' & chr(10);
        content &= '</p>' & chr(10);
        
        return content;
    }
    
    private function generateNewView(obj, options) {
        var content = '<h1>New #obj.objectNameSingularC#</h1>' & chr(10) & chr(10);
        content &= '<cfinclude template="_form.cfm">' & chr(10);
        
        return content;
    }
    
    private function generateEditView(obj, options) {
        var content = '<h1>Edit #obj.objectNameSingularC#</h1>' & chr(10) & chr(10);
        content &= '<cfinclude template="_form.cfm">' & chr(10);
        
        return content;
    }
    
    private function generateFormPartial(obj, options) {
        var content = '##startFormTag(route=#obj.objectNameSingular#.persisted() ? "#obj.objectNameSingular#" : "#obj.objectNamePlural#", key=#obj.objectNameSingular#.persisted() ? #obj.objectNameSingular#.key() : "", method=#obj.objectNameSingular#.persisted() ? "patch" : "post")##' & chr(10) & chr(10);
        
        if (len(options.attributes)) {
            var attrs = parseAttributes(options.attributes);
            for (var attr in attrs) {
                content &= '    <div>' & chr(10);
                content &= '        ##textField(objectName="#obj.objectNameSingular#", property="#attr#", label="#helpers.capitalize(attr)#")##' & chr(10);
                content &= '    </div>' & chr(10) & chr(10);
            }
        }
        
        content &= '    ##submitTag()##' & chr(10);
        content &= '    ##linkTo(text="Cancel", route="#obj.objectNamePlural#")##' & chr(10) & chr(10);
        content &= '##endFormTag()##' & chr(10);
        
        return content;
    }
    
    private function generateTests(obj, options) {
        var testPaths = [];
        
        // Generate model test
        command("wheels generate test")
            .params(
                type = "model",
                objectname = obj.objectNameSingular,
                crud = true
            )
            .run();
        arrayAppend(testPaths, "tests/Testbox/specs/models/#obj.objectNameSingularC#.cfc");
        
        // Generate controller test
        command("wheels generate test")
            .params(
                type = "controller",
                objectname = obj.objectNamePlural,
                crud = true
            )
            .run();
        arrayAppend(testPaths, "tests/Testbox/specs/controllers/#obj.objectNamePluralC#.cfc");
        
        return testPaths;
    }
    
    private function generateMigration(obj, options) {
        var migrationName = "create_#obj.objectNamePlural#_table";
        var migrationContent = generateMigrationContent(obj, options);
        
        command("wheels dbmigrate create blank")
            .params(name = migrationName)
            .run();
        
        // Find the created migration file and update its content
        var migrationDir = fileSystemUtil.resolvePath("app/migrator/migrations");
        var files = directoryList(migrationDir, false, "name", "*#migrationName#.cfc");
        
        if (arrayLen(files)) {
            var migrationPath = "#migrationDir#/#files[1]#";
            var content = fileRead(migrationPath);
            
            // Find positions of up() and down() functions
            var upMatch = reFind("function up\(\)\s*\{[^}]*// your code goes here", content, 1, true);
            var downMatch = reFind("function down\(\)\s*\{[^}]*// your code goes here", content, 1, true);
            
            // Replace down() first (it's later in the file)
            if (downMatch.pos[1]) {
                var downContent = 'dropTable("' & obj.objectNamePlural & '");';
                content = mid(content, 1, downMatch.pos[1] - 1) & 
                         replace(mid(content, downMatch.pos[1], downMatch.len[1]), "// your code goes here", downContent) &
                         mid(content, downMatch.pos[1] + downMatch.len[1]);
            }
            
            // Then replace up()
            if (upMatch.pos[1]) {
                content = mid(content, 1, upMatch.pos[1] - 1) & 
                         replace(mid(content, upMatch.pos[1], upMatch.len[1]), "// your code goes here", migrationContent) &
                         mid(content, upMatch.pos[1] + upMatch.len[1]);
            }
            
            fileWrite(migrationPath, content);
            
            return "app/migrator/migrations/#files[1]#";
        }
        
        return "";
    }
    
    private function generateMigrationContent(obj, options) {
        var content = '        t = createTable(name="' & obj.objectNamePlural & '", id=true, primaryKey="id");' & chr(10);
        
        // Add attributes
        if (len(options.attributes)) {
            var attrs = parseAttributes(options.attributes);
            for (var attr in attrs) {
                var columnType = mapAttributeType(attrs[attr]);
                content &= '        t.' & columnType & '(columnName="' & attr & '");' & chr(10);
            }
        }
        
        // Add foreign keys for belongsTo relationships
        if (len(options.belongsTo)) {
            var belongsToList = listToArray(options.belongsTo);
            for (var parent in belongsToList) {
                var parentObj = helpers.getNameVariants(trim(parent));
                content &= '        t.integer(columnName="' & parentObj.objectNameSingular & 'Id", null=true);' & chr(10);
            }
        }
        
        content &= '        t.timestamps();' & chr(10);
        content &= '        t.create();';
        
        return content;
    }
    
    private function addRoutes(obj, options) {
        var routesPath = fileSystemUtil.resolvePath("app/config/routes.cfm");
        
        if (!fileExists(routesPath)) {
            return false;
        }
        
        var content = fileRead(routesPath);
        var resourceName = arguments.obj.objectNamePlural;
        var resourceRoute = arguments.options.api ? '.apiResource("' & resourceName & '")' : '.resources("' & resourceName & '")';
        
        // Check if route already exists
        if (find(resourceRoute, content)) {
            return false;
        }
        
        // Find the CLI-Appends-Here marker and add route there
        var markerPattern = '// CLI-Appends-Here';
        var indent = '';
        
        // Try to find marker with various indentation levels
        if (find(chr(9) & chr(9) & chr(9) & markerPattern, content)) {
            indent = chr(9) & chr(9) & chr(9);
        } else if (find(chr(9) & chr(9) & markerPattern, content)) {
            indent = chr(9) & chr(9);
        } else if (find(chr(9) & markerPattern, content)) {
            indent = chr(9);
        }
        
        var fullMarkerPattern = indent & markerPattern;
        var inject = indent & resourceRoute;
        
        if (find(fullMarkerPattern, content)) {
            // Replace the marker with the new route followed by the marker on a new line
            content = replace(content, fullMarkerPattern, inject & chr(10) & fullMarkerPattern, 'all');
            fileWrite(routesPath, content);
            return true;
        } else {
            // If no marker found, try to add before .end()
            if (find('.end()', content)) {
                content = replace(content, '.end()', resourceRoute & chr(10) & chr(9) & chr(9) & chr(9) & '.end()', 'all');
                fileWrite(routesPath, content);
                return true;
            }
        }
        
        return false;
    }
    
    private function parseAttributes(attributes) {
        var result = {};
        var attrs = listToArray(arguments.attributes);
        
        for (var attr in attrs) {
            if (find(":", attr)) {
                var parts = listToArray(attr, ":");
                result[trim(parts[1])] = trim(parts[2]);
            } else {
                result[trim(attr)] = "string";
            }
        }
        
        return result;
    }
    
    private function mapAttributeType(type) {
        switch (lCase(arguments.type)) {
            case "string":
            case "email":
                return "string";
            case "text":
                return "text";
            case "integer":
            case "int":
                return "integer";
            case "float":
            case "decimal":
            case "numeric":
                return "decimal";
            case "boolean":
            case "bool":
                return "boolean";
            case "date":
                return "date";
            case "datetime":
            case "timestamp":
                return "datetime";
            default:
                return "string";
        }
    }
    
    private function displayGenerationSummary(generatedFiles, options) {
        detailOutput.success("Resource generation complete!");
        
        var nextSteps = [
            "Run migrations: wheels dbmigrate up",
            "Reload your application"
        ];
        
        if (arguments.options.tests) {
            arrayAppend(nextSteps, "Run tests: wheels test run");
        }
        
        detailOutput.nextSteps(nextSteps);
    }
    
    private function openPath(required string path) {
        if (shell.isWindows()) {
            runCommand("start #arguments.path#");
        } else if (shell.isMac()) {
            runCommand("open #arguments.path#");
        } else {
            runCommand("xdg-open #arguments.path#");
        }
    }
}