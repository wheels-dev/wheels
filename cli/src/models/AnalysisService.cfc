component {
    
    property name="config" type="struct";
    
    /**
     * Initialize the service
     */
    function init() {
        variables.config = loadConfig();
        return this;
    }
    
    /**
     * Analyze code quality and patterns
     */
    function analyze(
        required string path,
        string severity = "warning",
        any printer = "",
        boolean verbose = false
    ) {
        var startTime = getTickCount();
        
        var results = {
            hasErrors = false,
            hasWarnings = false,
            totalIssues = 0,
            files = {},
            metrics = {
                totalFiles = 0,
                totalLines = 0,
                totalFunctions = 0,
                averageComplexity = 0,
                duplicateBlocks = 0,
                codeSmells = 0,
                deprecatedCalls = 0
            },
            duplicates = [],
            complexFunctions = [],
            summary = {
                errors = 0,
                warnings = 0,
                info = 0
            },
            executionTime = 0,
            config = variables.config // Include config in results
        };
        
        var fullPath = arguments.path;
        
        // Collect all files first
        var allFiles = [];
        if (directoryExists(fullPath)) {
            allFiles = collectFiles(fullPath, arguments.printer, arguments.verbose);
        } else if (fileExists(fullPath)) {
            allFiles = [fullPath];
            if (arguments.verbose && isObject(arguments.printer)) {
                arguments.printer.line("Analyzing single file: #fullPath#");
            }
        } else {
            throw("Path not found: #arguments.path#");
        }
        
        // Analyze files
        analyzeFiles(allFiles, results, arguments.severity, arguments.printer, arguments.verbose);

        // Detect duplicates across all files
        if (variables.config.features.duplicateDetection) {
            if (arguments.verbose && isObject(arguments.printer)) {
                arguments.printer.line("Starting duplicate code detection...");
            }
            detectDuplicates(allFiles, results, arguments.printer);
        }
        
        // Calculate final metrics
        finalizeMetrics(results);
        
        // Update summary flags
        results.hasErrors = results.summary.errors > 0;
        results.hasWarnings = results.summary.warnings > 0;
        results.totalIssues = results.summary.errors + results.summary.warnings + results.summary.info;
        results.executionTime = (getTickCount() - startTime) / 1000; // in seconds
        
        return results;
    }
    
    /**
     * Load configuration from .wheelscheck file or defaults
     */
    private function loadConfig() {
        var configPath = ".wheelscheck";
        var config = getDefaultConfig();
        
        if (fileExists(configPath)) {
            try {
                var customConfig = deserializeJSON(fileRead(configPath));
                config = mergeConfigs(config, customConfig);
            } catch (any e) {
                // Invalid config file, use defaults
            }
        }
        
        return config;
    }
    
    /**
     * Get default configuration
     */
    private function getDefaultConfig() {
        return {
            "rules": {
                "max-line-length": 120,
                "indent-style": "spaces",
                "indent-size": 4,
                "max-function-length": 50,
                "max-function-complexity": 10,
                "max-file-length": 500,
                "naming-convention": "camelCase",
                "require-var-scoping": true,
                "no-trailing-spaces": true,
                "no-tabs": true,
                "no-hardcoded-credentials": true,
                "no-sql-injection": true,
                "no-evaluate": true,
                "no-deprecated": true,
                "require-output-attribute": true,
                "duplicate-threshold": 30 // minimum lines for duplicate detection
            },
            "features": {
                "duplicateDetection": true,
                "complexityAnalysis": true,
                "wheelsConventions": true,
                "codeSmells": true,
                "metrics": true
            },
            "exclude": [
                "vendor/",
                "node_modules/",
                ".git/",
                "testbox/",
                "tests/",
                "build/",
                "dist/",
                ".svn/",
                "bower_components/",
                "packages/",
                "coldbox/",
                "modules/",
                "WEB-INF/"
            ],
            "wheels": {
                "check-deprecated": true,
                "enforce-conventions": true,
                "version": "2.x"
            }
        };
    }
    
    /**
     * Merge custom config with defaults
     */
    private function mergeConfigs(defaultConfig, customConfig) {
        var merged = duplicate(arguments.defaultConfig);
        
        for (var key in arguments.customConfig) {
            if (isStruct(arguments.customConfig[key]) && structKeyExists(merged, key)) {
                for (var subKey in arguments.customConfig[key]) {
                    merged[key][subKey] = arguments.customConfig[key][subKey];
                }
            } else {
                merged[key] = arguments.customConfig[key];
            }
        }
        
        return merged;
    }
    
    /**
     * Collect all files to analyze
     */
    private function collectFiles(required string path, any printer = "", boolean verbose = false) {
        var files = [];
        
        if (isObject(arguments.printer)) {
            arguments.printer.text("Scanning for files... ").toConsole();
        }
        
        var allFiles = directoryList(
            arguments.path, 
            true, 
            "path", 
            "*.cfc|*.cfm", 
            "name asc"
        );
        
        for (var file in allFiles) {
            if (!isExcluded(file)) {
                arrayAppend(files, file);
                if (arguments.verbose && isObject(arguments.printer)) {
                    arguments.printer.line("  + #file#").toConsole();
                }
            } else {
                if (arguments.verbose && isObject(arguments.printer)) {
                    arguments.printer.line("  - #file# (excluded)").toConsole();
                }
            }
        }

        if (isObject(arguments.printer)) {
            arguments.printer.greenLine("Found #arrayLen(files)# files to analyze").toConsole();
            if (arguments.verbose && arrayLen(allFiles) > arrayLen(files)) {
                arguments.printer.line("Excluded #arrayLen(allFiles) - arrayLen(files)# files based on config").toConsole();
            }
        }
        
        return files;
    }
    
    /**
     * Analyze multiple files
     */
    private function analyzeFiles(
        required array files,
        required struct results,
        required string severity,
        any printer = "",
        boolean verbose = false
    ) {
        var totalFiles = arrayLen(arguments.files);
        var currentFile = 0;
        
        for (var file in arguments.files) {
            currentFile++;

            // Progress indicator
            if (isObject(arguments.printer)) {
                if (arguments.verbose) {
                    arguments.printer.line("Analyzing file #currentFile#/#totalFiles#: #file#").toConsole();
                } else {
                    var percentage = int((currentFile / totalFiles) * 100);
                    arguments.printer.text(chr(13) & "Analyzing: [")
                        .text(repeatString("=", int(percentage/2)))
                        .text(repeatString(" ", 50 - int(percentage/2)))
                        .text("] #percentage#% (#currentFile#/#totalFiles#)")
                        .toConsole();
                }
            }

            analyzeFile(file, arguments.results, arguments.severity, arguments.verbose, arguments.printer);
        }
        
        if (isObject(arguments.printer)) {
            arguments.printer.line(chr(13) & "Analyzing: [" & repeatString("=", 50) & "] 100% Complete!").toConsole();
        }
    }
    
    /**
     * Analyze a single file comprehensively
     */
    private function analyzeFile(
        required string path,
        required struct results,
        required string severity,
        boolean verbose = false,
        any printer = ""
    ) {
        var issues = [];
        var content = fileRead(arguments.path);
        var lines = listToArray(content, chr(10));
        
        // Update metrics
        arguments.results.metrics.totalFiles++;
        arguments.results.metrics.totalLines += arrayLen(lines);

        if (arguments.verbose && isObject(arguments.printer)) {
            arguments.printer.line("  File has #arrayLen(lines)# lines").toConsole();
            arguments.printer.line("  Running code style checks...").toConsole();
        }

        // Run all checks - Pass results to functions that need it
        issues.addAll(checkCodeStyle(arguments.path, lines));

        if (arguments.verbose && isObject(arguments.printer)) {
            arguments.printer.line("  Running security checks...").toConsole();
        }
        issues.addAll(checkSecurity(arguments.path, lines));

        if (arguments.verbose && isObject(arguments.printer)) {
            arguments.printer.line("  Running performance checks...").toConsole();
        }
        issues.addAll(checkPerformance(arguments.path, lines));

        if (arguments.verbose && isObject(arguments.printer)) {
            arguments.printer.line("  Running best practice checks...").toConsole();
        }
        issues.addAll(checkBestPractices(arguments.path, lines));
        
        // These functions need results for metrics
        if (arguments.verbose && isObject(arguments.printer)) {
            arguments.printer.line("  Running complexity analysis...").toConsole();
        }
        var complexityIssues = checkComplexity(arguments.path, content, arguments.results);
        issues.addAll(complexityIssues);

        if (arguments.verbose && isObject(arguments.printer)) {
            arguments.printer.line("  Checking naming conventions...").toConsole();
        }
        issues.addAll(checkNamingConventions(arguments.path, content));

        if (arguments.verbose && isObject(arguments.printer)) {
            arguments.printer.line("  Detecting code smells...").toConsole();
        }
        var smellIssues = checkCodeSmells(arguments.path, content, arguments.results);
        issues.addAll(smellIssues);

        if (variables.config.wheels["check-deprecated"]) {
            if (arguments.verbose && isObject(arguments.printer)) {
                arguments.printer.line("  Checking for deprecated functions...").toConsole();
            }
            var deprecatedIssues = checkDeprecatedFunctions(arguments.path, content, arguments.results);
            issues.addAll(deprecatedIssues);
        }

        if (variables.config.wheels["enforce-conventions"]) {
            if (arguments.verbose && isObject(arguments.printer)) {
                arguments.printer.line("  Checking Wheels conventions...").toConsole();
            }
            issues.addAll(checkWheelsConventions(arguments.path, content));
        }
        
        // Filter by severity
        var filteredIssues = filterBySeverity(issues, arguments.severity);

        if (arguments.verbose && isObject(arguments.printer)) {
            arguments.printer.line("  Found #arrayLen(issues)# issues total, #arrayLen(filteredIssues)# after severity filter").toConsole();
        }

        if (arrayLen(filteredIssues)) {
            arguments.results.files[arguments.path] = filteredIssues;

            // Update summary
            for (var issue in filteredIssues) {
                if (structKeyExists(arguments.results.summary, issue.severity)) {
                    arguments.results.summary[issue.severity]++;
                }
            }
        }
    }
    
    /**
     * Check code complexity using cyclomatic complexity
     */
    private function checkComplexity(required string path, required string content, required struct results) {
        var issues = [];
        var functionPattern = "(?:public|private|remote|package|)\s*(?:any|string|numeric|boolean|struct|array|query|void|)\s*function\s+(\w+)\s*\([^)]*\)\s*\{";
        var matches = reFindAll(functionPattern, arguments.content, true);
        
        for (var match in matches) {
            var functionName = match.groups[1];
            var functionBody = extractFunctionBody(arguments.content, match.pos);
            var complexity = calculateCyclomaticComplexity(functionBody);
            
            // Update metrics
            arguments.results.metrics.totalFunctions++;
            
            if (complexity > variables.config.rules["max-function-complexity"]) {
                arrayAppend(issues, {
                    line = getLineNumber(arguments.content, match.pos),
                    column = 1,
                    severity = "warning",
                    message = "Function '#functionName#' has high cyclomatic complexity (#complexity#)",
                    rule = "max-complexity",
                    fixable = false,
                    complexity = complexity,
                    functionName = functionName
                });
                
                // Track complex functions
                arrayAppend(arguments.results.complexFunctions, {
                    file = arguments.path,
                    function = functionName,
                    complexity = complexity
                });
            }
            
            // Check function length
            var lineCount = arrayLen(listToArray(functionBody, chr(10)));
            if (lineCount > variables.config.rules["max-function-length"]) {
                arrayAppend(issues, {
                    line = getLineNumber(arguments.content, match.pos),
                    column = 1,
                    severity = "warning",
                    message = "Function '#functionName#' exceeds maximum length (#lineCount# lines)",
                    rule = "max-function-length",
                    fixable = false
                });
            }
        }
        
        return issues;
    }
    
    /**
     * Calculate cyclomatic complexity of code
     */
    private function calculateCyclomaticComplexity(required string code) {
        var complexity = 1; // Base complexity
        
        // Decision points that increase complexity
        var patterns = [
            "\bif\s*\(",
            "\belseif\s*\(",
            "\belse\b",
            "\bcase\s+",
            "\bfor\s*\(",
            "\bwhile\s*\(",
            "\bdo\s*\{",
            "\bcatch\s*\(",
            "\?\s*[^:]+\s*:", // ternary operator
            "\&\&", // AND
            "\|\|"  // OR
        ];
        
        for (var pattern in patterns) {
            var matches = reFindAll(pattern, arguments.code, false);
            complexity += arrayLen(matches);
        }
        
        return complexity;
    }
    
    /**
     * Extract function body from content
     */
    private function extractFunctionBody(required string content, required numeric startPos) {
        var braceCount = 0;
        var inFunction = false;
        var functionBody = "";
        var i = arguments.startPos;
        
        // Find the opening brace
        while (i <= len(arguments.content)) {
            var char = mid(arguments.content, i, 1);
            if (char == "{") {
                inFunction = true;
                braceCount = 1;
                i++;
                break;
            }
            i++;
        }
        
        // Extract until closing brace
        while (i <= len(arguments.content) && braceCount > 0) {
            var char = mid(arguments.content, i, 1);
            functionBody &= char;
            
            if (char == "{") {
                braceCount++;
            } else if (char == "}") {
                braceCount--;
            }
            i++;
        }
        
        return functionBody;
    }
    
    /**
     * Check naming conventions
     */
    private function checkNamingConventions(required string path, required string content) {
        var issues = [];
        var convention = variables.config.rules["naming-convention"];
        
        // Check variable names
        var varPattern = "(?:var\s+|local\.)(\w+)\s*=";
        var matches = reFindAll(varPattern, arguments.content, true);
        
        for (var match in matches) {
            var varName = match.groups[1];
            
            if (convention == "camelCase" && !reFindNoCase("^[a-z][a-zA-Z0-9]*$", varName)) {
                arrayAppend(issues, {
                    line = getLineNumber(arguments.content, match.pos),
                    column = match.pos,
                    severity = "info",
                    message = "Variable '#varName#' does not follow camelCase convention",
                    rule = "naming-convention",
                    fixable = false
                });
            }
        }
        
        // Check function names
        var funcPattern = "function\s+(\w+)\s*\(";
        matches = reFindAll(funcPattern, arguments.content, true);
        
        for (var match in matches) {
            var funcName = match.groups[1];
            
            if (convention == "camelCase" && !reFindNoCase("^[a-z][a-zA-Z0-9]*$", funcName)) {
                arrayAppend(issues, {
                    line = getLineNumber(arguments.content, match.pos),
                    column = match.pos,
                    severity = "info",
                    message = "Function '#funcName#' does not follow camelCase convention",
                    rule = "naming-convention",
                    fixable = false
                });
            }
        }
        
        return issues;
    }
    
    /**
     * Check for code smells
     */
    private function checkCodeSmells(required string path, required string content, required struct results) {
        var issues = [];
        
        // Long parameter lists
        var funcPattern = "function\s+\w+\s*\(([^)]+)\)";
        var matches = reFindAll(funcPattern, arguments.content, true);
        
        for (var match in matches) {
            var params = match.groups[1];
            var paramCount = listLen(params, ",");
            
            if (paramCount > 5) {
                arrayAppend(issues, {
                    line = getLineNumber(arguments.content, match.pos),
                    column = 1,
                    severity = "warning",
                    message = "Function has too many parameters (#paramCount#). Consider using a struct",
                    rule = "long-parameter-list",
                    fixable = false
                });
                arguments.results.metrics.codeSmells++;
            }
        }
        
        // Nested loops (code smell)
        if (reFindNoCase("(for|while|loop).*\n.*?(for|while|loop)", arguments.content)) {
            arrayAppend(issues, {
                line = 1,
                column = 1,
                severity = "info",
                message = "Nested loops detected. Consider refactoring for better performance",
                rule = "nested-loops",
                fixable = false
            });
            arguments.results.metrics.codeSmells++;
        }
        
        // Large files
        var lineCount = arrayLen(listToArray(arguments.content, chr(10)));
        if (lineCount > variables.config.rules["max-file-length"]) {
            arrayAppend(issues, {
                line = 1,
                column = 1,
                severity = "warning",
                message = "File exceeds maximum length (#lineCount# lines). Consider splitting into smaller files",
                rule = "max-file-length",
                fixable = false
            });
            arguments.results.metrics.codeSmells++;
        }
        
        // TODO comments (technical debt)
        var todoPattern = "(\/\/|<" & "!---|<" & "!--)\s*(TODO|FIXME|HACK|XXX|BUG):?";
        var todoMatches = reFindAll(todoPattern, arguments.content, true);
        
        for (var match in todoMatches) {
            arrayAppend(issues, {
                line = getLineNumber(arguments.content, match.pos),
                column = 1,
                severity = "info",
                message = "Found TODO/FIXME comment indicating technical debt",
                rule = "todo-comment",
                fixable = false
            });
            arguments.results.metrics.codeSmells++;
        }
        
        return issues;
    }
    
    /**
     * Check for deprecated Wheels functions
     */
    private function checkDeprecatedFunctions(required string path, required string content, required struct results) {
        var issues = [];
        
        // List of deprecated functions (example - adjust based on Wheels version)
        var deprecatedFunctions = {
            "findAll": "Use findAll() with new syntax",
            "findByKey": "Use findOne() instead",
            "updateByKey": "Use updateOne() instead",
            "deleteByKey": "Use deleteOne() instead",
            "renderNothing": "Use renderText('') instead",
            "sendEmail": "Use sendMail() instead",
            "includePartial": "Use renderPartial() instead",
            "contentForLayout": "Use includeContent() instead"
        };
        
        for (var funcName in deprecatedFunctions) {
            var pattern = "\b#funcName#\s*\(";
            var matches = reFindAll(pattern, arguments.content, false);
            
            for (var match in matches) {
                arrayAppend(issues, {
                    line = getLineNumber(arguments.content, match.pos),
                    column = match.pos,
                    severity = "warning",
                    message = "Deprecated function '#funcName#' used. #deprecatedFunctions[funcName]#",
                    rule = "no-deprecated",
                    fixable = false
                });
                arguments.results.metrics.deprecatedCalls++;
            }
        }
        
        return issues;
    }
    
    /**
     * Check Wheels-specific conventions
     */
    private function checkWheelsConventions(required string path, required string content) {
        var issues = [];
        var fileName = listLast(arguments.path, "/\");
        var isController = findNoCase("/controllers/", arguments.path) || findNoCase("Controller.cfc", fileName);
        var isModel = findNoCase("/models/", arguments.path) && !isController;
        
        // Controller conventions
        if (isController) {
            // Check controller naming
            if (!reFindNoCase("Controller\.cfc$", fileName)) {
                arrayAppend(issues, {
                    line = 1,
                    column = 1,
                    severity = "warning",
                    message = "Controller file should end with 'Controller.cfc'",
                    rule = "wheels-controller-naming",
                    fixable = false
                });
            }
            
            // Check for init method
            if (!findNoCase("function init", arguments.content)) {
                arrayAppend(issues, {
                    line = 1,
                    column = 1,
                    severity = "info",
                    message = "Controller missing init() method",
                    rule = "wheels-controller-init",
                    fixable = false
                });
            }
            
            // Check for filters
            if (findNoCase("before(", arguments.content) || findNoCase("after(", arguments.content)) {
                // Good - using filters
            } else {
                arrayAppend(issues, {
                    line = 1,
                    column = 1,
                    severity = "info",
                    message = "Consider using before/after filters for common functionality",
                    rule = "wheels-use-filters",
                    fixable = false
                });
            }
        }
        
        // Model conventions
        if (isModel) {
            // Check for table name property
            if (!findNoCase('table(', arguments.content) && !findNoCase('tableName', arguments.content)) {
                arrayAppend(issues, {
                    line = 1,
                    column = 1,
                    severity = "info",
                    message = "Model should specify table name explicitly",
                    rule = "wheels-model-table",
                    fixable = false
                });
            }
            
            // Check for validations
            if (!reFindNoCase("validates(Presence|Length|Uniqueness|Format|Inclusion|Exclusion)", arguments.content)) {
                arrayAppend(issues, {
                    line = 1,
                    column = 1,
                    severity = "info",
                    message = "Model has no validations defined",
                    rule = "wheels-model-validations",
                    fixable = false
                });
            }
        }
        
        // Check for proper use of params
        if (findNoCase("params.", arguments.content)) {
            // Check for param validation
            if (!findNoCase("param name=", arguments.content)) {
                arrayAppend(issues, {
                    line = 1,
                    column = 1,
                    severity = "info",
                    message = "Consider validating params with param tags",
                    rule = "wheels-param-validation",
                    fixable = false
                });
            }
        }
        
        return issues;
    }
    
    /**
     * Detect duplicate code blocks
     */
    private function detectDuplicates(
        required array files,
        required struct results,
        any printer = ""
    ) {
        if (isObject(arguments.printer)) {
            arguments.printer.text("Detecting duplicate code... ").toConsole();
        }
        
        var codeBlocks = {};
        var minLines = variables.config.rules["duplicate-threshold"];
        
        // Extract code blocks from all files
        for (var file in arguments.files) {
            var content = fileRead(file);
            var lines = listToArray(content, chr(10));
            
            // Create blocks of N lines
            for (var i = 1; i <= arrayLen(lines) - minLines; i++) {
                var block = "";
                for (var j = i; j < i + minLines && j <= arrayLen(lines); j++) {
                    // Normalize whitespace for comparison
                    block &= trim(lines[j]) & chr(10);
                }
                
                var blockHash = hash(block);
                
                if (!structKeyExists(codeBlocks, blockHash)) {
                    codeBlocks[blockHash] = [];
                }
                
                arrayAppend(codeBlocks[blockHash], {
                    file = file,
                    startLine = i,
                    endLine = i + minLines - 1,
                    content = block
                });
            }
        }
        
        // Find duplicates
        for (var blockHash in codeBlocks) {
            if (arrayLen(codeBlocks[blockHash]) > 1) {
                arguments.results.metrics.duplicateBlocks++;
                
                // Add to duplicates list
                arrayAppend(arguments.results.duplicates, {
                    hash = blockHash,
                    occurrences = codeBlocks[blockHash],
                    lineCount = minLines
                });
                
                // Add issues for each occurrence
                for (var occurrence in codeBlocks[blockHash]) {
                    if (!structKeyExists(arguments.results.files, occurrence.file)) {
                        arguments.results.files[occurrence.file] = [];
                    }
                    
                    arrayAppend(arguments.results.files[occurrence.file], {
                        line = occurrence.startLine,
                        column = 1,
                        severity = "warning",
                        message = "Duplicate code block detected (lines #occurrence.startLine#-#occurrence.endLine#)",
                        rule = "no-duplicate-code",
                        fixable = false
                    });
                    
                    arguments.results.summary.warnings++;
                }
            }
        }
        
        if (isObject(arguments.printer)) {
            arguments.printer.greenLine("Found #arguments.results.metrics.duplicateBlocks# duplicate blocks").toConsole();
        }
    }
    
    /**
     * Finalize metrics calculations
     */
    private function finalizeMetrics(required struct results) {
        // Calculate average complexity
        var totalComplexity = 0;
        for (var func in arguments.results.complexFunctions) {
            totalComplexity += func.complexity;
        }
        
        if (arrayLen(arguments.results.complexFunctions) > 0) {
            arguments.results.metrics.averageComplexity = round(totalComplexity / arrayLen(arguments.results.complexFunctions));
        }
        
        // Add code health score (0-100)
        var score = 100;
        score -= arguments.results.summary.errors * 10;
        score -= arguments.results.summary.warnings * 5;
        score -= arguments.results.summary.info * 1;
        score -= arguments.results.metrics.duplicateBlocks * 2;
        score -= arguments.results.metrics.codeSmells * 3;
        score -= arguments.results.metrics.deprecatedCalls * 5;
        
        arguments.results.metrics.healthScore = max(0, score);
        
        // Add grade
        if (score >= 90) {
            arguments.results.metrics.grade = "A";
        } else if (score >= 80) {
            arguments.results.metrics.grade = "B";
        } else if (score >= 70) {
            arguments.results.metrics.grade = "C";
        } else if (score >= 60) {
            arguments.results.metrics.grade = "D";
        } else {
            arguments.results.metrics.grade = "F";
        }
    }
    
    /**
     * Check code style issues
     */
    private function checkCodeStyle(required string path, required array lines) {
        var issues = [];
        var lineNum = 0;
        
        for (var line in arguments.lines) {
            lineNum++;
            
            // Check line length
            if (len(line) > variables.config.rules["max-line-length"]) {
                arrayAppend(issues, {
                    line = lineNum,
                    column = variables.config.rules["max-line-length"] + 1,
                    severity = "warning",
                    message = "Line exceeds #variables.config.rules['max-line-length']# characters",
                    rule = "max-line-length",
                    fixable = false
                });
            }
            
            // Check for tabs vs spaces
            if (variables.config.rules["no-tabs"] && find(chr(9), line)) {
                arrayAppend(issues, {
                    line = lineNum,
                    column = 1,
                    severity = "info",
                    message = "Tab character found, use spaces for indentation",
                    rule = "no-tabs",
                    fixable = true,
                    fix = {
                        type = "replace",
                        find = chr(9),
                        replace = repeatString(" ", variables.config.rules["indent-size"])
                    }
                });
            }
            
            // Check for trailing whitespace
            if (variables.config.rules["no-trailing-spaces"] && reFind("\s+$", line)) {
                arrayAppend(issues, {
                    line = lineNum,
                    column = len(line),
                    severity = "warning",
                    message = "Trailing whitespace",
                    rule = "no-trailing-spaces",
                    fixable = true,
                    fix = {
                        type = "trim"
                    }
                });
            }
        }
        
        return issues;
    }
    
    /**
     * Check security issues
     */
    private function checkSecurity(required string path, required array lines) {
        var issues = [];
        var content = arrayToList(arguments.lines, chr(10));
        
        // Check for SQL injection vulnerabilities
        if (variables.config.rules["no-sql-injection"]) {
            var sqlPatterns = [
                "preserveSingleQuotes\s*\(",
                "evaluate\s*\([^)]*sql",
                "cfquery[^>]+preservesinglequotes",
                "##.*?##.*?(SELECT|INSERT|UPDATE|DELETE|DROP)"
            ];
            
            for (var pattern in sqlPatterns) {
                var matches = reFindAll(pattern, content, false);
                for (var match in matches) {
                    arrayAppend(issues, {
                        line = getLineNumber(content, match.pos),
                        column = match.pos,
                        severity = "error",
                        message = "Potential SQL injection vulnerability",
                        rule = "no-sql-injection",
                        fixable = false
                    });
                }
            }
        }
        
        // Check for evaluate() usage
        if (variables.config.rules["no-evaluate"]) {
            var evalPattern = "\bevaluate\s*\(";
            var matches = reFindAll(evalPattern, content, false);
            for (var match in matches) {
                arrayAppend(issues, {
                    line = getLineNumber(content, match.pos),
                    column = match.pos,
                    severity = "error",
                    message = "Avoid using evaluate() - it's a security risk",
                    rule = "no-evaluate",
                    fixable = false
                });
            }
        }
        
        // Check for hardcoded credentials
        if (variables.config.rules["no-hardcoded-credentials"]) {
            var credentialPatterns = [
                "password\s*=\s*[""'][^""']+[""']",
                "api_?key\s*=\s*[""'][^""']+[""']",
                "secret\s*=\s*[""'][^""']+[""']",
                "token\s*=\s*[""'][^""']+[""']"
            ];
            
            for (var pattern in credentialPatterns) {
                var matches = reFindAll(pattern, content, false);
                for (var match in matches) {
                    // Skip if it's a variable reference
                    var matchText = mid(content, match.pos, match.len);
                    if (!find("##", matchText) && !findNoCase("variables.", matchText)) {
                        arrayAppend(issues, {
                            line = getLineNumber(content, match.pos),
                            column = match.pos,
                            severity = "error",
                            message = "Hardcoded credentials detected",
                            rule = "no-hardcoded-credentials",
                            fixable = false
                        });
                    }
                }
            }
        }
        
        return issues;
    }
    
    /**
     * Check performance issues
     */
    private function checkPerformance(required string path, required array lines) {
        var issues = [];
        var content = arrayToList(arguments.lines, chr(10));
        
        // Check for N+1 query patterns
        if (reFindNoCase("cfloop.*cfquery|for\s*\(.*\).*\{[^}]*\.(find|save|update|delete)\(", content)) {
            arrayAppend(issues, {
                line = 1,
                column = 1,
                severity = "warning",
                message = "Potential N+1 query problem detected",
                rule = "no-n-plus-one",
                fixable = false
            });
        }
        
        // Check for missing query caching
        if (findNoCase("cfquery", content) && !findNoCase("cachedwithin", content)) {
            arrayAppend(issues, {
                line = 1,
                column = 1,
                severity = "info",
                message = "Consider using query caching for better performance",
                rule = "use-query-cache",
                fixable = false
            });
        }
        
        // Check for select * queries
        var selectStarPattern = "SELECT\s+\*\s+FROM";
        if (reFindNoCase(selectStarPattern, content)) {
            var matches = reFindAll(selectStarPattern, content, false);
            for (var match in matches) {
                arrayAppend(issues, {
                    line = getLineNumber(content, match.pos),
                    column = match.pos,
                    severity = "info",
                    message = "Avoid SELECT *, specify needed columns explicitly",
                    rule = "no-select-star",
                    fixable = false
                });
            }
        }
        
        return issues;
    }
    
    /**
     * Check best practices
     */
    private function checkBestPractices(required string path, required array lines) {
        var issues = [];
        var content = arrayToList(arguments.lines, chr(10));
        
        // Check for var scoping in functions
        if (variables.config.rules["require-var-scoping"]) {
            var functionMatches = reFindAll("function\s+\w+[^{]*\{", content, true);
            
            for (var funcMatch in functionMatches) {
                var startPos = funcMatch.pos + funcMatch.len;
                var functionContent = extractFunctionBody(content, funcMatch.pos);
                
                // Look for unscoped variables
                var unscopedPattern = "^\s*([a-z_][a-z0-9_]*)\s*=(?!=)";
                var varMatches = reFindAll(unscopedPattern, functionContent, true);
                
                for (var varMatch in varMatches) {
                    var varName = varMatch.groups[1];
                    // Check if it's not already scoped
                    if (!reFindNoCase("(var|local\.|arguments\.|variables\.|this\.)\s*#varName#", functionContent)) {
                        arrayAppend(issues, {
                            line = getLineNumber(content, funcMatch.pos),
                            column = 1,
                            severity = "warning",
                            message = "Variable '#varName#' may not be properly scoped",
                            rule = "var-scoping",
                            fixable = true,
                            fix = {
                                type = "addVar",
                                variable = varName
                            }
                        });
                    }
                }
            }
        }
        
        // Check for missing output attribute on components
        if (variables.config.rules["require-output-attribute"]) {
            if (reFindNoCase("^component(?!.*output\s*=)", content)) {
                arrayAppend(issues, {
                    line = 1,
                    column = 1,
                    severity = "info",
                    message = "Component missing explicit output attribute",
                    rule = "explicit-output",
                    fixable = true,
                    fix = {
                        type = "replace",
                        find = "component",
                        replace = "component output=""false"""
                    }
                });
            }
        }
        
        return issues;
    }
    
    /**
     * Automatically fix certain types of issues
     */
    function autoFix(required struct results, any printer = "") {
        var fixed = {
            count = 0,
            files = []
        };
        
        var totalFiles = structCount(arguments.results.files);
        var currentFile = 0;
        
        for (var filePath in arguments.results.files) {
            currentFile++;
            var fileIssues = arguments.results.files[filePath];
            var fileFixed = false;
            
            if (isObject(arguments.printer)) {
                arguments.printer.text("Fixing issues in file #currentFile#/#totalFiles#... ").toConsole();
            }
            
            var content = fileRead(filePath);
            var originalContent = content;
            
            for (var issue in fileIssues) {
                if (issue.fixable && structKeyExists(issue, "fix")) {
                    content = applyFix(content, issue);
                    fixed.count++;
                    fileFixed = true;
                }
            }
            
            if (fileFixed && content != originalContent) {
                fileWrite(filePath, content);
                arrayAppend(fixed.files, filePath);
                if (isObject(arguments.printer)) {
                    arguments.printer.greenLine("✓ Fixed").toConsole();
                }
            } else if (isObject(arguments.printer)) {
                arguments.printer.line("no fixes applied").toConsole();
            }
        }
        
        return fixed;
    }
    
    /**
     * Apply a fix to content
     */
    private function applyFix(required string content, required struct issue) {
        var fixedContent = arguments.content;
        
        switch (arguments.issue.fix.type) {
            case "replace":
                fixedContent = replace(
                    fixedContent, 
                    arguments.issue.fix.find, 
                    arguments.issue.fix.replace, 
                    "all"
                );
                break;
                
            case "trim":
                var lines = listToArray(fixedContent, chr(10));
                if (arguments.issue.line > 0 && arguments.issue.line <= arrayLen(lines)) {
                    lines[arguments.issue.line] = rtrim(lines[arguments.issue.line]);
                    fixedContent = arrayToList(lines, chr(10));
                }
                break;
                
            case "addVar":
                // Add var declaration at the beginning of the function
                var pattern = "(function\s+\w+[^{]*\{)";
                fixedContent = reReplace(
                    fixedContent,
                    pattern,
                    "\1#chr(10)#    var #arguments.issue.fix.variable#;",
                    "all"
                );
                break;
        }
        
        return fixedContent;
    }
    
    /**
     * Helper functions
     */
    
    private function reFindAll(required string pattern, required string text, boolean includeGroups = false) {
        var matches = [];
        var start = 1;
        
        while (start <= len(arguments.text)) {
            var result = reFind(arguments.pattern, arguments.text, start, true);
            
            if (arrayLen(result.pos) && result.pos[1] > 0) {
                var matchData = {
                    pos = result.pos[1],
                    len = result.len[1],
                    match = mid(arguments.text, result.pos[1], result.len[1])
                };
                
                if (arguments.includeGroups && arrayLen(result.pos) > 1) {
                    matchData.groups = [];
                    for (var i = 2; i <= arrayLen(result.pos); i++) {
                        if (i <= arrayLen(result.pos) && result.pos[i] > 0) {
                            arrayAppend(matchData.groups, mid(arguments.text, result.pos[i], result.len[i]));
                        }
                    }
                }
                
                arrayAppend(matches, matchData);
                start = result.pos[1] + result.len[1];
            } else {
                break;
            }
        }
        
        return matches;
    }
    
    private function getLineNumber(required string text, required numeric position) {
        var lines = listToArray(left(arguments.text, min(arguments.position, len(arguments.text))), chr(10));
        return arrayLen(lines);
    }
    
    private function filterBySeverity(required array issues, required string minSeverity) {
        var severityLevels = {
            "info" = 1,
            "warning" = 2,
            "error" = 3
        };
        
        var minLevel = severityLevels[arguments.minSeverity];
        
        return arguments.issues.filter(function(issue) {
            return severityLevels[issue.severity] >= minLevel;
        });
    }
    
    private function isExcluded(required string path) {
        for (var pattern in variables.config.exclude) {
            if (findNoCase(pattern, arguments.path)) {
                return true;
            }
        }
        
        // Also exclude minified files
        if (reFindNoCase("\.(min\.(js|css)|bundle\.js)$", arguments.path)) {
            return true;
        }
        
        return false;
    }
    
    private function resolvePath(path, baseDirectory = "") {
        var appPath = arguments.path;
        if (!findNoCase("app/", appPath) && !findNoCase("tests/", appPath)) {
            if (reFind("^(controllers|models|views|migrator)/", appPath)) {
                appPath = "app/" & appPath;
            }
        }
        
        if (left(appPath, 1) == "/" || mid(appPath, 2, 1) == ":") {
            return appPath;
        }
        
        var baseDir = len(arguments.baseDirectory) ? arguments.baseDirectory : expandPath(".");
        
        if (right(baseDir, 1) != "/") {
            baseDir &= "/";
        }
        
        return baseDir & appPath;
    }
}