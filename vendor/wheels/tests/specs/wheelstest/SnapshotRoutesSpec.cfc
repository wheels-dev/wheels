/**
 * Self-test for the shared route snapshot/restore helpers on wheels.WheelsTest (#4194).
 * Invariant: snapshot -> mutate -> restore yields identical route state AND identical URLFor output.
 *
 * Global route state is protected here by independent (non-helper) Duplicate-based save/restore in
 * before/afterEach, so a broken helper under test cannot leak a corrupted table into later specs.
 */
component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo;

		describe("WheelsTest $snapshotRoutes / $restoreRoutes / $clearRoutes (4194)", () => {

			// Independent protection of the live route table (NOT via the helper under test).
			var orig = {};
			beforeEach(() => {
				orig.routes = Duplicate(application.wheels.routes);
				orig.staticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? Duplicate(application.wheels.staticRoutes) : {};
				orig.named = StructKeyExists(application.wheels, "namedRoutePositions") ? Duplicate(application.wheels.namedRoutePositions) : {};
				orig.rewrite = application.wheels.URLRewriting;
				// Named-route pattern differences only surface in the URL when rewriting is on.
				application.wheels.URLRewriting = "On";
			});
			afterEach(() => {
				application.wheels.routes = orig.routes;
				application.wheels.staticRoutes = orig.staticRoutes;
				application.wheels.namedRoutePositions = orig.named;
				application.wheels.URLRewriting = orig.rewrite;
			});

			it("round-trips route state and URLFor output across a mutation", () => {
				var c = g.controller(name = "dummy");

				// --- Table A: a named route 'foo' -> /foo/[key] ---
				$clearRoutes();
				g.mapper().$match(name = "foo", pattern = "foo/[key]", to = "x##y").root(to = "home##index", method = "get").end();
				g.$setNamedRoutePositions();
				var urlA = c.URLFor(route = "foo", key = 1);
				var routeCountA = ArrayLen(application.wheels.routes);

				// Snapshot table A.
				var snap = $snapshotRoutes();

				// --- Mutate to table B: same name 'foo' but a DIFFERENT pattern -> /bar/[key] ---
				$clearRoutes();
				g.mapper().$match(name = "foo", pattern = "bar/[key]", to = "x##y").root(to = "home##index", method = "get").end();
				g.$setNamedRoutePositions();
				var urlB = c.URLFor(route = "foo", key = 1);

				// The mutation must be observable (otherwise the round-trip proves nothing).
				expect(urlB).notToBe(urlA, "table B did not change URLFor output; test is not exercising a real mutation");

				// --- Restore table A ---
				$restoreRoutes(snap);
				var urlA2 = c.URLFor(route = "foo", key = 1);

				// Behavioural invariant: URLFor output is byte-identical to pre-mutation.
				expect(urlA2).toBe(urlA, "URLFor output not restored after $restoreRoutes");
				// Structural invariant: the route table is back to its snapshot shape.
				expect(ArrayLen(application.wheels.routes)).toBe(routeCountA, "route count not restored");
			});

			it("$restoreRoutes deletes a managed key that did not exist at snapshot time", () => {
				$clearRoutes();
				g.mapper().root(to = "home##index", method = "get").end();
				g.$setNamedRoutePositions();

				// Managed key used as the probe: dynamicRouteIndex (#4183). Ensure it is absent, snapshot,
				// then introduce it and confirm $restoreRoutes removes it (restoring the absent state).
				StructDelete(application.wheels, "dynamicRouteIndex");
				var snap = $snapshotRoutes();
				application.wheels.dynamicRouteIndex = {generation = 1, count = 0, signature = "x"};

				$restoreRoutes(snap);
				expect(StructKeyExists(application.wheels, "dynamicRouteIndex")).toBeFalse("$restoreRoutes left a managed key that was absent at snapshot time");
			});
		});
	}
}
