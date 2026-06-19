component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Route Model Binding", function() {

			beforeEach(function() {
				// Store original setting so we can restore it.
				_originalBinding = g.$get("routeModelBinding");
				// Default to off for isolation.
				g.$set(routeModelBinding = false);

				// Get the Dispatch object via the DI container.
				_dispatch = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
			});

			afterEach(function() {
				g.$set(routeModelBinding = _originalBinding);
				// Clean up any negative-cache entries created by these tests so other
				// specs (and re-runs) are unaffected.
				var appKey = g.$appKey();
				if (StructKeyExists(application[appKey], "unresolvableRouteBindings")) {
					StructDelete(application[appKey].unresolvableRouteBindings, "Post");
					StructDelete(application[appKey].unresolvableRouteBindings, "NonexistentThing");
					StructDelete(application[appKey].unresolvableRouteBindings, "NonexistentWidget");
				}
			});

			describe("when binding is enabled on a route", function() {

				it("resolves a model instance into params", function() {
					// Find an existing post to use as test data.
					var post = g.model("Post").findOne(order="id");
					if (IsBoolean(post) && !post) {
						// Skip if no test data — create one.
						post = g.model("Post").create(
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
					g.$set(routeModelBinding = true);

					var params = {controller = "posts", action = "show", key = "1"};
					var route = {binding = false};

					var result = _dispatch.$resolveRouteModelBinding(params = params, route = route);

					expect(result).notToHaveKey("post");
				});

			});

			describe("with explicit model name", function() {

				it("uses the specified model name instead of deriving from controller", function() {
					var author = g.model("Author").findOne(order="id");
					if (IsBoolean(author) && !author) {
						author = g.model("Author").create(firstName = "Test", lastName = "Author");
					}

					var params = {controller = "writers", action = "show", key = author.key()};
					var route = {binding = "Author"};

					var result = _dispatch.$resolveRouteModelBinding(params = params, route = route);

					expect(result).toHaveKey("author");
					expect(result.author.key()).toBe(author.key());
				});

				it("throws when the explicitly named model cannot be resolved", function() {
					var params = {controller = "writers", action = "show", key = "1"};
					var route = {binding = "TotallyMissingBindingModel"};

					expect(function() {
						_dispatch.$resolveRouteModelBinding(params = params, route = route);
					}).toThrow();
				});

			});

			describe("controller resolution", function() {

				it("derives model from route.controller when params.controller is not set", function() {
					var post = g.model("Post").findOne(order="id");
					if (IsBoolean(post) && !post) {
						post = g.model("Post").create(
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

				it("negative-caches a conventional binding miss so the bootstrap is not repeated", function() {
					var appKey = g.$appKey();
					// Start clean in case a previous run already cached this miss.
					if (StructKeyExists(application[appKey], "unresolvableRouteBindings")) {
						StructDelete(application[appKey].unresolvableRouteBindings, "NonexistentWidget");
					}

					var params = {controller = "nonexistentWidgets", action = "show", key = "1"};
					var route = {binding = true};

					var result = _dispatch.$resolveRouteModelBinding(params = params, route = route);

					expect(result).notToHaveKey("nonexistentWidget");
					expect(application[appKey]).toHaveKey("unresolvableRouteBindings");
					expect(application[appKey].unresolvableRouteBindings).toHaveKey("NonexistentWidget");
				});

				it("skips resolution for models present in the negative cache", function() {
					var appKey = g.$appKey();
					if (!StructKeyExists(application[appKey], "unresolvableRouteBindings")) {
						application[appKey].unresolvableRouteBindings = {};
					}
					application[appKey].unresolvableRouteBindings["Post"] = true;

					var params = {controller = "posts", action = "show", key = "1"};
					var route = {binding = true};

					var result = _dispatch.$resolveRouteModelBinding(params = params, route = route);

					expect(result).notToHaveKey("post");
				});

				it("resolves models when global setting is enabled and no per-route binding", function() {
					g.$set(routeModelBinding = true);

					var post = g.model("Post").findOne(order="id");
					if (IsBoolean(post) && !post) {
						post = g.model("Post").create(
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
					var appKey = g.$appKey();
					var mapper = application[appKey].mapper;
					var originalRoutes = Duplicate(application[appKey].routes);

					// Clear routes and add a test resource with binding.
					application[appKey].routes = [];
					mapper.$draw(restful = true, methods = true);
						mapper.resources(name = "posts", binding = true);
					mapper.end();

					var routes = application[appKey].routes;

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
					application[appKey].routes = originalRoutes;
				});

			});

		});

	}

}
