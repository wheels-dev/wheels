component extends="wheels.databaseAdapters.Base" output=false {

	/**
	 * Internal function. This database converts a high-precision decimal sent as text exactly,
	 * in an insert and in a comparison (#4172).
	 */
	public string function $wideDecimalBindType() {
		return "cf_sql_varchar";
	}

	/**
	 * Internal function. SQL Server converts a text value to the column's DECIMAL type, rounding
	 * it to the column's scale, so a high-precision decimal also binds inside an exact cast (#4172).
	 */
	public struct function $wideDecimalCastLimits() {
		return {precision = 38, scale = 38};
	}

	/**
	 * Internal function. Splits IN lists that would exceed the parameter limit into one parameter
	 * each (#4103), casts date and time conditions to their column's type (#4326, #4327), then casts
	 * high-precision decimal params exactly (#4172), before running the query.
	 */
	public struct function $performQuery(
		required array sql,
		required boolean parameterize,
		numeric limit = 0,
		numeric offset = 0,
		string dataSource = variables.dataSource,
		string $primaryKey = "",
		string $debugName = "query",
		boolean $captureResult = true
	) {
		$splitLargeInLists(args = arguments);
		$castTemporalParams(args = arguments);
		$castWideDecimalParams(args = arguments);
		return super.$performQuery(argumentCollection = arguments);
	}

	/**
	 * Internal function. The SQL Server type a condition on a column of `dataType` compares in, or
	 * "" to keep the bind as it is (#4326, #4327). Every engine binds cf_sql_timestamp as
	 * DATETIME2(7), and SQL Server then converts a DATETIME or SMALLDATETIME column exactly, so a
	 * value with a fraction never equals what the column stored in 1/300-second (or one-minute)
	 * steps; compared as DATETIME / SMALLDATETIME, the value rounds the way the stored value did.
	 * cf_sql_time binds as DATETIME on Lucee, not at all on BoxLang and without its fraction on
	 * Adobe, so a TIME column compares as TIME(7), which holds any TIME(n) value exactly.
	 */
	public string function $temporalComparisonType(required string dataType) {
		switch (LCase(arguments.dataType)) {
			case "datetime":
				return "DATETIME";
			case "smalldatetime":
				return "SMALLDATETIME";
			case "time":
				return "TIME(7)";
		}
		return "";
	}

	/**
	 * Internal function. Rewrites each date or time condition param that $isTemporalCastParam()
	 * selects into `CAST(? AS <column type>)`, an IN list into one CAST per value (#4326, #4327).
	 * The number of bound parameters is unchanged.
	 */
	public void function $castTemporalParams(required struct args) {
		if (!arguments.args.parameterize) {
			return;
		}
		local.rv = [];
		for (local.part in arguments.args.sql) {
			// Adobe CF passes arrays by value, so the parts are returned and appended here.
			if ($isTemporalCastParam(local.part)) {
				local.parts = $castTemporalParts(local.part);
			} else {
				local.parts = [local.part];
			}
			for (local.item in local.parts) {
				ArrayAppend(local.rv, local.item);
			}
		}
		arguments.args.sql = local.rv;
	}

	/**
	 * Internal function. True for a WHERE condition param on a DATETIME or SMALLDATETIME column
	 * compared with =, <>, !=, IN or NOT IN, or on a TIME column with any comparison. A range on a
	 * DATETIME column keeps the exact comparison: rounding its bound could move a row across it.
	 */
	public boolean function $isTemporalCastParam(required any part) {
		if (
			!IsStruct(arguments.part)
			|| !StructKeyExists(arguments.part, "dataType")
			|| !StructKeyExists(arguments.part, "operator")
			|| !StructKeyExists(arguments.part, "type")
			|| !StructKeyExists(arguments.part, "value")
			|| !ListFindNoCase("cf_sql_timestamp,cf_sql_time,cf_sql_date", arguments.part.type)
			|| (StructKeyExists(arguments.part, "null") && arguments.part.null)
		) {
			return false;
		}
		local.castType = $temporalComparisonType(arguments.part.dataType);
		if (!Len(local.castType)) {
			return false;
		}
		local.operator = UCase(ReReplace(Trim(arguments.part.operator), "\s+", " ", "all"));
		if (local.castType == "TIME(7)") {
			return ListFind("=,<>,!=,<,<=,>,>=,IN,NOT IN", local.operator) > 0;
		}
		return ListFind("=,<>,!=,IN,NOT IN", local.operator) > 0;
	}

	/**
	 * Internal function. The SQL parts for a date or time condition param as `CAST(? AS <type>)`,
	 * or for an IN list as `(CAST(...), CAST(...))` with one param per value. A TIME value binds as
	 * text (HH:mm:ss.fffffff), which every engine sends as it is.
	 */
	public array function $castTemporalParts(required struct part) {
		local.castType = $temporalComparisonType(arguments.part.dataType);
		// $queryParams() unmasks an IN list's values and joins them with Chr(7).
		local.qp = $queryParams(arguments.part);
		local.isList = StructKeyExists(local.qp, "list") && local.qp.list;
		local.values = local.isList ? ListToArray(local.qp.value, Chr(7)) : [local.qp.value];
		local.rv = [];
		local.iEnd = ArrayLen(local.values);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.param = StructCopy(arguments.part);
			StructDelete(local.param, "list");
			local.param.value = local.values[local.i];
			if (local.castType == "TIME(7)") {
				local.param.value = $timeText(local.values[local.i]);
				local.param.type = "cf_sql_varchar";
			}
			ArrayAppend(local.rv, (local.i == 1 ? (local.isList ? "(" : "") : ", ") & "CAST(");
			ArrayAppend(local.rv, local.param);
			ArrayAppend(local.rv, " AS #local.castType#)" & (local.isList && local.i == local.iEnd ? ")" : ""));
		}
		return local.rv;
	}

	/**
	 * Internal function. A time value as SQL Server TIME text: `HH:mm[:ss[.fffffff]]` as written, the
	 * time of a `yyyy-mm-dd HH:mm:ss[.f]` string, or a CFML date's time to the millisecond. Any other
	 * text is returned unchanged, so the CAST reports it.
	 */
	public string function $timeText(required any value) {
		if (IsSimpleValue(arguments.value)) {
			local.text = Trim(arguments.value);
			if (ReFind("^\d{1,2}:\d{2}(:\d{2}(\.\d{1,7})?)?$", local.text)) {
				return local.text;
			}
			local.match = ReFind("^\d{4}-\d{2}-\d{2}[ T](\d{1,2}:\d{2}(:\d{2}(\.\d{1,7})?)?)$", local.text, 1, true);
			if (local.match.pos[1]) {
				return Mid(local.text, local.match.pos[2], local.match.len[2]);
			}
			if (!IsDate(local.text)) {
				return local.text;
			}
		}
		if (IsDate(arguments.value)) {
			return TimeFormat(arguments.value, "HH:mm:ss") & "." & NumberFormat(Millisecond(arguments.value), "000");
		}
		return arguments.value;
	}

	/**
	 * Internal function. When a statement would bind more parameters than SQL Server accepts,
	 * rewrites IN lists, largest first until it fits, to one parameter each (#4103):
	 * `(SELECT CAST(value AS <type>) FROM STRING_SPLIT(?, NCHAR(31)))`. A statement that fits keeps
	 * its SQL. STRING_SPLIT needs compatibility level 130; below it, and for lists of other types
	 * (times among them), the statement is left for $assertBoundParameterCount() to refuse. Date and
	 * timestamp lists are split only when the driver's bind type is known (#4318).
	 */
	public void function $splitLargeInLists(required struct args) {
		local.limit = $inListSplitLimit();
		if (!arguments.args.parameterize || $boundParameterCount(arguments.args.sql) <= local.limit) {
			return;
		}
		if (!$supportsStringSplit(arguments.args.dataSource)) {
			return;
		}
		local.dateCasts = $stringSplitDateCasts(arguments.args.dataSource);
		local.convert = $inListsToSplit(sql = arguments.args.sql, limit = local.limit, dateCasts = local.dateCasts);
		local.rv = [];
		local.iEnd = ArrayLen(arguments.args.sql);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			// Adobe CF passes arrays by value, so the parts are returned and appended here.
			if (StructKeyExists(local.convert, local.i)) {
				local.parts = $stringSplitParts(part = arguments.args.sql[local.i], dateCasts = local.dateCasts);
			} else {
				local.parts = [arguments.args.sql[local.i]];
			}
			for (local.item in local.parts) {
				ArrayAppend(local.rv, local.item);
			}
		}
		arguments.args.sql = local.rv;
	}

	/**
	 * Internal function. The positions of the IN lists to split, largest first, until the statement
	 * binds no more than `limit` parameters (as a struct keyed by position). `dateCasts` is
	 * $stringSplitDateCasts()'s result; without it, date and timestamp lists aren't split.
	 */
	public struct function $inListsToSplit(required array sql, required numeric limit, struct dateCasts = {}) {
		local.sizes = {};
		local.iEnd = ArrayLen(arguments.sql);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.split = $stringSplitList(part = arguments.sql[local.i], dateCasts = arguments.dateCasts);
			if (!StructIsEmpty(local.split) && ArrayLen(local.split.values) > 1) {
				local.sizes[local.i] = ArrayLen(local.split.values);
			}
		}
		local.count = $boundParameterCount(arguments.sql);
		local.rv = {};
		while (local.count > arguments.limit && !StructIsEmpty(local.sizes)) {
			local.largest = "";
			for (local.key in local.sizes) {
				if (!Len(local.largest) || local.sizes[local.key] > local.sizes[local.largest]) {
					local.largest = local.key;
				}
			}
			local.rv[local.largest] = true;
			local.count -= local.sizes[local.largest] - 1;
			StructDelete(local.sizes, local.largest);
		}
		return local.rv;
	}

	/**
	 * Internal function. The SQL parts for an IN list bound as one STRING_SPLIT parameter.
	 */
	public array function $stringSplitParts(required struct part, struct dateCasts = {}) {
		local.split = $stringSplitList(part = arguments.part, dateCasts = arguments.dateCasts);
		return [
			"(SELECT " & local.split.expression & " FROM STRING_SPLIT(",
			{type = "cf_sql_nvarchar", value = ArrayToList(local.split.values, Chr(31))},
			", NCHAR(31)))"
		];
	}

	/**
	 * Internal function. For an IN list STRING_SPLIT can carry, its values and the expression that
	 * turns each split value back into the list's type: integers and decimals are validated here
	 * and CAST (never TRY_CAST, which turns '' into 0), strings are compared as they are. Dates and
	 * timestamps are cast to the type the driver binds them as, given in `dateCasts` (#4318). An
	 * empty struct for any other list, including times, or one with a value that doesn't validate.
	 */
	public struct function $stringSplitList(required any part, struct dateCasts = {}) {
		if (
			!IsStruct(arguments.part)
			|| !StructKeyExists(arguments.part, "list")
			|| !arguments.part.list
			|| !StructKeyExists(arguments.part, "value")
			|| !StructKeyExists(arguments.part, "type")
		) {
			return {};
		}
		local.values = ListToArray($queryParams(arguments.part).value, Chr(7));
		local.integerType = $stringSplitIntegerType(arguments.part.type);
		if (Len(local.integerType)) {
			return $stringSplitNumbers(values = local.values, pattern = "^-?[0-9]+$", sqlType = local.integerType);
		}
		if (ListFindNoCase("cf_sql_decimal,cf_sql_numeric", arguments.part.type)) {
			return $stringSplitDecimals(local.values);
		}
		if (ListFindNoCase("cf_sql_varchar,cf_sql_char", arguments.part.type)) {
			return $stringSplitStrings(local.values);
		}
		if (StructKeyExists(arguments.dateCasts, arguments.part.type)) {
			return $stringSplitDates(
				values = local.values,
				sqlType = arguments.dateCasts[arguments.part.type],
				dateOnly = CompareNoCase(arguments.part.type, "cf_sql_date") == 0
			);
		}
		return {};
	}

	/**
	 * Internal function. Date or timestamp values written in a form SQL Server reads the same way
	 * under every language and DATEFORMAT setting, cast to `sqlType`; empty when a value isn't in a
	 * form $isoDateTimeValue() accepts.
	 */
	public struct function $stringSplitDates(required array values, required string sqlType, required boolean dateOnly) {
		local.rv = [];
		for (local.value in arguments.values) {
			local.iso = $isoDateTimeValue(value = local.value, dateOnly = arguments.dateOnly);
			if (!Len(local.iso)) {
				return {};
			}
			ArrayAppend(local.rv, local.iso);
		}
		return {expression = "CAST(value AS #arguments.sqlType#)", values = local.rv};
	}

	/**
	 * Internal function. `value` as `yyyy-mm-ddTHH:nn:ss.lll` (or `yyyy-mm-dd` when `dateOnly`), or ""
	 * when it isn't a valid date written as `yyyy-mm-dd` with an optional ` HH:nn`, `:ss` and
	 * `.lll`, or CFML's `{ts '...'}` / `{d '...'}` form of one. Other forms (locale dates, time
	 * zones, other fractions) are left to the one-parameter-per-value path, whose parsing they need.
	 */
	public string function $isoDateTimeValue(required string value, required boolean dateOnly) {
		local.text = Trim(arguments.value);
		local.wrapped = ReFind("^\{(ts|d) '([^']*)'\}$", local.text, 1, true);
		if (local.wrapped.pos[1]) {
			local.text = Mid(local.text, local.wrapped.pos[3], local.wrapped.len[3]);
		}
		local.pattern = arguments.dateOnly ? "^([0-9]{4})-([0-9]{2})-([0-9]{2})$" : "^([0-9]{4})-([0-9]{2})-([0-9]{2})([ T]([0-9]{2}):([0-9]{2})(:([0-9]{2})(\.([0-9]{3}))?)?)?$";
		local.parts = $regexGroups(pattern = local.pattern, text = local.text, count = 10);
		if (!ArrayLen(local.parts)) {
			return "";
		}
		local.date = Left(local.text, 10);
		if (!$isCalendarDate(local.date)) {
			return "";
		}
		if (arguments.dateOnly) {
			return local.date;
		}
		local.hour = Len(local.parts[5]) ? local.parts[5] : "00";
		local.minute = Len(local.parts[6]) ? local.parts[6] : "00";
		local.second = Len(local.parts[8]) ? local.parts[8] : "00";
		local.fraction = Len(local.parts[10]) ? local.parts[10] : "000";
		if (Val(local.hour) > 23 || Val(local.minute) > 59 || Val(local.second) > 59) {
			return "";
		}
		return local.date & "T" & local.hour & ":" & local.minute & ":" & local.second & "." & local.fraction;
	}

	/**
	 * Internal function. The text of groups 1 to `count` when `pattern` matches `text` ("" for a
	 * group that took no part), or an empty array when it doesn't match. Engines differ in how
	 * they report a group that took no part (0 or -1, or a shorter array), so any of those is "".
	 */
	public array function $regexGroups(required string pattern, required string text, required numeric count) {
		local.match = ReFind(arguments.pattern, arguments.text, 1, true);
		if (local.match.pos[1] < 1) {
			return [];
		}
		local.rv = [];
		for (local.i = 2; local.i <= arguments.count + 1; local.i++) {
			if (local.i <= ArrayLen(local.match.pos) && local.match.pos[local.i] > 0 && local.match.len[local.i] > 0) {
				ArrayAppend(local.rv, Mid(arguments.text, local.match.pos[local.i], local.match.len[local.i]));
			} else {
				ArrayAppend(local.rv, "");
			}
		}
		return local.rv;
	}

	/**
	 * Internal function. True when `yyyy-mm-dd` names a real calendar day.
	 */
	public boolean function $isCalendarDate(required string ymd) {
		local.year = Val(ListGetAt(arguments.ymd, 1, "-"));
		local.month = Val(ListGetAt(arguments.ymd, 2, "-"));
		local.day = Val(ListGetAt(arguments.ymd, 3, "-"));
		if (local.year < 1 || local.month < 1 || local.month > 12 || local.day < 1) {
			return false;
		}
		return local.day <= DaysInMonth(CreateDate(local.year, local.month, 1));
	}

	/**
	 * Internal function. The SQL Server type an integer IN list is cast to, or "" for other types.
	 */
	public string function $stringSplitIntegerType(required string sqlType) {
		local.types = {cf_sql_tinyint = "TINYINT", cf_sql_smallint = "SMALLINT", cf_sql_integer = "INT", cf_sql_bigint = "BIGINT"};
		return StructKeyExists(local.types, arguments.sqlType) ? local.types[arguments.sqlType] : "";
	}

	/**
	 * Internal function. Trimmed values cast to `sqlType`, when every value matches `pattern`.
	 */
	public struct function $stringSplitNumbers(required array values, required string pattern, required string sqlType) {
		local.rv = [];
		for (local.value in arguments.values) {
			local.value = Trim(local.value);
			if (!ReFind(arguments.pattern, local.value)) {
				return {};
			}
			ArrayAppend(local.rv, local.value);
		}
		return {expression = "CAST(value AS #arguments.sqlType#)", values = local.rv};
	}

	/**
	 * Internal function. Plain decimal values cast exactly to DECIMAL(38, s), `s` being the most
	 * fraction digits of any value; empty when a value isn't a plain decimal or doesn't fit 38 digits.
	 */
	public struct function $stringSplitDecimals(required array values) {
		local.scale = 0;
		local.integerDigits = 0;
		for (local.value in arguments.values) {
			local.value = Trim(local.value);
			if (!ReFind("^-?[0-9]+(\.[0-9]+)?$", local.value)) {
				return {};
			}
			local.scale = Max(local.scale, $fractionDigitCount(local.value));
			local.integerDigits = Max(local.integerDigits, $integerDigitCount(local.value));
		}
		if (local.integerDigits + local.scale > 38) {
			return {};
		}
		return $stringSplitNumbers(
			values = arguments.values,
			pattern = "^-?[0-9]+(\.[0-9]+)?$",
			sqlType = "DECIMAL(38, #local.scale#)"
		);
	}

	/**
	 * Internal function. String values, compared as they are. A value holding the NCHAR(31)
	 * delimiter can't be split, so it is refused with a clear error.
	 */
	public struct function $stringSplitStrings(required array values) {
		for (local.value in arguments.values) {
			if (Find(Chr(31), local.value)) {
				Throw(
					type = "Wheels.QueryParamValue",
					message = "An IN list value contains the control character Chr(31), which Wheels uses to bind long IN lists on SQL Server.",
					extendedInfo = "Remove the character from the value, or query the values in batches of fewer than #$maxBoundParameters()#."
				);
			}
		}
		return {expression = "value", values = arguments.values};
	}

	/**
	 * Internal function. The parameter count above which IN lists are split: the database limit,
	 * or a lower value set by $setInListSplitLimit() (used by the specs to exercise the split path).
	 */
	public numeric function $inListSplitLimit() {
		if (StructKeyExists(variables, "inListSplitLimit") && variables.inListSplitLimit > 0) {
			return variables.inListSplitLimit;
		}
		return $maxBoundParameters();
	}

	/**
	 * Internal function. Sets the split limit; 0 restores the database limit.
	 */
	public void function $setInListSplitLimit(required numeric limit) {
		variables.inListSplitLimit = arguments.limit;
	}

	/**
	 * Internal function. Wheels.TooManyParameters advice for SQL Server: which long lists run as one
	 * STRING_SPLIT parameter, and that every other list (or a database below level 130) doesn't.
	 */
	public string function $tooManyParametersAdvice(required numeric limit) {
		return super.$tooManyParametersAdvice(limit = arguments.limit)
			& " On SQL Server 2016 and later (database compatibility level 130 or higher), Wheels runs a long list of integers, plain decimals (up to 38 digits), strings or uniqueidentifiers as one parameter, and also a list of dates or timestamps written as yyyy-mm-dd with an optional HH:nn, :ss and .lll. Any other list (times, dates written another way, float, real, bit, text or binary values, or numbers written another way, such as +5, .5 or 1E5), or a database below level 130, still needs batching.";
	}

	/**
	 * Internal function. True when the datasource's database has compatibility level 130 or higher,
	 * which STRING_SPLIT needs. Read once per datasource and kept in the application's Wheels
	 * settings, so an application reload reads it again.
	 */
	public boolean function $supportsStringSplit(required string dataSource) {
		local.appKey = $appKey();
		local.dataSource = $effectiveDataSource(arguments.dataSource);
		if (!StructKeyExists(application[local.appKey], "sqlServerCompatibilityLevels")) {
			application[local.appKey].sqlServerCompatibilityLevels = {};
		}
		local.levels = application[local.appKey].sqlServerCompatibilityLevels;
		if (!StructKeyExists(local.levels, local.dataSource)) {
			local.levels[local.dataSource] = $readCompatibilityLevel(local.dataSource);
		}
		return local.levels[local.dataSource] >= 130;
	}

	/**
	 * Internal function. The database's compatibility level, or 0 when it can't be read.
	 */
	public numeric function $readCompatibilityLevel(required string dataSource) {
		local.options = {datasource = arguments.dataSource};
		if (Len(variables.username)) {
			local.options.username = variables.username;
		}
		if (Len(variables.password)) {
			local.options.password = variables.password;
		}
		try {
			local.query = QueryExecute("SELECT compatibility_level AS lvl FROM sys.databases WHERE name = DB_NAME()", [], local.options);
			return local.query.recordCount ? Val(local.query.lvl) : 0;
		} catch (any e) {
			return 0;
		}
	}

	/**
	 * Internal function. The CAST each date or timestamp IN list is split with, keyed by cf_sql type:
	 * the type the datasource's driver binds that cf_sql type as, so a split list matches exactly
	 * the rows a list bound one parameter per value matches (#4318). Read once per datasource and
	 * kept in the application's Wheels settings, like the compatibility level.
	 */
	public struct function $stringSplitDateCasts(required string dataSource) {
		local.appKey = $appKey();
		local.dataSource = $effectiveDataSource(arguments.dataSource);
		if (!StructKeyExists(application[local.appKey], "sqlServerDateBindTypes")) {
			application[local.appKey].sqlServerDateBindTypes = {};
		}
		local.bindTypes = application[local.appKey].sqlServerDateBindTypes;
		if (!StructKeyExists(local.bindTypes, local.dataSource)) {
			local.bindTypes[local.dataSource] = $readDateBindTypes(local.dataSource);
		}
		return $dateCastsFor(local.bindTypes[local.dataSource]);
	}

	/**
	 * Internal function. Casts for the bind types $readDateBindTypes() found. Only the bind types the
	 * split form is proven to mirror get one: a timestamp bound as datetime2(7) and a date bound as
	 * date. Any other driver behaviour leaves those lists to Wheels.TooManyParameters.
	 */
	public struct function $dateCastsFor(required struct bindTypes) {
		local.rv = {};
		if (StructKeyExists(arguments.bindTypes, "cf_sql_timestamp") && Compare(arguments.bindTypes.cf_sql_timestamp, "datetime2/7") == 0) {
			local.rv.cf_sql_timestamp = "DATETIME2(7)";
		}
		if (StructKeyExists(arguments.bindTypes, "cf_sql_date") && Compare(arguments.bindTypes.cf_sql_date, "date/0") == 0) {
			local.rv.cf_sql_date = "DATE";
		}
		return local.rv;
	}

	/**
	 * Internal function. The SQL Server base type and scale (`datetime2/7`) the driver binds a
	 * cf_sql_timestamp and a cf_sql_date parameter as, or an empty struct when it can't be read.
	 */
	public struct function $readDateBindTypes(required string dataSource) {
		local.options = {datasource = arguments.dataSource};
		if (Len(variables.username)) {
			local.options.username = variables.username;
		}
		if (Len(variables.password)) {
			local.options.password = variables.password;
		}
		local.property = "CAST(SQL_VARIANT_PROPERTY(CAST(? AS SQL_VARIANT), '%s') AS VARCHAR(30))";
		local.sql = "SELECT " & Replace(local.property, "%s", "BaseType") & " AS tsType, " & Replace(local.property, "%s", "Scale") & " AS tsScale, "
			& Replace(local.property, "%s", "BaseType") & " AS dType, " & Replace(local.property, "%s", "Scale") & " AS dScale";
		local.ts = {value = "2026-01-02 10:00:00", cfsqltype = "cf_sql_timestamp"};
		local.d = {value = "2026-01-02", cfsqltype = "cf_sql_date"};
		try {
			local.query = QueryExecute(local.sql, [local.ts, local.ts, local.d, local.d], local.options);
			return {
				cf_sql_timestamp = LCase(local.query.tsType) & "/" & local.query.tsScale,
				cf_sql_date = LCase(local.query.dType) & "/" & local.query.dScale
			};
		} catch (any e) {
			return {};
		}
	}

	/**
	 * SQL Server accepts at most 2100 parameters in one request, and the JDBC drivers use some of them
	 * themselves: mssql-jdbc (Lucee, BoxLang) runs 2098 bound values and fails at 2099, Adobe's
	 * driver runs 2097 and fails at 2098. 2097 is the highest count that runs on every engine (#3906).
	 */
	public numeric function $maxBoundParameters() {
		return 2097;
	}

	/**
	 * SQL Server's TINYINT is unsigned, 0 to 255 (#4087).
	 */
	public struct function $integerKeyRange(required string sqlType) {
		if (arguments.sqlType == "cf_sql_tinyint") {
			return {min = "0", max = "255"};
		}
		return super.$integerKeyRange(argumentCollection = arguments);
	}

	variables.mssqlTypeMap = {
		"bigint": "cf_sql_bigint",
		"binary": "cf_sql_binary",
		"geography": "cf_sql_binary",
		"geometry": "cf_sql_binary",
		"timestamp": "cf_sql_binary",
		"bit": "cf_sql_bit",
		"char": "cf_sql_char",
		"nchar": "cf_sql_char",
		"uniqueidentifier": "cf_sql_char",
		"date": "cf_sql_date",
		"datetime": "cf_sql_timestamp",
		"datetime2": "cf_sql_timestamp",
		"smalldatetime": "cf_sql_timestamp",
		"datetimeoffset": "cf_sql_timestamp",
		"decimal": "cf_sql_decimal",
		"money": "cf_sql_decimal",
		"smallmoney": "cf_sql_decimal",
		"float": "cf_sql_float",
		"int": "cf_sql_integer",
		"image": "cf_sql_longvarbinary",
		"text": "cf_sql_longvarchar",
		"ntext": "cf_sql_longvarchar",
		"xml": "cf_sql_longvarchar",
		"numeric": "cf_sql_numeric",
		"real": "cf_sql_real",
		"smallint": "cf_sql_smallint",
		"time": "cf_sql_time",
		"tinyint": "cf_sql_tinyint",
		"varbinary": "cf_sql_varbinary",
		"varchar": "cf_sql_varchar",
		"nvarchar": "cf_sql_varchar",
		"hierarchyid": "cf_sql_varchar",
		"cursor": "cf_sql_refcursor"
	};

	/**
	 * Map database types to the ones used in CFML.
	 */
	public string function $getType(required string type, string scale, string details) {
		local.key = LCase(arguments.type);
		if (StructKeyExists(variables.mssqlTypeMap, local.key)) {
			return variables.mssqlTypeMap[local.key];
		}
		$throwUnknownColumnType(arguments.type);
	}

	/**
	 * The nested TOP queries in $querySetup() return the last `limit` rows rather than the requested
	 * window when limit + offset exceeds the matching rows, so callers must clamp the limit first.
	 */
	public boolean function $offsetNeedsRowCount() {
		return true;
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
		// An INSERT that supplies its own primary-key value may need IDENTITY_INSERT
		// (#3647). This runs before the BoxLang branch below on purpose: a wrapped
		// statement no longer starts with INSERT INTO, so no SCOPE_IDENTITY() is
		// appended — correctly, since the caller already has the key.
		if (
			Len(Trim(arguments.$primaryKey))
			&& IsSimpleValue(arguments.sql[1])
			&& Left(arguments.sql[1], 11) == "INSERT INTO"
		) {
			arguments.sql = $identityInsertSQL(sql = arguments.sql, primaryKey = arguments.$primaryKey);
		}

		// Same-batch identity retrieval for engines whose query result carries no
		// driver-supplied generated key (currently BoxLang). SCOPE_IDENTITY() is
		// batch-scoped, so it must ride in the INSERT's own batch; Base.$executeQuery
		// passes the resulting resultset to $identitySelect as returningIdentity
		// (the same plumbing the CockroachDB adapter uses for RETURNING). Bulk paths
		// pass no primary-key hint and are skipped.
		if (
			$isBoxLangEngine()
			&& Len(Trim(arguments.$primaryKey))
			&& IsSimpleValue(arguments.sql[1])
			&& Left(arguments.sql[1], 11) == "INSERT INTO"
		) {
			ArrayAppend(arguments.sql, ";SELECT SCOPE_IDENTITY() AS lastId");
		}

		if (StructKeyExists(arguments, "maxrows") && arguments.maxrows > 0) {
			if (arguments.maxrows > 0) {
				arguments.sql[1] = ReplaceNoCase(arguments.sql[1], "SELECT ", "SELECT TOP #arguments.maxrows# ", "one");
			}
			StructDelete(arguments, "maxrows");
		}
		if (arguments.limit + arguments.offset > 0) {
			local.containsGroup = false;
			local.afterWhere = "";
			if (
				IsSimpleValue(arguments.sql[ArrayLen(arguments.sql) - 1])
				&& FindNoCase("GROUP BY", arguments.sql[ArrayLen(arguments.sql) - 1])
			) {
				local.containsGroup = true;
			}

			// Fix for pagination issue when ordering multiple columns with same name.
			if (Find(",", arguments.sql[ArrayLen(arguments.sql)])) {
				local.order = arguments.sql[ArrayLen(arguments.sql)];
				local.newOrder = "";
				local.doneColumns = "";
				local.done = 0;
				local.iEnd = ListLen(local.order);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.item = ListGetAt(local.order, local.i);
					local.column = SpanExcluding(Reverse(SpanExcluding(Reverse(local.item), ".")), " ");
					if (ListFind(local.doneColumns, local.column)) {
						local.done++;
						local.item &= " AS tmp" & local.done;
					}
					local.doneColumns = ListAppend(local.doneColumns, local.column);
					local.newOrder = ListAppend(local.newOrder, local.item);
				}
				arguments.sql[ArrayLen(arguments.sql)] = local.newOrder;
			}

			// Select clause always comes first in the array, the order by clause last, remove the leading keywords leaving only the columns and set to the ones used in the inner most sub query.
			local.thirdSelect = ReplaceNoCase(ReplaceNoCase(arguments.sql[1], "SELECT DISTINCT ", ""), "SELECT ", "");
			local.thirdOrder = ReplaceNoCase(arguments.sql[ArrayLen(arguments.sql)], "ORDER BY ", "");
			if (local.containsGroup) {
				local.thirdGroup = ReplaceNoCase(arguments.sql[ArrayLen(arguments.sql) - 1], "GROUP BY ", "");
			}

			// The first select is the outer most in the query and need to contain columns without table names and using aliases when they exist.
			local.firstSelect = $columnAlias(list = $tableName(list = local.thirdSelect, action = "remove"), action = "keep");

			// We need to add columns from the inner order clause to the select clauses in the inner two queries.
			// Strip identifier quotes once up front (and keep the stripped list in sync with appends below)
			// instead of re-stripping the whole select list on every loop iteration.
			local.thirdSelectStripped = $stripIdentifierQuotes(local.thirdSelect);
			local.iEnd = ListLen(local.thirdOrder);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.item = ReReplace(ReReplace(ListGetAt(local.thirdOrder, local.i), " ASC\b", ""), " DESC\b", "");
				// Strip identifier quotes for comparison since SELECT may have different quoting than ORDER BY
				local.itemStripped = $stripIdentifierQuotes(local.item);
				if (!ListFindNoCase(local.thirdSelectStripped, local.itemStripped) && !ListFindNoCase(local.thirdSelect, local.item)) {
					// The test "order_clause_with_paginated_include_and_ambiguous_columns" passes in a complex order (CASE WHEN registration IN ('foo') THEN 0 ELSE 1 END DESC).
					// This gets moved up to the SELECT clause to support pagination.
					// However, we need to add "AS" to it otherwise we get a "No column name was specified" error.
					// We check if it's complex simply by looking for a space in the table / column name and that it's not a calculated property (the "AS" part).
					if (Find(" ", local.item) && !Find(" AS ", local.item)) {
						local.item &= " AS tmpSelect" & local.i;
					}

					local.thirdSelect = ListAppend(local.thirdSelect, local.item);
					local.thirdSelectStripped = ListAppend(local.thirdSelectStripped, $stripIdentifierQuotes(local.item));
				}
				if (local.containsGroup) {
					local.item = ReReplace(local.item, "[[:space:]]AS[[:space:]][A-Za-z1-9]+", "", "all");
					if (!ListFindNoCase(local.thirdGroup, local.item)) {
						local.thirdGroup = ListAppend(local.thirdGroup, local.item);
					}
				}
			}

			// The second select also needs to contain columns without table names and using aliases when they exist (but now including the columns added above).
			local.secondSelect = $columnAlias(list = $tableName(list = local.thirdSelect, action = "remove"), action = "keep");

			// First order also needs the table names removed, the column aliases can be kept since they are removed before running the query anyway.
			local.firstOrder = $tableName(list = local.thirdOrder, action = "remove");

			// Second order clause is the same as the first but with the ordering reversed.
			local.secondOrder = Replace(
				ReReplace(ReReplace(local.firstOrder, " DESC\b", Chr(7), "all"), " ASC\b", " DESC", "all"),
				Chr(7),
				" ASC",
				"all"
			);

			// Fix column aliases from order by clauses.
			local.thirdOrder = $columnAlias(list = local.thirdOrder, action = "remove");
			local.secondOrder = $columnAlias(list = local.secondOrder, action = "keep");
			local.firstOrder = $columnAlias(list = local.firstOrder, action = "keep");

			// Build new SQL string and replace the old one with it.
			local.beforeWhere = "SELECT " & local.firstSelect & " FROM (SELECT TOP " & arguments.limit & " " & local.secondSelect & " FROM (SELECT ";
			if (Find(" ", ListRest(arguments.sql[2], " "))) {
				local.beforeWhere &= "DISTINCT ";
			}
			local.beforeWhere &= "TOP " & arguments.limit + arguments.offset & " " & local.thirdSelect & " " & arguments.sql[2];
			if (local.containsGroup) {
				local.afterWhere = "GROUP BY " & local.thirdGroup & " ";
			}
			local.afterWhere &= "ORDER BY " & local.thirdOrder & ") AS tmp1 ORDER BY " & local.secondOrder & ") AS tmp2 ORDER BY " & local.firstOrder;
			ArrayDeleteAt(arguments.sql, 1);
			ArrayDeleteAt(arguments.sql, 1);
			ArrayDeleteAt(arguments.sql, ArrayLen(arguments.sql));
			if (local.containsGroup) {
				ArrayDeleteAt(arguments.sql, ArrayLen(arguments.sql));
			}
			ArrayPrepend(arguments.sql, local.beforeWhere);
			ArrayAppend(arguments.sql, local.afterWhere);
		} else {
			$removeColumnAliasesInOrderClause(args = arguments);
		}

		// SQL Server doesn't support limit and offset in SQL.
		StructDelete(arguments, "limit");
		StructDelete(arguments, "offset");

		$moveAggregateToHaving(args = arguments);
		return $performQuery(argumentCollection = arguments);
	}

	/**
	 * SQL Server rejects an explicit value for an IDENTITY column unless
	 * IDENTITY_INSERT is ON for the table, so `create(id = 41, ...)` failed here while
	 * every other supported database accepts it (#3647). This wraps an INSERT whose
	 * column list includes a primary-key column (the caller supplied that value) in the
	 * ON/OFF pair. Three rules shape the wrapper:
	 *
	 * - One batch. IDENTITY_INSERT is session-scoped, so the ON, the INSERT and the OFF
	 *   must share a connection; a single statement guarantees that whether or not the
	 *   caller opened a transaction.
	 * - Guarded by the catalog. The ON/OFF only runs when one of those key columns is
	 *   in sys.identity_columns. A natural or UUID key has no identity property, and
	 *   SET IDENTITY_INSERT on such a table is an error.
	 * - No TRY/CATCH. The OFF must run even when the INSERT fails: with inlined values
	 *   (parameterize=false) the batch runs as-is and the setting outlives it, so the
	 *   pooled connection's next insert into the table would fail. A constraint
	 *   violation only ends its own statement, so the trailing OFF still runs.
	 *   Re-raising from a CATCH block (THROW) does not work: Lucee drops an error raised
	 *   after a batch's first result, so a duplicate key came back as success.
	 *
	 * Returns the SQL array unchanged when no primary-key column is supplied.
	 *
	 * @sql The INSERT statement as a `$querySetup()` SQL array.
	 * @primaryKey The table's primary-key column name(s).
	 */
	public array function $identityInsertSQL(required array sql, required string primaryKey) {
		// Parse the INSERT's column list from the fragment strings only (the values are
		// param structs), the same parse $identitySelect uses.
		local.text = "";
		for (local.part in arguments.sql) {
			if (IsSimpleValue(local.part)) {
				local.text &= local.part;
			}
		}
		local.insertColumns = $parseInsertColumnList(local.text);

		local.names = "";
		for (local.key in ListToArray(arguments.primaryKey)) {
			local.column = $stripIdentifierQuotes(Trim(local.key));
			if (ListFindNoCase(local.insertColumns, local.column)) {
				local.names = ListAppend(local.names, "N'" & Replace(local.column, "'", "''", "all") & "'");
			}
		}
		if (!Len(local.names)) {
			return arguments.sql;
		}

		// "INSERT INTO [table] (" -> "[table]"
		local.table = Trim(SpanExcluding(Mid(arguments.sql[1], 12, Len(arguments.sql[1])), "("));
		local.tableLiteral = Replace(local.table, "'", "''", "all");

		ArrayPrepend(
			arguments.sql,
			"DECLARE @wheelsIdentityInsert bit = CASE WHEN EXISTS (SELECT 1 FROM sys.identity_columns"
			& " WHERE object_id = OBJECT_ID(N'" & local.tableLiteral & "') AND name IN (" & local.names & "))"
			& " THEN 1 ELSE 0 END; IF @wheelsIdentityInsert = 1 SET IDENTITY_INSERT " & local.table & " ON;"
		);
		ArrayAppend(arguments.sql, "; IF @wheelsIdentityInsert = 1 SET IDENTITY_INSERT " & local.table & " OFF;");
		return arguments.sql;
	}

	/**
	 * Acquire a SQL Server application lock using sp_getapplock, owned by the database session
	 * (#4220), so no transaction is needed.
	 */
	public void function $acquireAdvisoryLock(required string name, numeric timeout = 10) {
		$acquireAdvisoryLockSession(name = arguments.name, timeout = arguments.timeout);
	}

	/**
	 * Internal function. Acquires a session-owned application lock (sp_getapplock @LockOwner =
	 * 'Session') and returns the holding session's id, @@SPID read in the same batch (#4220, #4197).
	 * The default 'Transaction' owner needs an open transaction, so withAdvisoryLock() used to fail
	 * outside one.
	 *
	 * sp_getapplock RETURNS a status rather than throwing: >= 0 granted (0 immediately, 1 after
	 * waiting), < 0 failed (-1 timeout, -2 canceled, -3 deadlock victim, -999 parameter/other). The
	 * batch opens with SET NOCOUNT ON so the driver does not surface a leading update count ahead of
	 * the SELECT, which would leave QueryExecute without a result set.
	 */
	public string function $acquireAdvisoryLockSession(required string name, numeric timeout = 10) {
		local.result = queryExecute(
			"SET NOCOUNT ON; DECLARE @r int; EXEC @r = sp_getapplock @Resource = ?, @LockMode = 'Exclusive', @LockOwner = 'Session', @LockTimeout = ?; SELECT @r AS lockResult, @@SPID AS sessionId",
			[arguments.name, arguments.timeout * 1000],
			$advisoryLockConnection()
		);
		local.status = (IsQuery(local.result) && local.result.recordCount) ? Val(local.result.lockResult) : -999;
		if (local.status < 0) {
			if (local.status == -1) {
				Throw(
					type = "Wheels.AdvisoryLockTimeout",
					message = "Could not acquire advisory lock '#arguments.name#' within #arguments.timeout# seconds.",
					extendedInfo = "SQL Server sp_getapplock returned -1 (timeout), indicating another session holds the lock."
				);
			}
			Throw(
				type = "Wheels.AdvisoryLockError",
				message = "Could not acquire advisory lock '#arguments.name#' (sp_getapplock returned #local.status#).",
				extendedInfo = "SQL Server sp_getapplock returned a negative status: -2 canceled, -3 deadlock victim, -999 parameter or other error."
			);
		}
		return local.result.sessionId;
	}

	/**
	 * Release a SQL Server application lock held by this session. A session that doesn't hold it
	 * releases nothing.
	 */
	public void function $releaseAdvisoryLock(required string name) {
		$tryReleaseAdvisoryLock(name = arguments.name);
	}

	/**
	 * Internal function. Releases the lock when this pooled session holds it and reports whether it
	 * did (#4197). APPLOCK_MODE is checked first: sp_releaseapplock on a session that doesn't hold
	 * the lock raises an error instead of returning a status.
	 */
	public boolean function $tryReleaseAdvisoryLock(required string name) {
		local.result = queryExecute(
			"SET NOCOUNT ON; DECLARE @n nvarchar(255) = ?; DECLARE @r int = -1; IF APPLOCK_MODE('public', @n, 'Session') <> 'NoLock' EXEC @r = sp_releaseapplock @Resource = @n, @LockOwner = 'Session'; SELECT @r AS released",
			[arguments.name],
			$advisoryLockConnection()
		);
		return IsQuery(local.result) && local.result.recordCount && Val(local.result.released) >= 0;
	}

	/**
	 * Internal function. True while the named lock is held: by the session `holder` when given, by
	 * any session otherwise (#4197). The holder is read from sys.dm_tran_locks, where an application
	 * lock appears as `<db>:[<first 32 characters of the name>]:(<hash>)`. That view needs the VIEW
	 * SERVER (PERFORMANCE) STATE permission; without it the check falls back to whether ANY session
	 * holds the lock (APPLOCK_MODE for this session, APPLOCK_TEST for the others), which can only
	 * make a release wait longer, never report a held lock as free.
	 */
	public boolean function $isAdvisoryLockHeld(required string name, string holder = "") {
		if (!StructKeyExists(variables, "$applockViewDenied")) {
			try {
				return $isAdvisoryLockHeldBySession(name = arguments.name, holder = arguments.holder);
			} catch (any e) {
				// Only a missing permission switches this adapter to the fallback for good.
				if (!$isPermissionDenied(e)) {
					rethrow;
				}
				variables.$applockViewDenied = true;
			}
		}
		return $isAdvisoryLockHeldByAnySession(name = arguments.name);
	}

	/**
	 * Internal function. True when a database error is SQL Server refusing a permission: error 300
	 * (VIEW ... STATE permission was denied), 297 (the user does not have permission to perform this
	 * action) or 229 (permission denied on an object). Keyed on the error number, so it holds on a
	 * server whose messages aren't in English; the message text is a fallback for an engine that
	 * gives no number.
	 */
	public boolean function $isPermissionDenied(required any exception) {
		if (ListFind("229,297,300", $sqlServerErrorNumber(arguments.exception))) {
			return true;
		}
		local.text = "";
		for (local.key in ["message", "detail"]) {
			try {
				local.text &= " " & arguments.exception[local.key];
			} catch (any e) {
			}
		}
		return FindNoCase("permission", local.text) > 0;
	}

	/**
	 * Internal function. SQL Server's error number for a database error, or 0. Each engine keeps it
	 * somewhere else: Lucee and Adobe in nativeErrorCode, BoxLang only on the driver's
	 * SQLServerException in the Java cause chain, and a thrown error (cfthrow) in errorCode.
	 */
	public numeric function $sqlServerErrorNumber(required any exception) {
		try {
			local.native = arguments.exception.nativeErrorCode;
			if (IsNumeric(local.native) && local.native > 0) {
				return Val(local.native);
			}
		} catch (any e) {
		}
		try {
			local.cause = arguments.exception.getCause();
			local.depth = 0;
			while (!IsNull(local.cause) && local.depth < 5) {
				local.code = local.cause.getErrorCode();
				if (IsNumeric(local.code) && local.code > 0) {
					return Val(local.code);
				}
				local.cause = local.cause.getCause();
				local.depth++;
			}
		} catch (any e) {
		}
		try {
			local.code = arguments.exception.errorCode;
			if (IsNumeric(local.code) && local.code > 0) {
				return Val(local.code);
			}
		} catch (any e) {
		}
		return 0;
	}

	/**
	 * Internal function. The sys.dm_tran_locks form of $isAdvisoryLockHeld(); throws without the VIEW
	 * SERVER (PERFORMANCE) STATE permission.
	 */
	public boolean function $isAdvisoryLockHeldBySession(required string name, string holder = "") {
		local.sql = "SELECT COUNT(*) AS n FROM sys.dm_tran_locks WHERE resource_type = 'APPLICATION' AND request_owner_type = 'SESSION' AND CHARINDEX('[' + LEFT(?, 32) + ']', resource_description) > 0";
		local.params = [arguments.name];
		if (Len(arguments.holder)) {
			local.sql &= " AND request_session_id = ?";
			ArrayAppend(local.params, {value = arguments.holder, cfsqltype = "cf_sql_integer"});
		}
		local.result = queryExecute(local.sql, local.params, $advisoryLockConnection());
		return IsQuery(local.result) && local.result.recordCount && Val(local.result.n) > 0;
	}

	/**
	 * Internal function. True when any session holds the lock, read without special permissions:
	 * APPLOCK_MODE for this session (APPLOCK_TEST grants a session its own lock), APPLOCK_TEST for the
	 * others.
	 */
	public boolean function $isAdvisoryLockHeldByAnySession(required string name) {
		local.result = queryExecute(
			"SET NOCOUNT ON; DECLARE @n nvarchar(255) = ?; SELECT CASE WHEN APPLOCK_MODE('public', @n, 'Session') <> 'NoLock' THEN 1 WHEN APPLOCK_TEST('public', @n, 'Exclusive', 'Session') = 0 THEN 1 ELSE 0 END AS held",
			[arguments.name],
			$advisoryLockConnection()
		);
		return IsQuery(local.result) && local.result.recordCount && Val(local.result.held) == 1;
	}

	/**
	 * SQL Server supports standalone advisory locks with a session-owned sp_getapplock (#4220).
	 */
	public boolean function $supportsAdvisoryLocks() {
		return true;
	}

	/**
	 * SQL Server supports the transaction-scoped path (#4198), using a SESSION-owned application lock
	 * (sp_getapplock @LockOwner = 'Session'). The sp_getapplock 'Transaction' owner is unusable under
	 * Lucee / Adobe: cftransaction sets the JDBC connection to autocommit = false without issuing an
	 * explicit BEGIN TRANSACTION, so @@TRANCOUNT stays 0 and sp_getapplock @LockOwner = 'Transaction'
	 * returns -999 (verified on Lucee 7 — the pinning gate proved same-connection but not
	 * @@TRANCOUNT > 0). The transaction's role here is purely to pin one connection, exactly as for
	 * MySQL, so the session lock, the callback's queries and the release all run on one session.
	 */
	public boolean function $supportsTransactionalAdvisoryLock() {
		return true;
	}

	/**
	 * A SESSION-owned application lock is session- not transaction-scoped: it does not auto-release at
	 * transaction end, so the caller releases it explicitly on the pinned connection before the
	 * transaction closes (#4198). Same contract as MySQL.
	 */
	public boolean function $transactionalAdvisoryLockIsSessionScoped() {
		return true;
	}

	/**
	 * Internal function. Acquires a SQL Server session-owned application lock with sp_getapplock on
	 * the current (pinned) connection (#4198). @LockOwner = 'Session' is required because cftransaction
	 * does not raise @@TRANCOUNT on SQL Server (see $supportsTransactionalAdvisoryLock).
	 *
	 * The same session-owned acquire as the standalone path ($acquireAdvisoryLockSession); the
	 * enclosing transaction is what pins it to the callback's connection.
	 */
	public void function $acquireAdvisoryLockTransactional(required string name, numeric timeout = 10) {
		$acquireAdvisoryLockSession(name = arguments.name, timeout = arguments.timeout);
	}

	/**
	 * Internal function. Releases the SQL Server session-owned application lock on the pinned
	 * connection before the transaction closes (#4198). sp_releaseapplock returns >= 0 on success
	 * (0 released) and < 0 on error; on the pinned connection a negative result is a real failure and
	 * is thrown (no retry). SET NOCOUNT ON keeps the status SELECT the only result set. The caller runs
	 * this in a finally inside the transaction, so a release error never replaces the callback's own.
	 */
	public void function $releaseAdvisoryLockTransactional(required string name) {
		local.result = queryExecute(
			"SET NOCOUNT ON; DECLARE @r int; EXEC @r = sp_releaseapplock @Resource = ?, @LockOwner = 'Session'; SELECT @r AS releaseResult",
			[arguments.name],
			$advisoryLockConnection()
		);
		local.status = (IsQuery(local.result) && local.result.recordCount) ? Val(local.result.releaseResult) : -999;
		if (local.status < 0) {
			Throw(
				type = "Wheels.AdvisoryLockReleaseFailed",
				message = "Advisory lock '#arguments.name#' could not be released on its pinned connection.",
				extendedInfo = "SQL Server sp_releaseapplock returned #local.status# on the connection that holds the lock, which should not happen inside the lock's own transaction."
			);
		}
	}

	/**
	 * SQL Server uses table hints (WITH (UPDLOCK)) instead of trailing FOR UPDATE.
	 * Table hints require modifying the FROM clause which is too complex for initial implementation.
	 * Returns empty string to no-op.
	 */
	public string function $forUpdateClause() {
		return "";
	}

	/**
	 * Override Base adapter's function.
	 */
	public string function $generatedKey() {
		return "identitycol";
	}

	/**
	 * Override Base adapter's $identitySelect hook.
	 */
	public any function $lastIdLookup(
		required struct queryAttributes,
		required struct result,
		required string primaryKey,
		any returningIdentity = "",
		required string insertSql
	) {
		// Prefer the driver-supplied generated key: mssql-jdbc retrieves it in the
		// insert's own batch, so it is both scope-safe and trigger-safe — a trigger
		// that inserts into another identity table cannot leak its key in here.
		// StructKeyExists is case-insensitive, so Lucee's lowercase `generatedkey`
		// result key matches. ListFirst because multi-row inserts can return a list.
		if (StructKeyExists(arguments.result, "generatedKey") && Len(arguments.result.generatedKey)) {
			return ListFirst(arguments.result.generatedKey);
		}

		// Same-batch retrieval: when the engine surfaces no driver key, $querySetup
		// appended `;SELECT SCOPE_IDENTITY() AS lastId` to the INSERT's own batch
		// (SCOPE_IDENTITY() is batch-scoped, so it must ride along — a standalone
		// `SELECT SCOPE_IDENTITY()` executes in its own scope and returns NULL).
		// Base.$executeQuery pipes the batch's resultset in here as returningIdentity.
		if (
			IsQuery(arguments.returningIdentity)
			&& arguments.returningIdentity.recordCount
			&& ListFindNoCase(arguments.returningIdentity.columnList, "lastId")
			&& Len(arguments.returningIdentity.lastId[1])
		) {
			return arguments.returningIdentity.lastId[1];
		}

		$throwIdentityNotFound();
	}

	/**
	 * Override Base adapter's function.
	 */
	public string function $randomOrder() {
		return "NEWID()";
	}

	/**
	 * Override Base adapter's function.
	 * SQL Server uses square brackets to quote identifiers.
	 */
	public string function $quoteIdentifier(required string name) {
		return "[#arguments.name#]";
	}

	/**
	 * SQL Server upsert using MERGE statement syntax.
	 */
	public array function $upsertSQL(
		required string tableName,
		required array columns,
		required array uniqueBy,
		required array updateColumns,
		required array validProperties,
		required array records,
		required numeric batchStart,
		required numeric batchEnd,
		required struct propertyInfo
	) {
		local.sql = [];

		// Build column list for SELECT.
		local.colList = "";
		local.selectCols = "";
		for (local.c = 1; local.c <= ArrayLen(arguments.columns); local.c++) {
			if (Len(local.colList)) {
				local.colList &= ", ";
				local.selectCols &= ", ";
			}
			local.colList &= $quoteIdentifier(arguments.columns[local.c]);
			local.selectCols &= "source." & $quoteIdentifier(arguments.columns[local.c]);
		}

		// MERGE INTO target USING (VALUES rows) AS source(cols) ON match
		ArrayAppend(local.sql, "MERGE INTO #arguments.tableName# WITH (HOLDLOCK) AS target USING (VALUES ");

		// Build value rows.
		for (local.r = arguments.batchStart; local.r <= arguments.batchEnd; local.r++) {
			if (local.r > arguments.batchStart) {
				ArrayAppend(local.sql, ", ");
			}
			ArrayAppend(local.sql, "(");
			for (local.p = 1; local.p <= ArrayLen(arguments.validProperties); local.p++) {
				if (local.p > 1) ArrayAppend(local.sql, ", ");
				local.propName = arguments.validProperties[local.p];
				local.val = StructKeyExists(arguments.records[local.r], local.propName) ? arguments.records[local.r][local.propName] : "";
				ArrayAppend(local.sql, $buildBulkParam(value=local.val, propName=local.propName, propertyInfo=arguments.propertyInfo));
			}
			ArrayAppend(local.sql, ")");
		}

		ArrayAppend(local.sql, ") AS source (#local.colList#) ON ");

		// ON clause.
		local.onClause = "";
		for (local.u in arguments.uniqueBy) {
			if (Len(local.onClause)) local.onClause &= " AND ";
			local.onClause &= "target." & $quoteIdentifier(local.u) & " = source." & $quoteIdentifier(local.u);
		}
		ArrayAppend(local.sql, local.onClause);

		// WHEN MATCHED THEN UPDATE.
		if (ArrayLen(arguments.updateColumns)) {
			local.setClause = "";
			for (local.uc in arguments.updateColumns) {
				if (Len(local.setClause)) local.setClause &= ", ";
				local.setClause &= "target." & $quoteIdentifier(local.uc) & " = source." & $quoteIdentifier(local.uc);
			}
			ArrayAppend(local.sql, " WHEN MATCHED THEN UPDATE SET #local.setClause#");
		}

		// WHEN NOT MATCHED THEN INSERT.
		ArrayAppend(local.sql, " WHEN NOT MATCHED THEN INSERT (#local.colList#) VALUES (#local.selectCols#);");

		return local.sql;
	}

}
