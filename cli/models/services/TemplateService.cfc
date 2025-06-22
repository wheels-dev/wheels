/**
 * Template Service for Wheels CLI
 * Handles template loading, rendering, and management
 * 
 * @singleton
 * @author CFWheels Team
 * @version 3.0.0
 */
component accessors="true" singleton {
    
    // DI Properties
    property name="fileSystem" inject="FileSystem";
    property name="log" inject="logbox:logger:{this}";
    property name="configService" inject="ConfigService@wheelscli";
    
    // Service Properties
    property name="settings" type="struct";
    property name="templateCache" type="struct";
    property name="customTemplatePaths" type="array";
    
    /**
     * Constructor
     */
    function init(struct settings = {}) {
        variables.settings = arguments.settings;
        variables.templateCache = {};
        variables.customTemplatePaths = [];
        
        return this;
    }
    
    /**
     * Render template with data
     */
    function render(required string template, struct data = {}) {
        var content = "";
        
        // Load template from file or cache
        if (fileExists(arguments.template)) {
            content = fileRead(arguments.template);
        } else {
            content = arguments.template;
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
     * Get template by type and name
     */
    function getTemplate(required string type, string name = "default") {
        var cacheKey = arguments.type & ":" & arguments.name;
        
        // Check cache
        if (structKeyExists(variables.templateCache, cacheKey)) {
            return variables.templateCache[cacheKey];
        }
        
        // Search for template file
        var templatePath = findTemplate(arguments.type, arguments.name);
        
        if (len(templatePath)) {
            var content = fileRead(templatePath);
            
            // Cache the template
            variables.templateCache[cacheKey] = content;
            
            return content;
        }
        
        // Return built-in template
        return getBuiltInTemplate(arguments.type, arguments.name);
    }
    
    /**
     * Find template file in search paths
     */
    private function findTemplate(required string type, required string name) {
        var searchPaths = getTemplatePaths();
        var fileName = arguments.name & ".cfc";
        
        // Special handling for view templates
        if (arguments.type == "view") {
            fileName = arguments.name & ".cfm";
        }
        
        // Search custom paths first
        for (var searchPath in searchPaths) {
            var fullPath = searchPath & "/" & arguments.type & "/" & fileName;
            fullPath = replace(fullPath, "//", "/", "all");
            
            if (fileExists(fullPath)) {
                log.debug("Found template: #fullPath#");
                return fullPath;
            }
        }
        
        return "";
    }
    
    /**
     * Get all template search paths
     */
    function getTemplatePaths() {
        var paths = [];
        
        // Add custom template paths from config
        var configPaths = getConfigService().get("templates.searchPaths", []);
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
        
        // Add default module template path
        var modulePath = expandPath("/wheelscli/templates");
        if (directoryExists(modulePath) && !arrayFind(paths, modulePath)) {
            arrayAppend(paths, modulePath);
        }
        
        return paths;
    }
    
    /**
     * Check if template is custom (not built-in)
     */
    function isCustomTemplate(required string path) {
        var builtInPath = expandPath("/wheelscli/templates");
        return !findNoCase(builtInPath, arguments.path);
    }
    
    /**
     * List available templates
     */
    function listTemplates(string type = "") {
        var templates = {
            builtin = {},
            custom = {}
        };
        
        var searchPaths = getTemplatePaths();
        var types = len(arguments.type) ? [arguments.type] : ["model", "controller", "view", "migration", "test"];
        
        for (var searchPath in searchPaths) {
            var isCustom = isCustomTemplate(searchPath);
            
            for (var templateType in types) {
                var typePath = searchPath & "/" & templateType;
                
                if (directoryExists(typePath)) {
                    var files = directoryList(typePath, false, "name", "*.cf*");
                    
                    for (var file in files) {
                        var templateName = listFirst(file, ".");
                        
                        if (isCustom) {
                            if (!structKeyExists(templates.custom, templateType)) {
                                templates.custom[templateType] = [];
                            }
                            if (!arrayFind(templates.custom[templateType], templateName)) {
                                arrayAppend(templates.custom[templateType], templateName);
                            }
                        } else {
                            if (!structKeyExists(templates.builtin, templateType)) {
                                templates.builtin[templateType] = [];
                            }
                            if (!arrayFind(templates.builtin[templateType], templateName)) {
                                arrayAppend(templates.builtin[templateType], templateName);
                            }
                        }
                    }
                }
            }
        }
        
        return templates;
    }
    
    /**
     * Copy template to project
     */
    function copyTemplate(required string type, required string name, required string destination) {
        var templatePath = findTemplate(arguments.type, arguments.name);
        
        if (!len(templatePath)) {
            throw(type="TemplateNotFound", message="Template '#arguments.type#/#arguments.name#' not found");
        }
        
        // Ensure destination directory exists
        var destDir = getDirectoryFromPath(arguments.destination);
        if (!directoryExists(destDir)) {
            directoryCreate(destDir, true);
        }
        
        // Copy the template
        fileCopy(templatePath, arguments.destination);
        
        log.info("Copied template '#arguments.type#/#arguments.name#' to '#arguments.destination#'");
        
        return true;
    }
    
    /**
     * Get merged data with defaults
     */
    private function getMergedData(required struct data) {
        var merged = {};
        
        // Add template defaults from settings
        var defaults = getSetting("defaults", {});
        structAppend(merged, defaults);
        
        // Add template defaults from config
        var configDefaults = getConfigService().get("templates", {});
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
     * Process conditional blocks in template
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
     * Process loops in template
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
     * Get built-in template
     */
    private function getBuiltInTemplate(required string type, required string name) {
        // These would be the actual built-in templates
        // For now, returning empty templates
        
        switch(arguments.type) {
            case "model":
                return getBuiltInModelTemplate(arguments.name);
            case "controller":
                return getBuiltInControllerTemplate(arguments.name);
            case "view":
                return getBuiltInViewTemplate(arguments.name);
            case "migration":
                return getBuiltInMigrationTemplate(arguments.name);
            case "test":
                return getBuiltInTestTemplate(arguments.name);
            default:
                return "";
        }
    }
    
    /**
     * Built-in model template
     */
    private function getBuiltInModelTemplate(required string name) {
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
     * Built-in controller template
     */
    private function getBuiltInControllerTemplate(required string name) {
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
     * Built-in view template
     */
    private function getBuiltInViewTemplate(required string name) {
        if (arguments.name == "default") {
            return '<cfoutput>

<h1>@TITLE@</h1>

@CONTENT@

</cfoutput>';
        }
        
        return "";
    }
    
    /**
     * Built-in migration template
     */
    private function getBuiltInMigrationTemplate(required string name) {
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
     * Built-in test template
     */
    private function getBuiltInTestTemplate(required string name) {
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