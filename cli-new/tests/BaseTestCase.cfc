/**
 * Base test case for Wheels CLI tests
 * Provides common functionality for testing CLI commands
 */
component extends="testbox.system.BaseSpec" {
    
    // Test helpers
    property name="tempDir" type="string";
    property name="originalCWD" type="string";
    property name="mockPrint" type="struct";
    property name="mockFileSystem" type="struct";
    property name="capturedOutput" type="array";
    property name="mockInputs" type="array";
    property name="mockInputIndex" type="numeric";
    
    /**
     * Run before all tests
     */
    function beforeAll() {
        // Store original working directory
        variables.originalCWD = expandPath(".");
        
        // Initialize arrays
        variables.capturedOutput = [];
        variables.mockInputs = [];
        variables.mockInputIndex = 0;
    }
    
    /**
     * Run after all tests
     */
    function afterAll() {
        // Restore original working directory
        if (len(variables.originalCWD)) {
            directoryChange(variables.originalCWD);
        }
    }
    
    /**
     * Run before each test
     */
    function beforeEach() {
        // Create temporary directory for test
        variables.tempDir = getTempDirectory() & "wheels_cli_test_" & createUUID() & "/";
        directoryCreate(variables.tempDir);
        
        // Clear captured output
        variables.capturedOutput = [];
        variables.mockInputs = [];
        variables.mockInputIndex = 0;
        
        // Set up mocks
        setupMocks();
    }
    
    /**
     * Run after each test
     */
    function afterEach() {
        // Clean up temporary directory
        if (directoryExists(variables.tempDir)) {
            directoryDelete(variables.tempDir, true);
        }
        
        // Restore mocks
        restoreMocks();
    }
    
    /**
     * Execute a CLI command and capture results
     */
    function executeCommand(
        required string command,
        struct params = {},
        string workingDirectory = variables.tempDir
    ) {
        var result = {
            success = true,
            output = [],
            exitCode = 0,
            error = ""
        };
        
        try {
            // Change to working directory
            directoryChange(arguments.workingDirectory);
            
            // Parse command
            var commandParts = listToArray(arguments.command, " ");
            var commandPath = "commands.wheels." & arrayToList(commandParts, ".");
            
            // Get command component
            var commandComponent = createObject("component", commandPath);
            
            // Inject mocks
            injectMocks(commandComponent);
            
            // Clear output
            variables.capturedOutput = [];
            
            // Execute command
            var commandResult = commandComponent.run(argumentCollection = arguments.params);
            
            // Capture results
            result.output = duplicate(variables.capturedOutput);
            
            if (isStruct(commandResult)) {
                result.data = commandResult;
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e;
            result.exitCode = 1;
        } finally {
            // Change back to original directory
            directoryChange(variables.originalCWD);
        }
        
        return result;
    }
    
    /**
     * Set up mock objects
     */
    private function setupMocks() {
        // Mock print buffer
        variables.mockPrint = {
            line = mockPrintLine,
            text = mockPrintText,
            greenLine = mockPrintLine,
            redLine = mockPrintLine,
            yellowLine = mockPrintLine,
            blueLine = mockPrintLine,
            boldLine = mockPrintLine,
            greenBoldLine = mockPrintLine,
            redBoldLine = mockPrintLine,
            yellowBoldLine = mockPrintLine,
            boldBlueLine = mockPrintLine,
            greyLine = mockPrintLine,
            indentedLine = mockPrintIndentedLine,
            greenText = mockPrintText,
            redText = mockPrintText,
            yellowText = mockPrintText,
            blueText = mockPrintText,
            boldText = mockPrintText,
            toConsole = mockPrintToConsole,
            clear = mockPrintClear
        };
        
        // Mock file system utilities
        variables.mockFileSystem = createMockFileSystem();
    }
    
    /**
     * Restore original functionality
     */
    private function restoreMocks() {
        // Cleanup
    }
    
    /**
     * Inject mocks into command component
     */
    private function injectMocks(required component command) {
        // Inject print mock
        arguments.command.print = variables.mockPrint;
        
        // Override shell methods
        arguments.command.getCWD = function() {
            return variables.tempDir;
        };
        
        arguments.command.ask = function(required string message, string defaultResponse = "") {
            return getMockInput(arguments.message, arguments.defaultResponse);
        };
        
        arguments.command.confirm = function(required string message, boolean defaultValue = false) {
            var input = getMockInput(arguments.message, arguments.defaultValue ? "y" : "n");
            return listFindNoCase("y,yes,true,1", input) > 0;
        };
        
        arguments.command.command = function(required string command) {
            return createMockCommandBuilder(arguments.command);
        };
        
        // Override error method to throw catchable exception
        arguments.command.error = function(required string message, string detail = "", numeric exitCode = 1) {
            throw(type="CommandError", message=arguments.message, detail=arguments.detail);
        };
        
        // Mock the runCommand wrapper to not use interceptors
        if (structKeyExists(arguments.command, "runCommand")) {
            var originalRunCommand = arguments.command.runCommand;
            arguments.command.runCommand = function(required function commandFunction, struct args = {}) {
                // Just execute the function directly without interceptor logic
                return arguments.commandFunction(argumentCollection = arguments.args);
            };
        }
    }
    
    /**
     * Mock print line function
     */
    private function mockPrintLine(string text = "") {
        arrayAppend(variables.capturedOutput, arguments.text);
        return this;
    }
    
    /**
     * Mock print text function
     */
    private function mockPrintText(string text = "") {
        if (arrayLen(variables.capturedOutput)) {
            variables.capturedOutput[arrayLen(variables.capturedOutput)] &= arguments.text;
        } else {
            arrayAppend(variables.capturedOutput, arguments.text);
        }
        return this;
    }
    
    /**
     * Mock print indented line
     */
    private function mockPrintIndentedLine(string text = "", numeric indent = 1) {
        var indentation = repeatString("    ", arguments.indent);
        arrayAppend(variables.capturedOutput, indentation & arguments.text);
        return this;
    }
    
    /**
     * Mock print to console
     */
    private function mockPrintToConsole() {
        return this;
    }
    
    /**
     * Mock print clear
     */
    private function mockPrintClear() {
        variables.capturedOutput = [];
        return this;
    }
    
    /**
     * Create mock file system
     */
    private function createMockFileSystem() {
        return {
            createDirectory = function(required string path, boolean createPath = false) {
                directoryCreate(arguments.path, arguments.createPath);
            },
            directoryExists = function(required string path) {
                return directoryExists(arguments.path);
            },
            fileExists = function(required string path) {
                return fileExists(arguments.path);
            },
            fileWrite = function(required string path, required any data) {
                fileWrite(arguments.path, arguments.data);
            },
            fileRead = function(required string path) {
                return fileRead(arguments.path);
            },
            fileCopy = function(required string source, required string destination) {
                fileCopy(arguments.source, arguments.destination);
            },
            fileDelete = function(required string path) {
                fileDelete(arguments.path);
            },
            directoryList = function(required string path, boolean recurse = false) {
                return directoryList(arguments.path, arguments.recurse);
            },
            getFileInfo = function(required string path) {
                return getFileInfo(arguments.path);
            }
        };
    }
    
    /**
     * Create mock command builder
     */
    private function createMockCommandBuilder(required string command) {
        var builder = {
            command = arguments.command,
            parameters = {},
            workingDir = "",
            flags = {},
            
            params = function(struct params = {}) {
                structAppend(this.parameters, arguments.params);
                return this;
            },
            
            flags = function(struct flags = {}) {
                structAppend(this.flags, arguments.flags);
                return this;
            },
            
            inWorkingDirectory = function(required string dir) {
                this.workingDir = arguments.dir;
                return this;
            },
            
            run = function(boolean returnOutput = false) {
                // Mock command execution
                var output = "Mock execution of: " & this.command;
                
                if (arguments.returnOutput) {
                    return output;
                } else {
                    arrayAppend(variables.capturedOutput, output);
                    return 0;
                }
            }
        };
        
        return builder;
    }
    
    /**
     * Set mock user inputs
     */
    function mockUserInput(required array inputs) {
        variables.mockInputs = arguments.inputs;
        variables.mockInputIndex = 0;
    }
    
    /**
     * Get next mock input
     */
    private function getMockInput(required string prompt, string defaultValue = "") {
        // Add prompt to output
        arrayAppend(variables.capturedOutput, arguments.prompt);
        
        // Return next mock input or default
        if (variables.mockInputIndex < arrayLen(variables.mockInputs)) {
            variables.mockInputIndex++;
            var input = variables.mockInputs[variables.mockInputIndex];
            arrayAppend(variables.capturedOutput, "> " & input);
            return input;
        }
        
        arrayAppend(variables.capturedOutput, "> " & arguments.defaultValue);
        return arguments.defaultValue;
    }
    
    /**
     * Create a test project structure
     */
    function createTestProject(string path = variables.tempDir) {
        // Create basic Wheels project structure
        directoryCreate(arguments.path & "/app/controllers", true);
        directoryCreate(arguments.path & "/app/models", true);
        directoryCreate(arguments.path & "/app/views", true);
        directoryCreate(arguments.path & "/config", true);
        directoryCreate(arguments.path & "/db/migrate", true);
        directoryCreate(arguments.path & "/vendor/wheels", true);
        directoryCreate(arguments.path & "/tests", true);
        
        // Create marker files
        fileWrite(arguments.path & "/Application.cfc", '<cfcomponent></cfcomponent>');
        fileWrite(arguments.path & "/box.json", '{"name":"test-project","version":"1.0.0"}');
        
        return arguments.path;
    }
    
    /**
     * Assert file was created
     */
    function assertFileCreated(required string path, string message = "") {
        var fullPath = isAbsolutePath(arguments.path) ? arguments.path : variables.tempDir & arguments.path;
        var defaultMessage = "Expected file to exist: #arguments.path#";
        expect(fileExists(fullPath)).toBeTrue(len(arguments.message) ? arguments.message : defaultMessage);
    }
    
    /**
     * Assert directory was created
     */
    function assertDirectoryCreated(required string path, string message = "") {
        var fullPath = isAbsolutePath(arguments.path) ? arguments.path : variables.tempDir & arguments.path;
        var defaultMessage = "Expected directory to exist: #arguments.path#";
        expect(directoryExists(fullPath)).toBeTrue(len(arguments.message) ? arguments.message : defaultMessage);
    }
    
    /**
     * Assert output contains text
     */
    function assertOutputContains(required string text, string message = "") {
        var output = arrayToList(variables.capturedOutput, chr(10));
        var defaultMessage = "Expected output to contain: #arguments.text#";
        expect(output).toInclude(arguments.text, len(arguments.message) ? arguments.message : defaultMessage);
    }
    
    /**
     * Assert output matches pattern
     */
    function assertOutputMatches(required string pattern, string message = "") {
        var output = arrayToList(variables.capturedOutput, chr(10));
        var defaultMessage = "Expected output to match pattern: #arguments.pattern#";
        expect(reFindNoCase(arguments.pattern, output)).toBeTrue(len(arguments.message) ? arguments.message : defaultMessage);
    }
    
    /**
     * Get captured output as string
     */
    function getOutput() {
        return arrayToList(variables.capturedOutput, chr(10));
    }
    
    /**
     * Get captured output as array
     */
    function getOutputArray() {
        return duplicate(variables.capturedOutput);
    }
    
    /**
     * Check if path is absolute
     */
    private function isAbsolutePath(required string path) {
        return left(arguments.path, 1) == "/" || find(":", arguments.path) > 0;
    }
    
    /**
     * Get temp directory path
     */
    function getTempDir() {
        return variables.tempDir;
    }
}