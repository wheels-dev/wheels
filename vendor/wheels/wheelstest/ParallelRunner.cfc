/**
 * Parallel Test Runner for Wheels
 *
 * Partitions test bundles and runs them concurrently via multiple HTTP requests,
 * then aggregates the results. Uses cfthread for parallelism and the existing
 * TestBox JSON reporter endpoint for each partition.
 *
 * Usage:
 *   var runner = new wheels.wheelstest.ParallelRunner(baseUrl="http://localhost:8080", workers=4);
 *   var results = runner.run(type="core", db="sqlite");
 */
component {

	variables.baseUrl = "";
	variables.workers = 4;
	variables.timeoutMs = 600000;

	/**
	 * Initialize the parallel runner.
	 *
	 * @baseUrl  Base URL of the running Wheels application (e.g. "http://localhost:8080")
	 * @workers  Number of parallel workers (threads) to use
	 */
	public ParallelRunner function init(string baseUrl = "http://localhost:8080", numeric workers = 4) {
		variables.baseUrl = arguments.baseUrl;
		variables.workers = arguments.workers;
		return this;
	}

	/**
	 * Main entry point. Discovers bundles, partitions them, executes in parallel, and aggregates results.
	 *
	 * @type      "core" or "app" — determines which test suite to run
	 * @directory Optional subdirectory filter (dotted path, e.g. "wheels.tests.specs.model")
	 * @db        Database to test against (default "sqlite")
	 * @workers   Override the default worker count for this run
	 */
	public struct function run(
		required string type,
		string directory = "",
		string db = "sqlite",
		numeric workers = variables.workers
	) {
		var startTick = getTickCount();

		// Determine base spec directory
		var baseDir = "";
		if (len(arguments.directory)) {
			baseDir = arguments.directory;
		} else if (arguments.type == "core") {
			baseDir = "wheels.tests.specs";
		} else {
			baseDir = "tests.specs";
		}

		// Discover all bundle paths
		var bundles = discoverBundles(baseDirectory = baseDir);
		if (arrayLen(bundles) == 0) {
			return {
				totalPass = 0, totalFail = 0, totalError = 0, totalSkipped = 0,
				totalDuration = 0, bundleStats = [], failures = [],
				workers = arguments.workers, partitions = 0,
				wallTime = getTickCount() - startTick,
				message = "No test bundles found in #baseDir#"
			};
		}

		// Partition bundles across workers
		var effectiveWorkers = min(arguments.workers, arrayLen(bundles));
		var partitions = partitionBundles(bundles = bundles, partitionCount = effectiveWorkers);

		// Execute partitions in parallel
		var partitionResults = executePartitions(
			partitions = partitions,
			type = arguments.type,
			db = arguments.db
		);

		// Aggregate results
		var aggregated = aggregateResults(partitionResults = partitionResults);
		aggregated.workers = effectiveWorkers;
		aggregated.partitions = arrayLen(partitions);
		aggregated.wallTime = getTickCount() - startTick;
		aggregated.totalBundles = arrayLen(bundles);

		return aggregated;
	}

	/**
	 * Discover test bundle paths by scanning the filesystem for *Spec.cfc files.
	 *
	 * @baseDirectory  Dotted path to the base directory (e.g. "wheels.tests.specs")
	 * @return         Array of dotted bundle paths (e.g. ["wheels.tests.specs.model.CreateSpec", ...])
	 */
	public array function discoverBundles(required string baseDirectory) {
		var results = [];
		var fsPath = expandPath("/" & replace(arguments.baseDirectory, ".", "/", "all"));

		if (!directoryExists(fsPath)) {
			return results;
		}

		var files = directoryList(fsPath, true, "path", "*.cfc", "name asc", "file");

		var baseFsPath = replace(fsPath, "\", "/", "all");
		if (right(baseFsPath, 1) == "/") {
			baseFsPath = left(baseFsPath, len(baseFsPath) - 1);
		}

		for (var filePath in files) {
			var fileName = listLast(replace(filePath, "\", "/", "all"), "/");
			if (reFindNoCase("(Spec|Test)\.cfc$", fileName)) {
				// Convert filesystem path to dotted bundle path
				var normalized = replace(filePath, "\", "/", "all");
				normalized = reReplaceNoCase(normalized, "\.cfc$", "");
				normalized = replace(normalized, baseFsPath, "");
				var dottedRelative = replace(normalized, "/", ".", "all");
				if (left(dottedRelative, 1) == ".") {
					dottedRelative = right(dottedRelative, len(dottedRelative) - 1);
				}
				arrayAppend(results, arguments.baseDirectory & "." & dottedRelative);
			}
		}

		return results;
	}

	/**
	 * Partition an array of bundles into N groups using round-robin distribution.
	 *
	 * @bundles         Array of bundle paths
	 * @partitionCount  Number of partitions to create
	 * @return          Array of arrays, each containing a subset of bundle paths
	 */
	public array function partitionBundles(required array bundles, required numeric partitionCount) {
		var effectiveCount = min(arguments.partitionCount, arrayLen(arguments.bundles));
		if (effectiveCount <= 0) {
			return [];
		}

		var partitions = [];
		for (var i = 1; i <= effectiveCount; i++) {
			arrayAppend(partitions, []);
		}

		for (var i = 1; i <= arrayLen(arguments.bundles); i++) {
			var partitionIndex = ((i - 1) mod effectiveCount) + 1;
			arrayAppend(partitions[partitionIndex], arguments.bundles[i]);
		}

		return partitions;
	}

	/**
	 * Execute test partitions in parallel using cfthread.
	 * Each thread fires an HTTP request to the test runner with its assigned bundles.
	 *
	 * @partitions  Array of arrays, each containing bundle paths for one worker
	 * @type        "core" or "app"
	 * @db          Database name
	 * @return      Array of structs, each containing {success, data, error, duration, partition}
	 */
	public array function executePartitions(
		required array partitions,
		required string type,
		required string db
	) {
		var threadNames = [];
		var runId = replace(createUUID(), "-", "", "all");

		for (var i = 1; i <= arrayLen(arguments.partitions); i++) {
			var threadName = "parallelTest_#runId#_#i#";
			arrayAppend(threadNames, threadName);

			var bundleList = arrayToList(arguments.partitions[i]);

			thread
				name="#threadName#"
				action="run"
				baseUrl="#variables.baseUrl#"
				testType="#arguments.type#"
				testDb="#arguments.db#"
				bundleList="#bundleList#"
				partitionIndex="#i#"
			{
				var partitionStart = getTickCount();
				try {
					var testPath = (attributes.testType == "app") ? "/wheels/app/tests" : "/wheels/core/tests";
					var testUrl = attributes.baseUrl
						& testPath & "?db=" & attributes.testDb
						& "&format=json&cli=true"
						& "&testBundles=" & urlEncodedFormat(attributes.bundleList);

					cfhttp(
						url = testUrl,
						method = "GET",
						timeout = 600,
						result = "local.httpResult"
					);

					if (listFirst(local.httpResult.statusCode, " ") == "200" || listFirst(local.httpResult.statusCode, " ") == "417") {
						thread.success = true;
						thread.data = deserializeJSON(local.httpResult.fileContent);
						thread.error = "";
					} else {
						thread.success = false;
						thread.data = {};
						thread.error = "HTTP #local.httpResult.statusCode#: #left(local.httpResult.fileContent, 500)#";
					}
				} catch (any e) {
					thread.success = false;
					thread.data = {};
					thread.error = "Thread error: #e.message# #e.detail#";
				}
				thread.duration = getTickCount() - partitionStart;
				thread.partition = attributes.partitionIndex;
			}
		}

		// Join all threads — wait up to 10 minutes
		var nameList = arrayToList(threadNames);
		thread action="join" name="#nameList#" timeout="#variables.timeoutMs#";

		// Collect results
		var results = [];
		for (var tName in threadNames) {
			var t = cfthread[tName];
			arrayAppend(results, {
				success = structKeyExists(t, "success") ? t.success : false,
				data = structKeyExists(t, "data") ? t.data : {},
				error = structKeyExists(t, "error") ? t.error : "Thread did not complete",
				duration = structKeyExists(t, "duration") ? t.duration : 0,
				partition = structKeyExists(t, "partition") ? t.partition : 0,
				status = structKeyExists(t, "status") ? t.status : "UNKNOWN"
			});
		}

		return results;
	}

	/**
	 * Aggregate results from multiple partition runs into a single result struct.
	 *
	 * @partitionResults  Array of partition result structs from executePartitions()
	 * @return            Aggregated result struct
	 */
	public struct function aggregateResults(required array partitionResults) {
		var aggregated = {
			totalPass = 0,
			totalFail = 0,
			totalError = 0,
			totalSkipped = 0,
			totalDuration = 0,
			bundleStats = [],
			failures = [],
			partitionErrors = []
		};

		for (var pr in arguments.partitionResults) {
			if (pr.success && isStruct(pr.data) && !structIsEmpty(pr.data)) {
				var d = pr.data;
				aggregated.totalPass += val(structKeyExists(d, "totalPass") ? d.totalPass : 0);
				aggregated.totalFail += val(structKeyExists(d, "totalFail") ? d.totalFail : 0);
				aggregated.totalError += val(structKeyExists(d, "totalError") ? d.totalError : 0);
				aggregated.totalSkipped += val(structKeyExists(d, "totalSkipped") ? d.totalSkipped : 0);
				aggregated.totalDuration += val(structKeyExists(d, "totalDuration") ? d.totalDuration : 0);

				// Merge bundle stats
				if (structKeyExists(d, "bundleStats") && isArray(d.bundleStats)) {
					for (var bs in d.bundleStats) {
						arrayAppend(aggregated.bundleStats, bs);

						// Collect failures from bundle suiteStats
						if (structKeyExists(bs, "suiteStats") && isArray(bs.suiteStats)) {
							$collectFailures(
								suiteStats = bs.suiteStats,
								bundleName = structKeyExists(bs, "name") ? bs.name : "unknown",
								aggregated = aggregated
							);
						}
					}
				}
			} else {
				// Partition-level error
				arrayAppend(aggregated.partitionErrors, {
					partition = pr.partition,
					error = pr.error,
					duration = pr.duration
				});
				// Count partition errors as test errors so they surface in totals
				aggregated.totalError++;
			}
		}

		return aggregated;
	}

	/**
	 * Format aggregated results as a human-readable report or JSON.
	 *
	 * @results  Aggregated result struct from aggregateResults()
	 * @format   "text" for human-readable, "json" for JSON
	 * @return   Formatted report string
	 */
	public string function formatReport(required struct results, string format = "text") {
		if (arguments.format == "json") {
			return serializeJSON(arguments.results);
		}

		var r = arguments.results;
		var out = [];

		arrayAppend(out, "=== Parallel Test Results ===");
		arrayAppend(out, "Workers: #val(structKeyExists(r, 'workers') ? r.workers : 0)# | Partitions: #val(structKeyExists(r, 'partitions') ? r.partitions : 0)#");
		arrayAppend(out, "Wall time: #val(structKeyExists(r, 'wallTime') ? r.wallTime : 0)#ms | Sum of partition durations: #r.totalDuration#ms");
		arrayAppend(out, "");

		var total = r.totalPass + r.totalFail + r.totalError + r.totalSkipped;
		arrayAppend(out, "Total: #total# | Passed: #r.totalPass# | Failed: #r.totalFail# | Errors: #r.totalError# | Skipped: #r.totalSkipped#");

		if (r.totalFail > 0 || r.totalError > 0) {
			arrayAppend(out, "");
			arrayAppend(out, "--- Failures ---");
			for (var f in r.failures) {
				arrayAppend(out, "  [#f.status#] #f.bundle# > #f.spec#");
				if (len(f.message)) {
					arrayAppend(out, "    #left(f.message, 200)#");
				}
			}
		}

		if (structKeyExists(r, "partitionErrors") && arrayLen(r.partitionErrors) > 0) {
			arrayAppend(out, "");
			arrayAppend(out, "--- Partition Errors ---");
			for (var pe in r.partitionErrors) {
				arrayAppend(out, "  Partition #pe.partition#: #pe.error#");
			}
		}

		arrayAppend(out, "");
		if (r.totalFail == 0 && r.totalError == 0 && (!structKeyExists(r, "partitionErrors") || arrayLen(r.partitionErrors) == 0)) {
			arrayAppend(out, "RESULT: PASSED");
		} else {
			arrayAppend(out, "RESULT: FAILED");
		}

		return arrayToList(out, chr(10));
	}

	/**
	 * Recursively collect failure/error specs from suiteStats. Takes the
	 * `aggregated` parent struct rather than the inner `failures` array
	 * directly: Adobe CF copies arrays by value out of struct literals
	 * (Cross-Engine Invariant #6), so mutating `failures` via a separate
	 * argument writes to a copy that never propagates back to the caller.
	 */
	private void function $collectFailures(
		required array suiteStats,
		required string bundleName,
		required struct aggregated
	) {
		for (var suite in arguments.suiteStats) {
			if (structKeyExists(suite, "specStats") && isArray(suite.specStats)) {
				for (var spec in suite.specStats) {
					var status = structKeyExists(spec, "status") ? spec.status : "";
					if (status == "Failed" || status == "Error") {
						arrayAppend(arguments.aggregated.failures, {
							bundle = arguments.bundleName,
							spec = structKeyExists(spec, "name") ? spec.name : "unknown",
							status = status,
							message = structKeyExists(spec, "failMessage") ? spec.failMessage : ""
						});
					}
				}
			}
			// Recurse into nested suites
			if (structKeyExists(suite, "suiteStats") && isArray(suite.suiteStats)) {
				$collectFailures(
					suiteStats = suite.suiteStats,
					bundleName = arguments.bundleName,
					aggregated = arguments.aggregated
				);
			}
		}
	}

}
