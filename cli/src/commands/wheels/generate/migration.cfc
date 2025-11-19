/**
 * Generate a database migration file using templates
 *
 * Examples:
 * wheels generate migration CreateUsersTable
 * wheels generate migration AddEmailToUsers --table=users --attributes="email:string:index"
 * wheels generate migration RemoveAgeFromUsers --table=users
 * wheels generate migration CreateUsersTable --create=users
 */
component aliases='wheels g migration' extends="../base" {

    property name="helpers" inject="helpers@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @name.hint Name of the migration (e.g., CreateUsersTable, AddEmailToUsers)
     * @create.hint Table to create (for create_table migrations)
     * @table.hint Table to modify (for alter_table migrations)
     * @drop.hint Table to drop (for drop_table migrations)
     * @description.hint Migration description
     * @force.hint Overwrite existing migration file
     */
    function run(
        required string name,
        string create = "",
        string table = "",
        string drop = "",
        string description = "",
        boolean force = false
    ) {
        // Reconstruct arguments for handling --prefixed options
        arguments = reconstructArgs(arguments);

        detailOutput.header("", "Migration Generation: #arguments.name#");

        // Validate migration name
        if (!reFindNoCase("^[A-Za-z][A-Za-z0-9_]*$", arguments.name)) {
            error("Invalid migration name. Use only letters, numbers, and underscores, starting with a letter.");
            return;
        }

        // Determine migration type and get appropriate template
        var migrationType = detectMigrationType(arguments);
        var templateName = mapTypeToTemplate(migrationType);

        // Get template content
        var content = fileRead(getTemplate("dbmigrate/#templateName#"));

        // Replace template placeholders based on type
        content = populateTemplate(content, arguments, migrationType);

        // Create migration file using base method
        var migrationPath = $createMigrationFile(
            name = lcase(trim(arguments.name)),
            action = migrationType,
            content = content
        );

        detailOutput.create(migrationPath);
        detailOutput.success("Migration created successfully!");

        // Show next steps
        var nextSteps = [];
        if (migrationType == "blank" || migrationType == "custom") {
            arrayAppend(nextSteps, "Edit the migration file: #migrationPath#");
        }
        arrayAppend(nextSteps, "Run the migration: wheels dbmigrate latest");
        detailOutput.nextSteps(nextSteps);
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
            return "remove_table";
        }

        // Detect from name patterns
        var name = args.name;

        if (reFindNoCase("^Create\w+Table$", name)) {
            return "create_table";
        } else if (reFindNoCase("^Drop\w+Table$", name) || reFindNoCase("^Remove\w+Table$", name)) {
            return "remove_table";
        } else if (reFindNoCase("^Add\w+To\w+$", name)) {
            return "create_column";
        } else if (reFindNoCase("^Remove\w+From\w+$", name)) {
            return "remove_column";
        } else if (reFindNoCase("^Rename\w+To\w+$", name)) {
            return "rename_column";
        } else if (reFindNoCase("^Change\w+In\w+$", name)) {
            return "change_column";
        } else if (reFindNoCase("^CreateIndexOn\w+$", name)) {
            return "create_index";
        } else if (reFindNoCase("^RemoveIndexFrom\w+$", name)) {
            return "remove_index";
        }

        // Default to blank migration
        return "blank";
    }

    /**
     * Map migration type to template file
     */
    private string function mapTypeToTemplate(required string migrationType) {
        switch(arguments.migrationType) {
            case "create_table":
                return "create-table.txt";
            case "remove_table":
                return "remove-table.txt";
            case "create_column":
                return "create-column.txt";
            case "remove_column":
                return "remove-column.txt";
            case "change_column":
                return "change-column.txt";
            case "rename_column":
                return "rename-column.txt";
            case "create_index":
                return "create-index.txt";
            case "remove_index":
                return "remove-index.txt";
            default:
                return "blank.txt";
        }
    }

    /**
     * Populate template with values
     */
    private string function populateTemplate(required string content, required struct args, required string migrationType) {
        var result = arguments.content;

        // Set description if provided
        if (len(trim(args.description))) {
            result = replaceNoCase(result, "|DBMigrateDescription|", args.description, "all");
        } else {
            result = replaceNoCase(result, "|DBMigrateDescription|", args.name, "all");
        }

        // Populate based on migration type
        switch(migrationType) {
            case "create_table":
                var tableName = len(args.create) ? args.create : inferTableName(args.name);
                result = replaceNoCase(result, "|tableName|", tableName, "all");
                result = replaceNoCase(result, "|force|", "false", "all");
                result = replaceNoCase(result, "|id|", "true", "all");
                result = replaceNoCase(result, "|primaryKey|", "id", "all");
                break;

            case "remove_table":
                var tableName = len(args.drop) ? args.drop : inferTableName(args.name);
                result = replaceNoCase(result, "|tableName|", tableName, "all");
                break;

            case "create_column":
                var tableName = len(args.table) ? args.table : inferTableNameFromAdd(args.name);
                result = replaceNoCase(result, "|tableName|", tableName, "all");
                result = replaceNoCase(result, "|columnType|", "string", "all");
                result = replaceNoCase(result, "|columnName|", "column_name", "all");
                result = replaceNoCase(result, "|default|", "", "all");
                result = replaceNoCase(result, "|allowNull|", "true", "all");
                result = replaceNoCase(result, "|limit|", "255", "all");
                break;

            case "remove_column":
                var tableName = len(args.table) ? args.table : inferTableNameFromRemove(args.name);
                result = replaceNoCase(result, "|tableName|", tableName, "all");
                result = replaceNoCase(result, "|columnName|", "column_name", "all");
                break;

            case "change_column":
                var tableName = len(args.table) ? args.table : inferTableName(args.name);
                result = replaceNoCase(result, "|tableName|", tableName, "all");
                result = replaceNoCase(result, "|oldColumnName|", "old_column", "all");
                result = replaceNoCase(result, "|newColumnName|", "new_column", "all");
                result = replaceNoCase(result, "|columnType|", "string", "all");
                break;

            case "rename_column":
                var tableName = len(args.table) ? args.table : inferTableName(args.name);
                result = replaceNoCase(result, "|tableName|", tableName, "all");
                result = replaceNoCase(result, "|oldColumnName|", "old_column", "all");
                result = replaceNoCase(result, "|newColumnName|", "new_column", "all");
                break;

            case "create_index":
                var tableName = len(args.table) ? args.table : inferTableName(args.name);
                result = replaceNoCase(result, "|tableName|", tableName, "all");
                result = replaceNoCase(result, "|columnNames|", "column_name", "all");
                result = replaceNoCase(result, "|indexName|", "", "all");
                result = replaceNoCase(result, "|unique|", "false", "all");
                break;

            case "remove_index":
                var tableName = len(args.table) ? args.table : inferTableName(args.name);
                result = replaceNoCase(result, "|tableName|", tableName, "all");
                result = replaceNoCase(result, "|columnNames|", "column_name", "all");
                result = replaceNoCase(result, "|indexName|", "", "all");
                break;
        }

        return result;
    }

    // Utility functions to infer table names from migration names
    private string function inferTableName(required string migrationName) {
        // CreateUsersTable -> users
        // DropProductsTable -> products
        var match = reFindNoCase("(Create|Drop|Remove)(\w+)Table", migrationName, 1, true);
        if (arrayLen(match.pos) >= 3) {
            var modelName = mid(migrationName, match.pos[3], match.len[3]);
            return lCase(modelName);
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
}