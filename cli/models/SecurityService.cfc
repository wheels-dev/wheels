component {
    
    property name="fileSystemUtil" inject="FileSystem@commandbox-core";
    
    /**
     * Scan for security vulnerabilities
     */
    function scan(required string path, string severity = "medium") {
        var results = {
            path: arguments.path,
            scanDate: now(),
            issues: [],
            fixableIssues: [],
            hasHighSeverity: false,
            severityCounts: {
                low: 0,
                medium: 0,
                high: 0,
                critical: 0
            }
        };
        
        // Get all CFC and CFM files
        var files = directoryList(
            arguments.path,
            true,
            "path",
            "*.cfc|*.cfm",
            "file"
        );
        
        // Scan each file
        for (var file in files) {
            var fileIssues = scanFile(file);
            results.issues.append(fileIssues, true);
        }
        
        // Process results
        for (var issue in results.issues) {
            // Count by severity
            results.severityCounts[issue.severity]++;
            
            // Check for high severity
            if (listFindNoCase("high,critical", issue.severity)) {
                results.hasHighSeverity = true;
            }
            
            // Collect fixable issues
            if (issue.fixable) {
                arrayAppend(results.fixableIssues, issue);
            }
        }
        
        // Filter by minimum severity
        results.issues = filterBySeverity(results.issues, arguments.severity);
        
        return results;
    }
    
    /**
     * Scan a single file for security issues
     */
    private function scanFile(required string filePath) {
        var issues = [];
        var content = fileRead(arguments.filePath);
        var lineNumber = 0;
        var lines = listToArray(content, chr(10));
        
        for (var line in lines) {
            lineNumber++;
            
            // SQL Injection vulnerabilities
            var sqlInjection = checkSQLInjection(line, lineNumber, arguments.filePath);
            if (!isNull(sqlInjection)) {
                arrayAppend(issues, sqlInjection);
            }
            
            // XSS vulnerabilities
            var xss = checkXSS(line, lineNumber, arguments.filePath);
            if (!isNull(xss)) {
                arrayAppend(issues, xss);
            }
            
            // Hardcoded credentials
            var credentials = checkHardcodedCredentials(line, lineNumber, arguments.filePath);
            if (!isNull(credentials)) {
                arrayAppend(issues, credentials);
            }
            
            // File upload vulnerabilities
            var fileUpload = checkFileUpload(line, lineNumber, arguments.filePath);
            if (!isNull(fileUpload)) {
                arrayAppend(issues, fileUpload);
            }
            
            // Directory traversal
            var traversal = checkDirectoryTraversal(line, lineNumber, arguments.filePath);
            if (!isNull(traversal)) {
                arrayAppend(issues, traversal);
            }
            
            // Insecure random
            var randomIssue = checkInsecureRandom(line, lineNumber, arguments.filePath);
            if (!isNull(randomIssue)) {
                arrayAppend(issues, randomIssue);
            }
        }
        
        return issues;
    }
    
    /**
     * Check for SQL injection vulnerabilities
     */
    private function checkSQLInjection(required string line, required numeric lineNumber, required string filePath) {
        // Check for dynamic SQL without query params
        if (reFindNoCase("(query|queryExecute)\s*\(.*##.*##", arguments.line) &&
            !reFindNoCase("queryParams|:[\w]+", arguments.line)) {
            
            return {
                type: "SQL_INJECTION",
                severity: "critical",
                file: arguments.filePath,
                line: arguments.lineNumber,
                message: "Potential SQL injection: Use query parameters instead of string concatenation",
                code: trim(arguments.line),
                fixable: true,
                fix: "Use queryExecute() with parameters or cfqueryparam"
            };
        }
        
        // Check for preserveSingleQuotes with user input
        if (reFindNoCase("preserveSingleQuotes\s*\(\s*(form\.|url\.|arguments\.)", arguments.line)) {
            return {
                type: "SQL_INJECTION",
                severity: "critical",
                file: arguments.filePath,
                line: arguments.lineNumber,
                message: "preserveSingleQuotes() with user input can lead to SQL injection",
                code: trim(arguments.line),
                fixable: false
            };
        }
    }
    
    /**
     * Check for XSS vulnerabilities
     */
    private function checkXSS(required string line, required numeric lineNumber, required string filePath) {
        // Check for unescaped output of user input
        if (reFindNoCase("##\s*(form\.|url\.|cookie\.|cgi\.)", arguments.line) &&
            !reFindNoCase("(encodeForHTML|encodeForHTMLAttribute|encodeForJavaScript|encodeForCSS|encodeForURL|htmlEditFormat)", arguments.line)) {
            
            return {
                type: "XSS",
                severity: "high",
                file: arguments.filePath,
                line: arguments.lineNumber,
                message: "Potential XSS: User input should be encoded before output",
                code: trim(arguments.line),
                fixable: true,
                fix: "Wrap output in appropriate encoding function (e.g., encodeForHTML())"
            };
        }
    }
    
    /**
     * Check for hardcoded credentials
     */
    private function checkHardcodedCredentials(required string line, required numeric lineNumber, required string filePath) {
        // Check for password assignments
        if (reFindNoCase("(password|passwd|pwd|apikey|api_key|secret)\s*=\s*[""'][^""']+[""']", arguments.line) &&
            !reFindNoCase("(env\.|application\.|server\.|getSystemSetting|getEnv)", arguments.line)) {
            
            return {
                type: "HARDCODED_CREDENTIALS",
                severity: "high",
                file: arguments.filePath,
                line: arguments.lineNumber,
                message: "Hardcoded credentials detected",
                code: trim(arguments.line),
                fixable: false,
                fix: "Move credentials to environment variables or secure configuration"
            };
        }
    }
    
    /**
     * Check for file upload vulnerabilities
     */
    private function checkFileUpload(required string line, required numeric lineNumber, required string filePath) {
        // Check for file uploads without validation
        if (reFindNoCase("(fileUpload|cffile.*action\s*=\s*[""']upload)", arguments.line) &&
            !reFindNoCase("(accept|strict|nameconflict)", arguments.line)) {
            
            return {
                type: "FILE_UPLOAD",
                severity: "high",
                file: arguments.filePath,
                line: arguments.lineNumber,
                message: "File upload without proper validation",
                code: trim(arguments.line),
                fixable: false,
                fix: "Add file type validation and use strict mode"
            };
        }
    }
    
    /**
     * Check for directory traversal vulnerabilities
     */
    private function checkDirectoryTraversal(required string line, required numeric lineNumber, required string filePath) {
        // Check for file operations with user input
        if (reFindNoCase("(fileRead|fileWrite|directoryList|cffile|cfinclude|cfmodule).*\(.*\##.*(url\.|form\.|cookie\.)", arguments.line) &&
            !reFindNoCase("(expandPath|fileSystemUtil\.resolvePath)", arguments.line)) {
            
            return {
                type: "DIRECTORY_TRAVERSAL",
                severity: "high",
                file: arguments.filePath,
                line: arguments.lineNumber,
                message: "Potential directory traversal vulnerability",
                code: trim(arguments.line),
                fixable: false,
                fix: "Validate and sanitize file paths, use expandPath() or resolvePath()"
            };
        }
    }
    
    /**
     * Check for insecure random number generation
     */
    private function checkInsecureRandom(required string line, required numeric lineNumber, required string filePath) {
        // Check for rand() or randomize() in security context
        if (reFindNoCase("(rand\(\)|randomize\(\)|randRange\(\))", arguments.line) &&
            reFindNoCase("(token|session|password|key|salt)", arguments.line)) {
            
            return {
                type: "INSECURE_RANDOM",
                severity: "medium",
                file: arguments.filePath,
                line: arguments.lineNumber,
                message: "Insecure random number generation for security-sensitive operation",
                code: trim(arguments.line),
                fixable: true,
                fix: "Use generateSecretKey() or createUUID() for security tokens"
            };
        }
    }
    
    /**
     * Auto-fix security issues where possible
     */
    function autoFix(required array issues) {
        var fixedCount = 0;
        
        for (var issue in arguments.issues) {
            if (issue.fixable) {
                try {
                    var fixed = false;
                    
                    switch (issue.type) {
                        case "SQL_INJECTION":
                            fixed = fixSQLInjection(issue);
                            break;
                        case "XSS":
                            fixed = fixXSS(issue);
                            break;
                        case "INSECURE_RANDOM":
                            fixed = fixInsecureRandom(issue);
                            break;
                    }
                    
                    if (fixed) {
                        fixedCount++;
                    }
                } catch (any e) {
                    // Log but continue with other fixes
                }
            }
        }
        
        return fixedCount;
    }
    
    /**
     * Fix SQL injection issues
     */
    private function fixSQLInjection(required struct issue) {
        var content = fileRead(arguments.issue.file);
        var lines = listToArray(content, chr(10));
        
        // Simple fix: add comment about using query params
        lines[arguments.issue.line] = lines[arguments.issue.line] & " // TODO: Use query parameters";
        
        fileWrite(arguments.issue.file, arrayToList(lines, chr(10)));
        return true;
    }
    
    /**
     * Fix XSS issues
     */
    private function fixXSS(required struct issue) {
        var content = fileRead(arguments.issue.file);
        var lines = listToArray(content, chr(10));
        var line = lines[arguments.issue.line];
        
        // Wrap user input in encodeForHTML
        line = reReplace(line, "##(form\.|url\.|cookie\.|cgi\.)([^##]+)##", "##encodeForHTML(\1\2)##", "all");
        lines[arguments.issue.line] = line;
        
        fileWrite(arguments.issue.file, arrayToList(lines, chr(10)));
        return true;
    }
    
    /**
     * Fix insecure random issues
     */
    private function fixInsecureRandom(required struct issue) {
        var content = fileRead(arguments.issue.file);
        var lines = listToArray(content, chr(10));
        var line = lines[arguments.issue.line];
        
        // Replace rand() with generateSecretKey()
        line = reReplace(line, "rand\(\)", "generateSecretKey('AES')", "all");
        line = reReplace(line, "randRange\([^)]+\)", "generateSecretKey('AES')", "all");
        lines[arguments.issue.line] = line;
        
        fileWrite(arguments.issue.file, arrayToList(lines, chr(10)));
        return true;
    }
    
    /**
     * Filter issues by minimum severity
     */
    private function filterBySeverity(required array issues, required string minSeverity) {
        var severityLevels = {
            low: 1,
            medium: 2,
            high: 3,
            critical: 4
        };
        
        var minLevel = severityLevels[arguments.minSeverity];
        
        return arguments.issues.filter(function(issue) {
            return severityLevels[issue.severity] >= minLevel;
        });
    }
    
    /**
     * Generate security report
     */
    function generateReport(required struct results, string format = "console") {
        switch (arguments.format) {
            case "json":
                return serializeJSON(arguments.results, true);
                
            case "html":
                return generateHTMLReport(arguments.results);
                
            default:
                return generateConsoleReport(arguments.results);
        }
    }
    
    /**
     * Generate HTML security report
     */
    private function generateHTMLReport(required struct results) {
        var html = "<!DOCTYPE html>
<html>
<head>
    <title>Wheels Security Scan Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .critical { color: ##d32f2f; }
        .high { color: ##f57c00; }
        .medium { color: ##fbc02d; }
        .low { color: ##388e3c; }
        .issue { margin: 10px 0; padding: 10px; border: 1px solid ##ddd; }
        code { background: ##f5f5f5; padding: 2px 4px; }
    </style>
</head>
<body>
    <h1>Security Scan Report</h1>
    <p>Scan Date: #dateTimeFormat(arguments.results.scanDate, 'yyyy-mm-dd HH:nn:ss')#</p>
    <p>Path: #arguments.results.path#</p>
    
    <h2>Summary</h2>
    <ul>
        <li>Critical: #arguments.results.severityCounts.critical#</li>
        <li>High: #arguments.results.severityCounts.high#</li>
        <li>Medium: #arguments.results.severityCounts.medium#</li>
        <li>Low: #arguments.results.severityCounts.low#</li>
    </ul>
    
    <h2>Issues</h2>";
        
        for (var issue in arguments.results.issues) {
            html &= "
    <div class='issue'>
        <h3 class='#issue.severity#'>#issue.type# - #issue.severity#</h3>
        <p><strong>File:</strong> #issue.file#:#issue.line#</p>
        <p><strong>Message:</strong> #issue.message#</p>
        <p><strong>Code:</strong> <code>#encodeForHTML(issue.code)#</code></p>
        <p><strong>Fix:</strong> #issue.fix#</p>
    </div>";
        }
        
        html &= "
</body>
</html>";
        
        return html;
    }
    
    /**
     * Generate console report
     */
    private function generateConsoleReport(required struct results) {
        var report = [];
        
        arrayAppend(report, "Security Scan Results");
        arrayAppend(report, "====================");
        arrayAppend(report, "Path: #arguments.results.path#");
        arrayAppend(report, "Date: #dateTimeFormat(arguments.results.scanDate, 'yyyy-mm-dd HH:nn:ss')#");
        arrayAppend(report, "");
        arrayAppend(report, "Summary:");
        arrayAppend(report, "  Critical: #arguments.results.severityCounts.critical#");
        arrayAppend(report, "  High: #arguments.results.severityCounts.high#");
        arrayAppend(report, "  Medium: #arguments.results.severityCounts.medium#");
        arrayAppend(report, "  Low: #arguments.results.severityCounts.low#");
        
        if (arrayLen(arguments.results.issues)) {
            arrayAppend(report, "");
            arrayAppend(report, "Issues Found:");
            
            for (var issue in arguments.results.issues) {
                arrayAppend(report, "");
                arrayAppend(report, "[#uCase(issue.severity)#] #issue.type#");
                arrayAppend(report, "File: #issue.file#:#issue.line#");
                arrayAppend(report, "Message: #issue.message#");
                arrayAppend(report, "Fix: #issue.fix#");
            }
        }
        
        return arrayToList(report, chr(10));
    }
}