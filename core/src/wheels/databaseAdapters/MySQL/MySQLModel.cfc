component extends="wheels.databaseAdapters.Base" output=false {

	/**
	 * Map database types to the ones used in CFML.
	 */
	public string function $getType(required string type, string scale, string details) {
		// Special handling for unsigned (stores only positive or 0 numbers) data types.
		// When using unsigned data types we can store a higher value than usual so we need to map to different CF types.
		// E.g. unsigned int stores up to 4,294,967,295 instead of 2,147,483,647 so we map to cf_sql_bigint to support that.
		if (StructKeyExists(arguments, "details") && arguments.details == "unsigned") {
			if (arguments.type == "int") {
				return "cf_sql_bigint";
			} else if (arguments.type == "bigint") {
				return "cf_sql_decimal";
			}
		}

		switch (arguments.type) {
			case "bigint":
				local.rv = "cf_sql_bigint";
				break;
			case "binary":
			case "geometry":
			case "point":
			case "linestring":
			case "polygon":
			case "multipoint":
			case "multilinestring":
			case "multipolygon":
			case "geometrycollection":
				local.rv = "cf_sql_binary";
				break;
			case "bit":
			case "bool":
				local.rv = "cf_sql_bit";
				break;
			case "blob":
			case "tinyblob":
			case "mediumblob":
			case "longblob":
				local.rv = "cf_sql_blob";
				break;
			case "char":
				local.rv = "cf_sql_char";
				break;
			case "date":
				local.rv = "cf_sql_date";
				break;
			case "decimal":
				local.rv = "cf_sql_decimal";
				break;
			case "double":
				local.rv = "cf_sql_double";
				break;
			case "float":
				local.rv = "cf_sql_float";
				break;
			case "int":
			case "mediumint":
				local.rv = "cf_sql_integer";
				break;
			case "smallint":
			case "year":
				local.rv = "cf_sql_smallint";
				break;
			case "time":
				local.rv = "cf_sql_time";
				break;
			case "datetime":
			case "timestamp":
				local.rv = "cf_sql_timestamp";
				break;
			case "tinyint":
				local.rv = "cf_sql_tinyint";
				break;
			case "varbinary":
				local.rv = "cf_sql_varbinary";
				break;
			case "varchar":
			case "enum":
			case "set":
			case "tinytext":
				local.rv = "cf_sql_varchar";
				break;
			case "json":
			case "text":
			case "mediumtext":
			case "longtext":
				local.rv = "cf_sql_longvarchar";
				break;
		}
		return local.rv;
	}

	/**
	 * Call functions to make adapter specific changes to arguments before executing query.
	 */
	public struct function $querySetup(
		required array sql,
		numeric limit = 0,
		numeric offset = 0,
		required boolean parameterize,
		string $primaryKey = ""
	) {
		$convertMaxRowsToLimit(args = arguments);
		$removeColumnAliasesInOrderClause(args = arguments);
		$moveAggregateToHaving(args = arguments);
		return $performQuery(argumentCollection = arguments);
	}

	/**
	 * Override Base adapter's function.
	 */
	public string function $defaultValues() {
		return "() VALUES()";
	}

	/**
	 * Define MySQL reserved words.
	 */
	public string function $escapeReservedWords(required string word) {
		local.reservedWords = [
			"ACCESSIBLE",
			"ADD",
			"ALL",
			"ALTER",
			"ANALYZE",
			"AND",
			"AS",
			"ASC",
			"ASENSITIVE",
			"BEFORE",
			"BETWEEN",
			"BIGINT",
			"BINARY",
			"BLOB",
			"BOTH",
			"BY",
			"CALL",
			"CASCADE",
			"CASE",
			"CHANGE",
			"CHAR",
			"CHARACTER",
			"CHECK",
			"COLLATE",
			"COLUMN",
			"CONDITION",
			"CONSTRAINT",
			"CONTINUE",
			"CONVERT",
			"CREATE",
			"CROSS",
			"CUBE",
			"CUME_DIST",
			"CURRENT_DATE",
			"CURRENT_TIME",
			"CURRENT_TIMESTAMP",
			"CURRENT_USER",
			"CURSOR",
			"DATABASE",
			"DATABASES",
			"DAY_HOUR",
			"DAY_MICROSECOND",
			"DAY_MINUTE",
			"DAY_SECOND",
			"DEC",
			"DECIMAL",
			"DECLARE",
			"DEFAULT",
			"DELAYED",
			"DELETE",
			"DENSE_RANK",
			"DESC",
			"DESCRIBE",
			"DETERMINISTIC",
			"DISTINCT",
			"DISTINCTROW",
			"DIV",
			"DOUBLE",
			"DROP",
			"DUAL",
			"EACH",
			"ELSE",
			"ELSEIF",
			"EMPTY",
			"ENCLOSED",
			"ESCAPED",
			"EXCEPT",
			"EXISTS",
			"EXIT",
			"EXPLAIN",
			"FALSE",
			"FETCH",
			"FIRST_VALUE",
			"FLOAT",
			"FLOAT4",
			"FLOAT8",
			"FOR",
			"FORCE",
			"FOREIGN",
			"FROM",
			"FULLTEXT",
			"FUNCTION",
			"GENERATED",
			"GET",
			"GRANT",
			"GROUP",
			"GROUPING",
			"GROUPS",
			"HAVING",
			"HIGH_PRIORITY",
			"HOUR_MICROSECOND",
			"HOUR_MINUTE",
			"HOUR_SECOND",
			"IF",
			"IGNORE",
			"IN",
			"INDEX",
			"INFILE",
			"INNER",
			"INOUT",
			"INSENSITIVE",
			"INSERT",
			"INT",
			"INT1",
			"INT2",
			"INT3",
			"INT4",
			"INT8",
			"INTEGER",
			"INTERVAL",
			"INTO",
			"IO_AFTER_GTIDS",
			"IO_BEFORE_GTIDS",
			"IS",
			"ITERATE",
			"JOIN",
			"JSON_TABLE",
			"KEY",
			"KEYS",
			"KILL",
			"LAG",
			"LAST_VALUE",
			"LEAD",
			"LEADING",
			"LEAVE",
			"LEFT",
			"LIKE",
			"LIMIT",
			"LINEAR",
			"LINES",
			"LOAD",
			"LOCALTIME",
			"LOCALTIMESTAMP",
			"LOCK",
			"LONG",
			"LONGBLOB",
			"LONGTEXT",
			"LOOP",
			"LOW_PRIORITY",
			"MASTER_BIND",
			"MASTER_SSL_VERIFY_SERVER_CERT",
			"MATCH",
			"MAXVALUE",
			"MEDIUMBLOB",
			"MEDIUMINT",
			"MEDIUMTEXT",
			"MIDDLEINT",
			"MINUTE_MICROSECOND",
			"MINUTE_SECOND",
			"MOD",
			"MODIFIES",
			"NATURAL",
			"NOT",
			"NO_WRITE_TO_BINLOG",
			"NTH_VALUE",
			"NTILE",
			"NULL",
			"NUMERIC",
			"OF",
			"ON",
			"OPTIMIZE",
			"OPTIMIZER_COSTS",
			"OPTION",
			"OPTIONALLY",
			"OR",
			"ORDER",
			"OUT",
			"OUTER",
			"OUTFILE",
			"OVER",
			"PARTITION",
			"PERCENT_RANK",
			"PERSIST",
			"PERSIST_ONLY",
			"PRECISION",
			"PRIMARY",
			"PROCEDURE",
			"PURGE",
			"RANGE",
			"RANK",
			"READ",
			"READS",
			"READ_WRITE",
			"REAL",
			"RECURSIVE",
			"REFERENCES",
			"REGEXP",
			"RELEASE",
			"RENAME",
			"REPEAT",
			"REPLACE",
			"REQUIRE",
			"RESIGNAL",
			"RESTRICT",
			"RETURN",
			"REVOKE",
			"RIGHT",
			"RLIKE",
			"ROW",
			"ROWS",
			"ROW_NUMBER",
			"SCHEMA",
			"SCHEMAS",
			"SECOND_MICROSECOND",
			"SELECT",
			"SENSITIVE",
			"SEPARATOR",
			"SET",
			"SHOW",
			"SIGNAL",
			"SMALLINT",
			"SPATIAL",
			"SPECIFIC",
			"SQL",
			"SQLEXCEPTION",
			"SQLSTATE",
			"SQLWARNING",
			"SQL_BIG_RESULT",
			"SQL_CALC_FOUND_ROWS",
			"SQL_SMALL_RESULT",
			"SSL",
			"STARTING",
			"STORED",
			"STRAIGHT_JOIN",
			"SYSTEM",
			"TABLE",
			"TERMINATED",
			"THEN",
			"TINYBLOB",
			"TINYINT",
			"TINYTEXT",
			"TO",
			"TRAILING",
			"TRIGGER",
			"TRUE",
			"UNDO",
			"UNION",
			"UNIQUE",
			"UNLOCK",
			"UNSIGNED",
			"UPDATE",
			"USAGE",
			"USE",
			"USING",
			"UTC_DATE",
			"UTC_TIME",
			"UTC_TIMESTAMP",
			"VALUES",
			"VARBINARY",
			"VARCHAR",
			"VARCHARACTER",
			"VARYING",
			"VIRTUAL",
			"WHEN",
			"WHERE",
			"WHILE",
			"WINDOW",
			"WITH",
			"WRITE",
			"XOR",
			"YEAR_MONTH",
			"ZEROFILL"
		];
		local.rv = arguments.word;
		if (local.reservedWords.findNoCase(arguments.word)) {
			local.rv = "`#local.rv#`";
		}
		return local.rv;
	}

}
