component extends="wheels.WheelsTest" {

	function run() {
		describe("EventMethods request-header memoization (issue 2961 DC6)", () => {
			// $runOnRequestStart memoizes HTTP headers into request.$wheelsHeaders
			// (consumed by csrf.cfc and Dispatch.cfc). The guard used to check a
			// misspelled singular key ($wheelsHeader) that is never written, so the
			// memo never hit and GetHTTPRequestData() — which materializes the
			// request body — ran a second time per request even though
			// $initializeRequestScope() already stored the full result in
			// request.wheels.httpRequestData. These specs run inside the live test
			// request, so each one snapshots and restores the request-scope keys it
			// touches (request.$wheelsHeaders / request.wheels.httpRequestData are
			// live state consumed by the csrf specs later in the same request).

			it("preserves an already-memoized request.$wheelsHeaders", () => {
				var em = CreateObject("component", "wheels.events.EventMethods");
				var hadHeaders = StructKeyExists(request, "$wheelsHeaders");
				var priorHeaders = hadHeaders ? request.$wheelsHeaders : {};

				try {
					request.$wheelsHeaders = {"X-Memo-Sentinel" = "kept"};

					em.$initializeRequestHeaders();

					expect(StructKeyExists(request.$wheelsHeaders, "X-Memo-Sentinel")).toBeTrue(
						"an already-memoized request.$wheelsHeaders must not be overwritten"
					);
				} finally {
					if (hadHeaders) {
						request.$wheelsHeaders = priorHeaders;
					} else {
						StructDelete(request, "$wheelsHeaders");
					}
				}
			});

			it("reuses request.wheels.httpRequestData.headers instead of calling GetHTTPRequestData() again", () => {
				var em = CreateObject("component", "wheels.events.EventMethods");
				var hadHeaders = StructKeyExists(request, "$wheelsHeaders");
				var priorHeaders = hadHeaders ? request.$wheelsHeaders : {};
				var hadHttpData = StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "httpRequestData");
				var priorHttpData = hadHttpData ? request.wheels.httpRequestData : {};

				try {
					StructDelete(request, "$wheelsHeaders");

					// Overwriting this from the test suite is a documented seam,
					// see the comment in $initializeRequestScope() in Global.cfc.
					request.wheels.httpRequestData = {
						headers = {"X-From-Stored" = "yes"},
						content = "",
						method = "GET",
						protocol = "HTTP/1.1"
					};

					em.$initializeRequestHeaders();

					expect(StructKeyExists(request, "$wheelsHeaders")).toBeTrue(
						"the helper must populate request.$wheelsHeaders when it is absent"
					);
					expect(StructKeyExists(request.$wheelsHeaders, "X-From-Stored")).toBeTrue(
						"headers must come from the request.wheels.httpRequestData snapshot, not a fresh GetHTTPRequestData() call"
					);
				} finally {
					if (hadHttpData) {
						request.wheels.httpRequestData = priorHttpData;
					} else {
						StructDelete(request.wheels, "httpRequestData");
					}
					if (hadHeaders) {
						request.$wheelsHeaders = priorHeaders;
					} else {
						StructDelete(request, "$wheelsHeaders");
					}
				}
			});

			it("falls back to GetHTTPRequestData() when request.wheels.httpRequestData is absent", () => {
				var em = CreateObject("component", "wheels.events.EventMethods");
				var hadHeaders = StructKeyExists(request, "$wheelsHeaders");
				var priorHeaders = hadHeaders ? request.$wheelsHeaders : {};
				var hadHttpData = StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "httpRequestData");
				var priorHttpData = hadHttpData ? request.wheels.httpRequestData : {};

				try {
					StructDelete(request, "$wheelsHeaders");
					StructDelete(request.wheels, "httpRequestData");

					em.$initializeRequestHeaders();

					expect(StructKeyExists(request, "$wheelsHeaders")).toBeTrue(
						"the helper must fall back to GetHTTPRequestData() when the request-start snapshot is missing"
					);
					expect(IsStruct(request.$wheelsHeaders)).toBeTrue(
						"the fallback must still store a headers struct"
					);
				} finally {
					if (hadHttpData) {
						request.wheels.httpRequestData = priorHttpData;
					} else {
						StructDelete(request.wheels, "httpRequestData");
					}
					if (hadHeaders) {
						request.$wheelsHeaders = priorHeaders;
					} else {
						StructDelete(request, "$wheelsHeaders");
					}
				}
			});
		});
	}

}
