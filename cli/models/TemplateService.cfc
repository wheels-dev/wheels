component {
    
    property name="fileSystemUtil" inject="FileSystem@commandbox-core";
    
    /**
     * Generate file from template
     */
    function generateFromTemplate(
        required string template,
        required string destination,
        required struct context
    ) {
        var templatePath = expandPath("/wheels-cli/templates/#arguments.template#");
        var destinationPath = resolvePath(arguments.destination);
        
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
        for (var key in arguments.context) {
            var value = arguments.context[key];
            processed = reReplace(processed, "\{\{#key#\}\}", value, "all");
        }
        
        // Handle special transformations
        if (structKeyExists(arguments.context, "name")) {
            var name = arguments.context.name;
            
            // Generate variations of the name
            processed = reReplace(processed, "\{\{nameSingular\}\}", name, "all");
            processed = reReplace(processed, "\{\{namePlural\}\}", pluralize(name), "all");
            processed = reReplace(processed, "\{\{nameSingularLower\}\}", lCase(name), "all");
            processed = reReplace(processed, "\{\{namePluralLower\}\}", lCase(pluralize(name)), "all");
            processed = reReplace(processed, "\{\{nameSingularUpper\}\}", uCase(name), "all");
            processed = reReplace(processed, "\{\{namePluralUpper\}\}", uCase(pluralize(name)), "all");
        }
        
        // Process relationships
        if (structKeyExists(arguments.context, "belongsTo") && len(arguments.context.belongsTo)) {
            var belongsToCode = generateBelongsToCode(arguments.context.belongsTo);
            processed = reReplace(processed, "\{\{belongsToRelationships\}\}", belongsToCode, "all");
        } else {
            processed = reReplace(processed, "\{\{belongsToRelationships\}\}", "", "all");
        }
        
        if (structKeyExists(arguments.context, "hasMany") && len(arguments.context.hasMany)) {
            var hasManyCode = generateHasManyCode(arguments.context.hasMany);
            processed = reReplace(processed, "\{\{hasManyRelationships\}\}", hasManyCode, "all");
        } else {
            processed = reReplace(processed, "\{\{hasManyRelationships\}\}", "", "all");
        }
        
        // Process attributes
        if (structKeyExists(arguments.context, "attributes") && len(arguments.context.attributes)) {
            var attributesStruct = parseAttributes(arguments.context.attributes);
            var validationCode = generateValidationCode(attributesStruct);
            processed = reReplace(processed, "\{\{validations\}\}", validationCode, "all");
        } else {
            processed = reReplace(processed, "\{\{validations\}\}", "", "all");
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
            arrayAppend(code, "        belongsTo('#trim(rel)#');");
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
            arrayAppend(code, "        hasMany('#trim(rel)#');");
        }
        
        return arrayToList(code, chr(10));
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
     * Simple pluralization helper
     */
    private function pluralize(required string word) {
        var singular = trim(arguments.word);
        
        // Handle common irregular plurals
        var irregulars = {
            "person" = "people",
            "child" = "children",
            "man" = "men",
            "woman" = "women",
            "tooth" = "teeth",
            "foot" = "feet",
            "mouse" = "mice",
            "goose" = "geese"
        };
        
        if (structKeyExists(irregulars, lCase(singular))) {
            return irregulars[lCase(singular)];
        }
        
        // Handle regular pluralization rules
        if (reFind("(s|ss|sh|ch|x|z)$", singular)) {
            return singular & "es";
        } else if (reFind("y$", singular) && !reFind("[aeiou]y$", singular)) {
            return left(singular, len(singular) - 1) & "ies";
        } else if (reFind("f$", singular)) {
            return left(singular, len(singular) - 1) & "ves";
        } else if (reFind("fe$", singular)) {
            return left(singular, len(singular) - 2) & "ves";
        } else {
            return singular & "s";
        }
    }
}