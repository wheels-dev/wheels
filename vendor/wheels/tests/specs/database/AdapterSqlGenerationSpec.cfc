component extends="wheels.WheelsTest" {

    /**
     * Unit coverage for the per-database adapters' PURE SQL-generation
     * functions. No live MySQL/Oracle/SQL Server/H2/PostgreSQL connection is
     * needed — the adapters instantiate standalone and these functions build
     * SQL strings (or simple values) only. Live per-DB execution is covered
     * by the compat-matrix legs; this spec makes the sqlite leg exercise the
     * generators on every engine in CI.
     */

    function run() {

        describe("adapter SQL generation (unit)", () => {

            describe("$upsertSQL", () => {

                // Shared upsert arguments; every adapter takes the same shape.
                // $buildBulkParam reads type/dataType/scale/nullable from the
                // propertyInfo entry, mirroring the model class metadata.
                upsertArgs = function() {
                    return {
                        tableName = "c_o_r_e_bulkitems",
                        columns = ["code", "name"],
                        uniqueBy = ["code"],
                        updateColumns = ["name"],
                        validProperties = ["code", "name"],
                        records = [
                            {code = "A1", name = "first"},
                            {code = "A2", name = "second"}
                        ],
                        batchStart = 1,
                        batchEnd = 2,
                        propertyInfo = {
                            code = {type = "string", dataType = "varchar", scale = 0, nullable = false},
                            name = {type = "string", dataType = "varchar", scale = 0, nullable = false}
                        }
                    };
                };

                it("MySQL emits INSERT ... ON DUPLICATE KEY UPDATE", () => {
                    var adapter = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
                    var sql = adapter.$upsertSQL(argumentCollection = upsertArgs());
                    var joined = "";
                    for (var part in sql) {
                        if (IsSimpleValue(part)) joined &= part;
                    }
                    expect(sql).toBeArray();
                    expect(joined).toInclude("INSERT INTO c_o_r_e_bulkitems");
                    expect(joined).toInclude("ON DUPLICATE KEY UPDATE");
                });

                it("H2 emits MERGE INTO ... KEY (...) VALUES", () => {
                    var adapter = CreateObject("component", "wheels.databaseAdapters.H2.H2Model");
                    var sql = adapter.$upsertSQL(argumentCollection = upsertArgs());                    var joined = "";
                    for (var part in sql) {
                        if (IsSimpleValue(part)) joined &= part;
                    }

                    expect(joined).toInclude("MERGE INTO c_o_r_e_bulkitems");
                    expect(joined).toInclude("KEY");
                });

                it("PostgreSQL emits INSERT ... ON CONFLICT ... DO UPDATE", () => {
                    var adapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel");
                    var sql = adapter.$upsertSQL(argumentCollection = upsertArgs());                    var joined = "";
                    for (var part in sql) {
                        if (IsSimpleValue(part)) joined &= part;
                    }

                    expect(joined).toInclude("ON CONFLICT");
                    expect(joined).toInclude("DO UPDATE");
                });

                it("SQL Server emits MERGE INTO ... WITH (HOLDLOCK)", () => {
                    var adapter = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
                    var sql = adapter.$upsertSQL(argumentCollection = upsertArgs());                    var joined = "";
                    for (var part in sql) {
                        if (IsSimpleValue(part)) joined &= part;
                    }

                    expect(joined).toInclude("MERGE INTO");
                    expect(joined).toInclude("WITH (HOLDLOCK)");
                });

                it("Oracle emits a MERGE INTO ... USING dual clause", () => {
                    var adapter = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleModel");
                    var sql = adapter.$upsertSQL(argumentCollection = upsertArgs());                    var joined = "";
                    for (var part in sql) {
                        if (IsSimpleValue(part)) joined &= part;
                    }

                    expect(joined).toInclude("MERGE INTO c_o_r_e_bulkitems");
                    expect(joined).toInclude("FROM dual");
                });

            });

            describe("Base adapter helpers", () => {

                it("$addColumnsToSelectAndGroupBy appends ORDER BY columns into GROUP BY", () => {
                    var adapter = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
                    var args = {
                        sql = [
                            "SELECT",
                            "COUNT(authorid) AS x",
                            "GROUP BY authorid",
                            "ORDER BY authorid, title"
                        ]
                    };
                    adapter.$addColumnsToSelectAndGroupBy(args = args);
                    expect(args.sql[3]).toInclude("authorid");
                    expect(args.sql[3]).toInclude("title");
                });

                it("$defaultValues returns the DEFAULT VALUES fragment", () => {
                    var adapter = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
                    expect(adapter.$defaultValues()).toBe(" DEFAULT VALUES");
                });

                it("$isBoxLangEngine returns a boolean", () => {
                    var adapter = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
                    expect(adapter.$isBoxLangEngine()).toBeTypeOf("boolean");
                });

                it("$forUpdateClause returns '' on adapters without row locking", () => {
                    var adapter = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
                    expect(adapter.$forUpdateClause()).toBe("");
                });

            });

            describe("per-adapter model helpers", () => {

                it("PostgreSQL/MSSQL/MySQL $quoteIdentifier wrap identifiers", () => {
                    var pg = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel");
                    expect(pg.$quoteIdentifier(name = "Users")).toBe('"users"');
                    var mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
                    expect(mssql.$quoteIdentifier(name = "Users")).toInclude("Users");
                    var mysql = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
                    expect(mysql.$quoteIdentifier(name = "Users")).toInclude("Users");
                });

                it("Oracle $tableAlias joins table and alias", () => {
                    var oracle = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleModel");
                    expect(oracle.$tableAlias(table = "users", alias = "u")).toBe("users u");
                });

                it("H2/Oracle $lowerCaseColumnNames report their column folding", () => {
                    var h2 = CreateObject("component", "wheels.databaseAdapters.H2.H2Model");
                    expect(h2.$lowerCaseColumnNames()).toBeTrue();
                    var oracle = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleModel");
                    expect(oracle.$lowerCaseColumnNames()).toBeTypeOf("boolean");
                });

                it("MySQL/Oracle $defaultValues emit their dialect fragment", () => {
                    var mysql = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
                    expect(mysql.$defaultValues()).toBe("() VALUES()");
                    var oracle = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleModel");
                    expect(oracle.$defaultValues($primaryKey = "id")).toBe("(id) VALUES(DEFAULT)");
                });

                it("MSSQL $forUpdateClause returns its dialect default", () => {
                    var mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
                    expect(mssql.$forUpdateClause()).toBeTypeOf("string");
                });

                it("MSSQL/PostgreSQL $randomOrder emit dialect-specific randomness", () => {
                    var mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
                    expect(mssql.$randomOrder()).toBe("NEWID()");
                    var pg = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel");
                    expect(pg.$randomOrder()).toInclude("RANDOM");
                });

                it("$supportsAdvisoryLocks reports per-adapter support", () => {
                    var pg = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel");
                    expect(pg.$supportsAdvisoryLocks()).toBeTrue();
                    var mysql = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
                    expect(mysql.$supportsAdvisoryLocks()).toBeTrue();
                    var mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
                    expect(mssql.$supportsAdvisoryLocks()).toBeTypeOf("boolean");
                });

            });

            describe("Microsoft SQL Server migrator", () => {

                beforeEach(() => {
                    adapter = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerMigrator");
                });

                it("adapterName()", () => {
                    expect(adapter.adapterName()).toInclude("Microsoft");
                });

                it("addPrimaryKeyOptions() builds NOT NULL + IDENTITY + PRIMARY KEY", () => {
                    expect(adapter.addPrimaryKeyOptions(sql = "int")).toBe("int NOT NULL PRIMARY KEY");
                    expect(adapter.addPrimaryKeyOptions(sql = "int", options = {autoIncrement = true}))
                        .toInclude("IDENTITY(1,1)");
                    expect(adapter.addPrimaryKeyOptions(sql = "int", options = {allowNull = true}))
                        .toInclude("NULL");
                });

                it("addForeignKeyOptions() decorates the column sql", () => {
                    var out = adapter.addForeignKeyOptions(
                        sql = "userid int",
                        options = {column = "userid", referenceTable = "users", referenceColumn = "id"}
                    );
                    expect(out).toInclude("userid int");
                    expect(out).toInclude("FOREIGN KEY");
                    expect(out).toInclude("REFERENCES");
                });

                it("renameTable()/dropTable()/dropView()", () => {
                    expect(adapter.renameTable(oldName = "users", newName = "people")).toInclude("sp_rename");
                    expect(adapter.dropTable(name = "users")).toInclude("DROP TABLE");
                    expect(adapter.dropView(name = "v_users")).toInclude("DROP VIEW");
                });

                it("renameColumnInTable()", () => {
                    expect(adapter.renameColumnInTable(name = "users", columnName = "name", newColumnName = "fullname"))
                        .toInclude("sp_rename");
                });

                it("dropForeignKeyFromTable()", () => {
                    expect(adapter.dropForeignKeyFromTable(name = "posts", keyName = "FK_posts"))
                        .toInclude("DROP CONSTRAINT");
                });

                it("removeIndex()", () => {
                    expect(adapter.removeIndex(table = "posts", indexName = "idx_posts_authorid"))
                        .toInclude("DROP INDEX");
                });

                it("addRecordPrefix()/addRecordSuffix() wrap a row prefix", () => {
                    expect(adapter.addRecordPrefix(table = "posts")).toInclude("IDENTITY_INSERT");
                    expect(adapter.addRecordSuffix(table = "posts")).notToBe("");
                });

            });

            describe("Oracle migrator", () => {

                beforeEach(() => {
                    adapter = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleMigrator");
                });

                it("adapterName()", () => {
                    expect(adapter.adapterName()).toInclude("Oracle");
                });

                it("addIndex() builds CREATE [UNIQUE] INDEX", () => {
                    expect(adapter.addIndex(table = "posts", columnNames = "authorid"))
                        .toInclude("CREATE INDEX");
                    expect(adapter.addIndex(table = "posts", columnNames = "authorid", unique = true))
                        .toInclude("CREATE UNIQUE INDEX");
                });

                it("removeIndex()", () => {
                    expect(adapter.removeIndex(table = "posts", indexName = "idx_posts_authorid"))
                        .toInclude("DROP INDEX");
                });

                it("addPrimaryKeyOptions()", () => {
                    expect(adapter.addPrimaryKeyOptions(sql = "NUMBER(10)")).toInclude("NUMBER(10)");
                });

                it("renameTable()/renameColumnInTable()", () => {
                    expect(adapter.renameTable(oldName = "users", newName = "people")).toInclude("RENAME");
                    expect(adapter.renameColumnInTable(name = "users", columnName = "name", newColumnName = "fullname"))
                        .toInclude("RENAME");
                });

                it("dropForeignKeyFromTable()", () => {
                    expect(adapter.dropForeignKeyFromTable(name = "posts", keyName = "FK_posts"))
                        .toInclude("DROP CONSTRAINT");
                });

                it("addColumnToTable()/changeColumnInTable() use a ColumnDefinition", () => {
                    var column = new wheels.migrator.ColumnDefinition(
                        adapter = adapter,
                        name = "title",
                        type = "string"
                    );
                    expect(adapter.addColumnToTable(name = "posts", column = column))
                        .toInclude("ALTER TABLE");
                    expect(adapter.changeColumnInTable(name = "posts", column = column))
                        .toInclude("ALTER TABLE");
                });

            });

            describe("MySQL migrator", () => {

                beforeEach(() => {
                    adapter = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLMigrator");
                });

                it("adapterName()", () => {
                    expect(adapter.adapterName()).toInclude("MySQL");
                });

                it("addPrimaryKeyOptions()", () => {
                    expect(adapter.addPrimaryKeyOptions(sql = "int", options = {autoIncrement = true}))
                        .toInclude("AUTO_INCREMENT");
                });

                it("addForeignKeyOptions()", () => {
                    var out = adapter.addForeignKeyOptions(
                        sql = "userid int",
                        options = {column = "userid", referenceTable = "users", referenceColumn = "id"}
                    );
                    expect(out).toInclude("userid int");
                    expect(out).toInclude("FOREIGN KEY");
                });

                it("quoteTableName()", () => {
                    expect(adapter.quoteTableName(name = "users")).toInclude("users");
                });

                it("removeIndex()", () => {
                    expect(adapter.removeIndex(table = "posts", indexName = "idx_posts_authorid"))
                        .toInclude("DROP INDEX");
                });

            });

            describe("H2 migrator", () => {

                beforeEach(() => {
                    adapter = CreateObject("component", "wheels.databaseAdapters.H2.H2Migrator");
                });

                it("adapterName()", () => {
                    expect(adapter.adapterName()).toInclude("H2");
                });

                it("addPrimaryKeyOptions()", () => {
                    expect(adapter.addPrimaryKeyOptions(sql = "int", options = {autoIncrement = true}))
                        .toBe("int NOT NULL AUTO_INCREMENT");
                });

                it("createTable() builds DDL from ColumnDefinitions", () => {
                    var pk = new wheels.migrator.ColumnDefinition(
                        adapter = adapter,
                        name = "id",
                        type = "integer"
                    );
                    var col = new wheels.migrator.ColumnDefinition(
                        adapter = adapter,
                        name = "title",
                        type = "string"
                    );
                    var sql = adapter.createTable(name = "h2unit", columns = [col], primaryKeys = [pk]);
                    expect(sql).toInclude("CREATE TABLE");
                    expect(sql).toInclude("h2unit");
                    expect(sql).toInclude("title");
                });

                it("quoteTableName()/quoteColumnName()", () => {
                    expect(adapter.quoteTableName(name = "users")).toInclude("users");
                    expect(adapter.quoteColumnName(name = "title")).toInclude("title");
                });

                it("renameTable()/renameColumnInTable()/dropForeignKeyFromTable()", () => {
                    expect(adapter.renameTable(oldName = "users", newName = "people"))
                        .toInclude("RENAME");
                    expect(adapter.renameColumnInTable(name = "users", columnName = "name", newColumnName = "fullname"))
                        .toInclude("RENAME");
                    expect(adapter.dropForeignKeyFromTable(name = "posts", keyName = "FK_posts"))
                        .toInclude("DROP CONSTRAINT");
                });

                it("changeColumnInTable()", () => {
                    var col = new wheels.migrator.ColumnDefinition(
                        adapter = adapter,
                        name = "title",
                        type = "string"
                    );
                    expect(adapter.changeColumnInTable(name = "posts", column = col))
                        .toInclude("ALTER TABLE");
                });

            });

            describe("PostgreSQL migrator", () => {

                beforeEach(() => {
                    adapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator");
                });

                it("adapterName()", () => {
                    expect(adapter.adapterName()).toInclude("PostgreSQL");
                });

                it("addPrimaryKeyOptions()", () => {
                    expect(adapter.addPrimaryKeyOptions(sql = "SERIAL")).toInclude("SERIAL");
                });

                it("renameTable()/dropForeignKeyFromTable()", () => {
                    expect(adapter.renameTable(oldName = "users", newName = "people"))
                        .toInclude("RENAME");
                    expect(adapter.dropForeignKeyFromTable(name = "posts", keyName = "FK_posts"))
                        .toInclude("DROP CONSTRAINT");
                });

            });

        });

    }

}
