/**
 * Regression test for #3114: running the legacy global CORS path
 * (`set(allowCorsRequests=true)`) alongside a `wheels.middleware.Cors`
 * instance stacks duplicate Access-Control-Allow-* headers. A duplicate
 * `Access-Control-Allow-Origin` makes browsers reject the response per the
 * Fetch spec.
 *
 * The fix makes the global `onRequestStart` emitter step aside when a Cors
 * middleware is registered, leaving the dispatch-level middleware as the
 * single source of truth. `$corsMiddlewareActive()` is the arbitration
 * signal the global path consults.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Global CORS arbitration with wheels.middleware.Cors (#3114)", () => {

			beforeEach(() => {
				_savedMiddleware = StructKeyExists(application.wheels, "middleware")
					? Duplicate(application.wheels.middleware) : [];
			});

			afterEach(() => {
				application.wheels.middleware = _savedMiddleware;
			});

			it("reports a registered Cors middleware instance as active", () => {
				application.wheels.middleware = [
					new wheels.middleware.Cors(allowOrigins = "https://app.example")
				];
				expect(application.wo.$corsMiddlewareActive()).toBeTrue();
			});

			it("reports a registered Cors middleware string path as active", () => {
				application.wheels.middleware = ["wheels.middleware.Cors"];
				expect(application.wo.$corsMiddlewareActive()).toBeTrue();
			});

			it("reports inactive when no middleware is registered", () => {
				application.wheels.middleware = [];
				expect(application.wo.$corsMiddlewareActive()).toBeFalse();
			});

			it("reports inactive when only non-Cors middleware is registered", () => {
				application.wheels.middleware = ["wheels.middleware.SecurityHeaders"];
				expect(application.wo.$corsMiddlewareActive()).toBeFalse();
			});

		});

	}

}
