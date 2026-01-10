/**
 * Clean up expired session files
 */
component extends="../base" {

	/**
	 * Remove expired session files from the application
	 *
	 * @storage Session storage type (file or database) 
	 * @directory Custom session directory for file storage (default: sessions/)
	 * @datasource Datasource name for database sessions
	 * @table Table name for database sessions (default: sessions)
	 * @expiredOnly Only remove expired sessions (default: true)
	 * @dryRun Show what would be deleted without actually deleting
	 * @force Skip confirmation prompt
	 */
	function run(
		string storage = "file",
		string directory = "sessions",
		string datasource = "",
		string table = "sessions",
		boolean expiredOnly = true,
		boolean dryRun = false,
		boolean force = false
	) {
		// Ensure we're in a Wheels app directory
		if (!isWheelsApp()) {
			error("This command must be run from a Wheels application root directory.");
		}

		if (arguments.storage == "file") {
			cleanFileSessions(argumentCollection=arguments);
		} else if (arguments.storage == "database") {
			cleanDatabaseSessions(argumentCollection=arguments);
		} else {
			error("Invalid storage type. Use 'file' or 'database'.");
		}
	}

	/**
	 * Clean file-based sessions
	 */
	private function cleanFileSessions(
		required string directory,
		required boolean expiredOnly,
		required boolean dryRun,
		required boolean force
	) {
		// Resolve session directory
		var sessionDir = fileSystemUtil.resolvePath(arguments.directory);
		
		if (!directoryExists(sessionDir)) {
			// Try common session directories
			var commonDirs = [
				fileSystemUtil.resolvePath("WEB-INF/cfclasses/sessions"),
				fileSystemUtil.resolvePath("WEB-INF/lucee/sessions"),
				fileSystemUtil.resolvePath("sessions"),
				getTempDirectory() & "sessions"
			];
			
			var found = false;
			for (var dir in commonDirs) {
				if (directoryExists(dir)) {
					sessionDir = dir;
					found = true;
					break;
				}
			}
			
			if (!found) {
				print.yellowLine("Session directory '#arguments.directory#' does not exist.");
				print.line("Tried common locations:");
				for (var dir in commonDirs) {
					print.indentedLine("- #dir#");
				}
				return;
			}
		}

		print.line("Scanning session files in: #sessionDir#");
		print.line("");

		// Get list of session files
		var files = [];
		try {
			files = directoryList(
				path = sessionDir,
				recurse = true,
				filter = "*.cfm,*.tmp,*.session",
				type = "file",
				listInfo = "query"
			);
		} catch (any e) {
			print.redLine("Error accessing session directory: #e.message#");
			return;
		}

		var filesToDelete = [];
		var totalSize = 0;
		var expiredCount = 0;
		var activeCount = 0;

		// Analyze session files
		for (var file in files) {
			var isExpired = false;
			
			if (arguments.expiredOnly) {
				// Try to determine if session is expired
				// Most session files are updated with each access
				var age = dateDiff("n", file.dateLastModified, now());
				
				// Consider sessions older than 2 hours as expired (configurable)
				// This should match your CF/Lucee session timeout settings
				if (age > 120) {
					isExpired = true;
				}
			} else {
				// Delete all sessions
				isExpired = true;
			}
			
			if (isExpired) {
				var fileInfo = {
					name: file.name,
					path: file.directory & "/" & file.name,
					size: file.size,
					modified: file.dateLastModified,
					age: dateDiff("n", file.dateLastModified, now())
				};
				filesToDelete.append(fileInfo);
				totalSize += file.size;
				expiredCount++;
			} else {
				activeCount++;
			}
		}

		print.line("Session summary:");
		print.indentedLine("Total sessions: #files.recordCount#");
		print.indentedLine("Expired sessions: #expiredCount#");
		print.indentedLine("Active sessions: #activeCount#");
		print.line("");

		if (filesToDelete.len() == 0) {
			print.greenLine("No expired session files found to clean up.");
			return;
		}

		// Display files to be deleted
		print.line("Found #filesToDelete.len()# session file(s) to clean up:");
		print.line("");
		
		// Show summary instead of listing all files if there are many
		if (filesToDelete.len() > 20) {
			print.line("Summary by age:");
			var ageBuckets = {
				"< 1 hour": 0,
				"1-2 hours": 0,
				"2-24 hours": 0,
				"1-7 days": 0,
				"> 7 days": 0
			};
			
			for (var file in filesToDelete) {
				var ageInHours = file.age / 60;
				var ageInDays = ageInHours / 24;
				
				if (ageInHours < 1) {
					ageBuckets["< 1 hour"]++;
				} else if (ageInHours <= 2) {
					ageBuckets["1-2 hours"]++;
				} else if (ageInHours <= 24) {
					ageBuckets["2-24 hours"]++;
				} else if (ageInDays <= 7) {
					ageBuckets["1-7 days"]++;
				} else {
					ageBuckets["> 7 days"]++;
				}
			}
			
			var summaryTable = [];
			for (var bucket in ageBuckets) {
				if (ageBuckets[bucket] > 0) {
					summaryTable.append({
						"Age Range": bucket,
						"Count": ageBuckets[bucket]
					});
				}
			}
			
			print.table(
				data = summaryTable,
				headers = ["Age Range", "Count"]
			);
		} else {
			// Show individual files if not too many
			var table = [];
			for (var file in filesToDelete) {
				table.append({
					"File": file.name,
					"Age": formatAge(file.age),
					"Size": formatFileSize(file.size)
				});
			}
			
			print.table(
				data = table,
				headers = ["File", "Age", "Size"]
			);
		}
		
		print.line("");
		print.line("Total size to be freed: #formatFileSize(totalSize)#");
		print.line("");

		if (arguments.dryRun) {
			print.yellowLine("DRY RUN: No sessions were deleted.");
			return;
		}

		// Confirm deletion if not forced
		if (!arguments.force) {
			var proceed = confirm("Are you sure you want to delete these #filesToDelete.len()# session file(s)? [y/N]");
			if (!proceed) {
				print.line("Session cleanup cancelled.");
				return;
			}
		}

		// Delete files
		var deletedCount = 0;
		var deletedSize = 0;
		var errors = [];

		for (var file in filesToDelete) {
			try {
				fileDelete(file.path);
				deletedCount++;
				deletedSize += file.size;
			} catch (any e) {
				errors.append({
					file: file.name,
					error: e.message
				});
			}
		}

		// Report results
		print.line("");
		if (deletedCount > 0) {
			print.greenLine("✓ Successfully deleted #deletedCount# session file(s).");
			print.greenLine("✓ Freed #formatFileSize(deletedSize)# of disk space.");
		}
		
		if (errors.len() > 0) {
			print.line("");
			print.redLine("Failed to delete #errors.len()# file(s):");
			for (var error in errors) {
				print.indentedRedLine("- #error.file#: #error.error#");
			}
		}
	}

	/**
	 * Clean database sessions
	 */
	private function cleanDatabaseSessions(
		required string datasource,
		required string table,
		required boolean expiredOnly,
		required boolean dryRun,
		required boolean force
	) {
		if (!len(arguments.datasource)) {
			error("Datasource is required for database session cleanup.");
		}

		print.line("Cleaning database sessions from datasource: #arguments.datasource#");
		print.line("Table: #arguments.table#");
		print.line("");

		try {
			// Check if table exists
			var tables = queryExecute(
				"SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = :tableName",
				{tableName: arguments.table},
				{datasource: arguments.datasource}
			);
			
			if (tables.recordCount == 0) {
				print.yellowLine("Session table '#arguments.table#' does not exist.");
				return;
			}

			// Count sessions
			var countQuery = "SELECT COUNT(*) as total FROM #arguments.table#";
			var whereClause = "";
			
			if (arguments.expiredOnly) {
				// Assume expires column exists
				whereClause = " WHERE expires < :now";
			}
			
			var counts = queryExecute(
				countQuery & whereClause,
				arguments.expiredOnly ? {now: now()} : {},
				{datasource: arguments.datasource}
			);
			
			var totalSessions = counts.total;
			
			if (totalSessions == 0) {
				print.greenLine("No #arguments.expiredOnly ? 'expired ' : ''#sessions found to clean up.");
				return;
			}

			print.line("Found #totalSessions# #arguments.expiredOnly ? 'expired ' : ''#session(s) to clean up.");
			print.line("");

			if (arguments.dryRun) {
				print.yellowLine("DRY RUN: No sessions were deleted.");
				return;
			}

			// Confirm deletion if not forced
			if (!arguments.force) {
				var proceed = confirm("Are you sure you want to delete these #totalSessions# session(s)? [y/N]");
				if (!proceed) {
					print.line("Session cleanup cancelled.");
					return;
				}
			}

			// Delete sessions
			var deleteQuery = "DELETE FROM #arguments.table#" & whereClause;
			var result = queryExecute(
				deleteQuery,
				arguments.expiredOnly ? {now: now()} : {},
				{datasource: arguments.datasource, result: "result"}
			);
			
			print.line("");
			print.greenLine("✓ Successfully deleted #result.recordCount# session(s) from the database.");
			
		} catch (any e) {
			print.redLine("Error cleaning database sessions: #e.message#");
			if (structKeyExists(e, "detail")) {
				print.redLine("Detail: #e.detail#");
			}
		}
	}

	/**
	 * Format file size in human-readable format
	 */
	private function formatFileSize(numeric size) {
		if (arguments.size < 1024) {
			return "#arguments.size# B";
		} else if (arguments.size < 1024 * 1024) {
			return "#numberFormat(arguments.size / 1024, '0.0')# KB";
		} else if (arguments.size < 1024 * 1024 * 1024) {
			return "#numberFormat(arguments.size / (1024 * 1024), '0.0')# MB";
		} else {
			return "#numberFormat(arguments.size / (1024 * 1024 * 1024), '0.0')# GB";
		}
	}

	/**
	 * Format age in human-readable format
	 */
	private function formatAge(numeric minutes) {
		if (arguments.minutes < 60) {
			return "#arguments.minutes# min";
		} else if (arguments.minutes < 1440) {
			var hours = int(arguments.minutes / 60);
			return "#hours# hour#hours != 1 ? 's' : ''#";
		} else {
			var days = int(arguments.minutes / 1440);
			return "#days# day#days != 1 ? 's' : ''#";
		}
	}

}