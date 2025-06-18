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
	 * @path.hint Path to test file or directory to migrate (or --status for migration status)
	 * @recursive.hint Process subdirectories when migrating a directory
	 * @pattern.hint File pattern to match (default: *.cfc)
	 * @dryRun.hint Preview changes without modifying files
	 * @backup.hint Create backup files before migration
	 * @report.hint Generate detailed migration report
	 * @status.hint Show migration status for directory instead of migrating
	 **/
	function run(
		required string path,
		boolean recursive = true,
		string pattern = "*.cfc",
		boolean dryRun = false,
		boolean backup = true,
		boolean report = false,
		boolean status = false
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
		
		// Check if we're showing status instead of migrating
		if (arguments.status) {
			return showMigrationStatus(targetPath, arguments.recursive, arguments.pattern, details, migrationService);
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
	
	/**
	 * Show migration status for a directory
	 */
	private function showMigrationStatus(
		required string path,
		required boolean recursive,
		required string pattern,
		required any details,
		required any migrationService
	) {
		// Output header
		arguments.details.header("📊", "Test Migration Status");
		
		if (!directoryExists(arguments.path)) {
			error("Status can only be shown for directories, not individual files");
		}
		
		// Get all test files
		var files = directoryList(
			arguments.path,
			arguments.recursive,
			"path",
			arguments.pattern
		);
		
		var status = {
			total = arrayLen(files),
			migrated = 0,
			unmigrated = 0,
			mixed = 0,
			nonTest = 0,
			migratedFiles = [],
			unmigratedFiles = [],
			mixedFiles = []
		};
		
		// Analyze each file
		for (var file in files) {
			try {
				var content = fileRead(file);
				var hasBaseSpec = findNoCase('extends="tests.BaseSpec"', content) || findNoCase("extends='tests.BaseSpec'", content);
				var hasOldTest = findNoCase('extends="tests.Test"', content) || findNoCase("extends='tests.Test'", content);
				var hasAssert = reFindNoCase('assert\s*\(', content);
				var hasExpect = findNoCase('expect(', content);
				
				if (hasBaseSpec && !hasAssert) {
					status.migrated++;
					arrayAppend(status.migratedFiles, file);
				} else if (hasOldTest || hasAssert) {
					status.unmigrated++;
					arrayAppend(status.unmigratedFiles, file);
				} else if (hasBaseSpec && hasAssert) {
					status.mixed++;
					arrayAppend(status.mixedFiles, file);
				} else {
					status.nonTest++;
				}
			} catch (any e) {
				// Skip files that can't be read
				status.nonTest++;
			}
		}
		
		// Calculate percentages
		var percentMigrated = status.total > 0 ? round(status.migrated / status.total * 100) : 0;
		var percentUnmigrated = status.total > 0 ? round(status.unmigrated / status.total * 100) : 0;
		
		// Display summary
		arguments.details.line();
		arguments.details.header("📊", "Migration Summary");
		arguments.details.info("Total test files: #status.total#");
		arguments.details.line();
		
		// Progress bar
		var barWidth = 40;
		var migratedBars = round(barWidth * status.migrated / max(status.total, 1));
		var progressBar = repeatString("█", migratedBars) & repeatString("░", barWidth - migratedBars);
		
		arguments.details.text("Progress: [#progressBar#] #percentMigrated#%");
		arguments.details.line();
		
		// Status breakdown
		arguments.details.success("✓ Migrated: #status.migrated# files (#percentMigrated#%)");
		arguments.details.warning("⚠ Unmigrated: #status.unmigrated# files (#percentUnmigrated#%)");
		
		if (status.mixed > 0) {
			arguments.details.error("⚠ Partially migrated: #status.mixed# files");
		}
		if (status.nonTest > 0) {
			arguments.details.info("• Non-test files: #status.nonTest#");
		}
		
		// Show file lists if not too many
		if (status.unmigrated > 0 && status.unmigrated <= 10) {
			arguments.details.line();
			arguments.details.header("📝", "Files Needing Migration");
			for (var file in status.unmigratedFiles) {
				arguments.details.text("  - #replace(file, arguments.path, '.')#");
			}
		} else if (status.unmigrated > 10) {
			arguments.details.line();
			arguments.details.info("Run with --report to see all unmigrated files");
		}
		
		// Next steps
		var nextSteps = [];
		if (status.unmigrated > 0) {
			arrayAppend(nextSteps, "Run 'wheels test migrate #arguments.path#' to migrate remaining files");
			arrayAppend(nextSteps, "Use --dry-run to preview changes first");
		}
		if (status.mixed > 0) {
			arrayAppend(nextSteps, "Review partially migrated files for manual fixes");
		}
		if (status.migrated == status.total && status.total > 0) {
			arrayAppend(nextSteps, "All tests migrated! Run your test suite to verify");
		}
		
		if (arrayLen(nextSteps) > 0) {
			arguments.details.nextSteps(nextSteps);
		}
		
		// Generate detailed report if requested
		if (request.wheels.report ?: false) {
			var reportData = {
				summary = status,
				path = arguments.path,
				date = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
				files = {
					migrated = status.migratedFiles,
					unmigrated = status.unmigratedFiles,
					mixed = status.mixedFiles
				}
			};
			
			var reportPath = fileSystemUtil.resolvePath("migration-status-report.json");
			fileWrite(reportPath, serializeJSON(reportData));
			arguments.details.line();
			arguments.details.create("Detailed report saved to: #reportPath#");
		}
	}
}