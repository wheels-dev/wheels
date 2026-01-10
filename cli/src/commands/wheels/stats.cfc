/**
 * Display code statistics for the Wheels application
 *
 * {code:bash}
 * wheels stats
 * wheels stats verbose=true
 * {code}
 */
component extends="base" {

	/**
	 * @verbose Show detailed statistics
	 * @help Display comprehensive code statistics for the application
	 */
	public void function run(boolean verbose = false) {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}
		
		print.line();
		print.boldGreenLine("Code Statistics");
		print.line(RepeatString("=", 70));
		
		// Collect statistics
		local.stats = {
			controllers = analyzeDirectory(local.appPath & "/app/controllers", "*.cfc"),
			models = analyzeDirectory(local.appPath & "/app/models", "*.cfc"),
			views = analyzeDirectory(local.appPath & "/app/views", "*.cfm"),
			helpers = analyzeDirectory(local.appPath & "/app/helpers", "*.cfc"),
			tests = analyzeDirectory(local.appPath & "/tests", "*.cfc"),
			migrations = analyzeDirectory(local.appPath & "/db/migrate", "*.cfc"),
			config = analyzeDirectory(local.appPath & "/config", "*.cfm,*.cfc"),
			javascripts = analyzeDirectory(local.appPath & "/public/javascripts", "*.js"),
			stylesheets = analyzeDirectory(local.appPath & "/public/stylesheets", "*.css,*.scss,*.sass")
		};
		
		// Display header
		print.text(PadRight("Type", 20));
		print.text(PadRight("Files", 10));
		print.text(PadRight("Lines", 10));
		print.text(PadRight("LOC", 10));
		print.text(PadRight("Comments", 10));
		print.line(PadRight("Blank", 10));
		print.line(RepeatString("-", 70));
		
		// Display stats for each type
		local.totals = {
			files = 0,
			lines = 0,
			loc = 0,
			comments = 0,
			blank = 0
		};
		
		for (local.type in ["controllers", "models", "views", "helpers", "tests", "migrations", "config", "javascripts", "stylesheets"]) {
			if (local.stats[local.type].files > 0) {
				displayStatRow(local.type, local.stats[local.type]);
				
				// Add to totals
				local.totals.files += local.stats[local.type].files;
				local.totals.lines += local.stats[local.type].lines;
				local.totals.loc += local.stats[local.type].loc;
				local.totals.comments += local.stats[local.type].comments;
				local.totals.blank += local.stats[local.type].blank;
			}
		}
		
		// Display totals
		print.line(RepeatString("-", 70));
		displayStatRow("Total", local.totals);
		print.line();
		
		// Display additional metrics
		print.boldGreenLine("Code Metrics");
		print.line(RepeatString("=", 70));
		
		// Code to test ratio
		if (local.stats.tests.loc > 0) {
			local.codeLines = local.stats.controllers.loc + local.stats.models.loc + local.stats.helpers.loc;
			local.testRatio = Round(local.stats.tests.loc / local.codeLines * 100);
			print.greenLine("Code to Test Ratio: 1:" & NumberFormat(local.stats.tests.loc / local.codeLines, "0.0") & " (" & local.testRatio & "% test coverage by LOC)");
		} else {
			print.yellowLine("Code to Test Ratio: No tests found");
		}
		
		// Average file sizes
		if (local.totals.files > 0) {
			print.greenLine("Average Lines per File: " & Round(local.totals.lines / local.totals.files));
			print.greenLine("Average LOC per File: " & Round(local.totals.loc / local.totals.files));
		}
		
		// Comment percentage
		if (local.totals.loc > 0) {
			local.commentPercentage = Round(local.totals.comments / (local.totals.loc + local.totals.comments) * 100);
			print.greenLine("Comment Percentage: " & local.commentPercentage & "%");
		}
		
		// Verbose output
		if (arguments.verbose) {
			print.line();
			print.boldGreenLine("Detailed File Analysis");
			print.line(RepeatString("=", 70));
			
			// Show largest files
			local.allFiles = [];
			for (local.type in local.stats) {
				if (IsArray(local.stats[local.type].fileDetails)) {
					ArrayAppend(local.allFiles, local.stats[local.type].fileDetails, true);
				}
			}
			
			// Sort by LOC descending
			ArraySort(local.allFiles, function(a, b) {
				return b.loc - a.loc;
			});
			
			print.boldLine("Largest Files (by LOC):");
			for (local.i = 1; local.i <= Min(10, ArrayLen(local.allFiles)); local.i++) {
				local.file = local.allFiles[local.i];
				local.relativePath = Replace(local.file.path, local.appPath & "/", "");
				print.line("  " & local.i & ". " & local.relativePath & " (" & local.file.loc & " LOC)");
			}
		}
		
		print.line();
	}

	private struct function analyzeDirectory(required string path, required string filter) {
		local.result = {
			files = 0,
			lines = 0,
			loc = 0,
			comments = 0,
			blank = 0,
			fileDetails = []
		};
		
		if (!DirectoryExists(arguments.path)) {
			return local.result;
		}
		
		try {
			// Get all files matching the filter
			local.filters = ListToArray(arguments.filter);
			local.files = [];
			
			for (local.filter in local.filters) {
				local.matchingFiles = DirectoryList(arguments.path, true, "path", local.filter);
				ArrayAppend(local.files, local.matchingFiles, true);
			}
			
			// Analyze each file
			for (local.file in local.files) {
				local.fileStats = analyzeFile(local.file);
				
				local.result.files++;
				local.result.lines += local.fileStats.lines;
				local.result.loc += local.fileStats.loc;
				local.result.comments += local.fileStats.comments;
				local.result.blank += local.fileStats.blank;
				
				// Store file details
				ArrayAppend(local.result.fileDetails, {
					path = local.file,
					lines = local.fileStats.lines,
					loc = local.fileStats.loc,
					comments = local.fileStats.comments,
					blank = local.fileStats.blank
				});
			}
			
		} catch (any e) {
			// Continue with what we have
		}
		
		return local.result;
	}

	private struct function analyzeFile(required string filePath) {
		local.result = {
			lines = 0,
			loc = 0,
			comments = 0,
			blank = 0
		};
		
		try {
			local.content = FileRead(arguments.filePath);
			local.lines = ListToArray(local.content, Chr(10));
			local.result.lines = ArrayLen(local.lines);
			
			local.inBlockComment = false;
			local.fileExt = ListLast(arguments.filePath, ".");
			
			for (local.line in local.lines) {
				local.trimmedLine = Trim(local.line);
				
				// Check for blank lines
				if (!Len(local.trimmedLine)) {
					local.result.blank++;
					continue;
				}
				
				// Check for comments based on file type
				if (fileExt == "cfc" || fileExt == "cfm") {
					// CFML comments
					if (Find("<!---", local.trimmedLine)) {
						local.inBlockComment = true;
					}
					
					if (local.inBlockComment || Left(local.trimmedLine, 2) == "//") {
						local.result.comments++;
					} else {
						local.result.loc++;
					}
					
					if (Find("--->", local.trimmedLine)) {
						local.inBlockComment = false;
					}
				} else if (fileExt == "js") {
					// JavaScript comments
					if (Find("/*", local.trimmedLine)) {
						local.inBlockComment = true;
					}
					
					if (local.inBlockComment || Left(local.trimmedLine, 2) == "//") {
						local.result.comments++;
					} else {
						local.result.loc++;
					}
					
					if (Find("*/", local.trimmedLine)) {
						local.inBlockComment = false;
					}
				} else if (fileExt == "css" || fileExt == "scss" || fileExt == "sass") {
					// CSS comments
					if (Find("/*", local.trimmedLine)) {
						local.inBlockComment = true;
					}
					
					if (local.inBlockComment) {
						local.result.comments++;
					} else {
						local.result.loc++;
					}
					
					if (Find("*/", local.trimmedLine)) {
						local.inBlockComment = false;
					}
				} else {
					// Default: count as code
					local.result.loc++;
				}
			}
			
		} catch (any e) {
			// Continue with zeros
		}
		
		return local.result;
	}

	private void function displayStatRow(required string type, required struct stats) {
		print.text(PadRight(UCase(Left(arguments.type, 1)) & Right(arguments.type, Len(arguments.type) - 1), 20));
		print.text(PadRight(arguments.stats.files, 10));
		print.text(PadRight(arguments.stats.lines, 10));
		print.text(PadRight(arguments.stats.loc, 10));
		print.text(PadRight(arguments.stats.comments, 10));
		print.line(PadRight(arguments.stats.blank, 10));
	}

	private string function PadRight(required any text, required numeric width) {
		local.str = ToString(arguments.text);
		if (Len(local.str) >= arguments.width) {
			return local.str;
		}
		return local.str & RepeatString(" ", arguments.width - Len(local.str));
	}

}