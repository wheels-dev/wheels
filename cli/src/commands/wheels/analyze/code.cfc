/**
 * Analyze code quality and patterns
 * Examples:
 * wheels analyze code
 * wheels analyze code --fix --format=json
 * wheels analyze code --path=app/models --severity=error
 */
component extends="wheels-cli.models.BaseCommand" {
    
    property name="analysisService" inject="AnalysisService@wheels-cli";
    
    /**
     * @path.hint Path to analyze (default: current directory)
     * @fix.hint Attempt to fix issues automatically
     * @format.hint Output format (console, json, junit)
     * @format.options console,json,junit
     * @severity.hint Minimum severity level (info, warning, error)
     * @severity.options info,warning,error
     * @report.hint Generate HTML report
     * @verbose.hint Show detailed progress
     */
    function run(
        string path = ".",
        boolean fix = false,
        string format = "console",
        string severity = "warning",
        boolean report = false,
        boolean verbose = false
    ) {
        arguments = reconstructArgs(arguments);
        // Set verbose mode if requested
        if (arguments.verbose) {
            print.setVerbose(true);
        }
        
        print.yellowLine("Analyzing code quality...")
             .line();
        // Pass the print object to the service
        var results = analysisService.analyze(
            path = resolvePath(arguments.path),
            severity = arguments.severity,
            printer = print  // Pass the print object here
        );
        
        if (arguments.fix) {
            print.line().yellowLine("Applying automatic fixes...");
            var fixed = analysisService.autoFix(results, print); // Pass print here too
            print.greenLine("Fixed #fixed.count# issues automatically");
            print.line();

            // Re-analyze after fixes
            print.yellowLine("Re-analyzing after fixes...");
            results = analysisService.analyze(
                path = resolvePath(arguments.path),
                severity = arguments.severity,
                printer = print
            );
        }
        
        print.line();
        displayResults(results, arguments.format);
        
        if (arguments.report) {
            generateReport(results);
        }
        
        if (results.hasErrors) {
            setExitCode(1);
        }
    }
    
    // ... rest of your existing methods remain the same ...
    
    private function displayResults(results, format) {
        switch (format) {
            case "json":
                print.line(serializeJSON(results, true));
                break;
            case "junit":
                print.line(generateJUnitXML(results));
                break;
            default:
                displayConsoleResults(results);
        }
    }
    
    private function displayConsoleResults(results) {
        // Display header with grade
        print.line();
        displayCodeHealthHeader(results);
        
        if (results.totalIssues == 0 && results.metrics.duplicateBlocks == 0) {
            print.greenBoldLine("✅ Excellent! No issues found. Your code is pristine!");
            displayMetricsSummary(results);
            return;
        }
        
        // Display metrics summary
        displayMetricsSummary(results);
        
        // Display issue summary
        print.boldLine("📊 Issue Summary");
        print.line(repeatString("-", 50));
        
        if (results.summary.errors > 0) {
            print.redLine("🔴 Errors:   #padString(results.summary.errors, 5)# (Critical issues requiring immediate attention)");
        }
        if (results.summary.warnings > 0) {
            print.yellowLine("🟡 Warnings: #padString(results.summary.warnings, 5)# (Issues that should be addressed)");
        }
        if (results.summary.info > 0) {
            print.blueLine("🔵 Info:     #padString(results.summary.info, 5)# (Suggestions for improvement)");
        }
        
        print.line();
        
        // Display complexity analysis
        if (arrayLen(results.complexFunctions) > 0) {
            displayComplexityAnalysis(results);
        }
        
        // Display duplicate code blocks
        if (results.metrics.duplicateBlocks > 0) {
            displayDuplicateCode(results);
        }
        
        // Display issues by file
        if (structCount(results.files) > 0) {
            print.boldLine("📁 Issues by File");
            print.line(repeatString("-", 50));
            
            for (var filePath in results.files) {
                var fileIssues = results.files[filePath];
                var relativePath = replace(filePath, getCWD(), "");

                print.boldLine("#relativePath# (#arrayLen(fileIssues)# issues)");

                // Group issues by severity for better readability
                var groupedIssues = groupIssuesBySeverity(fileIssues);
                
                for (var severity in ["error", "warning", "info"]) {
                    if (structKeyExists(groupedIssues, severity) && arrayLen(groupedIssues[severity]) > 0) {
                        for (var issue in groupedIssues[severity]) {
                            var icon = getSeverityIcon(issue.severity);
                            var color = getSeverityColor(issue.severity);
                            
                            print[color & "Line"]("  #icon# Line #issue.line#:#issue.column# - #issue.message#");
                            print.grayLine("     Rule: #issue.rule#" & (issue.fixable ? " [Auto-fixable]" : ""));
                        }
                    }
                }
                
                print.line();
            }
        }
        
        // Display recommendations
        displayRecommendations(results);
        
        // Display execution time
        print.line();
        print.grayLine("⏱️  Analysis completed in #numberFormat(results.executionTime, '0.00')# seconds");
    }
    
    private function displayCodeHealthHeader(results) {
        var grade = results.metrics.grade;
        var score = results.metrics.healthScore;
        var gradeColor = getGradeColor(grade);
        
        print.line(repeatString("=", 50));
        print.boldLine("           CODE QUALITY REPORT");
        print.line(repeatString("=", 50));
        print.line();
        
        // Display grade with appropriate color
        print[gradeColor & "BoldLine"]("           Grade: #grade# (#score#/100)");
        
        // Display grade description
        var gradeDesc = getGradeDescription(grade);
        print.line("           #gradeDesc#");
        print.line(repeatString("=", 50));
        print.line();
    }
    
    private function displayMetricsSummary(results) {
        print.boldLine("📈 Code Metrics");
        print.line(repeatString("-", 50));
        print.line("Files Analyzed:       #padString(results.metrics.totalFiles, 5)#");
        print.line("Total Lines:          #padString(results.metrics.totalLines, 5)#");
        print.line("Functions:            #padString(results.metrics.totalFunctions, 5)#");
        print.line("Avg Complexity:       #padString(results.metrics.averageComplexity, 5)#");
        print.line("Duplicate Blocks:     #padString(results.metrics.duplicateBlocks, 5)#");
        print.line("Code Smells:          #padString(results.metrics.codeSmells, 5)#");
        print.line("Deprecated Calls:     #padString(results.metrics.deprecatedCalls, 5)#");
        print.line();
    }
    
    private function displayComplexityAnalysis(results) {
        print.boldLine("⚠️  High Complexity Functions");
        print.line(repeatString("-", 50));
        
        // Sort by complexity
        var sorted = duplicate(results.complexFunctions);
        arraySort(sorted, function(a, b) {
            return b.complexity - a.complexity;
        });
        
        // Show top 5
        var count = min(5, arrayLen(sorted));
        for (var i = 1; i <= count; i++) {
            var func = sorted[i];
            var relativePath = replace(func.file, getCWD(), "");
            print.yellowLine("  • #func.function#() in #relativePath#");
            // Use a default threshold of 10 if not available in results
            var threshold = structKeyExists(results, "config") && structKeyExists(results.config, "rules") 
                ? results.config.rules["max-function-complexity"] 
                : 10;
            print.line("    Complexity: #func.complexity# (threshold: #threshold#)");
        }
        
        if (arrayLen(sorted) > 5) {
            print.grayLine("  ... and #arrayLen(sorted) - 5# more");
        }
        print.line();
    }
    
    private function displayDuplicateCode(results) {
        print.boldLine("🔁 Duplicate Code Detection");
        print.line(repeatString("-", 50));
        print.yellowLine("Found #results.metrics.duplicateBlocks# duplicate code blocks");
        
        // Show first few duplicates
        var count = min(3, arrayLen(results.duplicates));
        for (var i = 1; i <= count; i++) {
            var dup = results.duplicates[i];
            print.line();
            print.line("  Duplicate Block #i# (#dup.lineCount# lines, #arrayLen(dup.occurrences)# occurrences):");
            for (var j = 1; j <= min(3, arrayLen(dup.occurrences)); j++) {
                var occ = dup.occurrences[j];
                var relativePath = replace(occ.file, getCWD(), "");
                print.grayLine("    - #relativePath# (lines #occ.startLine#-#occ.endLine#)");
            }
        }
        
        if (arrayLen(results.duplicates) > 3) {
            print.grayLine("  ... and #arrayLen(results.duplicates) - 3# more duplicate blocks");
        }
        print.line();
    }
    
    private function displayRecommendations(results) {
        print.yellowBoldLine("💡 Recommendations");
        print.line(repeatString("-", 50));
        
        var recommendations = [];
        
        if (countFixableIssues(results) > 0) {
            arrayAppend(recommendations, "Run with --fix to automatically fix #countFixableIssues(results)# issues");
        }
        
        if (results.metrics.averageComplexity > 10) {
            arrayAppend(recommendations, "Refactor complex functions to reduce cyclomatic complexity");
        }
        
        if (results.metrics.duplicateBlocks > 5) {
            arrayAppend(recommendations, "Extract duplicate code into reusable functions or components");
        }
        
        if (results.metrics.deprecatedCalls > 0) {
            arrayAppend(recommendations, "Update deprecated function calls to use modern alternatives");
        }
        
        if (results.metrics.codeSmells > 10) {
            arrayAppend(recommendations, "Address code smells to improve maintainability");
        }
        
        if (!fileExists(".wheelscheck")) {
            arrayAppend(recommendations, "Create a .wheelscheck config file for custom rules");
        }
        
        arrayAppend(recommendations, "Integrate this check into your CI/CD pipeline");
        
        for (var rec in recommendations) {
            print.line("  • #rec#");
        }
    }
    
    private function groupIssuesBySeverity(issues) {
        var grouped = {};
        for (var issue in arguments.issues) {
            if (!structKeyExists(grouped, issue.severity)) {
                grouped[issue.severity] = [];
            }
            arrayAppend(grouped[issue.severity], issue);
        }
        return grouped;
    }
    
    private function getGradeColor(grade) {
        switch(arguments.grade) {
            case "A": return "green";
            case "B": return "blue";
            case "C": return "yellow";
            case "D": return "magenta";
            case "F": return "red";
            default: return "";
        }
    }
    
    private function getGradeDescription(grade) {
        switch(arguments.grade) {
            case "A": return "Excellent code quality";
            case "B": return "Good code quality with minor issues";
            case "C": return "Acceptable code quality, needs improvement";
            case "D": return "Poor code quality, significant refactoring needed";
            case "F": return "Critical issues, immediate attention required";
            default: return "";
        }
    }
    
    private function padString(value, length) {
        var str = toString(arguments.value);
        while (len(str) < arguments.length) {
            str = " " & str;
        }
        return str;
    }
    
    private function generateJUnitXML(results) {
        var xml = '<?xml version="1.0" encoding="UTF-8"?>';
        xml &= '<testsuites name="Wheels Code Analysis">';
        
        for (var filePath in results.files) {
            var fileIssues = results.files[filePath];
            xml &= '<testsuite name="#xmlFormat(filePath)#" tests="#arrayLen(fileIssues)#">';
            
            for (var issue in fileIssues) {
                xml &= '<testcase name="#xmlFormat(issue.rule)#" classname="#xmlFormat(filePath)#">';
                if (issue.severity == "error") {
                    xml &= '<failure message="#xmlFormat(issue.message)#" type="#issue.severity#">';
                    xml &= 'Line #issue.line#, Column #issue.column#';
                    xml &= '</failure>';
                }
                xml &= '</testcase>';
            }
            
            xml &= '</testsuite>';
        }
        
        xml &= '</testsuites>';
        return xml;
    }
    
    private function generateReport(results) {
        var reportPath = fileSystemUtil.resolvePath("reports/code-analysis-#dateFormat(now(), 'yyyymmdd-HHmmss')#.html");
        var reportDir = getDirectoryFromPath(reportPath);
        
        if (!directoryExists(reportDir)) {
            directoryCreate(reportDir, true);
        }
        
        var html = generateReportHTML(results);
        fileWrite(reportPath, html);
        
        print.greenLine("📊 HTML report generated: #reportPath#");
    }
    
    private function generateReportHTML(results) {
        var gradeColor = getGradeColorHex(results.metrics.grade);
        
        return '<!DOCTYPE html>
<html>
<head>
    <title>Wheels Code Analysis Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; padding: 20px; background: ##f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: ##333; margin-bottom: 10px; }
        h2 { color: ##555; margin-top: 30px; }
        .grade-header { text-align: center; padding: 30px; background: linear-gradient(135deg, ' & gradeColor & '22, ' & gradeColor & '44); border-radius: 10px; margin-bottom: 30px; }
        .grade { font-size: 72px; font-weight: bold; color: ' & gradeColor & '; margin: 10px 0; }
        .grade-score { font-size: 24px; color: ##666; }
        .grade-desc { font-size: 18px; color: ##777; margin-top: 10px; }
        .summary { display: flex; gap: 20px; margin-bottom: 30px; flex-wrap: wrap; }
        .summary-card { flex: 1; min-width: 150px; padding: 20px; border-radius: 8px; text-align: center; }
        .summary-card.error { background: ##ffebee; color: ##c62828; }
        .summary-card.warning { background: ##fff3e0; color: ##ef6c00; }
        .summary-card.info { background: ##e3f2fd; color: ##1565c0; }
        .summary-card.success { background: ##e8f5e9; color: ##2e7d32; }
        .summary-card.metric { background: ##f3e5f5; color: ##6a1b9a; }
        .summary-card h3 { margin: 0 0 10px 0; font-size: 36px; }
        .summary-card p { margin: 0; font-size: 14px; }
        .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 30px; }
        .metric-item { background: ##f9f9f9; padding: 15px; border-radius: 8px; }
        .metric-label { font-size: 12px; color: ##999; text-transform: uppercase; }
        .metric-value { font-size: 24px; font-weight: bold; color: ##333; }
        .section { margin-bottom: 40px; }
        .complex-func { background: ##fff3e0; padding: 10px; margin: 5px 0; border-radius: 5px; }
        .duplicate-block { background: ##f3e5f5; padding: 10px; margin: 5px 0; border-radius: 5px; }
        .file-section { margin-bottom: 30px; }
        .file-header { background: ##f5f5f5; padding: 15px; border-radius: 5px; font-weight: bold; }
        .issue { padding: 15px; border-left: 4px solid ##ddd; margin: 10px 0; }
        .issue.error { border-color: ##f44336; background: ##ffebee; }
        .issue.warning { border-color: ##ff9800; background: ##fff3e0; }
        .issue.info { border-color: ##2196f3; background: ##e3f2fd; }
        .issue-header { display: flex; justify-content: space-between; margin-bottom: 5px; }
        .issue-location { font-family: monospace; color: ##666; }
        .issue-rule { font-size: 12px; color: ##999; }
        .fixable { color: ##4caf50; font-size: 12px; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid ##ddd; color: ##999; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Wheels Code Analysis Report</h1>
        <p>Generated on ' & dateTimeFormat(now(), "full") & ' • Execution time: ' & numberFormat(results.executionTime, '0.00') & ' seconds</p>
        
        <div class="grade-header">
            <div class="grade">' & results.metrics.grade & '</div>
            <div class="grade-score">Score: ' & results.metrics.healthScore & '/100</div>
            <div class="grade-desc">' & getGradeDescription(results.metrics.grade) & '</div>
        </div>
        
        <div class="summary">
            <div class="summary-card ' & (results.totalIssues == 0 ? 'success' : 'info') & '">
                <h3>' & results.totalIssues & '</h3>
                <p>Total Issues</p>
            </div>
            <div class="summary-card error">
                <h3>' & results.summary.errors & '</h3>
                <p>Errors</p>
            </div>
            <div class="summary-card warning">
                <h3>' & results.summary.warnings & '</h3>
                <p>Warnings</p>
            </div>
            <div class="summary-card info">
                <h3>' & results.summary.info & '</h3>
                <p>Info</p>
            </div>
            <div class="summary-card metric">
                <h3>' & results.metrics.duplicateBlocks & '</h3>
                <p>Duplicate Blocks</p>
            </div>
        </div>
        
        <h2>📊 Code Metrics</h2>
        <div class="metrics-grid">
            <div class="metric-item">
                <div class="metric-label">Files Analyzed</div>
                <div class="metric-value">' & results.metrics.totalFiles & '</div>
            </div>
            <div class="metric-item">
                <div class="metric-label">Total Lines</div>
                <div class="metric-value">' & numberFormat(results.metrics.totalLines, ',') & '</div>
            </div>
            <div class="metric-item">
                <div class="metric-label">Functions</div>
                <div class="metric-value">' & results.metrics.totalFunctions & '</div>
            </div>
            <div class="metric-item">
                <div class="metric-label">Avg Complexity</div>
                <div class="metric-value">' & results.metrics.averageComplexity & '</div>
            </div>
            <div class="metric-item">
                <div class="metric-label">Code Smells</div>
                <div class="metric-value">' & results.metrics.codeSmells & '</div>
            </div>
            <div class="metric-item">
                <div class="metric-label">Deprecated Calls</div>
                <div class="metric-value">' & results.metrics.deprecatedCalls & '</div>
            </div>
        </div>
        
        ' & generateComplexFunctionsHTML(results) & '
        ' & generateDuplicateCodeHTML(results) & '
        ' & generateFileIssuesHTML(results) & '
        
        <div class="footer">
            <p>Wheels Code Analyzer v1.0 • <a href="##">View Documentation</a></p>
        </div>
    </div>
</body>
</html>';
    }
    
    private function generateComplexFunctionsHTML(results) {
        if (arrayLen(results.complexFunctions) == 0) {
            return "";
        }
        
        var html = '<div class="section">';
        html &= '<h2>⚠️ Complex Functions</h2>';
        
        // Sort by complexity
        var sorted = duplicate(results.complexFunctions);
        arraySort(sorted, function(a, b) {
            return b.complexity - a.complexity;
        });
        
        for (var func in sorted) {
            var relativePath = replace(func.file, getCWD(), "");
            html &= '<div class="complex-func">';
            html &= '<strong>' & func.function & '()</strong> in ' & relativePath;
            html &= ' - Complexity: <strong>' & func.complexity & '</strong>';
            html &= '</div>';
        }
        
        html &= '</div>';
        return html;
    }
    
    private function generateDuplicateCodeHTML(results) {
        if (results.metrics.duplicateBlocks == 0) {
            return "";
        }
        
        var html = '<div class="section">';
        html &= '<h2>🔁 Duplicate Code Blocks</h2>';
        html &= '<p>Found ' & results.metrics.duplicateBlocks & ' duplicate code blocks across your codebase.</p>';
        
        var count = min(10, arrayLen(results.duplicates));
        for (var i = 1; i <= count; i++) {
            var dup = results.duplicates[i];
            html &= '<div class="duplicate-block">';
            html &= '<strong>Block ##' & i & '</strong> (' & dup.lineCount & ' lines, ' & arrayLen(dup.occurrences) & ' occurrences)';
            html &= '<ul>';
            for (var occ in dup.occurrences) {
                var relativePath = replace(occ.file, getCWD(), "");
                html &= '<li>' & relativePath & ' (lines ' & occ.startLine & '-' & occ.endLine & ')</li>';
            }
            html &= '</ul>';
            html &= '</div>';
        }
        
        html &= '</div>';
        return html;
    }
    
    private function getGradeColorHex(grade) {
        switch(arguments.grade) {
            case "A": return "##4caf50";
            case "B": return "##2196f3";
            case "C": return "##ff9800";
            case "D": return "##9c27b0";
            case "F": return "##f44336";
            default: return "##999999";
        }
    }
    
    private function generateFileIssuesHTML(results) {
        var html = "";
        
        for (var filePath in results.files) {
            var fileIssues = results.files[filePath];
            var relativePath = replace(filePath, getCWD(), "");
            
            html &= '<div class="file-section">';
            html &= '<div class="file-header">📄 ' & relativePath & ' (' & arrayLen(fileIssues) & ' issues)</div>';
            
            for (var issue in fileIssues) {
                html &= '<div class="issue ' & issue.severity & '">';
                html &= '<div class="issue-header">';
                html &= '<span>' & issue.message & '</span>';
                html &= '<span class="issue-location">Line ' & issue.line & ':' & issue.column & '</span>';
                html &= '</div>';
                html &= '<div class="issue-rule">Rule: ' & issue.rule & '</div>';
                if (issue.fixable) {
                    html &= '<div class="fixable">✅ Auto-fixable</div>';
                }
                html &= '</div>';
            }
            
            html &= '</div>';
        }
        
        return html;
    }
    
    private function getSeverityIcon(severity) {
        switch (arguments.severity) {
            case "error": return "🔴";
            case "warning": return "🟡";
            case "info": return "🔵";
            default: return "⚪";
        }
    }
    
    private function getSeverityColor(severity) {
        switch (arguments.severity) {
            case "error": return "red";
            case "warning": return "yellow";
            case "info": return "blue";
            default: return "";
        }
    }
    
    private function countFixableIssues(results) {
        var count = 0;
        for (var filePath in results.files) {
            for (var issue in results.files[filePath]) {
                if (issue.fixable) {
                    count++;
                }
            }
        }
        return count;
    }
}