component extends="Abstract" {

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
                arrayAppend(local.lines, col.toSQL());
            }
        }

        // 2. Add normal columns
        for (local.col in arguments.columns) {
            arrayAppend(local.lines, col.toSQL());
        }

        // 3. Add composite primary key constraint if needed
        if (ArrayLen(arguments.primaryKeys) > 1) {
            arrayAppend(local.lines, primaryKeyConstraint(argumentCollection = arguments));
        }

        // 4. Add foreign keys
        for (local.fk in arguments.foreignKeys) {
            arrayAppend(local.lines, fk.toForeignKeySQL());
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
	 */
    public string function dropTable(required string name) {
		return "DROP TABLE IF EXISTS #objectCase(arguments.name)#";
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

		local.iEnd = ListLen(arguments.columnNames);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			sql = sql & quoteColumnName(ListGetAt(arguments.columnNames, local.i));
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

        if (StructKeyExists(arguments.options, "null") && arguments.options.null) {
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
        arguments.sql &= " FOREIGN KEY (" & arguments.options.column & ")";

        if (StructKeyExists(arguments.options, "referenceTable")) {
            if (StructKeyExists(arguments.options, "referenceColumn")) {
                arguments.sql &= " REFERENCES " & arguments.options.referenceTable;
                arguments.sql &= " (" & arguments.options.referenceColumn & ")";
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
        return "ALTER TABLE #quoteTableName(arguments.name)# MODIFY #arguments.column.toSQL()#";
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
        local.base = variables.sqlTypes[arguments.type];

        // VARCHAR2 length
        if (StructKeyExists(local.base, "limit") && (!structKeyExists(arguments.options, "limit") || arguments.options.limit EQ 0)) {
            arguments.options.limit = local.base.limit;
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