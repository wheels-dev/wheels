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

}
