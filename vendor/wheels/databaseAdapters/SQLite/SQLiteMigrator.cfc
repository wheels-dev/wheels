component extends="wheels.databaseAdapters.Abstract" {

	// SQLite type mapping (simpler type system)
	variables.sqlTypes = {};
	variables.sqlTypes['biginteger'] = { name = 'INTEGER' };
	variables.sqlTypes['binary'] = { name = 'BLOB' };
	variables.sqlTypes['boolean'] = { name = 'INTEGER' }; // SQLite has no real BOOLEAN type
	variables.sqlTypes['date'] = { name = 'TEXT' };
	variables.sqlTypes['datetime'] = { name = 'TEXT' };
	variables.sqlTypes['decimal'] = { name = 'REAL' };
	variables.sqlTypes['float'] = { name = 'REAL' };
	variables.sqlTypes['integer'] = { name = 'INTEGER' };
	variables.sqlTypes['string'] = { name = 'TEXT', limit = 255 };
	variables.sqlTypes['text'] = { name = 'TEXT' };
	variables.sqlTypes['mediumtext'] = { name = 'TEXT' };
	variables.sqlTypes['longtext'] = { name = 'TEXT' };
	variables.sqlTypes['time'] = { name = 'TEXT' };
	variables.sqlTypes['timestamp'] = { name = 'TEXT' };
	variables.sqlTypes['uuid'] = { name = 'TEXT', limit = 36 };

	/**
	 * name of database adapter
	 */
	public string function adapterName() {
		return "SQLite";
	}

	/**
	 * SQLite supports inline foreign key definitions
	 */
	public string function addForeignKeyOptions(required string sql, struct options = {}) {
		arguments.sql &= " REFERENCES " & arguments.options.referenceTable;
		if (StructKeyExists(arguments.options, "referenceColumn")) {
			arguments.sql &= " (" & arguments.options.referenceColumn & ")";
		}
		// Add ON DELETE / ON UPDATE if provided
		if (StructKeyExists(arguments.options, "onDelete")) {
			arguments.sql &= " ON DELETE " & arguments.options.onDelete;
		}
		if (StructKeyExists(arguments.options, "onUpdate")) {
			arguments.sql &= " ON UPDATE " & arguments.options.onUpdate;
		}
		return arguments.sql;
	}

	/**
	 * Generates SQL for primary key options.
	 * In SQLite, only INTEGER PRIMARY KEY is auto-incrementable.
	 */
	public string function addPrimaryKeyOptions(required string sql, struct options = {}) {
		arguments.sql &= " PRIMARY KEY";
		if (
			StructKeyExists(arguments.options, "autoIncrement") &&
			arguments.options.autoIncrement &&
			FindNoCase("INTEGER", arguments.sql)
		) {
			arguments.sql &= " AUTOINCREMENT";
		}
		return arguments.sql;
	}

	/**
	 * Surround table or index names with double quotes (SQLite standard).
	 */
	public string function quoteTableName(required string name) {
		return """#Replace(objectCase(arguments.name), ".", """.""", "ALL")#""";
	}

	/**
	 * Surround column names with double quotes.
	 */
	public string function quoteColumnName(required string name) {
		return """#objectCase(arguments.name)#""";
	}

	/**
	 * In SQLite, most types can have default values, except BLOB.
	 */
	public boolean function optionsIncludeDefault(string type, string default = "", boolean allowNull = true) {
		if (ListFindNoCase("blob", arguments.type)) {
			return false;
		}
		return true;
	}

	/**
	 * generates sql to rename a table
	 */
	public string function renameTable(required string oldName, required string newName) {
		return "ALTER TABLE #quoteTableName(arguments.oldName)# RENAME TO #quoteTableName(arguments.newName)#";
	}

	/**
	 * SQLite supports simple RENAME COLUMN syntax from version 3.25.0+.
	 */
	public string function renameColumnInTable(
		required string name,
		required string columnName,
		required string newColumnName
	) {
		return "ALTER TABLE #quoteTableName(arguments.name)# RENAME COLUMN #quoteColumnName(arguments.columnName)# TO #quoteColumnName(arguments.newColumnName)#";
	}

	/**
	 * Removes an index in SQLite.
	 */
	public string function removeIndex(required string table, string indexName = "") {
		return "DROP INDEX IF EXISTS #quoteTableName(arguments.indexName)#";
	}

	/**
	 * SQLite does not support ALTER TABLE ... CHANGE / ALTER COLUMN. The
	 * documented workaround is the "recreate table" pattern: build a new table
	 * with the desired schema, copy data, drop the original, rename the new
	 * table, and recreate indexes. Returns an array of statements — the
	 * migrator's `$execute` accepts arrays.
	 *
	 * Limitations (v1): triggers and foreign-key constraints defined on the
	 * original CREATE TABLE are not preserved. Indexes declared outside the
	 * CREATE TABLE (CREATE INDEX) are preserved.
	 */
	public any function changeColumnInTable(required string name, required any column) {
		local.tableName = arguments.name;
		local.changedColumnName = arguments.column.name;
		local.quotedTable = quoteTableName(local.tableName);
		local.tempTableName = "_wheels_new_" & local.tableName;
		local.quotedTempTable = quoteTableName(local.tempTableName);
		local.appKey = $appKey();
		local.dsName = application[local.appKey].dataSourceName;

		// Read columns via PRAGMA — authoritative SQLite metadata.
		local.cols = $query(
			datasource = local.dsName,
			sql = "PRAGMA table_info(#local.quotedTable#)"
		);
		if (!IsQuery(local.cols) || local.cols.recordCount == 0) {
			throw(
				type = "Wheels.MigratorError",
				message = "Table '#local.tableName#' not found or has no columns."
			);
		}

		// Detect AUTOINCREMENT on INTEGER PK by inspecting the original CREATE TABLE.
		local.master = $query(
			datasource = local.dsName,
			sql = "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '#local.tableName#'"
		);
		local.hasAutoIncrement = false;
		if (IsQuery(local.master) && local.master.recordCount > 0 && Len(local.master.sql[1])) {
			local.hasAutoIncrement = FindNoCase("AUTOINCREMENT", local.master.sql[1]) > 0;
		}

		// Count primary-key columns to choose inline vs table-level PK constraint.
		local.pkCount = 0;
		for (local.i = 1; local.i <= local.cols.recordCount; local.i++) {
			if (local.cols.pk[local.i] > 0) {
				local.pkCount++;
			}
		}

		// Build new column definitions, preserving unchanged columns.
		local.columnDefs = [];
		local.allColumnNames = [];
		local.changedColumnFound = false;
		for (local.i = 1; local.i <= local.cols.recordCount; local.i++) {
			local.colName = local.cols.name[local.i];
			ArrayAppend(local.allColumnNames, local.colName);
			if (local.colName == local.changedColumnName) {
				ArrayAppend(local.columnDefs, arguments.column.toSQL());
				local.changedColumnFound = true;
			} else {
				ArrayAppend(
					local.columnDefs,
					$sqliteBuildColumnDef(
						cols = local.cols,
						i = local.i,
						hasAutoIncrement = local.hasAutoIncrement,
						inlinePK = local.pkCount == 1
					)
				);
			}
		}
		if (!local.changedColumnFound) {
			throw(
				type = "Wheels.MigratorError",
				message = "Column '#local.changedColumnName#' not found in table '#local.tableName#'."
			);
		}

		// Composite PK becomes a table-level constraint.
		if (local.pkCount > 1) {
			local.pkCols = [];
			for (local.i = 1; local.i <= local.cols.recordCount; local.i++) {
				if (local.cols.pk[local.i] > 0) {
					local.pkCols[local.cols.pk[local.i]] = quoteColumnName(local.cols.name[local.i]);
				}
			}
			ArrayAppend(local.columnDefs, "PRIMARY KEY (" & ArrayToList(local.pkCols, ", ") & ")");
		}

		local.createSQL = "CREATE TABLE #local.quotedTempTable# (" & ArrayToList(local.columnDefs, ", ") & ")";

		// Build the column list for INSERT ... SELECT data copy.
		local.quotedColList = [];
		for (local.colName in local.allColumnNames) {
			ArrayAppend(local.quotedColList, quoteColumnName(local.colName));
		}
		local.columnList = ArrayToList(local.quotedColList, ", ");

		// Capture non-auto indexes to recreate after rename.
		local.indexes = $query(
			datasource = local.dsName,
			sql = "SELECT sql FROM sqlite_master WHERE type = 'index' AND tbl_name = '#local.tableName#' AND sql IS NOT NULL"
		);

		// When the migrator's cftransaction already wraps this call (issue #2789
		// sets request.$wheelsTransactionWrapper) the engine owns BEGIN / COMMIT /
		// ROLLBACK: emitting our own would collide with the active transaction,
		// PRAGMA foreign_keys is a silent no-op inside one, and a raw COMMIT would
		// defeat the wrapper's rollback (leaving the temp table behind on a
		// mid-sequence failure). Use PRAGMA defer_foreign_keys instead — it is
		// allowed mid-transaction, moves FK enforcement to COMMIT, and auto-resets
		// on commit/rollback — and let the wrapper provide atomicity.
		local.inWrappingTransaction = StructKeyExists(request, "$wheelsTransactionWrapper")
		&& request.$wheelsTransactionWrapper;
		if (local.inWrappingTransaction) {
			local.statements = ["PRAGMA defer_foreign_keys = ON"];
		} else {
			// Standalone execution: PRAGMA foreign_keys must toggle outside any
			// active transaction, so wrap the recreate in our own.
			local.statements = ["PRAGMA foreign_keys = OFF", "BEGIN TRANSACTION"];
		}
		ArrayAppend(local.statements, local.createSQL);
		ArrayAppend(
			local.statements,
			"INSERT INTO #local.quotedTempTable# (#local.columnList#) SELECT #local.columnList# FROM #local.quotedTable#"
		);
		ArrayAppend(local.statements, "DROP TABLE #local.quotedTable#");
		ArrayAppend(local.statements, "ALTER TABLE #local.quotedTempTable# RENAME TO #quoteTableName(local.tableName)#");
		if (!local.inWrappingTransaction) {
			ArrayAppend(local.statements, "COMMIT");
		}
		if (IsQuery(local.indexes)) {
			for (local.j = 1; local.j <= local.indexes.recordCount; local.j++) {
				ArrayAppend(local.statements, local.indexes.sql[local.j]);
			}
		}
		if (!local.inWrappingTransaction) {
			ArrayAppend(local.statements, "PRAGMA foreign_keys = ON");
		}
		return local.statements;
	}

	/**
	 * Build a column-definition SQL fragment from PRAGMA table_info output for a
	 * single column. Preserves type, PRIMARY KEY (with AUTOINCREMENT for INTEGER
	 * PKs when the original table had it), NOT NULL, and DEFAULT.
	 */
	public string function $sqliteBuildColumnDef(
		required query cols,
		required numeric i,
		required boolean hasAutoIncrement,
		required boolean inlinePK
	) {
		local.name = arguments.cols.name[arguments.i];
		local.type = arguments.cols.type[arguments.i];
		local.notNull = arguments.cols.notnull[arguments.i];
		local.dflt = arguments.cols.dflt_value[arguments.i];
		local.pk = arguments.cols.pk[arguments.i];

		local.def = quoteColumnName(local.name) & " " & local.type;
		if (arguments.inlinePK && local.pk > 0) {
			local.def &= " PRIMARY KEY";
			if (arguments.hasAutoIncrement && UCase(Trim(local.type)) == "INTEGER") {
				local.def &= " AUTOINCREMENT";
			}
		}
		if (local.notNull) {
			local.def &= " NOT NULL";
		}
		// PRAGMA table_info returns dflt_value already as a SQL literal
		// (quoted string, bare number, or NULL expression) so it can be
		// concatenated directly after DEFAULT.
		if (IsSimpleValue(local.dflt) && Len(local.dflt)) {
			local.def &= " DEFAULT " & local.dflt;
		}
		return local.def;
	}

}
