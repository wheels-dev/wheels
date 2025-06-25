component {
    
    property name="print" inject="print";
    
    /**
     * Create a new migration file
     */
    function createMigration(
        required string name,
        string table = "",
        string model = "",
        string type = "create",
        string baseDirectory = ""
    ) {
        var timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
        var className = sanitizeMigrationName(arguments.name);
        var fileName = timestamp & "_" & className & ".cfc";
        var migrationDir = resolvePath("app/migrator/migrations", arguments.baseDirectory);
        
        // Create migrations directory if it doesn't exist
        if (!directoryExists(migrationDir)) {
            directoryCreate(migrationDir, true);
        }
        
        var migrationPath = migrationDir & "/" & fileName;
        
        // Generate migration content
        var content = generateMigrationContent(
            className = className,
            table = arguments.table,
            model = arguments.model,
            type = arguments.type
        );
        
        // Write migration file
        fileWrite(migrationPath, content);
        
        return "app/migrator/migrations/" & fileName;
    }
    
    /**
     * Create a new seeder file
     */
    function createSeeder(
        required string name,
        string model = "",
        numeric count = 10
    ) {
        var seederName = sanitizeSeederName(arguments.name);
        var seederDir = resolvePath("app/migrator/seeds");
        
        // Create seeds directory if it doesn't exist
        if (!directoryExists(seederDir)) {
            directoryCreate(seederDir, true);
        }
        
        var seederPath = seederDir & "/" & seederName & ".cfc";
        
        // Generate seeder content
        var content = generateSeederContent(
            seederName = seederName,
            model = arguments.model,
            count = arguments.count
        );
        
        // Write seeder file
        fileWrite(seederPath, content);
        
        return "app/migrator/seeds/" & seederName & ".cfc";
    }
    
    /**
     * Generate migration content based on type
     */
    private function generateMigrationContent(
        required string className,
        string table = "",
        string model = "",
        string type = "create"
    ) {
        // Determine table name
        var tableName = len(arguments.table) ? arguments.table : "";
        if (!len(tableName) && len(arguments.model)) {
            tableName = pluralize(lCase(arguments.model));
        }
        if (!len(tableName)) {
            tableName = extractTableFromName(arguments.className);
        }
        
        // Determine template file based on type
        var templateFile = "";
        switch (arguments.type) {
            case "create":
                templateFile = "create-table.txt";
                break;
            case "modify":
                templateFile = "change-table.txt";
                break;
            default:
                templateFile = "blank.txt";
        }
        
        // Load and process template
        return loadAndProcessTemplate(
            templateFile = templateFile,
            tableName = tableName,
            className = arguments.className
        );
    }
    
    /**
     * Load and process template file
     */
    private function loadAndProcessTemplate(
        required string templateFile,
        required string tableName,
        required string className
    ) {
        // First try app/snippets directory (preferred)
        var templatePath = resolvePath("app/snippets/dbmigrate/" & arguments.templateFile);
        
        // If not found, try the module templates directory
        if (!fileExists(templatePath)) {
            templatePath = expandPath("/wheels-cli/templates/dbmigrate/" & arguments.templateFile);
        }
        
        // Read template file
        if (!fileExists(templatePath)) {
            throw(
                type = "MigrationService.TemplateNotFound",
                message = "Migration template not found",
                detail = "The template file '" & arguments.templateFile & "' was not found at: " & templatePath
            );
        }
        
        var content = fileRead(templatePath);
        
        // Replace template placeholders
        content = replace(content, "|tableName|", arguments.tableName, "all");
        content = replace(content, "|DBMigrateExtends|", "wheels.migrator.Migration", "all");
        content = replace(content, "|DBMigrateDescription|", "Migration: " & arguments.className, "all");
        content = replace(content, "|force|", "false", "all");
        content = replace(content, "|id|", "true", "all");
        content = replace(content, "|primaryKey|", "id", "all");
        
        return content;
    }
    
    /**
     * Generate seeder content
     */
    private function generateSeederContent(
        required string seederName,
        string model = "",
        numeric count = 10
    ) {
        var modelName = len(arguments.model) ? arguments.model : extractModelFromSeederName(arguments.seederName);
        
        var content = 'component extends="wheels.migrator.Seed" {' & chr(10) & chr(10);
        content &= '    function run() {' & chr(10);
        content &= '        // Seed ' & arguments.count & ' ' & modelName & ' records' & chr(10);
        content &= '        for (var i = 1; i <= ' & arguments.count & '; i++) {' & chr(10);
        content &= '            model("' & modelName & '").create(' & chr(10);
        content &= '                name = "' & modelName & ' ##i##",' & chr(10);
        content &= '                // Add more properties here' & chr(10);
        content &= '                createdAt = now(),' & chr(10);
        content &= '                updatedAt = now()' & chr(10);
        content &= '            );' & chr(10);
        content &= '        }' & chr(10);
        content &= '        ' & chr(10);
        content &= '        print.greenLine("Seeded ' & arguments.count & ' ' & modelName & ' records");' & chr(10);
        content &= '    }' & chr(10) & chr(10);
        content &= '}';
        
        return content;
    }
    
    /**
     * Sanitize migration name
     */
    private function sanitizeMigrationName(required string name) {
        // Remove special characters and convert to underscore format
        var cleaned = reReplace(arguments.name, "[^a-zA-Z0-9_]", "_", "all");
        // Convert camelCase to snake_case
        cleaned = reReplace(cleaned, "([a-z])([A-Z])", "\1_\2", "all");
        return lCase(cleaned);
    }
    
    /**
     * Sanitize seeder name
     */
    private function sanitizeSeederName(required string name) {
        // Ensure it ends with "Seeder"
        var cleaned = arguments.name;
        if (!reFind("Seeder$", cleaned)) {
            cleaned &= "Seeder";
        }
        // Remove special characters
        cleaned = reReplace(cleaned, "[^a-zA-Z0-9]", "", "all");
        // Ensure first letter is uppercase
        return uCase(left(cleaned, 1)) & right(cleaned, len(cleaned) - 1);
    }
    
    /**
     * Extract table name from migration name
     */
    private function extractTableFromName(required string name) {
        // Look for patterns like create_users_table or add_column_to_users
        if (reFind("create_(\w+)_table", arguments.name)) {
            var matches = reMatch("create_(\w+)_table", arguments.name);
            if (arrayLen(matches)) {
                return reReplace(matches[1], "create_|_table", "", "all");
            }
        } else if (reFind("to_(\w+)$", arguments.name)) {
            var matches = reMatch("to_(\w+)$", arguments.name);
            if (arrayLen(matches)) {
                return reReplace(matches[1], "to_", "", "all");
            }
        }
        
        return "table_name";
    }
    
    /**
     * Extract model name from seeder name
     */
    private function extractModelFromSeederName(required string name) {
        // Remove "Seeder" suffix
        var modelName = reReplace(arguments.name, "Seeder$", "");
        // Singularize if needed
        return singularize(modelName);
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
            "woman" = "women"
        };
        
        if (structKeyExists(irregulars, lCase(singular))) {
            return irregulars[lCase(singular)];
        }
        
        // Handle regular pluralization rules
        if (reFind("(s|ss|sh|ch|x|z)$", singular)) {
            return singular & "es";
        } else if (reFind("y$", singular) && !reFind("[aeiou]y$", singular)) {
            return left(singular, len(singular) - 1) & "ies";
        } else {
            return singular & "s";
        }
    }
    
    /**
     * Simple singularization helper
     */
    private function singularize(required string word) {
        var plural = trim(arguments.word);
        
        // Handle common irregular plurals
        var irregulars = {
            "people" = "person",
            "children" = "child",
            "men" = "man",
            "women" = "woman"
        };
        
        if (structKeyExists(irregulars, lCase(plural))) {
            return irregulars[lCase(plural)];
        }
        
        // Handle regular singularization rules
        if (reFind("ies$", plural)) {
            return left(plural, len(plural) - 3) & "y";
        } else if (reFind("es$", plural)) {
            return left(plural, len(plural) - 2);
        } else if (reFind("s$", plural)) {
            return left(plural, len(plural) - 1);
        }
        
        return plural;
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
}