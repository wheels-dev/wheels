/**
 * Clean up temporary files
 */
component extends="../base" {

	/**
	 * Remove old temporary files from the application
	 *
	 * @days Number of days to keep temporary files (default: 1)
	 * @directories Comma-separated list of directories to clean (default: tmp,temp,cache)
	 * @patterns Comma-separated list of file patterns to match (default: *,.*) 
	 * @excludePatterns Comma-separated list of patterns to exclude
	 * @dryRun Show what would be deleted without actually deleting
	 * @force Skip confirmation prompt
	 */
	function run(
		numeric days = 1,
		string directories = "tmp,temp,cache",
		string patterns = "*,.*",
		string excludePatterns = ".gitkeep,.gitignore",
		boolean dryRun = false,
		boolean force = false
	) {
		// Ensure we're in a Wheels app directory
		if (!directoryExists(fileSystemUtil.resolvePath("vendor/wheels"))) {
			error("This command must be run from a Wheels application root directory.");
		}

		// Parse directories
		var dirList = listToArray(arguments.directories);
		var patternList = listToArray(arguments.patterns);
		var excludeList = listToArray(arguments.excludePatterns);
		
		// Calculate cutoff date
		var cutoffDate = dateAdd("d", -arguments.days, now());
		
		print.line("Scanning for temporary files older than #arguments.days# day(s)...");
		print.line("Cutoff date: #dateFormat(cutoffDate, 'yyyy-mm-dd')# #timeFormat(cutoffDate, 'HH:mm:ss')#");
		print.line("");

		var filesToDelete = [];
		var totalSize = 0;
		var scannedDirs = [];

		// Scan each directory
		for (var dir in dirList) {
			var dirPath = fileSystemUtil.resolvePath(trim(dir));
			
			if (!directoryExists(dirPath)) {
				continue;
			}
			
			scannedDirs.append(dir);
			
			// Scan for each pattern
			for (var pattern in patternList) {
				try {
					var files = directoryList(
						path = dirPath,
						recurse = true,
						filter = trim(pattern),
						type = "file",
						listInfo = "query"
					);
					
					// Filter files by age and exclusions
					for (var file in files) {
						var fileName = file.name;
						var shouldExclude = false;
						
						// Check exclusions
						for (var exclude in excludeList) {
							if (fileName == trim(exclude) || reFindNoCase(trim(exclude), fileName)) {
								shouldExclude = true;
								break;
							}
						}
						
						if (!shouldExclude && file.dateLastModified < cutoffDate) {
							var fileInfo = {
								name: file.name,
								path: file.directory & "/" & file.name,
								relativePath: replaceNoCase(file.directory & "/" & file.name, getCWD() & "/", ""),
								size: file.size,
								modified: file.dateLastModified,
								age: dateDiff("d", file.dateLastModified, now()),
								directory: dir
							};
							filesToDelete.append(fileInfo);
							totalSize += file.size;
						}
					}
				} catch (any e) {
					// Continue with next pattern
				}
			}
		}

		if (scannedDirs.len() == 0) {
			print.yellowLine("No temporary directories found to scan.");
			return;
		}

		print.line("Scanned directories: #arrayToList(scannedDirs, ', ')#");
		print.line("");

		if (filesToDelete.len() == 0) {
			print.greenLine("No temporary files found older than #arguments.days# day(s).");
			return;
		}

		// Group files by directory for display
		var filesByDir = {};
		for (var file in filesToDelete) {
			if (!structKeyExists(filesByDir, file.directory)) {
				filesByDir[file.directory] = [];
			}
			filesByDir[file.directory].append(file);
		}

		// Display files to be deleted
		print.line("Found #filesToDelete.len()# temporary file(s) to clean up:");
		print.line("");
		
		for (var dir in filesByDir) {
			print.boldLine("#dir#/ (#filesByDir[dir].len()# files):");
			
			var table = [];
			for (var file in filesByDir[dir]) {
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
		}
		
		print.line("Total size to be freed: #formatFileSize(totalSize)#");
		print.line("");

		if (arguments.dryRun) {
			print.yellowLine("DRY RUN: No files were deleted.");
			return;
		}

		// Confirm deletion if not forced
		if (!arguments.force) {
			var proceed = confirm("Are you sure you want to delete these #filesToDelete.len()# temporary file(s)? [y/N]");
			if (!proceed) {
				print.line("Temporary file cleanup cancelled.");
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
					file: file.relativePath,
					error: e.message
				});
			}
		}

		// Report results
		print.line("");
		if (deletedCount > 0) {
			print.greenLine("✓ Successfully deleted #deletedCount# temporary file(s).");
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
		for (var dir in scannedDirs) {
			cleanEmptyDirectories(fileSystemUtil.resolvePath(dir));
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
	 * Clean up empty directories after file deletion
	 */
	private function cleanEmptyDirectories(required string directory) {
		if (!directoryExists(arguments.directory)) {
			return;
		}
		
		try {
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
		} catch (any e) {
			// Ignore errors
		}
	}

}