/**
 * Thin HTTP GET wrapper. Exists so Registry can be tested offline with
 * a fake that returns canned responses keyed by URL.
 *
 * Uses cfhttp (script syntax) for cross-engine portability — `new http()`
 * is Lucee-specific and the framework test matrix also runs these specs
 * against Adobe CF.
 *
 * Mirrors cli/lucli/services/packages/HttpClient.cfc. The CLI keeps its
 * own copy because it runs in a LuCLI module context with different path
 * mappings. Keep both copies in sync when changing fetch behavior.
 */
component {

	public HttpClient function init(numeric timeoutSeconds = 30) {
		variables.timeout = arguments.timeoutSeconds;
		return this;
	}

	/**
	 * @return struct { status: numeric, body: string }
	 */
	public struct function get(required string url, struct headers = {}) {
		cfhttp(url = arguments.url, method = "GET", timeout = variables.timeout, result = "local.result") {
			for (local.name in arguments.headers) {
				cfhttpparam(type = "header", name = local.name, value = arguments.headers[local.name]);
			}
			// GitHub's API prefers an explicit User-Agent on unauth requests.
			cfhttpparam(type = "header", name = "User-Agent", value = "wheels-framework");
		}
		return {status = Val(ListFirst(local.result.statusCode, " ")), body = local.result.fileContent ?: ""};
	}

}
