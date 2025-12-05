/**
 * Remove all compiled assets
 * 
 * This command completely removes all compiled assets and the manifest file.
 * Use with caution as this will require full asset recompilation.
 * 
 * {code:bash}
 * wheels assets:clobber
 * wheels assets:clobber --force
 * {code}
 **/
component aliases="clobber" extends="../base" {

	property name="FileSystemUtil" inject="FileSystem";
	property name="detailOutput" inject="DetailOutputService@wheels-cli";
	
	/**
	 * Remove all compiled assets and reset the asset pipeline
	 * 
	 * This command completely removes all compiled assets and the manifest file.
	 * Use with caution as this will require full asset recompilation.
	 * 
	 * @force Skip confirmation prompt
	 **/
	function run(boolean force = false) {
		requireWheelsApp(getCWD());
		arguments = reconstructArgs(argStruct=arguments);
		var compiledDir = fileSystemUtil.resolvePath("public/assets/compiled");
		
		if (!directoryExists(compiledDir)) {
			print.yellowLine("No compiled assets directory found. Nothing to clobber.").toConsole();
			return;
		}
		
		// Count files to be deleted
		var files = directoryList(compiledDir, true, "query");
		var fileCount = 0;
		var totalSize = 0;
		
		for (var file in files) {
			if (file.type == "File") {
				fileCount++;
				totalSize += getFileInfo(file.directory & "/" & file.name).size;
			}
		}
		
		if (fileCount == 0) {
			print.yellowLine("No compiled assets found. Nothing to clobber.").toConsole();
			return;
		}
		
		detailOutput.line();
		detailOutput.statusWarning("This will permanently delete:");
		detailOutput.output("  - #fileCount# compiled asset files");
		detailOutput.output("  - #formatFileSize(totalSize)# of disk space");
		detailOutput.output("  - The asset manifest file");
		detailOutput.line();
		print.yellowLine("You will need to run 'wheels assets:precompile' to regenerate assets.").toConsole();
		detailOutput.line();
		
		// Confirm unless forced
		if (!arguments.force) {
			var confirmed = ask("Are you sure you want to delete all compiled assets? [y/N]: ");
			if (lCase(trim(confirmed)) != "y") {
				detailOutput.output("Operation cancelled.");
				return;
			}
		}
		
		detailOutput.line();
		print.boldLine("Removing compiled assets...").toConsole();
		
		try {
			// Delete all files and subdirectories
			directoryDelete(compiledDir, true);
			
			// Recreate empty directory
			directoryCreate(compiledDir);
			detailOutput.line();
			detailOutput.statusSuccess("Asset clobber complete!");
			print.greenLine("Deleted #fileCount# files").toConsole();
			print.greenLine("Freed #formatFileSize(totalSize)# of disk space").toConsole();
			detailOutput.line();
			print.yellowLine("Remember to run 'wheels assets:precompile' before deploying to production.").toConsole();
		} catch (any e) {
			detailOutput.statusFailed("Failed to clobber assets");
			detailOutput.error("Error removing compiled assets: #e.message#");
			return;
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