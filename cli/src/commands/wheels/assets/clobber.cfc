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
component extends="../base" {
	
	property name="FileSystemUtil" inject="FileSystem";
	
	// CommandBox metadata
	this.aliases = [ "clobber" ];
	this.parameters = [
		{ name="force", type="boolean", required=false, default=false, hint="Skip confirmation prompt" }
	];
	
	/**
	 * Remove all compiled assets and reset the asset pipeline
	 * 
	 * This command completely removes all compiled assets and the manifest file.
	 * Use with caution as this will require full asset recompilation.
	 * 
	 * @force Skip confirmation prompt
	 **/
	function run(boolean force = false) {
		if (!isWheelsApp()) {
			error("This command must be run from a Wheels application root directory.");
		}
		
		// var compiledDir = fileSystemUtil.resolvePath("public/assets/compiled");
		var compiledDir = fileSystemUtil.resolvePath("templates/base/src/public/assets/compiled");
		
		if (!directoryExists(compiledDir)) {
			print.yellowLine("No compiled assets directory found. Nothing to clobber.");
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
			print.yellowLine("No compiled assets found. Nothing to clobber.");
			return;
		}
		
		print.boldRedLine("==> WARNING: Asset Clobber");
		print.line();
		print.line("This will permanently delete:");
		print.line("  - #fileCount# compiled asset files");
		print.line("  - #formatFileSize(totalSize)# of disk space");
		print.line("  - The asset manifest file");
		print.line();
		print.yellowLine("You will need to run 'wheels assets:precompile' to regenerate assets.");
		print.line();
		
		// Confirm unless forced
		if (!arguments.force) {
			var confirmed = ask("Are you sure you want to delete all compiled assets? [y/N]: ");
			if (lCase(trim(confirmed)) != "y") {
				print.line("Operation cancelled.");
				return;
			}
		}
		
		print.line();
		print.boldLine("Removing compiled assets...");
		
		try {
			// Delete all files and subdirectories
			directoryDelete(compiledDir, true);
			
			// Recreate empty directory
			directoryCreate(compiledDir);
			
			print.line();
			print.boldGreenLine("==> Asset clobber complete!");
			print.greenLine("    Deleted #fileCount# files");
			print.greenLine("    Freed #formatFileSize(totalSize)# of disk space");
			print.line();
			print.yellowLine("Remember to run 'wheels assets:precompile' before deploying to production.");
		} catch (any e) {
			print.redLine("Error removing compiled assets: #e.message#");
			error("Failed to clobber assets");
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