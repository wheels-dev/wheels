/**
 * Tests for nested resource routes with callback syntax.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Nested Resources with Callback", function() {

			beforeEach(function(currentSpec) {
				m = new wheels.Mapper();
				m.$init();
				prepareMock(m);
			});

			afterEach(function(currentSpec) {
				structDelete(variables, "m");
				structDelete(variables, "r");
			});

			it("generates nested routes using callback function", function() {
				m.$draw()
					.resources(name="posts", callback=function(map) {
						map.resources("comments");
					})
				.end();
				r = m.getRoutes();

				// Should have routes for both posts and nested comments
				expect(r).toBeArray();

				// Check that nested comment routes contain the parent path segment
				local.hasNestedRoute = false;
				for (local.route in r) {
					if (FindNoCase("posts/[postKey]/comments", local.route.pattern)) {
						local.hasNestedRoute = true;
						break;
					}
				}
				expect(local.hasNestedRoute).toBeTrue();
			});

			it("generates correct parent routes alongside nested routes", function() {
				m.$draw()
					.resources(name="posts", callback=function(map) {
						map.resources("comments");
					})
				.end();
				r = m.getRoutes();

				// Should have post index route (pattern is normalized without optional-segment parens)
				local.hasPostIndex = false;
				for (local.route in r) {
					if (FindNoCase("posts", local.route.pattern) && !FindNoCase("comments", local.route.pattern) && StructKeyExists(local.route, "action") && local.route.action == "index") {
						local.hasPostIndex = true;
						break;
					}
				}
				expect(local.hasPostIndex).toBeTrue();
			});

			it("sets correct controller for nested resource", function() {
				m.$draw()
					.resources(name="posts", callback=function(map) {
						map.resources("comments");
					})
				.end();
				r = m.getRoutes();

				// Find a nested comment route and check its controller
				for (local.route in r) {
					if (FindNoCase("posts/[postKey]/comments", local.route.pattern) && StructKeyExists(local.route, "controller")) {
						expect(local.route.controller).toBe("comments");
						break;
					}
				}
			});

			it("generates named routes with parent prefix for nested resources", function() {
				m.$draw()
					.resources(name="posts", callback=function(map) {
						map.resources("comments");
					})
				.end();
				r = m.getRoutes();

				// Check for named route like postComments or postComment
				local.hasNamedRoute = false;
				for (local.route in r) {
					if (StructKeyExists(local.route, "name") && FindNoCase("postComment", local.route.name)) {
						local.hasNamedRoute = true;
						break;
					}
				}
				expect(local.hasNamedRoute).toBeTrue();
			});

			it("supports multiple nested resources in a single callback", function() {
				m.$draw()
					.resources(name="posts", callback=function(map) {
						map.resources("comments");
						map.resources("tags");
					})
				.end();
				r = m.getRoutes();

				// Should have routes for both comments and tags under posts
				local.hasComments = false;
				local.hasTags = false;
				for (local.route in r) {
					if (FindNoCase("posts/[postKey]/comments", local.route.pattern)) {
						local.hasComments = true;
					}
					if (FindNoCase("posts/[postKey]/tags", local.route.pattern)) {
						local.hasTags = true;
					}
				}
				expect(local.hasComments).toBeTrue();
				expect(local.hasTags).toBeTrue();
			});

			it("works with singular resource nesting", function() {
				m.$draw()
					.resources(name="users", callback=function(map) {
						map.resource("profile");
					})
				.end();
				r = m.getRoutes();

				// Should have nested profile routes under users
				local.hasNestedProfile = false;
				for (local.route in r) {
					if (FindNoCase("users/[userKey]/profile", local.route.pattern)) {
						local.hasNestedProfile = true;
						break;
					}
				}
				expect(local.hasNestedProfile).toBeTrue();
			});

			it("callback and nested=true manual approach produce equivalent routes", function() {
				// Callback approach
				m.$draw()
					.resources(name="posts", callback=function(map) {
						map.resources("comments");
					})
				.end();
				local.callbackRoutes = m.getRoutes();

				// Manual nested approach
				m2 = new wheels.Mapper();
				m2.$init();
				prepareMock(m2);
				m2.$draw()
					.resources(name="posts", nested=true)
						.resources("comments")
					.end()
				.end();
				local.manualRoutes = m2.getRoutes();

				// Both should produce the same number of routes
				expect(ArrayLen(local.callbackRoutes)).toBe(ArrayLen(local.manualRoutes));
			});

			it("supports only/except options on nested resources", function() {
				m.$draw()
					.resources(name="posts", callback=function(map) {
						map.resources(name="comments", only="index,create");
					})
				.end();
				r = m.getRoutes();

				// Should NOT have edit or delete routes for comments
				local.hasEditComment = false;
				for (local.route in r) {
					if (FindNoCase("comments", local.route.pattern) && StructKeyExists(local.route, "action") && local.route.action == "edit") {
						local.hasEditComment = true;
					}
				}
				expect(local.hasEditComment).toBeFalse();
			});

			it("supports namespace with nested callback resources", function() {
				m.$draw()
					.namespace(name="api")
						.resources(name="posts", callback=function(map) {
							map.resources("comments");
						})
					.end()
				.end();
				r = m.getRoutes();

				// Should have namespaced nested routes
				local.hasNamespacedNested = false;
				for (local.route in r) {
					if (FindNoCase("api/posts", local.route.pattern) && FindNoCase("comments", local.route.pattern)) {
						local.hasNamespacedNested = true;
						break;
					}
				}
				expect(local.hasNamespacedNested).toBeTrue();
			});

			it("raises error when combining callback with list of resources", function() {
				expect(function() {
					m.$draw()
						.resources(name="posts,articles", callback=function(map) {
							map.resources("comments");
						})
					.end();
				}).toThrow(type = "Wheels.InvalidResource");
			});
		});

		describe("Nested Resources backward compatibility", function() {

			beforeEach(function(currentSpec) {
				m = new wheels.Mapper();
				m.$init();
				prepareMock(m);
			});

			afterEach(function(currentSpec) {
				structDelete(variables, "m");
				structDelete(variables, "r");
			});

			it("nested=true without callback still works (manual end)", function() {
				m.$draw()
					.resources(name="posts", nested=true)
						.resources("comments")
					.end()
				.end();
				r = m.getRoutes();
				expect(r).toBeArray();

				local.hasNested = false;
				for (local.route in r) {
					if (FindNoCase("posts/[postKey]/comments", local.route.pattern)) {
						local.hasNested = true;
						break;
					}
				}
				expect(local.hasNested).toBeTrue();
			});

			it("non-nested resources still work normally", function() {
				m.$draw()
					.resources("posts")
					.resources("comments")
				.end();
				r = m.getRoutes();

				// Comments should NOT be nested under posts
				local.hasNested = false;
				for (local.route in r) {
					if (FindNoCase("posts/[postKey]/comments", local.route.pattern)) {
						local.hasNested = true;
					}
				}
				expect(local.hasNested).toBeFalse();
			});
		});
	}
}
