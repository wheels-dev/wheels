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
		local.reservedWords = {
			"accessible" = true,
			"add" = true,
			"all" = true,
			"alter" = true,
			"analyze" = true,
			"and" = true,
			"as" = true,
			"asc" = true,
			"asensitive" = true,
			"before" = true,
			"between" = true,
			"bigint" = true,
			"binary" = true,
			"blob" = true,
			"both" = true,
			"by" = true,
			"call" = true,
			"cascade" = true,
			"case" = true,
			"change" = true,
			"char" = true,
			"character" = true,
			"check" = true,
			"collate" = true,
			"column" = true,
			"condition" = true,
			"constraint" = true,
			"continue" = true,
			"convert" = true,
			"create" = true,
			"cross" = true,
			"cube" = true,
			"cume_dist" = true,
			"current_date" = true,
			"current_time" = true,
			"current_timestamp" = true,
			"current_user" = true,
			"cursor" = true,
			"database" = true,
			"databases" = true,
			"day_hour" = true,
			"day_microsecond" = true,
			"day_minute" = true,
			"day_second" = true,
			"dec" = true,
			"decimal" = true,
			"declare" = true,
			"default" = true,
			"delayed" = true,
			"delete" = true,
			"dense_rank" = true,
			"desc" = true,
			"describe" = true,
			"deterministic" = true,
			"distinct" = true,
			"distinctrow" = true,
			"div" = true,
			"double" = true,
			"drop" = true,
			"dual" = true,
			"each" = true,
			"else" = true,
			"elseif" = true,
			"empty" = true,
			"enclosed" = true,
			"escaped" = true,
			"except" = true,
			"exists" = true,
			"exit" = true,
			"explain" = true,
			"false" = true,
			"fetch" = true,
			"first_value" = true,
			"float" = true,
			"float4" = true,
			"float8" = true,
			"for" = true,
			"force" = true,
			"foreign" = true,
			"from" = true,
			"fulltext" = true,
			"function" = true,
			"generated" = true,
			"get" = true,
			"grant" = true,
			"group" = true,
			"grouping" = true,
			"groups" = true,
			"having" = true,
			"high_priority" = true,
			"hour_microsecond" = true,
			"hour_minute" = true,
			"hour_second" = true,
			"if" = true,
			"ignore" = true,
			"in" = true,
			"index" = true,
			"infile" = true,
			"inner" = true,
			"inout" = true,
			"insensitive" = true,
			"insert" = true,
			"int" = true,
			"int1" = true,
			"int2" = true,
			"int3" = true,
			"int4" = true,
			"int8" = true,
			"integer" = true,
			"interval" = true,
			"into" = true,
			"io_after_gtids" = true,
			"io_before_gtids" = true,
			"is" = true,
			"iterate" = true,
			"join" = true,
			"json_table" = true,
			"key" = true,
			"keys" = true,
			"kill" = true,
			"lag" = true,
			"last_value" = true,
			"lead" = true,
			"leading" = true,
			"leave" = true,
			"left" = true,
			"like" = true,
			"limit" = true,
			"linear" = true,
			"lines" = true,
			"load" = true,
			"localtime" = true,
			"localtimestamp" = true,
			"lock" = true,
			"long" = true,
			"longblob" = true,
			"longtext" = true,
			"loop" = true,
			"low_priority" = true,
			"master_bind" = true,
			"master_ssl_verify_server_cert" = true,
			"match" = true,
			"maxvalue" = true,
			"mediumblob" = true,
			"mediumint" = true,
			"mediumtext" = true,
			"middleint" = true,
			"minute_microsecond" = true,
			"minute_second" = true,
			"mod" = true,
			"modifies" = true,
			"natural" = true,
			"not" = true,
			"no_write_to_binlog" = true,
			"nth_value" = true,
			"ntile" = true,
			"null" = true,
			"numeric" = true,
			"of" = true,
			"on" = true,
			"optimize" = true,
			"optimizer_costs" = true,
			"option" = true,
			"optionally" = true,
			"or" = true,
			"order" = true,
			"out" = true,
			"outer" = true,
			"outfile" = true,
			"over" = true,
			"partition" = true,
			"percent_rank" = true,
			"persist" = true,
			"persist_only" = true,
			"precision" = true,
			"primary" = true,
			"procedure" = true,
			"purge" = true,
			"range" = true,
			"rank" = true,
			"read" = true,
			"reads" = true,
			"read_write" = true,
			"real" = true,
			"recursive" = true,
			"references" = true,
			"regexp" = true,
			"release" = true,
			"rename" = true,
			"repeat" = true,
			"replace" = true,
			"require" = true,
			"resignal" = true,
			"restrict" = true,
			"return" = true,
			"revoke" = true,
			"right" = true,
			"rlike" = true,
			"row" = true,
			"rows" = true,
			"row_number" = true,
			"schema" = true,
			"schemas" = true,
			"second_microsecond" = true,
			"select" = true,
			"sensitive" = true,
			"separator" = true,
			"set" = true,
			"show" = true,
			"signal" = true,
			"smallint" = true,
			"spatial" = true,
			"specific" = true,
			"sql" = true,
			"sqlexception" = true,
			"sqlstate" = true,
			"sqlwarning" = true,
			"sql_big_result" = true,
			"sql_calc_found_rows" = true,
			"sql_small_result" = true,
			"ssl" = true,
			"starting" = true,
			"stored" = true,
			"straight_join" = true,
			"system" = true,
			"table" = true,
			"terminated" = true,
			"then" = true,
			"tinyblob" = true,
			"tinyint" = true,
			"tinytext" = true,
			"to" = true,
			"trailing" = true,
			"trigger" = true,
			"true" = true,
			"undo" = true,
			"union" = true,
			"unique" = true,
			"unlock" = true,
			"unsigned" = true,
			"update" = true,
			"usage" = true,
			"use" = true,
			"using" = true,
			"utc_date" = true,
			"utc_time" = true,
			"utc_timestamp" = true,
			"values" = true,
			"varbinary" = true,
			"varchar" = true,
			"varcharacter" = true,
			"varying" = true,
			"virtual" = true,
			"when" = true,
			"where" = true,
			"while" = true,
			"window" = true,
			"with" = true,
			"write" = true,
			"xor" = true,
			"year_month" = true,
			"zerofill" = true
		};

		if (StructKeyExists(local.reservedWords, arguments.word)) {
			return "`#local.rv#`";
		}
		return arguments.word;
	}

}
