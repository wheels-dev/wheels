/**
 * Abstract base engine adapter with default implementations.
 * Concrete adapters (Lucee, Adobe, BoxLang) extend this and override
 * only the methods that differ for their engine.
 *
 * Defaults are Lucee-compatible since Lucee is the primary target engine.
 */
component output="false" {

	variables.engineName = "";
	variables.engineVersion = "";
	variables.engineMajorVersion = 0;

	public Base function init(required string version) {
		variables.engineVersion = arguments.version;
		variables.engineMajorVersion = Val(ListFirst(arguments.version, ".,"));
		return this;
	}

	// --- Identity ---

	public string function getName() {
		return variables.engineName;
	}

	public string function getVersion() {
		return variables.engineVersion;
	}

	public numeric function getMajorVersion() {
		return variables.engineMajorVersion;
	}

	/**
	 * Returns true if the current engine is BoxLang.
	 */
	public boolean function isBoxLang() {
		return false;
	}

	/**
	 * Returns true if the current engine is Lucee.
	 */
	public boolean function isLucee() {
		return false;
	}

	/**
	 * Returns true if the current engine is Adobe ColdFusion.
	 */
	public boolean function isAdobe() {
		return false;
	}

	// --- Response / PageContext ---

	/**
	 * Returns the engine-specific HTTP response object.
	 * Default: Lucee-style via GetPageContext().getResponse()
	 */
	public any function getResponse() {
		return GetPageContext().getResponse();
	}

	/**
	 * Returns the response writer for streaming output (SSE, etc).
	 */
	public any function getResponseWriter() {
		return getResponse().getWriter();
	}

	/**
	 * Returns the HTTP status code of the current response.
	 */
	public numeric function getStatusCode() {
		return getResponse().getStatus();
	}

	/**
	 * Returns the Content-Type header value of the current response.
	 */
	public string function getContentType() {
		local.rv = "";
		local.response = getResponse();
		if (local.response.containsHeader("Content-Type")) {
			local.header = local.response.getHeader("Content-Type");
			if (!IsNull(local.header)) {
				local.rv = local.header;
			}
		}
		return local.rv;
	}

	/**
	 * Returns the request timeout value in seconds.
	 * Default: Lucee-style via GetPageContext().getRequestTimeout() / 1000
	 */
	public numeric function getRequestTimeout() {
		return (GetPageContext().getRequestTimeout() / 1000);
	}

	// --- Form Handling ---

	/**
	 * Parses bracket-notation form keys like "user[address][city]" into
	 * an array of nested segments: ["address", "city"].
	 *
	 * @key The full form field key (e.g. "user[address][city]")
	 * @name The base name prefix (e.g. "user")
	 */
	public array function parseFormKey(required string key, required string name) {
		return ListToArray(ReplaceList(arguments.key, arguments.name & "[,]", ""), "[", true);
	}

	// --- Controller ---

	/**
	 * Converts a dot-delimited controller name to UpperCamelCase.
	 * E.g. "admin.user-settings" -> "admin.UserSettings"
	 *
	 * @name The controller name to convert
	 */
	public string function controllerNameToUpperCamelCase(required string name) {
		local.cName = ListLast(arguments.name, ".");
		local.cName = ReReplace(local.cName, "(^|-)([a-z])", "\u\2", "all");
		local.cLen = ListLen(arguments.name, ".");
		if (local.cLen) {
			return ListSetAt(arguments.name, local.cLen, local.cName, ".");
		}
		return arguments.name;
	}

	// --- Oracle JDBC Object Handling ---

	/**
	 * Coerces Oracle JDBC objects (TIMESTAMP, DATE) to CFML datetime values,
	 * and Oracle BLOB to binary data. Returns the value unchanged if it's not
	 * an Oracle JDBC object or if the engine doesn't need coercion.
	 *
	 * @value The value to check and potentially coerce
	 */
	public any function coerceOracleObject(required any value) {
		return arguments.value;
	}

	/**
	 * Returns true if the value is an Oracle JDBC object (TIMESTAMP, DATE)
	 * that should be treated as having content for validation purposes.
	 *
	 * @value The value to check
	 */
	public boolean function isOracleJdbcObject(required any value) {
		return false;
	}

	// --- Dynamic Finders ---

	/**
	 * Parses a dynamic finder method name (e.g. "findAllByTitleAndStatus")
	 * into an array of property names (e.g. ["Title", "Status"]).
	 * Lucee uppercases method names, so the Lucee adapter normalizes casing.
	 *
	 * @methodName The dynamic finder method name
	 * @prefix The prefix to strip ("findAllBy" or "findOneBy")
	 */
	public array function dynamicFinderProperties(required string methodName, required string prefix) {
		return ListToArray(
			ReplaceNoCase(
				Replace(arguments.methodName, "And", "|", "all"),
				arguments.prefix, "", "all"
			),
			"|"
		);
	}

	// --- Hash Normalization ---

	/**
	 * Normalizes a serialized JSON string for consistent cross-engine hashing.
	 * Removes structural characters and sorts the result.
	 *
	 * @serialized The serialized JSON string
	 */
	public string function normalizeForHash(required string serialized) {
		local.rv = ReplaceList(arguments.serialized, "{,},[,],/", ",,,,");
		return ListSort(local.rv, "text");
	}

	// --- Struct Defaults ---

	/**
	 * Appends default values from a source struct to a target struct,
	 * only for keys that don't already exist in the target.
	 *
	 * @target The struct to append defaults to
	 * @defaults The struct containing default values
	 */
	public void function structAppendDefaults(required struct target, required struct defaults) {
		StructAppend(arguments.target, arguments.defaults, false);
	}

	// --- Numeric Validation ---

	/**
	 * Returns true if the value is a valid number. Stricter than IsNumeric()
	 * on engines where locale-aware parsing accepts commas.
	 *
	 * @value The value to check
	 */
	public boolean function isNumericStrict(required any value) {
		return IsNumeric(arguments.value);
	}

	// --- DI Completion ---

	/**
	 * Prepares the variables scope for DI completion and mixin injection.
	 * BoxLang requires `variables.this = this` before mixin integration.
	 *
	 * @vars The variables scope of the component
	 * @thisScope The this scope of the component
	 */
	public void function prepareDIComplete(required struct vars, required any thisScope) {
		// Default: no-op. BoxLang overrides to set variables.this = this.
	}

	// --- Method Invocation ---

	/**
	 * Invokes a public method on an object by name.
	 * BoxLang requires extracting the method reference and calling directly;
	 * Lucee/Adobe use the invoke() BIF.
	 *
	 * @object The object containing the method
	 * @methodName The name of the method to invoke
	 */
	public void function invokeMethod(required any object, required string methodName) {
		invoke(object=arguments.object, method=arguments.methodName);
	}

	// --- Image Handling ---

	/**
	 * Gets image information for a given source file.
	 * BoxLang uses ImageRead+ImageInfo; Lucee/Adobe use cfimage action=info.
	 *
	 * @source The path to the image file
	 */
	public struct function imageInfo(required string source) {
		local.rv = {};
		local.args = {action: "info", source: arguments.source, structName: "rv"};
		cfimage(attributeCollection = local.args);
		return local.rv;
	}

	// --- Zip Handling ---

	/**
	 * Prepares zip arguments for the current engine.
	 * BoxLang requires absolute paths for file and destination.
	 *
	 * @args The arguments struct to prepare
	 */
	public struct function prepareZipArgs(required struct args) {
		return arguments.args;
	}

	// --- Glob Pattern Matching ---

	/**
	 * Returns the regex pattern for matching glob variables in route patterns.
	 * BoxLang uses *[varname] syntax; others use *varname.
	 */
	public string function globRegex() {
		return "\*([^\/]+)";
	}

	/**
	 * Extracts the variable name from a glob match.
	 *
	 * @glob The matched glob string (e.g., "*varname" or "*[varname]")
	 */
	public string function extractGlobVariable(required string glob) {
		return ReplaceList(arguments.glob, "*,[,]", "");
	}

	// --- Query Argument Mapping ---

	/**
	 * Returns the correct argument name for key column in cfquery.
	 * BoxLang uses "columnKey" instead of "keyColumn".
	 */
	public string function queryKeyColumnArgName() {
		return "keyColumn";
	}

	// --- Port Detection ---

	/**
	 * Returns the default HTTP port for the current engine.
	 */
	public numeric function getDefaultPort() {
		return 8500;
	}

	// --- Date Parsing ---

	/**
	 * Parses an ambiguous slash-format date string (e.g. "01/02/2024")
	 * into a consistent date. When the day/month are ambiguous (both <= 12),
	 * prefers MM/DD/YYYY on Lucee/Adobe and DD/MM/YYYY on BoxLang.
	 *
	 * @d1 The first number (before first slash)
	 * @d2 The second number (between slashes)
	 * @year The year
	 */
	public date function parseAmbiguousSlashDate(required numeric d1, required numeric d2, required numeric year) {
		// Default: MM/DD/YYYY (US format, Lucee/Adobe convention)
		return CreateDate(arguments.year, arguments.d1, arguments.d2);
	}

	// --- Readable Image Formats ---

	/**
	 * Returns readable image formats as a display string.
	 * BoxLang returns an array from GetReadableImageFormats(), so converts it.
	 */
	public string function getReadableImageFormatsString() {
		return GetReadableImageFormats();
	}

}
