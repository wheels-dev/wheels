/**
 * Generate a database migration file
 * 
 * Examples:
 * wheels generate migration CreateUsersTable
 * wheels generate migration AddEmailToUsers
 * wheels generate migration RemoveAgeFromUsers
 * wheels generate migration CreateUsersTable --create=users
 * wheels generate migration AddEmailToUsers --table=users --attributes="email:string:index,verified:boolean"
 * wheels generate migration CreateProductsTable --attributes="name:string,price:decimal,inStock:boolean"
 */
component aliases='wheels g migration' extends="../base" {
    
    property name="migrationService" inject="MigrationService@wheels-cli";
    property name="helpers" inject="helpers@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @name.hint Name of the migration (e.g., CreateUsersTable, AddEmailToUsers)
     * @create.hint Table to create (for create_table migrations)
     * @table.hint Table to modify (for alter_table migrations)
     * @attributes.hint Column definitions (format: name:type:options,name2:type2)
     * @drop.hint Table to drop (for drop_table migrations)
     * @up.hint Custom up() migration code
     * @down.hint Custom down() migration code
     * @force.hint Overwrite existing migration file
     */
    function run(
        required string name,
        string create = "",
        string table = "",
        string attributes = "",
        string drop = "",
        string up = "",
        string down = "",
        boolean force = false
    ) {
        detailOutput.header("🗄️", "Generating migration: #arguments.name#");
        
        // Validate migration name
        if (!reFindNoCase("^[A-Za-z][A-Za-z0-9_]*$", arguments.name)) {
            error("Invalid migration name. Use only letters, numbers, and underscores, starting with a letter.");
            return;
        }
        
        // Determine migration type based on name and arguments
        var migrationType = detectMigrationType(arguments);
        
        // Get migration directory
        var migrationDir = helpers.getMigrationPath();
        if (!directoryExists(migrationDir)) {
            directoryCreate(migrationDir);
            detailOutput.output("Created migration directory: #migrationDir#");
        }
        
        // Generate timestamp
        var timestamp = helpers.generateMigrationTimestamp();
        
        // Create migration filename
        var fileName = timestamp & "_" & arguments.name & ".cfc";
        var filePath = migrationDir & "/" & fileName;
        
        // Check if file exists
        if (fileExists(filePath) && !arguments.force) {
            error("Migration file already exists: #fileName#. Use --force to overwrite.");
            return;
        }
        
        // Generate migration content
        var migrationContent = generateMigrationContent(arguments, migrationType);
        
        // Write migration file
        fileWrite(filePath, migrationContent);
        
        detailOutput.success("Created migration: #fileName#");
        
        // Show migration code if verbose
        if (arguments.verbose ?: false) {
            detailOutput.code(migrationContent, "cfscript");
        }
        
        detailOutput.output("Run 'wheels dbmigrate latest' to apply this migration");
    }
    
    /**
     * Detect migration type from name and arguments
     */
    private string function detectMigrationType(required struct args) {
        // Explicit create table
        if (len(args.create)) {
            return "create_table";
        }
        
        // Explicit drop table
        if (len(args.drop)) {
            return "drop_table";
        }
        
        // Detect from name patterns
        var name = args.name;
        
        if (reFindNoCase("^Create\w+Table$", name)) {
            return "create_table";
        } else if (reFindNoCase("^Drop\w+Table$", name)) {
            return "drop_table";
        } else if (reFindNoCase("^Add\w+To\w+$", name)) {
            return "add_column";
        } else if (reFindNoCase("^Remove\w+From\w+$", name)) {
            return "remove_column";
        } else if (reFindNoCase("^Rename\w+To\w+$", name)) {
            return "rename_column";
        } else if (reFindNoCase("^Change\w+In\w+$", name)) {
            return "change_column";
        } else if (reFindNoCase("^CreateIndexOn\w+$", name)) {
            return "add_index";
        } else if (reFindNoCase("^RemoveIndexFrom\w+$", name)) {
            return "remove_index";
        }
        
        // Default to custom migration
        return "custom";
    }
    
    /**
     * Generate migration content based on type
     */
    private string function generateMigrationContent(required struct args, required string migrationType) {
        var content = "component extends=""wheels.migrator.Migration"" hint=""#args.name#"" {" & chr(10) & chr(10);
        
        // Generate up() method
        content &= chr(9) & "function up() {" & chr(10);
        
        if (len(args.up)) {
            // Custom up code provided
            content &= chr(9) & chr(9) & args.up & chr(10);
        } else {
            // Generate based on type
            switch(migrationType) {
                case "create_table":
                    content &= generateCreateTableUp(args);
                    break;
                case "drop_table":
                    content &= generateDropTableUp(args);
                    break;
                case "add_column":
                    content &= generateAddColumnUp(args);
                    break;
                case "remove_column":
                    content &= generateRemoveColumnUp(args);
                    break;
                case "change_column":
                    content &= generateChangeColumnUp(args);
                    break;
                case "add_index":
                    content &= generateAddIndexUp(args);
                    break;
                case "remove_index":
                    content &= generateRemoveIndexUp(args);
                    break;
                default:
                    content &= chr(9) & chr(9) & "// Add your migration code here" & chr(10);
            }
        }
        
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        // Generate down() method
        content &= chr(9) & "function down() {" & chr(10);
        
        if (len(args.down)) {
            // Custom down code provided
            content &= chr(9) & chr(9) & args.down & chr(10);
        } else {
            // Generate based on type
            switch(migrationType) {
                case "create_table":
                    content &= generateCreateTableDown(args);
                    break;
                case "drop_table":
                    content &= generateDropTableDown(args);
                    break;
                case "add_column":
                    content &= generateAddColumnDown(args);
                    break;
                case "remove_column":
                    content &= generateRemoveColumnDown(args);
                    break;
                case "change_column":
                    content &= generateChangeColumnDown(args);
                    break;
                case "add_index":
                    content &= generateAddIndexDown(args);
                    break;
                case "remove_index":
                    content &= generateRemoveIndexDown(args);
                    break;
                default:
                    content &= chr(9) & chr(9) & "// Add your rollback code here" & chr(10);
            }
        }
        
        content &= chr(9) & "}" & chr(10);
        content &= "}";
        
        return content;
    }
    
    // Helper functions for generating specific migration types
    private string function generateCreateTableUp(required struct args) {
        var tableName = len(args.create) ? args.create : inferTableName(args.name);
        var content = chr(9) & chr(9) & "createTable(name=""#tableName#"", id=true, force=true);" & chr(10);
        
        if (len(args.attributes)) {
            content &= parseAndGenerateColumns(args.attributes, tableName);
        }
        
        return content;
    }
    
    private string function generateCreateTableDown(required struct args) {
        var tableName = len(args.create) ? args.create : inferTableName(args.name);
        return chr(9) & chr(9) & "dropTable(""#tableName#"");" & chr(10);
    }
    
    private string function generateDropTableUp(required struct args) {
        var tableName = len(args.drop) ? args.drop : inferTableName(args.name);
        return chr(9) & chr(9) & "dropTable(""#tableName#"");" & chr(10);
    }
    
    private string function generateDropTableDown(required struct args) {
        var tableName = len(args.drop) ? args.drop : inferTableName(args.name);
        return chr(9) & chr(9) & "// Recreate the dropped table" & chr(10) &
               chr(9) & chr(9) & "createTable(name=""#tableName#"", id=true, force=true);" & chr(10);
    }
    
    private string function generateAddColumnUp(required struct args) {
        var tableName = len(args.table) ? args.table : inferTableNameFromAdd(args.name);
        var content = "";
        
        if (len(args.attributes)) {
            var columns = parseColumns(args.attributes);
            for (var column in columns) {
                content &= chr(9) & chr(9) & "addColumn(table=""#tableName#"", ";
                content &= "columnType=""#column.type#"", ";
                content &= "columnName=""#column.name#""";
                
                if (structKeyExists(column, "null") && !column.null) {
                    content &= ", null=false";
                }
                if (structKeyExists(column, "default")) {
                    content &= ", default=""#column.default#""";
                }
                if (structKeyExists(column, "limit")) {
                    content &= ", limit=#column.limit#";
                }
                
                content &= ");" & chr(10);
                
                // Add index if specified
                if (structKeyExists(column, "index") && column.index) {
                    content &= chr(9) & chr(9) & "addIndex(table=""#tableName#"", columnNames=""#column.name#"", unique=false);" & chr(10);
                }
            }
        } else {
            content &= chr(9) & chr(9) & "// addColumn(table=""#tableName#"", columnType=""string"", columnName=""column_name"");" & chr(10);
        }
        
        return content;
    }
    
    private string function generateAddColumnDown(required struct args) {
        var tableName = len(args.table) ? args.table : inferTableNameFromAdd(args.name);
        var content = "";
        
        if (len(args.attributes)) {
            var columns = parseColumns(args.attributes);
            for (var column in columns) {
                // Remove index first if it exists
                if (structKeyExists(column, "index") && column.index) {
                    content &= chr(9) & chr(9) & "removeIndex(table=""#tableName#"", columnNames=""#column.name#"");" & chr(10);
                }
                content &= chr(9) & chr(9) & "removeColumn(table=""#tableName#"", columnName=""#column.name#"");" & chr(10);
            }
        } else {
            content &= chr(9) & chr(9) & "// removeColumn(table=""#tableName#"", columnName=""column_name"");" & chr(10);
        }
        
        return content;
    }
    
    private string function generateRemoveColumnUp(required struct args) {
        var tableName = len(args.table) ? args.table : inferTableNameFromRemove(args.name);
        return chr(9) & chr(9) & "removeColumn(table=""#tableName#"", columnName=""column_name"");" & chr(10);
    }
    
    private string function generateRemoveColumnDown(required struct args) {
        var tableName = len(args.table) ? args.table : inferTableNameFromRemove(args.name);
        return chr(9) & chr(9) & "addColumn(table=""#tableName#"", columnType=""string"", columnName=""column_name"");" & chr(10);
    }
    
    private string function generateChangeColumnUp(required struct args) {
        var tableName = len(args.table) ? args.table : inferTableName(args.name);
        return chr(9) & chr(9) & "changeColumn(table=""#tableName#"", columnName=""old_column"", columnType=""string"", columnName=""new_column"");" & chr(10);
    }
    
    private string function generateChangeColumnDown(required struct args) {
        var tableName = len(args.table) ? args.table : inferTableName(args.name);
        return chr(9) & chr(9) & "changeColumn(table=""#tableName#"", columnName=""new_column"", columnType=""string"", columnName=""old_column"");" & chr(10);
    }
    
    private string function generateAddIndexUp(required struct args) {
        var tableName = len(args.table) ? args.table : inferTableName(args.name);
        return chr(9) & chr(9) & "addIndex(table=""#tableName#"", columnNames=""column_name"", unique=false);" & chr(10);
    }
    
    private string function generateAddIndexDown(required struct args) {
        var tableName = len(args.table) ? args.table : inferTableName(args.name);
        return chr(9) & chr(9) & "removeIndex(table=""#tableName#"", columnNames=""column_name"");" & chr(10);
    }
    
    private string function generateRemoveIndexUp(required struct args) {
        var tableName = len(args.table) ? args.table : inferTableName(args.name);
        return chr(9) & chr(9) & "removeIndex(table=""#tableName#"", columnNames=""column_name"");" & chr(10);
    }
    
    private string function generateRemoveIndexDown(required struct args) {
        var tableName = len(args.table) ? args.table : inferTableName(args.name);
        return chr(9) & chr(9) & "addIndex(table=""#tableName#"", columnNames=""column_name"", unique=false);" & chr(10);
    }
    
    // Utility functions
    private string function inferTableName(required string migrationName) {
        // CreateUsersTable -> users
        // DropProductsTable -> products
        var match = reFindNoCase("(Create|Drop)(\w+)Table", migrationName, 1, true);
        if (arrayLen(match.pos) >= 3) {
            var modelName = mid(migrationName, match.pos[3], match.len[3]);
            return helpers.pluralize(lCase(modelName));
        }
        return "table_name";
    }
    
    private string function inferTableNameFromAdd(required string migrationName) {
        // AddEmailToUsers -> users
        var match = reFindNoCase("Add\w+To(\w+)", migrationName, 1, true);
        if (arrayLen(match.pos) >= 2) {
            var tableName = mid(migrationName, match.pos[2], match.len[2]);
            return lCase(tableName);
        }
        return "table_name";
    }
    
    private string function inferTableNameFromRemove(required string migrationName) {
        // RemoveAgeFromUsers -> users
        var match = reFindNoCase("Remove\w+From(\w+)", migrationName, 1, true);
        if (arrayLen(match.pos) >= 2) {
            var tableName = mid(migrationName, match.pos[2], match.len[2]);
            return lCase(tableName);
        }
        return "table_name";
    }
    
    private array function parseColumns(required string attributes) {
        var columns = [];
        var attributeList = listToArray(attributes, ",");
        
        for (var attr in attributeList) {
            var parts = listToArray(trim(attr), ":");
            var column = {
                name = parts[1],
                type = arrayLen(parts) >= 2 ? mapColumnType(parts[2]) : "string"
            };
            
            // Check for additional options like index
            if (arrayLen(parts) >= 3) {
                for (var i = 3; i <= arrayLen(parts); i++) {
                    switch(parts[i]) {
                        case "index":
                            column.index = true;
                            break;
                        case "unique":
                            column.index = true;
                            column.unique = true;
                            break;
                        case "null":
                            column.null = true;
                            break;
                        case "notnull":
                        case "required":
                            column.null = false;
                            break;
                        default:
                            // Check if it's a default value
                            if (left(parts[i], 8) == "default=") {
                                column.default = mid(parts[i], 9, len(parts[i]));
                            }
                    }
                }
            }
            
            arrayAppend(columns, column);
        }
        
        return columns;
    }
    
    private string function parseAndGenerateColumns(required string attributes, required string tableName) {
        var content = "";
        var columns = parseColumns(attributes);
        
        for (var column in columns) {
            content &= chr(9) & chr(9) & "t.column(";
            content &= "columnName=""#column.name#"", ";
            content &= "columnType=""#column.type#""";
            
            if (structKeyExists(column, "null") && !column.null) {
                content &= ", null=false";
            }
            if (structKeyExists(column, "default")) {
                content &= ", default=""#column.default#""";
            }
            
            content &= ");" & chr(10);
        }
        
        return content;
    }
    
    private string function mapColumnType(required string type) {
        // Map common type aliases to Wheels column types
        switch(lCase(type)) {
            case "str":
            case "varchar":
                return "string";
            case "int":
            case "number":
                return "integer";
            case "bool":
                return "boolean";
            case "datetime":
                return "timestamp";
            case "money":
            case "currency":
                return "decimal";
            default:
                return type;
        }
    }
}