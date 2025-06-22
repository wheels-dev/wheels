/**
 * Test helper functions for Wheels CLI tests
 */
component {
    
    /**
     * Create a minimal Wheels project structure for testing
     */
    function createMinimalProject(required string path) {
        directoryCreate(arguments.path & "/vendor/wheels", true);
        fileWrite(arguments.path & "/Application.cfc", '<cfcomponent></cfcomponent>');
        fileWrite(arguments.path & "/box.json", '{"name":"test-project"}');
        return arguments.path;
    }
    
    /**
     * Create test model file
     */
    function createTestModel(required string path, required string name) {
        var content = 'component extends="Model" {
            function config() {
                // Model configuration
            }
        }';
        
        var filePath = arguments.path & "/app/models/" & arguments.name & ".cfc";
        directoryCreate(getDirectoryFromPath(filePath), true);
        fileWrite(filePath, content);
        return filePath;
    }
    
    /**
     * Create test controller file
     */
    function createTestController(required string path, required string name) {
        var content = 'component extends="Controller" {
            function config() {
                // Controller configuration
            }
            
            function index() {
                // Index action
            }
        }';
        
        var filePath = arguments.path & "/app/controllers/" & arguments.name & ".cfc";
        directoryCreate(getDirectoryFromPath(filePath), true);
        fileWrite(filePath, content);
        return filePath;
    }
    
    /**
     * Create test migration file
     */
    function createTestMigration(required string path, required string name) {
        var timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
        var fileName = timestamp & "_" & arguments.name & ".cfc";
        
        var content = 'component extends="wheels.migrator.Migration" {
            function up() {
                // Migration up
            }
            
            function down() {
                // Migration down
            }
        }';
        
        var filePath = arguments.path & "/db/migrate/" & fileName;
        directoryCreate(getDirectoryFromPath(filePath), true);
        fileWrite(filePath, content);
        return filePath;
    }
    
    /**
     * Get list of files in directory matching pattern
     */
    function getFilesMatching(required string directory, required string pattern) {
        if (!directoryExists(arguments.directory)) {
            return [];
        }
        
        var files = directoryList(arguments.directory, false, "name");
        var matches = [];
        
        for (var file in files) {
            if (reFindNoCase(arguments.pattern, file)) {
                arrayAppend(matches, file);
            }
        }
        
        return matches;
    }
    
    /**
     * Clean test database
     */
    function cleanTestDatabase(required string path) {
        var dbPath = arguments.path & "/db/sqlite/test.sqlite";
        if (fileExists(dbPath)) {
            fileDelete(dbPath);
        }
    }
    
    /**
     * Create mock user input file
     */
    function createMockInputFile(required string path, required array inputs) {
        var content = arrayToList(arguments.inputs, chr(10));
        fileWrite(arguments.path, content);
        return arguments.path;
    }
    
    /**
     * Assert file contains all strings
     */
    function assertFileContainsAll(required string filePath, required array strings) {
        if (!fileExists(arguments.filePath)) {
            throw(type="AssertionError", message="File does not exist: #arguments.filePath#");
        }
        
        var content = fileRead(arguments.filePath);
        for (var str in arguments.strings) {
            if (!findNoCase(str, content)) {
                throw(type="AssertionError", message="File does not contain: #str#");
            }
        }
        
        return true;
    }
    
    /**
     * Get relative path from base
     */
    function getRelativePath(required string fullPath, required string basePath) {
        var cleanFull = replace(arguments.fullPath, "\", "/", "all");
        var cleanBase = replace(arguments.basePath, "\", "/", "all");
        
        if (!endsWith(cleanBase, "/")) {
            cleanBase &= "/";
        }
        
        if (findNoCase(cleanBase, cleanFull) == 1) {
            return mid(cleanFull, len(cleanBase) + 1, len(cleanFull));
        }
        
        return cleanFull;
    }
    
    /**
     * Wait for file to exist (async operations)
     */
    function waitForFile(required string path, numeric timeout = 5000) {
        var startTime = getTickCount();
        
        while (!fileExists(arguments.path) && (getTickCount() - startTime) < arguments.timeout) {
            sleep(100);
        }
        
        return fileExists(arguments.path);
    }
    
    /**
     * Create server.json for testing
     */
    function createTestServerJson(required string path, struct config = {}) {
        var defaultConfig = {
            name = "test-app",
            app = {
                cfengine = "lucee@5"
            },
            web = {
                http = {
                    port = 8080
                }
            }
        };
        
        structAppend(defaultConfig, arguments.config, true);
        
        fileWrite(
            arguments.path & "/server.json",
            serializeJSON(defaultConfig, false, false)
        );
    }
    
    /**
     * Ends with helper
     */
    private function endsWith(required string str, required string suffix) {
        var lenStr = len(arguments.str);
        var lenSuffix = len(arguments.suffix);
        
        if (lenSuffix > lenStr) {
            return false;
        }
        
        return right(arguments.str, lenSuffix) == arguments.suffix;
    }
}