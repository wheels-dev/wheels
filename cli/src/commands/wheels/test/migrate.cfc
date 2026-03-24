/**
 * Migrate legacy RocketUnit tests to TestBox BDD syntax
 *
 * Scans test files for RocketUnit patterns (test_ prefix functions, assert() calls,
 * extends="wheels.Test") and converts them to TestBox BDD syntax (describe/it blocks,
 * expect() matchers, extends="wheels.WheelsTest").
 *
 * Creates .bak backup files before conversion unless --no-backup is specified.
 *
 * Examples:
 * wheels test migrate
 * wheels test migrate tests/legacy
 * wheels test migrate --dry-run
 * wheels test migrate --no-backup
 * wheels test migrate tests/RocketUnit/functions/models/User.cfc
 */
component aliases="wheels test:migrate" extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";
	property name="migrationService" inject="TestMigrationService@wheels-cli";

	/**
	 * @directory Directory containing test files to migrate (default: tests/)
	 * @file Single file to migrate instead of a directory
	 * @recurse Recurse into subdirectories
	 * @backup Create .bak backup files before conversion
	 * @dryRun Preview changes without writing files
	 * @verbose Show detailed output for each file
	 */
	function run(
		string directory = "",
		string file = "",
		boolean recurse = true,
		boolean backup = true,
		boolean dryRun = false,
		boolean verbose = false
	) {
		requireWheelsApp(getCWD());

		detailOutput.header("Test Migration: RocketUnit -> TestBox BDD");

		if (arguments.dryRun) {
			detailOutput.statusInfo("DRY RUN - no files will be modified");
			detailOutput.line();
		}

		// Single file mode
		if (len(arguments.file)) {
			var filePath = fileSystemUtil.resolvePath(arguments.file);
			if (!fileExists(filePath)) {
				detailOutput.error("File not found: #filePath#");
				return;
			}
			migrateSingleFile(filePath, arguments.backup, arguments.dryRun, arguments.verbose);
			return;
		}

		// Directory mode
		var targetDir = len(arguments.directory)
			? fileSystemUtil.resolvePath(arguments.directory)
			: fileSystemUtil.resolvePath("tests/");

		if (!directoryExists(targetDir)) {
			detailOutput.error("Directory not found: #targetDir#");
			return;
		}

		migrateDirectoryFiles(targetDir, arguments.recurse, arguments.backup, arguments.dryRun, arguments.verbose);
	}

	/**
	 * Migrate a single file and display results
	 */
	private function migrateSingleFile(
		required string filePath,
		boolean backup = true,
		boolean dryRun = false,
		boolean verbose = false
	) {
		detailOutput.metric("File", getFileFromPath(arguments.filePath));
		detailOutput.line();

		var result = migrationService.migrateTestFile(
			filePath = arguments.filePath,
			backup = arguments.backup,
			dryRun = arguments.dryRun
		);

		if (result.success) {
			detailOutput.statusSuccess("Migrated: #getFileFromPath(arguments.filePath)#");

			if (arrayLen(result.changes) > 0) {
				detailOutput.subHeader("Changes");
				for (var change in result.changes) {
					detailOutput.output("  - #change#", true);
				}
			}

			if (arrayLen(result.warnings) > 0) {
				detailOutput.line();
				detailOutput.statusWarning("Warnings (#arrayLen(result.warnings)#)");
				for (var warning in result.warnings) {
					detailOutput.output("  - #warning#", true);
				}
			}

			if (arguments.dryRun && len(result.preview)) {
				detailOutput.subHeader("Preview");
				detailOutput.code(result.preview);
			}
		} else {
			if (structKeyExists(result, "skipped") && result.skipped) {
				detailOutput.skip(getFileFromPath(arguments.filePath) & " (" & result.reason & ")");
			} else {
				detailOutput.statusFailed("Failed: #result.error#");
			}
		}
	}

	/**
	 * Migrate all files in a directory and display summary
	 */
	private function migrateDirectoryFiles(
		required string directory,
		boolean recurse = true,
		boolean backup = true,
		boolean dryRun = false,
		boolean verbose = false
	) {
		detailOutput.metric("Directory", arguments.directory);
		detailOutput.metric("Recursive", arguments.recurse ? "Yes" : "No");
		detailOutput.metric("Backup", arguments.backup ? "Yes" : "No");
		detailOutput.line();

		var migrationResult = migrationService.migrateDirectory(
			directory = arguments.directory,
			recursive = arguments.recurse,
			backup = arguments.backup,
			dryRun = arguments.dryRun
		);

		var results = migrationResult.results;
		var stats = migrationResult.statistics;

		// Display per-file results
		var converted = 0;
		var skipped = 0;
		var failed = 0;

		for (var result in results) {
			var fileName = getFileFromPath(result.filePath);

			if (!result.success && !(structKeyExists(result, "skipped") && result.skipped)) {
				detailOutput.statusFailed(fileName & ": " & result.error);
				failed++;
			} else if (structKeyExists(result, "skipped") && result.skipped) {
				if (arguments.verbose) {
					detailOutput.skip(fileName & " (" & result.reason & ")");
				}
				skipped++;
			} else {
				var changeCount = structKeyExists(result, "changes") ? arrayLen(result.changes) : 0;
				if (changeCount > 0) {
					detailOutput.create(fileName & " (#changeCount# changes)");
					converted++;
				} else {
					if (arguments.verbose) {
						detailOutput.skip(fileName & " (no RocketUnit patterns found)");
					}
					skipped++;
				}

				// Show warnings
				if (structKeyExists(result, "warnings") && arrayLen(result.warnings) > 0) {
					for (var warning in result.warnings) {
						detailOutput.statusWarning("  " & warning);
					}
				}

				// Show detailed changes in verbose mode
				if (arguments.verbose && structKeyExists(result, "changes")) {
					for (var change in result.changes) {
						detailOutput.output("    - #change#", true);
					}
				}
			}
		}

		// Summary
		detailOutput.line();
		detailOutput.subHeader("Migration Summary");
		detailOutput.metric("Files scanned", arrayLen(results));
		detailOutput.metric("Converted", converted);
		detailOutput.metric("Skipped", skipped);
		detailOutput.metric("Failed", failed);

		if (stats.totalWarnings > 0) {
			detailOutput.metric("Warnings", stats.totalWarnings);
		}

		// Generate and display report recommendations
		var report = migrationService.generateReport(results);
		if (arrayLen(report.recommendations) > 0) {
			detailOutput.line();
			detailOutput.nextSteps(report.recommendations);
		}

		if (converted > 0) {
			detailOutput.line();
			if (arguments.dryRun) {
				detailOutput.statusInfo("Re-run without --dry-run to apply changes");
			} else {
				detailOutput.statusSuccess("Migration complete! #converted# file(s) converted.");
				if (arguments.backup) {
					detailOutput.statusInfo("Backup files created with .bak extension");
				}
			}
		} else if (failed == 0) {
			detailOutput.line();
			detailOutput.statusInfo("No RocketUnit tests found to migrate");
		}
	}

}
