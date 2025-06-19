/**
 * Base specification for testing CLI commands
 * Provides common functionality for CLI command testing
 */
component extends="tests.BaseSpec" {
	
	/**
	 * Initialize test environment for CLI commands
	 */
	function beforeEach() {
		// Create temporary directory for test files
		variables.tempDir = getTempDirectory() & "wheels_cli_test_" & createUUID() & "/";
		directoryCreate(variables.tempDir);
		
		// Mock print buffer to capture command output
		variables.printBuffer = [];
		
		// Store original working directory
		variables.originalWorkingDir = getCurrentDirectory();
		
		// Change to temp directory
		directorySet(variables.tempDir);
	}
	
	/**
	 * Clean up test environment
	 */
	function afterEach() {
		// Restore original working directory
		directorySet(variables.originalWorkingDir);
		
		// Clean up temporary directory
		if (directoryExists(variables.tempDir)) {
			directoryDelete(variables.tempDir, true);
		}
		
		// Clear print buffer
		variables.printBuffer = [];
	}
	
	/**
	 * Mock print function to capture command output
	 * @message The message to print
	 */
	private function mockPrint(required string message) {
		arrayAppend(variables.printBuffer, arguments.message);
	}
	
	/**
	 * Get all printed output as a single string
	 * @return Concatenated print output
	 */
	private string function getPrintOutput() {
		return arrayToList(variables.printBuffer, chr(10));
	}
	
	/**
	 * Get all printed output as an array
	 * @return Array of printed lines
	 */
	private array function getPrintLines() {
		return variables.printBuffer;
	}
	
	/**
	 * Clear the print buffer
	 */
	private void function clearPrintBuffer() {
		variables.printBuffer = [];
	}
	
	/**
	 * Create a mock command instance with print interception
	 * @commandPath The path to the command CFC
	 * @return The mocked command instance
	 */
	private any function createMockCommand(required string commandPath) {
		var command = createObject("component", arguments.commandPath);
		
		// Override print method if it exists
		if (structKeyExists(command, "print")) {
			command.print = mockPrint;
		}
		
		// Override error method if it exists
		if (structKeyExists(command, "error")) {
			command.error = mockPrint;
		}
		
		// Override success method if it exists
		if (structKeyExists(command, "success")) {
			command.success = mockPrint;
		}
		
		return command;
	}
	
	/**
	 * Create a test file with content
	 * @fileName The name of the file to create
	 * @content The content to write to the file
	 * @return The full path to the created file
	 */
	private string function createTestFile(required string fileName, required string content) {
		var filePath = variables.tempDir & arguments.fileName;
		fileWrite(filePath, arguments.content);
		return filePath;
	}
	
	/**
	 * Create a test directory structure
	 * @structure An array of paths to create
	 */
	private void function createDirectoryStructure(required array structure) {
		for (var path in arguments.structure) {
			var fullPath = variables.tempDir & path;
			directoryCreate(fullPath, true);
		}
	}
	
	/**
	 * Assert that a file exists with optional content check
	 * @filePath The path to the file (relative to temp dir)
	 * @expectedContent Optional content to verify
	 */
	private void function assertFileExists(required string filePath, string expectedContent) {
		var fullPath = variables.tempDir & arguments.filePath;
		expect(fileExists(fullPath)).toBeTrue("File should exist: #arguments.filePath#");
		
		if (structKeyExists(arguments, "expectedContent")) {
			var actualContent = fileRead(fullPath);
			if (isSimpleValue(arguments.expectedContent)) {
				expect(actualContent).toInclude(arguments.expectedContent);
			}
		}
	}
	
	/**
	 * Assert that a directory exists
	 * @dirPath The path to the directory (relative to temp dir)
	 */
	private void function assertDirectoryExists(required string dirPath) {
		var fullPath = variables.tempDir & arguments.dirPath;
		expect(directoryExists(fullPath)).toBeTrue("Directory should exist: #arguments.dirPath#");
	}
	
	/**
	 * Assert that the print output contains a specific string
	 * @expectedString The string to look for in the output
	 */
	private void function assertOutputContains(required string expectedString) {
		var output = getPrintOutput();
		expect(output).toInclude(arguments.expectedString, "Output should contain: #arguments.expectedString#");
	}
	
	/**
	 * Assert that the print output matches a pattern
	 * @pattern The regex pattern to match
	 */
	private void function assertOutputMatches(required string pattern) {
		var output = getPrintOutput();
		expect(reFindNoCase(arguments.pattern, output)).toBeGT(0, "Output should match pattern: #arguments.pattern#");
	}
	
	/**
	 * Get the content of a generated file
	 * @filePath The path to the file (relative to temp dir)
	 * @return The file content
	 */
	private string function getFileContent(required string filePath) {
		var fullPath = variables.tempDir & arguments.filePath;
		if (fileExists(fullPath)) {
			return fileRead(fullPath);
		}
		return "";
	}
	
	/**
	 * Create a mock database schema for testing
	 * @tables Array of table definitions
	 */
	private void function createMockSchema(required array tables) {
		// This would be implemented based on your database testing setup
		// For now, it's a placeholder for database-aware command tests
	}
	
}