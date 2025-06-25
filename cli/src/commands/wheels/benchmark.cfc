/**
 * Simple benchmarking tool for Wheels applications
 *
 * This command allows you to benchmark your Wheels application endpoints
 * to measure performance and identify bottlenecks.
 *
 * {code:bash}
 * wheels benchmark /
 * wheels benchmark /products --requests=1000 --concurrent=10
 * wheels benchmark /api/users --method=POST --data='{"name":"test"}'
 * wheels benchmark --config=benchmark.json
 * {code}
 **/
component extends="base" {

	/**
	 * @url URL or path to benchmark (required unless using config file)
	 * @requests Number of requests to make (default: 100)
	 * @concurrent Number of concurrent requests (default: 1)
	 * @method HTTP method to use (default: GET)
	 * @headers Comma-separated list of headers (e.g., "Content-Type:application/json,Authorization:Bearer token")
	 * @data Request body data for POST/PUT requests
	 * @timeout Request timeout in seconds (default: 30)
	 * @config Path to JSON config file with benchmark scenarios
	 * @output Output format: text, json, csv (default: text)
	 * @save Save results to file
	 **/
	function run(
		string url = "",
		numeric requests = 100,
		numeric concurrent = 1,
		string method = "GET",
		string headers = "",
		string data = "",
		numeric timeout = 30,
		string config = "",
		string output = "text",
		string save = ""
	) {
		// Check if using config file
		if (len(arguments.config)) {
			if (!fileExists(fileSystemUtil.resolvePath(arguments.config))) {
				error("Config file not found: " & arguments.config);
			}
			runFromConfig(arguments.config, arguments.output, arguments.save);
			return;
		}

		// Validate URL is provided
		if (!len(arguments.url)) {
			error("URL is required. Use 'wheels benchmark /path' or 'wheels benchmark --config=file.json'");
		}

		// Get server info if URL is relative
		local.serverInfo = getServerInfo();
		local.fullUrl = normalizeUrl(arguments.url, local.serverInfo);

		// Parse headers
		local.headerStruct = parseHeaders(arguments.headers);

		// Show benchmark plan
		print.boldLine("Benchmark Configuration:");
		print.line("URL: " & local.fullUrl);
		print.line("Method: " & arguments.method);
		print.line("Requests: " & arguments.requests);
		print.line("Concurrent: " & arguments.concurrent);
		print.line("Timeout: " & arguments.timeout & "s");
		
		if (structCount(local.headerStruct)) {
			print.line("Headers: " & serializeJSON(local.headerStruct));
		}
		
		if (len(arguments.data)) {
			print.line("Data: " & left(arguments.data, 100) & (len(arguments.data) > 100 ? "..." : ""));
		}
		
		print.line();

		// Warm up request
		print.line("Warming up...");
		makeRequest(
			url = local.fullUrl,
			method = arguments.method,
			headers = local.headerStruct,
			data = arguments.data,
			timeout = arguments.timeout
		);

		// Run benchmark
		print.line("Running benchmark...");
		local.results = runBenchmark(
			url = local.fullUrl,
			method = arguments.method,
			headers = local.headerStruct,
			data = arguments.data,
			timeout = arguments.timeout,
			requests = arguments.requests,
			concurrent = arguments.concurrent
		);

		// Display results
		displayResults(local.results, arguments.output);

		// Save results if requested
		if (len(arguments.save)) {
			saveResults(local.results, arguments.save, arguments.output);
			print.line().greenLine("Results saved to: " & arguments.save);
		}
	}

	/**
	 * Run benchmark from config file
	 */
	private void function runFromConfig(required string configPath, required string output, required string save) {
		local.config = deserializeJSON(fileRead(fileSystemUtil.resolvePath(arguments.configPath)));
		local.serverInfo = getServerInfo();
		local.allResults = [];

		print.boldLine("Running benchmark scenarios from config file...");
		print.line();

		for (local.scenario in local.config.scenarios) {
			print.boldLine("Scenario: " & local.scenario.name);
			
			local.fullUrl = normalizeUrl(local.scenario.url, local.serverInfo);
			local.headerStruct = structKeyExists(local.scenario, "headers") ? local.scenario.headers : {};
			
			local.results = runBenchmark(
				url = local.fullUrl,
				method = structKeyExists(local.scenario, "method") ? local.scenario.method : "GET",
				headers = local.headerStruct,
				data = structKeyExists(local.scenario, "data") ? local.scenario.data : "",
				timeout = structKeyExists(local.scenario, "timeout") ? local.scenario.timeout : 30,
				requests = structKeyExists(local.scenario, "requests") ? local.scenario.requests : 100,
				concurrent = structKeyExists(local.scenario, "concurrent") ? local.scenario.concurrent : 1
			);
			
			local.results.scenario = local.scenario.name;
			arrayAppend(local.allResults, local.results);
			
			displayResults(local.results, "text");
			print.line();
		}

		// Save all results
		if (len(arguments.save)) {
			saveResults(local.allResults, arguments.save, arguments.output);
			print.greenLine("All results saved to: " & arguments.save);
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
	 * Normalize URL (convert relative to absolute)
	 */
	private string function normalizeUrl(required string url, required struct serverInfo) {
		if (left(arguments.url, 4) == "http") {
			return arguments.url;
		}
		
		// Ensure URL starts with /
		local.path = left(arguments.url, 1) == "/" ? arguments.url : "/" & arguments.url;
		
		return arguments.serverInfo.url & local.path;
	}

	/**
	 * Parse header string into struct
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
	 * Make a single HTTP request
	 */
	private struct function makeRequest(
		required string url,
		required string method,
		required struct headers,
		required string data,
		required numeric timeout
	) {
		local.startTime = getTickCount();
		
		try {
			cfhttp(
				url = arguments.url,
				method = arguments.method,
				timeout = arguments.timeout,
				result = "local.result"
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
			
			return {
				success: local.result.statusCode < 400,
				statusCode: local.result.statusCode,
				time: local.endTime - local.startTime,
				size: len(local.result.fileContent)
			};
			
		} catch (any e) {
			return {
				success: false,
				statusCode: 0,
				time: getTickCount() - local.startTime,
				size: 0,
				error: e.message
			};
		}
	}

	/**
	 * Run the benchmark
	 */
	private struct function runBenchmark(
		required string url,
		required string method,
		required struct headers,
		required string data,
		required numeric timeout,
		required numeric requests,
		required numeric concurrent
	) {
		local.results = {
			url: arguments.url,
			method: arguments.method,
			totalRequests: arguments.requests,
			concurrent: arguments.concurrent,
			successful: 0,
			failed: 0,
			times: [],
			sizes: [],
			statusCodes: {},
			errors: [],
			startTime: now(),
			endTime: ""
		};

		local.batches = ceiling(arguments.requests / arguments.concurrent);
		local.progress = 0;

		for (local.batch = 1; local.batch <= local.batches; local.batch++) {
			local.batchSize = min(arguments.concurrent, arguments.requests - local.progress);
			local.threads = [];
			
			// Create threads for concurrent requests
			for (local.i = 1; local.i <= local.batchSize; local.i++) {
				local.threadName = "benchmark_#local.batch#_#local.i#";
				
				thread name="#local.threadName#" action="run" {
					thread.result = makeRequest(
						url = attributes.url,
						method = attributes.method,
						headers = attributes.headers,
						data = attributes.data,
						timeout = attributes.timeout
					);
				}
				
				arrayAppend(local.threads, local.threadName);
			}
			
			// Wait for threads to complete
			thread action="join" name="#arrayToList(local.threads)#";
			
			// Collect results
			for (local.threadName in local.threads) {
				local.threadResult = evaluate("cfthread.#local.threadName#.result");
				
				if (local.threadResult.success) {
					local.results.successful++;
				} else {
					local.results.failed++;
					if (structKeyExists(local.threadResult, "error")) {
						arrayAppend(local.results.errors, local.threadResult.error);
					}
				}
				
				arrayAppend(local.results.times, local.threadResult.time);
				arrayAppend(local.results.sizes, local.threadResult.size);
				
				// Track status codes
				local.statusKey = toString(local.threadResult.statusCode);
				if (!structKeyExists(local.results.statusCodes, local.statusKey)) {
					local.results.statusCodes[local.statusKey] = 0;
				}
				local.results.statusCodes[local.statusKey]++;
			}
			
			local.progress += local.batchSize;
			
			// Show progress
			local.percent = round((local.progress / arguments.requests) * 100);
			print.text("#chr(13)#Progress: #local.percent#% (#local.progress#/#arguments.requests#)").toConsole();
		}
		
		print.line(); // Clear progress line
		
		local.results.endTime = now();
		local.results.totalTime = dateDiff("s", local.results.startTime, local.results.endTime) * 1000 + 
								  dateDiff("l", local.results.startTime, local.results.endTime);
		
		// Calculate statistics
		local.results.stats = calculateStats(local.results.times);
		local.results.throughput = local.results.totalRequests / (local.results.totalTime / 1000);
		local.results.successRate = (local.results.successful / local.results.totalRequests) * 100;
		
		if (arrayLen(local.results.sizes)) {
			local.results.totalBytes = arraySum(local.results.sizes);
			local.results.avgSize = round(local.results.totalBytes / arrayLen(local.results.sizes));
		} else {
			local.results.totalBytes = 0;
			local.results.avgSize = 0;
		}
		
		return local.results;
	}

	/**
	 * Calculate statistics from time array
	 */
	private struct function calculateStats(required array times) {
		if (arrayLen(arguments.times) == 0) {
			return {
				min: 0,
				max: 0,
				mean: 0,
				median: 0,
				p95: 0,
				p99: 0
			};
		}
		
		// Sort times
		local.sortedTimes = duplicate(arguments.times);
		arraySort(local.sortedTimes, "numeric");
		
		return {
			min: local.sortedTimes[1],
			max: local.sortedTimes[arrayLen(local.sortedTimes)],
			mean: round(arrayAvg(local.sortedTimes)),
			median: getPercentile(local.sortedTimes, 50),
			p95: getPercentile(local.sortedTimes, 95),
			p99: getPercentile(local.sortedTimes, 99)
		};
	}

	/**
	 * Get percentile from sorted array
	 */
	private numeric function getPercentile(required array sortedArray, required numeric percentile) {
		local.index = ceiling((arguments.percentile / 100) * arrayLen(arguments.sortedArray));
		return arguments.sortedArray[min(local.index, arrayLen(arguments.sortedArray))];
	}

	/**
	 * Display benchmark results
	 */
	private void function displayResults(required struct results, required string format) {
		if (arguments.format == "json") {
			print.line(serializeJSON(arguments.results));
			return;
		}
		
		if (arguments.format == "csv") {
			displayCSVResults(arguments.results);
			return;
		}
		
		// Default text format
		print.line();
		print.boldLine("Benchmark Results:");
		print.line("─".repeatString(50));
		
		print.line("Total Requests: " & arguments.results.totalRequests);
		print.line("Concurrent: " & arguments.results.concurrent);
		print.line("Total Time: " & numberFormat(arguments.results.totalTime / 1000, "0.00") & "s");
		print.line();
		
		print.greenLine("Successful: " & arguments.results.successful & " (" & numberFormat(arguments.results.successRate, "0.0") & "%)");
		if (arguments.results.failed > 0) {
			print.redLine("Failed: " & arguments.results.failed);
		}
		print.line();
		
		print.boldLine("Response Times (ms):");
		print.line("  Min: " & arguments.results.stats.min);
		print.line("  Max: " & arguments.results.stats.max);
		print.line("  Mean: " & arguments.results.stats.mean);
		print.line("  Median: " & arguments.results.stats.median);
		print.line("  95th percentile: " & arguments.results.stats.p95);
		print.line("  99th percentile: " & arguments.results.stats.p99);
		print.line();
		
		print.boldLine("Throughput:");
		print.line("  Requests/sec: " & numberFormat(arguments.results.throughput, "0.00"));
		print.line("  Data transferred: " & formatBytes(arguments.results.totalBytes));
		print.line("  Avg response size: " & formatBytes(arguments.results.avgSize));
		print.line();
		
		if (structCount(arguments.results.statusCodes)) {
			print.boldLine("Status Codes:");
			for (local.code in structSort(arguments.results.statusCodes, "textnocase")) {
				print.line("  " & local.code & ": " & arguments.results.statusCodes[local.code]);
			}
		}
		
		if (arrayLen(arguments.results.errors)) {
			print.line();
			print.redBoldLine("Errors:");
			local.uniqueErrors = {};
			for (local.error in arguments.results.errors) {
				local.uniqueErrors[local.error] = true;
			}
			for (local.error in local.uniqueErrors) {
				print.redLine("  • " & local.error);
			}
		}
	}

	/**
	 * Display results in CSV format
	 */
	private void function displayCSVResults(required struct results) {
		// Header
		print.line("url,method,requests,concurrent,successful,failed,min_ms,max_ms,mean_ms,median_ms,p95_ms,p99_ms,throughput,total_bytes");
		
		// Data
		print.line(
			'"#arguments.results.url#",' &
			'"#arguments.results.method#",' &
			'#arguments.results.totalRequests#,' &
			'#arguments.results.concurrent#,' &
			'#arguments.results.successful#,' &
			'#arguments.results.failed#,' &
			'#arguments.results.stats.min#,' &
			'#arguments.results.stats.max#,' &
			'#arguments.results.stats.mean#,' &
			'#arguments.results.stats.median#,' &
			'#arguments.results.stats.p95#,' &
			'#arguments.results.stats.p99#,' &
			'#numberFormat(arguments.results.throughput, "0.00")#,' &
			'#arguments.results.totalBytes#'
		);
	}

	/**
	 * Save results to file
	 */
	private void function saveResults(required any results, required string filename, required string format) {
		local.content = "";
		
		if (arguments.format == "json") {
			local.content = serializeJSON(arguments.results);
		} else if (arguments.format == "csv") {
			// For CSV, capture the output
			savecontent variable="local.content" {
				displayCSVResults(arguments.results);
			}
		} else {
			// For text, capture the formatted output
			savecontent variable="local.content" {
				displayResults(arguments.results, "text");
			}
		}
		
		fileWrite(fileSystemUtil.resolvePath(arguments.filename), local.content);
	}

	/**
	 * Format bytes into human-readable format
	 */
	private string function formatBytes(required numeric bytes) {
		if (arguments.bytes < 1024) {
			return arguments.bytes & " B";
		} else if (arguments.bytes < 1048576) {
			return numberFormat(arguments.bytes / 1024, "0.0") & " KB";
		} else if (arguments.bytes < 1073741824) {
			return numberFormat(arguments.bytes / 1048576, "0.0") & " MB";
		} else {
			return numberFormat(arguments.bytes / 1073741824, "0.0") & " GB";
		}
	}

}