component extends="Controller" {

	/**
	 * Initialize the controller
	 */
	public void function config() {
		// This controller provides JSON responses for test running
		provides("json");
	}

	/**
	 * Run tests and return results
	 */
	public void function index() {
		// Set long timeout for test execution
		setting requesttimeout="300";
		
		// Get test parameters
		param name="params.type" default="app";
		param name="params.format" default="json";
		param name="params.reporter" default="json";
		param name="params.filter" default="";
		param name="params.group" default="";
		param name="params.coverage" default="false";
		param name="params.failFast" default="false";
		param name="params.watch" default="false";
		
		local.result = {
			success = false,
			message = "",
			tests = {},
			coverage = {}
		};
		
		try {
			// Determine test directory based on type
			local.testDirectory = "";
			switch(params.type) {
				case "core":
					local.testDirectory = expandPath("/wheels/tests");
					break;
				case "app":
				default:
					local.testDirectory = expandPath("/tests");
					break;
			}
			
			// Check if test directory exists
			if (!directoryExists(local.testDirectory)) {
				local.result.message = "Test directory not found: #local.testDirectory#";
				renderWith(local.result);
				return;
			}
			
			// Check if WheelsTest is available
			if (!structKeyExists(application, "testbox") && !fileExists(expandPath("/wheels/wheelstest/system/TestBox.cfc"))) {
				local.result.message = "WheelsTest is not installed. Please ensure the wheels test framework is available.";
				renderWith(local.result);
				return;
			}
			
			// Build WheelsTest options
			local.testboxOptions = {
				directory = local.testDirectory,
				recurse = true,
				reporter = params.reporter,
				labels = params.group,
				testBundles = params.filter,
				coverageEnabled = params.coverage,
				coveragePathToCapture = expandPath("/app"),
				coverageWhitelist = "",
				coverageBlacklist = "tests,wheelstest,vendor,wheels"
			};
			
			// Run tests using WheelsTest
			if (fileExists(expandPath("/wheels/wheelstest/system/TestBox.cfc"))) {
				local.testbox = new wheels.wheelstest.system.TestBox();
				local.testResults = local.testbox.run(argumentCollection=local.testboxOptions);
				
				// Format results
				local.result.success = true;
				local.result.tests = {
					totalSpecs = local.testResults.getTotalSpecs(),
					totalPass = local.testResults.getTotalPass(),
					totalFail = local.testResults.getTotalFail(),
					totalError = local.testResults.getTotalError(),
					totalSkipped = local.testResults.getTotalSkipped(),
					totalDuration = local.testResults.getTotalDuration(),
					bundles = []
				};
				
				// Add bundle details
				for (local.bundle in local.testResults.getBundleStats()) {
					arrayAppend(local.result.tests.bundles, {
						name = local.bundle.name,
						totalSpecs = local.bundle.totalSpecs,
						totalPass = local.bundle.totalPass,
						totalFail = local.bundle.totalFail,
						totalError = local.bundle.totalError,
						totalSkipped = local.bundle.totalSkipped
					});
				}
				
				// Add coverage if enabled
				if (params.coverage && structKeyExists(local.testResults, "getCoverageData")) {
					local.result.coverage = local.testResults.getCoverageData();
				}
				
				local.result.message = "Tests completed successfully";
			} else {
				// Fallback for when WheelsTest isn't properly installed
				local.result.message = "WheelsTest installation not found. Please ensure the wheels test framework is properly installed.";
			}
			
		} catch (any e) {
			local.result.success = false;
			local.result.message = "Error running tests: #e.message# #e.detail#";
		}
		
		// Return JSON response
		renderWith(local.result);
	}
	
	/**
	 * Run a single test bundle
	 */
	public void function run() {
		// Redirect to index with parameters
		params.type = "single";
		index();
	}
	
	/**
	 * Get test coverage report
	 */
	public void function coverage() {
		local.result = {
			success = false,
			message = "Coverage reporting not yet implemented",
			coverage = {}
		};
		
		renderWith(local.result);
	}

}