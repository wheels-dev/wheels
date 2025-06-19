/**
 * Tail log files
 **/
component extends="../base" {
	
	property name="FileSystemUtil" inject="FileSystem";
	
	/**
	 * Tail application log files in real-time
	 * 
	 * This command displays the last lines of a log file and optionally
	 * follows the file for new content (like Unix tail -f).
	 * 
	 * @environment Environment log to tail (development|testing|production)
	 * @lines Number of lines to display (default: 10)
	 * @follow Follow the log file for new content
	 * @file Specific log file name to tail
	 **/
	function run(
		string environment = "development",
		numeric lines = 10,
		boolean follow = false,
		string file = ""
	) {
		if (!isWheelsApp()) {
			error("This command must be run from a Wheels application root directory.");
		}
		
		var logsDir = fileSystemUtil.resolvePath("logs");
		
		if (!directoryExists(logsDir)) {
			print.yellowLine("No logs directory found.");
			return;
		}
		
		// Determine which log file to tail
		var logFile = "";
		
		if (len(arguments.file)) {
			// Specific file requested
			logFile = logsDir & "/" & arguments.file;
			if (!fileExists(logFile)) {
				// Try adding .log extension
				logFile = logsDir & "/" & arguments.file & ".log";
			}
		} else {
			// Use environment-based log file
			logFile = logsDir & "/" & arguments.environment & ".log";
		}
		
		if (!fileExists(logFile)) {
			print.redLine("Log file not found: #getFileFromPath(logFile)#");
			print.line();
			
			// Show available log files
			var availableLogs = directoryList(logsDir, false, "query", "*.log");
			if (availableLogs.recordCount > 0) {
				print.yellowLine("Available log files:");
				for (var log in availableLogs) {
					print.line("  - #log.name#");
				}
			} else {
				print.line("No log files found in logs directory.");
			}
			return;
		}
		
		print.boldGreenLine("==> Tailing: #getFileFromPath(logFile)#");
		print.line();
		
		if (arguments.follow) {
			print.yellowLine("Press Ctrl+C to stop following the log file.");
			print.line();
		}
		
		// Display the last N lines
		displayLastLines(logFile, arguments.lines);
		
		// Follow mode
		if (arguments.follow) {
			var lastPosition = getFileInfo(logFile).size;
			var checkInterval = 1000; // 1 second
			
			print.line();
			print.greyLine("==> Waiting for new content...");
			
			// Keep checking for new content
			while (true) {
				sleep(checkInterval);
				
				var currentSize = getFileInfo(logFile).size;
				
				if (currentSize > lastPosition) {
					// New content detected
					var fileHandle = fileOpen(logFile, "read");
					fileSeek(fileHandle, lastPosition);
					
					while (!fileIsEOF(fileHandle)) {
						var line = fileReadLine(fileHandle);
						// Color-code log levels
						if (findNoCase("[ERROR]", line) || findNoCase("ERROR:", line)) {
							print.redLine(line);
						} else if (findNoCase("[WARN]", line) || findNoCase("WARNING:", line)) {
							print.yellowLine(line);
						} else if (findNoCase("[INFO]", line) || findNoCase("INFO:", line)) {
							print.cyanLine(line);
						} else if (findNoCase("[DEBUG]", line) || findNoCase("DEBUG:", line)) {
							print.greyLine(line);
						} else {
							print.line(line);
						}
					}
					
					fileClose(fileHandle);
					lastPosition = currentSize;
				} else if (currentSize < lastPosition) {
					// File was truncated or rotated
					print.line();
					print.yellowLine("==> Log file was truncated or rotated. Starting from beginning...");
					lastPosition = 0;
				}
			}
		}
	}
	
	/**
	 * Display the last N lines of a file
	 */
	private void function displayLastLines(required string filePath, required numeric lines) {
		try {
			// Read file content
			var content = fileRead(arguments.filePath);
			var allLines = listToArray(content, chr(10));
			
			// Calculate starting line
			var startLine = max(1, arrayLen(allLines) - arguments.lines + 1);
			
			// Display lines with color coding
			for (var i = startLine; i <= arrayLen(allLines); i++) {
				var line = allLines[i];
				
				// Skip empty lines at the end
				if (i == arrayLen(allLines) && !len(trim(line))) {
					continue;
				}
				
				// Color-code based on log level
				if (findNoCase("[ERROR]", line) || findNoCase("ERROR:", line)) {
					print.redLine(line);
				} else if (findNoCase("[WARN]", line) || findNoCase("WARNING:", line)) {
					print.yellowLine(line);
				} else if (findNoCase("[INFO]", line) || findNoCase("INFO:", line)) {
					print.cyanLine(line);
				} else if (findNoCase("[DEBUG]", line) || findNoCase("DEBUG:", line)) {
					print.greyLine(line);
				} else {
					print.line(line);
				}
			}
		} catch (any e) {
			print.redLine("Error reading log file: #e.message#");
		}
	}
	
}