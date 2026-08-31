/**
 * Guard for the model mixin surface (issue #3213).
 *
 * The model mixin files (vendor/wheels/model/*.cfm) are compile-time included
 * into wheels.Model, so every model instance INHERITS the full API with no
 * per-instance integration plan and no per-instance copy. The runtime
 * integration-plan cache (#3236) still exists for the controller/mapper
 * surfaces (see IntegrationPlanSpec), but the model path must no longer touch
 * it.
 *
 * These specs pin what the fast path must preserve: no model integration plan
 * is built, and every materialized instance still carries the full, working,
 * independent set of model methods.
 */
component extends="wheels.WheelsTest" {

	function run() {
		describe("mixin-integration plan cache (##3213)", () => {

			it("materializes models without building a model integration plan", () => {
				// With the compile-time-included surface (#3213), model
				// materialization must never touch the runtime integration-plan
				// cache — no "wheels.model" entry may appear, even when the cache
				// exists for other surfaces.
				model("author").new();
				if (StructKeyExists(application.wheels, "integrationPlans")) {
					expect(StructKeyExists(application.wheels.integrationPlans, "wheels.model")).toBeFalse();
				}
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
