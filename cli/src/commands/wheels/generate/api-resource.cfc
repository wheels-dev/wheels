/**
 * Create RESTful API controller and supporting files
 *
 * {code:bash}
 * wheels generate api-resource products
 * wheels generate api-resource products --model --docs --auth
 * wheels g api-resource products --version=v2 --pagination --filtering
 * wheels g api-resource products --namespace=api --format=json
 * {code}
 */
component aliases='wheels g api-resource' extends="../base" {

    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @name Name of the API resource (singular or plural)
     * @version API version (v1, v2, etc)
     * @format Response format (json, xml)
     * @auth Include authentication
     * @pagination Include pagination
     * @filtering Include filtering
     * @sorting Include sorting
     * @skipModel Skip model generation
     * @skipMigration Skip migration generation
     * @skipTests Skip test generation
     * @namespace API namespace
     * @docs Generate API documentation template
     * @force Overwrite existing files
     */
    function run(
        required string name,
        string version="v1",
        string format="json",
        boolean auth=false,
        boolean pagination=true,
        boolean filtering=true,
        boolean sorting=true,
        boolean skipModel=false,
        boolean skipMigration=false,
        boolean skipTests=false,
        string namespace="api",
        boolean docs=false,
        boolean force=false
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                format: ["json", "xml"]
            }
        );

        detailOutput.header("", "Generating API resource: #arguments.name# (#arguments.namespace#/#arguments.version#)");

        // Process resource name using getNameVariants
        local.obj = helpers.getNameVariants(arguments.name);

        // Determine controller path with namespace
        local.controllerPath = "";
        if (len(arguments.namespace)) {
            local.controllerPath = arguments.namespace & "/";
            if (len(arguments.version)) {
                local.controllerPath &= arguments.version & "/";
            }
        }
        local.controllerPath &= local.obj.objectNamePlural;

        // Create model if requested
        if (!arguments.skipModel) {
            detailOutput.invoke("model");
            command("wheels generate model")
                .params(name=local.obj.objectNameSingular, force=arguments.force)
                .run();
        }

        // Generate API controller with advanced features
        detailOutput.invoke("controller");

        // Build controller content with all features
        local.controllerContent = buildAdvancedController(
            obj = local.obj,
            version = arguments.version,
            format = arguments.format,
            auth = arguments.auth,
            pagination = arguments.pagination,
            filtering = arguments.filtering,
            sorting = arguments.sorting,
            namespace = arguments.namespace
        );

        // Create controller directory structure
        local.controllerDir = fileSystemUtil.resolvePath("app/controllers");
        if (len(arguments.namespace)) {
            local.controllerDir &= "/" & arguments.namespace;
            if (!directoryExists(local.controllerDir)) {
                directoryCreate(local.controllerDir);
            }
            if (len(arguments.version)) {
                local.controllerDir &= "/" & arguments.version;
                if (!directoryExists(local.controllerDir)) {
                    directoryCreate(local.controllerDir);
                }
            }
        }

        local.controllerFilePath = local.controllerDir & "/" & local.obj.objectNamePluralC & ".cfc";

        // Check if controller exists
        if (fileExists(local.controllerFilePath) && !arguments.force) {
            detailOutput.error("Controller already exists. Use --force to overwrite.");
            setExitCode(1);
            return;
        }

        // Write controller file
        file action='write' file='#local.controllerFilePath#' mode='777' output='#trim(local.controllerContent)#';
        detailOutput.create(local.controllerFilePath);

        // Add routes automatically
        detailOutput.invoke("routes");
        addRoutesToConfig(
            resourceName = lCase(local.obj.objectNamePlural),
            namespace = arguments.namespace,
            version = arguments.version
        );

        // Generate API documentation if requested
        if (arguments.docs) {
            detailOutput.invoke("documentation");

            local.docsDir = fileSystemUtil.resolvePath("app/docs/api");
            if (!directoryExists(local.docsDir)) {
                directoryCreate(local.docsDir);
            }

            local.docsPath = "#local.docsDir#/#local.obj.objectNamePlural#.md";
            local.docsContent = "## #local.obj.objectNamePluralC# API

#### Endpoints

#### GET /#local.obj.objectNamePlural#
Returns a list of all #local.obj.objectNamePlural#.

**Response:**
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

#### GET /#local.obj.objectNamePlural#/:id
Returns a specific #local.obj.objectNameSingular# by ID.

**Response:**
```json
{
    ""#local.obj.objectNameSingular#"": {
        ""id"": 1,
        ""createdAt"": ""2023-01-01T12:00:00Z"",
        ""updatedAt"": ""2023-01-01T12:00:00Z""
    }
}
```

#### POST /#local.obj.objectNamePlural#
Creates a new #local.obj.objectNameSingular#.

**Request:**
```json
{
    ""#local.obj.objectNameSingular#"": {
        ""property1"": ""value1"",
        ""property2"": ""value2""
    }
}
```

**Response:**
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

#### PUT /#local.obj.objectNamePlural#/:id
Updates an existing #local.obj.objectNameSingular#.

**Request:**
```json
{
    ""#local.obj.objectNameSingular#"": {
        ""property1"": ""updatedValue""
    }
}
```

**Response:**
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

#### DELETE /#local.obj.objectNamePlural#/:id
Deletes a #local.obj.objectNameSingular#.

**Response:**
Status 204 No Content
";

            file action='write' file='#local.docsPath#' mode='777' output='#trim(local.docsContent)#';
            detailOutput.create(local.docsPath, true);
        }

        // Show next steps
        var nextSteps = [
            "Review the generated controller at #local.controllerFilePath#",
            "Routes have been automatically added to config/routes.cfm",
            "Test your API endpoints"
        ];

        // Build endpoint URLs for display
        local.baseUrl = "";
        if (len(arguments.namespace)) {
            local.baseUrl = "/" & arguments.namespace;
            if (len(arguments.version)) {
                local.baseUrl &= "/" & arguments.version;
            }
        }
        local.baseUrl &= "/" & lCase(local.obj.objectNamePlural);

        arrayAppend(nextSteps, "");
        arrayAppend(nextSteps, "Available endpoints:");
        arrayAppend(nextSteps, "  GET    #local.baseUrl# (List all)");
        arrayAppend(nextSteps, "  GET    #local.baseUrl#/:key (Show one)");
        arrayAppend(nextSteps, "  POST   #local.baseUrl# (Create)");
        arrayAppend(nextSteps, "  PUT    #local.baseUrl#/:key (Update)");
        arrayAppend(nextSteps, "  DELETE #local.baseUrl#/:key (Delete)");

        if (arguments.docs) {
            arrayAppend(nextSteps, "Review API documentation at app/docs/api/#local.obj.objectNamePlural#.md");
        }

        detailOutput.success("API resource generation complete!");
        detailOutput.nextSteps(nextSteps);
    }

    /**
     * Build advanced API controller with features
     */
    private function buildAdvancedController(
        required struct obj,
        required string version,
        required string format,
        required boolean auth,
        required boolean pagination,
        required boolean filtering,
        required boolean sorting,
        required string namespace
    ) {
        local.content = 'component extends="wheels.Controller" output="false" {

    function config() {
        provides("' & arguments.format & '");
        filters(through="clearOutputBuffer,setResponseFormat");';

        if (arguments.auth) {
            local.content &= chr(10) & '        filters(through="authenticate", except="index,show");';
        }

        local.content &= '
    }

    /**
     * GET /';
        local.content &= lCase(arguments.obj.objectNamePlural);
        local.content &= '
     * Returns a list of all ';
        local.content &= lCase(arguments.obj.objectNamePlural);
        local.content &= '
     */
    function index() {';

        if (arguments.pagination) {
            local.content &= '
        local.page = params.page ?: 1;
        local.perPage = params.perPage ?: 25;';
        }

        if (arguments.filtering || arguments.sorting) {
            local.content &= '
        local.options = {};';
        }

        if (arguments.pagination) {
            local.content &= '
        local.options.page = local.page;
        local.options.perPage = local.perPage;';
        }

        if (arguments.sorting) {
            local.content &= '
        if (structKeyExists(params, "sort")) {
            local.options.order = parseSort(params.sort);
        }';
        }

        if (arguments.filtering) {
            local.content &= '
        if (structKeyExists(params, "filter")) {
            local.options.where = parseFilter(params.filter);
        }';
        }

        local.content &= '

        local.';
        local.content &= arguments.obj.objectNamePlural;
        local.content &= ' = model("';
        local.content &= arguments.obj.objectNameSingularC;
        local.content &= '").findAll(';

        if (arguments.filtering || arguments.sorting || arguments.pagination) {
            local.content &= 'argumentCollection=local.options';
        }

        local.content &= ');';

        if (arguments.pagination) {
            local.content &= '

        local.paginationInfo = pagination();
        local.response = {
            data = local.';
            local.content &= arguments.obj.objectNamePlural;
            local.content &= ',
            meta = {
                pagination = {
                    page = local.paginationInfo.currentPage,
                    perPage = local.perPage,
                    total = local.paginationInfo.totalRecords,
                    pages = local.paginationInfo.totalPages
                }
            }
        };

        renderWith(data=local.response);';
        } else {
            local.content &= '
        local.response = {};
        local.response["';
            local.content &= arguments.obj.objectNamePlural;
            local.content &= '"] = local.';
            local.content &= arguments.obj.objectNamePlural;
            local.content &= ';
        renderWith(data=local.response);';
        }

        local.content &= '
    }

    /**
     * GET /';
        local.content &= lCase(arguments.obj.objectNamePlural);
        local.content &= '/:key
     * Returns a specific ';
        local.content &= lCase(arguments.obj.objectNameSingular);
        local.content &= ' by ID
     */
    function show() {
        local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= ' = model("';
        local.content &= arguments.obj.objectNameSingularC;
        local.content &= '").findByKey(params.key);

        if (IsObject(local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= ')) {
            local.response = {};
            local.response["';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= '"] = local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= ';
            renderWith(data=local.response);
        } else {
            renderWith(data={ error="Record not found" }, status=404);
        }
    }

    /**
     * POST /';
        local.content &= lCase(arguments.obj.objectNamePlural);
        local.content &= '
     * Creates a new ';
        local.content &= lCase(arguments.obj.objectNameSingular);
        local.content &= '
     */
    function create() {
        local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= ' = model("';
        local.content &= arguments.obj.objectNameSingularC;
        local.content &= '").new(params.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= ');

        if (local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= '.save()) {
            local.response = {};
            local.response["';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= '"] = local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= ';
            renderWith(data=local.response, status=201);
        } else {
            renderWith(data={ error="Validation failed", errors=local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= '.allErrors() }, status=422);
        }
    }

    /**
     * PUT /';
        local.content &= lCase(arguments.obj.objectNamePlural);
        local.content &= '/:key
     * Updates an existing ';
        local.content &= lCase(arguments.obj.objectNameSingular);
        local.content &= '
     */
    function update() {
        local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= ' = model("';
        local.content &= arguments.obj.objectNameSingularC;
        local.content &= '").findByKey(params.key);

        if (IsObject(local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= ')) {
            local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= '.update(params.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= ');

            if (local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= '.hasErrors()) {
                renderWith(data={ error="Validation failed", errors=local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= '.allErrors() }, status=422);
            } else {
                local.response = {};
                local.response["';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= '"] = local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= ';
                renderWith(data=local.response);
            }
        } else {
            renderWith(data={ error="Record not found" }, status=404);
        }
    }

    /**
     * DELETE /';
        local.content &= lCase(arguments.obj.objectNamePlural);
        local.content &= '/:key
     * Deletes a ';
        local.content &= lCase(arguments.obj.objectNameSingular);
        local.content &= '
     */
    function delete() {
        local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= ' = model("';
        local.content &= arguments.obj.objectNameSingularC;
        local.content &= '").findByKey(params.key);

        if (IsObject(local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= ')) {
            local.';
        local.content &= arguments.obj.objectNameSingular;
        local.content &= '.delete();
            renderWith(data={}, status=204);
        } else {
            renderWith(data={ error="Record not found" }, status=404);
        }
    }
';

        // Add authentication if requested
        if (arguments.auth) {
            local.content &= '

    /**
     * Authentication check
     */
    private function authenticate() {
        local.token = getHttpRequestData().headers["Authorization"] ?: "";
        local.token = reReplaceNoCase(local.token, "^Bearer\s+", "");

        if (!len(local.token) || !isValidToken(local.token)) {
            renderWith(data={error="Unauthorized"}, status=401);
            abort;
        }
    }

    /**
     * Validate authentication token
     *
     * IMPORTANT: This is a placeholder that returns true for testing.
     * You MUST implement proper token validation before deploying to production!
     *
     * Examples:
     * - Check token against database
     * - Verify JWT signature and expiration
     * - Validate API key
     */
    private function isValidToken(required string token) {
        // TODO: Implement your token validation logic
        // For now, return true to allow testing - CHANGE THIS IN PRODUCTION!
        return true;

        // Example JWT validation (requires jwt-cfml library):
        // try {
        //     local.decoded = jwt.verify(arguments.token, application.jwtSecret);
        //     return structKeyExists(local.decoded, "sub");
        // } catch (any e) {
        //     return false;
        // }

        // Example database token validation:
        // local.user = model("User").findOne(where="apiToken = ''##arguments.token##''");
        // return isObject(local.user);
    }';
        }

        // Add sorting helper if requested
        if (arguments.sorting) {
            local.content &= '

    /**
     * Parse sort parameter into ORDER BY clause
     * Format: ?sort=name,-price (prefix with - for DESC)
     */
    private function parseSort(required string sort) {
        local.allowedFields = ["id", "createdAt", "updatedAt"]; // TODO: Add your model fields
        local.parts = listToArray(arguments.sort);
        local.order = [];

        for (local.part in local.parts) {
            local.desc = left(local.part, 1) == "-";
            local.field = local.desc ? mid(local.part, 2, len(local.part)) : local.part;

            if (arrayFindNoCase(local.allowedFields, local.field)) {
                arrayAppend(local.order, local.field & (local.desc ? " DESC" : " ASC"));
            }
        }

        return arrayLen(local.order) ? arrayToList(local.order) : "id ASC";
    }';
        }

        // Add filtering helper if requested
        if (arguments.filtering) {
            local.content &= '

    /**
     * Parse filter parameters into WHERE clause
     * Format: ?filter[name]=value&filter[minPrice]=10
     */
    private function parseFilter(required struct filter) {
        local.where = [];
        local.params = {};

        // TODO: Add your filtering logic based on model fields
        // Example:
        // if (structKeyExists(arguments.filter, "name")) {
        //     arrayAppend(local.where, "name LIKE :name");
        //     local.params.name = "%##arguments.filter.name##%";
        // }

        return structKeyExists(local, "where") && arrayLen(local.where) ? arrayToList(local.where, " AND ") : "";
    }';
        }

        local.content &= '

    /**
     * Clear any output buffer to prevent whitespace before XML/JSON
     */
    private function clearOutputBuffer() {
        // Clear any whitespace that may have been output
        // Use cfcontent reset to clear everything including whitespace
        content reset="true";
    }

    /**
     * Set Response Format
     */
    private function setResponseFormat() {
        params.format = "';
        local.content &= arguments.format;
        local.content &= '";
    }

}';

        return local.content;
    }

    /**
     * Add routes to config/routes.cfm automatically
     */
    private function addRoutesToConfig(
        required string resourceName,
        required string namespace,
        required string version
    ) {
        local.routesPath = fileSystemUtil.resolvePath("config/routes.cfm");

        if (!fileExists(local.routesPath)) {
            detailOutput.error("Routes file not found: #local.routesPath#");
            return;
        }

        // Read existing routes
        local.routesContent = fileRead(local.routesPath);

        // Build the route definition
        local.routeDefinition = buildRouteDefinition(
            resourceName = arguments.resourceName,
            namespace = arguments.namespace,
            version = arguments.version
        );

        // Check if route already exists
        if (find(arguments.resourceName, local.routesContent)) {
            detailOutput.line("Route for '#arguments.resourceName#' may already exist. Skipping...");
            return;
        }

        // Find the position to insert (before wildcard or final .end())
        local.insertPosition = 0;

        // Try to find .wildcard() first (preferred insertion point)
        if (find(".wildcard()", local.routesContent)) {
            local.insertPosition = find(".wildcard()", local.routesContent);
        } else if (find(".end()", local.routesContent)) {
            // Insert before the final .end() if no wildcard found
            // Find the LAST occurrence of .end()
            local.lastEndPos = 0;
            local.searchPos = 1;
            while (find(".end()", local.routesContent, local.searchPos)) {
                local.lastEndPos = find(".end()", local.routesContent, local.searchPos);
                local.searchPos = local.lastEndPos + 1;
            }
            local.insertPosition = local.lastEndPos;
        }

        if (local.insertPosition > 0) {
            // Insert route before .end() or .wildcard()
            local.beforeEnd = left(local.routesContent, local.insertPosition - 1);
            local.afterEnd = mid(local.routesContent, local.insertPosition, len(local.routesContent));

            // Add proper indentation and newlines
            local.newRoutesContent = local.beforeEnd & chr(10) & chr(10) & local.routeDefinition & chr(10) & local.afterEnd;

            // Write updated routes
            fileWrite(local.routesPath, local.newRoutesContent);
            detailOutput.create("config/routes.cfm (updated)", true);
        } else {
            detailOutput.error("Could not find insertion point in routes.cfm. Please add routes manually.");
        }
    }

    /**
     * Build the route definition string
     */
    private function buildRouteDefinition(
        required string resourceName,
        required string namespace,
        required string version
    ) {
        local.indent = "    ";
        local.routeDef = "";

        if (len(arguments.namespace)) {
            local.routeDef &= chr(10) & local.indent & "// #uCase(arguments.namespace)# Routes" & chr(10);

            if (len(arguments.version)) {
                // Nested namespace with version
                local.routeDef &= local.indent & '.namespace("#arguments.namespace#")' & chr(10);
                local.routeDef &= local.indent & local.indent & '.namespace("#arguments.version#")' & chr(10);
                local.routeDef &= local.indent & local.indent & local.indent & '.resources("#arguments.resourceName#")' & chr(10);
                local.routeDef &= local.indent & local.indent & '.end()' & chr(10);
                local.routeDef &= local.indent & '.end()';
            } else {
                // Just namespace, no version
                local.routeDef &= local.indent & '.namespace("#arguments.namespace#")' & chr(10);
                local.routeDef &= local.indent & local.indent & '.resources("#arguments.resourceName#")' & chr(10);
                local.routeDef &= local.indent & '.end()';
            }
        } else {
            // No namespace - direct resources
            local.routeDef &= chr(10) & local.indent & "// #arguments.resourceName# Routes" & chr(10);
            local.routeDef &= local.indent & '.resources("#arguments.resourceName#")';
        }

        return local.routeDef;
    }
}
