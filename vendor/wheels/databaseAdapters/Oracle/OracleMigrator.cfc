component extends="wheels.databaseAdapters.Abstract" {

    /**
     * SQL type mappings specific to Oracle Database 12c+
     * Keys follow the canonical Wheels/ORM logical type names,
     * values define the Oracle column type plus any size / precision
     * defaults that will be used when no explicit column options are supplied.
     */
    variables.sqlTypes = {};
    variables.sqlTypes['biginteger'] = {name = 'NUMBER', precision = 19};
    variables.sqlTypes['binary']     = {name = 'BLOB'};
    variables.sqlTypes['boolean']    = {name = 'NUMBER', precision = 1};
    variables.sqlTypes['char']       = {name = 'CHAR', limit = 1};
    variables.sqlTypes['date']       = {name = 'DATE'};
    variables.sqlTypes['datetime']   = {name = 'TIMESTAMP'};
    variables.sqlTypes['decimal']    = {name = 'NUMBER'}; // precision/scale picked up from options
    variables.sqlTypes['float']      = {name = 'FLOAT'};
    variables.sqlTypes['integer']    = {name = 'NUMBER', precision = 10};
    variables.sqlTypes['string']     = {name = 'VARCHAR2', limit = 255};
    variables.sqlTypes['text']       = {name = 'CLOB'};
    variables.sqlTypes['time']       = {name = 'TIMESTAMP'};
    variables.sqlTypes['timestamp']  = {name = 'TIMESTAMP'};
    variables.sqlTypes['uuid']       = {name = 'RAW', limit = 16};
    variables.sqlTypes['uniqueidentifier'] = {name = 'CHAR', limit = 36};
    // SYS_GUID() is RAW(16); format it as a 36-character 8-4-4-4-12 string. It is unique
    // but not a version 4 (random) UUID (#4094).
    variables.uuidDefaultSQL = 'LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), ''(.{8})(.{4})(.{4})(.{4})(.{12})'', ''\1-\2-\3-\4-\5''))';

    // Oracle 23ai+ has a native BOOLEAN type, which the model maps to cf_sql_bit.
    // Earlier releases keep NUMBER(1), which reaches the model as an integer (#3897).
    // Set by Migration.init() from the server version.
    variables.nativeBoolean = false;

    public void function $setNativeBoolean(required boolean supported) {
        variables.nativeBoolean = arguments.supported;
    }

    /**
     * Column options, with a native BOOLEAN default written as TRUE / FALSE
     * rather than the 1 / 0 the shared implementation emits.
     */
    public string function addColumnOptions(required string sql, struct options = "#StructNew()#") {
        local.rv = super.addColumnOptions(argumentCollection = arguments);
        if (variables.nativeBoolean && StructKeyExists(arguments.options, "type") && arguments.options.type == "boolean") {
            local.rv = ReReplace(local.rv, " DEFAULT 1( |$)", " DEFAULT TRUE\1");
            local.rv = ReReplace(local.rv, " DEFAULT 0( |$)", " DEFAULT FALSE\1");
        }
        return local.rv;
    }

    /**
     * Name of database adapter
     */
    public string function adapterName() {
        return "Oracle";
    }

    /**
     * Builds a `CREATE TABLE` statement.
     * The implementation mirrors the approach in `MySQL.cfc` but
     * outputs Oracle‑specific SQL (quoted identifiers, no engine hints).
     *
     * @name       The table name (un‑quoted; quoting handled here)
     * @columns    An **array** of Column objects. Each must expose a `toSQL()` method that returns the column definition string.
     * @options    Currently accepts `tablespace`, but additional Oracle‑specific options could be added later.
     */
    public string function createTable(
        required string name,
        required array columns,
        array primaryKeys = [],
        array foreignKeys = [],
        struct options = {}
    ) {
        local.lines = [];

        // 1. Single primary key inlined as column definition
        if (ArrayLen(arguments.primaryKeys) == 1) {
            arrayAppend(local.lines, arguments.primaryKeys[1].toPrimaryKeySQL());
        } else {
            // Add all primary key columns normally
            for (local.col in arguments.primaryKeys) {
                arrayAppend(local.lines, local.col.toSQL());
            }
        }

        // 2. Add normal columns
        for (local.col in arguments.columns) {
            arrayAppend(local.lines, local.col.toSQL());
        }

        // 3. Add composite primary key constraint if needed
        if (ArrayLen(arguments.primaryKeys) > 1) {
            arrayAppend(local.lines, primaryKeyConstraint(argumentCollection = arguments));
        }

        // 4. Add foreign keys
        for (local.fk in arguments.foreignKeys) {
            arrayAppend(local.lines, local.fk.toForeignKeySQL());
        }

        // 5. Join all lines and wrap in CREATE TABLE
        local.sql = "CREATE TABLE #arguments.name# (" &
                    ArrayToList(local.lines) &
                    ")";

        // 6. Optional Oracle-specific options
        if (StructKeyExists(arguments.options, "tablespace") && Len(arguments.options.tablespace)) {
            local.sql &= " TABLESPACE " & arguments.options.tablespace;
        }

        return local.sql;
    }

    /**
	 * generates sql to drop a table
	 *
	 * Oracle only added the `IF EXISTS` DDL modifier in 23c; on 19c/21c
	 * `DROP TABLE IF EXISTS ...` is a hard parse error (ORA-00933), and the
	 * `remove-table` migration template re-throws on error, so the whole
	 * migration fails. We instead wrap the drop in the version-agnostic PL/SQL
	 * idiom that runs the bare DROP and swallows ORA-00942 ("table or view does
	 * not exist") — preserving "drop if exists" semantics on every supported
	 * Oracle version. `$execute` (vendor/wheels/migrator/Base.cfc) never splits
	 * on `;` and deliberately omits the trailing-semicolon append for Oracle, so
	 * the anonymous block reaches the driver intact.
	 *
	 * CASCADE CONSTRAINTS drops referential integrity constraints that point
	 * at this table from other tables. Without it, re-running the migrator
	 * tests collides with ORA-02264 (name already used by an existing
	 * constraint) because the parent table's incoming FK survives the drop.
	 */
    public string function dropTable(required string name) {
		return "BEGIN EXECUTE IMMEDIATE 'DROP TABLE #objectCase(arguments.name)# CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;";
	}

	/**
	 * generates sql to drop a view
	 *
	 * Overrides Abstract.dropView (which emits `DROP VIEW IF EXISTS`) for the
	 * same Oracle <23c reason as dropTable — wrap the bare DROP VIEW in a PL/SQL
	 * block that swallows ORA-00942 so a missing view is a no-op on every
	 * Oracle version. Views have no CASCADE CONSTRAINTS clause.
	 */
	public string function dropView(required string name) {
		return "BEGIN EXECUTE IMMEDIATE 'DROP VIEW #objectCase(arguments.name)#'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;";
	}

    /**
	 * generates sql to add a new column to a table
	 */
	public string function addColumnToTable(required string name, required any column) {
		return "ALTER TABLE #objectCase(arguments.name)# ADD #arguments.column.toSQL()#";
	}

    /**
	 * generates sql to add a foreign key constraint to a table
	 */
	public string function addForeignKeyToTable(required string name, required any foreignKey) {
		return "ALTER TABLE #objectCase(arguments.name)# ADD #arguments.foreignKey.toSQL()#";
	}

    /**
	 * generates sql to add database index on a table column
	 */
	public string function addIndex(
		required string table,
		string columnNames,
		boolean unique = false,
		string indexName = "#objectCase(arguments.table)#_#ListFirst(arguments.columnNames)#"
	) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		var sql = "CREATE ";
		if (arguments.unique) {
			sql = sql & "UNIQUE ";
		}
		sql = sql & "INDEX #arguments.indexName# ON #arguments.table#(";

		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			sql = sql & quoteColumnName(local.columnNamesArray[local.i]);
			if (local.i != local.iEnd) {
				sql = sql & ",";
			}
		}
		sql = sql & ")";
		return sql;
	}

    /**
     * Surrounds table names with double‑quotes to preserve case
     * and allow use of reserved words. Also handles dotted names
     * (schema.table) by quoting each part.
     */
    public string function quoteTableName(required string name) {
        return objectCase(arguments.name);
    }

    /**
     * Surrounds column names with double‑quotes.
     */
    public string function quoteColumnName(required string name) {
        return objectCase(arguments.name);
    }

    /**
     * Generates SQL fragments for primary‑key column definitions.
     * Handles NULL / NOT NULL and identity (auto‑increment) options.
     *
     * Oracle 12c+ supports identity columns.  The Wheels option
     * `autoIncrement = true` maps to `GENERATED BY DEFAULT ON NULL AS IDENTITY`.
     */
    public string function addPrimaryKeyOptions(
        required string sql,
        struct options = {}
    ) {
        // Insert identity clause immediately after type
        if (
            StructKeyExists(arguments.options, "autoIncrement") &&
            arguments.options.autoIncrement
        ) {
            arguments.sql &= " GENERATED BY DEFAULT ON NULL AS IDENTITY";
        }

        if (StructKeyExists(arguments.options, "allowNull") && arguments.options.allowNull) {
            arguments.sql &= " NULL";
        } else {
            arguments.sql &= " NOT NULL";
        }

        arguments.sql &= " PRIMARY KEY";
        return arguments.sql;
    }

    /**
	 * generates sql to drop a foreign key constraint from a table
	 */
	public string function dropForeignKeyFromTable(required string name, required string keyName) {
		return "ALTER TABLE #quoteTableName(objectCase(arguments.name))# DROP CONSTRAINT #quoteTableName(arguments.keyname)#";
	}

    /**
     * Generates SQL fragment for adding foreign‑key constraints.
     * Oracle does not support ON UPDATE actions, so those options
     * are ignored.  ON DELETE is honoured.
     */
    public string function addForeignKeyOptions(
        required string sql,
        struct options = {}
    ) {
        arguments.sql &= " FOREIGN KEY (" & quoteColumnName(arguments.options.column) & ")";

        if (StructKeyExists(arguments.options, "referenceTable")) {
            if (StructKeyExists(arguments.options, "referenceColumn")) {
                arguments.sql &= " REFERENCES " & quoteTableName(arguments.options.referenceTable);
                arguments.sql &= " (" & quoteColumnName(arguments.options.referenceColumn) & ")";
            }
        }

        if (StructKeyExists(arguments.options, "onDelete")) {
            arguments.sql &= " ON DELETE " & arguments.options.onDelete;
        }

        return arguments.sql;
    }

    /**
     * Generates SQL to rename an existing table.
     */
    public string function renameTable(
        required string oldName,
        required string newName
    ) {
        return "ALTER TABLE #quoteTableName(arguments.oldName)# RENAME TO #objectCase(arguments.newName)#";
    }

    /**
     * Generates SQL to rename an existing column in a table.
     */
    public string function renameColumnInTable(
        required string name,
        required string columnName,
        required string newColumnName
    ) {
        return "ALTER TABLE #quoteTableName(arguments.name)# RENAME COLUMN #quoteColumnName(arguments.columnName)# TO #quoteColumnName(arguments.newColumnName)#";
    }

    /**
     * Generates SQL to change/modify an existing column definition.
     */
    public string function changeColumnInTable(
        required string name,
        required any column
    ) {
        // Without an explicit precision, a NUMBER column keeps the precision it has now
        // (#4097): a bare NUMBER from an earlier version stays bare, because Oracle cannot
        // narrow a populated column (ORA-01440), and a NUMBER(10) stays NUMBER(10) instead
        // of falling back to the type map's default. changeColumn() is how a migration
        // changes a default or allowNull, so it must not re-type the column.
        if (!StructKeyExists(arguments.column, "precision") && $isNumberColumnType(arguments.column.type)) {
            local.current = $currentNumberPrecision(tableName = arguments.name, columnName = arguments.column.name);
            arguments.column.precision = local.current.precision;
            if (local.current.precision > 0 && local.current.scale > 0 && !StructKeyExists(arguments.column, "scale")) {
                arguments.column.scale = local.current.scale;
            }
        }
        return "ALTER TABLE #quoteTableName(arguments.name)# MODIFY #arguments.column.toSQL()#";
    }

    /**
     * Internal function. True when a logical column type is declared as an Oracle NUMBER.
     */
    public boolean function $isNumberColumnType(required string type) {
        if (arguments.type == "boolean" && variables.nativeBoolean) {
            return false;
        }
        return StructKeyExists(variables.sqlTypes, arguments.type) && variables.sqlTypes[arguments.type].name == "NUMBER";
    }

    /**
     * Internal function. The current precision and scale of an existing NUMBER column, read
     * from USER_TAB_COLUMNS. A bare NUMBER, a missing column or an unreadable catalog give
     * precision 0, which typeToSQL() renders as a bare NUMBER.
     */
    public struct function $currentNumberPrecision(required string tableName, required string columnName) {
        var rv = {precision = 0, scale = 0};
        try {
            local.creds = $migratorDataSourceCredentials();
            local.queryOptions = {datasource = $migratorDataSource()};
            if (Len(local.creds.username)) {
                local.queryOptions.username = local.creds.username;
                local.queryOptions.password = local.creds.password;
            }
            local.info = QueryExecute(
                "SELECT data_precision, data_scale FROM user_tab_columns WHERE UPPER(table_name) = UPPER(:tableName) AND UPPER(column_name) = UPPER(:columnName)",
                {
                    tableName = {value = arguments.tableName, cfsqltype = "cf_sql_varchar"},
                    columnName = {value = arguments.columnName, cfsqltype = "cf_sql_varchar"}
                },
                local.queryOptions
            );
            if (local.info.recordCount && IsNumeric(local.info.data_precision)) {
                rv.precision = local.info.data_precision;
                rv.scale = IsNumeric(local.info.data_scale) ? local.info.data_scale : 0;
            }
        } catch (any e) {
            rv.precision = 0;
        }
        return rv;
    }

    /**
     * Generates SQL to drop a database index.
     */
    public string function removeIndex(
        required string table,
        string indexName = ""
    ) {
        if (Len(arguments.indexName)) {
            return "DROP INDEX #quoteTableName(arguments.indexName)#";
        } else {
            // When an index name isn't provided Wheels builds it like {table}_{col}_idx
            return "DROP INDEX #objectCase(arguments.table)#";
        }
    }

    /**
     * Maps CFML/Wheels logical types to Oracle SQL column definitions
     * when a more nuanced mapping is required than the `sqlTypes` struct
     * provides (e.g. applying length, precision or scale).
     */
    public string function typeToSQL(
        required string type,
        struct options = {}
    ) {
        if (arguments.type == "boolean" && variables.nativeBoolean) {
            return "BOOLEAN";
        }
        local.base = variables.sqlTypes[arguments.type];

        // VARCHAR2 length
        if (StructKeyExists(local.base, "limit") && (!structKeyExists(arguments.options, "limit") || arguments.options.limit EQ 0)) {
            arguments.options.limit = local.base.limit;
        }

        // NUMBER precision, so integer columns are NUMBER(10) / NUMBER(19) / NUMBER(1)
        // instead of a bare NUMBER that binds as numeric (#4097). A passed precision wins,
        // including the 0 that changeColumnInTable() uses to keep a bare NUMBER.
        if (StructKeyExists(local.base, "precision") && !StructKeyExists(arguments.options, "precision")) {
            arguments.options.precision = local.base.precision;
        }

        switch (local.base.name) {
            case "NUMBER":
                if (structKeyExists(arguments.options, "precision") && arguments.options.precision GT 0) {
                    if (structKeyExists(arguments.options, "scale") && arguments.options.scale GT 0) {
                        return "NUMBER(#arguments.options.precision#,#arguments.options.scale#)";
                    }
                    return "NUMBER(#arguments.options.precision#)";
                }
                return "NUMBER";
            case "VARCHAR2":
                return "VARCHAR2(#arguments.options.limit#)";
            case "RAW":
                return "RAW(#arguments.options.limit#)";
            default:
                if (structKeyExists(arguments.options, "limit") && arguments.options.limit GT 0) {
                    return "#local.base.name#(#arguments.options.limit#)";
                }
                return local.base.name;
        }
    }

}