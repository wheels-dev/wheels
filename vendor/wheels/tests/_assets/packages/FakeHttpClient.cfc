/**
 * Records every call; returns canned responses keyed by URL. Use seed()
 * to pre-populate responses. Unseeded URLs return 404 with an empty body
 * so tests fail fast on typos.
 *
 * Mirrors cli/lucli/tests/specs/packages/_stubs/FakeHttpClient.cfc but
 * trimmed to the framework HttpClient surface (no download()).
 */
component {

	public FakeHttpClient function init() {
		variables.responses = {};
		variables.calls = [];
		return this;
	}

	public void function seed(required string url, required struct response) {
		variables.responses[arguments.url] = arguments.response;
	}

	public struct function get(required string url, struct headers = {}) {
		ArrayAppend(variables.calls, {url = arguments.url, headers = arguments.headers});
		if (StructKeyExists(variables.responses, arguments.url)) {
			return variables.responses[arguments.url];
		}
		return {status = 404, body = ""};
	}

	public array function calls() {
		return variables.calls;
	}

}
