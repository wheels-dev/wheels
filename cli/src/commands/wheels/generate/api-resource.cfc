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
        // Reconstruct arguments for handling --prefixed options
        arguments = reconstructArgs(arguments);

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
            "Review the generated controller at #local.controllerFilePath#"
        ];

        // Add route configuration
        local.routeConfig = "resources(name='#lCase(local.obj.objectNamePlural)#', except='new,edit')";
        if (len(arguments.namespace)) {
            local.routeConfig = "namespace(name='#arguments.namespace#', function() {" & chr(10);
            if (len(arguments.version)) {
                local.routeConfig &= "    namespace(name='#arguments.version#', function() {" & chr(10);
                local.routeConfig &= "        resources(name='#lCase(local.obj.objectNamePlural)#', except='new,edit');" & chr(10);
                local.routeConfig &= "    });" & chr(10);
            } else {
                local.routeConfig &= "    resources(name='#lCase(local.obj.objectNamePlural)#', except='new,edit');" & chr(10);
            }
            local.routeConfig &= "})";
        }
        arrayAppend(nextSteps, "Add route to config/routes.cfm: #local.routeConfig#");
        arrayAppend(nextSteps, "Test your API endpoints");

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
        local.content = 'component extends="wheels.Controller" {

    function config() {
        provides("#arguments.format#");
        filters(through="setJsonResponse");';

        if (arguments.auth) {
            local.content &= chr(10) & '        filters(through="authenticate", except="index,show");';
        }

        local.content &= '
    }

    /**
     * GET /#lCase(arguments.obj.objectNamePlural)#
     * Returns a list of all #lCase(arguments.obj.objectNamePlural)#
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

        local.#arguments.obj.objectNamePlural# = model("#arguments.obj.objectNameSingularC#").findAll(';

        if (arguments.filtering || arguments.sorting || arguments.pagination) {
            local.content &= 'argumentCollection=local.options';
        }

        local.content &= ');';

        if (arguments.pagination) {
            local.content &= '

        local.response = {
            data = local.#arguments.obj.objectNamePlural#,
            meta = {
                pagination = {
                    page = local.#arguments.obj.objectNamePlural#.currentPage ?: local.page,
                    perPage = local.perPage,
                    total = local.#arguments.obj.objectNamePlural#.totalRecords ?: 0,
                    pages = local.#arguments.obj.objectNamePlural#.totalPages ?: 1
                }
            }
        };

        renderWith(data=local.response);';
        } else {
            local.content &= '
        renderWith(data={ #arguments.obj.objectNamePlural#=local.#arguments.obj.objectNamePlural# });';
        }

        local.content &= '
    }

    /**
     * GET /#lCase(arguments.obj.objectNamePlural)#/:key
     * Returns a specific #lCase(arguments.obj.objectNameSingular)# by ID
     */
    function show() {
        local.#arguments.obj.objectNameSingular# = model("#arguments.obj.objectNameSingularC#").findByKey(params.key);

        if (IsObject(local.#arguments.obj.objectNameSingular#)) {
            renderWith(data={ #arguments.obj.objectNameSingular#=local.#arguments.obj.objectNameSingular# });
        } else {
            renderWith(data={ error="Record not found" }, status=404);
        }
    }

    /**
     * POST /#lCase(arguments.obj.objectNamePlural)#
     * Creates a new #lCase(arguments.obj.objectNameSingular)#
     */
    function create() {
        local.#arguments.obj.objectNameSingular# = model("#arguments.obj.objectNameSingularC#").new(params.#arguments.obj.objectNameSingular#);

        if (local.#arguments.obj.objectNameSingular#.save()) {
            renderWith(data={ #arguments.obj.objectNameSingular#=local.#arguments.obj.objectNameSingular# }, status=201);
        } else {
            renderWith(data={ error="Validation failed", errors=local.#arguments.obj.objectNameSingular#.allErrors() }, status=422);
        }
    }

    /**
     * PUT /#lCase(arguments.obj.objectNamePlural)#/:key
     * Updates an existing #lCase(arguments.obj.objectNameSingular)#
     */
    function update() {
        local.#arguments.obj.objectNameSingular# = model("#arguments.obj.objectNameSingularC#").findByKey(params.key);

        if (IsObject(local.#arguments.obj.objectNameSingular#)) {
            local.#arguments.obj.objectNameSingular#.update(params.#arguments.obj.objectNameSingular#);

            if (local.#arguments.obj.objectNameSingular#.hasErrors()) {
                renderWith(data={ error="Validation failed", errors=local.#arguments.obj.objectNameSingular#.allErrors() }, status=422);
            } else {
                renderWith(data={ #arguments.obj.objectNameSingular#=local.#arguments.obj.objectNameSingular# });
            }
        } else {
            renderWith(data={ error="Record not found" }, status=404);
        }
    }

    /**
     * DELETE /#lCase(arguments.obj.objectNamePlural)#/:key
     * Deletes a #lCase(arguments.obj.objectNameSingular)#
     */
    function delete() {
        local.#arguments.obj.objectNameSingular# = model("#arguments.obj.objectNameSingularC#").findByKey(params.key);

        if (IsObject(local.#arguments.obj.objectNameSingular#)) {
            local.#arguments.obj.objectNameSingular#.delete();
            renderWith(data={}, status=204);
        } else {
            renderWith(data={ error="Record not found" }, status=404);
        }
    }

    /**
     * Set Response to JSON
     */
    private function setJsonResponse() {
        params.format = "#arguments.format#";
    }';

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
        }
    }

    /**
     * Validate authentication token
     */
    private function isValidToken(required string token) {
        // TODO: Implement your token validation logic
        // Example: Check against database, verify JWT, etc.
        return false;
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

}';

        return local.content;
    }
}
