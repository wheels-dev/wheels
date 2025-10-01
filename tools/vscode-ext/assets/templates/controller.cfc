component extends="Controller" {

    function config() {
        // Set filters, verifies parameters, provides formats, etc.
        // Example:
        // filters(through="authenticate", except="index,show");
        // verifies(only="show,edit,update,delete", params="key", paramsTypes="integer");
        // provides("html,json");
    }

    function index() {
        // List all ${modelNamePlural}
        ${modelNamePlural} = model("${modelName}").findAll(order="${defaultSortColumn} ASC");

        // Uncomment to provide JSON API
        // renderWith(${modelNamePlural});
    }

    function show() {
        // Display a single ${modelNameLower}
        // ${modelNameLower} is set by findRecord() filter or:
        // ${modelNameLower} = model("${modelName}").findByKey(params.key);
    }

    function new() {
        // Display form for creating a new ${modelNameLower}
        ${modelNameLower} = model("${modelName}").new();
    }

    function create() {
        // Create a new ${modelNameLower}
        ${modelNameLower} = model("${modelName}").new(params.${modelNameLower});

        if (${modelNameLower}.save()) {
            flashInsert(success="${modelName} created successfully.");
            redirectTo(route="${routeName}", key=${modelNameLower}.key());
        } else {
            flashInsert(error="Please correct the errors below.");
            renderView(action="new");
        }
    }

    function edit() {
        // Display form for editing an existing ${modelNameLower}
        // ${modelNameLower} is set by findRecord() filter or:
        // ${modelNameLower} = model("${modelName}").findByKey(params.key);
    }

    function update() {
        // Update an existing ${modelNameLower}
        ${modelNameLower} = model("${modelName}").findByKey(params.key);

        if (${modelNameLower}.update(params.${modelNameLower})) {
            flashInsert(success="${modelName} updated successfully.");
            redirectTo(route="${routeName}", key=${modelNameLower}.key());
        } else {
            flashInsert(error="Please correct the errors below.");
            renderView(action="edit");
        }
    }

    function delete() {
        // Delete an existing ${modelNameLower}
        ${modelNameLower} = model("${modelName}").findByKey(params.key);

        if (${modelNameLower}.delete()) {
            flashInsert(success="${modelName} deleted successfully.");
        } else {
            flashInsert(error="Unable to delete ${modelNameLower}.");
        }

        redirectTo(route="${routeNamePlural}");
    }
}