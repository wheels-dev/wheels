component extends="testbox.system.BaseSpec" {

    // Use datasource defined in settings.cfm
    variables.datasource = application.wheels.dataSourceName;
    variables.prefix = "c_o_r_e_dbinfo_" & left(lcase(hash(createUUID())), 8) & "_";

    function beforeAll() {
        setupDatabaseVariables();
        createTestTables();
    }

    function afterAll() {
        cleanupTestTables();
    }

    function run( ) {
        g = application.wo;

        describe( "Testing $dbinfo() function for database", () => {

            it( "should return correct column information", () => {
                local.result = g.$dbinfo(
                    datasource = variables.datasource,
                    type = "columns",
                    table = variables.prefix & "users"
                );

                expect( local.result.recordCount ).toBe( 3 );
                expect( queryColumnData( local.result, "column_name" ) ).toInclude( "role_id" );
                expect( listToArray( local.result.columnList ) ).toInclude( "REFERENCED_PRIMARYKEY" );
            });

            it( "should throw an error for non-existing table", () => {
                expect( function() {
                    g.$dbinfo(
                        datasource = variables.datasource,
                        type = "columns",
                        table = variables.prefix & "invalid_users"
                    );
                } ).toThrow();
            });

            it( "should return column info for valid table", () => {
                local.result = g.$dbinfo(
                    datasource = variables.datasource,
                    type = "columns",
                    table = variables.prefix & "roles"
                );

                expect( local.result.recordCount ).toBe( 2 );
                expect( queryColumnData( local.result, "column_name" ) ).toInclude( "role_id" );
                expect( queryColumnData( local.result, "column_name" ) ).toInclude( "role_name" );
            });

            it( "should return correct index information", () => {
                local.result = g.$dbinfo(
                    datasource = variables.datasource,
                    type = "index",
                    table = variables.prefix & "roles"
                );

                switch( variables.dbAdapter ) {
                    case "Oracle":
                    case "SQLServer":
                        // If running in BoxLang, expect 1 instead of 2
                        if ( structKeyExists(server, "boxlang") ) {
                            expect( local.result.recordCount ).toBe( 1 );
                        } else {
                            expect( local.result.recordCount ).toBe( 2 );
                        }
                        break;
                    default:
                        expect( local.result.recordCount ).toBe( 1 );
                }

                expect( queryColumnData( local.result, "column_name" ) ).toInclude( "role_id" );
            });

            it( "should return correct database version info", () => {
                local.result = g.$dbinfo(
                    datasource = variables.datasource,
                    type = "version"
                );

                expect( local.result.recordCount ).toBe( 1 );
            });

            it( "should return tables matching exact pattern", () => {
                local.result = g.$dbinfo(
                    datasource = variables.datasource,
                    type = "tables",
                    pattern = variables.prefix & "users%"
                );

                expect( local.result.recordCount ).toBe( 1 );
            });

            it( "should return tables matching wildcard pattern", () => {
                local.result = g.$dbinfo(
                    datasource = variables.datasource,
                    type = "tables",
                    pattern = variables.prefix & "%"
                );

                expect( local.result.recordCount ).toBe( 3 );
            });

            it( "should return all tables and views with pattern", () => {
                local.result = g.$dbinfo(
                    datasource = variables.datasource,
                    type = "tables",
                    pattern = variables.prefix & "%"
                );

                expect( local.result.recordCount ).toBe( 3 );
                
                // Should find both tables and view
                local.tableNames = queryColumnData( local.result, "table_name" );
                expect( local.tableNames ).toInclude( variables.prefix & "users" );
                expect( local.tableNames ).toInclude( variables.prefix & "roles" );
                expect( local.tableNames ).toInclude( variables.prefix & "v_users" );
            });

        });
    }

    // Helper functions using populate.cfm approach
    
    private void function setupDatabaseVariables() {
        // Get database info like populate.cfm does
        cfdbinfo(name="local.dbinfo", datasource=variables.datasource, type="version");
        variables.db = LCase(Replace(local.dbinfo.database_productname, " ", "", "all"));
        
        // Set the dbAdapter variable that tests expect
        variables.dbAdapter = application.wheels.adapterName;
        
        // Set database-specific column types like populate.cfm
        variables.identityColumnType = "";
        variables.storageEngine = "";
        variables.intColumnType = "INT";
        variables.varcharType = "VARCHAR";
        
        if (variables.db == "microsoftsqlserver") {
            variables.identityColumnType = "INT NOT NULL IDENTITY(1,1)";
            variables.varcharType = "VARCHAR";
        } else if (variables.db == "mysql" || variables.db == "mariadb") {
            variables.identityColumnType = "INT NOT NULL AUTO_INCREMENT";
            variables.storageEngine = "ENGINE=InnoDB";
            variables.varcharType = "VARCHAR";
        } else if (variables.db == "postgresql") {
            variables.identityColumnType = "SERIAL NOT NULL";
            variables.varcharType = "VARCHAR";
        } else if (variables.db == "oracle") {
            variables.identityColumnType = "INTEGER GENERATED BY DEFAULT AS IDENTITY";
            variables.intColumnType = "NUMBER(10)";
            variables.varcharType = "VARCHAR2";
        } else {
            // Default (H2, etc.)
            variables.identityColumnType = "INT NOT NULL IDENTITY";
            variables.varcharType = "VARCHAR";
        }
    }
    
    private void function createTestTables() {
        // Create roles table
        query datasource=variables.datasource {
            echo("
                CREATE TABLE #variables.prefix#roles (
                    role_id #variables.identityColumnType#,
                    role_name #variables.varcharType#(100) DEFAULT NULL,
                    PRIMARY KEY (role_id)
                ) #variables.storageEngine#
            ");
        }

        // Create users table  
        query datasource=variables.datasource {
            echo("
                CREATE TABLE #variables.prefix#users (
                    user_id #variables.varcharType#(50) NOT NULL,
                    user_name #variables.varcharType#(50) NOT NULL,
                    role_id #variables.intColumnType# DEFAULT NULL,
                    PRIMARY KEY (user_id)
                ) #variables.storageEngine#
            ");
        }

        // Add foreign key
        query datasource=variables.datasource {
            echo("
                ALTER TABLE #variables.prefix#users
                ADD CONSTRAINT fk_#variables.prefix#_user_role_id
                FOREIGN KEY (role_id)
                REFERENCES #variables.prefix#roles (role_id)
            ");
        }

        // Add index
        query datasource=variables.datasource {
            echo("CREATE INDEX idx_#variables.prefix#_users_role_id ON #variables.prefix#users(role_id)");
        }

        // Create a view
        query datasource=variables.datasource {
            echo("
                CREATE VIEW #variables.prefix#v_users AS
                SELECT u.user_id, u.user_name, r.role_id, r.role_name
                FROM #variables.prefix#users u
                JOIN #variables.prefix#roles r ON r.role_id = u.role_id
            ");
        }
    }
    
    private void function cleanupTestTables() {
        // Get current table list like populate.cfm does
        cfdbinfo(name="local.dbinfo", datasource=variables.datasource, type="tables");
        local.tableList = ValueList(local.dbinfo.table_name, Chr(7));
        
        // Drop view first
        if (ListFindNoCase(local.tableList, variables.prefix & "v_users", Chr(7))) {
            try {
                query datasource=variables.datasource {
                    echo("DROP VIEW #variables.prefix#v_users");
                }
            } catch (any e) {}
        }
        
        // Drop tables
        local.testTables = "#variables.prefix#users,#variables.prefix#roles";
        for (local.table in ListToArray(local.testTables)) {
            if (ListFindNoCase(local.tableList, local.table, Chr(7))) {
                try {
                    query datasource=variables.datasource {
                        echo("DROP TABLE #local.table#");
                    }
                } catch (any e) {}
            }
        }
    }
}
