/**
 * Create RESTful API controller and supporting files
 *
 * {code:bash}
 * wheels generate api-resource users
 * wheels generate api-resource posts --model --docs --auth
 * wheels g api-resource products --model --docs
 * wheels g api-resource orders --auth
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

        // Set API controller path (namespace: api)
        local.apiDir = fileSystemUtil.resolvePath("app/controllers/api");
        if (!directoryExists(local.apiDir)) {
            directoryCreate(local.apiDir);
        }
        local.controllerPath = "#local.apiDir#/#local.obj.objectNamePluralC#.cfc";

        // Check if controller already exists
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

        // Add RESTful routes to config/routes.cfm
        local.routesPath = fileSystemUtil.resolvePath("config/routes.cfm");
        if (fileExists(local.routesPath)) {
            local.routesContent = fileRead(local.routesPath);
            local.routePrefix = "/api/#local.obj.objectNamePlural#";
            if (!findNoCase(local.routePrefix, local.routesContent)) {
                local.newRoutes = '
addRoute(pattern="/api/#local.obj.objectNamePlural#", controller="api/#local.obj.objectNamePluralC#", action="index", method="get");
addRoute(pattern="/api/#local.obj.objectNamePlural#/[key]", controller="api/#local.obj.objectNamePluralC#", action="show", method="get");
addRoute(pattern="/api/#local.obj.objectNamePlural#", controller="api/#local.obj.objectNamePluralC#", action="create", method="post");
addRoute(pattern="/api/#local.obj.objectNamePlural#/[key]", controller="api/#local.obj.objectNamePluralC#", action="update", method="put");
addRoute(pattern="/api/#local.obj.objectNamePlural#/[key]", controller="api/#local.obj.objectNamePluralC#", action="delete", method="delete");
';
                fileWrite(local.routesPath, trim(local.routesContent) & chr(10) & local.newRoutes);
                print.greenLine("Added RESTful routes to config/routes.cfm");
            } else {
                print.yellowLine("Routes for /api/#local.obj.objectNamePlural# already exist in config/routes.cfm");
            }
        } else {
            print.redLine("Could not find config/routes.cfm to add routes.");
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
        print.line("GET /api/#local.obj.objectNamePlural#");
        print.line("GET /api/#local.obj.objectNamePlural#/:id");
        print.line("POST /api/#local.obj.objectNamePlural#");
        print.line("PUT /api/#local.obj.objectNamePlural#/:id");
        print.line("DELETE /api/#local.obj.objectNamePlural#/:id");
        print.line();
    }
}
