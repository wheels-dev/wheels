/**
 * Create RESTful API controller and supporting files
 * 
 * {code:bash}
 * wheels generate api-resource users
 * wheels generate api-resource posts --model=true --docs=true
 * {code}
 */
component extends="../base" {

    /**
     * @name Name of the API resource (singular or plural)
     * @model Generate associated model
     * @docs Generate API documentation template
     * @auth Include authentication checks
     */
    function run(
        required string name, 
        boolean model=false,
        boolean docs=false,
        boolean auth=false
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels API Resource Generator");
        print.line();
        
        // Process resource name
        local.objectNamePlural = helpers.pluralize(arguments.name);
        local.objectNameSingular = helpers.singularize(arguments.name);
        local.objectNameSingularC = helpers.capitalize(local.objectNameSingular);
        local.objectNamePluralC = helpers.capitalize(local.objectNamePlural);
        
        // Check if controller already exists
        local.controllerPath = fileSystemUtil.resolvePath("app/controllers/#local.objectNamePlural#controller.cfc");
        if (fileExists(local.controllerPath)) {
            if (!confirm("Controller already exists. Do you want to overwrite it? [y/n]")) {
                print.line("Aborted");
                return;
            }
        }
        
        // Create model if requested
        if (arguments.model) {
            print.line("Generating model #local.objectNameSingularC#...");
            command("wheels generate model")
                .params(name=local.objectNameSingular)
                .run();
        }
        
        // Create API controller
        print.line("Generating API controller #local.objectNamePluralC#...");
        
        // Prepare template variables
        local.obj = {
            objectNameSingular = local.objectNameSingular,
            objectNamePlural = local.objectNamePlural,
            objectNameSingularC = local.objectNameSingularC,
            objectNamePluralC = local.objectNamePluralC
        };
        
        // Read API controller template
        local.template = fileRead(expandPath("/wheels-cli/templates/ApiControllerContent.txt"));
        if (!isNull(local.template)) {
            // Replace placeholders
            local.content = $replaceDefaultObjectNames(local.template, local.obj);
            
            // Add authentication if requested
            if (arguments.auth) {
                local.authContent = "
    // Authentication check before actions
    function init() {
        filters(through="authenticateAPI", except="index,show");
    }
    
    private function authenticateAPI() {
        // Add your API authentication logic here
        // Example: Check for API token in header
        local.apiToken = request.headers['X-API-Token'] ?: '';
        if (len(local.apiToken) == 0 || !authenticateToken(local.apiToken)) {
            renderWith(data={error='Unauthorized'}, status=401);
        }
    }
    
    private function authenticateToken(required string token) {
        // Implement your token validation logic
        // Return true if token is valid, false otherwise
        return false;
    }";
                local.content = replaceNoCase(local.content, "function init() {", "#local.authContent#", "all");
            }
            
            // Create the controller file
            file action='write' file='#local.controllerPath#' mode='777' output='#trim(local.content)#';
            print.greenLine("Created #local.controllerPath#");
        } else {
            // If template doesn't exist, create basic controller
            error("API controller template not found. Create one at /wheels-cli/templates/ApiControllerContent.txt");
        }
        
        // Generate API documentation if requested
        if (arguments.docs) {
            local.docsDir = fileSystemUtil.resolvePath("app/docs/api");
            if (!directoryExists(local.docsDir)) {
                directoryCreate(local.docsDir);
            }
            
            local.docsPath = "#local.docsDir#/#local.objectNamePlural#.md";
            local.docsContent = "# #local.objectNamePluralC# API
            
## Endpoints

### GET /#local.objectNamePlural#
Returns a list of all #local.objectNamePlural#.

#### Response
```json
{
    "#local.objectNamePlural#": [
        {
            "id": 1,
            "createdAt": "2023-01-01T12:00:00Z",
            "updatedAt": "2023-01-01T12:00:00Z"
        }
    ]
}
```

### GET /#local.objectNamePlural#/:id
Returns a specific #local.objectNameSingular# by ID.

#### Response
```json
{
    "#local.objectNameSingular#": {
        "id": 1,
        "createdAt": "2023-01-01T12:00:00Z",
        "updatedAt": "2023-01-01T12:00:00Z"
    }
}
```

### POST /#local.objectNamePlural#
Creates a new #local.objectNameSingular#.

#### Request
```json
{
    "#local.objectNameSingular#": {
        "property1": "value1",
        "property2": "value2"
    }
}
```

#### Response
```json
{
    "#local.objectNameSingular#": {
        "id": 1,
        "property1": "value1",
        "property2": "value2",
        "createdAt": "2023-01-01T12:00:00Z",
        "updatedAt": "2023-01-01T12:00:00Z"
    }
}
```

### PUT /#local.objectNamePlural#/:id
Updates an existing #local.objectNameSingular#.

#### Request
```json
{
    "#local.objectNameSingular#": {
        "property1": "updatedValue"
    }
}
```

#### Response
```json
{
    "#local.objectNameSingular#": {
        "id": 1,
        "property1": "updatedValue",
        "property2": "value2",
        "createdAt": "2023-01-01T12:00:00Z",
        "updatedAt": "2023-01-01T12:00:00Z"
    }
}
```

### DELETE /#local.objectNamePlural#/:id
Deletes a #local.objectNameSingular#.

#### Response
Status 204 No Content
";
            
            file action='write' file='#local.docsPath#' mode='777' output='#trim(local.docsContent)#';
            print.greenLine("Created API documentation at #local.docsPath#");
        }
        
        print.line();
        print.greenLine("API resource '#local.objectNamePlural#' generated successfully.");
        print.line();
        print.yellowLine("You can access your API at:");
        print.line("GET /api/#local.objectNamePlural#");
        print.line("GET /api/#local.objectNamePlural#/:id");
        print.line("POST /api/#local.objectNamePlural#");
        print.line("PUT /api/#local.objectNamePlural#/:id");
        print.line("DELETE /api/#local.objectNamePlural#/:id");
        print.line();
    }
}