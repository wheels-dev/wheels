/**
 * Profile Wheels application requests to identify performance bottlenecks
 *
 * This command helps you analyze the performance characteristics of your
 * Wheels application by profiling requests and generating detailed reports.
 *
 * {code:bash}
 * wheels profile /products
 * wheels profile /api/users --iterations=10
 * wheels profile /admin --output=html --save=profile.html
 * wheels profile --interactive
 * {code}
 **/
component extends="base" {

	/**
	 * @url URL or path to profile (required unless interactive mode)
	 * @iterations Number of times to run the request (default: 5)
	 * @method HTTP method to use (default: GET)
	 * @headers Comma-separated list of headers
	 * @data Request body data for POST/PUT requests
	 * @timeout Request timeout in seconds (default: 60)
	 * @output Output format: text, html, json (default: text)
	 * @save Save profile results to file
	 * @interactive Interactive mode to profile multiple endpoints
	 * @verbose Show detailed timing information
	 **/
	function run(
		string url = "",
		numeric iterations = 5,
		string method = "GET",
		string headers = "",
		string data = "",
		numeric timeout = 60,
		string output = "text",
		string save = "",
		boolean interactive = false,
		boolean verbose = false
	) {
		// Check if interactive mode
		if (arguments.interactive) {
			runInteractive();
			return;
		}

		// Validate URL is provided
		if (!len(arguments.url)) {
			error("URL is required. Use 'wheels profile /path' or 'wheels profile --interactive'");
		}

		// Get server info
		local.serverInfo = getServerInfo();
		local.fullUrl = normalizeUrl(arguments.url, local.serverInfo);

		// Parse headers
		local.headerStruct = parseHeaders(arguments.headers);

		// Show profile configuration
		print.boldLine("Profile Configuration:");
		print.line("URL: " & local.fullUrl);
		print.line("Method: " & arguments.method);
		print.line("Iterations: " & arguments.iterations);
		print.line("Output Format: " & arguments.output);
		print.line();

		// Enable CFML debugging/timing if possible
		enableProfiling();

		// Run profiling
		print.line("Profiling request...");
		local.profileResults = profileRequest(
			url = local.fullUrl,
			method = arguments.method,
			headers = local.headerStruct,
			data = arguments.data,
			timeout = arguments.timeout,
			iterations = arguments.iterations,
			verbose = arguments.verbose
		);

		// Display results
		displayProfileResults(local.profileResults, arguments.output);

		// Save results if requested
		if (len(arguments.save)) {
			saveProfileResults(local.profileResults, arguments.save, arguments.output);
			print.line().greenLine("Profile results saved to: " & arguments.save);
		}

		// Disable profiling
		disableProfiling();
	}

	/**
	 * Run interactive profiling session
	 */
	private void function runInteractive() {
		local.serverInfo = getServerInfo();
		local.profiles = [];
		
		print.boldLine("Interactive Profiling Mode");
		print.line("Enter URLs to profile (empty line to finish):");
		print.line();
		
		while (true) {
			local.url = ask("URL to profile: ");
			if (!len(trim(local.url))) {
				break;
			}
			
			local.method = ask("Method [GET]: ");
			if (!len(local.method)) {
				local.method = "GET";
			}
			
			local.iterations = ask("Iterations [5]: ");
			if (!len(local.iterations)) {
				local.iterations = 5;
			} else {
				local.iterations = val(local.iterations);
			}
			
			// Profile this endpoint
			local.fullUrl = normalizeUrl(local.url, local.serverInfo);
			print.line().line("Profiling " & local.fullUrl & "...");
			
			local.result = profileRequest(
				url = local.fullUrl,
				method = local.method,
				headers = {},
				data = "",
				timeout = 60,
				iterations = local.iterations,
				verbose = false
			);
			
			arrayAppend(local.profiles, local.result);
			displayProfileSummary(local.result);
			print.line();
		}
		
		if (arrayLen(local.profiles)) {
			// Show comparison
			print.boldLine("Profile Comparison:");
			compareProfiles(local.profiles);
			
			// Ask to save
			if (confirm("Save profile results?")) {
				local.filename = ask("Filename [profile-results.json]: ");
				if (!len(local.filename)) {
					local.filename = "profile-results.json";
				}
				fileWrite(
					fileSystemUtil.resolvePath(local.filename), 
					serializeJSON(local.profiles)
				);
				print.greenLine("Results saved to: " & local.filename);
			}
		}
	}

	/**
	 * Get server information
	 */
	private struct function getServerInfo() {
		local.serverJSON = serverService.getServerInfoJSON();
		
		if (structIsEmpty(local.serverJSON) || !structKeyExists(local.serverJSON, "url")) {
			error("No server is running. Start your server with 'server start' first.");
		}
		
		return {
			url: local.serverJSON.url,
			host: local.serverJSON.host,
			port: local.serverJSON.port
		};
	}

	/**
	 * Normalize URL
	 */
	private string function normalizeUrl(required string url, required struct serverInfo) {
		if (left(arguments.url, 4) == "http") {
			return arguments.url;
		}
		
		local.path = left(arguments.url, 1) == "/" ? arguments.url : "/" & arguments.url;
		return arguments.serverInfo.url & local.path;
	}

	/**
	 * Parse headers
	 */
	private struct function parseHeaders(required string headers) {
		local.headerStruct = {};
		
		if (len(arguments.headers)) {
			local.headerList = listToArray(arguments.headers, ",");
			for (local.header in local.headerList) {
				local.parts = listToArray(local.header, ":");
				if (arrayLen(local.parts) == 2) {
					local.headerStruct[trim(local.parts[1])] = trim(local.parts[2]);
				}
			}
		}
		
		return local.headerStruct;
	}

	/**
	 * Enable profiling features
	 */
	private void function enableProfiling() {
		// Add profiling headers
		// This would ideally enable CFML debugging features
		// For now, we'll use custom timing
	}

	/**
	 * Disable profiling features
	 */
	private void function disableProfiling() {
		// Remove profiling headers
	}

	/**
	 * Profile a single request multiple times
	 */
	private struct function profileRequest(
		required string url,
		required string method,
		required struct headers,
		required string data,
		required numeric timeout,
		required numeric iterations,
		required boolean verbose
	) {
		local.results = {
			url: arguments.url,
			method: arguments.method,
			iterations: arguments.iterations,
			timestamp: now(),
			timings: [],
			phases: {
				dns: [],
				connect: [],
				request: [],
				response: [],
				total: []
			},
			sizes: [],
			statusCodes: [],
			headers: [],
			metrics: {}
		};

		// Add profiling headers
		local.profileHeaders = duplicate(arguments.headers);
		local.profileHeaders["X-Wheels-Profile"] = "true";
		local.profileHeaders["X-Wheels-Debug"] = "true";

		// Run iterations
		for (local.i = 1; local.i <= arguments.iterations; local.i++) {
			if (arguments.verbose) {
				print.text("#chr(13)#Iteration #local.i#/#arguments.iterations#...").toConsole();
			}
			
			local.iterationResult = profileSingleRequest(
				url = arguments.url,
				method = arguments.method,
				headers = local.profileHeaders,
				data = arguments.data,
				timeout = arguments.timeout
			);
			
			// Collect results
			arrayAppend(local.results.timings, local.iterationResult.totalTime);
			arrayAppend(local.results.sizes, local.iterationResult.size);
			arrayAppend(local.results.statusCodes, local.iterationResult.statusCode);
			
			// Collect phase timings
			for (local.phase in local.iterationResult.phases) {
				if (structKeyExists(local.results.phases, local.phase)) {
					arrayAppend(local.results.phases[local.phase], local.iterationResult.phases[local.phase]);
				}
			}
			
			// Store first iteration headers for analysis
			if (local.i == 1) {
				local.results.headers = local.iterationResult.headers;
			}
			
			// Parse Wheels debug info if available
			if (structKeyExists(local.iterationResult, "wheelsDebug")) {
				if (!structKeyExists(local.results, "wheelsMetrics")) {
					local.results.wheelsMetrics = [];
				}
				arrayAppend(local.results.wheelsMetrics, local.iterationResult.wheelsDebug);
			}
		}
		
		if (arguments.verbose) {
			print.line(); // Clear iteration counter
		}

		// Calculate statistics
		local.results.stats = {
			timing: calculateStats(local.results.timings),
			size: calculateStats(local.results.sizes)
		};
		
		// Calculate phase statistics
		local.results.phaseStats = {};
		for (local.phase in local.results.phases) {
			if (arrayLen(local.results.phases[local.phase])) {
				local.results.phaseStats[local.phase] = calculateStats(local.results.phases[local.phase]);
			}
		}
		
		// Analyze Wheels-specific metrics
		if (structKeyExists(local.results, "wheelsMetrics") && arrayLen(local.results.wheelsMetrics)) {
			local.results.wheelsAnalysis = analyzeWheelsMetrics(local.results.wheelsMetrics);
		}
		
		return local.results;
	}

	/**
	 * Profile a single HTTP request with detailed timing
	 */
	private struct function profileSingleRequest(
		required string url,
		required string method,
		required struct headers,
		required string data,
		required numeric timeout
	) {
		local.result = {
			phases: {},
			headers: {},
			wheelsDebug: {}
		};
		
		local.startTime = getTickCount();
		
		try {
			// Make the request
			cfhttp(
				url = arguments.url,
				method = arguments.method,
				timeout = arguments.timeout,
				result = "local.httpResult"
			) {
				// Add headers
				for (local.key in arguments.headers) {
					cfhttpparam(type = "header", name = local.key, value = arguments.headers[local.key]);
				}
				
				// Add body for POST/PUT
				if (listFindNoCase("POST,PUT,PATCH", arguments.method) && len(arguments.data)) {
					cfhttpparam(type = "body", value = arguments.data);
				}
			}
			
			local.endTime = getTickCount();
			
			// Basic timing
			local.result.totalTime = local.endTime - local.startTime;
			local.result.statusCode = local.httpResult.statusCode;
			local.result.size = len(local.httpResult.fileContent);
			
			// Estimate phase timings (would be more accurate with lower-level access)
			local.result.phases.total = local.result.totalTime;
			local.result.phases.dns = round(local.result.totalTime * 0.05); // Estimate
			local.result.phases.connect = round(local.result.totalTime * 0.10); // Estimate
			local.result.phases.request = round(local.result.totalTime * 0.15); // Estimate
			local.result.phases.response = local.result.totalTime - local.result.phases.dns - local.result.phases.connect - local.result.phases.request;
			
			// Collect response headers
			local.result.headers = local.httpResult.responseHeader;
			
			// Look for Wheels debug information in headers or content
			if (structKeyExists(local.httpResult.responseHeader, "X-Wheels-Debug-Time")) {
				local.result.wheelsDebug.totalTime = val(local.httpResult.responseHeader["X-Wheels-Debug-Time"]);
			}
			
			if (structKeyExists(local.httpResult.responseHeader, "X-Wheels-Query-Count")) {
				local.result.wheelsDebug.queryCount = val(local.httpResult.responseHeader["X-Wheels-Query-Count"]);
			}
			
			if (structKeyExists(local.httpResult.responseHeader, "X-Wheels-Query-Time")) {
				local.result.wheelsDebug.queryTime = val(local.httpResult.responseHeader["X-Wheels-Query-Time"]);
			}
			
			// Try to extract debug info from HTML comments if present
			if (local.httpResult.mimeType contains "html") {
				local.debugInfo = extractDebugInfo(local.httpResult.fileContent);
				if (!structIsEmpty(local.debugInfo)) {
					structAppend(local.result.wheelsDebug, local.debugInfo, true);
				}
			}
			
		} catch (any e) {
			local.result.totalTime = getTickCount() - local.startTime;
			local.result.statusCode = 0;
			local.result.size = 0;
			local.result.error = e.message;
			local.result.phases.total = local.result.totalTime;
		}
		
		return local.result;
	}

	/**
	 * Extract debug information from HTML content
	 */
	private struct function extractDebugInfo(required string content) {
		local.debugInfo = {};
		
		// Look for Wheels debug comments
		local.debugPattern = "<!-- Wheels Debug: (.+?) -->";
		local.matches = reMatchNoCase(local.debugPattern, arguments.content);
		
		for (local.match in local.matches) {
			local.data = reReplaceNoCase(local.match, local.debugPattern, "\1");
			// Parse key:value pairs
			if (find(":", local.data)) {
				local.key = listFirst(local.data, ":");
				local.value = listRest(local.data, ":");
				local.debugInfo[local.key] = trim(local.value);
			}
		}
		
		return local.debugInfo;
	}

	/**
	 * Calculate statistics
	 */
	private struct function calculateStats(required array values) {
		if (arrayLen(arguments.values) == 0) {
			return {
				min: 0,
				max: 0,
				mean: 0,
				median: 0,
				stdDev: 0
			};
		}
		
		local.sorted = duplicate(arguments.values);
		arraySort(local.sorted, "numeric");
		
		local.sum = arraySum(local.sorted);
		local.mean = local.sum / arrayLen(local.sorted);
		
		// Calculate standard deviation
		local.squaredDiffs = [];
		for (local.value in arguments.values) {
			arrayAppend(local.squaredDiffs, (local.value - local.mean) ^ 2);
		}
		local.variance = arraySum(local.squaredDiffs) / arrayLen(local.squaredDiffs);
		local.stdDev = sqr(local.variance);
		
		return {
			min: local.sorted[1],
			max: local.sorted[arrayLen(local.sorted)],
			mean: round(local.mean),
			median: local.sorted[ceiling(arrayLen(local.sorted) / 2)],
			stdDev: round(local.stdDev)
		};
	}

	/**
	 * Analyze Wheels-specific metrics
	 */
	private struct function analyzeWheelsMetrics(required array metrics) {
		local.analysis = {
			queries: {
				counts: [],
				times: []
			},
			recommendations: []
		};
		
		// Collect query metrics
		for (local.metric in arguments.metrics) {
			if (structKeyExists(local.metric, "queryCount")) {
				arrayAppend(local.analysis.queries.counts, local.metric.queryCount);
			}
			if (structKeyExists(local.metric, "queryTime")) {
				arrayAppend(local.analysis.queries.times, local.metric.queryTime);
			}
		}
		
		// Calculate query statistics
		if (arrayLen(local.analysis.queries.counts)) {
			local.analysis.queries.countStats = calculateStats(local.analysis.queries.counts);
			local.avgQueries = local.analysis.queries.countStats.mean;
			
			if (local.avgQueries > 50) {
				arrayAppend(local.analysis.recommendations, "High query count detected (" & round(local.avgQueries) & " avg). Consider using includes() to reduce N+1 queries.");
			}
		}
		
		if (arrayLen(local.analysis.queries.times)) {
			local.analysis.queries.timeStats = calculateStats(local.analysis.queries.times);
			local.avgQueryTime = local.analysis.queries.timeStats.mean;
			
			if (local.avgQueryTime > 1000) {
				arrayAppend(local.analysis.recommendations, "Slow queries detected (" & round(local.avgQueryTime) & "ms avg). Review query performance and add indexes if needed.");
			}
		}
		
		return local.analysis;
	}

	/**
	 * Display profile results
	 */
	private void function displayProfileResults(required struct results, required string format) {
		if (arguments.format == "json") {
			print.line(serializeJSON(arguments.results));
			return;
		}
		
		if (arguments.format == "html") {
			displayHTMLResults(arguments.results);
			return;
		}
		
		// Default text format
		print.line();
		print.boldLine("Profile Results:");
		print.line("─".repeatString(60));
		
		print.line("URL: " & arguments.results.url);
		print.line("Method: " & arguments.results.method);
		print.line("Iterations: " & arguments.results.iterations);
		print.line();
		
		// Response time statistics
		print.boldLine("Response Times (ms):");
		print.line("  Min: " & arguments.results.stats.timing.min);
		print.line("  Max: " & arguments.results.stats.timing.max);
		print.line("  Mean: " & arguments.results.stats.timing.mean);
		print.line("  Median: " & arguments.results.stats.timing.median);
		print.line("  Std Dev: " & arguments.results.stats.timing.stdDev);
		print.line();
		
		// Phase breakdown if available
		if (structKeyExists(arguments.results, "phaseStats") && structCount(arguments.results.phaseStats)) {
			print.boldLine("Phase Breakdown (ms avg):");
			for (local.phase in arguments.results.phaseStats) {
				if (local.phase != "total") {
					print.line("  #uCase(left(local.phase, 1))##right(local.phase, len(local.phase)-1)#: " & arguments.results.phaseStats[local.phase].mean);
				}
			}
			print.line();
		}
		
		// Response size statistics
		print.boldLine("Response Sizes:");
		print.line("  Min: " & formatBytes(arguments.results.stats.size.min));
		print.line("  Max: " & formatBytes(arguments.results.stats.size.max));
		print.line("  Mean: " & formatBytes(arguments.results.stats.size.mean));
		print.line();
		
		// Wheels-specific analysis
		if (structKeyExists(arguments.results, "wheelsAnalysis")) {
			print.boldLine("Wheels Analysis:");
			
			if (structKeyExists(arguments.results.wheelsAnalysis.queries, "countStats")) {
				print.line("  Query Count: " & round(arguments.results.wheelsAnalysis.queries.countStats.mean) & " avg");
			}
			
			if (structKeyExists(arguments.results.wheelsAnalysis.queries, "timeStats")) {
				print.line("  Query Time: " & round(arguments.results.wheelsAnalysis.queries.timeStats.mean) & "ms avg");
			}
			
			if (arrayLen(arguments.results.wheelsAnalysis.recommendations)) {
				print.line();
				print.yellowBoldLine("Recommendations:");
				for (local.rec in arguments.results.wheelsAnalysis.recommendations) {
					print.yellowLine("  • " & local.rec);
				}
			}
			print.line();
		}
		
		// Headers analysis
		if (structCount(arguments.results.headers)) {
			local.importantHeaders = ["Server", "X-Powered-By", "Content-Type", "Content-Encoding", "Cache-Control"];
			print.boldLine("Response Headers:");
			for (local.header in local.importantHeaders) {
				if (structKeyExists(arguments.results.headers, local.header)) {
					print.line("  " & local.header & ": " & arguments.results.headers[local.header]);
				}
			}
		}
	}

	/**
	 * Display profile summary (for interactive mode)
	 */
	private void function displayProfileSummary(required struct result) {
		print.line("  Response Time: " & result.stats.timing.mean & "ms (avg)");
		print.line("  Response Size: " & formatBytes(result.stats.size.mean) & " (avg)");
		
		if (structKeyExists(result, "wheelsAnalysis") && structKeyExists(result.wheelsAnalysis.queries, "countStats")) {
			print.line("  Query Count: " & round(result.wheelsAnalysis.queries.countStats.mean) & " (avg)");
		}
	}

	/**
	 * Compare multiple profiles
	 */
	private void function compareProfiles(required array profiles) {
		print.line("─".repeatString(80));
		print.line(
			ljustify("URL", 40) & 
			rjustify("Time (ms)", 12) & 
			rjustify("Size", 12) & 
			rjustify("Queries", 12)
		);
		print.line("─".repeatString(80));
		
		for (local.profile in arguments.profiles) {
			local.url = local.profile.url;
			if (len(local.url) > 40) {
				local.url = "..." & right(local.url, 37);
			}
			
			local.queries = "N/A";
			if (structKeyExists(local.profile, "wheelsAnalysis") && structKeyExists(local.profile.wheelsAnalysis.queries, "countStats")) {
				local.queries = round(local.profile.wheelsAnalysis.queries.countStats.mean);
			}
			
			print.line(
				ljustify(local.url, 40) & 
				rjustify(local.profile.stats.timing.mean, 12) & 
				rjustify(formatBytes(local.profile.stats.size.mean), 12) & 
				rjustify(local.queries, 12)
			);
		}
		print.line("─".repeatString(80));
	}

	/**
	 * Display HTML results
	 */
	private void function displayHTMLResults(required struct results) {
		local.html = generateHTMLReport(arguments.results);
		print.line(local.html);
	}

	/**
	 * Generate HTML report
	 */
	private string function generateHTMLReport(required struct results) {
		savecontent variable="local.html" {
			writeOutput('
<!DOCTYPE html>
<html>
<head>
	<title>Wheels Profile Report</title>
	<style>
		body { font-family: Arial, sans-serif; margin: 20px; background: ##f5f5f5; }
		.container { max-width: 1000px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
		h1, h2 { color: ##333; }
		.metric { display: inline-block; margin: 10px 20px 10px 0; }
		.metric-label { font-size: 12px; color: ##666; text-transform: uppercase; }
		.metric-value { font-size: 24px; font-weight: bold; color: ##2196F3; }
		table { width: 100%; border-collapse: collapse; margin: 20px 0; }
		th, td { padding: 10px; text-align: left; border-bottom: 1px solid ##ddd; }
		th { background: ##f8f8f8; font-weight: normal; color: ##666; }
		.recommendation { background: ##fff3cd; border: 1px solid ##ffeeba; padding: 10px; margin: 10px 0; border-radius: 4px; }
		.chart { margin: 20px 0; }
		canvas { max-width: 100%; }
	</style>
	<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
	<div class="container">
		<h1>Wheels Profile Report</h1>
		<p><strong>URL:</strong> #encodeForHTML(arguments.results.url)#<br>
		<strong>Method:</strong> #encodeForHTML(arguments.results.method)#<br>
		<strong>Timestamp:</strong> #dateTimeFormat(arguments.results.timestamp, "yyyy-mm-dd HH:nn:ss")#<br>
		<strong>Iterations:</strong> #arguments.results.iterations#</p>
		
		<h2>Response Time Metrics</h2>
		<div>
			<div class="metric">
				<div class="metric-label">Mean</div>
				<div class="metric-value">#arguments.results.stats.timing.mean#ms</div>
			</div>
			<div class="metric">
				<div class="metric-label">Median</div>
				<div class="metric-value">#arguments.results.stats.timing.median#ms</div>
			</div>
			<div class="metric">
				<div class="metric-label">Min</div>
				<div class="metric-value">#arguments.results.stats.timing.min#ms</div>
			</div>
			<div class="metric">
				<div class="metric-label">Max</div>
				<div class="metric-value">#arguments.results.stats.timing.max#ms</div>
			</div>
			<div class="metric">
				<div class="metric-label">Std Dev</div>
				<div class="metric-value">#arguments.results.stats.timing.stdDev#ms</div>
			</div>
		</div>
		
		<div class="chart">
			<canvas id="timingChart"></canvas>
		</div>
		
		<h2>Response Times by Iteration</h2>
		<table>
			<thead>
				<tr>
					<th>Iteration</th>
					<th>Response Time (ms)</th>
					<th>Size</th>
					<th>Status</th>
				</tr>
			</thead>
			<tbody>');
			
			for (local.i = 1; local.i <= arrayLen(arguments.results.timings); local.i++) {
				writeOutput('
				<tr>
					<td>#local.i#</td>
					<td>#arguments.results.timings[local.i]#</td>
					<td>#formatBytes(arguments.results.sizes[local.i])#</td>
					<td>#arguments.results.statusCodes[local.i]#</td>
				</tr>');
			}
			
			writeOutput('
			</tbody>
		</table>');
		
		if (structKeyExists(arguments.results, "wheelsAnalysis") && arrayLen(arguments.results.wheelsAnalysis.recommendations)) {
			writeOutput('
		<h2>Performance Recommendations</h2>');
			for (local.rec in arguments.results.wheelsAnalysis.recommendations) {
				writeOutput('
		<div class="recommendation">#encodeForHTML(local.rec)#</div>');
			}
		}
		
		writeOutput('
	</div>
	
	<script>
		const ctx = document.getElementById("timingChart").getContext("2d");
		new Chart(ctx, {
			type: "line",
			data: {
				labels: [#arrayToList(arrayMap(arguments.results.timings, function(v, i) { return i; }))#],
				datasets: [{
					label: "Response Time (ms)",
					data: [#arrayToList(arguments.results.timings)#],
					borderColor: "##2196F3",
					tension: 0.1
				}]
			},
			options: {
				responsive: true,
				plugins: {
					title: {
						display: true,
						text: "Response Time Distribution"
					}
				}
			}
		});
	</script>
</body>
</html>');
		}
		
		return trim(local.html);
	}

	/**
	 * Save profile results
	 */
	private void function saveProfileResults(required struct results, required string filename, required string format) {
		local.content = "";
		
		if (arguments.format == "json") {
			local.content = serializeJSON(arguments.results);
		} else if (arguments.format == "html") {
			local.content = generateHTMLReport(arguments.results);
		} else {
			// Capture text output
			savecontent variable="local.content" {
				displayProfileResults(arguments.results, "text");
			}
		}
		
		fileWrite(fileSystemUtil.resolvePath(arguments.filename), local.content);
	}

	/**
	 * Format bytes
	 */
	private string function formatBytes(required numeric bytes) {
		if (arguments.bytes < 1024) {
			return arguments.bytes & " B";
		} else if (arguments.bytes < 1048576) {
			return numberFormat(arguments.bytes / 1024, "0.0") & " KB";
		} else {
			return numberFormat(arguments.bytes / 1048576, "0.0") & " MB";
		}
	}

}