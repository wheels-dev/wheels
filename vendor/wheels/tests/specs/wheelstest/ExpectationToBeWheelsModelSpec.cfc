/**
 * Covers the cross-engine-portable instance check used by Wheels test specs.
 *
 * Background: `toBeInstanceOf("component")` passes on Lucee/Adobe (where
 * `getMetadata().type` returns the literal string "component") but fails on
 * BoxLang (where the FQN is returned, so `IsInstanceOf(x, "component")` is
 * false). The portable equivalent is to assert against the framework base
 * class (`Model`/`Controller`), since `IsInstanceOf` walks the inheritance
 * chain on every engine. `toBeWheelsModel()` codifies that for model objects
 * so future test authors do not re-introduce the BoxLang break.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("toBeWheelsModel", () => {

			it("accepts any Wheels model instance regardless of engine class reflection", () => {
				var record = application.wo.model("author").new();
				expect(record).toBeWheelsModel();
			});

			it("accepts subclassed model instances via inheritance walk", () => {
				var record = application.wo.model("bulkItem").new();
				expect(record).toBeWheelsModel();
			});

			it("rejects plain structs", () => {
				var ctx = {fake: {firstName: "Not", lastName: "AModel"}};
				expect(() => {
					expect(ctx.fake).toBeWheelsModel();
				}).toThrow();
			});

			it("rejects non-Model CFC instances", () => {
				var ctx = {nonModel: new wheels.wheelstest.system.Assertion()};
				expect(() => {
					expect(ctx.nonModel).toBeWheelsModel();
				}).toThrow();
			});

		});

	}

}
