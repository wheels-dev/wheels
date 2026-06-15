/**
 * Regression coverage for cross-engine null-pattern handling in $match().
 *
 * On BoxLang an unpassed optional `pattern` argument surfaces as a present-but-null
 * key (Lucee/Adobe treat it as absent), which skipped the name->pattern derivation
 * and left the route with a null/empty pattern. $match() now strips that present-null
 * key before the derivation so a named route gets the hyphenized name on every
 * engine — not an empty pattern (which would silently break URL matching and
 * linkTo()).
 *
 * The compat-matrix demo app routes are only `.wildcard().root()`, so the named
 * `to=` shape was previously unexercised on BoxLang; these specs run in the matrix
 * and assert the derived pattern value (not just "didn't throw") so an empty-pattern
 * regression fails rather than passes.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		_originalRoutes = Duplicate(application.wheels.routes);
		_originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? StructCopy(
			application.wheels.staticRoutes
		) : {};
	}

	function afterAll() {
		application.wheels.routes = _originalRoutes;
		application.wheels.staticRoutes = _originalStaticRoutes;
	}

	function run() {
		describe("named route given via to= with no explicit pattern", () => {

			beforeEach(() => {
				m = new wheels.Mapper();
				m.$init();
			});

			afterEach(() => {
				StructDelete(variables, "m");
			});

			it("derives the hyphenized name as the pattern (not empty)", () => {
				m.$draw().$match(name = "ping", method = "get", to = "main##ping").end();
				var r = m.getRoutes();
				expect(r[1].pattern).toBe("/ping");
				expect(r[1].name).toBe("ping");
				expect(r[1].controller).toBe("main");
				expect(r[1].action).toBe("ping");
			});

			it("builds a resources() route set with non-empty patterns", () => {
				m.$draw().resources(name = "posts", mapFormat = false).end();
				var routes = m.getRoutes();
				expect(ArrayLen(routes)).toBeGT(0);
				for (var route in routes) {
					expect(Len(route.pattern)).toBeGT(0);
				}
			});
		});
	}
}
