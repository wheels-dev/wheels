/**
 * Create a new database migration
 */
component extends="commands.wheels.BaseCommand" {
    
    /**
     * Create a new database migration
     * 
     * @name Name of the migration (e.g., CreateUsersTable, AddEmailToUsers)
     * @model Model name to base migration on (optional)
     * @properties Properties to include in migration (name:type format)
     * @table Table name (defaults to pluralized model name)
     * @action Migration action (create, add, remove, change, drop)
     * @force Overwrite existing migration
     * @help Generate a database migration file
     * 
     * Examples:
     * wheels create migration CreateUsersTable
     * wheels create migration AddEmailToUsers --table=users
     * wheels create migration CreatePostsTable --model=Post --properties="title:string,content:text,published:boolean"
     */
    function run(
        required string name,
        string model = "",
        string properties = "",
        string table = "",
        string action = "",
        boolean force = false
    ) {
        ensureWheelsProject();
        
        // Validate migration name
        if (!reFind("^[A-Z][a-zA-Z0-9]*$", arguments.name)) {
            error("Invalid migration name. Migration names must start with a capital letter and contain only letters and numbers.");
        }
        
        print.line();
        print.boldBlueLine("Creating migration: #arguments.name#");
        
        // Auto-detect action from name if not specified
        if (!len(arguments.action)) {
            arguments.action = detectMigrationAction(arguments.name);
        }
        
        // Determine table name
        if (!len(arguments.table)) {
            if (len(arguments.model)) {
                arguments.table = pluralize(lCase(arguments.model));
            } else {
                arguments.table = extractTableNameFromMigration(arguments.name);
            }
        }
        
        // Parse properties if provided
        var props = [];
        if (len(arguments.properties)) {
            props = parseProperties(arguments.properties);
        }
        
        // Generate migration file
        var timestamp = dateTimeFormat(now(), "yyyymmddHHnnss");
        var fileName = timestamp & "_" & arguments.name & ".cfc";
        var migrationPath = getDbPath("migrate");
        var migrationFile = migrationPath & fileName;
        
        // Ensure migration directory exists
        if (!directoryExists(migrationPath)) {
            directoryCreate(migrationPath, true);
        }
        
        // Check if file exists
        if (fileExists(migrationFile) && !arguments.force) {
            error("Migration already exists: #fileName#");
        }
        
        // Generate migration content
        var migrationContent = generateMigrationContent(
            arguments.name,
            arguments.action,
            arguments.table,
            props,
            arguments.model
        );
        
        fileWrite(migrationFile, migrationContent);
        print.greenLine("✓ Created migration: db/migrate/#fileName#");
        
        print.line();
        print.boldLine("Next steps:");
        print.indentedLine("1. Review and modify the migration file");
        print.indentedLine("2. Run 'wheels db migrate' to apply the migration");
        
        if (arguments.action == "create" && !len(arguments.model)) {
            print.line();
            print.yellowLine("Tip: Generate a model with 'wheels create model #singularize(capFirst(arguments.table))#'");
        }
    }
    
    /**
     * Detect migration action from name
     */
    private function detectMigrationAction(required string name) {
        var lowerName = lCase(arguments.name);
        
        if (findNoCase("create", lowerName) && findNoCase("table", lowerName)) {
            return "create";
        } else if (findNoCase("add", lowerName) && findNoCase("to", lowerName)) {
            return "add";
        } else if (findNoCase("remove", lowerName) && findNoCase("from", lowerName)) {
            return "remove";
        } else if (findNoCase("change", lowerName) || findNoCase("modify", lowerName)) {
            return "change";
        } else if (findNoCase("drop", lowerName) && findNoCase("table", lowerName)) {
            return "drop";
        } else if (findNoCase("rename", lowerName)) {
            return "rename";
        } else if (findNoCase("index", lowerName)) {
            return "index";
        }
        
        return "change"; // Default action
    }
    
    /**
     * Extract table name from migration name
     */
    private function extractTableNameFromMigration(required string name) {
        // CreateUsersTable -> users
        if (reFindNoCase("Create([A-Z][a-zA-Z]+)Table", arguments.name, 1, true).pos[1]) {
            var match = reFindNoCase("Create([A-Z][a-zA-Z]+)Table", arguments.name, 1, true);
            var modelName = mid(arguments.name, match.pos[2], match.len[2]);
            return lCase(pluralize(modelName));
        }
        
        // AddEmailToUsers -> users
        if (reFindNoCase("To([A-Z][a-zA-Z]+)$", arguments.name, 1, true).pos[1]) {
            var match = reFindNoCase("To([A-Z][a-zA-Z]+)$", arguments.name, 1, true);
            var tableName = mid(arguments.name, match.pos[2], match.len[2]);
            return lCase(tableName);
        }
        
        // RemovePasswordFromUsers -> users
        if (reFindNoCase("From([A-Z][a-zA-Z]+)$", arguments.name, 1, true).pos[1]) {
            var match = reFindNoCase("From([A-Z][a-zA-Z]+)$", arguments.name, 1, true);
            var tableName = mid(arguments.name, match.pos[2], match.len[2]);
            return lCase(tableName);
        }
        
        return "table_name"; // Default placeholder
    }
    
    /**
     * Parse properties string
     */
    private function parseProperties(required string properties) {
        var props = [];
        var propList = listToArray(arguments.properties);
        
        for (var prop in propList) {
            var parts = listToArray(prop, ":");
            var property = {
                name = trim(parts[1]),
                type = arrayLen(parts) > 1 ? trim(parts[2]) : "string",
                options = {}
            };
            
            // Map types to database column types
            switch(property.type) {
                case "string":
                    property.columnType = "varchar";
                    property.length = 255;
                    break;
                case "text":
                    property.columnType = "text";
                    break;
                case "integer":
                case "int":
                    property.columnType = "integer";
                    break;
                case "bigint":
                    property.columnType = "bigint";
                    break;
                case "boolean":
                case "bool":
                    property.columnType = "boolean";
                    property.default = false;
                    break;
                case "date":
                    property.columnType = "date";
                    break;
                case "datetime":
                case "timestamp":
                    property.columnType = "datetime";
                    break;
                case "decimal":
                case "numeric":
                    property.columnType = "decimal";
                    property.precision = 10;
                    property.scale = 2;
                    break;
                case "float":
                case "double":
                    property.columnType = "float";
                    break;
                case "uuid":
                    property.columnType = "varchar";
                    property.length = 36;
                    break;
                default:
                    property.columnType = property.type;
            }
            
            // Parse options
            if (arrayLen(parts) > 2) {
                for (var i = 3; i <= arrayLen(parts); i++) {
                    var option = trim(parts[i]);
                    property.options[option] = true;
                    
                    // Handle specific options
                    if (option == "index") {
                        property.index = true;
                    } else if (option == "unique") {
                        property.unique = true;
                    } else if (option == "required" || option == "notnull") {
                        property.nullable = false;
                    } else if (isNumeric(option)) {
                        property.length = option;
                    }
                }
            }
            
            arrayAppend(props, property);
        }
        
        return props;
    }
    
    /**
     * Generate migration content
     */
    private function generateMigrationContent(
        required string name,
        required string action,
        required string table,
        required array properties,
        string model = ""
    ) {
        var snippet = getSnippet("migration", "Migration");
        
        var data = {
            migrationName = arguments.name,
            tableName = arguments.table,
            timestamp = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            generatedBy = "Wheels CLI v3.0.0-beta.1"
        };
        
        // Generate column definitions
        var columnDefs = [];
        for (var prop in arguments.properties) {
            var colDef = 'column(name="' & prop.name & '", type="' & prop.columnType & '"';
            
            if (structKeyExists(prop, "length")) {
                colDef &= ', length=' & prop.length;
            }
            if (structKeyExists(prop, "precision")) {
                colDef &= ', precision=' & prop.precision & ', scale=' & prop.scale;
            }
            if (structKeyExists(prop, "nullable") && !prop.nullable) {
                colDef &= ', null=false';
            }
            if (structKeyExists(prop, "default")) {
                if (isBoolean(prop.default)) {
                    colDef &= ', default=' & prop.default;
                } else {
                    colDef &= ', default="' & prop.default & '"';
                }
            }
            if (structKeyExists(prop, "unique") && prop.unique) {
                colDef &= ', unique=true';
            }
            
            colDef &= ');';
            arrayAppend(columnDefs, colDef);
        }
        
        // Build the migration content based on action
        var upContent = "";
        var downContent = "";
        
        switch(arguments.action) {
            case "create":
                upContent = 'createTable(name="' & arguments.table & '") {' & chr(10);
                upContent &= '                // Primary key' & chr(10);
                upContent &= '                column(name="id", type="integer", primaryKey=true, autoIncrement=true);' & chr(10);
                
                if (arrayLen(columnDefs)) {
                    upContent &= '                ' & chr(10);
                    upContent &= '                // Columns' & chr(10);
                    for (var colDef in columnDefs) {
                        upContent &= '                ' & colDef & chr(10);
                    }
                }
                
                upContent &= '                ' & chr(10);
                upContent &= '                // Timestamps' & chr(10);
                upContent &= '                timestamps();' & chr(10);
                upContent &= '            }';
                
                // Add indexes
                for (var prop in arguments.properties) {
                    if (structKeyExists(prop, "index") && prop.index && !structKeyExists(prop, "unique")) {
                        upContent &= chr(10) & chr(10);
                        upContent &= '            // Add index' & chr(10);
                        upContent &= '            addIndex(table="' & arguments.table & '", columns="' & prop.name & '");';
                    }
                }
                
                downContent = 'dropTable("' & arguments.table & '");';
                break;
                
            case "add":
                if (arrayLen(arguments.properties)) {
                    var addColumns = [];
                    for (var colDef in columnDefs) {
                        arrayAppend(addColumns, 'addColumn(table="' & arguments.table & '", ' & 
                                   reReplace(colDef, '^column\(', '') );
                    }
                    upContent = arrayToList(addColumns, chr(10) & '            ');
                    
                    // Down migration removes the columns
                    var removeColumns = [];
                    for (var prop in arguments.properties) {
                        arrayAppend(removeColumns, 'removeColumn(table="' & arguments.table & 
                                   '", column="' & prop.name & '");');
                    }
                    downContent = arrayToList(removeColumns, chr(10) & '            ');
                } else {
                    upContent = '// addColumn(table="' & arguments.table & '", name="column_name", type="string");';
                    downContent = '// removeColumn(table="' & arguments.table & '", column="column_name");';
                }
                break;
                
            case "remove":
                if (arrayLen(arguments.properties)) {
                    var removeColumns = [];
                    for (var prop in arguments.properties) {
                        arrayAppend(removeColumns, 'removeColumn(table="' & arguments.table & 
                                   '", column="' & prop.name & '");');
                    }
                    upContent = arrayToList(removeColumns, chr(10) & '            ');
                    downContent = '// Restore removed columns - implement based on your needs';
                } else {
                    upContent = '// removeColumn(table="' & arguments.table & '", column="column_name");';
                    downContent = '// addColumn(table="' & arguments.table & '", name="column_name", type="string");';
                }
                break;
                
            case "drop":
                upContent = 'dropTable("' & arguments.table & '");';
                downContent = '// Recreate table - implement based on your needs';
                break;
                
            default:
                upContent = '// Implement your migration logic here';
                downContent = '// Implement your rollback logic here';
        }
        
        // Replace placeholders in snippet
        var content = renderSnippet(snippet, data);
        content = replaceNoCase(content, "// Create table", upContent, "all");
        content = replaceNoCase(content, "// Drop table", downContent, "all");
        
        return content;
    }
    
    /**
     * Capitalize first letter
     */
    private function capFirst(required string str) {
        if (len(arguments.str) == 0) return "";
        return uCase(left(arguments.str, 1)) & right(arguments.str, len(arguments.str) - 1);
    }
}