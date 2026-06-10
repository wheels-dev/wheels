/**
 * Regression surface of the DC16 fix (#2933): $get()'s per-tenant override
 * lookup traverses request.wheels.tenant.config via a StructKeyExists chain.
 * The exact hazard the IsDefined→StructKeyExists rewrite guarded against is
 * an ABSENT request.wheels (early bootstrap, CLI call sites) — the happy
 * tenant-override paths are covered by MultiTenantIntegrationSpec; this
 * pins the no-throw contract for the absent case (#2977).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("$get() without request.wheels", () => {

			it("does not throw when request.wheels is absent", () => {
				var had = StructKeyExists(request, "wheels");
				var saved = had ? request.wheels : {};
				StructDelete(request, "wheels");
				try {
					var value = application.wo.$get("environment");
					expect(value).toBe(application.wheels.environment);
				} finally {
					if (had) {
						request.wheels = saved;
					}
				}
			});

		});

	}

}
