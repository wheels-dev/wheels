/**
 * Engine adapter for BoxLang.
 * BoxLang has significant differences in PageContext, form parsing,
 * controller name handling, Oracle JDBC objects, date parsing,
 * and method invocation compared to Lucee/Adobe CF.
 */
component extends="wheels.engineAdapters.Base" output="false" {

	variables.engineName = "BoxLang";

	public boolean function isBoxLang() {
		return true;
	}

	/**
	 * BoxLang returns the response directly from GetPageContext().
	 */
	public any function getResponse() {
		return GetPageContext();
	}

	/**
	 * BoxLang gets Content-Type from the request side, not response side.
	 */
	public string function getContentType() {
		local.rv = "";
		local.response = getResponse();
		local.request = local.response.getRequest();
		local.header = local.request.getHeader("Content-Type");
		if (!IsNull(local.header)) {
			local.rv = local.header;
		}
		return local.rv;
	}

	/**
	 * BoxLang does not expose a standard request timeout API.
	 * Returns a hardcoded high value consistent with existing behavior.
	 */
	public numeric function getRequestTimeout() {
		return 10000;
	}

	/**
	 * BoxLang has different bracket-parsing semantics for form keys.
	 * Splits on "][" and cleans remaining brackets from each segment.
	 */
	public array function parseFormKey(required string key, required string name) {
		local.keyWithoutName = ReplaceNoCase(arguments.key, arguments.name & "[", "", "one");
		local.keyWithoutEndBracket = Left(local.keyWithoutName, Len(local.keyWithoutName) - 1);
		local.nested = [];
		local.segments = ListToArray(local.keyWithoutEndBracket, "][", false);
		for (local.segment in local.segments) {
			local.cleanSegment = Replace(Replace(local.segment, "[", "", "all"), "]", "", "all");
			ArrayAppend(local.nested, local.cleanSegment);
		}
		return local.nested;
	}

	/**
	 * BoxLang handles consecutive leading dots differently in controller names.
	 * Preserves the dot prefix and only uppercases the clean portion.
	 */
	public string function controllerNameToUpperCamelCase(required string name) {
		local.dotPrefix = "";
		local.cleanName = arguments.name;
		while (Left(local.cleanName, 1) == ".") {
			local.dotPrefix &= ".";
			local.cleanName = Right(local.cleanName, Len(local.cleanName) - 1);
		}
		local.cleanName = ReReplace(local.cleanName, "(^|-)([a-z])", "\u\2", "all");
		return local.dotPrefix & local.cleanName;
	}

	// --- Oracle JDBC Object Handling ---

	/**
	 * BoxLang encounters Oracle JDBC objects (TIMESTAMP, DATE, BLOB) that need
	 * coercion to CFML-native types.
	 */
	public any function coerceOracleObject(required any value) {
		if (!IsObject(arguments.value) || IsStruct(arguments.value)) {
			return arguments.value;
		}
		try {
			local.className = GetMetadata(arguments.value).getName();
		} catch (any e) {
			return arguments.value;
		}
		if (local.className == "oracle.sql.TIMESTAMP" || local.className == "oracle.sql.DATE") {
			try {
				local.timestampString = arguments.value.toString();
				if (Len(local.timestampString)) {
					return ParseDateTime(local.timestampString);
				}
			} catch (any e) {
				try {
					return arguments.value.toString();
				} catch (any e2) {
					// fall through
				}
			}
			return arguments.value;
		}
		if (local.className == "oracle.sql.BLOB") {
			try {
				return arguments.value.getBytes();
			} catch (any e) {
				// fall through
			}
		}
		return arguments.value;
	}

	/**
	 * Returns true if the value is an Oracle JDBC object that should be
	 * treated as having content for validation purposes.
	 */
	public boolean function isOracleJdbcObject(required any value) {
		if (!IsObject(arguments.value) || IsStruct(arguments.value)) {
			return false;
		}
		try {
			local.className = GetMetadata(arguments.value).getName();
			return ListContains("oracle.sql.TIMESTAMP,oracle.sql.DATE", local.className);
		} catch (any e) {
			return false;
		}
	}

	// --- Hash Normalization ---

	/**
	 * BoxLang needs a different normalization approach for consistent hashing.
	 * Removes structural chars with regex and sorts parts.
	 */
	public string function normalizeForHash(required string serialized) {
		local.normalized = REReplace(arguments.serialized, '[\[\]{}"]', "", "all");
		local.parts = listToArray(local.normalized, ",");
		arraySort(local.parts, "textnocase");
		return arrayToList(local.parts, ",");
	}

	// --- Struct Defaults ---

	/**
	 * BoxLang's StructAppend doesn't work correctly with overwrite=false,
	 * so we manually loop and set defaults.
	 */
	public void function structAppendDefaults(required struct target, required struct defaults) {
		for (local.key in arguments.defaults) {
			if (!StructKeyExists(arguments.target, local.key)) {
				arguments.target[local.key] = arguments.defaults[local.key];
			}
		}
	}

	// --- Numeric Validation ---

	/**
	 * BoxLang's IsNumeric() is locale-aware and accepts commas (e.g. "1,000.00").
	 * This stricter version rejects values with commas.
	 */
	public boolean function isNumericStrict(required any value) {
		if (!IsNumeric(arguments.value)) {
			return false;
		}
		if (IsSimpleValue(arguments.value) && Find(",", arguments.value)) {
			return false;
		}
		return true;
	}

	// --- DI Completion ---

	/**
	 * BoxLang requires variables.this = this before mixin integration.
	 */
	public void function prepareDIComplete(required struct vars, required any thisScope) {
		arguments.vars.this = arguments.thisScope;
	}

	// --- Method Invocation ---

	/**
	 * BoxLang dispatch via direct bracket-call rather than invoke().
	 *
	 * The bracket-and-call MUST happen in a single expression. Splitting it
	 * across two statements (local.method = obj[name]; local.method()) extracts
	 * a bare function reference and loses the component receiver, so any
	 * in-component call inside the invoked method (e.g. Public.cfc handlers
	 * calling $blockInProduction()) fails with "Function [$...] not found".
	 * Regression test: vendor/wheels/tests/specs/dispatch/InvokeMethodSpec.cfc.
	 * Issue #2646.
	 */
	public void function invokeMethod(required any object, required string methodName) {
		arguments.object[arguments.methodName]();
	}

	// --- Image Handling ---

	/**
	 * BoxLang uses ImageRead+ImageInfo instead of cfimage action=info.
	 */
	public struct function imageInfo(required string source) {
		var img = ImageRead(arguments.source);
		return ImageInfo(img);
	}

	// --- Zip Handling ---

	/**
	 * BoxLang requires absolute paths for zip operations.
	 */
	public struct function prepareZipArgs(required struct args) {
		if (StructKeyExists(arguments.args, "file") && Left(arguments.args.file, 1) != "/") {
			arguments.args.file = "/" & arguments.args.file;
		}
		if (StructKeyExists(arguments.args, "destination") && Left(arguments.args.destination, 1) != "/") {
			arguments.args.destination = "/" & arguments.args.destination;
		}
		return arguments.args;
	}

	// --- Glob Pattern Matching ---

	/**
	 * BoxLang uses *[varname] glob syntax instead of *varname.
	 */
	public string function globRegex() {
		return "\*\[([^\]]+)\]";
	}

	/**
	 * Extracts variable name from BoxLang's *[varname] pattern.
	 */
	public string function extractGlobVariable(required string glob) {
		return ReReplace(arguments.glob, "\*\[([^\]]+)\]", "\1");
	}

	// --- Query Argument Mapping ---

	/**
	 * BoxLang uses "columnKey" instead of "keyColumn" for cfquery.
	 */
	public string function queryKeyColumnArgName() {
		return "columnKey";
	}

	// --- Date Parsing ---

	/**
	 * BoxLang prefers DD/MM/YYYY when the date is ambiguous.
	 */
	public date function parseAmbiguousSlashDate(required numeric d1, required numeric d2, required numeric year) {
		return CreateDate(arguments.year, arguments.d2, arguments.d1);
	}

	// --- Readable Image Formats ---

	/**
	 * BoxLang's GetReadableImageFormats() returns an array, not a string.
	 */
	public string function getReadableImageFormatsString() {
		return ArrayToList(GetReadableImageFormats(), ", ");
	}

}
