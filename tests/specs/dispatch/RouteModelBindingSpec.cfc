component extends="wheels.WheelsTest" {

	function run() {

		describe("Route Model Binding", function() {

			beforeEach(function() {
				// Store original setting so we can restore it.
				_originalBinding = application.$wheels.routeModelBinding;
				// Default to off for isolation.
				application.$wheels.routeModelBinding = false;

				// Get a reference to the Dispatch object for calling internal methods.
				_dispatch = application.wheels.dispatch;
			});

			afterEach(function() {
				application.$wheels.routeModelBinding = _originalBinding;
			});

			describe("when binding is enabled on a route", function() {

				it("resolves a model instance into params", function() {
					// Find an existing post to use as test data.
					var post = model("Post").findOne(order="id");
					if (IsBoolean(post) && !post) {
						// Skip if no test data — create one.
						post = model("Post").create(
							authorId = 1,
							title = "Binding Test",
							body = "Test body",
							views = 0
						);
					}

					var params = {controller = "posts", action = "show", key = post.key()};
					var route = {binding = true};

					var result = _dispatch.$resolveRouteModelBinding(params = params, route = route);

					expect(result).toHaveKey("post");
					expect(result.post.key()).toBe(post.key());
					// Original key param should be preserved.
					expect(result.key).toBe(post.key());
				});

				it("throws RecordNotFound when record does not exist", function() {
					var params = {controller = "posts", action = "show", key = "999999"};
					var route = {binding = true};

					expect(function() {
						_dispatch.$resolveRouteModelBinding(params = params, route = route);
					}).toThrow("Wheels.RecordNotFound");
				});

			});

			describe("when binding is disabled", function() {

				it("does not resolve models when disabled by default", function() {
					var params = {controller = "posts", action = "show", key = "1"};
					var route = {};

					var result = _dispatch.$resolveRouteModelBinding(params = params, route = route);

					expect(result).notToHaveKey("post");
				});

				it("does not resolve models when per-route binding is false even if global is true", function() {
					application.$wheels.routeModelBinding = true;

					var params = {controller = "posts", action = "show", key = "1"};
					var route = {binding = false};

					var result = _dispatch.$resolveRouteModelBinding(params = params, route = route);

					expect(result).notToHaveKey("post");
				});

			});

			describe("with explicit model name", function() {

				it("uses the specified model name instead of deriving from controller", function() {
					var author = model("Author").findOne(order="id");
					if (IsBoolean(author) && !author) {
						author = model("Author").create(firstName = "Test", lastName = "Author");
					}

					var params = {controller = "writers", action = "show", key = author.key()};
					var route = {binding = "Author"};

					var result = _dispatch.$resolveRouteModelBinding(params = params, route = route);

					expect(result).toHaveKey("author");
					expect(result.author.key()).toBe(author.key());
				});

			});

			describe("controller resolution", function() {

				it("derives model from route.controller when params.controller is not set", function() {
					var post = model("Post").findOne(order="id");
					if (IsBoolean(post) && !post) {
						post = model("Post").create(
							authorId = 1,
							title = "Route Controller Test",
							body = "Test body",
							views = 0
						);
					}

					// Simulates a resource route where controller is on the route struct, not in params.
					var params = {key = post.key()};
					var route = {binding = true, controller = "posts"};

					var result = _dispatch.$resolveRouteModelBinding(params = params, route = route);

					expect(result).toHaveKey("post");
					expect(result.post.key()).toBe(post.key());
				});

			});

			describe("edge cases", function() {

				it("skips binding when no key param is present", function() {
					var params = {controller = "posts", action = "index"};
					var route = {binding = true};

					var result = _dispatch.$resolveRouteModelBinding(params = params, route = route);

					expect(result).notToHaveKey("post");
				});

				it("skips silently when model class does not exist", function() {
					var params = {controller = "nonexistentThings", action = "show", key = "1"};
					var route = {binding = true};

					var result = _dispatch.$resolveRouteModelBinding(params = params, route = route);

					expect(result).notToHaveKey("nonexistentThing");
				});

				it("resolves models when global setting is enabled and no per-route binding", function() {
					application.$wheels.routeModelBinding = true;

					var post = model("Post").findOne(order="id");
					if (IsBoolean(post) && !post) {
						post = model("Post").create(
							authorId = 1,
							title = "Global Binding Test",
							body = "Test body",
							views = 0
						);
					}

					var params = {controller = "posts", action = "show", key = post.key()};
					var route = {};

					var result = _dispatch.$resolveRouteModelBinding(params = params, route = route);

					expect(result).toHaveKey("post");
					expect(result.post.key()).toBe(post.key());
				});

			});

			describe("route-level integration", function() {

				it("produces routes with binding property when binding=true on resources", function() {
					// Create a temporary mapper to test route generation.
					var testRoutes = [];
					var mapper = application.wheels.mapper;
					var originalRoutes = Duplicate(application.wheels.routes);

					// Clear routes and add a test resource with binding.
					application.wheels.routes = [];
					mapper.draw(restful = true, methods = true);
						mapper.resources(name = "posts", binding = true);
					mapper.end();

					var routes = application.wheels.routes;

					// Check that the show route has binding property.
					var showRoute = {};
					for (var route in routes) {
						if (StructKeyExists(route, "action") && route.action == "show") {
							showRoute = route;
							break;
						}
					}

					expect(showRoute).toHaveKey("binding");
					expect(showRoute.binding).toBeTrue();

					// Restore original routes.
					application.wheels.routes = originalRoutes;
				});

			});

		});

	}

}
