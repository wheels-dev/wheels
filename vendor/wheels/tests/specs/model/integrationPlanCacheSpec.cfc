/**
 * Guard for the mixin-integration cache (issue #3213).
 *
 * Model objects are materialized constantly — every `new()` and every finder
 * row goes through $createInstance -> init() -> $integrateComponents. That used
 * to re-scan vendor/wheels/model/, re-createObject every sub-component, and
 * re-getMetaData on each, on EVERY instance. The plan is now built once per app
 * (Global.cfc::$componentIntegrationPlan, cached in
 * application.wheels.integrationPlans) and replayed cheaply.
 *
 * These specs pin the behavior the optimization must preserve: the cache is
 * populated and reused, and every materialized instance still carries the full,
 * working set of mixed-in model methods.
 */
component extends="wheels.WheelsTest" {

	function run() {
		describe("mixin-integration plan cache (##3213)", () => {

			it("populates the per-app integration-plan cache for wheels.model", () => {
				// Materializing any model triggers $integrateComponents("wheels.model").
				model("author").new();
				expect(StructKeyExists(application.wheels, "integrationPlans")).toBeTrue();
				expect(StructKeyExists(application.wheels.integrationPlans, "wheels.model")).toBeTrue();

				var plan = application.wheels.integrationPlans["wheels.model"];
				expect(IsArray(plan)).toBeTrue();
				expect(ArrayLen(plan)).toBeGT(0);
				// Each entry carries the pre-resolved public methods used on the hot path.
				expect(StructKeyExists(plan[1], "publicMethods")).toBeTrue();
				expect(IsArray(plan[1].publicMethods)).toBeTrue();
			});

			it("reuses the same cached plan across instances rather than rebuilding it", () => {
				model("author").new();
				var first = application.wheels.integrationPlans["wheels.model"];
				// A second materialization must not replace the cached plan.
				model("author").new();
				var second = application.wheels.integrationPlans["wheels.model"];
				// Same identity (Lucee/Adobe compare arrays by reference here): a
				// rebuild would produce a different array with fresh instances.
				expect(first.equals(second)).toBeTrue();
			});

			it("materializes instances that carry the full mixed-in model method surface", () => {
				var a = model("author").new();
				// A representative spread across the model sub-components
				// (create/read/update/delete/validations/errors/properties).
				for (var fn in ["save", "update", "delete", "valid", "hasErrors", "isNew", "reload", "key", "properties"]) {
					expect(StructKeyExists(a, fn)).toBeTrue();
					expect(IsCustomFunction(a[fn])).toBeTrue();
				}
			});

			it("keeps mixed-in methods functional and instances independent", () => {
				// Default value comes from config()/properties — proves the instance
				// is wired up, not just method-shaped.
				var a1 = model("author").new();
				expect(a1.firstName).toBe("Dave");
				expect(a1.valid()).toBeBoolean();

				var a2 = model("author").new(firstName = "Grace");
				expect(a2.firstName).toBe("Grace");
				// Mutating one instance must not leak into another.
				expect(a1.firstName).toBe("Dave");
			});

		});
	}

}
