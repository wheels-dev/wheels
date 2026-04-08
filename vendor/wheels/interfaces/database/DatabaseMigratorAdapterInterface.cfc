/**
 * Contract for database migrator adapters (schema DDL generation).
 *
 * The default implementation lives in `wheels.databaseAdapters.Abstract` (extends
 * `wheels.migrator.Base`). Concrete adapters: `MySQLMigrator`, `PostgreSQLMigrator`,
 * `H2Migrator`, `MicrosoftSQLServerMigrator`, `OracleMigrator`, `SQLiteMigrator`,
 * `CockroachDBMigrator`.
 *
 * This is the DDL/migration-side adapter. For query execution, see
 * `DatabaseModelAdapterInterface`.
 *
 * [section: Database]
 * [category: Interface]
 */
interface {

	/**
	 * Convert a Wheels column type name to engine-specific SQL type.
	 *
	 * @type Wheels type name ("string", "text", "integer", "float", "boolean", etc.).
	 * @options Optional struct with size/precision hints.
	 * @return Engine-specific SQL type (e.g., "VARCHAR(255)", "INT").
	 */
	public string function typeToSQL(required string type, struct options);

	/**
	 * Return engine-specific SQL options for a primary key column (e.g., AUTO_INCREMENT).
	 */
	public string function addPrimaryKeyOptions();

	/**
	 * Generate a PRIMARY KEY constraint clause.
	 *
	 * @name Constraint name.
	 * @primaryKeys Array of primary key column names.
	 * @return SQL fragment like "CONSTRAINT pk_name PRIMARY KEY (col1, col2)".
	 */
	public string function primaryKeyConstraint(required string name, required array primaryKeys);

	/**
	 * Append column options (NULL, DEFAULT, etc.) to a column definition.
	 *
	 * @sql The column definition SQL so far.
	 * @options Struct of column options.
	 * @return The column definition with options appended.
	 */
	public string function addColumnOptions(required string sql, struct options);

	/**
	 * Determine whether a DEFAULT clause should be included for a column.
	 *
	 * @type Column type.
	 * @default Default value.
	 * @allowNull Whether NULL is allowed.
	 * @return True if a DEFAULT clause should be added.
	 */
	public boolean function optionsIncludeDefault(string type, string default, boolean allowNull);

	/**
	 * Quote a value for use in DDL statements.
	 *
	 * @value The value to quote.
	 * @options Optional struct with type hints.
	 * @return The quoted value.
	 */
	public string function quote(required string value, struct options);

	/**
	 * Quote a table name for the target engine.
	 *
	 * @name Table name.
	 * @return Quoted table name.
	 */
	public string function quoteTableName(required string name);

	/**
	 * Quote a column name for the target engine.
	 *
	 * @name Column name.
	 * @return Quoted column name.
	 */
	public string function quoteColumnName(required string name);

	/**
	 * Generate a CREATE TABLE statement.
	 *
	 * @name Table name.
	 * @columns Array of column definition structs.
	 * @primaryKeys Array of primary key column names.
	 * @foreignKeys Array of foreign key definition structs.
	 * @return The CREATE TABLE SQL statement.
	 */
	public string function createTable(required string name, required array columns, array primaryKeys, array foreignKeys);

	/**
	 * Generate a RENAME TABLE statement.
	 *
	 * @oldName Current table name.
	 * @newName New table name.
	 * @return The RENAME TABLE SQL statement.
	 */
	public string function renameTable(required string oldName, required string newName);

	/**
	 * Generate a DROP TABLE statement.
	 *
	 * @name Table name.
	 * @return The DROP TABLE SQL statement.
	 */
	public string function dropTable(required string name);

	/**
	 * Generate an ALTER TABLE ... ADD COLUMN statement.
	 *
	 * @name Table name.
	 * @column Column definition struct.
	 * @return The ADD COLUMN SQL statement.
	 */
	public string function addColumnToTable(required string name, required any column);

	/**
	 * Generate an ALTER TABLE ... ALTER COLUMN statement.
	 *
	 * @name Table name.
	 * @column Column definition struct with new settings.
	 * @return The ALTER COLUMN SQL statement.
	 */
	public string function changeColumnInTable(required string name, required any column);

	/**
	 * Generate an ALTER TABLE ... RENAME COLUMN statement.
	 *
	 * @name Table name.
	 * @columnName Current column name.
	 * @newColumnName New column name.
	 * @return The RENAME COLUMN SQL statement.
	 */
	public string function renameColumnInTable(required string name, required string columnName, required string newColumnName);

	/**
	 * Generate an ALTER TABLE ... DROP COLUMN statement.
	 *
	 * @name Table name.
	 * @columnName Column to drop.
	 * @return The DROP COLUMN SQL statement.
	 */
	public string function dropColumnFromTable(required string name, required string columnName);

	/**
	 * Generate an ALTER TABLE ... ADD FOREIGN KEY statement.
	 *
	 * @name Table name.
	 * @foreignKey Foreign key definition struct.
	 * @return The ADD FOREIGN KEY SQL statement.
	 */
	public string function addForeignKeyToTable(required string name, required any foreignKey);

	/**
	 * Generate an ALTER TABLE ... DROP FOREIGN KEY statement.
	 *
	 * @name Table name.
	 * @keyName Foreign key constraint name.
	 * @return The DROP FOREIGN KEY SQL statement.
	 */
	public string function dropForeignKeyFromTable(required string name, required string keyName);

	/**
	 * Generate inline FOREIGN KEY SQL for use within CREATE TABLE.
	 *
	 * @name Constraint name.
	 * @table Source table.
	 * @referenceTable Target table.
	 * @column Source column.
	 * @referenceColumn Target column.
	 * @onUpdate ON UPDATE action (CASCADE, SET NULL, etc.).
	 * @onDelete ON DELETE action.
	 * @return The FOREIGN KEY SQL fragment.
	 */
	public string function foreignKeySQL(
		required string name,
		required string table,
		required string referenceTable,
		required string column,
		required string referenceColumn,
		string onUpdate,
		string onDelete
	);

	/**
	 * Generate a CREATE INDEX statement.
	 *
	 * @table Table name.
	 * @columnNames Comma-delimited column names.
	 * @unique Whether this is a unique index.
	 * @indexName Override the generated index name.
	 * @return The CREATE INDEX SQL statement.
	 */
	public string function addIndex(required string table, string columnNames, boolean unique, string indexName);

	/**
	 * Generate a DROP INDEX statement.
	 *
	 * @table Table name.
	 * @indexName Index name to drop.
	 * @return The DROP INDEX SQL statement.
	 */
	public any function removeIndex(required string table, string indexName);

	/**
	 * Generate a CREATE VIEW statement.
	 *
	 * @name View name.
	 * @sql SELECT statement for the view body.
	 * @return The CREATE VIEW SQL statement.
	 */
	public string function createView(required string name, required string sql);

	/**
	 * Generate a DROP VIEW statement.
	 *
	 * @name View name.
	 * @return The DROP VIEW SQL statement.
	 */
	public string function dropView(required string name);

	/**
	 * Return engine-specific SQL prefix for record-manipulation (e.g., SET IDENTITY_INSERT ON).
	 */
	public string function addRecordPrefix();

	/**
	 * Return engine-specific SQL suffix for record-manipulation (e.g., SET IDENTITY_INSERT OFF).
	 */
	public string function addRecordSuffix();

}
