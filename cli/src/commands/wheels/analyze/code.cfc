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
     */
    function run(
        string path = ".",
        boolean fix = false,
        string format = "console",
        string severity = "warning",
        boolean report = false
    ) {
        print.yellowLine("Analyzing code quality...")
             .line();
        
        var results = analysisService.analyze(
            path = resolvePath(arguments.path),
            severity = arguments.severity
        );
        
        if (arguments.fix) {
            var fixed = analysisService.autoFix(results);
            print.greenLine("Fixed #fixed.count# issues automatically");

            // Re-analyze after fixes
            results = analysisService.analyze(
                path = resolvePath(arguments.path),
                severity = arguments.severity
            );
        }
        
        displayResults(results, arguments.format);
        
        if (arguments.report) {
            generateReport(results);
        }
        
        if (results.hasErrors) {
            setExitCode(1);
        }
    }
    
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
        if (results.totalIssues == 0) {
            print.greenBoldLine("No issues found! Your code is clean.");
            return;
        }
        
        print.line("Found #results.totalIssues# issues:");
        print.line();
        
        // Summary
        if (results.summary.errors > 0) {
            print.redLine("Errors: #results.summary.errors#");
        }
        if (results.summary.warnings > 0) {
            print.yellowLine("Warnings: #results.summary.warnings#");
        }
        if (results.summary.info > 0) {
            print.blueLine("Info: #results.summary.info#");
        }
        
        print.line();
        
        // Issues by file
        for (var filePath in results.files) {
            var fileIssues = results.files[filePath];
            var relativePath = replace(filePath, getCWD(), "");

            print.boldLine("#relativePath#");

            for (var issue in fileIssues) {
                var icon = getSeverityIcon(issue.severity);
                var color = getSeverityColor(issue.severity);
                
                print[color & "Line"]("  #icon# Line #issue.line#:#issue.column# - #issue.message#");
                print.line("     Rule: #issue.rule#");
                
                if (issue.fixable) {
                    print.greenLine("      Auto-fixable");
                }
            }
            
            print.line();
        }
        
        // Recommendations
        print.yellowBoldLine("Recommendations:");
        print.line("  • Run with --fix to automatically fix #countFixableIssues(results)# issues");
        print.line("  • Consider using a .wheelscheck config file for custom rules");
        print.line("  • Integrate this check into your CI/CD pipeline");
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
        return '<!DOCTYPE html>
<html>
<head>
    <title>Wheels Code Analysis Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; padding: 20px; background: ##f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: ##333; margin-bottom: 30px; }
        .summary { display: flex; gap: 20px; margin-bottom: 30px; }
        .summary-card { flex: 1; padding: 20px; border-radius: 8px; text-align: center; }
        .summary-card.error { background: ##ffebee; color: ##c62828; }
        .summary-card.warning { background: ##fff3e0; color: ##ef6c00; }
        .summary-card.info { background: ##e3f2fd; color: ##1565c0; }
        .summary-card.success { background: ##e8f5e9; color: ##2e7d32; }
        .summary-card h2 { margin: 0 0 10px 0; font-size: 36px; }
        .summary-card p { margin: 0; font-size: 14px; }
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
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Wheels Code Analysis Report</h1>
        <p>Generated on ' & dateTimeFormat(now(), "full") & '</p>
        
        <div class="summary">
            <div class="summary-card ' & (results.totalIssues == 0 ? 'success' : 'info') & '">
                <h2>' & results.totalIssues & '</h2>
                <p>Total Issues</p>
            </div>
            <div class="summary-card error">
                <h2>' & results.summary.errors & '</h2>
                <p>Errors</p>
            </div>
            <div class="summary-card warning">
                <h2>' & results.summary.warnings & '</h2>
                <p>Warnings</p>
            </div>
            <div class="summary-card info">
                <h2>' & results.summary.info & '</h2>
                <p>Info</p>
            </div>
        </div>
        
        ' & generateFileIssuesHTML(results) & '
    </div>
</body>
</html>';
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