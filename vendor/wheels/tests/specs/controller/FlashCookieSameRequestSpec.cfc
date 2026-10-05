/**
 * Cookie flash storage, written and read in the same request (4433). The flash cookie
 * is set as an attribute struct; RustCFML reads such a cookie back in that request as
 * the struct, where Lucee, Adobe and BoxLang give its value. Over real HTTP, because
 * inside the test runner cookie flash goes through a request-scoped slot instead.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("cookie flash in the request that wrote it (4433)", () => {

			it("reads back the message flashInsert() just stored", () => {
				$testClient().get("/_flashcookie/insertread").assertOk().assertSee("notice=[saved]");
			});

		});

		describe("$flashCookieScopeValue", () => {

			beforeEach(() => {
				_controller = application.wo.controller("dummy", {});
			});

			it("returns a cookie read as a string unchanged", () => {
				expect(_controller.$flashCookieScopeValue('{"notice":"saved"}')).toBe('{"notice":"saved"}');
			});

			it("returns the value of a cookie read back as its attribute struct", () => {
				var assigned = {value = '{"notice":"saved"}', httpOnly = true, secure = false, path = "/"};
				expect(_controller.$flashCookieScopeValue(assigned)).toBe('{"notice":"saved"}');
			});

			it("reads a struct without a value, or a value that isn't simple, as no cookie", () => {
				expect(_controller.$flashCookieScopeValue({httpOnly = true})).toBe("");
				expect(_controller.$flashCookieScopeValue({value = {nested = true}})).toBe("");
				expect(_controller.$flashCookieScopeValue(["x"])).toBe("");
			});

		});

	}

}