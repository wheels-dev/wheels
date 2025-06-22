/**
 * Formatter Service for Wheels CLI
 * Handles string formatting, pluralization, and table display
 * 
 * @singleton
 * @author CFWheels Team
 * @version 3.0.0
 */
component accessors="true" singleton {
    
    // DI Properties
    property name="print" inject="print";
    property name="log" inject="logbox:logger:{this}";
    
    // Pluralization rules
    property name="pluralRules" type="array";
    property name="singularRules" type="array";
    property name="uncountables" type="array";
    property name="irregulars" type="struct";
    
    /**
     * Constructor
     */
    function init() {
        initializePluralizationRules();
        return this;
    }
    
    /**
     * Initialize pluralization rules
     */
    private function initializePluralizationRules() {
        // Irregular plurals
        variables.irregulars = {
            "person" = "people",
            "man" = "men",
            "woman" = "women",
            "child" = "children",
            "tooth" = "teeth",
            "foot" = "feet",
            "mouse" = "mice",
            "goose" = "geese"
        };
        
        // Uncountable words
        variables.uncountables = [
            "equipment", "information", "rice", "money", "species",
            "series", "fish", "sheep", "deer", "news", "food"
        ];
        
        // Plural rules (order matters - most specific first)
        variables.pluralRules = [
            {pattern = "(quiz)$", replacement = "$1zes"},
            {pattern = "^(ox)$", replacement = "$1en"},
            {pattern = "([m|l])ouse$", replacement = "$1ice"},
            {pattern = "(matr|vert|ind)(?:ix|ex)$", replacement = "$1ices"},
            {pattern = "(x|ch|ss|sh)$", replacement = "$1es"},
            {pattern = "([^aeiouy]|qu)y$", replacement = "$1ies"},
            {pattern = "(hive)$", replacement = "$1s"},
            {pattern = "(?:([^f])fe|([lr])f)$", replacement = "$1$2ves"},
            {pattern = "sis$", replacement = "ses"},
            {pattern = "([ti])um$", replacement = "$1a"},
            {pattern = "(buffal|tomat)o$", replacement = "$1oes"},
            {pattern = "(bu)s$", replacement = "$1ses"},
            {pattern = "(alias|status)$", replacement = "$1es"},
            {pattern = "(octop|vir)us$", replacement = "$1i"},
            {pattern = "(ax|test)is$", replacement = "$1es"},
            {pattern = "s$", replacement = "s"},
            {pattern = "$", replacement = "s"}
        ];
        
        // Singular rules
        variables.singularRules = [
            {pattern = "(quiz)zes$", replacement = "$1"},
            {pattern = "(matr)ices$", replacement = "$1ix"},
            {pattern = "(vert|ind)ices$", replacement = "$1ex"},
            {pattern = "^(ox)en", replacement = "$1"},
            {pattern = "(alias|status)es$", replacement = "$1"},
            {pattern = "(octop|vir)i$", replacement = "$1us"},
            {pattern = "(cris|ax|test)es$", replacement = "$1is"},
            {pattern = "(shoe)s$", replacement = "$1"},
            {pattern = "(o)es$", replacement = "$1"},
            {pattern = "(bus)es$", replacement = "$1"},
            {pattern = "([m|l])ice$", replacement = "$1ouse"},
            {pattern = "(x|ch|ss|sh)es$", replacement = "$1"},
            {pattern = "(m)ovies$", replacement = "$1ovie"},
            {pattern = "(s)eries$", replacement = "$1eries"},
            {pattern = "([^aeiouy]|qu)ies$", replacement = "$1y"},
            {pattern = "([lr])ves$", replacement = "$1f"},
            {pattern = "(tive)s$", replacement = "$1"},
            {pattern = "(hive)s$", replacement = "$1"},
            {pattern = "([^f])ves$", replacement = "$1fe"},
            {pattern = "(^analy)ses$", replacement = "$1sis"},
            {pattern = "([ti])a$", replacement = "$1um"},
            {pattern = "(n)ews$", replacement = "$1ews"},
            {pattern = "s$", replacement = ""}
        ];
    }
    
    /**
     * Pluralize a word
     */
    function pluralize(required string word) {
        var lower = lCase(arguments.word);
        
        // Check if already plural
        if (isPlural(lower)) {
            return arguments.word;
        }
        
        // Check uncountables
        if (arrayFindNoCase(variables.uncountables, lower)) {
            return arguments.word;
        }
        
        // Check irregulars
        if (structKeyExists(variables.irregulars, lower)) {
            return matchCase(variables.irregulars[lower], arguments.word);
        }
        
        // Apply rules
        for (var rule in variables.pluralRules) {
            if (reFindNoCase(rule.pattern, lower)) {
                var plural = reReplaceNoCase(lower, rule.pattern, rule.replacement);
                return matchCase(plural, arguments.word);
            }
        }
        
        return arguments.word;
    }
    
    /**
     * Singularize a word
     */
    function singularize(required string word) {
        var lower = lCase(arguments.word);
        
        // Check if already singular
        if (!isPlural(lower)) {
            return arguments.word;
        }
        
        // Check uncountables
        if (arrayFindNoCase(variables.uncountables, lower)) {
            return arguments.word;
        }
        
        // Check irregulars (reverse lookup)
        for (var singular in variables.irregulars) {
            if (variables.irregulars[singular] == lower) {
                return matchCase(singular, arguments.word);
            }
        }
        
        // Apply rules
        for (var rule in variables.singularRules) {
            if (reFindNoCase(rule.pattern, lower)) {
                var singular = reReplaceNoCase(lower, rule.pattern, rule.replacement);
                return matchCase(singular, arguments.word);
            }
        }
        
        return arguments.word;
    }
    
    /**
     * Check if word is plural
     */
    function isPlural(required string word) {
        return singularize(arguments.word) != arguments.word;
    }
    
    /**
     * Convert to camelCase
     */
    function camelCase(required string text) {
        var words = listToArray(reReplace(arguments.text, "[^a-zA-Z0-9]+", " ", "all"), " ");
        var result = "";
        
        for (var i = 1; i <= arrayLen(words); i++) {
            if (i == 1) {
                result &= lCase(words[i]);
            } else {
                result &= uCase(left(words[i], 1)) & lCase(mid(words[i], 2, len(words[i])));
            }
        }
        
        return result;
    }
    
    /**
     * Convert to PascalCase
     */
    function pascalCase(required string text) {
        var camel = camelCase(arguments.text);
        return uCase(left(camel, 1)) & mid(camel, 2, len(camel));
    }
    
    /**
     * Convert to snake_case
     */
    function snakeCase(required string text) {
        var result = reReplace(arguments.text, "([A-Z])", "_\1", "all");
        result = reReplace(result, "[^a-zA-Z0-9]+", "_", "all");
        result = reReplace(result, "_+", "_", "all");
        result = reReplace(result, "^_|_$", "", "all");
        return lCase(result);
    }
    
    /**
     * Convert to kebab-case
     */
    function kebabCase(required string text) {
        var result = reReplace(arguments.text, "([A-Z])", "-\1", "all");
        result = reReplace(result, "[^a-zA-Z0-9]+", "-", "all");
        result = reReplace(result, "-+", "-", "all");
        result = reReplace(result, "^-|-$", "", "all");
        return lCase(result);
    }
    
    /**
     * Convert to Title Case
     */
    function titleCase(required string text) {
        var words = listToArray(arguments.text, " ");
        var result = [];
        
        for (var word in words) {
            arrayAppend(result, uCase(left(word, 1)) & lCase(mid(word, 2, len(word))));
        }
        
        return arrayToList(result, " ");
    }
    
    /**
     * Convert to CONSTANT_CASE
     */
    function constantCase(required string text) {
        return uCase(snakeCase(arguments.text));
    }
    
    /**
     * Print formatted table
     */
    function printTable(
        required array data,
        array headers = [],
        array columns = [],
        boolean border = true,
        string emptyMessage = "No data to display"
    ) {
        // Handle empty data
        if (!arrayLen(arguments.data)) {
            getPrint().line(arguments.emptyMessage);
            return;
        }
        
        // Determine columns
        var cols = arguments.columns;
        if (!arrayLen(cols) && arrayLen(arguments.data)) {
            if (isStruct(arguments.data[1])) {
                cols = structKeyArray(arguments.data[1]);
            } else if (isQuery(arguments.data[1])) {
                cols = listToArray(arguments.data[1].columnList);
            }
        }
        
        // Determine headers
        var heads = arguments.headers;
        if (!arrayLen(heads)) {
            heads = cols;
        }
        
        // Calculate column widths
        var widths = calculateColumnWidths(arguments.data, cols, heads);
        
        // Print table
        if (arguments.border) {
            printTableBorder(widths);
        }
        
        // Print headers
        printTableRow(heads, widths, true);
        
        if (arguments.border) {
            printTableBorder(widths);
        }
        
        // Print data rows
        for (var row in arguments.data) {
            var values = [];
            for (var col in cols) {
                if (isStruct(row) && structKeyExists(row, col)) {
                    arrayAppend(values, toString(row[col]));
                } else {
                    arrayAppend(values, "");
                }
            }
            printTableRow(values, widths);
        }
        
        if (arguments.border) {
            printTableBorder(widths);
        }
    }
    
    /**
     * Calculate column widths
     */
    private function calculateColumnWidths(required array data, required array columns, required array headers) {
        var widths = [];
        
        // Initialize with header widths
        for (var i = 1; i <= arrayLen(arguments.headers); i++) {
            widths[i] = len(arguments.headers[i]);
        }
        
        // Check data widths
        for (var row in arguments.data) {
            for (var i = 1; i <= arrayLen(arguments.columns); i++) {
                var col = arguments.columns[i];
                var value = "";
                
                if (isStruct(row) && structKeyExists(row, col)) {
                    value = toString(row[col]);
                }
                
                if (len(value) > widths[i]) {
                    widths[i] = len(value);
                }
            }
        }
        
        // Add padding
        for (var i = 1; i <= arrayLen(widths); i++) {
            widths[i] = widths[i] + 2;
        }
        
        return widths;
    }
    
    /**
     * Print table border
     */
    private function printTableBorder(required array widths) {
        var border = "+";
        for (var width in arguments.widths) {
            border &= repeatString("-", width) & "+";
        }
        getPrint().line(border);
    }
    
    /**
     * Print table row
     */
    private function printTableRow(required array values, required array widths, boolean isHeader = false) {
        var row = "|";
        
        for (var i = 1; i <= arrayLen(arguments.values); i++) {
            var value = " " & arguments.values[i] & " ";
            var width = arguments.widths[i];
            var padding = width - len(value);
            
            if (padding > 0) {
                value &= repeatString(" ", padding);
            } else if (padding < 0) {
                value = left(value, width - 3) & "...";
            }
            
            row &= value & "|";
        }
        
        if (arguments.isHeader) {
            getPrint().boldLine(row);
        } else {
            getPrint().line(row);
        }
    }
    
    /**
     * Format file size
     */
    function formatFileSize(required numeric bytes) {
        var units = ["B", "KB", "MB", "GB", "TB"];
        var size = arguments.bytes;
        var unit = 1;
        
        while (size >= 1024 && unit < arrayLen(units)) {
            size = size / 1024;
            unit++;
        }
        
        if (unit == 1) {
            return numberFormat(size, "0") & " " & units[unit];
        } else {
            return numberFormat(size, "0.00") & " " & units[unit];
        }
    }
    
    /**
     * Format duration
     */
    function formatDuration(required numeric milliseconds) {
        var ms = arguments.milliseconds;
        
        if (ms < 1000) {
            return ms & "ms";
        }
        
        var seconds = int(ms / 1000);
        var minutes = int(seconds / 60);
        var hours = int(minutes / 60);
        
        if (hours > 0) {
            return hours & "h " & (minutes % 60) & "m " & (seconds % 60) & "s";
        } else if (minutes > 0) {
            return minutes & "m " & (seconds % 60) & "s";
        } else {
            return seconds & "s";
        }
    }
    
    /**
     * Truncate string with ellipsis
     */
    function truncate(required string text, numeric length = 50, string suffix = "...") {
        if (len(arguments.text) <= arguments.length) {
            return arguments.text;
        }
        
        return left(arguments.text, arguments.length - len(arguments.suffix)) & arguments.suffix;
    }
    
    /**
     * Match case of source to target
     */
    private function matchCase(required string source, required string target) {
        if (uCase(arguments.target) == arguments.target) {
            return uCase(arguments.source);
        } else if (lCase(arguments.target) == arguments.target) {
            return lCase(arguments.source);
        } else if (len(arguments.target) && uCase(left(arguments.target, 1)) == left(arguments.target, 1)) {
            return uCase(left(arguments.source, 1)) & mid(arguments.source, 2, len(arguments.source));
        }
        
        return arguments.source;
    }
    
    /**
     * Convert value to string
     */
    private function toString(required any value) {
        if (isSimpleValue(arguments.value)) {
            return arguments.value;
        } else if (isArray(arguments.value)) {
            return arrayToList(arguments.value, ", ");
        } else if (isStruct(arguments.value)) {
            return "{struct}";
        } else if (isQuery(arguments.value)) {
            return "{query:#arguments.value.recordCount#}";
        }
        
        return "";
    }
    
    /**
     * Get print helper
     */
    private function getPrint() {
        return variables.print;
    }
}