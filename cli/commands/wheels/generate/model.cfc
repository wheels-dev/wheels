/**
 * Generate a model in /models/NAME.cfc and optionally create associated DB table
 * 
 * Examples:
 * wheels generate model User
 * wheels generate model User --properties="name:string,email:string,age:integer"
 * wheels generate model Post --belongs-to=User --has-many=Comments
 * wheels generate model Product --no-migration
 */
component aliases='wheels g model' extends="../base" {
    
    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="migrationService" inject="MigrationService@wheels-cli";
    property name="scaffoldService" inject="ScaffoldService@wheels-cli";
    property name="helpers" inject="helpers@wheels-cli";
    
    /**
     * @name.hint Name of the model to create (singular form)
     * @migration.hint Generate database migration (default: true)
     * @properties.hint Model properties (format: name:type,name2:type2)
     * @belongs-to.hint Parent model relationships (comma-separated)
     * @has-many.hint Child model relationships (comma-separated)
     * @has-one.hint One-to-one relationships (comma-separated)
     * @primary-key.hint Primary key column name(s) (default: id)
     * @table-name.hint Custom database table name
     * @description.hint Model description
     * @force.hint Overwrite existing files
     */
    function run(
        required string name,
        boolean migration = true,
        string properties = "",
        string "belongs-to" = "",
        string "has-many" = "",
        string "has-one" = "",
        string "primary-key" = "id",
        string "table-name" = "",
        string description = "",
        boolean force = false
    ) {
        // Validate model name
        var validation = codeGenerationService.validateName(arguments.name, "model");
        if (!validation.valid) {
            error("Invalid model name: " & arrayToList(validation.errors, ", "));
            return;
        }
        
        print.yellowLine("🏗️  Generating model: #arguments.name#")
             .line();
        
        // Parse properties
        var parsedProperties = parseProperties(arguments.properties);
        
        // Add relationship properties
        parsedProperties = addRelationshipProperties(
            parsedProperties,
            arguments["belongs-to"],
            arguments["has-many"],
            arguments["has-one"]
        );
        
        // Generate model
        var result = codeGenerationService.generateModel(
            name = arguments.name,
            description = arguments.description,
            force = arguments.force,
            properties = parsedProperties,
            baseDirectory = getCWD(),
            primaryKey = arguments["primary-key"],
            tableName = arguments["table-name"]
        );
        
        if (result.success) {
            print.greenLine("✅ Created model: #result.path#");
            
            // Generate migration if requested
            if (arguments.migration) {
                print.line()
                     .yellowLine("📄 Creating migration...");
                
                try {
                    // Use scaffoldService to create migration with properties
                    var migrationPath = "";
                    if (arrayLen(parsedProperties)) {
                        migrationPath = scaffoldService.createMigrationWithProperties(
                            name = arguments.name,
                            properties = parsedProperties,
                            baseDirectory = getCWD()
                        );
                    } else {
                        migrationPath = migrationService.createMigration(
                            name = "create_#helpers.pluralize(lCase(arguments.name))#_table",
                            table = helpers.pluralize(lCase(arguments.name)),
                            model = arguments.name,
                            type = "create",
                            baseDirectory = getCWD()
                        );
                    }
                    
                    print.greenLine("✅ Created migration: #migrationPath#");
                } catch (any e) {
                    print.redLine("❌ Failed to create migration: #e.message#");
                }
            }
            
            // Show next steps
            print.line()
                 .yellowLine("📋 Next steps:")
                 .line("1. Review the generated model")
                 .line("2. Add validation rules if needed")
                 .line("3. Run migrations: wheels dbmigrate up");
            
            if (len(arguments["belongs-to"]) || len(arguments["has-many"]) || len(arguments["has-one"])) {
                print.line("4. Ensure related models exist");
            }
        } else {
            print.redLine("❌ Failed to generate model: #result.error#");
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
        // Add belongsTo relationships
        if (len(arguments.belongsTo)) {
            var parents = listToArray(arguments.belongsTo);
            for (var parent in parents) {
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