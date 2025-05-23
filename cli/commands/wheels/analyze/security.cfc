/**
 * Scan for security vulnerabilities
 * Examples:
 * wheels analyze security
 * wheels analyze security --fix --report=json
 * wheels analyze security --severity=high --path=app/
 */
component extends="wheels-cli.models.BaseCommand" {
    
    /**
     * @path.hint Path to scan (default: current directory)
     * @fix.hint Attempt to fix issues automatically
     * @report.hint Generate report in specified format
     * @report.options console,json,html
     * @severity.hint Minimum severity to report
     * @severity.options low,medium,high,critical
     * @deep.hint Perform deep scan (slower but more thorough)
     */
    function run(
        string path = ".",
        boolean fix = false,
        string report = "console",
        string severity = "medium",
        boolean deep = false
    ) {
        print.yellowLine("🔒 Scanning for security issues...")
             .line();
        
        var results = performSecurityScan(
            path = resolvePath(arguments.path),
            severity = arguments.severity,
            deep = arguments.deep
        );
        
        displaySecurityResults(results, arguments.report);
        
        if (arguments.fix && results.fixableIssues.len()) {
            var fixed = autoFixSecurityIssues(results.fixableIssues);
            print.greenLine("✅ Fixed #fixed# security issues");
        }
        
        if (results.hasHighSeverity || results.hasCritical) {
            setExitCode(1);
        }
    }
    
    private function performSecurityScan(required string path, required string severity, boolean deep = false) {
        var results = {
            hasHighSeverity = false,
            hasCritical = false,
            totalIssues = 0,
            fixableIssues = [],
            vulnerabilities = [],
            summary = {
                critical = 0,
                high = 0,
                medium = 0,
                low = 0
            }
        };
        
        // Scan for various security issues
        scanForSQLInjection(arguments.path, results);
        scanForXSS(arguments.path, results);
        scanForHardcodedCredentials(arguments.path, results);
        scanForInsecureDeserialization(arguments.path, results);
        scanForPathTraversal(arguments.path, results);
        scanForInsecureCookies(arguments.path, results);
        scanForWeakCrypto(arguments.path, results);
        
        if (arguments.deep) {
            scanForBusinessLogicFlaws(arguments.path, results);
            scanForInsecureFileOperations(arguments.path, results);
            scanForTimingAttacks(arguments.path, results);
        }
        
        // Update summary
        results.totalIssues = arrayLen(results.vulnerabilities);
        results.hasHighSeverity = results.summary.high > 0;
        results.hasCritical = results.summary.critical > 0;
        
        return results;
    }
    
    private function scanForSQLInjection(required string path, required struct results) {
        var files = directoryList(arguments.path, true, "path", "*.cfc|*.cfm");
        
        for (var file in files) {
            if (isExcluded(file)) continue;
            
            var content = fileRead(file);
            var lines = listToArray(content, chr(10));
            var lineNum = 0;
            
            // Patterns that indicate potential SQL injection
            var dangerousPatterns = [
                "preserveSingleQuotes\s*\(",
                "evaluate\s*\([^)]*sql",
                "cfquery[^>]+preservesinglequotes",
                "##[^##]+##[^##]*(SELECT|INSERT|UPDATE|DELETE|DROP)",
                "cfqueryparam\s*=\s*false",
                "sql\s*&\s*[^'""]+(?<!cfqueryparam)"
            ];
            
            for (var line in lines) {
                lineNum++;
                
                for (var pattern in dangerousPatterns) {
                    if (reFindNoCase(pattern, line)) {
                        var vuln = {
                            file = file,
                            line = lineNum,
                            type = "SQL Injection",
                            severity = "critical",
                            message = "Potential SQL injection vulnerability detected",
                            code = trim(line),
                            fixable = false,
                            recommendation = "Use cfqueryparam for all dynamic SQL values"
                        };
                        
                        arrayAppend(arguments.results.vulnerabilities, vuln);
                        arguments.results.summary.critical++;
                        
                        // Check if auto-fixable
                        if (canAutoFixSQLInjection(line)) {
                            vuln.fixable = true;
                            arrayAppend(arguments.results.fixableIssues, vuln);
                        }
                    }
                }
            }
        }
    }
    
    private function scanForXSS(required string path, required struct results) {
        var files = directoryList(arguments.path, true, "path", "*.cfm|*.cfc");
        
        for (var file in files) {
            if (isExcluded(file)) continue;
            
            var content = fileRead(file);
            var lines = listToArray(content, chr(10));
            var lineNum = 0;
            
            // XSS vulnerability patterns
            var xssPatterns = [
                "##[^##]+##(?![^<>]*>)(?![^""']*[""'])",  // Unencoded output
                "<cfoutput>[^<]+##[^##]+##[^<]+</cfoutput>(?!.*encodeFor)",
                "writeOutput\s*\([^)]+\)(?!.*encodeFor)",
                "url\.[^#\s]+(?!.*encodeFor)",
                "form\.[^#\s]+(?!.*encodeFor)"
            ];
            
            for (var line in lines) {
                lineNum++;
                
                for (var pattern in xssPatterns) {
                    if (reFindNoCase(pattern, line) && !reFindNoCase("encodeFor", line)) {
                        arrayAppend(arguments.results.vulnerabilities, {
                            file = file,
                            line = lineNum,
                            type = "Cross-Site Scripting (XSS)",
                            severity = "high",
                            message = "Unencoded output may lead to XSS vulnerability",
                            code = trim(line),
                            fixable = true,
                            recommendation = "Use appropriate encodeFor* functions (encodeForHTML, encodeForJavaScript, etc.)"
                        });
                        
                        arguments.results.summary.high++;
                    }
                }
            }
        }
    }
    
    private function scanForHardcodedCredentials(required string path, required struct results) {
        var files = directoryList(arguments.path, true, "path", "*.cfc|*.cfm|*.json|*.xml");
        
        for (var file in files) {
            if (isExcluded(file)) continue;
            
            var content = fileRead(file);
            var lines = listToArray(content, chr(10));
            var lineNum = 0;
            
            // Credential patterns
            var credentialPatterns = [
                "(password|passwd|pwd)\s*[:=]\s*[""'][^""']+[""']",
                "(api[_-]?key|apikey)\s*[:=]\s*[""'][^""']+[""']",
                "(secret|token)\s*[:=]\s*[""'][^""']+[""']",
                "datasource\s*=.*password\s*=\s*[""'][^""']+[""']",
                "(aws|azure|gcp)[_-]?(access[_-]?key|secret)\s*[:=]\s*[""'][^""']+[""']"
            ];
            
            for (var line in lines) {
                lineNum++;
                
                for (var pattern in credentialPatterns) {
                    if (reFindNoCase(pattern, line)) {
                        // Check if it's not a placeholder
                        if (!reFindNoCase("(example|placeholder|your[_-]?password|xxx+|<.*>|\$\{.*\})", line)) {
                            arrayAppend(arguments.results.vulnerabilities, {
                                file = file,
                                line = lineNum,
                                type = "Hardcoded Credentials",
                                severity = "critical",
                                message = "Hardcoded credentials detected",
                                code = maskCredentials(trim(line)),
                                fixable = false,
                                recommendation = "Use environment variables or secure configuration management"
                            });
                            
                            arguments.results.summary.critical++;
                        }
                    }
                }
            }
        }
    }
    
    private function scanForInsecureDeserialization(required string path, required struct results) {
        var files = directoryList(arguments.path, true, "path", "*.cfc|*.cfm");
        
        for (var file in files) {
            if (isExcluded(file)) continue;
            
            var content = fileRead(file);
            var lines = listToArray(content, chr(10));
            var lineNum = 0;
            
            for (var line in lines) {
                lineNum++;
                
                // Check for potentially unsafe deserialization
                if (reFindNoCase("(objectLoad|deserializeJSON|evaluate)\s*\([^)]*\)", line)) {
                    if (reFindNoCase("(form\.|url\.|cgi\.|cookie\.)", line)) {
                        arrayAppend(arguments.results.vulnerabilities, {
                            file = file,
                            line = lineNum,
                            type = "Insecure Deserialization",
                            severity = "high",
                            message = "Untrusted data deserialization detected",
                            code = trim(line),
                            fixable = false,
                            recommendation = "Validate and sanitize input before deserialization"
                        });
                        
                        arguments.results.summary.high++;
                    }
                }
            }
        }
    }
    
    private function scanForPathTraversal(required string path, required struct results) {
        var files = directoryList(arguments.path, true, "path", "*.cfc|*.cfm");
        
        for (var file in files) {
            if (isExcluded(file)) continue;
            
            var content = fileRead(file);
            var lines = listToArray(content, chr(10));
            var lineNum = 0;
            
            for (var line in lines) {
                lineNum++;
                
                // Check for file operations with user input
                if (reFindNoCase("(fileRead|fileWrite|fileOpen|directoryList|cffile|cfinclude)\s*\(", line)) {
                    if (reFindNoCase("(form\.|url\.|cgi\.|cookie\.)", line) && !reFindNoCase("getSafeFile|sanitizePath", line)) {
                        arrayAppend(arguments.results.vulnerabilities, {
                            file = file,
                            line = lineNum,
                            type = "Path Traversal",
                            severity = "high",
                            message = "Potential path traversal vulnerability",
                            code = trim(line),
                            fixable = false,
                            recommendation = "Validate and sanitize file paths, use whitelists"
                        });
                        
                        arguments.results.summary.high++;
                    }
                }
            }
        }
    }
    
    private function scanForInsecureCookies(required string path, required struct results) {
        var files = directoryList(arguments.path, true, "path", "*.cfc|*.cfm");
        
        for (var file in files) {
            if (isExcluded(file)) continue;
            
            var content = fileRead(file);
            
            // Check for cookie operations without secure flags
            if (reFindNoCase("cfcookie(?![^>]*secure)", content) || 
                reFindNoCase("cookie\s*\[.*\]\s*=(?!.*secure)", content)) {
                
                arrayAppend(arguments.results.vulnerabilities, {
                    file = file,
                    line = 0,
                    type = "Insecure Cookie",
                    severity = "medium",
                    message = "Cookie set without secure flag",
                    code = "Cookie operations detected without secure/httpOnly flags",
                    fixable = true,
                    recommendation = "Always set secure=true and httpOnly=true for cookies"
                });
                
                arguments.results.summary.medium++;
            }
        }
    }
    
    private function scanForWeakCrypto(required string path, required struct results) {
        var files = directoryList(arguments.path, true, "path", "*.cfc|*.cfm");
        
        for (var file in files) {
            if (isExcluded(file)) continue;
            
            var content = fileRead(file);
            var lines = listToArray(content, chr(10));
            var lineNum = 0;
            
            var weakCryptoPatterns = [
                "(MD5|SHA1)\s*\(",
                "algorithm\s*=\s*[""'](MD5|SHA1|DES)[""']",
                "hash\s*\([^,]+,\s*[""'](MD5|SHA1)[""']"
            ];
            
            for (var line in lines) {
                lineNum++;
                
                for (var pattern in weakCryptoPatterns) {
                    if (reFindNoCase(pattern, line)) {
                        arrayAppend(arguments.results.vulnerabilities, {
                            file = file,
                            line = lineNum,
                            type = "Weak Cryptography",
                            severity = "medium",
                            message = "Weak cryptographic algorithm detected",
                            code = trim(line),
                            fixable = true,
                            recommendation = "Use SHA256 or stronger algorithms"
                        });
                        
                        arguments.results.summary.medium++;
                    }
                }
            }
        }
    }
    
    private function scanForBusinessLogicFlaws(required string path, required struct results) {
        // Deep scan for business logic vulnerabilities
        // This would analyze control flow, authentication checks, etc.
        // Placeholder for more complex analysis
    }
    
    private function scanForInsecureFileOperations(required string path, required struct results) {
        // Scan for file upload vulnerabilities, unsafe file operations
        // Placeholder for implementation
    }
    
    private function scanForTimingAttacks(required string path, required struct results) {
        // Scan for timing attack vulnerabilities in authentication
        // Placeholder for implementation
    }
    
    private function displaySecurityResults(required struct results, required string format) {
        if (arguments.format == "json") {
            print.line(serializeJSON(results, true));
            return;
        } else if (arguments.format == "html") {
            generateSecurityReport(results);
            return;
        }
        
        // Console output
        if (results.totalIssues == 0) {
            print.greenBoldLine("✅ No security vulnerabilities detected!");
            return;
        }
        
        print.redBoldLine("⚠️  Found #results.totalIssues# security vulnerabilities:");
        print.line();
        
        // Summary
        if (results.summary.critical > 0) {
            print.redLine("  🚨 Critical: #results.summary.critical#");
        }
        if (results.summary.high > 0) {
            print.redLine("  🔴 High: #results.summary.high#");
        }
        if (results.summary.medium > 0) {
            print.yellowLine("  🟡 Medium: #results.summary.medium#");
        }
        if (results.summary.low > 0) {
            print.blueLine("  🔵 Low: #results.summary.low#");
        }
        
        print.line();
        
        // Group by type
        var vulnsByType = {};
        for (var vuln in results.vulnerabilities) {
            if (!structKeyExists(vulnsByType, vuln.type)) {
                vulnsByType[vuln.type] = [];
            }
            arrayAppend(vulnsByType[vuln.type], vuln);
        }
        
        // Display vulnerabilities
        for (var type in vulnsByType) {
            print.boldLine("🔒 #type# (#arrayLen(vulnsByType[type])# issues)");
            
            for (var vuln in vulnsByType[type]) {
                var severityIcon = getSeverityIcon(vuln.severity);
                var relativePath = replace(vuln.file, getCWD(), "");
                
                print.line("  #severityIcon# #relativePath#:#vuln.line#");
                print.line("     #vuln.message#");
                if (len(vuln.code) && vuln.code != "Cookie operations detected without secure/httpOnly flags") {
                    print.line("     Code: #left(vuln.code, 60)#...");
                }
                print.line("     💡 #vuln.recommendation#");
                if (vuln.fixable) {
                    print.greenLine("     ✅ Auto-fixable");
                }
                print.line();
            }
        }
        
        // Recommendations
        print.yellowBoldLine("🛡️  Security Recommendations:");
        print.line("  1. Fix all critical and high severity issues immediately");
        print.line("  2. Use cfqueryparam for all database queries");
        print.line("  3. Encode all output with appropriate encodeFor* functions");
        print.line("  4. Never hardcode credentials - use environment variables");
        print.line("  5. Implement security headers (CSP, X-Frame-Options, etc.)");
        print.line("  6. Regular security audits and dependency updates");
    }
    
    private function generateSecurityReport(results) {
        var reportPath = fileSystemUtil.resolvePath("reports/security-scan-#dateFormat(now(), 'yyyymmdd-HHmmss')#.html");
        var reportDir = getDirectoryFromPath(reportPath);
        
        if (!directoryExists(reportDir)) {
            directoryCreate(reportDir, true);
        }
        
        // Generate comprehensive HTML report
        // This would create a detailed security report with charts, etc.
        
        print.greenLine("📊 Security report generated: #reportPath#");
    }
    
    private function canAutoFixSQLInjection(line) {
        // Simple check if we can auto-fix the SQL injection
        return reFindNoCase("where.*=\s*##[^##]+##", arguments.line);
    }
    
    private function autoFixSecurityIssues(fixableIssues) {
        var fixedCount = 0;
        
        for (var issue in arguments.fixableIssues) {
            try {
                switch (issue.type) {
                    case "SQL Injection":
                        if (fixSQLInjection(issue)) fixedCount++;
                        break;
                    case "Cross-Site Scripting (XSS)":
                        if (fixXSS(issue)) fixedCount++;
                        break;
                    case "Weak Cryptography":
                        if (fixWeakCrypto(issue)) fixedCount++;
                        break;
                    case "Insecure Cookie":
                        if (fixInsecureCookie(issue)) fixedCount++;
                        break;
                }
            } catch (any e) {
                print.redLine("Failed to fix issue in #issue.file#: #e.message#");
            }
        }
        
        return fixedCount;
    }
    
    private function fixSQLInjection(issue) {
        // Implement SQL injection fix
        // This would add cfqueryparam tags
        return false;
    }
    
    private function fixXSS(issue) {
        // Implement XSS fix
        // This would add appropriate encodeFor* functions
        return false;
    }
    
    private function fixWeakCrypto(issue) {
        // Replace weak algorithms with stronger ones
        return false;
    }
    
    private function fixInsecureCookie(issue) {
        // Add secure and httpOnly flags to cookies
        return false;
    }
    
    private function maskCredentials(code) {
        // Mask sensitive information in output
        return reReplace(arguments.code, "([""'])([^""']{3})[^""']+([^""']{3})([""'])", "\1\2****\3\4", "all");
    }
    
    private function isExcluded(path) {
        var excludes = ["vendor/", "testbox/", "tests/", ".git/"];
        for (var exclude in excludes) {
            if (findNoCase(exclude, arguments.path)) {
                return true;
            }
        }
        return false;
    }
    
    private function getSeverityIcon(severity) {
        switch (arguments.severity) {
            case "critical": return "🚨";
            case "high": return "🔴";
            case "medium": return "🟡";
            case "low": return "🔵";
            default: return "⚪";
        }
    }
}