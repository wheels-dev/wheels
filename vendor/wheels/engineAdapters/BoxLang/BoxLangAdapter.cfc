/**
 * Engine adapter for BoxLang.
 * BoxLang has significant differences in PageContext, form parsing,
 * and controller name handling compared to Lucee/Adobe CF.
 */
component extends="wheels.engineAdapters.Base" output="false" {

	variables.engineName = "BoxLang";

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

}
