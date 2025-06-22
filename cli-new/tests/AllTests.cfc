/**
 * Main test suite for Wheels CLI
 * Runs all test categories
 */
component extends="testbox.system.BaseSpec" {
    
    function run() {
        describe("Wheels CLI Test Suite", function() {
            
            // Unit Tests - Commands
            describe("Command Tests", function() {
                it("should run all command tests", function() {
                    var testbox = new testbox.system.TestBox();
                    var results = testbox.run(
                        directory = {
                            mapping = "tests.specs.commands",
                            recurse = true
                        }
                    );
                    expect(results).toInclude("Passed:");
                });
            });
            
            // Unit Tests - Services
            describe("Service Tests", function() {
                it("should run all service tests", function() {
                    var testbox = new testbox.system.TestBox();
                    var results = testbox.run(
                        directory = {
                            mapping = "tests.specs.services",
                            recurse = true
                        }
                    );
                    expect(results).toInclude("Passed:");
                });
            });
            
            // Integration Tests
            describe("Integration Tests", function() {
                it("should run all integration tests", function() {
                    var testbox = new testbox.system.TestBox();
                    var results = testbox.run(
                        directory = {
                            mapping = "tests.specs.integration",
                            recurse = true
                        }
                    );
                    expect(results).toInclude("Passed:");
                });
            });
            
        });
    }
    
    /**
     * Get test statistics
     */
    function getTestStats() {
        var stats = {
            totalSpecs = 0,
            totalTests = 0,
            categories = []
        };
        
        // Count specs in each category
        var categories = [
            {name = "Commands", path = "tests/specs/commands"},
            {name = "Services", path = "tests/specs/services"},
            {name = "Integration", path = "tests/specs/integration"}
        ];
        
        for (var category in categories) {
            var files = directoryList(
                expandPath(category.path),
                true,
                "path",
                "*.cfc"
            );
            
            arrayAppend(stats.categories, {
                name = category.name,
                specCount = arrayLen(files)
            });
            
            stats.totalSpecs += arrayLen(files);
        }
        
        return stats;
    }
}