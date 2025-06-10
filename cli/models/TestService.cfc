component {
    
    property name="print" inject="print";
    
    /**
     * Run tests with specified options
     */
    function runTests(
        string filter = "",
        string group = "",
        boolean coverage = false,
        string reporter = "console",
        boolean verbose = false,
        boolean failfast = false
    ) {
        var result = {
            success = true,
            totalTests = 0,
            totalPassed = 0,
            totalFailed = 0,
            errors = []
        };
        
        try {
            // Build test command
            var testCommand = "testbox run";
            
            if (len(arguments.filter)) {
                testCommand &= " testBundles=#arguments.filter#";
            }
            
            if (len(arguments.group)) {
                testCommand &= " testSuites=#arguments.group#";
            }
            
            if (arguments.reporter != "console") {
                testCommand &= " reporter=#arguments.reporter#";
            }
            
            if (arguments.coverage) {
                testCommand &= " coverageEnabled=true";
            }
            
            if (arguments.verbose) {
                testCommand &= " verbose=true";
            }
            
            if (arguments.failfast) {
                testCommand &= " bail=true";
            }
            
            // Execute tests
            var output = command(testCommand).run(returnOutput = true);
            
            // Parse results
            result = parseTestOutput(output, arguments.reporter);
            
            if (arguments.coverage) {
                result.coverage = parseCoverageOutput(output);
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            arrayAppend(result.errors, e.message);
        }
        
        return result;
    }
    
    /**
     * Generate test file for given specifications
     */
    function generateTest(
        required string type,
        required string name,
        boolean crud = false,
        boolean mock = false
    ) {
        var testName = arguments.name;
        if (!reFind("Test$", testName)) {
            testName &= "Test";
        }
        
        var testPath = determineTestPath(arguments.type, testName);
        var testDir = getDirectoryFromPath(resolvePath(testPath));
        
        // Create directory if it doesn't exist
        if (!directoryExists(testDir)) {
            directoryCreate(testDir, true);
        }
        
        // Generate test content
        var testContent = generateTestContent(
            type = arguments.type,
            name = arguments.name,
            testName = testName,
            crud = arguments.crud,
            mock = arguments.mock
        );
        
        // Write test file
        fileWrite(resolvePath(testPath), testContent);
        
        return testPath;
    }
    
    /**
     * Determine test file path based on type
     */
    private function determineTestPath(required string type, required string testName) {
        var basePath = "tests/specs/";
        
        switch (arguments.type) {
            case "unit":
                return basePath & "unit/" & arguments.testName & ".cfc";
            case "integration":
                return basePath & "integration/" & arguments.testName & ".cfc";
            case "model":
                return basePath & "models/" & arguments.testName & ".cfc";
            case "controller":
                return basePath & "controllers/" & arguments.testName & ".cfc";
            default:
                return basePath & arguments.testName & ".cfc";
        }
    }
    
    /**
     * Generate test content based on type and options
     */
    private function generateTestContent(
        required string type,
        required string name,
        required string testName,
        boolean crud = false,
        boolean mock = false
    ) {
        var content = 'component extends="testbox.system.BaseSpec" {' & chr(10) & chr(10);
        
        // Add any required properties for mocking
        if (arguments.mock) {
            content &= '    property name="mockbox" inject="mockbox@testbox";' & chr(10) & chr(10);
        }
        
        content &= '    function run() {' & chr(10);
        content &= '        describe("#arguments.testName#", function() {' & chr(10) & chr(10);
        
        // Add test-specific content
        switch (arguments.type) {
            case "model":
                content &= generateModelTests(arguments.name, arguments.crud, arguments.mock);
                break;
            case "controller":
                content &= generateControllerTests(arguments.name, arguments.crud, arguments.mock);
                break;
            default:
                content &= generateBasicTests(arguments.name, arguments.mock);
        }
        
        content &= chr(10) & '        });' & chr(10);
        content &= '    }' & chr(10) & chr(10);
        content &= '}';
        
        return content;
    }
    
    /**
     * Generate model-specific tests
     */
    private function generateModelTests(required string name, boolean crud, boolean mock) {
        var tests = '';
        
        if (arguments.crud) {
            tests &= '            beforeEach(function() {' & chr(10);
            tests &= '                variables.#lCase(arguments.name)# = model("#arguments.name#").new();' & chr(10);
            tests &= '            });' & chr(10) & chr(10);
            
            tests &= '            afterEach(function() {' & chr(10);
            tests &= '                if (structKeyExists(variables, "#lCase(arguments.name)#") && variables.#lCase(arguments.name)#.exists()) {' & chr(10);
            tests &= '                    variables.#lCase(arguments.name)#.delete();' & chr(10);
            tests &= '                }' & chr(10);
            tests &= '            });' & chr(10) & chr(10);
            
            tests &= '            it("should create a new #arguments.name#", function() {' & chr(10);
            tests &= '                variables.#lCase(arguments.name)#.name = "Test #arguments.name#";' & chr(10);
            tests &= '                expect(variables.#lCase(arguments.name)#.save()).toBeTrue();' & chr(10);
            tests &= '                expect(variables.#lCase(arguments.name)#.exists()).toBeTrue();' & chr(10);
            tests &= '            });' & chr(10) & chr(10);
            
            tests &= '            it("should update an existing #arguments.name#", function() {' & chr(10);
            tests &= '                variables.#lCase(arguments.name)#.name = "Test #arguments.name#";' & chr(10);
            tests &= '                variables.#lCase(arguments.name)#.save();' & chr(10);
            tests &= '                ' & chr(10);
            tests &= '                variables.#lCase(arguments.name)#.name = "Updated #arguments.name#";' & chr(10);
            tests &= '                expect(variables.#lCase(arguments.name)#.save()).toBeTrue();' & chr(10);
            tests &= '                expect(variables.#lCase(arguments.name)#.name).toBe("Updated #arguments.name#");' & chr(10);
            tests &= '            });' & chr(10) & chr(10);
            
            tests &= '            it("should delete a #arguments.name#", function() {' & chr(10);
            tests &= '                variables.#lCase(arguments.name)#.name = "Test #arguments.name#";' & chr(10);
            tests &= '                variables.#lCase(arguments.name)#.save();' & chr(10);
            tests &= '                ' & chr(10);
            tests &= '                expect(variables.#lCase(arguments.name)#.delete()).toBeTrue();' & chr(10);
            tests &= '                expect(variables.#lCase(arguments.name)#.exists()).toBeFalse();' & chr(10);
            tests &= '            });' & chr(10) & chr(10);
            
            tests &= '            it("should validate required fields", function() {' & chr(10);
            tests &= '                expect(variables.#lCase(arguments.name)#.save()).toBeFalse();' & chr(10);
            tests &= '                expect(variables.#lCase(arguments.name)#.hasErrors()).toBeTrue();' & chr(10);
            tests &= '            });';
        } else {
            tests &= '            it("should instantiate the #arguments.name# model", function() {' & chr(10);
            tests &= '                var #lCase(arguments.name)# = model("#arguments.name#").new();' & chr(10);
            tests &= '                expect(#lCase(arguments.name)#).toBeInstanceOf("models.#arguments.name#");' & chr(10);
            tests &= '            });';
        }
        
        return tests;
    }
    
    /**
     * Generate controller-specific tests
     */
    private function generateControllerTests(required string name, boolean crud, boolean mock) {
        var tests = '';
        
        tests &= '            beforeEach(function() {' & chr(10);
        tests &= '                variables.controller = controller("#arguments.name#");' & chr(10);
        
        if (arguments.mock) {
            tests &= '                variables.mockModel = mockbox.createMock("models.#reSingularize(arguments.name)#");' & chr(10);
        }
        
        tests &= '            });' & chr(10) & chr(10);
        
        if (arguments.crud) {
            tests &= '            it("should display index page", function() {' & chr(10);
            tests &= '                var result = variables.controller.index();' & chr(10);
            tests &= '                expect(result).toBeStruct();' & chr(10);
            tests &= '                expect(result).toHaveKey("#lCase(arguments.name)#");' & chr(10);
            tests &= '            });' & chr(10) & chr(10);
            
            tests &= '            it("should display new form", function() {' & chr(10);
            tests &= '                var result = variables.controller.new();' & chr(10);
            tests &= '                expect(result).toBeStruct();' & chr(10);
            tests &= '                expect(result).toHaveKey("#reSingularize(lCase(arguments.name))#");' & chr(10);
            tests &= '            });' & chr(10) & chr(10);
            
            tests &= '            it("should create a new record", function() {' & chr(10);
            tests &= '                params.#reSingularize(lCase(arguments.name))# = {' & chr(10);
            tests &= '                    name = "Test Record"' & chr(10);
            tests &= '                };' & chr(10);
            tests &= '                var result = variables.controller.create();' & chr(10);
            tests &= '                expect(result).toBeStruct();' & chr(10);
            tests &= '            });';
        } else {
            tests &= '            it("should instantiate the controller", function() {' & chr(10);
            tests &= '                expect(variables.controller).toBeInstanceOf("controllers.#arguments.name#");' & chr(10);
            tests &= '            });';
        }
        
        return tests;
    }
    
    /**
     * Generate basic tests for other types
     */
    private function generateBasicTests(required string name, boolean mock) {
        var tests = '';
        
        tests &= '            it("should run a basic test", function() {' & chr(10);
        tests &= '                expect(true).toBeTrue();' & chr(10);
        tests &= '            });' & chr(10) & chr(10);
        
        tests &= '            it("should test #arguments.name# functionality", function() {' & chr(10);
        tests &= '                // Add your test logic here' & chr(10);
        tests &= '                expect(1).toBe(1);' & chr(10);
        tests &= '            });';
        
        return tests;
    }
    
    /**
     * Parse test output based on reporter type
     */
    private function parseTestOutput(output, reporter) {
        var result = {
            success = true,
            totalTests = 0,
            totalPassed = 0,
            totalFailed = 0
        };
        
        // Basic parsing logic - would need to be enhanced based on actual TestBox output
        if (findNoCase("failed", arguments.output) || findNoCase("error", arguments.output)) {
            result.success = false;
        }
        
        // Extract test counts using regex
        var patterns = {
            tests = "(\d+)\s+test[s]?",
            passed = "(\d+)\s+pass(ed)?",
            failed = "(\d+)\s+fail(ed)?"
        };
        
        for (var key in patterns) {
            var matches = reFind(patterns[key], arguments.output, 1, true);
            if (arrayLen(matches.match) > 1) {
                result["total" & key] = val(matches.match[2]);
            }
        }
        
        return result;
    }
    
    /**
     * Parse coverage output
     */
    private function parseCoverageOutput(output) {
        var coverage = {
            percentage = 0,
            files = {}
        };
        
        // Basic coverage parsing - would need enhancement based on actual coverage output
        var coveragePattern = "Coverage:\s*(\d+(?:\.\d+)?)\s*%";
        var matches = reFind(coveragePattern, arguments.output, 1, true);
        
        if (arrayLen(matches.match) > 1) {
            coverage.percentage = val(matches.match[2]);
        }
        
        return coverage;
    }
    
    /**
     * Simple singularization helper
     */
    private function reSingularize(word) {
        if (right(arguments.word, 3) == "ies") {
            return left(arguments.word, len(arguments.word) - 3) & "y";
        } else if (right(arguments.word, 2) == "es") {
            return left(arguments.word, len(arguments.word) - 2);
        } else if (right(arguments.word, 1) == "s") {
            return left(arguments.word, len(arguments.word) - 1);
        }
        return arguments.word;
    }
    
    /**
     * Resolve a file path  
     */
    private function resolvePath(path, baseDirectory = "") {
        // Prepend app/ to common paths if not already present
        var appPath = arguments.path;
        if (!findNoCase("app/", appPath) && !findNoCase("tests/", appPath)) {
            // Common app directories
            if (reFind("^(controllers|models|views|migrator)/", appPath)) {
                appPath = "app/" & appPath;
            }
        }
        
        // If path is already absolute, return it
        if (left(appPath, 1) == "/" || mid(appPath, 2, 1) == ":") {
            return appPath;
        }
        
        // Build absolute path from current working directory
        // Use provided base directory or fall back to expandPath
        var baseDir = len(arguments.baseDirectory) ? arguments.baseDirectory : expandPath(".");
        
        // Ensure we have a trailing slash
        if (right(baseDir, 1) != "/") {
            baseDir &= "/";
        }
        
        return baseDir & appPath;
    }
}