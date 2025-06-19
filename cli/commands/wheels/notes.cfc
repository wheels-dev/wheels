/**
 * Extract and display code annotations (TODO, FIXME, OPTIMIZE, etc.)
 *
 * {code:bash}
 * wheels notes
 * wheels notes TODO
 * wheels notes TODO,FIXME
 * wheels notes custom=HACK,REVIEW
 * {code}
 */
component extends="base" {

	/**
	 * @annotations Comma-separated list of annotations to search for (default: TODO,FIXME,OPTIMIZE)
	 * @custom Additional custom annotations to search for
	 * @verbose Show file paths with line numbers
	 * @help Extract and display code annotations from your application
	 */
	public void function run(
		string annotations = "TODO,FIXME,OPTIMIZE",
		string custom = "",
		boolean verbose = false
	) {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}
		
		// Build list of annotations to search for
		local.searchAnnotations = ListToArray(arguments.annotations);
		if (Len(arguments.custom)) {
			local.customAnnotations = ListToArray(arguments.custom);
			ArrayAppend(local.searchAnnotations, local.customAnnotations, true);
		}
		
		print.line();
		print.boldGreenLine("Code Annotations");
		print.greenLine("Searching for: " & ArrayToList(local.searchAnnotations, ", "));
		print.line(RepeatString("=", 70));
		
		// Directories to search
		local.searchDirs = [
			{path: local.appPath & "/app", label: "Application"},
			{path: local.appPath & "/config", label: "Configuration"},
			{path: local.appPath & "/tests", label: "Tests"},
			{path: local.appPath & "/db/migrate", label: "Migrations"}
		];
		
		local.totalAnnotations = 0;
		local.annotationsByType = {};
		
		// Initialize counters
		for (local.annotation in local.searchAnnotations) {
			local.annotationsByType[local.annotation] = 0;
		}
		
		// Search each directory
		for (local.searchDir in local.searchDirs) {
			if (DirectoryExists(local.searchDir.path)) {
				local.annotations = findAnnotations(
					local.searchDir.path,
					local.searchAnnotations,
					arguments.verbose
				);
				
				if (ArrayLen(local.annotations)) {
					print.line();
					print.boldYellowLine(local.searchDir.label & ":");
					
					for (local.annotation in local.annotations) {
						local.totalAnnotations++;
						local.annotationsByType[local.annotation.type]++;
						
						if (arguments.verbose) {
							print.line();
							print.cyanLine("  " & local.annotation.file & ":" & local.annotation.line);
							print.line("  " & local.annotation.type & ": " & local.annotation.text);
						} else {
							print.line("  [" & local.annotation.type & "] " & local.annotation.text);
						}
					}
				}
			}
		}
		
		// Display summary
		print.line();
		print.line(RepeatString("=", 70));
		print.boldGreenLine("Summary:");
		
		if (local.totalAnnotations == 0) {
			print.greenLine("No annotations found!");
		} else {
			for (local.type in local.searchAnnotations) {
				if (local.annotationsByType[local.type] > 0) {
					print.greenLine("  " & local.type & ": " & local.annotationsByType[local.type]);
				}
			}
			print.line();
			print.greenLine("Total annotations: " & local.totalAnnotations);
		}
		
		print.line();
	}

	private array function findAnnotations(
		required string path,
		required array annotations,
		required boolean verbose
	) {
		local.results = [];
		
		try {
			// Search for CFML files
			local.cfmlFiles = DirectoryList(arguments.path, true, "path", "*.cfc,*.cfm");
			
			for (local.file in local.cfmlFiles) {
				local.fileAnnotations = extractAnnotationsFromFile(
					local.file,
					arguments.annotations,
					arguments.verbose
				);
				ArrayAppend(local.results, local.fileAnnotations, true);
			}
			
			// Search for JavaScript files
			local.jsFiles = DirectoryList(arguments.path, true, "path", "*.js");
			
			for (local.file in local.jsFiles) {
				local.fileAnnotations = extractAnnotationsFromFile(
					local.file,
					arguments.annotations,
					arguments.verbose
				);
				ArrayAppend(local.results, local.fileAnnotations, true);
			}
			
			// Search for CSS files
			local.cssFiles = DirectoryList(arguments.path, true, "path", "*.css,*.scss,*.sass");
			
			for (local.file in local.cssFiles) {
				local.fileAnnotations = extractAnnotationsFromFile(
					local.file,
					arguments.annotations,
					arguments.verbose
				);
				ArrayAppend(local.results, local.fileAnnotations, true);
			}
			
		} catch (any e) {
			// Continue with what we have
		}
		
		return local.results;
	}

	private array function extractAnnotationsFromFile(
		required string filePath,
		required array annotations,
		required boolean verbose
	) {
		local.results = [];
		
		try {
			local.content = FileRead(arguments.filePath);
			local.lines = ListToArray(local.content, Chr(10));
			local.lineNumber = 0;
			
			for (local.line in local.lines) {
				local.lineNumber++;
				
				// Check each annotation type
				for (local.annotation in arguments.annotations) {
					// Look for annotation in various comment formats
					local.patterns = [
						"//\s*#local.annotation#:?\s*(.+)",
						"<!---\s*#local.annotation#:?\s*(.+?)\s*--->",
						"/\*\s*#local.annotation#:?\s*(.+?)\s*\*/",
						"##\s*#local.annotation#:?\s*(.+)"
					];
					
					for (local.pattern in local.patterns) {
						local.matches = REMatchNoCase(local.pattern, local.line);
						if (ArrayLen(local.matches)) {
							// Extract the annotation text
							local.text = Trim(REReplace(local.matches[1], local.pattern, "\1"));
							
							// Clean up the text
							local.text = Replace(local.text, "--->", "");
							local.text = Replace(local.text, "*/", "");
							local.text = Trim(local.text);
							
							if (Len(local.text)) {
								local.relativePath = Replace(arguments.filePath, getCWD() & "/", "");
								
								ArrayAppend(local.results, {
									file = local.relativePath,
									line = local.lineNumber,
									type = local.annotation,
									text = local.text
								});
								
								break; // Don't match same line multiple times
							}
						}
					}
				}
			}
			
		} catch (any e) {
			// Continue
		}
		
		return local.results;
	}

}