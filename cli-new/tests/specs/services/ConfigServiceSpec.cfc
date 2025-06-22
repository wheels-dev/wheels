/**
 * Tests for ConfigService
 */
component extends="tests.BaseTestCase" {
    
    function beforeAll() {
        super.beforeAll();
        // Create service instance for testing
        variables.configService = createObject("component", "models.ConfigService").init();
    }
    
    function run() {
        describe("ConfigService", function() {
            
            beforeEach(function() {
                // Set test project root
                variables.configService.setProjectRoot(getTempDir());
                
                // Clear any existing config
                variables.configService.config = {};
            });
            
            it("should load configuration from .wheelscli.json", function() {
                // Create config file
                var config = {
                    database = "postgresql",
                    template = "api",
                    author = "Test Author"
                };
                
                fileWrite(
                    getTempDir() & ".wheelscli.json",
                    serializeJSON(config)
                );
                
                variables.configService.loadConfiguration();
                
                expect(variables.configService.getConfig("database")).toBe("postgresql");
                expect(variables.configService.getConfig("template")).toBe("api");
                expect(variables.configService.getConfig("author")).toBe("Test Author");
            });
            
            it("should return default value when config key doesn't exist", function() {
                expect(variables.configService.getConfig("nonexistent", "default")).toBe("default");
            });
            
            it("should set and get config values", function() {
                variables.configService.setConfig("testKey", "testValue");
                expect(variables.configService.getConfig("testKey")).toBe("testValue");
                
                variables.configService.setConfig("nested.key", "nestedValue");
                expect(variables.configService.getConfig("nested.key")).toBe("nestedValue");
            });
            
            it("should save configuration to file", function() {
                variables.configService.setConfig("database", "mysql");
                variables.configService.setConfig("template", "spa");
                
                variables.configService.saveConfiguration();
                
                expect(fileExists(getTempDir() & ".wheelscli.json")).toBeTrue();
                
                var savedConfig = deserializeJSON(fileRead(getTempDir() & ".wheelscli.json"));
                expect(savedConfig.database).toBe("mysql");
                expect(savedConfig.template).toBe("spa");
            });
            
            it("should merge user config with defaults", function() {
                // Set some defaults
                variables.configService.config = {
                    database = "sqlite",
                    template = "default",
                    verbose = false
                };
                
                // Load user config that overrides some values
                var userConfig = {
                    database = "postgresql",
                    author = "John Doe"
                };
                
                fileWrite(
                    getTempDir() & ".wheelscli.json",
                    serializeJSON(userConfig)
                );
                
                variables.configService.loadConfiguration();
                
                // Check merged config
                expect(variables.configService.getConfig("database")).toBe("postgresql"); // overridden
                expect(variables.configService.getConfig("template")).toBe("default"); // kept default
                expect(variables.configService.getConfig("author")).toBe("John Doe"); // new value
            });
            
            it("should handle missing config file gracefully", function() {
                // Ensure no config file exists
                if (fileExists(getTempDir() & ".wheelscli.json")) {
                    fileDelete(getTempDir() & ".wheelscli.json");
                }
                
                // Should not throw error
                variables.configService.loadConfiguration();
                
                // Should still have access to defaults
                expect(structCount(variables.configService.config)).toBe(0);
            });
            
            it("should handle invalid JSON in config file", function() {
                fileWrite(
                    getTempDir() & ".wheelscli.json",
                    "{ invalid json content"
                );
                
                // Should not throw error
                variables.configService.loadConfiguration();
                
                // Config should be empty or defaults
                expect(structCount(variables.configService.config)).toBe(0);
            });
            
            it("should get nested config values", function() {
                variables.configService.config = {
                    server = {
                        host = "localhost",
                        port = 8080,
                        ssl = {
                            enabled = true,
                            cert = "/path/to/cert"
                        }
                    }
                };
                
                expect(variables.configService.getConfig("server.host")).toBe("localhost");
                expect(variables.configService.getConfig("server.port")).toBe(8080);
                expect(variables.configService.getConfig("server.ssl.enabled")).toBe(true);
                expect(variables.configService.getConfig("server.ssl.cert")).toBe("/path/to/cert");
            });
            
            it("should set nested config values", function() {
                variables.configService.setConfig("app.name", "TestApp");
                variables.configService.setConfig("app.version", "1.0.0");
                variables.configService.setConfig("app.features.auth", true);
                
                var config = variables.configService.getConfig();
                expect(config.app.name).toBe("TestApp");
                expect(config.app.version).toBe("1.0.0");
                expect(config.app.features.auth).toBe(true);
            });
            
            it("should detect project root correctly", function() {
                // Create a test project structure
                createTestProject();
                
                // Test from project root
                variables.configService.setProjectRoot(getTempDir());
                expect(variables.configService.getProjectRoot()).toBe(getTempDir());
                
                // Test from subdirectory
                var subDir = getTempDir() & "app/controllers/";
                variables.configService.setProjectRoot(subDir);
                expect(variables.configService.findProjectRoot(subDir)).toBe(getTempDir());
            });
            
            it("should provide all config when no key specified", function() {
                variables.configService.setConfig("key1", "value1");
                variables.configService.setConfig("key2", "value2");
                
                var allConfig = variables.configService.getConfig();
                expect(allConfig).toBeStruct();
                expect(allConfig.key1).toBe("value1");
                expect(allConfig.key2).toBe("value2");
            });
        });
    }
}