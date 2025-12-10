/**
 * Visualize the current database schema
 * 
 * {code:bash}
 * wheels db:schema
 * wheels db:schema --format=text
 * wheels db:schema --output=schema.txt
 * {code}
 */
component extends="../base" {

    /**
     * @format Output format (text, json, or sql)
     * @output File to write schema to (if not specified, outputs to console)
     * @tables Comma-delimited list of tables to include (defaults to all)
     */
    function run(
        string format="text",
        string output="",
        string tables=""
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Database Schema");
        print.line();
        
        // Validate format
        local.validFormats = ["text", "json", "sql"];
        if (!arrayContains(local.validFormats, lCase(arguments.format))) {
            error("Invalid format: #arguments.format#. Please choose from: #arrayToList(local.validFormats)#");
        }
        
        // Create URL parameters
        local.urlParams = "&command=dbSchema&format=#lCase(arguments.format)#";
        
        if (len(trim(arguments.tables))) {
            local.urlParams &= "&tables=#urlEncodedFormat(arguments.tables)#";
        }
        
        // Send command to get schema
        print.line("Retrieving database schema...");
        local.result = $sendToCliCommand(urlstring=local.urlParams);
        if(!local.result.success){
            return;
        }
        
        // Process and display results
        if (structKeyExists(local.result, "success") && local.result.success && structKeyExists(local.result, "schema")) {
            local.schema = local.result.schema;
            
            // Output schema according to format
            switch (lCase(arguments.format)) {
                case "json":
                    local.output = serializeJSON(local.schema);
                    break;
                case "sql":
                    local.output = local.schema;
                    break;
                case "text":
                default:
                    local.output = formatSchemaAsText(local.schema);
                    break;
            }
            
            // Write to file or display on console
            if (len(trim(arguments.output))) {
                local.outputPath = fileSystemUtil.resolvePath(arguments.output);
                file action='write' file='#local.outputPath#' mode='777' output='#local.output#';
                print.boldGreenLine("Schema exported to: #arguments.output#");
            } else {
                print.line();
                print.boldYellowLine("Database Schema:");
                print.line();
                print.line(local.output);
            }
        } else {
            print.boldRedLine("Failed to retrieve database schema");
            if (structKeyExists(local.result, "message")) {
                print.redLine(local.result.message);
            }
        }
        
        print.line();
    }
    
    /**
     * Format schema information as readable text
     */
    private string function formatSchemaAsText(required any schema) {
        local.output = "";
        
        // Handle different schema formats
        if (isStruct(arguments.schema) && structKeyExists(arguments.schema, "tables")) {
            // Process structured schema information
            local.tables = arguments.schema.tables;
            
            for (local.tableName in local.tables) {
                local.table = local.tables[local.tableName];
                local.output &= "TABLE: #uCase(local.tableName)#" & chr(10);
                local.output &= repeatString("-", 80) & chr(10);
                
                // Process columns
                if (structKeyExists(local.table, "columns") && isArray(local.table.columns)) {
                    for (local.column in local.table.columns) {
                        local.nullable = structKeyExists(local.column, "nullable") && local.column.nullable ? "NULL" : "NOT NULL";
                        local.default = structKeyExists(local.column, "default") && len(local.column.default) ? "DEFAULT " & local.column.default : "";
                        local.primaryKey = structKeyExists(local.column, "primaryKey") && local.column.primaryKey ? "PRIMARY KEY" : "";
                        
                        local.line = "  #local.column.name# #local.column.type#";
                        if (len(local.nullable)) local.line &= " #local.nullable#";
                        if (len(local.default)) local.line &= " #local.default#";
                        if (len(local.primaryKey)) local.line &= " #local.primaryKey#";
                        
                        local.output &= local.line & chr(10);
                    }
                }
                
                // Process indexes
                if (structKeyExists(local.table, "indexes") && isArray(local.table.indexes)) {
                    local.output &= chr(10) & "  INDEXES:" & chr(10);
                    for (local.index in local.table.indexes) {
                        local.unique = structKeyExists(local.index, "unique") && local.index.unique ? "UNIQUE " : "";
                        local.columns = isArray(local.index.columns) ? arrayToList(local.index.columns) : local.index.columns;
                        
                        local.output &= "  - #local.unique#INDEX #local.index.name# (#local.columns#)" & chr(10);
                    }
                }
                
                // Process foreign keys
                if (structKeyExists(local.table, "foreignKeys") && isArray(local.table.foreignKeys)) {
                    local.output &= chr(10) & "  FOREIGN KEYS:" & chr(10);
                    for (local.fk in local.table.foreignKeys) {
                        local.output &= "  - #local.fk.name# (#local.fk.column#) REFERENCES #local.fk.referenceTable# (#local.fk.referenceColumn#)" & chr(10);
                    }
                }
                
                local.output &= chr(10) & chr(10);
            }
        } else {
            // If we received plain text or SQL, just return it
            local.output = isSimpleValue(arguments.schema) ? arguments.schema : serializeJSON(arguments.schema);
        }
        
        return local.output;
    }
}