/**
 * Tests for MigrationService
 */
component extends="tests.BaseTestCase" {
    
    function beforeAll() {
        super.beforeAll();
        variables.migrationService = createObject("component", "models.MigrationService").init();
    }
    
    function run() {
        describe("MigrationService", function() {
            
            beforeEach(function() {
                createTestProject();
                // Set project root for service
                variables.migrationService.setProjectRoot(getTempDir());
            });
            
            describe("Migration generation", function() {
                
                it("should generate a blank migration", function() {
                    var result = variables.migrationService.generateMigration("AddIndexToUsers");
                    
                    expect(result.success).toBeTrue();
                    expect(result.fileName).toInclude("AddIndexToUsers");
                    assertFileCreated("db/migrate/" & result.fileName);
                    
                    var content = fileRead(getTempDir() & "db/migrate/" & result.fileName);
                    expect(content).toInclude("extends=""wheels.migrator.Migration""");
                    expect(content).toInclude("function up()");
                    expect(content).toInclude("function down()");
                });
                
                it("should generate CreateTable migration from name", function() {
                    var result = variables.migrationService.generateMigration("CreateUsers");
                    
                    expect(result.success).toBeTrue();
                    
                    var content = fileRead(getTempDir() & "db/migrate/" & result.fileName);
                    expect(content).toInclude("createTable(""users"")");
                    expect(content).toInclude("t.primaryKey()");
                    expect(content).toInclude("t.timestamps()");
                    expect(content).toInclude("dropTable(""users"")");
                });
                
                it("should generate migration with attributes", function() {
                    var operations = [
                        {
                            type = "createTable",
                            tableName = "posts",
                            columns = [
                                {name = "title", type = "string", nullable = false},
                                {name = "content", type = "text"},
                                {name = "published", type = "boolean", default = false}
                            ]
                        }
                    ];
                    
                    var result = variables.migrationService.generateMigration("CreatePosts", operations);
                    
                    expect(result.success).toBeTrue();
                    
                    var content = fileRead(getTempDir() & "db/migrate/" & result.fileName);
                    expect(content).toInclude('t.string("title", nullable=false)');
                    expect(content).toInclude('t.text("content")');
                    expect(content).toInclude('t.boolean("published", default=false)');
                });
                
                it("should generate AddColumn migration", function() {
                    var result = variables.migrationService.generateMigration("AddEmailToUsers");
                    
                    expect(result.success).toBeTrue();
                    
                    var content = fileRead(getTempDir() & "db/migrate/" & result.fileName);
                    expect(content).toInclude('addColumn(table="users", column="email", type="string")');
                    expect(content).toInclude('removeColumn(table="users", column="email")');
                });
                
                it("should generate RemoveColumn migration", function() {
                    var result = variables.migrationService.generateMigration("RemovePasswordFromUsers");
                    
                    expect(result.success).toBeTrue();
                    
                    var content = fileRead(getTempDir() & "db/migrate/" & result.fileName);
                    expect(content).toInclude('removeColumn(table="users", column="password")');
                });
                
                it("should generate AddIndex migration", function() {
                    var result = variables.migrationService.generateMigration("AddIndexToUsersEmail");
                    
                    expect(result.success).toBeTrue();
                    
                    var content = fileRead(getTempDir() & "db/migrate/" & result.fileName);
                    expect(content).toInclude('addIndex(table="users", column="email", indexName="idx_users_email")');
                    expect(content).toInclude('removeIndex(table="users", indexName="idx_users_email")');
                });
                
                it("should parse migration names correctly", function() {
                    var parsed = variables.migrationService.parseMigrationName("CreateUsers");
                    expect(parsed.action).toBe("create");
                    expect(parsed.tableName).toBe("users");
                    
                    parsed = variables.migrationService.parseMigrationName("AddEmailToUsers");
                    expect(parsed.action).toBe("add");
                    expect(parsed.columnName).toBe("email");
                    expect(parsed.tableName).toBe("users");
                    
                    parsed = variables.migrationService.parseMigrationName("RemovePasswordFromUsers");
                    expect(parsed.action).toBe("remove");
                    expect(parsed.columnName).toBe("password");
                    expect(parsed.tableName).toBe("users");
                    
                    parsed = variables.migrationService.parseMigrationName("AddIndexToUsersEmail");
                    expect(parsed.action).toBe("addindex");
                    expect(parsed.tableName).toBe("users");
                    expect(parsed.columnName).toBe("email");
                });
                
                it("should generate unique timestamps for migrations", function() {
                    var result1 = variables.migrationService.generateMigration("FirstMigration");
                    sleep(1100); // Sleep for more than a second
                    var result2 = variables.migrationService.generateMigration("SecondMigration");
                    
                    expect(result1.fileName).notToBe(result2.fileName);
                    
                    // Extract timestamps
                    var timestamp1 = listFirst(result1.fileName, "_");
                    var timestamp2 = listFirst(result2.fileName, "_");
                    
                    expect(timestamp1).notToBe(timestamp2);
                    expect(val(timestamp2)).toBeGT(val(timestamp1));
                });
                
            });
            
            describe("Migration status", function() {
                
                it("should get migration status", function() {
                    // Create some test migrations
                    variables.migrationService.generateMigration("CreateUsers");
                    variables.migrationService.generateMigration("CreatePosts");
                    
                    var status = variables.migrationService.getMigrationStatus();
                    
                    expect(status).toBeStruct();
                    expect(status.pending).toBeArray();
                    expect(status.executed).toBeArray();
                    
                    // All should be pending initially
                    expect(arrayLen(status.pending)).toBe(2);
                    expect(arrayLen(status.executed)).toBe(0);
                });
                
                it("should list pending migrations", function() {
                    variables.migrationService.generateMigration("CreateUsers");
                    variables.migrationService.generateMigration("CreatePosts");
                    
                    var pending = variables.migrationService.getPendingMigrations();
                    
                    expect(pending).toBeArray();
                    expect(arrayLen(pending)).toBe(2);
                    expect(pending[1]).toInclude("CreateUsers");
                    expect(pending[2]).toInclude("CreatePosts");
                });
                
                it("should detect migration files", function() {
                    // Create migration files
                    var file1 = "20240101120000_CreateUsers.cfc";
                    var file2 = "20240102120000_CreatePosts.cfc";
                    
                    fileWrite(getTempDir() & "db/migrate/" & file1, "// migration 1");
                    fileWrite(getTempDir() & "db/migrate/" & file2, "// migration 2");
                    
                    var migrations = variables.migrationService.listMigrationFiles();
                    
                    expect(migrations).toBeArray();
                    expect(arrayLen(migrations)).toBe(2);
                    expect(migrations).toInclude(file1);
                    expect(migrations).toInclude(file2);
                });
                
            });
            
            describe("Migration operations", function() {
                
                it("should validate migration names", function() {
                    expect(variables.migrationService.isValidMigrationName("CreateUsers")).toBeTrue();
                    expect(variables.migrationService.isValidMigrationName("AddEmailToUsers")).toBeTrue();
                    expect(variables.migrationService.isValidMigrationName("RemovePasswordFromUsers")).toBeTrue();
                    expect(variables.migrationService.isValidMigrationName("AddIndexToUsersEmail")).toBeTrue();
                    expect(variables.migrationService.isValidMigrationName("123Invalid")).toBeFalse();
                    expect(variables.migrationService.isValidMigrationName("")).toBeFalse();
                });
                
                it("should convert column types correctly", function() {
                    expect(variables.migrationService.convertColumnType("string")).toBe("string");
                    expect(variables.migrationService.convertColumnType("text")).toBe("text");
                    expect(variables.migrationService.convertColumnType("integer")).toBe("integer");
                    expect(variables.migrationService.convertColumnType("bigint")).toBe("biginteger");
                    expect(variables.migrationService.convertColumnType("decimal")).toBe("decimal");
                    expect(variables.migrationService.convertColumnType("boolean")).toBe("boolean");
                    expect(variables.migrationService.convertColumnType("datetime")).toBe("datetime");
                    expect(variables.migrationService.convertColumnType("date")).toBe("date");
                    expect(variables.migrationService.convertColumnType("time")).toBe("time");
                    expect(variables.migrationService.convertColumnType("binary")).toBe("binary");
                });
                
                it("should parse column definitions", function() {
                    var parsed = variables.migrationService.parseColumnDefinition("email:string:unique");
                    expect(parsed.name).toBe("email");
                    expect(parsed.type).toBe("string");
                    expect(parsed.unique).toBeTrue();
                    
                    parsed = variables.migrationService.parseColumnDefinition("age:integer:nullable");
                    expect(parsed.name).toBe("age");
                    expect(parsed.type).toBe("integer");
                    expect(parsed.nullable).toBeTrue();
                    
                    parsed = variables.migrationService.parseColumnDefinition("price:decimal(10,2)");
                    expect(parsed.name).toBe("price");
                    expect(parsed.type).toBe("decimal");
                    expect(parsed.precision).toBe(10);
                    expect(parsed.scale).toBe(2);
                });
                
            });
            
        });
    }
}