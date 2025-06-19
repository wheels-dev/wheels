/**
 * Clear temporary files
 **/
component extends="../base" {
	
	property name="FileSystemUtil" inject="FileSystem";
	
	/**
	 * Clear temporary files and directories
	 * 
	 * This command removes temporary files from the tmp directory,
	 * including cache files, session data, and other temporary content.
	 * 
	 * @type Type of temp files to clear (cache|sessions|uploads|all)
	 * @days Only clear files older than specified days
	 * @force Skip confirmation prompt
	 **/
	function run(
		string type = "all",
		numeric days = 0,
		boolean force = false
	) {
		if (!isWheelsApp()) {
			error("This command must be run from a Wheels application root directory.");
		}
		
		var validTypes = ["cache", "sessions", "uploads", "all"];
		
		if (!arrayContainsNoCase(validTypes, arguments.type)) {
			print.redLine("Invalid type: #arguments.type#");
			print.line("Valid options are: #arrayToList(validTypes, ', ')#");
			return;
		}
		
		print.boldGreenLine("==> Clearing temporary files...");
		print.line();
		
		var tmpDir = fileSystemUtil.resolvePath("tmp");
		
		if (!directoryExists(tmpDir)) {
			print.yellowLine("No tmp directory found. Nothing to clear.");
			return;
		}
		
		var results = [];
		var cutoffDate = (arguments.days > 0) ? dateAdd("d", -arguments.days, now()) : createDate(1900, 1, 1);
		
		// Clear specific type or all types
		if (arguments.type == "all" || arguments.type == "cache") {
			results.append(clearDirectory(
				path: tmpDir & "/cache",
				type: "cache",
				cutoffDate: cutoffDate,
				force: arguments.force
			));
		}
		
		if (arguments.type == "all" || arguments.type == "sessions") {
			results.append(clearDirectory(
				path: tmpDir & "/sessions",
				type: "sessions",
				cutoffDate: cutoffDate,
				force: arguments.force
			));
		}
		
		if (arguments.type == "all" || arguments.type == "uploads") {
			results.append(clearDirectory(
				path: tmpDir & "/uploads",
				type: "uploads",
				cutoffDate: cutoffDate,
				force: arguments.force
			));
		}
		
		// Also clear root tmp files if clearing all
		if (arguments.type == "all") {
			results.append(clearRootTmpFiles(
				path: tmpDir,
				cutoffDate: cutoffDate,
				force: arguments.force
			));
		}
		
		// Summary
		var totalFiles = 0;
		var totalSize = 0;
		
		for (var result in results) {
			totalFiles += result.fileCount;
			totalSize += result.freedSpace;
		}
		
		print.line();
		print.boldGreenLine("==> Temporary file clearing complete!");
		
		for (var result in results) {
			if (result.fileCount > 0) {
				print.greenLine("    ✓ #result.type#: #result.fileCount# files cleared (#formatFileSize(result.freedSpace)#)");
			} else if (result.skipped) {
				print.yellowLine("    ⚠ #result.type#: Skipped (cancelled by user)");
			} else {
				print.greyLine("    - #result.type#: No files to clear");
			}
		}
		
		if (totalFiles > 0) {
			print.line();
			print.boldLine("    Total: #totalFiles# files, #formatFileSize(totalSize)# freed");
		}
	}
	
	/**
	 * Clear a specific directory
	 */
	private struct function clearDirectory(
		required string path,
		required string type,
		required date cutoffDate,
		required boolean force
	) {
		var result = {
			type: arguments.type,
			fileCount: 0,
			freedSpace: 0,
			skipped: false
		};
		
		if (!directoryExists(arguments.path)) {
			return result;
		}
		
		// Get list of files to delete
		var files = directoryList(arguments.path, true, "query");
		var targetFiles = [];
		
		for (var file in files) {
			if (file.type == "File") {
				// Check age if days specified
				if (arguments.cutoffDate.year() > 1900) {
					if (dateCompare(file.dateLastModified, arguments.cutoffDate) < 0) {
						arrayAppend(targetFiles, file);
					}
				} else {
					arrayAppend(targetFiles, file);
				}
			}
		}
		
		if (arrayLen(targetFiles) == 0) {
			return result;
		}
		
		// Calculate total size
		var totalSize = 0;
		for (var file in targetFiles) {
			totalSize += getFileInfo(file.directory & "/" & file.name).size;
		}
		
		// Show what will be deleted and confirm if not forced
		if (!arguments.force && arrayLen(targetFiles) > 0) {
			print.line("Found #arrayLen(targetFiles)# #arguments.type# file(s) to clear (#formatFileSize(totalSize)#)");
			
			var confirmed = ask("Clear #arguments.type# files? [y/N]: ");
			if (lCase(trim(confirmed)) != "y") {
				result.skipped = true;
				return result;
			}
		}
		
		// Delete files
		for (var file in targetFiles) {
			try {
				var fileSize = getFileInfo(file.directory & "/" & file.name).size;
				fileDelete(file.directory & "/" & file.name);
				result.fileCount++;
				result.freedSpace += fileSize;
			} catch (any e) {
				// Continue on error
			}
		}
		
		// Clean up empty directories
		cleanEmptyDirectories(arguments.path);
		
		return result;
	}
	
	/**
	 * Clear files in root tmp directory (not in subdirectories)
	 */
	private struct function clearRootTmpFiles(
		required string path,
		required date cutoffDate,
		required boolean force
	) {
		var result = {
			type: "misc tmp files",
			fileCount: 0,
			freedSpace: 0,
			skipped: false
		};
		
		// Get only files in root tmp directory
		var files = directoryList(arguments.path, false, "query");
		var targetFiles = [];
		
		for (var file in files) {
			if (file.type == "File") {
				// Skip important files
				if (listFindNoCase(".gitkeep,.htaccess,web.config", file.name)) {
					continue;
				}
				
				// Check age if days specified
				if (arguments.cutoffDate.year() > 1900) {
					if (dateCompare(file.dateLastModified, arguments.cutoffDate) < 0) {
						arrayAppend(targetFiles, file);
					}
				} else {
					arrayAppend(targetFiles, file);
				}
			}
		}
		
		if (arrayLen(targetFiles) == 0) {
			return result;
		}
		
		// Calculate total size
		var totalSize = 0;
		for (var file in targetFiles) {
			totalSize += getFileInfo(file.directory & "/" & file.name).size;
		}
		
		// Show what will be deleted and confirm if not forced
		if (!arguments.force && arrayLen(targetFiles) > 0) {
			print.line("Found #arrayLen(targetFiles)# misc tmp file(s) to clear (#formatFileSize(totalSize)#)");
			
			var confirmed = ask("Clear misc tmp files? [y/N]: ");
			if (lCase(trim(confirmed)) != "y") {
				result.skipped = true;
				return result;
			}
		}
		
		// Delete files
		for (var file in targetFiles) {
			try {
				var fileSize = getFileInfo(file.directory & "/" & file.name).size;
				fileDelete(file.directory & "/" & file.name);
				result.fileCount++;
				result.freedSpace += fileSize;
			} catch (any e) {
				// Continue on error
			}
		}
		
		return result;
	}
	
	/**
	 * Clean up empty directories
	 */
	private void function cleanEmptyDirectories(required string path) {
		if (!directoryExists(arguments.path)) {
			return;
		}
		
		var dirs = directoryList(arguments.path, true, "query");
		
		// Sort by path length descending to process deepest directories first
		arraySort(dirs, function(a, b) {
			return len(b.directory) - len(a.directory);
		});
		
		for (var dir in dirs) {
			if (dir.type == "Dir") {
				var dirPath = dir.directory & "/" & dir.name;
				var contents = directoryList(dirPath, false, "query");
				
				if (contents.recordCount == 0) {
					try {
						directoryDelete(dirPath);
					} catch (any e) {
						// Ignore errors
					}
				}
			}
		}
	}
	
	/**
	 * Format file size in human-readable format
	 */
	private string function formatFileSize(required numeric bytes) {
		var units = ["B", "KB", "MB", "GB"];
		var size = arguments.bytes;
		var unitIndex = 1;
		
		while (size >= 1024 && unitIndex < arrayLen(units)) {
			size = size / 1024;
			unitIndex++;
		}
		
		if (unitIndex == 1) {
			return numberFormat(size, "0") & " " & units[unitIndex];
		} else {
			return numberFormat(size, "0.00") & " " & units[unitIndex];
		}
	}
	
}