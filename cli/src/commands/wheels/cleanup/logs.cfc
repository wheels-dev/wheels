/**
 * Clean up old log files
 */
component extends="../base" {

	/**
	 * Remove old log files from the application
	 *
	 * @days Number of days to keep logs (default: 7)
	 * @pattern File pattern to match (default: *.log)
	 * @directory Custom log directory (default: logs/)
	 * @dryRun Show what would be deleted without actually deleting
	 * @force Skip confirmation prompt
	 */
	function run(
		numeric days = 7,
		string pattern = "*.log",
		string directory = "logs",
		boolean dryRun = false,
		boolean force = false
	) {
		// Ensure we're in a Wheels app directory
		if (!isWheelsApp()) {
			error("This command must be run from a Wheels application root directory.");
		}

		// Resolve log directory
		var logDir = fileSystemUtil.resolvePath(arguments.directory);
		
		if (!directoryExists(logDir)) {
			print.yellowLine("Log directory '#arguments.directory#' does not exist.");
			return;
		}

		// Calculate cutoff date
		var cutoffDate = dateAdd("d", -arguments.days, now());
		
		print.line("Scanning for log files older than #arguments.days# days...");
		print.line("Cutoff date: #dateFormat(cutoffDate, 'yyyy-mm-dd')# #timeFormat(cutoffDate, 'HH:mm:ss')#");
		print.line("");

		// Get list of log files
		var files = directoryList(
			path = logDir,
			recurse = true,
			filter = arguments.pattern,
			type = "file",
			listInfo = "query"
		);

		var filesToDelete = [];
		var totalSize = 0;

		// Filter files by age
		for (var file in files) {
			if (file.dateLastModified < cutoffDate) {
				var fileInfo = {
					name: file.name,
					path: file.directory & "/" & file.name,
					size: file.size,
					modified: file.dateLastModified,
					age: dateDiff("d", file.dateLastModified, now())
				};
				filesToDelete.append(fileInfo);
				totalSize += file.size;
			}
		}

		if (filesToDelete.len() == 0) {
			print.greenLine("No log files found older than #arguments.days# days.");
			return;
		}

		// Display files to be deleted
		print.line("Found #filesToDelete.len()# log file(s) to clean up:");
		print.line("");
		
		var table = [];
		for (var file in filesToDelete) {
			table.append({
				"File": file.name,
				"Age": "#file.age# days",
				"Size": formatFileSize(file.size),
				"Modified": dateFormat(file.modified, "yyyy-mm-dd HH:mm")
			});
		}
		
		print.table(
			data = table,
			headers = ["File", "Age", "Size", "Modified"]
		);
		
		print.line("");
		print.line("Total size to be freed: #formatFileSize(totalSize)#");
		print.line("");

		if (arguments.dryRun) {
			print.yellowLine("DRY RUN: No files were deleted.");
			return;
		}

		// Confirm deletion if not forced
		if (!arguments.force) {
			var proceed = confirm("Are you sure you want to delete these #filesToDelete.len()# log file(s)? [y/N]");
			if (!proceed) {
				print.line("Log cleanup cancelled.");
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
			print.greenLine("✓ Successfully deleted #deletedCount# log file(s).");
			print.greenLine("✓ Freed #formatFileSize(deletedSize)# of disk space.");
		}
		
		if (errors.len() > 0) {
			print.line("");
			print.redLine("Failed to delete #errors.len()# file(s):");
			for (var error in errors) {
				print.indentedRedLine("- #error.file#: #error.error#");
			}
		}

		// Clean up empty directories
		cleanEmptyDirectories(logDir);
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
	 * Clean up empty directories after file deletion
	 */
	private function cleanEmptyDirectories(required string directory) {
		var dirs = directoryList(
			path = arguments.directory,
			recurse = true,
			type = "dir",
			listInfo = "path"
		);
		
		// Sort directories by depth (deepest first)
		dirs.sort(function(a, b) {
			return listLen(b, "/\") - listLen(a, "/\");
		});
		
		var removedCount = 0;
		for (var dir in dirs) {
			try {
				var contents = directoryList(dir);
				if (contents.len() == 0) {
					directoryDelete(dir);
					removedCount++;
				}
			} catch (any e) {
				// Ignore errors
			}
		}
		
		if (removedCount > 0) {
			print.line("");
			print.greenLine("✓ Removed #removedCount# empty director#removedCount == 1 ? 'y' : 'ies'#.");
		}
	}

}