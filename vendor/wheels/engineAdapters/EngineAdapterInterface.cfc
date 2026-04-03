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

}
