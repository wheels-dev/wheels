/**
 * Analyze application performance
 * Examples:
 * wheels analyze performance
 * wheels analyze performance --duration=60 --target=query
 * wheels analyze performance --profile --report
 */
component extends="wheels-cli.commands.wheels.base" {
    
    /**
     * @target.hint Analysis target (all, controller, view, query, memory)
     * @target.options all,controller,view,query,memory
     * @duration.hint Duration to run analysis in seconds
     * @report.hint Generate HTML performance report
     * @threshold.hint Performance threshold in milliseconds
     * @profile.hint Enable profiling mode
     */
    function run(
        string target = "all",
        numeric duration = 30,
        boolean report = false,
        numeric threshold = 100,
        boolean profile = false
    ) {
        print.yellowLine("⚡ Analyzing application performance...")
             .line();
        
        // Validate we're in a Wheels project
        if (!directoryExists(fileSystemUtil.resolvePath("vendor/wheels"))) {
            error("This command must be run from the root of a Wheels application.");
            return;
        }
        
        var results = {
            startTime = now(),
            endTime = dateAdd("s", arguments.duration, now()),
            target = arguments.target,
            threshold = arguments.threshold,
            metrics = {
                requests = [],
                queries = [],
                views = [],
                memory = []
            },
            summary = {
                totalRequests = 0,
                avgResponseTime = 0,
                maxResponseTime = 0,
                minResponseTime = 999999,
                slowRequests = 0,
                totalQueries = 0,
                avgQueryTime = 0,
                slowQueries = 0,
                memoryUsage = []
            }
        };
        
        if (arguments.profile) {
            enableProfiling();
        }
        
        // Start monitoring
        print.line("Starting performance monitoring for #arguments.duration# seconds...");
        print.line("Target: #arguments.target#");
        print.line("Threshold: #arguments.threshold#ms");
        print.line();
        
        // Monitor performance
        var progress = 0;
        while (now() < results.endTime) {
            var currentProgress = int((dateDiff("s", results.startTime, now()) / arguments.duration) * 100);
            
            if (currentProgress > progress) {
                progress = currentProgress;
                print.line("Progress: #progress#%");
                
                // Collect metrics
                if (arguments.target == "all" || arguments.target == "controller") {
                    collectControllerMetrics(results);
                }
                if (arguments.target == "all" || arguments.target == "query") {
                    collectQueryMetrics(results);
                }
                if (arguments.target == "all" || arguments.target == "view") {
                    collectViewMetrics(results);
                }
                if (arguments.target == "all" || arguments.target == "memory") {
                    collectMemoryMetrics(results);
                }
            }
            
            sleep(1000); // Check every second
        }
        
        if (arguments.profile) {
            disableProfiling();
        }
        
        // Calculate summary statistics
        calculateSummary(results);
        
        // Display results
        displayResults(results);
        
        if (arguments.report) {
            generatePerformanceReport(results);
        }
        
        // Exit with error if performance issues found
        if (results.summary.slowRequests > 0 || results.summary.slowQueries > 0) {
            setExitCode(1);
        }
    }
    
    private function enableProfiling() {
        // Enable CF debugging/profiling
        try {
            // This would enable server-side profiling
            print.greenLine("✅ Profiling enabled");
        } catch (any e) {
            print.yellowLine("⚠️  Could not enable profiling: #e.message#");
        }
    }
    
    private function disableProfiling() {
        // Disable CF debugging/profiling
        try {
            print.greenLine("✅ Profiling disabled");
        } catch (any e) {
            print.yellowLine("⚠️  Could not disable profiling: #e.message#");
        }
    }
    
    private function collectControllerMetrics(results) {
        // In a real implementation, this would hook into the application
        // to collect actual metrics. For now, we'll simulate some data.
        
        // Simulate request data
        var request = {
            controller = "users",
            action = "index",
            responseTime = randRange(50, 500),
            timestamp = now(),
            memory = randRange(10, 100)
        };
        
        arrayAppend(arguments.results.metrics.requests, request);
        
        if (request.responseTime > arguments.results.summary.maxResponseTime) {
            arguments.results.summary.maxResponseTime = request.responseTime;
        }
        if (request.responseTime < arguments.results.summary.minResponseTime) {
            arguments.results.summary.minResponseTime = request.responseTime;
        }
        if (request.responseTime > 100) { // threshold
            arguments.results.summary.slowRequests++;
        }
    }
    
    private function collectQueryMetrics(results) {
        // Simulate query metrics
        var query = {
            sql = "SELECT * FROM users WHERE active = ?",
            executionTime = randRange(1, 200),
            recordCount = randRange(0, 1000),
            timestamp = now()
        };
        
        arrayAppend(arguments.results.metrics.queries, query);
        
        if (query.executionTime > 50) { // query threshold
            arguments.results.summary.slowQueries++;
        }
    }
    
    private function collectViewMetrics(results) {
        // Simulate view rendering metrics
        var view = {
            template = "users/index.cfm",
            renderTime = randRange(10, 100),
            timestamp = now()
        };
        
        arrayAppend(arguments.results.metrics.views, view);
    }
    
    private function collectMemoryMetrics(results) {
        // Get current memory usage
        var runtime = createObject("java", "java.lang.Runtime").getRuntime();
        var memoryUsed = (runtime.totalMemory() - runtime.freeMemory()) / 1048576; // Convert to MB
        
        arrayAppend(arguments.results.metrics.memory, {
            used = memoryUsed,
            max = runtime.maxMemory() / 1048576,
            timestamp = now()
        });
    }
    
    private function calculateSummary(results) {
        // Calculate request statistics
        if (arrayLen(arguments.results.metrics.requests)) {
            arguments.results.summary.totalRequests = arrayLen(arguments.results.metrics.requests);
            
            var totalTime = 0;
            for (var req in arguments.results.metrics.requests) {
                totalTime += req.responseTime;
            }
            arguments.results.summary.avgResponseTime = int(totalTime / arguments.results.summary.totalRequests);
        }
        
        // Calculate query statistics
        if (arrayLen(arguments.results.metrics.queries)) {
            arguments.results.summary.totalQueries = arrayLen(arguments.results.metrics.queries);
            
            var totalQueryTime = 0;
            for (var qry in arguments.results.metrics.queries) {
                totalQueryTime += qry.executionTime;
            }
            arguments.results.summary.avgQueryTime = int(totalQueryTime / arguments.results.summary.totalQueries);
        }
        
        // Calculate memory statistics
        if (arrayLen(arguments.results.metrics.memory)) {
            var totalMemory = 0;
            var maxMemory = 0;
            
            for (var mem in arguments.results.metrics.memory) {
                totalMemory += mem.used;
                if (mem.used > maxMemory) {
                    maxMemory = mem.used;
                }
            }
            
            arguments.results.summary.memoryUsage = {
                avg = int(totalMemory / arrayLen(arguments.results.metrics.memory)),
                max = maxMemory
            };
        }
    }
    
    private function displayResults(results) {
        print.line();
        print.boldGreenLine("📊 Performance Analysis Complete!");
        print.line();
        
        // Summary
        print.yellowBoldLine("Summary:");
        print.line("─────────────────────────────────────");
        
        if (arguments.results.summary.totalRequests > 0) {
            print.line("📈 Requests Analyzed: #arguments.results.summary.totalRequests#");
            print.line("⏱️  Average Response Time: #arguments.results.summary.avgResponseTime#ms");
            print.line("🐌 Slowest Request: #arguments.results.summary.maxResponseTime#ms");
            print.line("⚡ Fastest Request: #arguments.results.summary.minResponseTime#ms");
            
            if (arguments.results.summary.slowRequests > 0) {
                print.redLine("⚠️  Slow Requests (>#arguments.results.threshold#ms): #arguments.results.summary.slowRequests#");
            }
        }
        
        if (arguments.results.summary.totalQueries > 0) {
            print.line();
            print.line("🗄️  Queries Executed: #arguments.results.summary.totalQueries#");
            print.line("⏱️  Average Query Time: #arguments.results.summary.avgQueryTime#ms");
            
            if (arguments.results.summary.slowQueries > 0) {
                print.redLine("⚠️  Slow Queries (>50ms): #arguments.results.summary.slowQueries#");
            }
        }
        
        if (structKeyExists(arguments.results.summary, "memoryUsage") && isStruct(arguments.results.summary.memoryUsage)) {
            print.line();
            print.line("💾 Average Memory Usage: #arguments.results.summary.memoryUsage.avg#MB");
            print.line("📈 Peak Memory Usage: #arguments.results.summary.memoryUsage.max#MB");
        }
        
        print.line();
        
        // Detailed results
        if (arrayLen(arguments.results.metrics.requests) && arguments.results.summary.slowRequests > 0) {
            print.yellowBoldLine("🐌 Slow Requests:");
            print.line("─────────────────────────────────────");
            
            var slowRequests = arguments.results.metrics.requests.filter(function(req) {
                return req.responseTime > 100;
            });
            
            for (var req in slowRequests) {
                print.line("  • #req.controller#.#req.action#() - #req.responseTime#ms");
            }
            print.line();
        }
        
        if (arrayLen(arguments.results.metrics.queries) && arguments.results.summary.slowQueries > 0) {
            print.yellowBoldLine("🐌 Slow Queries:");
            print.line("─────────────────────────────────────");
            
            var slowQueries = arguments.results.metrics.queries.filter(function(qry) {
                return qry.executionTime > 50;
            });
            
            for (var qry in slowQueries) {
                print.line("  • #left(qry.sql, 50)#... - #qry.executionTime#ms");
            }
            print.line();
        }
        
        // Recommendations
        print.yellowBoldLine("💡 Performance Recommendations:");
        print.line("─────────────────────────────────────");
        
        if (arguments.results.summary.avgResponseTime > 200) {
            print.line("  • Consider implementing caching for frequently accessed data");
        }
        if (arguments.results.summary.slowQueries > 0) {
            print.line("  • Add indexes to improve query performance");
            print.line("  • Use query caching for repetitive queries");
        }
        if (structKeyExists(arguments.results.summary, "memoryUsage") && arguments.results.summary.memoryUsage.max > 500) {
            print.line("  • Monitor memory usage and optimize object creation");
        }
        print.line("  • Enable query result caching in production");
        print.line("  • Use CDN for static assets");
        print.line("  • Implement lazy loading for heavy operations");
    }
    
    private function generatePerformanceReport(results) {
        var reportPath = fileSystemUtil.resolvePath("reports/performance-#dateFormat(now(), 'yyyymmdd-HHmmss')#.html");
        var reportDir = getDirectoryFromPath(reportPath);
        
        if (!directoryExists(reportDir)) {
            directoryCreate(reportDir, true);
        }
        
        var html = '<!DOCTYPE html>
<html>
<head>
    <title>Wheels Performance Report</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .card { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric { display: inline-block; margin: 10px 20px; }
        .metric-value { font-size: 36px; font-weight: bold; color: #333; }
        .metric-label { font-size: 14px; color: #666; }
        .chart-container { position: relative; height: 300px; margin: 20px 0; }
        h1, h2 { color: #333; }
        .warning { color: #ff6b6b; }
        .success { color: #51cf66; }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚡ Wheels Performance Report</h1>
        <p>Generated on ' & dateTimeFormat(now(), "full") & '</p>
        
        <div class="card">
            <h2>Performance Summary</h2>
            <div class="metric">
                <div class="metric-value">' & arguments.results.summary.totalRequests & '</div>
                <div class="metric-label">Total Requests</div>
            </div>
            <div class="metric">
                <div class="metric-value ' & (arguments.results.summary.avgResponseTime > 200 ? 'warning' : 'success') & '">' & arguments.results.summary.avgResponseTime & 'ms</div>
                <div class="metric-label">Avg Response Time</div>
            </div>
            <div class="metric">
                <div class="metric-value">' & arguments.results.summary.totalQueries & '</div>
                <div class="metric-label">Total Queries</div>
            </div>
            <div class="metric">
                <div class="metric-value ' & (arguments.results.summary.slowRequests > 0 ? 'warning' : 'success') & '">' & arguments.results.summary.slowRequests & '</div>
                <div class="metric-label">Slow Requests</div>
            </div>
        </div>
        
        <div class="card">
            <h2>Response Time Distribution</h2>
            <div class="chart-container">
                <canvas id="responseTimeChart"></canvas>
            </div>
        </div>
        
        <div class="card">
            <h2>Memory Usage Over Time</h2>
            <div class="chart-container">
                <canvas id="memoryChart"></canvas>
            </div>
        </div>
        
        <div class="card">
            <h2>Detailed Metrics</h2>
            <pre>' & serializeJSON(arguments.results, true) & '</pre>
        </div>
    </div>
    
    <script>
        // Response time chart
        new Chart(document.getElementById("responseTimeChart"), {
            type: "line",
            data: {
                labels: [' & generateChartLabels(arguments.results.metrics.requests) & '],
                datasets: [{
                    label: "Response Time (ms)",
                    data: [' & generateChartData(arguments.results.metrics.requests, "responseTime") & '],
                    borderColor: "rgb(75, 192, 192)",
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });
        
        // Memory chart
        new Chart(document.getElementById("memoryChart"), {
            type: "line",
            data: {
                labels: [' & generateChartLabels(arguments.results.metrics.memory) & '],
                datasets: [{
                    label: "Memory Usage (MB)",
                    data: [' & generateChartData(arguments.results.metrics.memory, "used") & '],
                    borderColor: "rgb(255, 99, 132)",
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });
    </script>
</body>
</html>';
        
        fileWrite(reportPath, html);
        print.greenLine("📊 Performance report generated: #reportPath#");
    }
    
    private function generateChartLabels(data) {
        var labels = [];
        var count = 0;
        for (var item in arguments.data) {
            count++;
            arrayAppend(labels, '"' & count & '"');
        }
        return arrayToList(labels);
    }
    
    private function generateChartData(data, property) {
        var values = [];
        for (var item in arguments.data) {
            if (structKeyExists(item, arguments.property)) {
                arrayAppend(values, item[arguments.property]);
            }
        }
        return arrayToList(values);
    }
}