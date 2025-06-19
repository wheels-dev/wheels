/**
 * Tests for Wheels CLI Configuration Commands
 */
component extends="tests.BaseSpec" {

    function beforeAll() {
        super.beforeAll();
        
        // Create a temporary test directory
        variables.testDir = getTempDirectory() & "wheels_config_test_" & createUUID();
        directoryCreate(variables.testDir);
        
        // Create basic Wheels app structure
        directoryCreate(variables.testDir & "/vendor/wheels");
        directoryCreate(variables.testDir & "/config");
        directoryCreate(variables.testDir & "/config/environment");
        directoryCreate(variables.testDir & "/app");
        
        // Create a basic settings file
        fileWrite(
            variables.testDir & "/config/settings.cfm",
            "<cfscript>
            // Test settings
            set(environment='test');
            </cfscript>"
        );
        
        // Create test environment files
        createTestEnvironment("development");
        createTestEnvironment("production");
    }
    
    function afterAll() {
        // Clean up test directory
        if (directoryExists(variables.testDir)) {
            directoryDelete(variables.testDir, true);
        }
        super.afterAll();
    }
    
    function run() {
        describe("Config Commands", function() {
            
            describe("config:dump", function() {
                it("should export current environment configuration", function() {
                    var result = runCommand("config:dump", variables.testDir);
                    expect(result).toInclude("Wheels Configuration Export");
                });
                
                it("should export specific environment configuration", function() {
                    var result = runCommand("config:dump production", variables.testDir);
                    expect(result).toInclude("production");
                });
                
                it("should mask sensitive values by default", function() {
                    var result = runCommand("config:dump production", variables.testDir);
                    expect(result).toInclude("***MASKED***");
                    expect(result).notToInclude("secretpassword123");
                });
                
                it("should export to different formats", function() {
                    var jsonResult = runCommand("config:dump --format=json", variables.testDir);
                    expect(isJSON(extractJSON(jsonResult))).toBeTrue();
                    
                    var envResult = runCommand("config:dump --format=env", variables.testDir);
                    expect(envResult).toInclude("DATABASE_NAME=");
                });
                
                it("should save to file when output specified", function() {
                    var outputFile = variables.testDir & "/config_export.json";
                    runCommand("config:dump --output=#outputFile#", variables.testDir);
                    expect(fileExists(outputFile)).toBeTrue();
                });
            });
            
            describe("config:check", function() {
                it("should validate configuration files", function() {
                    var result = runCommand("config:check", variables.testDir);
                    expect(result).toInclude("Wheels Configuration Validator");
                    expect(result).toInclude("✓");
                });
                
                it("should check specific environment", function() {
                    var result = runCommand("config:check production", variables.testDir);
                    expect(result).toInclude("production");
                });
                
                it("should identify missing files", function() {
                    // Remove app.cfm to trigger missing file
                    if (fileExists(variables.testDir & "/config/app.cfm")) {
                        fileDelete(variables.testDir & "/config/app.cfm");
                    }
                    var result = runCommand("config:check", variables.testDir);
                    expect(result).toInclude("Missing");
                });
                
                it("should warn about security issues", function() {
                    var result = runCommand("config:check production", variables.testDir);
                    expect(result).toInclude("default reload password");
                });
            });
            
            describe("config:diff", function() {
                it("should compare two environments", function() {
                    var result = runCommand("config:diff development production", variables.testDir);
                    expect(result).toInclude("Configuration Differences");
                    expect(result).toInclude("development");
                    expect(result).toInclude("production");
                });
                
                it("should show differences between environments", function() {
                    var result = runCommand("config:diff development production", variables.testDir);
                    expect(result).toInclude("DATABASE_NAME");
                    expect(result).toInclude("wheels_dev");
                    expect(result).toInclude("wheels_prod");
                });
                
                it("should output JSON format when requested", function() {
                    var result = runCommand("config:diff development production --format=json", variables.testDir);
                    var json = extractJSON(result);
                    expect(isJSON(json)).toBeTrue();
                    
                    var data = deserializeJSON(json);
                    expect(data).toHaveKey("differences");
                });
                
                it("should show only changes when requested", function() {
                    var result = runCommand("config:diff development production --changes-only", variables.testDir);
                    expect(result).notToInclude("Identical Configuration");
                });
            });
            
            describe("secret", function() {
                it("should generate a secret key", function() {
                    var result = runCommand("secret", variables.testDir);
                    expect(result).toInclude("Generated Secret Key");
                    expect(result).toMatch("[A-F0-9]{32}");
                });
                
                it("should generate key with specific length", function() {
                    var result = runCommand("secret --length=64", variables.testDir);
                    expect(result).toMatch("[A-F0-9]{64}");
                });
                
                it("should generate multiple keys", function() {
                    var result = runCommand("secret --count=3", variables.testDir);
                    expect(result).toInclude("Generated 3 Secret Keys");
                    expect(result).toInclude("1.");
                    expect(result).toInclude("2.");
                    expect(result).toInclude("3.");
                });
                
                it("should generate different types of secrets", function() {
                    var hexResult = runCommand("secret --type=hex", variables.testDir);
                    expect(hexResult).toMatch("[A-F0-9]+");
                    
                    var alphaResult = runCommand("secret --type=alphanumeric", variables.testDir);
                    expect(alphaResult).toMatch("[A-Za-z0-9]+");
                    
                    var uuidResult = runCommand("secret --type=uuid --length=36", variables.testDir);
                    expect(uuidResult).toMatch("[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}");
                });
                
                it("should save to .env file when requested", function() {
                    var envFile = variables.testDir & "/.env";
                    if (fileExists(envFile)) {
                        fileDelete(envFile);
                    }
                    
                    runCommand("secret --save --key=TEST_SECRET", variables.testDir);
                    
                    expect(fileExists(envFile)).toBeTrue();
                    var content = fileRead(envFile);
                    expect(content).toInclude("TEST_SECRET=");
                });
            });
            
        });
    }
    
    /**
     * Helper function to create test environment files
     */
    private void function createTestEnvironment(required string environment) {
        // Create .env file
        var envContent = "## #uCase(arguments.environment)# Environment
DATABASE_NAME=wheels_#lCase(left(arguments.environment, 3))#
DATABASE_HOST=localhost
DATABASE_PASSWORD=secretpassword123
RELOAD_PASSWORD=#arguments.environment == 'production' ? 'wheels' : 'dev'#
ENCRYPTION_SALT=testsalt123
";
        
        fileWrite(variables.testDir & "/.env.#arguments.environment#", envContent);
        
        // Create environment config file
        var configContent = "<cfscript>
// #arguments.environment# configuration
set(environment='#arguments.environment#');
set(dataSourceName='wheels_#arguments.environment#');
</cfscript>";
        
        fileWrite(variables.testDir & "/config/environment/#arguments.environment#.cfm", configContent);
    }
    
    /**
     * Helper to run a CLI command
     */
    private string function runCommand(required string command, string workingDir = "") {
        var originalDir = "";
        
        try {
            if (len(arguments.workingDir)) {
                originalDir = fileSystemUtil.getCWD();
                fileSystemUtil.cd(arguments.workingDir);
            }
            
            // Execute the command and capture output
            var result = "";
            savecontent variable="result" {
                runCommand("wheels #arguments.command#");
            }
            
            return result;
        } catch (any e) {
            return e.message;
        } finally {
            if (len(originalDir)) {
                fileSystemUtil.cd(originalDir);
            }
        }
    }
    
    /**
     * Extract JSON from command output
     */
    private string function extractJSON(required string output) {
        // Find JSON content in output
        var jsonStart = find("{", arguments.output);
        var jsonEnd = len(arguments.output) - reverse(find("}", reverse(arguments.output))) + 1;
        
        if (jsonStart > 0 && jsonEnd > jsonStart) {
            return mid(arguments.output, jsonStart, jsonEnd - jsonStart + 1);
        }
        
        return "{}";
    }
}