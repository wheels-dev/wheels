/**
 * Analyze your Wheels application for performance, security, and code quality
 * 
 * {code:bash}
 * wheels analyze
 * wheels analyze performance
 * wheels analyze code
 * wheels analyze security
 * wheels analyze --type=all
 * {code}
 */
component extends="base" {

    /**
     * @type Analysis type (performance, code, security, or all)
     * @type.options performance,code,security,all
     * @report Generate HTML report
     * @path Path to analyze (default: current directory)
     * @format Output format (console, json, html)
     * @format.options console,json,html
     */
    function run(
        string type="all",
        boolean report=true,
        string path=".",
        string format="console"
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("🔍 Wheels Application Analyzer");
        print.line();
        
        // Validate type
        local.validTypes = ["all", "performance", "code", "security"];
        if (!arrayContainsNoCase(local.validTypes, arguments.type)) {
            error("Invalid type: #arguments.type#. Please choose from: #arrayToList(local.validTypes)#");
        }
        
        // Run appropriate analysis
        if (arguments.type == "all" || arguments.type == "performance") {
            runPerformanceAnalysis(argumentCollection=arguments);
        }
        
        if (arguments.type == "all" || arguments.type == "code") {
            runCodeAnalysis(argumentCollection=arguments);
        }
        
        if (arguments.type == "all" || arguments.type == "security") {
            runSecurityAnalysis(argumentCollection=arguments);
        }
    }
    
    /**
     * Run performance analysis
     */
    private function runPerformanceAnalysis(argumentCollection) {
        print.line();
        print.yellowBoldLine("⚡ Performance Analysis");
        print.line("────────────────────────");
        
        // Delegate to existing performance analysis logic
        command("wheels analyze performance")
            .params(argumentCollection=arguments)
            .run();
    }
    
    /**
     * Run code quality analysis
     */
    private function runCodeAnalysis(argumentCollection) {
        print.line();
        print.yellowBoldLine("📝 Code Quality Analysis");
        print.line("────────────────────────");
        
        var analysisService = getInstance("AnalysisService@wheels-cli");
        var results = analysisService.analyze(
            path = arguments.path,
            severity = "info"
        );
        
        // Display results
        if (arguments.format == "console") {
            displayCodeAnalysisResults(results);
        } else if (arguments.format == "json") {
            print.line(serializeJSON(results, true));
        } else if (arguments.format == "html" && arguments.report) {
            generateHTMLReport(results, "code-analysis");
        }
    }
    
    /**
     * Run security analysis
     */
    private function runSecurityAnalysis(argumentCollection) {
        print.line();
        print.yellowBoldLine("🔒 Security Analysis");
        print.line("────────────────────────");
        
        command("wheels analyze security")
            .params(argumentCollection=arguments)
            .run();
    }
    
    /**
     * Display code analysis results
     */
    private function displayCodeAnalysisResults(required struct results) {
        if (results.totalIssues == 0) {
            print.greenLine("✅ No issues found!");
            return;
        }
        
        print.line("Found #results.totalIssues# issues:");
        print.line("  🔴 Errors: #results.summary.errors#");
        print.line("  🟡 Warnings: #results.summary.warnings#");
        print.line("  🔵 Info: #results.summary.info#");
        print.line();
        
        // Display issues by file
        for (var filePath in results.files) {
            var fileIssues = results.files[filePath];
            print.boldLine("📄 #filePath#");
            
            for (var issue in fileIssues) {
                var icon = "";
                switch(issue.severity) {
                    case "error": icon = "🔴"; break;
                    case "warning": icon = "🟡"; break;
                    case "info": icon = "🔵"; break;
                }
                
                print.line("  #icon# Line #issue.line#: #issue.message# (#issue.rule#)");
            }
            print.line();
        }
    }
    
    /**
     * Generate HTML report
     */
    private function generateHTMLReport(required struct results, required string reportType) {
        var reportPath = fileSystemUtil.resolvePath("reports/#arguments.reportType#-#dateFormat(now(), 'yyyymmdd-HHmmss')#.html");
        var reportDir = getDirectoryFromPath(reportPath);
        
        if (!directoryExists(reportDir)) {
            directoryCreate(reportDir);
        }
        
        // Generate HTML content
        var html = generateReportHTML(arguments.results, arguments.reportType);
        fileWrite(reportPath, html);
        
        print.greenLine("📊 HTML report generated: #reportPath#");
    }
    
    /**
     * Generate HTML content for report
     */
    private function generateReportHTML(required struct results, required string reportType) {
        // Simple HTML report template
        return '<!DOCTYPE html>
<html>
<head>
    <title>Wheels ' & arguments.reportType & ' Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .summary { background: ##f0f0f0; padding: 15px; border-radius: 5px; }
        .issue { margin: 10px 0; padding: 10px; border-left: 3px solid ##ddd; }
        .error { border-color: ##ff0000; }
        .warning { border-color: ##ffaa00; }
        .info { border-color: ##0099ff; }
    </style>
</head>
<body>
    <h1>Wheels ' & arguments.reportType & ' Report</h1>
    <div class="summary">
        <h2>Summary</h2>
        <pre>' & serializeJSON(arguments.results.summary, true) & '</pre>
    </div>
    <h2>Details</h2>
    <pre>' & serializeJSON(arguments.results, true) & '</pre>
</body>
</html>';
    }
    
    /**
     * Helper to check if array contains value (case insensitive)
     */
    private function arrayContainsNoCase(required array arr, required string value) {
        for (var item in arguments.arr) {
            if (compareNoCase(item, arguments.value) == 0) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Display controller analysis results
     */
    private void function displayControllerAnalysis(required struct analysis) {
        if (structKeyExists(arguments.analysis, "controllers") && isArray(arguments.analysis.controllers)) {
            print.boldYellowLine("Controller Analysis:");
            print.line();
            
            if (arrayLen(arguments.analysis.controllers) == 0) {
                print.line("No controller issues detected");
                print.line();
                return;
            }
            
            local.controllersTable = [];
            
            for (local.controller in arguments.analysis.controllers) {
                local.action = structKeyExists(local.controller, "action") ? local.controller.action : "";
                local.avgTime = structKeyExists(local.controller, "avgExecutionTime") ? local.controller.avgExecutionTime & " ms" : "";
                local.callCount = structKeyExists(local.controller, "callCount") ? local.controller.callCount : "";
                local.severity = structKeyExists(local.controller, "severity") ? local.controller.severity : "";
                local.issue = structKeyExists(local.controller, "issue") ? local.controller.issue : "";
                
                arrayAppend(local.controllersTable, [local.controller.name, local.action, local.avgTime, local.callCount, local.severity, local.issue]);
            }
            
            print.table(local.controllersTable, ["Controller", "Action", "Avg Time", "Calls", "Severity", "Issue"]);
            print.line();
        }
    }
    
    /**
     * Display view analysis results
     */
    private void function displayViewAnalysis(required struct analysis) {
        if (structKeyExists(arguments.analysis, "views") && isArray(arguments.analysis.views)) {
            print.boldYellowLine("View Analysis:");
            print.line();
            
            if (arrayLen(arguments.analysis.views) == 0) {
                print.line("No view issues detected");
                print.line();
                return;
            }
            
            local.viewsTable = [];
            
            for (local.view in arguments.analysis.views) {
                local.renderTime = structKeyExists(local.view, "renderTime") ? local.view.renderTime & " ms" : "";
                local.size = structKeyExists(local.view, "size") ? local.view.size & " KB" : "";
                local.severity = structKeyExists(local.view, "severity") ? local.view.severity : "";
                local.issue = structKeyExists(local.view, "issue") ? local.view.issue : "";
                
                arrayAppend(local.viewsTable, [local.view.name, local.renderTime, local.size, local.severity, local.issue]);
            }
            
            print.table(local.viewsTable, ["View", "Render Time", "Size", "Severity", "Issue"]);
            print.line();
        }
    }
    
    /**
     * Display query analysis results
     */
    private void function displayQueryAnalysis(required struct analysis) {
        if (structKeyExists(arguments.analysis, "queries") && isArray(arguments.analysis.queries)) {
            print.boldYellowLine("Query Analysis:");
            print.line();
            
            if (arrayLen(arguments.analysis.queries) == 0) {
                print.line("No query issues detected");
                print.line();
                return;
            }
            
            local.queriesTable = [];
            
            for (local.query in arguments.analysis.queries) {
                local.execTime = structKeyExists(local.query, "executionTime") ? local.query.executionTime & " ms" : "";
                local.callCount = structKeyExists(local.query, "callCount") ? local.query.callCount : "";
                local.severity = structKeyExists(local.query, "severity") ? local.query.severity : "";
                local.issue = structKeyExists(local.query, "issue") ? local.query.issue : "";
                
                arrayAppend(local.queriesTable, [local.query.name, local.execTime, local.callCount, local.severity, local.issue]);
            }
            
            print.table(local.queriesTable, ["Query", "Exec Time", "Calls", "Severity", "Issue"]);
            print.line();
        }
    }
    
    /**
     * Display memory analysis results
     */
    private void function displayMemoryAnalysis(required struct analysis) {
        if (structKeyExists(arguments.analysis, "memory") && isArray(arguments.analysis.memory)) {
            print.boldYellowLine("Memory Analysis:");
            print.line();
            
            if (arrayLen(arguments.analysis.memory) == 0) {
                print.line("No memory issues detected");
                print.line();
                return;
            }
            
            local.memoryTable = [];
            
            for (local.item in arguments.analysis.memory) {
                local.usage = structKeyExists(local.item, "usage") ? local.item.usage & " MB" : "";
                local.peak = structKeyExists(local.item, "peak") ? local.item.peak & " MB" : "";
                local.severity = structKeyExists(local.item, "severity") ? local.item.severity : "";
                local.issue = structKeyExists(local.item, "issue") ? local.item.issue : "";
                
                arrayAppend(local.memoryTable, [local.item.name, local.usage, local.peak, local.severity, local.issue]);
            }
            
            print.table(local.memoryTable, ["Component", "Usage", "Peak", "Severity", "Issue"]);
            print.line();
        }
    }
}