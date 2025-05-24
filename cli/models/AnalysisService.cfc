component {
    
    property name="fileSystemUtil" inject="FileSystem@commandbox-core";
    property name="print" inject="print";
    
    /**
     * Analyze code quality and patterns
     */
    function analyze(
        required string path,
        string severity = "warning"
    ) {
        var results = {
            hasErrors = false,
            hasWarnings = false,
            totalIssues = 0,
            files = {},
            summary = {
                errors = 0,
                warnings = 0,
                info = 0
            }
        };
        
        var fullPath = fileSystemUtil.resolvePath(arguments.path);
        
        if (directoryExists(fullPath)) {
            analyzeDirectory(fullPath, results, arguments.severity);
        } else if (fileExists(fullPath)) {
            analyzeFile(fullPath, results, arguments.severity);
        } else {
            throw("Path not found: #arguments.path#");
        }
        
        // Update summary flags
        results.hasErrors = results.summary.errors > 0;
        results.hasWarnings = results.summary.warnings > 0;
        results.totalIssues = results.summary.errors + results.summary.warnings + results.summary.info;
        
        return results;
    }
    
    /**
     * Automatically fix certain types of issues
     */
    function autoFix(required struct results) {
        var fixed = {
            count = 0,
            files = []
        };
        
        for (var filePath in arguments.results.files) {
            var fileIssues = arguments.results.files[filePath];
            var fileFixed = false;
            
            for (var issue in fileIssues) {
                if (issue.fixable && structKeyExists(issue, "fix")) {
                    applyFix(filePath, issue);
                    fixed.count++;
                    fileFixed = true;
                }
            }
            
            if (fileFixed) {
                arrayAppend(fixed.files, filePath);
            }
        }
        
        return fixed;
    }
    
    /**
     * Analyze a directory recursively
     */
    private function analyzeDirectory(required string path, required struct results, required string severity) {
        var files = directoryList(
            arguments.path, 
            true, 
            "path", 
            "*.cfc|*.cfm", 
            "name asc"
        );
        
        for (var file in files) {
            if (!isExcluded(file)) {
                analyzeFile(file, arguments.results, arguments.severity);
            }
        }
    }
    
    /**
     * Analyze a single file
     */
    private function analyzeFile(required string path, required struct results, required string severity) {
        var issues = [];
        var content = fileRead(arguments.path);
        var lines = listToArray(content, chr(10));
        
        // Run various checks
        issues.addAll(checkCodeStyle(arguments.path, lines));
        issues.addAll(checkSecurity(arguments.path, lines));
        issues.addAll(checkPerformance(arguments.path, lines));
        issues.addAll(checkBestPractices(arguments.path, lines));
        
        // Filter by severity
        issues = filterBySeverity(issues, arguments.severity);
        
        if (arrayLen(issues)) {
            arguments.results.files[arguments.path] = issues;
            
            // Update summary
            for (var issue in issues) {
                arguments.results.summary[issue.severity]++;
            }
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
            if (len(line) > 120) {
                arrayAppend(issues, {
                    line = lineNum,
                    column = 121,
                    severity = "warning",
                    message = "Line exceeds 120 characters",
                    rule = "max-line-length",
                    fixable = false
                });
            }
            
            // Check for tabs vs spaces (assuming spaces are preferred)
            if (find(chr(9), line)) {
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
                        replace = "    "
                    }
                });
            }
            
            // Check for trailing whitespace
            if (reFind("\s+$", line)) {
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
        var lineNum = 0;
        var content = arrayToList(arguments.lines, chr(10));
        
        // Check for SQL injection vulnerabilities
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
        
        // Check for hardcoded credentials
        var credentialPatterns = [
            "password\s*=\s*[""'][^""']+[""']",
            "api_?key\s*=\s*[""'][^""']+[""']",
            "secret\s*=\s*[""'][^""']+[""']"
        ];
        
        for (var pattern in credentialPatterns) {
            var matches = reFindAll(pattern, content, false);
            for (var match in matches) {
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
        
        return issues;
    }
    
    /**
     * Check performance issues
     */
    private function checkPerformance(required string path, required array lines) {
        var issues = [];
        var content = arrayToList(arguments.lines, chr(10));
        
        // Check for N+1 query patterns
        if (reFindNoCase("cfloop.*cfquery|for\s*\(.*model\(.*\.find", content)) {
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
        
        return issues;
    }
    
    /**
     * Check best practices
     */
    private function checkBestPractices(required string path, required array lines) {
        var issues = [];
        var content = arrayToList(arguments.lines, chr(10));
        
        // Check for var scoping in functions
        if (reFindNoCase("function\s+\w+.*?{[^}]*(?<!var\s+)\w+\s*=", content)) {
            arrayAppend(issues, {
                line = 1,
                column = 1,
                severity = "warning",
                message = "Variable may not be properly scoped with 'var' or 'local'",
                rule = "var-scoping",
                fixable = false
            });
        }
        
        // Check for missing output attribute on components
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
                    replace = "component output=false"
                }
            });
        }
        
        return issues;
    }
    
    /**
     * Apply a fix to a file
     */
    private function applyFix(required string path, required struct issue) {
        var content = fileRead(arguments.path);
        
        switch (arguments.issue.fix.type) {
            case "replace":
                content = replace(
                    content, 
                    arguments.issue.fix.find, 
                    arguments.issue.fix.replace, 
                    "all"
                );
                break;
            case "trim":
                var lines = listToArray(content, chr(10));
                lines[arguments.issue.line] = trim(lines[arguments.issue.line]);
                content = arrayToList(lines, chr(10));
                break;
        }
        
        fileWrite(arguments.path, content);
    }
    
    /**
     * Helper to find all regex matches
     */
    private function reFindAll(required string pattern, required string text, boolean returnMatch = true) {
        var matches = [];
        var start = 1;
        var result = reFind(arguments.pattern, arguments.text, start, true);
        
        while (arrayLen(result.pos) && result.pos[1] > 0) {
            if (arguments.returnMatch) {
                arrayAppend(matches, {
                    match = result.match[1],
                    pos = result.pos[1],
                    len = result.len[1]
                });
            } else {
                arrayAppend(matches, {
                    pos = result.pos[1],
                    len = result.len[1]
                });
            }
            
            start = result.pos[1] + result.len[1];
            result = reFind(arguments.pattern, arguments.text, start, true);
        }
        
        return matches;
    }
    
    /**
     * Get line number from position in text
     */
    private function getLineNumber(required string text, required numeric position) {
        var lines = listToArray(left(arguments.text, arguments.position), chr(10));
        return arrayLen(lines);
    }
    
    /**
     * Filter issues by severity
     */
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
    
    /**
     * Check if file should be excluded from analysis
     */
    private function isExcluded(required string path) {
        var excludePatterns = [
            "vendor/",
            "node_modules/",
            ".git/",
            "testbox/",
            "tests/"
        ];
        
        for (var pattern in excludePatterns) {
            if (findNoCase(pattern, arguments.path)) {
                return true;
            }
        }
        
        return false;
    }
}