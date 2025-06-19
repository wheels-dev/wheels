/**
 * Create RESTful API controller and supporting files
 *
 * {code:bash}
 * wheels generate api-resource users
 * wheels generate api-resource posts --model=true --docs=true
 * {code}
 */
component aliases='wheels g api-resource' extends="../base" {

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

        // Process resource name using getNameVariants
        local.obj = helpers.getNameVariants(arguments.name);

        // Check if controller already exists
        local.controllerPath = fileSystemUtil.resolvePath("app/controllers/#local.obj.objectNamePlural#controller.cfc");
        if (fileExists(local.controllerPath)) {
            if (!confirm("Controller already exists. Do you want to overwrite it? [y/n]")) {
                print.line("Aborted");
                return;
            }
        }

        // Create model if requested
        if (arguments.model) {
            print.line("Generating model #local.obj.objectNameSingularC#...");
            command("wheels generate model")
                .params(name=local.obj.objectNameSingular)
                .run();
        }

        // Create API controller
        print.line("Generating API controller #local.obj.objectNamePluralC#...");

        // Template variables are already prepared in local.obj from getNameVariants()

        // Read API controller template
        local.template = fileRead(expandPath("/wheels-cli/templates/ApiControllerContent.txt"));
        if (!isNull(local.template)) {
            // Replace placeholders
            local.content = $replaceDefaultObjectNames(local.template, local.obj);

            // Add authentication if requested
            if (arguments.auth) {
                // Find the position after config() function
                local.configEndPos = find("}", local.content, find("function config()", local.content));

                local.authContent = chr(10) & chr(10) &
                    "    // Authentication check before actions" & chr(10) &
                    "    private function authenticateAPI() {" & chr(10) &
                    "        // Add your API authentication logic here" & chr(10) &
                    "        // Example: Check for API token in header" & chr(10) &
                    "        local.apiToken = request.headers['X-API-Token'] ?: '';" & chr(10) &
                    "        if (len(local.apiToken) == 0 || !authenticateToken(local.apiToken)) {" & chr(10) &
                    "            renderWith(data={error='Unauthorized'}, status=401);" & chr(10) &
                    "        }" & chr(10) &
                    "    }" & chr(10) & chr(10) &
                    "    private function authenticateToken(required string token) {" & chr(10) &
                    "        // Implement your token validation logic" & chr(10) &
                    "        // Return true if token is valid, false otherwise" & chr(10) &
                    "        return false;" & chr(10) &
                    "    }";

                // Insert auth methods after config()
                local.content = insert(local.authContent, local.content, local.configEndPos);

                // Add filter to config() function
                local.content = replaceNoCase(local.content, "provides(""json"");", "provides(""json"");" & chr(10) & "        filters(through=""authenticateAPI"", except=""index,show"");", "all");
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

            local.docsPath = "#local.docsDir#/#local.obj.objectNamePlural#.md";
            local.docsContent = "## #local.obj.objectNamePluralC# API

#### Endpoints

###### GET /#local.obj.objectNamePlural#
Returns a list of all #local.obj.objectNamePlural#.

######## Response
```json
{
    ""#local.obj.objectNamePlural#"": [
        {
            ""id"": 1,
            ""createdAt"": ""2023-01-01T12:00:00Z"",
            ""updatedAt"": ""2023-01-01T12:00:00Z""
        }
    ]
}
```

###### GET /#local.obj.objectNamePlural#/:id
Returns a specific #local.obj.objectNameSingular# by ID.

######## Response
```json
{
    ""#local.obj.objectNameSingular#"": {
        ""id"": 1,
        ""createdAt"": ""2023-01-01T12:00:00Z"",
        ""updatedAt"": ""2023-01-01T12:00:00Z""
    }
}
```

###### POST /#local.obj.objectNamePlural#
Creates a new #local.obj.objectNameSingular#.

######## Request
```json
{
    ""#local.obj.objectNameSingular#"": {
        ""property1"": ""value1"",
        ""property2"": ""value2""
    }
}
```

######## Response
```json
{
    ""#local.obj.objectNameSingular#"": {
        ""id"": 1,
        ""property1"": ""value1"",
        ""property2"": ""value2"",
        ""createdAt"": ""2023-01-01T12:00:00Z"",
        ""updatedAt"": ""2023-01-01T12:00:00Z""
    }
}
```

###### PUT /#local.obj.objectNamePlural#/:id
Updates an existing #local.obj.objectNameSingular#.

######## Request
```json
{
    ""#local.obj.objectNameSingular#"": {
        ""property1"": ""updatedValue""
    }
}
```

######## Response
```json
{
    ""#local.obj.objectNameSingular#"": {
        ""id"": 1,
        ""property1"": ""updatedValue"",
        ""property2"": ""value2"",
        ""createdAt"": ""2023-01-01T12:00:00Z"",
        ""updatedAt"": ""2023-01-01T12:00:00Z""
    }
}
```

###### DELETE /#local.obj.objectNamePlural#/:id
Deletes a #local.obj.objectNameSingular#.

######## Response
Status 204 No Content
";

            file action='write' file='#local.docsPath#' mode='777' output='#trim(local.docsContent)#';
            print.greenLine("Created API documentation at #local.docsPath#");
        }

        print.line();
        print.greenLine("API resource '#local.obj.objectNamePlural#' generated successfully.");
        print.line();
        print.yellowLine("You can access your API at:");
        print.line("GET /#local.obj.objectNamePlural#");
        print.line("GET /#local.obj.objectNamePlural#/:id");
        print.line("POST /#local.obj.objectNamePlural#");
        print.line("PUT /#local.obj.objectNamePlural#/:id");
        print.line("DELETE /#local.obj.objectNamePlural#/:id");
        print.line();
    }
}
