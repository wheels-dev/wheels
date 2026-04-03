/**
 * Interface contract for engine adapters.
 * Each CFML engine (Lucee, Adobe CF, BoxLang) implements this contract
 * to provide consistent cross-engine behavior.
 *
 * NOTE: Using documented convention rather than CFML `interface` keyword
 * to avoid cross-engine interface compilation issues. Base.cfc serves
 * as the enforceable contract — all concrete adapters extend it.
 */
interface {

	// --- Identity ---
	public string function getName();
	public string function getVersion();
	public numeric function getMajorVersion();
	public boolean function isBoxLang();
	public boolean function isLucee();
	public boolean function isAdobe();

	// --- Response / PageContext ---
	public any function getResponse();
	public any function getResponseWriter();
	public numeric function getStatusCode();
	public string function getContentType();
	public numeric function getRequestTimeout();

	// --- Form Handling ---
	public array function parseFormKey(required string key, required string name);

	// --- Controller ---
	public string function controllerNameToUpperCamelCase(required string name);

	// --- Oracle JDBC Object Handling ---
	public any function coerceOracleObject(required any value);
	public boolean function isOracleJdbcObject(required any value);

	// --- Dynamic Finders ---
	public array function dynamicFinderProperties(required string methodName, required string prefix);

	// --- Hash Normalization ---
	public string function normalizeForHash(required string serialized);

	// --- Struct Defaults ---
	public void function structAppendDefaults(required struct target, required struct defaults);

	// --- Numeric Validation ---
	public boolean function isNumericStrict(required any value);

	// --- DI Completion ---
	public void function prepareDIComplete(required struct vars, required any thisScope);

	// --- Method Invocation ---
	public void function invokeMethod(required any object, required string methodName);

	// --- Image Handling ---
	public struct function imageInfo(required string source);

	// --- Zip Handling ---
	public struct function prepareZipArgs(required struct args);

	// --- Glob Pattern Matching ---
	public string function globRegex();
	public string function extractGlobVariable(required string glob);

	// --- Query Argument Mapping ---
	public string function queryKeyColumnArgName();

	// --- Port Detection ---
	public numeric function getDefaultPort();

	// --- Date Parsing ---
	public date function parseAmbiguousSlashDate(required numeric d1, required numeric d2, required numeric year);

	// --- Readable Image Formats ---
	public string function getReadableImageFormatsString();

}
