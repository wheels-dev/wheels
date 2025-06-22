/**
 * Tests for DatabaseService
 */
component extends="tests.BaseTestCase" {
    
    function beforeAll() {
        super.beforeAll();
        // Create service instance
        variables.databaseService = createObject("component", "models.DatabaseService").init();
    }
    
    function run() {
        describe("DatabaseService", function() {
            
            beforeEach(function() {
                // Create test project
                createTestProject();
            });
            
            describe("SQLite operations", function() {
                
                it("should create SQLite databases", function() {
                    var result = variables.databaseService.setupSQLite(getTempDir());
                    
                    expect(result.success).toBeTrue();
                    expect(result.databasesCreated).toBeArray();
                    expect(arrayLen(result.databasesCreated)).toBe(2);
                    
                    // Verify files were created
                    assertFileCreated("db/sqlite/development.sqlite");
                    assertFileCreated("db/sqlite/test.sqlite");
                });
                
                it("should create datasource configuration for SQLite", function() {
                    var config = variables.databaseService.createDatasourceConfig("sqlite", "myapp");
                    
                    expect(config).toBeStruct();
                    expect(structKeyExists(config, "wheelsdatasource")).toBeTrue();
                    expect(config.wheelsdatasource.driver).toBe("SQLite");
                    expect(config.wheelsdatasource.connectionString).toInclude("jdbc:sqlite:");
                });
                
                it("should handle existing SQLite databases", function() {
                    // Create databases first
                    variables.databaseService.setupSQLite(getTempDir());
                    
                    // Try to create again
                    var result = variables.databaseService.setupSQLite(getTempDir());
                    
                    expect(result.success).toBeTrue();
                    expect(result.message).toInclude("already exist");
                });
                
            });
            
            describe("Database configuration", function() {
                
                it("should create MySQL datasource configuration", function() {
                    var config = variables.databaseService.createDatasourceConfig("mysql", "myapp");
                    
                    expect(config).toBeStruct();
                    expect(config.wheelsdatasource.driver).toBe("MySQL");
                    expect(config.wheelsdatasource.class).toBe("com.mysql.cj.jdbc.Driver");
                    expect(config.wheelsdatasource.connectionString).toInclude("jdbc:mysql://");
                });
                
                it("should create PostgreSQL datasource configuration", function() {
                    var config = variables.databaseService.createDatasourceConfig("postgresql", "myapp");
                    
                    expect(config).toBeStruct();
                    expect(config.wheelsdatasource.driver).toBe("PostgreSQL");
                    expect(config.wheelsdatasource.class).toBe("org.postgresql.Driver");
                    expect(config.wheelsdatasource.connectionString).toInclude("jdbc:postgresql://");
                });
                
                it("should create SQL Server datasource configuration", function() {
                    var config = variables.databaseService.createDatasourceConfig("sqlserver", "myapp");
                    
                    expect(config).toBeStruct();
                    expect(config.wheelsdatasource.driver).toBe("MSSQL");
                    expect(config.wheelsdatasource.connectionString).toInclude("jdbc:sqlserver://");
                });
                
                it("should create H2 datasource configuration", function() {
                    var config = variables.databaseService.createDatasourceConfig("h2", "myapp");
                    
                    expect(config).toBeStruct();
                    expect(config.wheelsdatasource.driver).toBe("H2");
                    expect(config.wheelsdatasource.class).toBe("org.h2.Driver");
                });
                
                it("should use database name in connection string", function() {
                    var config = variables.databaseService.createDatasourceConfig("mysql", "testapp");
                    expect(config.wheelsdatasource.connectionString).toInclude("/testapp");
                    
                    config = variables.databaseService.createDatasourceConfig("postgresql", "testapp");
                    expect(config.wheelsdatasource.connectionString).toInclude("/testapp");
                });
                
            });
            
            describe("Database operations", function() {
                
                it("should detect database type from configuration", function() {
                    // Create server.json with datasource
                    var serverConfig = {
                        app = {
                            datasources = {
                                wheelsdatasource = {
                                    driver = "SQLite",
                                    connectionString = "jdbc:sqlite:db/test.sqlite"
                                }
                            }
                        }
                    };
                    
                    fileWrite(
                        getTempDir() & "server.json",
                        serializeJSON(serverConfig)
                    );
                    
                    var dbType = variables.databaseService.detectDatabaseType(getTempDir());
                    expect(dbType).toBe("sqlite");
                });
                
                it("should validate database configuration", function() {
                    var validConfig = {
                        driver = "MySQL",
                        connectionString = "jdbc:mysql://localhost:3306/mydb",
                        username = "root",
                        password = "password"
                    };
                    
                    var result = variables.databaseService.validateConfiguration(validConfig);
                    expect(result.valid).toBeTrue();
                    
                    var invalidConfig = {
                        driver = "MySQL"
                        // Missing connection string
                    };
                    
                    result = variables.databaseService.validateConfiguration(invalidConfig);
                    expect(result.valid).toBeFalse();
                    expect(result.errors).toBeArray();
                });
                
                it("should generate database URL correctly", function() {
                    var url = variables.databaseService.generateDatabaseURL("mysql", "localhost", 3306, "testdb");
                    expect(url).toBe("jdbc:mysql://localhost:3306/testdb");
                    
                    url = variables.databaseService.generateDatabaseURL("postgresql", "localhost", 5432, "testdb");
                    expect(url).toBe("jdbc:postgresql://localhost:5432/testdb");
                    
                    url = variables.databaseService.generateDatabaseURL("sqlite", "", 0, "test.db");
                    expect(url).toBe("jdbc:sqlite:test.db");
                });
                
            });
            
            describe("Migration support", function() {
                
                it("should create migration table SQL for different databases", function() {
                    var sqliteSql = variables.databaseService.getMigrationTableSQL("sqlite");
                    expect(sqliteSql).toInclude("CREATE TABLE IF NOT EXISTS schema_migrations");
                    expect(sqliteSql).toInclude("INTEGER PRIMARY KEY");
                    
                    var mysqlSql = variables.databaseService.getMigrationTableSQL("mysql");
                    expect(mysqlSql).toInclude("CREATE TABLE IF NOT EXISTS schema_migrations");
                    expect(mysqlSql).toInclude("BIGINT PRIMARY KEY");
                    
                    var postgresSql = variables.databaseService.getMigrationTableSQL("postgresql");
                    expect(postgresSql).toInclude("CREATE TABLE IF NOT EXISTS schema_migrations");
                    expect(postgresSql).toInclude("BIGINT PRIMARY KEY");
                });
                
                it("should handle database-specific column types", function() {
                    var sqliteType = variables.databaseService.mapColumnType("string", "sqlite");
                    expect(sqliteType).toBe("TEXT");
                    
                    var mysqlType = variables.databaseService.mapColumnType("string", "mysql");
                    expect(mysqlType).toBe("VARCHAR(255)");
                    
                    var postgresType = variables.databaseService.mapColumnType("boolean", "postgresql");
                    expect(postgresType).toBe("BOOLEAN");
                });
                
            });
            
        });
    }
}