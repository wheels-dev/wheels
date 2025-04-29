/**
 * Identify performance bottlenecks in applications
 * 
 * {code:bash}
 * wheels analyze
 * wheels analyze --target=controller
 * wheels analyze --target=view
 * wheels analyze --target=query
 * wheels analyze --target=memory
 * {code}
 */
component extends="base" {

    /**
     * @target Analysis target (controller, view, query, memory, or all)
     * @duration Duration to run analysis in seconds
     * @report Generate HTML report
     * @threshold Threshold for reporting issues (1-10, where 10 is most severe)
     */
    function run(
        string target="all",
        numeric duration=60,
        boolean report=true,
        numeric threshold=5
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Performance Analyzer");
        print.line();
        
        // Validate target
        local.validTargets = ["all", "controller", "view", "query", "memory"];
        if (!arrayContains(local.validTargets, lCase(arguments.target))) {
            error("Invalid target: #arguments.target#. Please choose from: #arrayToList(local.validTargets)#");
        }
        
        // Create URL parameters
        local.urlParams = "&command=analyze&target=#arguments.target#&duration=#arguments.duration#&threshold=#arguments.threshold#";
        
        if (arguments.report) {
            local.urlParams &= "&report=true";
        }
        
        // Start the analysis
        print.line("Starting performance analysis for #arguments.target#...");
        print.line("This will run for #arguments.duration# seconds. Please wait...");
        print.line();
        
        // Update progress while waiting for the analysis to complete
        local.startTime = getTickCount();
        local.endTime = local.startTime + (arguments.duration * 1000);
        
        // Enable data collection
        local.startResult = $sendToCliCommand(urlstring=local.urlParams & "&action=start");
        
        // Display progress
        while (getTickCount() < local.endTime) {
            local.elapsedSeconds = int((getTickCount() - local.startTime) / 1000);
            local.percentComplete = int((local.elapsedSeconds / arguments.duration) * 100);
            
            print.line("Progress: #local.percentComplete#% complete (#local.elapsedSeconds# of #arguments.duration# seconds)");
            sleep(5000); // Update every 5 seconds
            
            // Get intermediate results if available
            if (local.elapsedSeconds >= arguments.duration / 2) {
                local.progressResult = $sendToCliCommand(urlstring=local.urlParams & "&action=progress");
                
                if (structKeyExists(local.progressResult, "progress") && isStruct(local.progressResult.progress)) {
                    print.line();
                    print.yellowLine("Interim Results:");
                    
                    if (structKeyExists(local.progressResult.progress, "requestCount")) {
                        print.line("Requests processed: #local.progressResult.progress.requestCount#");
                    }
                    
                    if (structKeyExists(local.progressResult.progress, "avgResponseTime")) {
                        print.line("Average response time: #local.progressResult.progress.avgResponseTime# ms");
                    }
                    
                    print.line();
                }
            }
        }
        
        // Get final results
        local.result = $sendToCliCommand(urlstring=local.urlParams & "&action=stop");
        
        // Display results
        if (structKeyExists(local.result, "analysis") && isStruct(local.result.analysis)) {
            print.boldGreenLine("Analysis Complete!");
            print.line();
            
            // Display summary
            if (structKeyExists(local.result.analysis, "summary")) {
                print.boldYellowLine("Summary:");
                print.line();
                
                local.summary = local.result.analysis.summary;
                
                if (structKeyExists(local.summary, "requestCount")) {
                    print.line("Requests processed: #local.summary.requestCount#");
                }
                
                if (structKeyExists(local.summary, "avgResponseTime")) {
                    print.line("Average response time: #local.summary.avgResponseTime# ms");
                }
                
                if (structKeyExists(local.summary, "maxResponseTime")) {
                    print.line("Maximum response time: #local.summary.maxResponseTime# ms");
                }
                
                if (structKeyExists(local.summary, "avgMemoryUsage")) {
                    print.line("Average memory usage: #local.summary.avgMemoryUsage# MB");
                }
                
                if (structKeyExists(local.summary, "maxMemoryUsage")) {
                    print.line("Maximum memory usage: #local.summary.maxMemoryUsage# MB");
                }
                
                if (structKeyExists(local.summary, "issueCount")) {
                    print.line("Issues detected: #local.summary.issueCount#");
                }
                
                print.line();
            }
            
            // Display detailed results by target
            if (arguments.target == "all" || arguments.target == "controller") {
                displayControllerAnalysis(local.result.analysis);
            }
            
            if (arguments.target == "all" || arguments.target == "view") {
                displayViewAnalysis(local.result.analysis);
            }
            
            if (arguments.target == "all" || arguments.target == "query") {
                displayQueryAnalysis(local.result.analysis);
            }
            
            if (arguments.target == "all" || arguments.target == "memory") {
                displayMemoryAnalysis(local.result.analysis);
            }
            
            // If a report was generated, show the path
            if (arguments.report && structKeyExists(local.result, "reportPath")) {
                print.line();
                print.greenLine("HTML report generated at: #local.result.reportPath#");
            }
            
            // Display recommendations
            if (structKeyExists(local.result.analysis, "recommendations") && isArray(local.result.analysis.recommendations)) {
                print.line();
                print.boldYellowLine("Recommendations:");
                print.line();
                
                for (local.i = 1; local.i <= arrayLen(local.result.analysis.recommendations); local.i++) {
                    local.rec = local.result.analysis.recommendations[local.i];
                    print.yellowLine("#local.i#. #local.rec.title#");
                    print.line("   #local.rec.description#");
                    print.line();
                }
            }
        } else {
            print.boldRedLine("Failed to complete analysis");
            if (structKeyExists(local.result, "message")) {
                print.redLine(local.result.message);
            }
        }
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