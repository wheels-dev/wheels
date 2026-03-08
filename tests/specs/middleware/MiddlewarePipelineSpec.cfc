component extends="wheels.WheelsTest" {

	function run() {

		describe("Middleware Pipeline", function() {

			describe("Pipeline.init()", function() {

				it("creates an empty pipeline with no middleware", function() {
					var pipeline = new wheels.middleware.Pipeline();
					expect(pipeline.getMiddleware()).toBeArray();
					expect(ArrayLen(pipeline.getMiddleware())).toBe(0);
				});

				it("accepts an array of middleware instances", function() {
					var mw = new wheels.middleware.RequestId();
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
					expect(ArrayLen(pipeline.getMiddleware())).toBe(1);
				});

			});

			describe("Pipeline.run()", function() {

				it("calls the core handler when no middleware is registered", function() {
					var pipeline = new wheels.middleware.Pipeline();
					var shared = {called = false};
					var handler = function(required struct request) {
						shared.called = true;
						return "core response";
					};
					var result = pipeline.run(request = {}, coreHandler = handler);
					expect(result).toBe("core response");
					expect(shared.called).toBeTrue();
				});

				it("passes request through a single middleware to core handler", function() {
					var shared = {order = []};
					var mw = new tests.specs.middleware._helpers.TrackingMiddleware(id = "A", tracker = shared);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
					var handler = function(required struct request) {
						ArrayAppend(shared.order, "core");
						return "done";
					};
					var result = pipeline.run(request = {}, coreHandler = handler);
					expect(shared.order[1]).toBe("before:A");
					expect(shared.order[2]).toBe("core");
					expect(shared.order[3]).toBe("after:A");
					expect(result).toBe("done");
				});

				it("executes multiple middleware in correct order", function() {
					var shared = {order = []};
					var mwA = new tests.specs.middleware._helpers.TrackingMiddleware(id = "A", tracker = shared);
					var mwB = new tests.specs.middleware._helpers.TrackingMiddleware(id = "B", tracker = shared);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mwA, mwB]);
					var handler = function(required struct request) {
						ArrayAppend(shared.order, "core");
						return "done";
					};
					pipeline.run(request = {}, coreHandler = handler);
					// A wraps B wraps core: before:A, before:B, core, after:B, after:A
					expect(shared.order[1]).toBe("before:A");
					expect(shared.order[2]).toBe("before:B");
					expect(shared.order[3]).toBe("core");
					expect(shared.order[4]).toBe("after:B");
					expect(shared.order[5]).toBe("after:A");
				});

				it("allows middleware to short-circuit the pipeline", function() {
					var shared = {order = []};
					var blocker = new tests.specs.middleware._helpers.BlockingMiddleware(tracker = shared);
					var mwB = new tests.specs.middleware._helpers.TrackingMiddleware(id = "B", tracker = shared);
					var pipeline = new wheels.middleware.Pipeline(middleware = [blocker, mwB]);
					var handler = function(required struct request) {
						ArrayAppend(shared.order, "core");
						return "should not reach";
					};
					var result = pipeline.run(request = {}, coreHandler = handler);
					expect(result).toBe("blocked");
					expect(ArrayLen(shared.order)).toBe(1);
					expect(shared.order[1]).toBe("blocked");
				});

				it("passes request data through the middleware chain", function() {
					var enricher = new tests.specs.middleware._helpers.EnrichingMiddleware();
					var pipeline = new wheels.middleware.Pipeline(middleware = [enricher]);
					var shared = {capturedRequest = {}};
					var handler = function(required struct request) {
						shared.capturedRequest = arguments.request;
						return "done";
					};
					pipeline.run(request = {}, coreHandler = handler);
					expect(StructKeyExists(shared.capturedRequest, "enriched")).toBeTrue();
					expect(shared.capturedRequest.enriched).toBeTrue();
				});

			});

			describe("Built-in Middleware", function() {

				it("RequestId sets request.wheels.requestId", function() {
					var mw = new wheels.middleware.RequestId();
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
					var handler = function(required struct request) {
						return "ok";
					};
					pipeline.run(request = {}, coreHandler = handler);
					expect(StructKeyExists(request.wheels, "requestId")).toBeTrue();
					expect(Len(request.wheels.requestId)).toBeGT(0);
				});

				it("SecurityHeaders can be instantiated with defaults", function() {
					var mw = new wheels.middleware.SecurityHeaders();
					expect(mw).toBeInstanceOf("wheels.middleware.SecurityHeaders");
				});

				it("SecurityHeaders can be instantiated with custom options", function() {
					var mw = new wheels.middleware.SecurityHeaders(
						frameOptions = "DENY",
						referrerPolicy = "no-referrer"
					);
					expect(mw).toBeInstanceOf("wheels.middleware.SecurityHeaders");
				});

				it("Cors can be instantiated with defaults", function() {
					var mw = new wheels.middleware.Cors();
					expect(mw).toBeInstanceOf("wheels.middleware.Cors");
				});

				it("Cors can be instantiated with custom origins", function() {
					var mw = new wheels.middleware.Cors(
						allowOrigins = "https://example.com,https://app.example.com",
						allowCredentials = true
					);
					expect(mw).toBeInstanceOf("wheels.middleware.Cors");
				});

			});

		});

	}

}
