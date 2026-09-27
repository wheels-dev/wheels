/**
 * $initializeRequestScope() must initialize each request.wheels key that is
 * missing, even when request.wheels already exists (#3726).
 *
 * On Adobe CF 2025 the engine raises an error during application startup, and
 * the app's onError sets request.wheels.exception/eventName before the request
 * is initialized. The old all-or-nothing guard then skipped every key, and
 * Dispatch failed with "Element WHEELS.HTTPREQUESTDATA.HEADERS is undefined".
 *
 * These specs run inside the live test request, so each one saves and restores
 * request.wheels.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("$initializeRequestScope (##3726)", () => {

			it("fills in every key when onError has already created request.wheels", () => {
				var saved = request.wheels;
				// Hoisted: a bare zero-arg call through application.wo in a closure
				// fails to compile on Adobe 2025 (CLAUDE.md invariant 16b).
				var wo = application.wo;
				try {
					request.wheels = {exception = {message = "engine startup notice"}, eventName = "onApplicationStart"};

					wo.$initializeRequestScope();

					expect(request.wheels).toHaveKey("httpRequestData");
					expect(request.wheels.httpRequestData).toHaveKey("headers");
					expect(request.wheels).toHaveKey("params");
					expect(request.wheels).toHaveKey("cache");
					expect(request.wheels).toHaveKey("urlForCache");
					expect(request.wheels).toHaveKey("tickCountId");
					expect(request.wheels).toHaveKey("transactions");
					// What onError recorded is kept, not overwritten.
					expect(request.wheels.exception.message).toBe("engine startup notice");
					expect(request.wheels.eventName).toBe("onApplicationStart");
				} finally {
					request.wheels = saved;
				}
			});

			it("fills in the keys when a helper created an empty request.wheels", () => {
				var saved = request.wheels;
				// Hoisted: a bare zero-arg call through application.wo in a closure
				// fails to compile on Adobe 2025 (CLAUDE.md invariant 16b).
				var wo = application.wo;
				try {
					request.wheels = {};

					wo.$initializeRequestScope();

					expect(request.wheels).toHaveKey("httpRequestData");
					expect(request.wheels).toHaveKey("params");
					expect(request.wheels).toHaveKey("transactions");
				} finally {
					request.wheels = saved;
				}
			});

			it("keeps keys that are already initialized", () => {
				var saved = request.wheels;
				// Hoisted: a bare zero-arg call through application.wo in a closure
				// fails to compile on Adobe 2025 (CLAUDE.md invariant 16b).
				var wo = application.wo;
				try {
					request.wheels = {
						params = {sentinel = "kept"},
						httpRequestData = {headers = {"X-Sentinel" = "kept"}, content = "", method = "GET", protocol = "HTTP/1.1"}
					};

					wo.$initializeRequestScope();

					expect(request.wheels.params.sentinel).toBe("kept");
					expect(request.wheels.httpRequestData.headers["X-Sentinel"]).toBe("kept");
					expect(request.wheels).toHaveKey("cache");
				} finally {
					request.wheels = saved;
				}
			});

			it("creates request.wheels when it is absent", () => {
				var saved = request.wheels;
				// Hoisted: a bare zero-arg call through application.wo in a closure
				// fails to compile on Adobe 2025 (CLAUDE.md invariant 16b).
				var wo = application.wo;
				try {
					StructDelete(request, "wheels");

					wo.$initializeRequestScope();

					expect(request).toHaveKey("wheels");
					expect(request.wheels).toHaveKey("httpRequestData");
					expect(request.wheels).toHaveKey("params");
				} finally {
					request.wheels = saved;
				}
			});

		});

	}

}
