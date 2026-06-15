/**
 * Regression coverage for cross-engine null-pattern handling in $match().
 *
 * $match() derives `pattern` from `name`, and some name/resource forms leave the
 * derived `pattern` null at the point where it is manipulated (Find / ReFindNoCase
 * / concatenation). Lucee and Adobe coerce a null string subject to "", but
 * BoxLang throws a NullPointerException — so a named route given via `to=` (no
 * explicit pattern) failed to load on BoxLang. matching.cfc now normalizes a null
 * pattern to "" so route building behaves identically on every engine.
 *
 * The compat-matrix demo app routes are only `.wildcard().root()`, so these
 * shapes were previously unexercised on BoxLang; these specs run in the matrix
 * and guard the regression.
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
		describe("route building with a name-derived (null-equivalent) pattern", () => {

			beforeEach(() => {
				m = new wheels.Mapper();
				m.$init();
			});

			afterEach(() => {
				StructDelete(variables, "m");
			});

			it("builds a named route given via to= without an explicit pattern", () => {
				var state = {thrown = false};
				try {
					m.$draw().get(name = "ping", to = "main##ping").end();
				} catch (any e) {
					state.thrown = true;
				}
				expect(state.thrown).toBeFalse();
				expect(ArrayLen(m.getRoutes())).toBeGT(0);
			});

			it("builds a resources() route set without an explicit pattern", () => {
				var state = {thrown = false};
				try {
					m.$draw().resources(name = "posts", mapFormat = false).end();
				} catch (any e) {
					state.thrown = true;
				}
				expect(state.thrown).toBeFalse();
				expect(ArrayLen(m.getRoutes())).toBeGT(0);
			});
		});
	}
}
