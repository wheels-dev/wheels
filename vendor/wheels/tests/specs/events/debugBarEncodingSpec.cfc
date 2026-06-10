component extends="wheels.WheelsTest" {

	function run() {
		describe("debug.cfm output encoding", () => {
			// The dev debug bar reflects client-controlled request data (params.key,
			// param names, controller/action/route and the query string) into its
			// HTML. These must be HTML-encoded or any link a developer clicks becomes
			// reflected XSS on every dev page — and, via allowIPBasedDebugAccess,
			// in non-dev environments for allowlisted admins as well. Param VALUES
			// were already encoded; this locks in encoding for params.key and param
			// NAMES (the cgi.query_string site is fixed in the same way but cannot
			// be exercised here because the CGI scope is read-only in a spec).
			it("HTML-encodes params.key and param names in the debug bar", () => {
				var keyPayload = '"><script>alert(1)</script>';
				var namePayload = "<script>alert(2)</script>";
				var priorReqWheels = StructKeyExists(request, "wheels") ? Duplicate(request.wheels) : {};

				try {
					if (!StructKeyExists(request, "wheels")) {
						request.wheels = {};
					}
					request.wheels.execution = {total = 0};
					request.wheels.params = {controller = "wheels", action = "tests", route = ""};
					request.wheels.params.key = keyPayload;
					request.wheels.params[namePayload] = "benign-value";

					// debug.cfm bails out (cfexit) when url.format is one of
					// json/xml/csv/pdf so it never breaks an API response. The
					// test runner is hit with format=json — clear it for the
					// duration of the include so the template renders.
					var hadUrlFormat = StructKeyExists(url, "format");
					var priorUrlFormat = hadUrlFormat ? url.format : "";
					if (hadUrlFormat) {
						StructDelete(url, "format");
					}

					var output = "";
					try {
						output = application.wo.$includeAndReturnOutput($template = "/wheels/events/onrequestend/debug.cfm");
					} finally {
						if (hadUrlFormat) {
							url.format = priorUrlFormat;
						}
					}

					expect(output contains "<script>alert(1)").toBeFalse(
						"params.key must be HTML-encoded in the debug bar Request panel"
					);
					expect(output contains "<script>alert(2)").toBeFalse(
						"param names must be HTML-encoded in the debug bar Params panel"
					);
					expect(output contains "&lt;script&gt;").toBeTrue(
						"the injected payloads should still be visible in HTML-encoded form"
					);
				} finally {
					request.wheels = priorReqWheels;
				}
			});
		});
	}

}
