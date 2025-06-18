/**
 * Service for migrating RocketUnit tests to TestBox BDD syntax
 * Provides automated conversion with manual review recommendations
 */
component singleton {
	
	/**
	 * Initialize the service
	 */
	function init() {
		variables.conversionPatterns = getConversionPatterns();
		variables.statistics = resetStatistics();
		return this;
	}
	
	/**
	 * Migrate a single test file from RocketUnit to TestBox
	 *
	 * @filePath The path to the test file
	 * @backup Whether to create a backup file
	 * @dryRun Whether to perform a dry run without saving
	 */
	function migrateTestFile(
		required string filePath,
		boolean backup = true,
		boolean dryRun = false
	) {
		if (!fileExists(arguments.filePath)) {
			throw(type="TestMigration.FileNotFound", message="Test file not found: #arguments.filePath#");
		}
		
		var content = fileRead(arguments.filePath);
		var originalContent = content;
		
		// Create backup if requested
		if (arguments.backup && !arguments.dryRun) {
			var backupPath = arguments.filePath & ".bak";
			fileWrite(backupPath, originalContent);
		}
		
		// Apply conversions
		var result = {
			content = content,
			changes = [],
			warnings = []
		};
		
		// Convert component extends
		result = convertComponentExtends(result);
		
		// Convert test methods to BDD format
		result = convertTestMethods(result);
		
		// Convert assertions
		result = convertAssertions(result);
		
		// Convert setup/teardown
		result = convertLifecycleMethods(result);
		
		// Add missing imports
		result = addRequiredImports(result);
		
		// Clean up and format
		result = cleanupAndFormat(result);
		
		// Save if not dry run
		if (!arguments.dryRun) {
			fileWrite(arguments.filePath, result.content);
		}
		
		// Update statistics
		updateStatistics(result);
		
		return {
			success = true,
			filePath = arguments.filePath,
			changes = result.changes,
			warnings = result.warnings,
			dryRun = arguments.dryRun
		};
	}
	
	/**
	 * Migrate all test files in a directory
	 *
	 * @directory The directory containing test files
	 * @recursive Whether to process subdirectories
	 * @pattern File pattern to match (default: *.cfc)
	 * @backup Whether to create backups
	 * @dryRun Whether to perform a dry run
	 */
	function migrateDirectory(
		required string directory,
		boolean recursive = true,
		string pattern = "*.cfc",
		boolean backup = true,
		boolean dryRun = false
	) {
		if (!directoryExists(arguments.directory)) {
			throw(type="TestMigration.DirectoryNotFound", message="Directory not found: #arguments.directory#");
		}
		
		var files = directoryList(
			arguments.directory,
			arguments.recursive,
			"path",
			arguments.pattern
		);
		
		var results = [];
		
		for (var file in files) {
			// Skip already migrated files
			if (fileRead(file) contains 'extends="tests.BaseSpec"' || fileRead(file) contains "extends='tests.BaseSpec'") {
				arrayAppend(results, {
					success = true,
					filePath = file,
					skipped = true,
					reason = "Already migrated to TestBox"
				});
				continue;
			}
			
			try {
				var result = migrateTestFile(
					filePath = file,
					backup = arguments.backup,
					dryRun = arguments.dryRun
				);
				arrayAppend(results, result);
			} catch (any e) {
				arrayAppend(results, {
					success = false,
					filePath = file,
					error = e.message
				});
			}
		}
		
		return {
			results = results,
			statistics = getStatistics()
		};
	}
	
	/**
	 * Convert component extends from RocketUnit to TestBox
	 */
	private function convertComponentExtends(required struct result) {
		var patterns = [
			{
				pattern = 'extends\s*=\s*"tests\.Test"',
				replacement = 'extends="tests.BaseSpec"'
			},
			{
				pattern = "extends\s*=\s*'tests\.Test'",
				replacement = 'extends="tests.BaseSpec"'
			},
			{
				pattern = 'extends\s*=\s*"wheels\.Test"',
				replacement = 'extends="tests.BaseSpec"'
			}
		];
		
		for (var p in patterns) {
			if (reFindNoCase(p.pattern, arguments.result.content)) {
				arguments.result.content = reReplaceNoCase(
					arguments.result.content,
					p.pattern,
					p.replacement,
					"all"
				);
				arrayAppend(arguments.result.changes, "Updated component extends to TestBox BaseSpec");
			}
		}
		
		return arguments.result;
	}
	
	/**
	 * Convert test methods to BDD format
	 */
	private function convertTestMethods(required struct result) {
		// Find all test methods
		var testMethodPattern = "function\s+(test\w+)\s*\([^)]*\)\s*\{";
		var matches = reMatchNoCase(testMethodPattern, arguments.result.content);
		
		if (arrayLen(matches) > 0) {
			// Wrap in run() function and describe block if not already present
			if (!reFindNoCase("function\s+run\s*\(\s*\)", arguments.result.content)) {
				var componentPattern = "(component[^{]+\{)";
				var componentMatch = reFindNoCase(componentPattern, arguments.result.content, 1, true);
				
				if (componentMatch.pos[1] > 0) {
					var insertPos = componentMatch.pos[1] + componentMatch.len[1];
					var indent = chr(10) & chr(9);
					var runWrapper = indent & "function run() {" & indent & chr(9) & 'describe("Test Suite", () => {' & indent & indent;
					
					// Insert run wrapper
					arguments.result.content = insert(runWrapper, arguments.result.content, insertPos);
					
					// Close run wrapper before closing component
					var closePattern = "\s*\}\s*$";
					arguments.result.content = reReplaceNoCase(
						arguments.result.content,
						closePattern,
						indent & chr(9) & "});" & indent & "}" & chr(10) & "}",
						"one"
					);
					
					arrayAppend(arguments.result.changes, "Wrapped test methods in run() and describe()");
				}
			}
			
			// Convert individual test methods to it() blocks
			for (var match in matches) {
				var methodName = reReplaceNoCase(match, "function\s+", "", "one");
				methodName = reReplaceNoCase(methodName, "\s*\([^)]*\)\s*\{", "", "one");
				
				// Convert method name to readable description
				var description = convertTestNameToDescription(methodName);
				
				// Replace function with it()
				var itBlock = 'it("#description#", () => {';
				arguments.result.content = replaceNoCase(
					arguments.result.content,
					match,
					itBlock,
					"one"
				);
			}
			
			arrayAppend(arguments.result.changes, "Converted #arrayLen(matches)# test methods to it() blocks");
		}
		
		return arguments.result;
	}
	
	/**
	 * Convert test method name to readable description
	 */
	private function convertTestNameToDescription(required string methodName) {
		var description = arguments.methodName;
		
		// Remove "test" prefix
		description = reReplaceNoCase(description, "^test", "", "one");
		
		// Convert camelCase to spaces
		description = reReplace(description, "([A-Z])", " \1", "all");
		
		// Clean up
		description = trim(lCase(description));
		
		// Handle common patterns
		description = replaceNoCase(description, "should ", "should ", "all");
		
		if (left(description, 6) != "should") {
			description = "should " & description;
		}
		
		return description;
	}
	
	/**
	 * Convert RocketUnit assertions to TestBox expectations
	 */
	private function convertAssertions(required struct result) {
		var conversions = variables.conversionPatterns.assertions;
		var convertedCount = 0;
		
		for (var conversion in conversions) {
			var matches = reFindAllNoCase(conversion.pattern, arguments.result.content);
			
			if (arrayLen(matches) > 0) {
				for (var i = arrayLen(matches); i >= 1; i--) {
					var match = matches[i];
					var original = mid(arguments.result.content, match.pos[1], match.len[1]);
					var replacement = conversion.replace;
					
					// Handle captured groups
					if (structKeyExists(conversion, "groups") && arrayLen(match.pos) > 1) {
						for (var g = 2; g <= arrayLen(match.pos); g++) {
							if (match.len[g] > 0) {
								var groupValue = mid(arguments.result.content, match.pos[g], match.len[g]);
								replacement = replace(replacement, "$" & (g-1), groupValue, "all");
							}
						}
					}
					
					arguments.result.content = removeChars(arguments.result.content, match.pos[1], match.len[1]);
					arguments.result.content = insert(replacement, arguments.result.content, match.pos[1] - 1);
					convertedCount++;
				}
			}
		}
		
		if (convertedCount > 0) {
			arrayAppend(arguments.result.changes, "Converted #convertedCount# assertions to TestBox expectations");
		}
		
		// Add warnings for complex assertions that need manual review
		checkForComplexAssertions(arguments.result);
		
		return arguments.result;
	}
	
	/**
	 * Check for complex assertions that need manual review
	 */
	private function checkForComplexAssertions(required struct result) {
		var complexPatterns = [
			{
				pattern = "assert\s*\([^)]*\band\b[^)]*\)",
				warning = "Complex assertion with AND logic found - manual review recommended"
			},
			{
				pattern = "assert\s*\([^)]*\bor\b[^)]*\)",
				warning = "Complex assertion with OR logic found - manual review recommended"
			},
			{
				pattern = "assert\s*\([^)]*evaluate\s*\([^)]*\)[^)]*\)",
				warning = "Assertion with evaluate() found - manual review recommended"
			}
		];
		
		for (var pattern in complexPatterns) {
			if (reFindNoCase(pattern.pattern, arguments.result.content)) {
				arrayAppend(arguments.result.warnings, pattern.warning);
			}
		}
	}
	
	/**
	 * Convert lifecycle methods
	 */
	private function convertLifecycleMethods(required struct result) {
		var conversions = [
			{from = "function setup()", to = "beforeEach(() => {"},
			{from = "function teardown()", to = "afterEach(() => {"},
			{from = "function beforeTests()", to = "beforeAll(() => {"},
			{from = "function afterTests()", to = "afterAll(() => {"}
		];
		
		for (var conversion in conversions) {
			if (findNoCase(conversion.from, arguments.result.content)) {
				arguments.result.content = replaceNoCase(
					arguments.result.content,
					conversion.from,
					conversion.to,
					"all"
				);
				arrayAppend(arguments.result.changes, "Converted lifecycle method: #conversion.from#");
			}
		}
		
		return arguments.result;
	}
	
	/**
	 * Add required imports if missing
	 */
	private function addRequiredImports(required struct result) {
		// Check if BaseSpec import is needed and not present
		if (!findNoCase("tests.BaseSpec", arguments.result.content) && 
		    findNoCase("extends=", arguments.result.content)) {
			// Add helpful comment at the top
			var comment = "/**" & chr(10);
			comment &= " * Test migrated from RocketUnit to TestBox" & chr(10);
			comment &= " * Migration date: #dateFormat(now(), 'yyyy-mm-dd')#" & chr(10);
			comment &= " * Please review all expectations and test logic" & chr(10);
			comment &= " **/" & chr(10);
			
			if (!findNoCase("Test migrated from RocketUnit", arguments.result.content)) {
				arguments.result.content = comment & arguments.result.content;
				arrayAppend(arguments.result.changes, "Added migration comment header");
			}
		}
		
		return arguments.result;
	}
	
	/**
	 * Clean up and format the converted code
	 */
	private function cleanupAndFormat(required struct result) {
		// Remove empty setup/teardown methods
		arguments.result.content = reReplaceNoCase(
			arguments.result.content,
			"(before|after)(Each|All)\s*\(\s*\(\)\s*=>\s*\{\s*\}\s*\)",
			"",
			"all"
		);
		
		// Fix double semicolons
		arguments.result.content = replace(arguments.result.content, ";;", ";", "all");
		
		// Fix spacing issues
		arguments.result.content = reReplace(arguments.result.content, "\n\s*\n\s*\n", chr(10) & chr(10), "all");
		
		return arguments.result;
	}
	
	/**
	 * Get conversion patterns
	 */
	private function getConversionPatterns() {
		return {
			assertions = [
				// Simple assertions
				{
					pattern = 'assert\s*\(\s*"([^"]+)"\s*\)',
					replace = 'expect($1).toBeTrue()'
				},
				{
					pattern = "assert\s*\(\s*'([^']+)'\s*\)",
					replace = 'expect($1).toBeTrue()'
				},
				// Negated assertions
				{
					pattern = 'assert\s*\(\s*"!([^"]+)"\s*\)',
					replace = 'expect($1).toBeFalse()'
				},
				// Equality assertions
				{
					pattern = 'assert\s*\(\s*"([^"]+)\s*==\s*([^"]+)"\s*\)',
					replace = 'expect($1).toBe($2)'
				},
				{
					pattern = 'assert\s*\(\s*"([^"]+)\s*eq\s*([^"]+)"\s*\)',
					replace = 'expect($1).toBe($2)'
				},
				// Inequality assertions
				{
					pattern = 'assert\s*\(\s*"([^"]+)\s*!=\s*([^"]+)"\s*\)',
					replace = 'expect($1).notToBe($2)'
				},
				{
					pattern = 'assert\s*\(\s*"([^"]+)\s*neq\s*([^"]+)"\s*\)',
					replace = 'expect($1).notToBe($2)'
				},
				// Greater than
				{
					pattern = 'assert\s*\(\s*"([^"]+)\s*>\s*([^"]+)"\s*\)',
					replace = 'expect($1).toBeGT($2)'
				},
				{
					pattern = 'assert\s*\(\s*"([^"]+)\s*gt\s*([^"]+)"\s*\)',
					replace = 'expect($1).toBeGT($2)'
				},
				// Less than
				{
					pattern = 'assert\s*\(\s*"([^"]+)\s*<\s*([^"]+)"\s*\)',
					replace = 'expect($1).toBeLT($2)'
				},
				{
					pattern = 'assert\s*\(\s*"([^"]+)\s*lt\s*([^"]+)"\s*\)',
					replace = 'expect($1).toBeLT($2)'
				},
				// Type checking
				{
					pattern = 'assert\s*\(\s*"isArray\s*\(\s*([^)]+)\s*\)"\s*\)',
					replace = 'expect($1).toBeArray()'
				},
				{
					pattern = 'assert\s*\(\s*"isStruct\s*\(\s*([^)]+)\s*\)"\s*\)',
					replace = 'expect($1).toBeStruct()'
				},
				{
					pattern = 'assert\s*\(\s*"isNumeric\s*\(\s*([^)]+)\s*\)"\s*\)',
					replace = 'expect($1).toBeNumeric()'
				},
				// Structure key exists
				{
					pattern: 'assert\s*\(\s*"structKeyExists\s*\(\s*([^,]+),\s*["\']([^"\']+)["\']\s*\)"\s*\)',
					replace: 'expect($1).toHaveKey("$2")'
				},
				// Length checks
				{
					pattern = 'assert\s*\(\s*"len\s*\(\s*([^)]+)\s*\)\s*==\s*([^"]+)"\s*\)',
					replace = 'expect($1).toHaveLength($2)'
				},
				{
					pattern = 'assert\s*\(\s*"arrayLen\s*\(\s*([^)]+)\s*\)\s*==\s*([^"]+)"\s*\)',
					replace = 'expect(arrayLen($1)).toBe($2)'
				},
				// Contains
				{
					pattern = 'assert\s*\(\s*"([^"]+)\s+contains\s+([^"]+)"\s*\)',
					replace = 'expect($1).toInclude($2)'
				}
			]
		};
	}
	
	/**
	 * Helper to find all regex matches with positions
	 */
	private function reFindAllNoCase(required string pattern, required string text) {
		var matches = [];
		var result = reFindNoCase(arguments.pattern, arguments.text, 1, true);
		
		while (result.pos[1] > 0) {
			arrayAppend(matches, result);
			var startPos = result.pos[1] + result.len[1];
			if (startPos > len(arguments.text)) break;
			result = reFindNoCase(arguments.pattern, arguments.text, startPos, true);
		}
		
		return matches;
	}
	
	/**
	 * Reset statistics
	 */
	private function resetStatistics() {
		return {
			filesProcessed = 0,
			filesConverted = 0,
			filesSkipped = 0,
			filesFailed = 0,
			totalAssertions = 0,
			totalWarnings = 0
		};
	}
	
	/**
	 * Update statistics
	 */
	private function updateStatistics(required struct result) {
		variables.statistics.filesProcessed++;
		if (structKeyExists(arguments.result, "changes") && arrayLen(arguments.result.changes) > 0) {
			variables.statistics.filesConverted++;
		}
		if (structKeyExists(arguments.result, "warnings")) {
			variables.statistics.totalWarnings += arrayLen(arguments.result.warnings);
		}
	}
	
	/**
	 * Get current statistics
	 */
	function getStatistics() {
		return duplicate(variables.statistics);
	}
	
	/**
	 * Generate migration report
	 */
	function generateReport(required array results) {
		var report = {
			summary = getStatistics(),
			details = [],
			recommendations = []
		};
		
		// Process results
		for (var result in arguments.results) {
			if (!result.success) {
				arrayAppend(report.details, {
					file = result.filePath,
					status = "Failed",
					error = result.error
				});
			} else if (structKeyExists(result, "skipped") && result.skipped) {
				arrayAppend(report.details, {
					file = result.filePath,
					status = "Skipped",
					reason = result.reason
				});
			} else {
				arrayAppend(report.details, {
					file = result.filePath,
					status = "Converted",
					changes = arrayLen(result.changes),
					warnings = arrayLen(result.warnings)
				});
			}
		}
		
		// Add recommendations
		if (report.summary.totalWarnings > 0) {
			arrayAppend(report.recommendations, "Review files with warnings for complex assertions that may need manual adjustment");
		}
		
		arrayAppend(report.recommendations, "Run all tests to ensure they still pass after migration");
		arrayAppend(report.recommendations, "Review test descriptions for clarity and update as needed");
		arrayAppend(report.recommendations, "Consider adding more descriptive test names using TestBox's BDD syntax");
		
		return report;
	}
}