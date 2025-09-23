/**
 * Generate a model in /app/models/NAME.cfc and optionally create associated DB table
 *
 * Examples:
 * wheels generate model User
 * wheels generate model User name:string,email:string,age:integer
 * wheels generate model name=User properties=name:string,email:string,age:integer
 * wheels generate model name=Post belongsTo=User hasMany=Comments
 * wheels generate model name=Product migration=false
 */
component aliases='wheels g model' extends="../base" {

    /**
     * Constructor
     */
    function init() {
        return this;
    }

    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="migrationService" inject="MigrationService@wheels-cli";
    property name="scaffoldService" inject="ScaffoldService@wheels-cli";
    property name="helpers" inject="helpers@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @name.hint Name of the model to create (singular form)
     * @properties.hint Model properties (format: name:type,name2:type2)
     * @belongsTo.hint Parent model relationships (comma-separated)
     * @hasMany.hint Child model relationships (comma-separated)
     * @hasOne.hint One-to-one relationships (comma-separated)
     * @primaryKey.hint Primary key column name(s) (default: id)
     * @tableName.hint Custom database table name
     * @description.hint Model description
     * @migration.hint Generate database migration (default: true)
     * @force.hint Overwrite existing files
     */
    function run(
        required string name,
        string properties = "",
        string belongsTo = "",
        string hasMany = "",
        string hasOne = "",
        string primaryKey = "id",
        string tableName = "",
        string description = "",
        boolean migration = true,
        boolean force = false
    ) {
        // Reconstruct arguments for handling --prefixed options
        arguments = reconstructArgs(arguments);

        // Support positional parameter for name
        if (structKeyExists(arguments, "1") && !structKeyExists(arguments, "name")) {
            arguments.name = arguments["1"];
        }
        // Validate model name
        var validation = codeGenerationService.validateName(arguments.name, "model");
        if (!validation.valid) {
            error("Invalid model name: " & arrayToList(validation.errors, ", "));
            return;
        }

        detailOutput.header("", "Generating model: #arguments.name#");

        // Parse properties
        var parsedProperties = parseProperties(arguments.properties);

        // Add relationship properties
        parsedProperties = addRelationshipProperties(
            parsedProperties,
            arguments.belongsTo,
            arguments.hasMany,
            arguments.hasOne
        );

        // Generate model
        var result = codeGenerationService.generateModel(
            name = arguments.name,
            description = arguments.description,
            force = arguments.force,
            properties = parsedProperties,
            baseDirectory = getCWD(),
            belongsTo = arguments.belongsTo,
            hasMany = arguments.hasMany,
            hasOne = arguments.hasOne,
            primaryKey = arguments.primaryKey,
            tableName = arguments.tableName
        );

        if (result.success) {
            detailOutput.create(result.path);

            // Generate migration if requested
            if (arguments.migration) {
                detailOutput.invoke("dbmigrate");

                try {
                    // Use scaffoldService to create migration with properties
                    var migrationPath = "";
                    if (arrayLen(parsedProperties)) {
                        migrationPath = scaffoldService.createMigrationWithProperties(
                            name = arguments.name,
                            properties = parsedProperties,
                            baseDirectory = getCWD(),
                            tableName = arguments.tableName
                        );
                    } else {
                        var actualTableName = len(arguments.tableName) ? arguments.tableName : helpers.pluralize(lCase(arguments.name));
                        migrationPath = migrationService.createMigration(
                            name = "create_#actualTableName#_table",
                            table = actualTableName,
                            model = arguments.name,
                            type = "create",
                            baseDirectory = getCWD()
                        );
                    }

                    detailOutput.create(migrationPath, true);
                } catch (any e) {
                    detailOutput.error("Failed to create migration: #e.message#");
                }
            }

            // Show next steps
            var nextSteps = [
                "Review the generated model at #result.path#",
                "Add validation rules if needed",
                "Run migrations: wheels dbmigrate up"
            ];

            if (len(arguments.belongsTo) || len(arguments.hasMany) || len(arguments.hasOne)) {
                arrayAppend(nextSteps, "Ensure related models exist");
            }

            detailOutput.success("Model generation complete!");
            detailOutput.nextSteps(nextSteps);
        } else {
            detailOutput.error("Failed to generate model: #result.error#");
            setExitCode(1);
        }
    }

    /**
     * Parse properties string into array
     */
    private function parseProperties(required string propertiesString) {
        var properties = [];

        if (len(arguments.propertiesString)) {
            var propList = listToArray(arguments.propertiesString);

            for (var prop in propList) {
                var parts = listToArray(prop, ":");
                if (arrayLen(parts) >= 2) {
                    arrayAppend(properties, {
                        name: parts[1],
                        type: parts[2],
                        required: findNoCase("required", prop) > 0,
                        unique: findNoCase("unique", prop) > 0
                    });
                }
            }
        }

        return properties;
    }

    /**
     * Add relationship properties
     */
    private function addRelationshipProperties(
        required array properties,
        required string belongsTo,
        required string hasMany,
        required string hasOne
    ) {
        // Add belongsTo relationships and their foreign key columns
        if (len(arguments.belongsTo)) {
            var parents = listToArray(arguments.belongsTo);
            for (var parent in parents) {
                // Add the foreign key column for the migration
                var foreignKeyName = lCase(parent) & "Id";
                var hasFK = false;

                // Check if FK already exists in properties
                for (var prop in arguments.properties) {
                    if (prop.name == foreignKeyName) {
                        hasFK = true;
                        break;
                    }
                }

                // Add FK column if not already present
                if (!hasFK) {
                    arrayAppend(arguments.properties, {
                        name: foreignKeyName,
                        type: "integer",
                        required: false,
                        unique: false
                    });
                }

                // Add the association info (for model generation, not migration)
                arrayAppend(arguments.properties, {
                    name: lCase(parent),
                    association: "belongsTo",
                    class: helpers.capitalize(parent)
                });
            }
        }

        // Add hasMany relationships
        if (len(arguments.hasMany)) {
            var children = listToArray(arguments.hasMany);
            for (var child in children) {
                arrayAppend(arguments.properties, {
                    name: lCase(child),
                    association: "hasMany",
                    class: helpers.capitalize(helpers.singularize(child))
                });
            }
        }

        // Add hasOne relationships
        if (len(arguments.hasOne)) {
            var ones = listToArray(arguments.hasOne);
            for (var one in ones) {
                arrayAppend(arguments.properties, {
                    name: lCase(one),
                    association: "hasOne",
                    class: helpers.capitalize(one)
                });
            }
        }

        return arguments.properties;
    }
}
