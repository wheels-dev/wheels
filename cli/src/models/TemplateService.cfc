component {
    
    property name="helpers" inject="helpers@wheels-cli";
    
    /**
     * Generate file from template
     */
    function generateFromTemplate(
        required string template,
        required string destination,
        required struct context,
        string baseDirectory = ""
    ) {
        // Try to find the template in the app/snippets directory first
        var appSnippetsPath = expandPath("app/snippets/#arguments.template#");
        var templatePath = "";
        
        if (fileExists(appSnippetsPath)) {
            templatePath = appSnippetsPath;
        } else {
            // Fall back to module templates
            templatePath = expandPath("/wheels-cli/templates/#arguments.template#");
        }
        var destinationPath = resolvePath(arguments.destination, arguments.baseDirectory);
        
        if (!fileExists(templatePath)) {
            throw("Template not found: #arguments.template#");
        }
        
        var templateContent = fileRead(templatePath);
        var processedContent = processTemplate(templateContent, arguments.context);
        
        // Ensure destination directory exists
        var destinationDir = getDirectoryFromPath(destinationPath);
        if (!directoryExists(destinationDir)) {
            directoryCreate(destinationDir, true);
        }
        
        fileWrite(destinationPath, processedContent);
        
        return destinationPath;
    }
    
    /**
     * Process template with context replacements
     */
    private function processTemplate(content, context) {
        var processed = arguments.content;
        
        // Replace {{variable}} with context values
        var skipKeys = ["belongsTo", "hasMany", "hasOne", "belongsToRelationships", "hasManyRelationships"];
        for (var key in arguments.context) {
            // Skip special keys that need custom processing
            if (arrayFindNoCase(skipKeys, key)) {
                continue;
            }
            var value = arguments.context[key];
            // Handle arrays and structs differently
            if (isArray(value) || isStruct(value)) {
                // Skip arrays and structs in the generic replacement
                continue;
            }
            // Convert to string if it's a simple value
            if (isSimpleValue(value)) {
                processed = reReplace(processed, "\{\{#key#\}\}", toString(value), "all");
            }
        }
        
        // Handle special transformations
        if (structKeyExists(arguments.context, "name")) {
            var name = arguments.context.name;
            
            // Generate variations of the name
            processed = reReplace(processed, "\{\{nameSingular\}\}", name, "all");
            processed = reReplace(processed, "\{\{namePlural\}\}", variables.helpers.pluralize(name), "all");
            processed = reReplace(processed, "\{\{nameSingularLower\}\}", lCase(name), "all");
            processed = reReplace(processed, "\{\{namePluralLower\}\}", lCase(variables.helpers.pluralize(name)), "all");
            processed = reReplace(processed, "\{\{nameSingularUpper\}\}", uCase(name), "all");
            processed = reReplace(processed, "\{\{namePluralUpper\}\}", uCase(variables.helpers.pluralize(name)), "all");
        }
        
        // Process relationships (check both lowercase and uppercase keys)
        var belongsToValue = "";
        if (structKeyExists(arguments.context, "belongsTo")) {
            belongsToValue = arguments.context.belongsTo;
        } else if (structKeyExists(arguments.context, "BELONGSTO")) {
            belongsToValue = arguments.context.BELONGSTO;
        }
        
        if (len(belongsToValue)) {
            var belongsToCode = generateBelongsToCode(belongsToValue);
            processed = reReplace(processed, "\{\{belongsToRelationships\}\}", belongsToCode, "all");
        } else {
            processed = reReplace(processed, "\{\{belongsToRelationships\}\}", "", "all");
        }
        
        var hasManyValue = "";
        if (structKeyExists(arguments.context, "hasMany")) {
            hasManyValue = arguments.context.hasMany;
        } else if (structKeyExists(arguments.context, "HASMANY")) {
            hasManyValue = arguments.context.HASMANY;
        }
        
        if (len(hasManyValue)) {
            var hasManyCode = generateHasManyCode(hasManyValue);
            processed = reReplace(processed, "\{\{hasManyRelationships\}\}", hasManyCode, "all");
        } else {
            processed = reReplace(processed, "\{\{hasManyRelationships\}\}", "", "all");
        }
        
        var hasOneValue = "";
        if (structKeyExists(arguments.context, "hasOne")) {
            hasOneValue = arguments.context.hasOne;
        } else if (structKeyExists(arguments.context, "HASONE")) {
            hasOneValue = arguments.context.HASONE;
        }
        
        if (len(hasOneValue)) {
            var hasOneCode = generateHasOneCode(hasOneValue);
            processed = reReplace(processed, "\{\{hasOneRelationships\}\}", hasOneCode, "all");
        } else {
            processed = reReplace(processed, "\{\{hasOneRelationships\}\}", "", "all");
        }
        
        // Process attributes
        if (structKeyExists(arguments.context, "attributes") && len(arguments.context.attributes)) {
            var attributesStruct = parseAttributes(arguments.context.attributes);
            var validationCode = generateValidationCode(attributesStruct);
            processed = reReplace(processed, "\{\{validations\}\}", validationCode, "all");
        } else {
            processed = reReplace(processed, "\{\{validations\}\}", "", "all");
        }
        
        // Process actions for controllers
        if (structKeyExists(arguments.context, "actions") && isArray(arguments.context.actions)) {
            var actionsCode = generateActionsCode(arguments.context.actions);
            processed = replace(processed, "|Actions|", actionsCode, "all");
        } else {
            processed = replace(processed, "|Actions|", "", "all");
        }

        // Process description comment for controllers
        if (structKeyExists(arguments.context, "description") && len(trim(arguments.context.description))) {
            var descriptionComment = "/**" & chr(10) & " * " & arguments.context.description & chr(10) & " */" & chr(10);
            processed = replace(processed, "|DescriptionComment|", descriptionComment, "all");
        } else {
            processed = replace(processed, "|DescriptionComment|", "", "all");
        }

        // Process custom table name for models
        if (structKeyExists(arguments.context, "tableName") && len(trim(arguments.context.tableName))) {
            var tableNameCall = 'table("' & arguments.context.tableName & '");' & chr(10) & chr(9) & chr(9);
            processed = replace(processed, "|TableName|", tableNameCall, "all");
        } else {
            processed = replace(processed, "|TableName|", "", "all");
        }

        // Process form fields if properties are provided (must happen before object name replacements)
        if (structKeyExists(arguments.context, "properties") && isArray(arguments.context.properties) && arrayLen(arguments.context.properties) && structKeyExists(arguments.context, "modelName")) {
            var belongsToList = structKeyExists(arguments.context, "belongsTo") ? arguments.context.belongsTo : "";
            var formFieldsCode = generateFormFieldsCode(arguments.context.properties, arguments.context.modelName, belongsToList);
            processed = replace(processed, "|FormFields|", formFieldsCode, "all");
        } else {
            processed = replace(processed, "|FormFields|", "", "all");
        }
        
        // Process controller includes for associations
        if (structKeyExists(arguments.context, "belongsTo") && len(arguments.context.belongsTo)) {
            processed = addControllerIncludes(processed, arguments.context.belongsTo);
        }

        // Process CLI-Appends markers for index and show views BEFORE replacing object name placeholders
        if (structKeyExists(arguments.context, "properties") && isArray(arguments.context.properties) && arrayLen(arguments.context.properties)) {
            var belongsToList = structKeyExists(arguments.context, "belongsTo") ? arguments.context.belongsTo : "";

            // Process index view table headers
            if (find("<!--- CLI-Appends-thead-Here --->", processed)) {
                var theadCode = generateIndexTableHeaders(arguments.context.properties, belongsToList);
                processed = replace(processed, "<!--- CLI-Appends-thead-Here --->", theadCode, "all");
            }

            // Process index view table body
            if (find("<!--- CLI-Appends-tbody-Here --->", processed)) {
                var tbodyCode = generateIndexTableBody(arguments.context.properties, belongsToList);
                processed = replace(processed, "<!--- CLI-Appends-tbody-Here --->", tbodyCode, "all");
            }

            // Process show view properties - only for show.txt template, not for form templates
            if (find("<!--- CLI-Appends-Here --->", processed)) {
                if (structKeyExists(arguments.context, "action") && arguments.context.action == "show") {
                    var showCode = generateShowViewProperties(arguments.context.properties, arguments.context.modelName, belongsToList);
                    processed = replace(processed, "<!--- CLI-Appends-Here --->", showCode, "all");
                } else {
                    // Remove the marker from non-show templates (like forms) without adding content
                    processed = replace(processed, "<!--- CLI-Appends-Here --->", "", "all");
                }
            }
        }
        
        // Process pipe-delimited placeholders (used in CRUD templates) AFTER processing CLI-Appends
        // Generate object name variations from model or controller name
        if (structKeyExists(arguments.context, "modelName")) {
            var modelName = arguments.context.modelName;
            // Extract just the model name without namespace path for variable names
            var baseModelName = listLast(modelName, "/");
            processed = replace(processed, "|ObjectNameSingular|", lCase(baseModelName), "all");
            processed = replace(processed, "|ObjectNamePlural|", lCase(variables.helpers.pluralize(baseModelName)), "all");
            processed = replace(processed, "|ObjectNameSingularC|", baseModelName, "all");
            processed = replace(processed, "|ObjectNamePluralC|", variables.helpers.pluralize(baseModelName), "all");
        }
        
        return processed;
    }
    
    /**
     * Generate belongsTo relationship code
     */
    private function generateBelongsToCode(required string belongsTo) {
        var relationships = listToArray(arguments.belongsTo);
        var code = [];
        
        for (var rel in relationships) {
            arrayAppend(code, "		belongsTo('#trim(rel)#');");
        }
        
        return arrayToList(code, chr(10));
    }
    
    /**
     * Generate hasMany relationship code
     */
    private function generateHasManyCode(required string hasMany) {
        var relationships = listToArray(arguments.hasMany);
        var code = [];
        
        for (var rel in relationships) {
            arrayAppend(code, "		hasMany('#trim(rel)#');");
        }
        
        return arrayToList(code, chr(10));
    }
    
    /**
     * Generate hasOne relationship code
     */
    private function generateHasOneCode(required string hasOne) {
        var relationships = listToArray(arguments.hasOne);
        var code = [];
        
        for (var rel in relationships) {
            arrayAppend(code, "		hasOne('#trim(rel)#');");
        }
        
        return arrayToList(code, chr(10));
    }
    
    /**
     * Generate form fields code based on properties with association support
     */
    private function generateFormFieldsCode(required array properties, required string modelName, string belongsTo = "") {
        var fields = [];
        var objectName = lCase(arguments.modelName);

        // Build list of actual foreign key fields from belongsTo relationships
        var foreignKeys = [];
        if (len(arguments.belongsTo)) {
            var parents = listToArray(arguments.belongsTo);
            for (var parent in parents) {
                arrayAppend(foreignKeys, lCase(trim(parent)) & "Id");
            }
        }

        for (var prop in arguments.properties) {
            var fieldCode = "";
            var fieldName = prop.name;
            var fieldType = prop.keyExists("type") ? prop.type : "string";
            var fieldLabel = variables.helpers.capitalize(fieldName);

            // Check if this is an actual foreign key field from belongsTo relationships
            if (arrayFindNoCase(foreignKeys, fieldName)) {
                // This is a foreign key - generate a select field
                var associationName = left(fieldName, len(fieldName) - 2);
                var associationModel = variables.helpers.capitalize(associationName);
                fieldCode = '##select(objectName="|ObjectNameSingular|", property="#fieldName#", options=model("#associationModel#").findAll(), textField="name", valueField="id", includeBlank="Select #associationModel#", label="#fieldLabel#")##';
            } else {
                // Generate appropriate form field based on type
                switch(lCase(fieldType)) {
                    case "boolean":
                        fieldCode = '##checkBox(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
                        break;
                    case "text":
                    case "longtext":
                        fieldCode = '##textArea(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
                        break;
                    case "integer":
                    case "biginteger":
                    case "decimal":
                    case "float":
                        fieldCode = '##textField(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
                        break;
                    case "date":
                        fieldCode = '##dateSelect(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
                        break;
                    case "datetime":
                    case "timestamp":
                        fieldCode = '##dateTimeSelect(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
                        break;
                    case "time":
                        fieldCode = '##timeSelect(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
                        break;
                    default:
                        // Default to text field for string and unknown types
                        fieldCode = '##textField(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
                }
            }

            arrayAppend(fields, fieldCode);
        }

        return arrayToList(fields, chr(10));
    }
    
    /**
     * Parse attributes string into struct
     */
    private function parseAttributes(required string attributes) {
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
    
    /**
     * Generate validation code from attributes
     */
    private function generateValidationCode(required struct attributes) {
        var code = [];
        
        for (var attr in arguments.attributes) {
            var type = arguments.attributes[attr];
            
            switch (type) {
                case "email":
                    arrayAppend(code, "        validatesFormatOf(property='#attr#', type='email');");
                    break;
                case "integer":
                case "numeric":
                    arrayAppend(code, "        validatesNumericalityOf(property='#attr#');");
                    break;
                case "boolean":
                    arrayAppend(code, "        validatesInclusionOf(property='#attr#', list='true,false,0,1');");
                    break;
                default:
                    arrayAppend(code, "        validatesPresenceOf(property='#attr#');");
            }
        }
        
        return arrayToList(code, chr(10));
    }
    
    /**
     * Generate controller actions code
     */
    private function generateActionsCode(required array actions) {
        var code = [];
        
        for (var action in arguments.actions) {
            arrayAppend(code, "");
            arrayAppend(code, "    /**");
            arrayAppend(code, "     * #action# action");
            arrayAppend(code, "     */");
            arrayAppend(code, "    function #action#() {");
            arrayAppend(code, "        // TODO: Implement #action# action");
            arrayAppend(code, "    }");
        }
        
        return arrayToList(code, chr(10));
    }
    
    /**
     * Generate table headers for index view with association support
     */
    private function generateIndexTableHeaders(required array properties, string belongsTo = "") {
        var headers = [];

        // Build list of actual foreign key fields from belongsTo relationships
        var foreignKeys = [];
        if (len(arguments.belongsTo)) {
            var parents = listToArray(arguments.belongsTo);
            for (var parent in parents) {
                arrayAppend(foreignKeys, lCase(trim(parent)) & "Id");
            }
        }

        for (var prop in arguments.properties) {
            var headerName = variables.helpers.capitalize(prop.name);

            // Check if this is an actual foreign key field from belongsTo relationships
            if (arrayFindNoCase(foreignKeys, prop.name)) {
                // Show association name instead of foreign key
                var associationName = left(prop.name, len(prop.name) - 2);
                headerName = variables.helpers.capitalize(associationName);
            }

            arrayAppend(headers, '<th>#headerName#</th>');
        }

        return arrayToList(headers, chr(10) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9));
    }
    
    /**
     * Generate table body cells for index view with association support
     */
    private function generateIndexTableBody(required array properties, string belongsTo = "") {
        var cells = [];

        // Build list of actual foreign key fields from belongsTo relationships
        var foreignKeys = [];
        if (len(arguments.belongsTo)) {
            var parents = listToArray(arguments.belongsTo);
            for (var parent in parents) {
                arrayAppend(foreignKeys, lCase(trim(parent)) & "Id");
            }
        }

        for (var prop in arguments.properties) {
            var cellCode = '<td>' & chr(10);

            // Check if this is an actual foreign key field from belongsTo relationships
            if (arrayFindNoCase(foreignKeys, prop.name)) {
                // Display association name instead of foreign key ID
                var associationName = left(prop.name, len(prop.name) - 2);
                cellCode &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '##|ObjectNamePlural|.' & associationName & '.name##' & chr(10);
            } else {
                cellCode &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '##|ObjectNamePlural|.#prop.name###' & chr(10);
            }

            cellCode &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '</td>';
            arrayAppend(cells, cellCode);
        }

        return arrayToList(cells, chr(10) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9));
    }
    
    /**
     * Generate property display for show view with association support
     */
    private function generateShowViewProperties(required array properties, required string modelName, string belongsTo = "") {
        var displayCode = [];
        var objectName = lCase(arguments.modelName);

        // Build list of actual foreign key fields from belongsTo relationships
        var foreignKeys = [];
        if (len(arguments.belongsTo)) {
            var parents = listToArray(arguments.belongsTo);
            for (var parent in parents) {
                arrayAppend(foreignKeys, lCase(trim(parent)) & "Id");
            }
        }

        for (var prop in arguments.properties) {
            var propDisplay = '<p>' & chr(10);

            // Check if this is an actual foreign key field from belongsTo relationships
            if (arrayFindNoCase(foreignKeys, prop.name)) {
                // Display association name instead of foreign key ID
                var associationName = left(prop.name, len(prop.name) - 2);
                var displayLabel = variables.helpers.capitalize(associationName);
                propDisplay &= chr(9) & '<strong>#displayLabel#:</strong> ##encodeForHTML(|ObjectNameSingular|.' & associationName & '.name)##' & chr(10);
            } else {
                propDisplay &= chr(9) & '<strong>#variables.helpers.capitalize(prop.name)#:</strong> ##encodeForHTML(|ObjectNameSingular|.#prop.name#)##' & chr(10);
            }

            propDisplay &= '</p>';
            arrayAppend(displayCode, propDisplay);
        }

        // Add action links after properties
        arrayAppend(displayCode, '');
        arrayAppend(displayCode, '<p>');
        arrayAppend(displayCode, chr(9) & '##linkTo(route="edit|ObjectNameSingularC|", key=|ObjectNameSingular|.key(), text="Edit", class="btn btn-primary")##');
        arrayAppend(displayCode, chr(9) & '##linkTo(route="|ObjectNamePlural|", text="Back to List", class="btn btn-default")##');
        arrayAppend(displayCode, '</p>');
        
        return arrayToList(displayCode, chr(10));
    }
    
    /**
     * Resolve a file path
     */
    private function resolvePath(path, baseDirectory = "") {
        // Prepend app/ to common paths if not already present
        var appPath = arguments.path;
        if (!findNoCase("app/", appPath) && !findNoCase("tests/", appPath)) {
            // Common app directories
            if (reFind("^(controllers|models|views|migrator)/", appPath)) {
                appPath = "app/" & appPath;
            }
        }
        
        // If path is already absolute, return it
        if (left(appPath, 1) == "/" || mid(appPath, 2, 1) == ":") {
            return appPath;
        }
        
        // Build absolute path from current working directory
        // Use provided base directory or fall back to expandPath
        var baseDir = len(arguments.baseDirectory) ? arguments.baseDirectory : expandPath(".");
        
        // Ensure we have a trailing slash
        if (right(baseDir, 1) != "/") {
            baseDir &= "/";
        }
        
        return baseDir & appPath;
    }

    /**
     * Add includes to controller methods for associations
     */
    private function addControllerIncludes(required string template, required string belongsTo) {
        var processed = arguments.template;
        var associations = listToArray(arguments.belongsTo);
        var includeList = [];

        // Build include list from belongsTo associations
        for (var association in associations) {
            arrayAppend(includeList, lCase(association));
        }

        var includeParam = 'include="' & arrayToList(includeList) & '"';

        // Add includes to CRUD controller patterns
        // Add includes to findAll() calls (index action)
        processed = replace(processed, '=model("|ObjectNameSingular|").findAll();', '=model("|ObjectNameSingular|").findAll(' & includeParam & ');', 'all');

        // Add includes to findByKey() calls (show and edit actions)
        processed = replace(processed, '=model("|ObjectNameSingular|").findByKey(params.key);', '=model("|ObjectNameSingular|").findByKey(params.key, ' & includeParam & ');', 'all');

        // Add includes to API controller patterns
        // API index: local.|ObjectNamePlural| = model("|ObjectNameSingular|").findAll();
        processed = replace(processed, 'local.|ObjectNamePlural| = model("|ObjectNameSingular|").findAll();', 'local.|ObjectNamePlural| = model("|ObjectNameSingular|").findAll(' & includeParam & ');', 'all');

        // API show/update/delete: local.|ObjectNameSingular| = model("|ObjectNameSingular|").findByKey(params.key);
        processed = replace(processed, 'local.|ObjectNameSingular| = model("|ObjectNameSingular|").findByKey(params.key);', 'local.|ObjectNameSingular| = model("|ObjectNameSingular|").findByKey(params.key, ' & includeParam & ');', 'all');

        return processed;
    }
}