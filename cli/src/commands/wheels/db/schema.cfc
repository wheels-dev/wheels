/**
 * Visualize the current database schema
 * 
 * {code:bash}
 * wheels db:schema
 * wheels db:schema --format=text
 * wheels db:schema --format=json --save --file=schema.json
 * wheels db:schema --format=sql --save
 * wheels db:schema --tables=users,posts
 * wheels db:schema --engine=postgresql
 * {code}
 */
component extends="../base" {

    /**
     * @format Output format (text, json, or sql)
     * @save Save output to file instead of console
     * @file File path to write schema to (when using --save)
     * @engine Database engine to use
     * @tables Comma-delimited list of tables to include (defaults to all)
     */
    function run(
        string format="sql",
        boolean save=false,
        string file="",
        string engine="default",
        string tables=""
    ) {
        arguments = reconstructArgs(arguments);
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
        local.urlParams = "&command=dbSchema";
        
        if (len(trim(arguments.tables))) {
            local.urlParams &= "&tables=#urlEncodedFormat(arguments.tables)#";
        }
        
        if (arguments.engine != "default") {
            local.urlParams &= "&engine=#urlEncodedFormat(arguments.engine)#";
        }
        
        // Send command to get schema
        print.line("Retrieving database schema...");
        local.result = $sendToCliCommand(urlstring=local.urlParams);
        
        // Process and display results
        if (structKeyExists(local.result, "success") && local.result.success && structKeyExists(local.result, "SCHEMA")) {
            local.schema = local.result.SCHEMA;
            
            // Filter tables if specified
            if (len(trim(arguments.tables))) {
                local.tableList = listToArray(lCase(trim(arguments.tables)));
                local.filteredTables = [];
                
                for (local.table in local.schema.TABLES) {
                    if (arrayContainsNoCase(local.tableList, local.table.NAME)) {
                        arrayAppend(local.filteredTables, local.table);
                    }
                }
                
                local.schema.TABLES = local.filteredTables;
                local.schema.TABLECOUNT = arrayLen(local.filteredTables);
            }
            
            // Output schema according to format
            switch (lCase(arguments.format)) {
                case "json":
                    local.output = serializeJSON(local.schema);
                    break;
                case "sql":
                    local.output = generateSQLFromSchema(local.schema, arguments.engine);
                    break;
                case "text":
                default:
                    local.output = formatSchemaAsText(local.schema);
                    break;
            }
            
            // Write to file or display on console
            if (arguments.save) {
                // Determine file path
                local.outputPath = "";
                if (len(trim(arguments.file))) {
                    local.outputPath = fileSystemUtil.resolvePath(arguments.file);
                } else {
                    // Generate default filename based on format
                    local.timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
                    local.extension = lCase(arguments.format) == "json" ? "json" : (lCase(arguments.format) == "sql" ? "sql" : "txt");
                    local.defaultFilename = "schema_#local.timestamp#.#local.extension#";
                    local.outputPath = fileSystemUtil.resolvePath(local.defaultFilename);
                }
                
                file action='write' file='#local.outputPath#' mode='777' output='#local.output#';
                print.boldGreenLine("Schema exported to: #local.outputPath#");
                print.yellowLine("Format: #arguments.format#");
                if (structKeyExists(local.schema, "TABLECOUNT")) {
                    print.yellowLine("Tables: #local.schema.TABLECOUNT#");
                }
                if (arguments.engine != "default") {
                    print.yellowLine("Engine: #arguments.engine#");
                }
            } else {
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
        
        // Handle the actual schema structure from the JSON
        if (isStruct(arguments.schema)) {
            // Add database info
            if (structKeyExists(arguments.schema, "DATABASETYPE")) {
                local.output &= "Database Type: #arguments.schema.DATABASETYPE#" & chr(10);
            }
            if (structKeyExists(arguments.schema, "TABLECOUNT")) {
                local.output &= "Total Tables: #arguments.schema.TABLECOUNT#" & chr(10);
            }
            local.output &= chr(10);
            
            // Process tables array
            if (structKeyExists(arguments.schema, "TABLES") && isArray(arguments.schema.TABLES)) {
                for (local.table in arguments.schema.TABLES) {
                    // Table header
                    local.output &= "TABLE: #uCase(local.table.NAME)#" & chr(10);
                    local.output &= repeatString("=", 80) & chr(10);
                    
                    // Primary key info
                    if (structKeyExists(local.table, "PRIMARYKEY") && arrayLen(local.table.PRIMARYKEY)) {
                        local.output &= "PRIMARY KEY: " & arrayToList(local.table.PRIMARYKEY, ", ") & chr(10);
                        local.output &= chr(10);
                    }
                    
                    // Column headers
                    local.output &= "COLUMNS:" & chr(10);
                    local.output &= repeatString("-", 80) & chr(10);
                    
                    // Format column header
                    local.output &= ljustify("Column Name", 30) & " ";
                    local.output &= ljustify("Type", 20) & " ";
                    local.output &= ljustify("Nullable", 10) & " ";
                    local.output &= "Default" & chr(10);
                    local.output &= repeatString("-", 80) & chr(10);
                    
                    // Process columns
                    if (structKeyExists(local.table, "COLUMNS") && isArray(local.table.COLUMNS)) {
                        for (local.column in local.table.COLUMNS) {
                            // Column name
                            local.colName = ljustify(local.column.NAME, 30) & " ";
                            
                            // Column type with length/precision
                            local.colType = local.column.TYPE;
                            if (structKeyExists(local.column, "LENGTH") && len(local.column.LENGTH)) {
                                local.colType &= "(" & local.column.LENGTH & ")";
                            } else if (structKeyExists(local.column, "PRECISION") && len(local.column.PRECISION)) {
                                if (structKeyExists(local.column, "SCALE") && len(local.column.SCALE)) {
                                    local.colType &= "(" & local.column.PRECISION & "," & local.column.SCALE & ")";
                                } else {
                                    local.colType &= "(" & local.column.PRECISION & ")";
                                }
                            }
                            local.colType = ljustify(local.colType, 20) & " ";
                            
                            // Nullable
                            local.nullable = ljustify(local.column.NULLABLE, 10) & " ";
                            
                            // Default value
                            local.default = "";
                            if (structKeyExists(local.column, "DEFAULT") && len(local.column.DEFAULT)) {
                                local.default = local.column.DEFAULT;
                            }
                            
                            local.output &= local.colName & local.colType & local.nullable & local.default & chr(10);
                        }
                    }
                    
                    // Process indexes if any
                    if (structKeyExists(local.table, "INDEXES") && arrayLen(local.table.INDEXES)) {
                        local.output &= chr(10) & "INDEXES:" & chr(10);
                        for (local.index in local.table.INDEXES) {
                            local.unique = structKeyExists(local.index, "unique") && local.index.unique ? "UNIQUE " : "";
                            local.indexName = structKeyExists(local.index, "name") ? local.index.name : "unnamed";
                            local.columns = structKeyExists(local.index, "columns") ? 
                                           (isArray(local.index.columns) ? arrayToList(local.index.columns) : local.index.columns) : 
                                           "";
                            
                            local.output &= "  - #local.unique#INDEX #local.indexName# (#local.columns#)" & chr(10);
                        }
                    }
                    
                    local.output &= chr(10) & chr(10);
                }
            }
        } else {
            // If we received plain text or SQL, just return it
            local.output = isSimpleValue(arguments.schema) ? arguments.schema : serializeJSON(arguments.schema);
        }
        
        return local.output;
    }
    
    /**
     * Generate SQL CREATE statements from schema
     */
    private string function generateSQLFromSchema(required struct schema, string engine="default") {
        local.dbType = arguments.engine != "default" ? arguments.engine : (structKeyExists(arguments.schema, "DATABASETYPE") ? arguments.schema.DATABASETYPE : "Unknown");
        
        local.output = "-- Generated SQL Schema" & chr(10);
        local.output &= "-- Database Type: " & local.dbType & chr(10);
        local.output &= "-- Generated on: " & dateFormat(now(), "yyyy-mm-dd") & " " & timeFormat(now(), "HH:mm:ss") & chr(10);
        local.output &= chr(10);
        
        if (structKeyExists(arguments.schema, "TABLES") && isArray(arguments.schema.TABLES)) {
            for (local.table in arguments.schema.TABLES) {
                // CREATE TABLE statement
                local.output &= "CREATE TABLE " & local.table.NAME & " (" & chr(10);
                
                local.columnDefs = [];
                if (structKeyExists(local.table, "COLUMNS") && isArray(local.table.COLUMNS)) {
                    for (local.column in local.table.COLUMNS) {
                        local.colDef = "    " & local.column.NAME & " " & local.column.TYPE;
                        
                        // Add length/precision based on database engine
                        if (structKeyExists(local.column, "LENGTH") && len(local.column.LENGTH)) {
                            local.colDef &= "(" & local.column.LENGTH & ")";
                        } else if (structKeyExists(local.column, "PRECISION") && len(local.column.PRECISION)) {
                            if (structKeyExists(local.column, "SCALE") && len(local.column.SCALE) && local.column.SCALE != "0") {
                                local.colDef &= "(" & local.column.PRECISION & "," & local.column.SCALE & ")";
                            } else {
                                local.colDef &= "(" & local.column.PRECISION & ")";
                            }
                        }
                        
                        // Add NULL/NOT NULL
                        if (local.column.NULLABLE == "NO") {
                            local.colDef &= " NOT NULL";
                        } else if (local.dbType != "MicrosoftSQLServer") {
                            // SQL Server doesn't need explicit NULL
                            local.colDef &= " NULL";
                        }
                        
                        // Add default value with proper formatting
                        if (structKeyExists(local.column, "DEFAULT") && len(local.column.DEFAULT)) {
                            // Clean up SQL Server specific default syntax
                            local.defaultValue = local.column.DEFAULT;
                            if (local.dbType == "MicrosoftSQLServer" || local.dbType == "SQLServer") {
                                // Remove SQL Server parentheses from defaults like ((1))
                                local.defaultValue = reReplace(local.defaultValue, "^\(\((.*)\)\)$", "\1");
                            }
                            local.colDef &= " DEFAULT " & local.defaultValue;
                        }
                        
                        arrayAppend(local.columnDefs, local.colDef);
                    }
                }
                
                // Add primary key constraint
                if (structKeyExists(local.table, "PRIMARYKEY") && arrayLen(local.table.PRIMARYKEY)) {
                    arrayAppend(local.columnDefs, "    PRIMARY KEY (" & arrayToList(local.table.PRIMARYKEY, ", ") & ")");
                }
                
                local.output &= arrayToList(local.columnDefs, "," & chr(10));
                local.output &= chr(10) & ");" & chr(10) & chr(10);
            }
        }
        
        return local.output;
    }
    
    /**
     * Left justify a string to specified width
     */
    private string function ljustify(required string text, required numeric width) {
        if (len(arguments.text) >= arguments.width) {
            return left(arguments.text, arguments.width);
        }
        return arguments.text & repeatString(" ", arguments.width - len(arguments.text));
    }
    
    /**
     * Check if array contains value (case insensitive)
     */
    private boolean function arrayContainsNoCase(required array arr, required string value) {
        for (local.item in arguments.arr) {
            if (compareNoCase(local.item, arguments.value) == 0) {
                return true;
            }
        }
        return false;
    }
}