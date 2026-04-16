/**
 * Run browser-based E2E tests.
 *
 * Pre-flight checks that Playwright JARs are installed, then hits
 * the test runner URL scoped to browser test specs.
 *
 * Examples:
 *   wheels browser:test
 *   wheels browser:test --verbose
 *   wheels browser:test --format=json
 */
component aliases="wheels browser:test, wheels browser test" extends="../base" {

	property name="browserService" inject="BrowserService@wheels-cli";

	/**
	 * @format    Output format: text or json
	 * @verbose   Show full spec names
	 * @directory Test directory (dot-notation, relative to vendor/wheels/)
	 */
	function run(
		string format = "text",
		boolean verbose = false,
		string directory = "wheels.tests.specs.wheelstest"
	) {
		var projectRoot = getCWD();

		try {
			var manifest = browserService.getManifest(projectRoot);
			var installDir = browserService.resolveInstallDir();
			var status = browserService.verifyInstall(
				manifest=manifest,
				installDir=installDir
			);
			if (!status.installed) {
				print.redLine("Playwright not installed.");
				if (arrayLen(status.missing)) {
					print.yellowLine("Missing: " & arrayToList(status.missing, ", "));
				}
				if (arrayLen(status.mismatched)) {
					print.yellowLine("SHA mismatch: " & arrayToList(status.mismatched, ", "));
				}
				print.line("");
				print.line("Run: wheels browser:install");
				return;
			}
		} catch (any e) {
			print.redLine("Error: " & e.message);
			return;
		}

		print.line("Running browser tests...");
		print.line("Directory: " & arguments.directory);
		print.line("");

		var serverInfo = command("server info").params(property="host").run(returnOutput=true);
		var port = command("server info").params(property="port").run(returnOutput=true);
		var host = trim(serverInfo) ?: "localhost";
		var portNum = trim(port) ?: "8080";
		var baseUrl = "http://" & host & ":" & portNum;

		var testUrl = baseUrl
			& "/wheels/core/tests?db=sqlite&format=json&directory="
			& arguments.directory;

		try {
			cfhttp(url=testUrl, method="GET", timeout=300, result="local.response");
		} catch (any e) {
			print.redLine("Failed to reach test runner at: " & testUrl);
			print.redLine("Is the server running? Try: server start");
			return;
		}

		if (arguments.format == "json") {
			print.line(local.response.fileContent);
			return;
		}

		try {
			var data = deserializeJSON(local.response.fileContent);
			print.line("Pass: " & data.totalPass & "  Fail: " & data.totalFail & "  Error: " & data.totalError);
			print.line("");

			for (var bundle in (data.bundleStats ?: [])) {
				for (var suite in (bundle.suiteStats ?: [])) {
					for (var spec in (suite.specStats ?: [])) {
						if (listFindNoCase("Failed,Error", spec.status ?: "")) {
							print.redLine(
								"  " & (spec.status ?: "") & ": "
								& (spec.name ?: "unknown")
							);
							if (arguments.verbose && len(spec.failMessage ?: "")) {
								print.line("    " & left(spec.failMessage, 200));
							}
						}
					}
				}
			}

			if (data.totalFail == 0 && data.totalError == 0) {
				print.greenLine("All browser tests passed.");
			}
		} catch (any e) {
			print.redLine("Failed to parse test results: " & e.message);
			if (arguments.verbose) {
				print.line(left(local.response.fileContent ?: "", 500));
			}
		}
	}

}
