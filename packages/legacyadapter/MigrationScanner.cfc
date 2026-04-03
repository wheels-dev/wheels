/**
 * Analyzes application source files for legacy Wheels patterns.
 *
 * Scans CFML files (`.cfc`, `.cfm`) for patterns that should be updated
 * when migrating from Wheels 3.x to 4.0. Returns a structured report
 * with file, line, pattern name, severity, and migration guidance.
 *
 * Severity levels:
 *   info     — optional improvement, old way still works
 *   warning  — will be deprecated in a future release
 *   critical — already deprecated, will break in next major version
 */
component output="false" {

	public any function init() {
		variables.patterns = $buildPatternList();
		return this;
	}

	/**
	 * Scan a directory for legacy patterns.
	 *
	 * @appPath Absolute path to the directory to scan
	 * @recursive Whether to scan subdirectories (default true)
	 */
	public struct function scan(required string appPath, boolean recursive = true) {
		var report = {
			scannedAt: Now(),
			appPath: arguments.appPath,
			totalFiles: 0,
			totalFindings: 0,
			findings: [],
			summary: {}
		};

		if (!DirectoryExists(arguments.appPath)) {
			report.error = "Directory not found: #arguments.appPath#";
			return report;
		}

		var files = DirectoryList(
			arguments.appPath,
			arguments.recursive,
			"path",
			"*.cfc|*.cfm"
		);

		report.totalFiles = ArrayLen(files);

		for (var filePath in files) {
			$scanFile(filePath = filePath, report = report);
		}

		report.totalFindings = ArrayLen(report.findings);
		report.summary = $buildSummary(report.findings);

		return report;
	}

	/**
	 * Scan a single file for legacy patterns.
	 */
	public void function $scanFile(required string filePath, required struct report) {
		var content = "";
		try {
			content = FileRead(arguments.filePath);
		} catch (any e) {
			return;
		}

		if (!Len(Trim(content))) {
			return;
		}

		/* skip test/fixture directories entirely */
		if ($isTestPath(arguments.filePath)) {
			return;
		}

		var normalizedPath = ReplaceNoCase(arguments.filePath, "\", "/", "all");
		var lines = ListToArray(content, Chr(10), true);
		var lineCount = ArrayLen(lines);

		for (var i = 1; i <= lineCount; i++) {
			var line = lines[i];
			for (var pattern in variables.patterns) {
				if (REFindNoCase(pattern.regex, line)) {
					/* apply path filter if pattern requires one */
					if (StructKeyExists(pattern, "pathFilter") && Len(pattern.pathFilter)) {
						if (FindNoCase(pattern.pathFilter, normalizedPath) == 0) {
							continue;
						}
					}
					ArrayAppend(arguments.report.findings, {
						file: arguments.filePath,
						line: i,
						lineContent: Trim(line),
						pattern: pattern.name,
						severity: pattern.severity,
						guidance: pattern.guidance
					});
				}
			}
		}
	}

	/**
	 * Determines if a file path is in a test or fixture directory.
	 */
	public boolean function $isTestPath(required string filePath) {
		var normalized = ReplaceNoCase(arguments.filePath, "\", "/", "all");
		return (
			FindNoCase("/tests/", normalized) > 0
			|| FindNoCase("/test/", normalized) > 0
			|| FindNoCase("/_assets/", normalized) > 0
			|| FindNoCase("/fixtures/", normalized) > 0
		);
	}

	/**
	 * Builds the list of patterns to scan for.
	 *
	 * Each pattern is a struct with keys: name, regex, severity, guidance.
	 * Patterns may also include a `pathFilter` key — if present, the pattern
	 * only matches files whose path contains that substring. This prevents
	 * false positives (e.g., `this.version` in non-plugin CFCs).
	 */
	public array function $buildPatternList() {
		var p = [];

		/* ---- Controller patterns ---- */

		ArrayAppend(p, {
			name: "renderPage",
			regex: "renderPage\s*\(",
			severity: "critical",
			guidance: "Replace renderPage() with renderView(). The method was renamed in Wheels 3.0."
		});

		ArrayAppend(p, {
			name: "renderPageToString",
			regex: "renderPageToString\s*\(",
			severity: "critical",
			guidance: "Replace renderPageToString() with renderView(returnAs=""string"")."
		});

		/* ---- Plugin patterns (restricted to plugins/ directory) ---- */

		ArrayAppend(p, {
			name: "legacyPluginVersion",
			regex: "this\.version\s*=",
			severity: "warning",
			pathFilter: "/plugins/",
			guidance: "Legacy plugin version declaration. Move to package.json manifest with 'version' field. See: https://wheels.dev/docs/packages"
		});

		ArrayAppend(p, {
			name: "legacyPluginDependency",
			regex: "this\.dependency\s*=",
			severity: "warning",
			pathFilter: "/plugins/",
			guidance: "Legacy plugin dependency declaration. Move to package.json 'dependencies' field."
		});

		/* ---- Application scope direct access ---- */

		ArrayAppend(p, {
			name: "directAppScopeAccess",
			regex: "application\.(wheels|\$wheels)\.\w+",
			severity: "info",
			guidance: "Direct application scope access is discouraged in 4.0. Use service() or injector() for DI, or get()/set() for framework settings."
		});

		/* ---- Old extends patterns (future-proofing) ---- */

		ArrayAppend(p, {
			name: "shortExtendsModel",
			regex: 'extends\s*=\s*"Model"',
			severity: "info",
			guidance: "Short extends=""Model"" still works in 4.0. Future releases may require the full path extends=""wheels.Model"". No action needed yet."
		});

		ArrayAppend(p, {
			name: "shortExtendsController",
			regex: 'extends\s*=\s*"Controller"',
			severity: "info",
			guidance: "Short extends=""Controller"" still works in 4.0. Future releases may require the full path extends=""wheels.Controller"". No action needed yet."
		});

		/* ---- Query patterns (informational) ---- */

		ArrayAppend(p, {
			name: "rawWhereString",
			regex: "findAll\s*\([^)]*where\s*=\s*""[^""]*=[^""]*""",
			severity: "info",
			guidance: "String-based WHERE clauses still work but the chainable query builder (.where().get()) provides better injection safety. Consider migrating."
		});

		/* ---- Old test extends ---- */

		ArrayAppend(p, {
			name: "legacyTestExtends",
			regex: 'extends\s*=\s*"wheels\.Test"',
			severity: "warning",
			guidance: "extends=""wheels.Test"" (RocketUnit) is deprecated. Use extends=""wheels.WheelsTest"" (TestBox) for new tests."
		});

		return p;
	}

	/**
	 * Builds a count-by-severity and count-by-pattern summary.
	 */
	public struct function $buildSummary(required array findings) {
		var summary = {
			bySeverity: {info: 0, warning: 0, critical: 0},
			byPattern: {}
		};
		for (var finding in arguments.findings) {
			if (StructKeyExists(summary.bySeverity, finding.severity)) {
				summary.bySeverity[finding.severity] = summary.bySeverity[finding.severity] + 1;
			}
			if (!StructKeyExists(summary.byPattern, finding.pattern)) {
				summary.byPattern[finding.pattern] = 0;
			}
			summary.byPattern[finding.pattern] = summary.byPattern[finding.pattern] + 1;
		}
		return summary;
	}

}
