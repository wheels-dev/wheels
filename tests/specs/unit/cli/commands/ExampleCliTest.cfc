/**
 * Example test showing how to test CLI commands with TestBox
 */
component extends="tests.BaseSpec" {
    
    function beforeEach() {
        // Create a temporary directory for test isolation
        variables.tempDir = getTempDirectory() & "wheels_cli_test_" & createUUID() & "/";
        directoryCreate(variables.tempDir);
        
        // Create mock helpers (if BaseCommand not available in test context)
        variables.mockHelpers = {
            getNameVariants: function(name) {
                return {
                    name: arguments.name,
                    singularName: arguments.name,
                    pluralName: arguments.name & "s",
                    modelName: arguments.name,
                    modelNamePlural: arguments.name & "s"
                };
            }
        };
        
        // Create mock print output
        variables.output = [];
        variables.mockPrint = {
            line: function(text = "") { arrayAppend(variables.output, arguments.text); },
            greenLine: function(text) { arrayAppend(variables.output, "[GREEN] " & arguments.text); },
            yellowLine: function(text) { arrayAppend(variables.output, "[YELLOW] " & arguments.text); },
            boldMagentaLine: function(text) { arrayAppend(variables.output, "[BOLD] " & arguments.text); }
        };
    }
    
    function afterEach() {
        // Clean up temporary directory
        if (directoryExists(variables.tempDir)) {
            directoryDelete(variables.tempDir, true);
        }
    }
    
    function run() {
        describe("CLI Command Testing Examples", function() {
            
            describe("Testing File Generation", function() {
                it("can test that a command creates files", function() {
                    // Simulate what docker init command does
                    var dockerfileContent = 'FROM lucee/lucee:5.3
WORKDIR /app
COPY . /app
RUN box install
EXPOSE 8080
CMD ["box", "server", "start"]';
                    
                    // Write file like the command would
                    fileWrite(variables.tempDir & "Dockerfile", dockerfileContent);
                    
                    // Test file exists
                    expect(fileExists(variables.tempDir & "Dockerfile")).toBeTrue();
                    
                    // Test file content
                    var content = fileRead(variables.tempDir & "Dockerfile");
                    expect(content).toInclude("FROM lucee/lucee");
                    expect(content).toInclude("EXPOSE 8080");
                });
            });
            
            describe("Testing Command Output", function() {
                it("can test console output from commands", function() {
                    // Simulate command output
                    variables.mockPrint.boldMagentaLine("Wheels Docker Configuration");
                    variables.mockPrint.line();
                    variables.mockPrint.greenLine("Created Dockerfile");
                    variables.mockPrint.yellowLine("To start Docker: docker-compose up");
                    
                    // Test output
                    expect(arrayToList(variables.output, chr(10))).toInclude("Docker Configuration");
                    expect(arrayToList(variables.output, chr(10))).toInclude("Created Dockerfile");
                    expect(arrayToList(variables.output, chr(10))).toInclude("docker-compose up");
                });
            });
            
            describe("Testing Template Processing", function() {
                it("can test template variable replacement", function() {
                    // Test the getNameVariants helper
                    var obj = variables.mockHelpers.getNameVariants("Product");
                    
                    expect(obj.name).toBe("Product");
                    expect(obj.pluralName).toBe("Products");
                    
                    // Test template replacement
                    var template = 'component extends="Model" {
    // Model: |modelName|
    // Table: |modelNamePlural|
}';
                    
                    // Replace template variables
                    var result = template;
                    for (var key in obj) {
                        result = replace(result, "|#key#|", obj[key], "all");
                    }
                    
                    expect(result).toInclude("// Model: Product");
                    expect(result).toInclude("// Table: Products");
                });
            });
            
            describe("Testing Error Handling", function() {
                it("can test error conditions", function() {
                    // Test that command would error on invalid input
                    var invalidDb = "nosqldb";
                    var supportedDatabases = ["h2", "mysql", "postgres", "mssql"];
                    
                    expect(arrayContains(supportedDatabases, invalidDb)).toBeFalse();
                    
                    // In real command, this would throw an error
                    expect(function() {
                        if (!arrayContains(supportedDatabases, invalidDb)) {
                            throw(type="CommandError", message="Unsupported database: #invalidDb#");
                        }
                    }).toThrow("CommandError");
                });
            });
            
            describe("Testing Complex File Generation", function() {
                it("can test multi-file generation like scaffold", function() {
                    // Create directory structure
                    directoryCreate(variables.tempDir & "app/models");
                    directoryCreate(variables.tempDir & "app/controllers");
                    directoryCreate(variables.tempDir & "app/views/products");
                    
                    // Generate files
                    fileWrite(variables.tempDir & "app/models/Product.cfc", 'component extends="Model" {}');
                    fileWrite(variables.tempDir & "app/controllers/Products.cfc", 'component extends="Controller" {}');
                    fileWrite(variables.tempDir & "app/views/products/index.cfm", '<h1>Products</h1>');
                    
                    // Test structure
                    expect(directoryExists(variables.tempDir & "app/models")).toBeTrue();
                    expect(fileExists(variables.tempDir & "app/models/Product.cfc")).toBeTrue();
                    expect(fileExists(variables.tempDir & "app/controllers/Products.cfc")).toBeTrue();
                    expect(fileExists(variables.tempDir & "app/views/products/index.cfm")).toBeTrue();
                });
            });
            
        });
    }
}