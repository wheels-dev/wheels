/**
 * Records every call; returns canned responses keyed by URL. Use seed()
 * to pre-populate responses. Unseeded URLs return 404 with an empty body
 * so tests fail fast on typos.
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
		ArrayAppend(variables.calls, {url: arguments.url, headers: arguments.headers});
		if (StructKeyExists(variables.responses, arguments.url)) {
			return variables.responses[arguments.url];
		}
		return {status: 404, body: ""};
	}

	public string function download(required string url, required string destPath) {
		ArrayAppend(variables.calls, {url: arguments.url, destPath: arguments.destPath, download: true});
		if (StructKeyExists(variables.responses, arguments.url)) {
			local.resp = variables.responses[arguments.url];
			if (local.resp.status == 200) {
				FileWrite(arguments.destPath, local.resp.body ?: "");
				return arguments.destPath;
			}
		}
		Throw(type = "Wheels.Packages.DownloadFailed", message = "Fake: no seeded response for #arguments.url#");
	}

	public array function calls() { return variables.calls; }
}
