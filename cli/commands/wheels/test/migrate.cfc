/**
 * Migrate RocketUnit tests to TestBox BDD syntax
 *
 * Examples:
 * {code:bash}
 * wheels test migrate path/to/test.cfc
 * wheels test migrate tests/models --recursive
 * wheels test migrate tests --dry-run
 * wheels test migrate tests/controllers/UsersTest.cfc --no-backup
 * {code}
 **/
component aliases='wheels t migrate' extends="../base" {
	
	/**
	 * Initialize the command
	 */
	function init() {
		return this;
	}
	
	/**
	 * @path.hint Path to test file or directory to migrate
	 * @recursive.hint Process subdirectories when migrating a directory
	 * @pattern.hint File pattern to match (default: *.cfc)
	 * @dryRun.hint Preview changes without modifying files
	 * @backup.hint Create backup files before migration
	 * @report.hint Generate detailed migration report
	 **/
	function run(
		required string path,
		boolean recursive = true,
		string pattern = "*.cfc",
		boolean dryRun = false,
		boolean backup = true,
		boolean report = false
	) {
		// Initialize services
		var details = application.wirebox.getInstance("DetailOutputService@wheels-cli");
		var migrationService = new models.TestMigrationService();
		
		// Resolve path
		var targetPath = fileSystemUtil.resolvePath(arguments.path);
		
		// Validate path exists
		if (!fileExists(targetPath) && !directoryExists(targetPath)) {
			error("[#targetPath#] does not exist");
		}
		
		// Output header
		details.header("🔄", "Test Migration to TestBox");
		
		if (arguments.dryRun) {
			details.info("DRY RUN MODE - No files will be modified");
		}
		
		var results = [];
		
		// Process based on path type
		if (fileExists(targetPath)) {
			// Single file migration
			details.processing("Migrating: #targetPath#");
			
			try {
				var result = migrationService.migrateTestFile(
					filePath = targetPath,
					backup = arguments.backup,
					dryRun = arguments.dryRun
				);
				
				results = [result];
				
				if (result.success) {
					if (structKeyExists(result, "skipped") && result.skipped) {
						details.skip("#targetPath# - #result.reason#");
					} else {
						details.success("Migrated: #targetPath#");
						displayChanges(result, details);
					}
				}
			} catch (any e) {
				details.error("Failed to migrate: #e.message#");
				return;
			}
		} else {
			// Directory migration
			details.info("Scanning directory: #targetPath#");
			
			var migrationResult = migrationService.migrateDirectory(
				directory = targetPath,
				recursive = arguments.recursive,
				pattern = arguments.pattern,
				backup = arguments.backup,
				dryRun = arguments.dryRun
			);
			
			results = migrationResult.results;
			
			// Display results
			for (var result in results) {
				if (!result.success) {
					details.error("#result.filePath# - #result.error#");
				} else if (structKeyExists(result, "skipped") && result.skipped) {
					details.skip("#result.filePath# - #result.reason#");
				} else {
					details.success("Migrated: #result.filePath#");
					if (arguments.dryRun || isBoolean(request.wheels.verbose ?: false)) {
						displayChanges(result, details);
					}
				}
			}
			
			// Display summary
			details.line();
			details.header("📊", "Migration Summary");
			var stats = migrationResult.statistics;
			details.info("Files processed: #stats.filesProcessed#");
			details.success("Files converted: #stats.filesConverted#");
			if (stats.filesSkipped > 0) {
				details.info("Files skipped: #stats.filesSkipped#");
			}
			if (stats.filesFailed > 0) {
				details.error("Files failed: #stats.filesFailed#");
			}
			if (stats.totalWarnings > 0) {
				details.warning("Total warnings: #stats.totalWarnings#");
			}
		}
		
		// Generate report if requested
		if (arguments.report) {
			var report = migrationService.generateReport(results);
			var reportPath = fileSystemUtil.resolvePath("test-migration-report.json");
			fileWrite(reportPath, serializeJSON(report));
			details.line();
			details.create("Report saved to: #reportPath#");
		}
		
		// Display next steps
		if (!arguments.dryRun && arrayLen(results) > 0) {
			var nextSteps = [];
			
			if (arguments.backup) {
				arrayAppend(nextSteps, "Backup files created with .bak extension");
			}
			
			arrayAppend(nextSteps, "Run your tests to ensure they still pass");
			arrayAppend(nextSteps, "Review any warnings in the migrated files");
			arrayAppend(nextSteps, "Update test descriptions for better readability");
			arrayAppend(nextSteps, "Consider using TestBox's advanced features like data providers");
			
			details.nextSteps(nextSteps);
		}
	}
	
	/**
	 * Display changes made to a file
	 */
	private function displayChanges(required struct result, required any details) {
		if (structKeyExists(arguments.result, "changes") && arrayLen(arguments.result.changes) > 0) {
			arguments.details.indent();
			for (var change in arguments.result.changes) {
				arguments.details.text("✓ #change#");
			}
			arguments.details.outdent();
		}
		
		if (structKeyExists(arguments.result, "warnings") && arrayLen(arguments.result.warnings) > 0) {
			arguments.details.indent();
			for (var warning in arguments.result.warnings) {
				arguments.details.warning("⚠ #warning#");
			}
			arguments.details.outdent();
		}
	}
}