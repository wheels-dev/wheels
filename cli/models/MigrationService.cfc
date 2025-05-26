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
        var content = 'component extends="wheels.migrator.Migration" {' & chr(10) & chr(10);
        content &= '    function up() {' & chr(10);
        content &= '        transaction {' & chr(10);
        
        // Determine table name
        var tableName = len(arguments.table) ? arguments.table : "";
        if (!len(tableName) && len(arguments.model)) {
            tableName = pluralize(lCase(arguments.model));
        }
        if (!len(tableName)) {
            tableName = extractTableFromName(arguments.className);
        }
        
        switch (arguments.type) {
            case "create":
                content &= generateCreateTableContent(tableName);
                break;
            case "modify":
                content &= generateModifyTableContent(tableName);
                break;
            case "drop":
                content &= generateDropTableContent(tableName);
                break;
            default:
                content &= '            // Add your migration code here' & chr(10);
        }
        
        content &= '        }' & chr(10);
        content &= '    }' & chr(10) & chr(10);
        
        content &= '    function down() {' & chr(10);
        content &= '        transaction {' & chr(10);
        
        switch (arguments.type) {
            case "create":
                content &= '            dropTable("' & tableName & '");' & chr(10);
                break;
            default:
                content &= '            // Add your rollback code here' & chr(10);
        }
        
        content &= '        }' & chr(10);
        content &= '    }' & chr(10) & chr(10);
        content &= '}';
        
        return content;
    }
    
    /**
     * Generate create table content
     */
    private function generateCreateTableContent(required string tableName) {
        var content = '            t = createTable(name="' & arguments.tableName & '");' & chr(10);
        content &= '            t.primaryKey();' & chr(10);
        content &= '            ' & chr(10);
        content &= '            // Add your columns here' & chr(10);
        content &= '            // t.string(columnName="name", null=false);' & chr(10);
        content &= '            // t.text(columnName="description");' & chr(10);
        content &= '            // t.integer(columnName="status", default=1);' & chr(10);
        content &= '            // t.decimal(columnName="price", precision=10, scale=2);' & chr(10);
        content &= '            // t.boolean(columnName="active", default=true);' & chr(10);
        content &= '            // t.date(columnName="birthDate");' & chr(10);
        content &= '            // t.datetime(columnName="publishedAt");' & chr(10);
        content &= '            ' & chr(10);
        content &= '            t.timestamps();' & chr(10);
        content &= '            t.create();' & chr(10);
        
        return content;
    }
    
    /**
     * Generate modify table content
     */
    private function generateModifyTableContent(required string tableName) {
        var content = '            t = changeTable(name="' & arguments.tableName & '");' & chr(10);
        content &= '            ' & chr(10);
        content &= '            // Add your modifications here' & chr(10);
        content &= '            // t.addColumn(columnName="newColumn", columnType="string");' & chr(10);
        content &= '            // t.changeColumn(columnName="existingColumn", columnType="text");' & chr(10);
        content &= '            // t.removeColumn(columnName="oldColumn");' & chr(10);
        content &= '            // t.renameColumn(columnName="oldName", newColumnName="newName");' & chr(10);
        content &= '            ' & chr(10);
        content &= '            t.change();' & chr(10);
        
        return content;
    }
    
    /**
     * Generate drop table content
     */
    private function generateDropTableContent(required string tableName) {
        return '            dropTable("' & arguments.tableName & '");' & chr(10);
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