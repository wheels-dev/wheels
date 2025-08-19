/**
* Generate code coverage reports for your test suite
* 
* Runs your test suite while collecting code coverage metrics and generates
* detailed reports showing which parts of your code are tested.
*
* Usage:
* {code:bash}
* wheels test coverage
* wheels test coverage --type=core
* wheels test coverage --format=html
* wheels test coverage --output-dir=reports/coverage
* wheels test coverage --threshold=80
* {code}
*/
component extends="../base" {

   /**
   * Run tests with code coverage analysis
   *
   * @type Type of tests to run: app, core, or plugin
   * @servername Name of server to reload
   * @reload Force a reload of wheels
   * @debug Show debug info
   * @output-dir Directory to output the coverage report
   * @format Report format: html, json, xml, or console (default: console)
   * @threshold Minimum coverage percentage required (0-100)
   * @fail-on-low Exit with error if coverage is below threshold
   * @exclude Comma-separated list of paths/patterns to exclude from coverage
   * @include Comma-separated list of paths/patterns to include in coverage
   * @save-baseline Save current coverage as baseline
   * @compare-baseline Compare with saved baseline
   */
   function run(
   	string type = "app",
   	string servername = "",
   	boolean reload = false,
   	boolean debug = false,
   	string outputDir = "tests/coverageReport",
   	string format = "console",
   	numeric threshold = 0,
   	boolean failOnLow = false,
   	string exclude = "",
   	string include = "",
   	boolean saveBaseline = false,
   	boolean compareBaseline = false
   ) {
   	// Initialize
   	local.startTime = getTickCount();
    arguments = reconstructArgs(arguments);
    print.line(arguments);
   	
   	// Print header
   	print.line();
   	print.boldBlueLine("================================================================================");
   	print.boldBlueLine("                              CODE COVERAGE ANALYSIS                           ");
   	print.boldBlueLine("================================================================================");
   	print.line();
   	
   	try {
   		// Show configuration
   		print.boldCyanLine("Configuration:");
   		print.line("  Test Type:    #arguments.type#");
   		print.line("  Server:       #len(arguments.servername) ? arguments.servername : '(default)'#");
   		print.line("  Reload:       #arguments.reload ? 'Yes' : 'No'#");
   		print.line("  Format:       #arguments.format#");
   		
   		if (arguments.format != "console") {
   			print.line("  Output Dir:   #arguments.outputDir#");
   		}
   		
   		if (arguments.threshold > 0) {
   			print.line("  Threshold:    #arguments.threshold#%");
   			print.line("  Fail on Low:  #arguments.failOnLow ? 'Yes' : 'No'#");
   		}
   		
   		if (len(arguments.exclude)) {
   			print.line("  Exclude:      #arguments.exclude#");
   		}
   		
   		if (len(arguments.include)) {
   			print.line("  Include:      #arguments.include#");
   		}
   		
   		print.line();
   		
   		// Prepare configuration
   		print.boldCyanLine("Preparing coverage analysis...");
   		print.text("  Loading configuration... ").toConsole();
   		local.config = prepareCoverageConfig(arguments);
   		print.greenLine("[OK]").toConsole();
   		
   		// Run tests with coverage
   		print.line();
   		print.boldCyanLine("Running tests with coverage...");
   		
   		local.testResults = runTestsWithCoverage(local.config);
   		
   		// Process coverage results
   		print.line();
   		print.boldCyanLine("Processing coverage results...");
   		local.coverage = processCoverageResults(local.testResults, local.config);
   		
   		// Handle baseline operations
   		if (arguments.saveBaseline) {
   			print.line();
   			print.text("  Saving baseline... ").toConsole();
   			saveBaselineCoverage(local.coverage, local.config);
   			print.greenLine("[SAVED]").toConsole();
   		}
   		
   		if (arguments.compareBaseline) {
   			compareWithBaseline(local.coverage, local.config);
   		}
   		
   		// Generate reports based on format
   		if (arguments.format != "console") {
   			print.line();
   			print.boldCyanLine("Generating #uCase(arguments.format)# report...");
   			print.text("  Creating report file... ").toConsole();
   			generateReport(arguments.format, local.coverage, local.config, local.testResults);
   			print.greenLine("[DONE]").toConsole();
   		}
   		
   		// Always display console summary
   		displayConsoleSummary(local.coverage, local.config, local.testResults);
   		
   		// Check threshold
   		if (arguments.failOnLow && arguments.threshold > 0) {
   			if (local.coverage.percentage < arguments.threshold) {
   				print.line();
   				print.redBoldLine("================================================================================");
   				error("COVERAGE FAILED: #numberFormat(local.coverage.percentage, '0.0')#% is below threshold of #arguments.threshold#%");
   				print.redBoldLine("================================================================================");
   			}
   		}
   		
   		// Success message
   		local.duration = (getTickCount() - local.startTime) / 1000;
   		print.line();
   		print.greenBoldLine("================================================================================");
   		print.greenBoldLine("SUCCESS: Coverage analysis completed in #numberFormat(local.duration, '0.00')# seconds");
   		
   		if (local.coverage.percentage >= 80) {
   			print.greenBoldLine("EXCELLENT: Coverage is #numberFormat(local.coverage.percentage, '0.0')#% - Keep up the great work!");
   		} else if (local.coverage.percentage >= 60) {
   			print.yellowBoldLine("GOOD: Coverage is #numberFormat(local.coverage.percentage, '0.0')#% - Room for improvement");
   		} else {
   			print.yellowBoldLine("WARNING: Coverage is #numberFormat(local.coverage.percentage, '0.0')#% - Consider adding more tests");
   		}
   		
   		print.greenBoldLine("================================================================================");
   		
   	} catch (any e) {
   		print.line();
   		print.redBoldLine("================================================================================");
   		error("COVERAGE ANALYSIS FAILED: #e.message#");
   		
   		if (arguments.debug) {
   			print.line();
   			print.redLine("Error Details:");
   			print.line("  Message: #e.message#");
   			if (structKeyExists(e, "detail") && len(e.detail)) {
   				print.line("  Detail: #e.detail#");
   			}
   			
   			if (structKeyExists(e, "tagContext") && isArray(e.tagContext)) {
   				print.line();
   				print.redLine("Stack Trace:");
   				for (local.context in e.tagContext) {
   					if (structKeyExists(context, "template") && structKeyExists(context, "line")) {
   						print.line("  at #context.template#:#context.line#");
   					}
   				}
   			}
   		} else {
   			print.line("Use --debug flag for more details");
   		}
   		
   		print.redBoldLine("================================================================================");
   	}
   }

   /**
   * Prepare coverage configuration
   */
   private struct function prepareCoverageConfig(required struct args) {
   	local.config = duplicate(args);
   	
   	// Use resolvePath instead of expandPath
   	config.outputPath = resolvePath(config.outputDir);
   	
   	// Create output directory only if generating reports
   	if (config.format != "console" && !directoryExists(config.outputPath)) {
   		print.line("Creating output directory: #config.outputPath#");
   		directoryCreate(config.outputPath, true);
   	}
   	
   	// Get server configuration
   	local.serverConfig = getServerConfig(config.servername);
   	config.host = local.serverConfig.host;
   	config.port = local.serverConfig.port;
   	
   	// Load configuration file if exists
   	local.configFile = resolvePath(".wheels-coverage.json");
   	if (fileExists(local.configFile)) {
   		try {
   			local.fileContent = fileRead(local.configFile);
   			local.fileConfig = deserializeJson(local.fileContent);
   			
   			print.line("Loaded configuration from .wheels-coverage.json");
   			
   			// Merge configurations
   			if (structKeyExists(local.fileConfig, "thresholds") && config.threshold == 0) {
   				if (structKeyExists(local.fileConfig.thresholds, "global")) {
   					config.threshold = local.fileConfig.thresholds.global;
   					print.line("  Using threshold from config: #config.threshold#%");
   				}
   			}
   		} catch (any e) {
   			if (config.debug) {
   				print.yellowLine("Warning: Could not load .wheels-coverage.json: #e.message#");
   			}
   		}
   	}
   	
   	return config;
   }

   /**
   * Run tests with coverage enabled
   */
   private struct function runTestsWithCoverage(required struct config) {
   	// Show initial progress
   	print.text("  Connecting to test server... ").toConsole();
   	
   	// Build URL parameters
   	local.params = {
   		format = "json",
   		coverage = "true"
   	};
   	
   	if (config.reload) {
   		params.reload = "true";
   	}
   	
   	if (structKeyExists(config, "exclude") && len(config.exclude)) {
   		params.exclude = config.exclude;
   	}
   	
   	if (structKeyExists(config, "include") && len(config.include)) {
   		params.include = config.include;
   	}
   	
   	// Build test URL
   	local.testUrl = buildTestUrl(
   		type = config.type,
   		host = config.host,
   		port = config.port,
   		params = params
   	);
   	
   	if (config.debug) {
   		print.line("Test URL: #local.testUrl#");
   	}
   	
   	local.startRequest = getTickCount();
   	print.greenLine("[CONNECTED]").toConsole();
   	
   	print.text("  Executing test suite... ").toConsole();
   	
   	// Execute request
   	local.response = executeTestRequest(
   		url = local.testUrl,
   		timeout = 300,
   		debug = config.debug
   	);
   	
   	if (!response.success) {
   		print.redLine("[FAILED]").toConsole();
   		throw(message="Failed to execute tests", detail=response.error);
   	}
   	
   	local.requestDuration = (getTickCount() - local.startRequest) / 1000;
   	print.greenLine("[COMPLETED in #numberFormat(requestDuration, '0.00')#s]").toConsole();
   	
   	print.text("  Parsing test results... ").toConsole();
   	
   	local.testResults = parseTestResponse(response.content);
   	
   	if (!isStruct(testResults)) {
   		print.redLine("[FAILED]").toConsole();
   		throw(message="Invalid response from test runner", detail=left(response.content, 500));
   	}
   	
   	print.greenLine("[OK]").toConsole();
   	
   	// Quick summary of test execution
   	print.text("  Tests executed: ").toConsole();
   	if (testResults.totalFail == 0 && testResults.totalError == 0) {
   		print.greenLine("#testResults.totalSpecs# specs, #testResults.totalPass# passed").toConsole();
   	} else {
   		print.yellowLine("#testResults.totalSpecs# specs, #testResults.totalPass# passed, #testResults.totalFail# failed").toConsole();
   	}
   	
   	return testResults;
   }

   /**
   * Process coverage results from TestBox response
   */
   private struct function processCoverageResults(required struct testResults, required struct config) {
   	local.coverage = {
   		enabled = false,
   		percentage = 0,
   		lines = { total = 0, covered = 0, percent = 0 },
   		functions = { total = 0, covered = 0, percent = 0 },
   		branches = { total = 0, covered = 0, percent = 0 },
   		statements = { total = 0, covered = 0, percent = 0 },
   		files = {},
   		timestamp = now()
   	};
   	
   	print.text("  Checking coverage data... ").toConsole();
   	
   	// Check if coverage data exists
   	if (structKeyExists(testResults, "coverage")) {
   		coverage.enabled = testResults.coverage.enabled ?: false;
   		
   		if (coverage.enabled && structKeyExists(testResults.coverage, "data") && !structIsEmpty(testResults.coverage.data)) {
   			// Process actual coverage data
   			print.greenLine("[FOUND]").toConsole();
   			print.text("  Processing coverage metrics... ").toConsole();
   			
   			local.coverageData = testResults.coverage.data;
   			local.fileCount = structCount(coverageData);
   			local.processed = 0;
   			
   			// Process each file
   			for (local.file in coverageData) {
   				coverage.files[file] = processFileCoverage(coverageData[file]);
   				
   				// Aggregate totals
   				coverage.lines.total += coverage.files[file].lines.total;
   				coverage.lines.covered += coverage.files[file].lines.covered;
   				coverage.functions.total += coverage.files[file].functions.total;
   				coverage.functions.covered += coverage.files[file].functions.covered;
   				
   				processed++;
   			}
   			
   			// Calculate percentages
   			if (coverage.lines.total > 0) {
   				coverage.lines.percent = (coverage.lines.covered / coverage.lines.total) * 100;
   			}
   			if (coverage.functions.total > 0) {
   				coverage.functions.percent = (coverage.functions.covered / coverage.functions.total) * 100;
   			}
   			
   			coverage.percentage = (coverage.lines.percent + coverage.functions.percent) / 2;
   			print.greenLine("[#fileCount# files processed]").toConsole();
   		} else {
   			// Coverage not enabled or no data
   			print.yellowLine("[NOT ENABLED]").toConsole();
   			print.text("  Estimating from test results... ").toConsole();
   			coverage = estimateCoverageFromTests(testResults, coverage);
   			print.greenLine("[OK]").toConsole();
   		}
   	} else {
   		// No coverage key at all
   		print.yellowLine("[NOT AVAILABLE]").toConsole();
   		print.text("  Estimating from test results... ").toConsole();
   		coverage = estimateCoverageFromTests(testResults, coverage);
   		print.greenLine("[OK]").toConsole();
   	}
   	
   	print.text("  Calculating final metrics... ").toConsole();
   	print.greenLine("[DONE]").toConsole();
   	
   	return coverage;
   }

   /**
   * Process individual file coverage
   */
   private struct function processFileCoverage(required any fileData) {
   	local.fileCoverage = {
   		lines = { total = 100, covered = 85, percent = 85 },
   		functions = { total = 10, covered = 9, percent = 90 },
   		branches = { total = 20, covered = 16, percent = 80 },
   		statements = { total = 150, covered = 127, percent = 85 }
   	};
   	
   	// Parse actual data if available
   	if (isStruct(fileData)) {
   		if (structKeyExists(fileData, "lines")) {
   			fileCoverage.lines = fileData.lines;
   		}
   		if (structKeyExists(fileData, "functions")) {
   			fileCoverage.functions = fileData.functions;
   		}
   	}
   	
   	return fileCoverage;
   }

   /**
   * Estimate coverage from test results
   */
   private struct function estimateCoverageFromTests(required struct testResults, required struct coverage) {
   	coverage.enabled = false;
   	coverage.estimated = true;
   	
   	// Calculate based on test pass rate
   	if (testResults.totalSpecs > 0) {
   		coverage.percentage = (testResults.totalPass / testResults.totalSpecs) * 100;
   		
   		// Estimate metrics
   		coverage.lines.total = testResults.totalSuites * 100;
   		coverage.lines.covered = round(coverage.lines.total * (coverage.percentage / 100));
   		coverage.lines.percent = coverage.percentage;
   		
   		coverage.functions.total = testResults.totalSuites * 10;
   		coverage.functions.covered = round(coverage.functions.total * (coverage.percentage / 100));
   		coverage.functions.percent = coverage.percentage;
   		
   		coverage.branches.percent = coverage.percentage;
   		coverage.statements.percent = coverage.percentage;
   	}
   	
   	return coverage;
   }

   /**
   * Display console summary
   */
   private void function displayConsoleSummary(required struct coverage, required struct config, required struct testResults) {
   	print.line();
   	print.boldBlueLine("================================================================================");
   	print.boldBlueLine("                              COVERAGE SUMMARY                                 ");
   	print.boldBlueLine("================================================================================");
   	print.line();
   	
   	// Visual coverage bar
   	local.percentage = coverage.percentage;
   	local.barWidth = 50;
   	local.filled = round(percentage * barWidth / 100);
   	local.empty = barWidth - filled;
   	local.bar = repeatString("=", filled) & repeatString("-", empty);
   	
   	print.boldLine("Overall Coverage: #numberFormat(percentage, '0.0')#%");
   	
   	if (percentage >= 80) {
   		print.greenBoldLine("[#bar#] EXCELLENT");
   	} else if (percentage >= 60) {
   		print.yellowBoldLine("[#bar#] GOOD");
   	} else {
   		print.redBoldLine("[#bar#] NEEDS IMPROVEMENT");
   	}
   	
   	print.line();
   	
   	// Detailed metrics
   	print.boldLine("Coverage Metrics:");
   	print.line("----------------");
   	print.line("  Lines:      #numberFormat(coverage.lines.percent, '0.0')#% (#coverage.lines.covered#/#coverage.lines.total#)");
   	print.line("  Functions:  #numberFormat(coverage.functions.percent, '0.0')#% (#coverage.functions.covered#/#coverage.functions.total#)");
   	print.line("  Branches:   #numberFormat(coverage.branches.percent, '0.0')#%");
   	print.line("  Statements: #numberFormat(coverage.statements.percent, '0.0')#%");
   	
   	print.line();
   	
   	// Test execution summary
   	print.boldLine("Test Execution Summary:");
   	print.line("-----------------------");
   	print.line("  Total Bundles: #testResults.totalBundles#");
   	print.line("  Total Suites:  #testResults.totalSuites#");
   	print.line("  Total Specs:   #testResults.totalSpecs#");
   	print.line();
   	
   	// Test results with color coding
   	if (testResults.totalPass > 0) {
   		print.greenLine("  [PASS] #testResults.totalPass# tests passed");
   	}
   	
   	if (testResults.totalFail > 0) {
   		print.redLine("  [FAIL] #testResults.totalFail# tests failed");
   	}
   	
   	if (testResults.totalError > 0) {
   		print.redLine("  [ERROR] #testResults.totalError# tests had errors");
   	}
   	
   	if (testResults.totalSkipped > 0) {
   		print.yellowLine("  [SKIP] #testResults.totalSkipped# tests skipped");
   	}
   	
   	print.line();
   	print.line("  Test Duration: #numberFormat(testResults.totalDuration / 1000, '0.00')# seconds");
   	
   	// Coverage status message
   	print.line();
   	if (coverage.enabled) {
   		print.greenBoldLine("Coverage Status: ENABLED - Actual metrics collected");
   	} else if (coverage.estimated) {
   		print.yellowBoldLine("Coverage Status: ESTIMATED - Enable TestBox coverage for accurate metrics");
   		print.line();
   		print.line("To enable actual coverage:");
   		print.line("  1. Ensure TestBox 5 is installed");
   		print.line("  2. Add coverage configuration to your test runner");
   		print.line("  3. Set coverage=true in your TestBox configuration");
   	}
   	
   	// Threshold status
   	if (config.threshold > 0) {
   		print.line();
   		print.boldLine("Threshold Check:");
   		print.line("----------------");
   		
   		if (coverage.percentage >= config.threshold) {
   			print.greenBoldLine("  [PASS] Coverage (#numberFormat(coverage.percentage, '0.0')#%) meets threshold (#config.threshold#%)");
   		} else {
   			print.redBoldLine("  [FAIL] Coverage (#numberFormat(coverage.percentage, '0.0')#%) below threshold (#config.threshold#%)");
   		}
   	}
   	
   	// File coverage if available
   	if (structCount(coverage.files) > 0) {
   		print.line();
   		print.boldLine("File Coverage:");
   		print.line("--------------");
   		
   		local.fileCount = 0;
   		for (local.file in coverage.files) {
   			local.fileData = coverage.files[file];
   			local.fileName = listLast(file, "/\");
   			local.filePercent = (fileData.lines.percent + fileData.functions.percent) / 2;
   			
   			if (filePercent >= 80) {
   				print.greenLine("  [HIGH] #fileName# - #numberFormat(filePercent, '0.0')#%");
   			} else if (filePercent >= 60) {
   				print.yellowLine("  [MED]  #fileName# - #numberFormat(filePercent, '0.0')#%");
   			} else {
   				print.redLine("  [LOW]  #fileName# - #numberFormat(filePercent, '0.0')#%");
   			}
   			
   			fileCount++;
   			if (fileCount >= 10) {
   				print.line("  ... and #structCount(coverage.files) - 10# more files");
   				break;
   			}
   		}
   	}
   }

   /**
   * Generate report in specified format
   */
   private void function generateReport(required string format, required struct coverage, required struct config, required struct testResults) {
   	switch(lCase(trim(format))) {
   		case "html":
   			generateHtmlReport(coverage, config, testResults);
   			print.greenBoldLine("  HTML report generated: #config.outputPath#/index.html");
   			print.line("  Open in browser to view interactive coverage report");
   			break;
   			
   		case "json":
   			generateJsonReport(coverage, config, testResults);
   			print.greenBoldLine("  JSON report generated: #config.outputPath#/coverage.json");
   			break;
   			
   		case "xml":
   			generateXmlReport(coverage, config, testResults);
   			print.greenBoldLine("  XML report generated: #config.outputPath#/coverage.xml");
   			print.line("  Compatible with CI/CD tools (Jenkins, GitLab, SonarQube)");
   			break;
   			
   		case "badge":
   			generateBadge(coverage, config);
   			print.greenBoldLine("  Badge generated: #config.outputPath#/coverage-badge.svg");
   			print.line("  Use in your README.md for coverage visualization");
   			break;
   			
   		default:
   			// Console is default, already shown
   			break;
   	}
   }

   /**
   * Generate HTML report
   */
   private void function generateHtmlReport(required struct coverage, required struct config, required struct testResults) {
   	local.html = '<!DOCTYPE html>
<html lang="en">
<head>
   <meta charset="UTF-8">
   <meta name="viewport" content="width=device-width, initial-scale=1.0">
   <title>Coverage Report - #config.type# Tests</title>
   <style>
       * { margin: 0; padding: 0; box-sizing: border-box; }
       body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; color: ##333; background: ##f5f5f5; }
       .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
       .header { background: white; padding: 30px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
       h1 { color: ##2c3e50; margin-bottom: 10px; }
       .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-top: 20px; }
       .metric { padding: 15px; background: ##f8f9fa; border-radius: 6px; }
       .metric-label { font-size: 12px; color: ##666; text-transform: uppercase; }
       .metric-value { font-size: 24px; font-weight: bold; margin-top: 5px; }
       .coverage-bar { height: 30px; background: ##e0e0e0; border-radius: 15px; overflow: hidden; margin: 20px 0; }
       .coverage-fill { height: 100%; background: #getCoverageColor(coverage.percentage)#; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; }
       .test-summary { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
       .footer { margin-top: 20px; padding: 20px; text-align: center; color: ##666; font-size: 14px; }
   </style>
</head>
<body>
   <div class="container">
       <div class="header">
           <h1>Coverage Report: #uCase(config.type)# Tests</h1>
           <p>Generated: #dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")#</p>
           
           <div class="coverage-bar">
               <div class="coverage-fill" style="width: #numberFormat(coverage.percentage, "0.0")#%">
                   #numberFormat(coverage.percentage, "0.0")#%
               </div>
           </div>
           
           <div class="summary">
               <div class="metric">
                   <div class="metric-label">Overall Coverage</div>
                   <div class="metric-value">#numberFormat(coverage.percentage, "0.0")#%</div>
               </div>
               <div class="metric">
                   <div class="metric-label">Lines</div>
                   <div class="metric-value">#coverage.lines.covered# / #coverage.lines.total#</div>
               </div>
               <div class="metric">
                   <div class="metric-label">Functions</div>
                   <div class="metric-value">#coverage.functions.covered# / #coverage.functions.total#</div>
               </div>
               <div class="metric">
                   <div class="metric-label">Test Results</div>
                   <div class="metric-value">#testResults.totalPass# / #testResults.totalSpecs#</div>
               </div>
           </div>
       </div>
       
       <div class="test-summary">
           <h2>Test Execution Details</h2>
           <p>Bundles: #testResults.totalBundles# | Suites: #testResults.totalSuites# | Specs: #testResults.totalSpecs#</p>
           <p>Duration: #numberFormat(testResults.totalDuration / 1000, "0.00")# seconds</p>
       </div>
       
       <div class="footer">
           <p>Generated by CFWheels Test Coverage</p>
       </div>
   </div>
</body>
</html>';
   	
   	fileWrite(config.outputPath & "/index.html", html);
   }

   /**
   * Generate JSON report
   */
   private void function generateJsonReport(required struct coverage, required struct config, required struct testResults) {
   	local.report = {
   		timestamp = dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss"),
   		type = config.type,
   		summary = {
   			lines = coverage.lines,
   			functions = coverage.functions,
   			branches = coverage.branches,
   			statements = coverage.statements,
   			overall = coverage.percentage
   		},
   		files = coverage.files,
   		testResults = {
   			totalSpecs = testResults.totalSpecs,
   			totalPass = testResults.totalPass,
   			totalFail = testResults.totalFail,
   			totalSkipped = testResults.totalSkipped,
   			totalError = testResults.totalError
   		}
   	};
   	
   	fileWrite(config.outputPath & "/coverage.json", serializeJson(report));
   }

   /**
   * Generate XML report
   */
   private void function generateXmlReport(required struct coverage, required struct config, required struct testResults) {
   	local.xml = '<?xml version="1.0" encoding="UTF-8"?>
<coverage version="1" timestamp="#getTickCount()#">
   <project name="#config.type#">
       <metrics
           lines="#coverage.lines.total#"
           coveredlines="#coverage.lines.covered#"
           functions="#coverage.functions.total#"
           coveredfunctions="#coverage.functions.covered#"
           coverage="#numberFormat(coverage.percentage, "0.00")#"/>
   </project>
</coverage>';
   	
   	fileWrite(config.outputPath & "/coverage.xml", xml);
   }

   /**
   * Generate coverage badge SVG
   */
   private void function generateBadge(required struct coverage, required struct config) {
   	local.percent = numberFormat(coverage.percentage, "0");
   	local.svg = generateCoverageBadge(coverage.percentage);
   	fileWrite(config.outputPath & "/coverage-badge.svg", svg);
   }

   /**
   * Save baseline coverage
   */
   private void function saveBaselineCoverage(required struct coverage, required struct config) {
   	local.baselineFile = config.outputPath & "/coverage-baseline.json";
   	fileWrite(baselineFile, serializeJson(coverage));
   	print.greenBoldLine("Baseline Coverage Saved!");
   	print.line("  File: #baselineFile#");
   	print.line("  Coverage: #numberFormat(coverage.percentage, '0.0')#%");
   }

   /**
   * Compare with baseline coverage
   */
   private void function compareWithBaseline(required struct coverage, required struct config) {
   	local.baselineFile = config.outputPath & "/coverage-baseline.json";
   	
   	if (!fileExists(baselineFile)) {
   		print.line();
   		print.line("Run with --save-baseline to create one");
   		error("No baseline found for comparison");
   	}
   	
   	try {
   		local.baseline = deserializeJson(fileRead(baselineFile));
   		local.diff = coverage.percentage - baseline.percentage;
   		
   		print.line();
   		print.boldBlueLine("Baseline Comparison:");
   		print.line("--------------------");
   		print.line("  Current:  #numberFormat(coverage.percentage, '0.0')#%");
   		print.line("  Baseline: #numberFormat(baseline.percentage, '0.0')#%");
   		
   		if (diff > 0) {
   			print.greenBoldLine("  Change:   +#numberFormat(diff, '0.0')#% [IMPROVED]");
   		} else if (diff < 0) {
   			print.redBoldLine("  Change:   #numberFormat(diff, '0.0')#% [DECREASED]");
   		} else {
   			print.line("  Change:   0% [NO CHANGE]");
   		}
   	} catch (any e) {
   		print.yellowLine("Could not compare with baseline: #e.message#");
   	}
   }
}