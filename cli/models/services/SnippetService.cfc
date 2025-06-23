/**
 * Snippet Service for Wheels CLI
 * Handles snippet loading, rendering, and management
 * 
 * @singleton
 * @author CFWheels Team
 * @version 3.0.0
 */
component accessors="true" singleton {
    
    // DI Properties
    property name="fileSystem" inject="FileSystem";
    property name="log" inject="logbox:logger:{this}";
    property name="configService" inject="ConfigService@wheels-cli-next";
    
    // Service Properties
    property name="settings" type="struct";
    property name="snippetCache" type="struct";
    property name="customSnippetPaths" type="array";
    
    /**
     * Constructor
     */
    function init(struct settings = {}) {
        variables.settings = arguments.settings;
        variables.snippetCache = {};
        variables.customSnippetPaths = [];
        
        return this;
    }
    
    /**
     * Render snippet with data
     */
    function render(required string snippet, struct data = {}) {
        var content = "";
        
        // Load snippet from file or cache
        if (fileExists(arguments.snippet)) {
            content = fileRead(arguments.snippet);
        } else {
            content = arguments.snippet;
        }
        
        // Get placeholder settings
        var prefix = getSetting("placeholder.prefix", "@");
        var suffix = getSetting("placeholder.suffix", "@");
        
        // Merge data with defaults
        var renderData = getMergedData(arguments.data);
        
        // Replace placeholders
        for (var key in renderData) {
            var placeholder = prefix & uCase(key) & suffix;
            var value = renderData[key];
            
            // Handle different value types
            if (isSimpleValue(value)) {
                content = replace(content, placeholder, value, "all");
            } else if (isArray(value)) {
                content = replace(content, placeholder, arrayToList(value, ", "), "all");
            } else if (isStruct(value)) {
                content = replace(content, placeholder, serializeJSON(value), "all");
            }
        }
        
        // Process conditional blocks
        content = processConditionals(content, renderData);
        
        // Process loops
        content = processLoops(content, renderData);
        
        // Clean up any remaining placeholders
        content = cleanupPlaceholders(content);
        
        return content;
    }
    
    /**
     * Get snippet by type and name
     */
    function getSnippet(required string type, string name = "default") {
        var cacheKey = arguments.type & ":" & arguments.name;
        
        // Check cache
        if (structKeyExists(variables.snippetCache, cacheKey)) {
            return variables.snippetCache[cacheKey];
        }
        
        // Search for snippet file
        var snippetPath = findSnippet(arguments.type, arguments.name);
        
        if (len(snippetPath)) {
            var content = fileRead(snippetPath);
            
            // Cache the snippet
            variables.snippetCache[cacheKey] = content;
            
            return content;
        }
        
        // Return built-in snippet
        return getBuiltInSnippet(arguments.type, arguments.name);
    }
    
    /**
     * Find snippet file in search paths
     */
    private function findSnippet(required string type, required string name) {
        var searchPaths = getSnippetPaths();
        var fileName = arguments.name & ".cfc";
        
        // Special handling for view snippets
        if (arguments.type == "view") {
            fileName = arguments.name & ".cfm";
        }
        
        // Search custom paths first
        for (var searchPath in searchPaths) {
            var fullPath = searchPath & "/" & arguments.type & "/" & fileName;
            fullPath = replace(fullPath, "//", "/", "all");
            
            if (fileExists(fullPath)) {
                log.debug("Found snippet: #fullPath#");
                return fullPath;
            }
        }
        
        return "";
    }
    
    /**
     * Get all snippet search paths
     */
    function getSnippetPaths() {
        var paths = [];
        
        // Add custom snippet paths from config
        var configPaths = getConfigService().get("snippets.searchPaths", []);
        for (var path in configPaths) {
            if (directoryExists(expandPath(path))) {
                arrayAppend(paths, expandPath(path));
            }
        }
        
        // Add paths from settings
        var settingPaths = getSetting("searchPaths", []);
        for (var path in settingPaths) {
            var expandedPath = expandPath(path);
            if (directoryExists(expandedPath) && !arrayFind(paths, expandedPath)) {
                arrayAppend(paths, expandedPath);
            }
        }
        
        // Add default module snippet path
        var modulePath = expandPath("/wheelscli/snippets");
        if (directoryExists(modulePath) && !arrayFind(paths, modulePath)) {
            arrayAppend(paths, modulePath);
        }
        
        return paths;
    }
    
    /**
     * Check if snippet is custom (not built-in)
     */
    function isCustomSnippet(required string path) {
        var builtInPath = expandPath("/wheelscli/snippets");
        return !findNoCase(builtInPath, arguments.path);
    }
    
    /**
     * List available snippets
     */
    function listSnippets(string type = "") {
        var snippets = {
            builtin = {},
            custom = {}
        };
        
        var searchPaths = getSnippetPaths();
        var types = len(arguments.type) ? [arguments.type] : ["model", "controller", "view", "migration", "test"];
        
        for (var searchPath in searchPaths) {
            var isCustom = isCustomSnippet(searchPath);
            
            for (var snippetType in types) {
                var typePath = searchPath & "/" & snippetType;
                
                if (directoryExists(typePath)) {
                    var files = directoryList(typePath, false, "name", "*.cf*");
                    
                    for (var file in files) {
                        var snippetName = listFirst(file, ".");
                        
                        if (isCustom) {
                            if (!structKeyExists(snippets.custom, snippetType)) {
                                snippets.custom[snippetType] = [];
                            }
                            if (!arrayFind(snippets.custom[snippetType], snippetName)) {
                                arrayAppend(snippets.custom[snippetType], snippetName);
                            }
                        } else {
                            if (!structKeyExists(snippets.builtin, snippetType)) {
                                snippets.builtin[snippetType] = [];
                            }
                            if (!arrayFind(snippets.builtin[snippetType], snippetName)) {
                                arrayAppend(snippets.builtin[snippetType], snippetName);
                            }
                        }
                    }
                }
            }
        }
        
        return snippets;
    }
    
    /**
     * Copy snippet to project
     */
    function copySnippet(required string type, required string name, required string destination) {
        var snippetPath = findSnippet(arguments.type, arguments.name);
        
        if (!len(snippetPath)) {
            throw(type="SnippetNotFound", message="Snippet '#arguments.type#/#arguments.name#' not found");
        }
        
        // Ensure destination directory exists
        var destDir = getDirectoryFromPath(arguments.destination);
        if (!directoryExists(destDir)) {
            directoryCreate(destDir, true);
        }
        
        // Copy the snippet
        fileCopy(snippetPath, arguments.destination);
        
        log.info("Copied snippet '#arguments.type#/#arguments.name#' to '#arguments.destination#'");
        
        return true;
    }
    
    /**
     * Get merged data with defaults
     */
    private function getMergedData(required struct data) {
        var merged = {};
        
        // Add snippet defaults from settings
        var defaults = getSetting("defaults", {});
        structAppend(merged, defaults);
        
        // Add snippet defaults from config
        var configDefaults = getConfigService().get("snippets", {});
        structAppend(merged, configDefaults);
        
        // Add common variables
        merged.timestamp = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
        merged.year = year(now());
        merged.date = dateFormat(now(), "yyyy-mm-dd");
        
        // Add provided data (highest priority)
        structAppend(merged, arguments.data, true);
        
        return merged;
    }
    
    /**
     * Process conditional blocks in snippet
     */
    private function processConditionals(required string content, required struct data) {
        var processed = arguments.content;
        
        // Pattern: @IF(condition)@...@ENDIF@
        var pattern = "@IF\(([^)]+)\)@(.*?)@ENDIF@";
        var matches = reMatch(pattern, processed);
        
        for (var match in matches) {
            var condition = reReplace(match, pattern, "\1");
            var block = reReplace(match, pattern, "\2");
            
            // Evaluate condition
            var show = evaluateCondition(condition, arguments.data);
            
            if (show) {
                processed = replace(processed, match, block);
            } else {
                processed = replace(processed, match, "");
            }
        }
        
        return processed;
    }
    
    /**
     * Process loops in snippet
     */
    private function processLoops(required string content, required struct data) {
        var processed = arguments.content;
        
        // Pattern: @EACH(items as item)@...@ENDEACH@
        var pattern = "@EACH\(([^)]+)\)@(.*?)@ENDEACH@";
        var matches = reMatch(pattern, processed);
        
        for (var match in matches) {
            var loopDef = reReplace(match, pattern, "\1");
            var block = reReplace(match, pattern, "\2");
            
            // Parse loop definition
            var parts = listToArray(loopDef, " as ");
            if (arrayLen(parts) == 2) {
                var collectionName = trim(parts[1]);
                var itemName = trim(parts[2]);
                
                if (structKeyExists(arguments.data, collectionName) && isArray(arguments.data[collectionName])) {
                    var output = "";
                    
                    for (var item in arguments.data[collectionName]) {
                        var itemData = duplicate(arguments.data);
                        itemData[itemName] = item;
                        output &= render(block, itemData);
                    }
                    
                    processed = replace(processed, match, output);
                } else {
                    processed = replace(processed, match, "");
                }
            }
        }
        
        return processed;
    }
    
    /**
     * Evaluate condition
     */
    private function evaluateCondition(required string condition, required struct data) {
        var cond = trim(arguments.condition);
        
        // Simple existence check
        if (structKeyExists(arguments.data, cond)) {
            var value = arguments.data[cond];
            if (isBoolean(value)) {
                return value;
            }
            if (isNumeric(value)) {
                return value != 0;
            }
            if (isSimpleValue(value)) {
                return len(trim(value)) > 0;
            }
            return true;
        }
        
        // Negation
        if (left(cond, 1) == "!") {
            return !evaluateCondition(mid(cond, 2, len(cond)), arguments.data);
        }
        
        return false;
    }
    
    /**
     * Clean up remaining placeholders
     */
    private function cleanupPlaceholders(required string content) {
        var prefix = getSetting("placeholder.prefix", "@");
        var suffix = getSetting("placeholder.suffix", "@");
        
        // Remove any remaining placeholders
        var pattern = prefix & "[A-Z_]+" & suffix;
        return reReplace(arguments.content, pattern, "", "all");
    }
    
    /**
     * Get setting from settings
     */
    private function getSetting(required string key, any defaultValue = "") {
        if (structKeyExists(variables.settings, arguments.key)) {
            return variables.settings[arguments.key];
        }
        return arguments.defaultValue;
    }
    
    /**
     * Get built-in snippet
     */
    private function getBuiltInSnippet(required string type, required string name) {
        // These would be the actual built-in snippets
        // For now, returning empty snippets
        
        switch(arguments.type) {
            case "model":
                return getBuiltInModelSnippet(arguments.name);
            case "controller":
                return getBuiltInControllerSnippet(arguments.name);
            case "view":
                return getBuiltInViewSnippet(arguments.name);
            case "migration":
                return getBuiltInMigrationSnippet(arguments.name);
            case "test":
                return getBuiltInTestSnippet(arguments.name);
            default:
                return "";
        }
    }
    
    /**
     * Built-in model snippet
     */
    private function getBuiltInModelSnippet(required string name) {
        if (arguments.name == "default") {
            return 'component extends="Model" {
    
    /**
     * @MODEL_NAME@ Model
     * @DESCRIPTION@
     * 
     * @author @AUTHOR@
     * @date @DATE@
     */
    function config() {
        // Table name
        table("@TABLE_NAME@");
        
        // Associations
        @IF(BELONGS_TO)@
        belongsTo("@BELONGS_TO@");
        @ENDIF@
        
        @IF(HAS_MANY)@
        hasMany("@HAS_MANY@");
        @ENDIF@
        
        @IF(HAS_ONE)@
        hasOne("@HAS_ONE@");
        @ENDIF@
        
        // Validations
        @IF(VALIDATIONS)@
        @EACH(VALIDATIONS as validation)@
        validates@validation.type@("@validation.property@"@validation.options@);
        @ENDEACH@
        @ENDIF@
    }
    
}';
        }
        
        return "";
    }
    
    /**
     * Built-in controller snippet
     */
    private function getBuiltInControllerSnippet(required string name) {
        if (arguments.name == "default") {
            return 'component extends="Controller" {
    
    /**
     * @CONTROLLER_NAME@ Controller
     * @DESCRIPTION@
     * 
     * @author @AUTHOR@
     * @date @DATE@
     */
    function config() {
        // Filters
        @IF(FILTERS)@
        @EACH(FILTERS as filter)@
        filters("@filter@");
        @ENDEACH@
        @ENDIF@
    }
    
    @IF(ACTIONS)@
    @EACH(ACTIONS as action)@
    /**
     * @action@ action
     */
    function @action@() {
        // Action logic here
    }
    
    @ENDEACH@
    @ENDIF@
}';
        }
        
        return "";
    }
    
    /**
     * Built-in view snippet
     */
    private function getBuiltInViewSnippet(required string name) {
        if (arguments.name == "default") {
            return '<cfoutput>

<h1>@TITLE@</h1>

@CONTENT@

</cfoutput>';
        }
        
        return "";
    }
    
    /**
     * Built-in migration snippet
     */
    private function getBuiltInMigrationSnippet(required string name) {
        if (arguments.name == "default") {
            return 'component extends="wheels.migrator.Migration" {
    
    /**
     * @DESCRIPTION@
     * 
     * @author @AUTHOR@
     * @date @DATE@
     */
    function up() {
        transaction {
            // Migration code here
            @IF(CREATE_TABLE)@
            createTable(name="@TABLE_NAME@", force=true) {
                t.primaryKey();
                @EACH(COLUMNS as column)@
                t.@column.type@(columnName="@column.name@"@column.options@);
                @ENDEACH@
                t.timestamps();
            };
            @ENDIF@
            
            @IF(ADD_COLUMN)@
            addColumn(table="@TABLE_NAME@", columnName="@COLUMN_NAME@", columnType="@COLUMN_TYPE@"@COLUMN_OPTIONS@);
            @ENDIF@
            
            @IF(REMOVE_COLUMN)@
            removeColumn(table="@TABLE_NAME@", columnName="@COLUMN_NAME@");
            @ENDIF@
        }
    }
    
    function down() {
        transaction {
            // Rollback code here
            @IF(CREATE_TABLE)@
            dropTable("@TABLE_NAME@");
            @ENDIF@
            
            @IF(ADD_COLUMN)@
            removeColumn(table="@TABLE_NAME@", columnName="@COLUMN_NAME@");
            @ENDIF@
            
            @IF(REMOVE_COLUMN)@
            addColumn(table="@TABLE_NAME@", columnName="@COLUMN_NAME@", columnType="@COLUMN_TYPE@"@COLUMN_OPTIONS@);
            @ENDIF@
        }
    }
    
}';
        }
        
        return "";
    }
    
    /**
     * Built-in test snippet
     */
    private function getBuiltInTestSnippet(required string name) {
        if (arguments.name == "default") {
            return 'component extends="wheels.test" {
    
    /**
     * @TEST_NAME@ Test
     * @DESCRIPTION@
     * 
     * @author @AUTHOR@
     * @date @DATE@
     */
    
    function setup() {
        // Test setup
    }
    
    function teardown() {
        // Test cleanup
    }
    
    @IF(TEST_METHODS)@
    @EACH(TEST_METHODS as method)@
    function test_@method@() {
        // Test implementation
        assert(true);
    }
    
    @ENDEACH@
    @ENDIF@
}';
        }
        
        return "";
    }
}