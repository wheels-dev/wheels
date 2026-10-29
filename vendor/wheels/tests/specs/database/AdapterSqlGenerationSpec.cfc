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

                it("$quoteIdentifier doubles the closing delimiter inside a name, per adapter", () => {
                    var sqlite = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
                    expect(sqlite.$quoteIdentifier(name = "users")).toBe('"users"');
                    expect(sqlite.$quoteIdentifier(name = 'we"ird')).toBe('"we""ird"');
                    var pg = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel");
                    expect(pg.$quoteIdentifier(name = 'We"ird')).toBe('"we""ird"');
                    var crdb = CreateObject("component", "wheels.databaseAdapters.CockroachDB.CockroachDBModel");
                    expect(crdb.$quoteIdentifier(name = 'We"ird')).toBe('"we""ird"');
                    var oracle = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleModel");
                    expect(oracle.$quoteIdentifier(name = "users")).toBe('"USERS"');
                    expect(oracle.$quoteIdentifier(name = 'we"ird')).toBe('"WE""IRD"');
                    var mysql = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
                    expect(mysql.$quoteIdentifier(name = "users")).toBe("`users`");
                    expect(mysql.$quoteIdentifier(name = "we`ird")).toBe("`we``ird`");
                    var mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
                    expect(mssql.$quoteIdentifier(name = "users")).toBe("[users]");
                    expect(mssql.$quoteIdentifier(name = "we]ird")).toBe("[we]]ird]");
                    expect(mssql.$quoteIdentifier(name = "we[ird")).toBe("[we[ird]");
                });

                it("$quoteIdentifier doubles each of several consecutive delimiters", () => {
                    var sqlite = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
                    expect(sqlite.$quoteIdentifier(name = 'a""b')).toBe('"a""""b"');
                    var pg = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel");
                    expect(pg.$quoteIdentifier(name = 'A""b')).toBe('"a""""b"');
                    var oracle = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleModel");
                    expect(oracle.$quoteIdentifier(name = 'a""b')).toBe('"A""""B"');
                    var mysql = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
                    expect(mysql.$quoteIdentifier(name = "a``b")).toBe("`a````b`");
                    var mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
                    expect(mssql.$quoteIdentifier(name = "a]]b")).toBe("[a]]]]b]");
                });

                it("H2 $quoteIdentifier quotes in the datasource's own fold case (##4440)", () => {
                    var upper = CreateObject("component", "wheels.tests._assets.adapters.H2CaseProbe");
                    upper.identifierCase = "upper";
                    expect(upper.$quoteIdentifier(name = "users")).toBe('"USERS"');
                    expect(upper.$quoteIdentifier(name = "order")).toBe('"ORDER"');
                    expect(upper.$quoteIdentifier(name = 'we"ird')).toBe('"WE""IRD"');
                    expect(upper.$quoteIdentifier(name = 'a""b')).toBe('"A""""B"');

                    var lower = CreateObject("component", "wheels.tests._assets.adapters.H2CaseProbe");
                    lower.identifierCase = "lower";
                    expect(lower.$quoteIdentifier(name = "USERS")).toBe('"users"');
                    expect(lower.$quoteIdentifier(name = "ORDER")).toBe('"order"');
                    expect(lower.$quoteIdentifier(name = 'We"ird')).toBe('"we""ird"');
                    expect(lower.$quoteIdentifier(name = 'a""b')).toBe('"a""""b"');

                    var none = CreateObject("component", "wheels.tests._assets.adapters.H2CaseProbe");
                    none.identifierCase = "none";
                    expect(none.$quoteIdentifier(name = "users")).toBe("users");
                    expect(none.$quoteIdentifier(name = "order")).toBe("order");
                    expect(none.$quoteIdentifier(name = 'we"ird')).toBe('we"ird');
                });

                it("H2 classifies the verified identifier-folding settings shapes (##4629)", () => {
                    var h2 = CreateObject("component", "wheels.databaseAdapters.H2.H2Model");
                    var cases = [
                        {settings = {}, expected = "upper"},
                        {settings = {DATABASE_TO_UPPER = "TRUE"}, expected = "upper"},
                        {settings = {DATABASE_TO_UPPER = "FALSE"}, expected = "upper"},
                        {settings = {DATABASE_TO_LOWER = "FALSE", DATABASE_TO_UPPER = "TRUE"}, expected = "upper"},
                        {settings = {DATABASE_TO_LOWER = "FALSE", DATABASE_TO_UPPER = "FALSE"}, expected = "none"},
                        // Lower-case values reach the none branch through UCase(Trim()) on
                        // DATABASE_TO_UPPER (the LOWER branch returns before reading it).
                        {settings = {DATABASE_TO_LOWER = "false", DATABASE_TO_UPPER = "false"}, expected = "none"},
                        {settings = {DATABASE_TO_LOWER = " false ", DATABASE_TO_UPPER = " false "}, expected = "none"},
                        {settings = {DATABASE_TO_LOWER = "TRUE"}, expected = "lower"},
                        {settings = {DATABASE_TO_LOWER = "TRUE", DATABASE_TO_UPPER = "FALSE"}, expected = "lower"},
                        {settings = {DATABASE_TO_LOWER = "FALSE"}, expected = "upper"},
                        {settings = {DATABASE_TO_LOWER = "true", DATABASE_TO_UPPER = "false"}, expected = "lower"},
                        {settings = {DATABASE_TO_LOWER = "TRUE", NON_KEYWORDS = "ORDER,GROUP"}, expected = "lower"}
                    ];
                    for (var testCase in cases) {
                        var label = SerializeJSON(testCase.settings);
                        expect(h2.$classifyIdentifierCase(settings = testCase.settings)).toBe(
                            testCase.expected,
                            "classification for " & label
                        );
                    }
                });

                it("adapters without datasource-dependent quoting key as datasource-independent (##4629)", () => {
                    var base = CreateObject("component", "wheels.databaseAdapters.Base");
                    expect(base.$identifierCase()).toBe("");
                    var sqlite = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
                    expect(sqlite.$identifierCase()).toBe("");
                });

                it("H2 without a datasource reports no folding and leaves identifiers unquoted", () => {
                    var h2 = CreateObject("component", "wheels.databaseAdapters.H2.H2Model");
                    expect(h2.$identifierCase()).toBe("none");
                    expect(h2.$quoteIdentifier(name = "users")).toBe("users");
                });

                it("migrator quoteTableName/quoteColumnName double the closing delimiter, per adapter", () => {
                    // lower-case inputs, so the output does not depend on migratorObjectCase
                    var sqlite = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteMigrator");
                    expect(sqlite.quoteTableName(name = "users")).toBe('"users"');
                    expect(sqlite.quoteTableName(name = "main.users")).toBe('"main"."users"');
                    expect(sqlite.quoteTableName(name = 'main.we"ird')).toBe('"main"."we""ird"');
                    expect(sqlite.quoteColumnName(name = "title")).toBe('"title"');
                    expect(sqlite.quoteColumnName(name = 'we"ird')).toBe('"we""ird"');
                    var mysql = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLMigrator");
                    expect(mysql.quoteTableName(name = "users")).toBe("`users`");
                    expect(mysql.quoteTableName(name = "app.users")).toBe("`app`.`users`");
                    expect(mysql.quoteTableName(name = "app.we`ird")).toBe("`app`.`we``ird`");
                    expect(mysql.quoteColumnName(name = "title")).toBe("`title`");
                    expect(mysql.quoteColumnName(name = "we`ird")).toBe("`we``ird`");
                    var mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerMigrator");
                    expect(mssql.quoteTableName(name = "users")).toBe("[users]");
                    expect(mssql.quoteTableName(name = "dbo.users")).toBe("[dbo].[users]");
                    expect(mssql.quoteTableName(name = "dbo.we]ird")).toBe("[dbo].[we]]ird]");
                    expect(mssql.quoteColumnName(name = "title")).toBe("[title]");
                    expect(mssql.quoteColumnName(name = "we]ird")).toBe("[we]]ird]");
                });

                it("migrator quoting escapes consecutive delimiters and both parts of a dotted name", () => {
                    var sqlite = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteMigrator");
                    expect(sqlite.quoteColumnName(name = 'a""b')).toBe('"a""""b"');
                    expect(sqlite.quoteTableName(name = 'we"a.we"b')).toBe('"we""a"."we""b"');
                    var mysql = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLMigrator");
                    expect(mysql.quoteColumnName(name = "a``b")).toBe("`a````b`");
                    expect(mysql.quoteTableName(name = "we`a.we`b")).toBe("`we``a`.`we``b`");
                    var mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerMigrator");
                    expect(mssql.quoteColumnName(name = "a]]b")).toBe("[a]]]]b]");
                    expect(mssql.quoteTableName(name = "we]a.we]b")).toBe("[we]]a].[we]]b]");
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
                    expect(mssql.$supportsAdvisoryLocks()).toBeTrue();
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
                    variables.savedObjectCase = application.wheels.migratorObjectCase;
                });

                afterEach(() => {
                    application.wheels.migratorObjectCase = variables.savedObjectCase;
                });

                it("adapterName()", () => {
                    expect(adapter.adapterName()).toInclude("Oracle");
                });

                it("reports the upper DDL identifier case (##4629)", () => {
                    expect(adapter.$ddlIdentifierCase()).toBe("upper");
                });

                it("quotes table/column identifiers uppercase, without double quoting (##4629)", () => {
                    expect(adapter.quoteTableName(name = "users")).toBe('"USERS"');
                    expect(adapter.quoteTableName(name = "public.users")).toBe('"PUBLIC"."USERS"');
                    expect(adapter.quoteTableName(name = 'public.we"ird')).toBe('"PUBLIC"."WE""IRD"');
                    expect(adapter.quoteColumnName(name = "title")).toBe('"TITLE"');
                    expect(adapter.quoteColumnName(name = 'we"ird')).toBe('"WE""IRD"');
                });

                it("ignores migratorObjectCase while quoting is active (##4629)", () => {
                    application.wheels.migratorObjectCase = "lower";
                    expect(adapter.quoteTableName(name = "users")).toBe('"USERS"');
                    application.wheels.migratorObjectCase = "upper";
                    expect(adapter.quoteTableName(name = "users")).toBe('"USERS"');
                    expect(adapter.quoteColumnName(name = "title")).toBe('"TITLE"');
                });

                it("createTable() quotes the table, columns and tablespace", () => {
                    var pk = new wheels.migrator.ColumnDefinition(adapter = adapter, name = "id", type = "integer");
                    var col = new wheels.migrator.ColumnDefinition(adapter = adapter, name = "title", type = "string");
                    var sql = adapter.createTable(name = "oraunit", columns = [col], primaryKeys = [pk]);
                    expect(sql).toInclude('CREATE TABLE "ORAUNIT"');
                    expect(sql).toInclude('"ID" NUMBER(10) NOT NULL PRIMARY KEY');
                    expect(sql).toInclude('"TITLE" VARCHAR2(255)');

                    var withTablespace = adapter.createTable(
                        name = "oraunit",
                        columns = [col],
                        primaryKeys = [pk],
                        options = {tablespace = "users"}
                    );
                    expect(withTablespace).toInclude('TABLESPACE "USERS"');
                });

                it("routes rename/change/drop/add column and foreign-key DDL through the quoted identifiers", () => {
                    var col = new wheels.migrator.ColumnDefinition(adapter = adapter, name = "title", type = "string");
                    expect(adapter.renameTable(oldName = "users", newName = "people"))
                        .toBe('ALTER TABLE "USERS" RENAME TO "PEOPLE"');
                    expect(adapter.renameColumnInTable(name = "users", columnName = "name", newColumnName = "fullname"))
                        .toBe('ALTER TABLE "USERS" RENAME COLUMN "NAME" TO "FULLNAME"');
                    expect(adapter.addColumnToTable(name = "posts", column = col))
                        .toBe('ALTER TABLE "POSTS" ADD "TITLE" VARCHAR2(255)');
                    expect(adapter.changeColumnInTable(name = "posts", column = col))
                        .toBe('ALTER TABLE "POSTS" MODIFY "TITLE" VARCHAR2(255)');
                    expect(adapter.dropForeignKeyFromTable(name = "posts", keyName = "FK_posts"))
                        .toBe('ALTER TABLE "POSTS" DROP CONSTRAINT "FK_POSTS"');
                    expect(adapter.dropTable(name = "users")).toBe(
                        "BEGIN EXECUTE IMMEDIATE 'DROP TABLE ""USERS"" CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;"
                    );
                    expect(adapter.dropView(name = "user_summaries")).toBe(
                        "BEGIN EXECUTE IMMEDIATE 'DROP VIEW ""USER_SUMMARIES""'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;"
                    );
                });

                it("routes index DDL through the quoted identifiers", () => {
                    expect(adapter.addIndex(table = "posts", columnNames = "authorid"))
                        .toBe('CREATE INDEX "POSTS_AUTHORID" ON "POSTS"("AUTHORID")');
                    expect(adapter.addIndex(table = "posts", columnNames = "authorid", unique = true, indexName = "idx_pa"))
                        .toBe('CREATE UNIQUE INDEX "IDX_PA" ON "POSTS"("AUTHORID")');
                    expect(adapter.removeIndex(table = "posts", indexName = "idx_posts_authorid"))
                        .toBe('DROP INDEX "IDX_POSTS_AUTHORID"');
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
                    adapter = CreateObject("component", "wheels.tests._assets.adapters.H2MigratorCaseProbe");
                    variables.savedObjectCase = application.wheels.migratorObjectCase;
                });

                afterEach(() => {
                    application.wheels.migratorObjectCase = variables.savedObjectCase;
                });

                it("adapterName()", () => {
                    expect(adapter.adapterName()).toInclude("H2");
                });

                it("addPrimaryKeyOptions()", () => {
                    expect(adapter.addPrimaryKeyOptions(sql = "int", options = {autoIncrement = true}))
                        .toBe("int NOT NULL AUTO_INCREMENT");
                });

                it("quotes table/column identifiers in the upper fold case", () => {
                    adapter.identifierCase = "upper";
                    expect(adapter.quoteTableName(name = "users")).toBe('"USERS"');
                    expect(adapter.quoteTableName(name = "PUBLIC.users")).toBe('"PUBLIC"."USERS"');
                    expect(adapter.quoteColumnName(name = "title")).toBe('"TITLE"');
                    expect(adapter.quoteColumnName(name = 'we"ird')).toBe('"WE""IRD"');
                });

                it("quotes table/column identifiers in the lower fold case", () => {
                    adapter.identifierCase = "lower";
                    expect(adapter.quoteTableName(name = "USERS")).toBe('"users"');
                    expect(adapter.quoteTableName(name = "PUBLIC.USERS")).toBe('"public"."users"');
                    expect(adapter.quoteColumnName(name = "TITLE")).toBe('"title"');
                    expect(adapter.quoteColumnName(name = 'We"ird')).toBe('"we""ird"');
                });

                it("keeps the unquoted objectCase path when folding is off", () => {
                    adapter.identifierCase = "none";
                    application.wheels.migratorObjectCase = "";
                    expect(adapter.quoteTableName(name = "users")).toBe("users");
                    expect(adapter.quoteTableName(name = "PUBLIC.users")).toBe("PUBLIC.users");
                    application.wheels.migratorObjectCase = "lower";
                    expect(adapter.quoteTableName(name = "USERS")).toBe("users");
                    expect(adapter.quoteTableName(name = "PUBLIC.USERS")).toBe("public.users");
                    application.wheels.migratorObjectCase = "upper";
                    expect(adapter.quoteTableName(name = "users")).toBe("USERS");
                    expect(adapter.quoteTableName(name = "public.users")).toBe("PUBLIC.USERS");
                });

                it("ignores migratorObjectCase while quoting is active (##4629)", () => {
                    adapter.identifierCase = "upper";
                    application.wheels.migratorObjectCase = "lower";
                    expect(adapter.quoteTableName(name = "users")).toBe('"USERS"');
                    adapter.identifierCase = "none";
                    expect(adapter.quoteTableName(name = "users")).toBe("users");
                });

                it("createTable() builds quoted DDL from ColumnDefinitions", () => {
                    adapter.identifierCase = "upper";
                    var pk = new wheels.migrator.ColumnDefinition(adapter = adapter, name = "id", type = "integer");
                    var col = new wheels.migrator.ColumnDefinition(adapter = adapter, name = "title", type = "string");
                    var sql = adapter.createTable(name = "h2unit", columns = [col], primaryKeys = [pk]);
                    expect(sql).toInclude('CREATE TABLE "H2UNIT"');
                    expect(sql).toInclude('"ID" INTEGER');
                    expect(sql).toInclude('PRIMARY KEY ("ID")');
                    expect(sql).toInclude('"TITLE" VARCHAR');
                });

                it("routes rename/change/drop DDL through the quoted identifiers", () => {
                    adapter.identifierCase = "upper";
                    var col = new wheels.migrator.ColumnDefinition(adapter = adapter, name = "title", type = "string");
                    expect(adapter.renameTable(oldName = "users", newName = "people"))
                        .toBe('ALTER TABLE "USERS" RENAME TO "PEOPLE"');
                    expect(adapter.renameColumnInTable(name = "users", columnName = "name", newColumnName = "fullname"))
                        .toBe('ALTER TABLE "USERS" ALTER COLUMN "NAME" RENAME TO "FULLNAME"');
                    expect(adapter.changeColumnInTable(name = "posts", column = col))
                        .toInclude('ALTER TABLE "POSTS" ALTER COLUMN "TITLE"');
                    expect(adapter.dropForeignKeyFromTable(name = "posts", keyName = "FK_posts"))
                        .toBe('ALTER TABLE "POSTS" DROP CONSTRAINT "FK_POSTS"');
                    expect(adapter.dropTable(name = "users")).toBe('DROP TABLE IF EXISTS "USERS"');
                    expect(adapter.addColumnToTable(name = "users", column = col))
                        .toBe('ALTER TABLE "USERS" ADD COLUMN "TITLE" VARCHAR(255)');

                    adapter.identifierCase = "lower";
                    expect(adapter.renameTable(oldName = "USERS", newName = "PEOPLE"))
                        .toBe('ALTER TABLE "users" RENAME TO "people"');
                    expect(adapter.renameColumnInTable(name = "USERS", columnName = "NAME", newColumnName = "FULLNAME"))
                        .toBe('ALTER TABLE "users" ALTER COLUMN "name" RENAME TO "fullname"');
                });

                it("routes index and view DDL through the quoted identifiers", () => {
                    adapter.identifierCase = "upper";
                    expect(adapter.addIndex(table = "posts", columnNames = "authorid", indexName = "idx_posts_authorid"))
                        .toBe('CREATE INDEX "IDX_POSTS_AUTHORID" ON "POSTS"("AUTHORID")');
                    expect(adapter.removeIndex(table = "posts", indexName = "idx_posts_authorid"))
                        .toBe('DROP INDEX "IDX_POSTS_AUTHORID"');
                    expect(adapter.createView(name = "published", sql = "SELECT 1")).toBe('CREATE VIEW "PUBLISHED" AS SELECT 1');
                    expect(adapter.dropView(name = "published")).toBe('DROP VIEW IF EXISTS "PUBLISHED"');

                    adapter.identifierCase = "lower";
                    expect(adapter.addIndex(table = "POSTS", columnNames = "AUTHORID", indexName = "idx_posts_authorid"))
                        .toBe('CREATE INDEX "idx_posts_authorid" ON "posts"("authorid")');
                    expect(adapter.createView(name = "PUBLISHED", sql = "SELECT 1")).toBe('CREATE VIEW "published" AS SELECT 1');
                });

            });

            describe("PostgreSQL migrator", () => {

                beforeEach(() => {
                    adapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator");
                    variables.savedObjectCase = application.wheels.migratorObjectCase;
                });

                afterEach(() => {
                    application.wheels.migratorObjectCase = variables.savedObjectCase;
                });

                it("adapterName()", () => {
                    expect(adapter.adapterName()).toInclude("PostgreSQL");
                });

                it("addPrimaryKeyOptions()", () => {
                    expect(adapter.addPrimaryKeyOptions(sql = "SERIAL")).toInclude("SERIAL");
                });

                it("reports the lower DDL identifier case", () => {
                    expect(adapter.$ddlIdentifierCase()).toBe("lower");
                });

                it("quotes table/column identifiers lowercase, without double quoting (##4629)", () => {
                    expect(adapter.quoteTableName(name = "users")).toBe('"users"');
                    expect(adapter.quoteTableName(name = "public.users")).toBe('"public"."users"');
                    expect(adapter.quoteTableName(name = 'public.we"ird')).toBe('"public"."we""ird"');
                    expect(adapter.quoteColumnName(name = "title")).toBe('"title"');
                    expect(adapter.quoteColumnName(name = 'we"ird')).toBe('"we""ird"');
                });

                it("ignores migratorObjectCase while quoting is active (##4629)", () => {
                    application.wheels.migratorObjectCase = "lower";
                    expect(adapter.quoteTableName(name = "users")).toBe('"users"');
                    application.wheels.migratorObjectCase = "upper";
                    expect(adapter.quoteTableName(name = "users")).toBe('"users"');
                    expect(adapter.quoteColumnName(name = "title")).toBe('"title"');
                });

                it("builds quoted createTable DDL from ColumnDefinitions", () => {
                    var pk = new wheels.migrator.ColumnDefinition(adapter = adapter, name = "id", type = "integer");
                    var col = new wheels.migrator.ColumnDefinition(adapter = adapter, name = "title", type = "string");
                    var sql = adapter.createTable(name = "pgunit", columns = [col], primaryKeys = [pk]);
                    expect(sql).toInclude('CREATE TABLE "pgunit"');
                    expect(sql).toInclude('"id" INTEGER PRIMARY KEY');
                    expect(sql).toInclude('"title" VARCHAR(255)');
                });

                it("routes rename/change/drop/add column DDL through the quoted identifiers", () => {
                    var col = new wheels.migrator.ColumnDefinition(adapter = adapter, name = "title", type = "string");
                    expect(adapter.renameTable(oldName = "users", newName = "people"))
                        .toBe('ALTER TABLE "users" RENAME TO "people"');
                    expect(adapter.changeColumnInTable(name = "posts", column = col))
                        .toInclude('ALTER TABLE "posts" ALTER COLUMN "title" TYPE VARCHAR(255)');
                    expect(adapter.dropForeignKeyFromTable(name = "posts", keyName = "FK_posts"))
                        .toBe('ALTER TABLE "posts" DROP CONSTRAINT "fk_posts"');
                    expect(adapter.dropTable(name = "users")).toBe('DROP TABLE IF EXISTS "users"');
                    expect(adapter.addColumnToTable(name = "users", column = col))
                        .toBe('ALTER TABLE "users" ADD COLUMN "title" VARCHAR(255)');
                    expect(adapter.dropColumnFromTable(name = "users", columnName = "Title"))
                        .toBe('ALTER TABLE "users" DROP COLUMN "title"');
                });

                it("routes index and view DDL through the quoted identifiers", () => {
                    expect(adapter.addIndex(table = "posts", columnNames = "title"))
                        .toBe('CREATE INDEX "posts_title" ON "posts"("title")');
                    expect(adapter.removeIndex(table = "posts", indexName = "idx_posts_title"))
                        .toBe('DROP INDEX "idx_posts_title"');
                    expect(adapter.createView(name = "Published", sql = "SELECT 1")).toBe('CREATE VIEW "published" AS SELECT 1');
                    expect(adapter.dropView(name = "Published")).toBe('DROP VIEW IF EXISTS "published"');
                });

            });

            describe("CockroachDB migrator", () => {

                beforeEach(() => {
                    adapter = CreateObject("component", "wheels.databaseAdapters.CockroachDB.CockroachDBMigrator");
                });

                it("inherits the PostgreSQL lower-case DDL quoting (##4629)", () => {
                    expect(adapter.adapterName()).toInclude("Cockroach");
                    expect(adapter.$ddlIdentifierCase()).toBe("lower");
                    expect(adapter.quoteTableName(name = "users")).toBe('"users"');
                    expect(adapter.quoteTableName(name = "public.users")).toBe('"public"."users"');
                    expect(adapter.quoteColumnName(name = 'we"ird')).toBe('"we""ird"');
                    expect(adapter.renameTable(oldName = "users", newName = "people"))
                        .toBe('ALTER TABLE "users" RENAME TO "people"');
                });

            });

        });

    }

}
