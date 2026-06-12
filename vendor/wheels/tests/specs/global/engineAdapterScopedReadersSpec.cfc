component extends="wheels.WheelsTest" {

	/*
	 * Regression coverage for #3076.
	 *
	 * During a failed application start, the engine adapter is staged in the
	 * `application.$wheels` startup struct but never promoted to
	 * `application.wheels`. Three `$hasEngineAdapter()`-gated readers
	 * (`$getRequestTimeout()`, `$statusCode()`, `$contentType()`) used to gate
	 * on the two-scope check but then read `application.wheels.engineAdapter`
	 * unconditionally. When only the `$wheels` branch matched, that read threw
	 * `key [ENGINEADAPTER] doesn't exist` (Lucee) /
	 * `Element WHEELS.ENGINEADAPTER is undefined` (Adobe) from inside `onError`,
	 * masking the original app-start exception (e.g. the
	 * `Wheels.Cors.InvalidConfiguration` guard).
	 *
	 * Each spec simulates the failed-startup scope mismatch: the adapter lives
	 * only in `application.$wheels`, and `application.wheels.engineAdapter` is
	 * absent. The reader must resolve the adapter from whichever scope holds it
	 * (via `$engineAdapter()`) instead of crashing.
	 */
	function run() {

		g = application.wo

		describe("$hasEngineAdapter()-gated readers during a failed startup (##3076)", () => {

			it("$getRequestTimeout() resolves the adapter staged in application.$wheels", () => {
				var probe = {error = "", value = 0}
				var saved = application.wheels.engineAdapter
				var hadStaging = StructKeyExists(application, "$wheels")
				var savedStaging = hadStaging ? application.$wheels : {}
				application.$wheels = {engineAdapter = saved}
				StructDelete(application.wheels, "engineAdapter")
				try {
					probe.value = g.$getRequestTimeout()
				} catch (any e) {
					probe.error = e.message
				} finally {
					application.wheels.engineAdapter = saved
					if (hadStaging) {
						application.$wheels = savedStaging
					} else {
						StructDelete(application, "$wheels")
					}
				}
				expect(probe.error).toBe("")
				expect(probe.value).toBeNumeric()
			})

			it("$statusCode() resolves the adapter staged in application.$wheels", () => {
				var probe = {error = "", value = ""}
				var saved = application.wheels.engineAdapter
				var hadStaging = StructKeyExists(application, "$wheels")
				var savedStaging = hadStaging ? application.$wheels : {}
				application.$wheels = {engineAdapter = saved}
				StructDelete(application.wheels, "engineAdapter")
				try {
					probe.value = g.$statusCode()
				} catch (any e) {
					probe.error = e.message
				} finally {
					application.wheels.engineAdapter = saved
					if (hadStaging) {
						application.$wheels = savedStaging
					} else {
						StructDelete(application, "$wheels")
					}
				}
				expect(probe.error).toBe("")
				expect(probe.value).toBeNumeric()
			})

			it("$contentType() resolves the adapter staged in application.$wheels", () => {
				var probe = {error = "", value = "", isSimple = false}
				var saved = application.wheels.engineAdapter
				var hadStaging = StructKeyExists(application, "$wheels")
				var savedStaging = hadStaging ? application.$wheels : {}
				application.$wheels = {engineAdapter = saved}
				StructDelete(application.wheels, "engineAdapter")
				try {
					probe.value = g.$contentType()
					probe.isSimple = IsSimpleValue(probe.value)
				} catch (any e) {
					probe.error = e.message
				} finally {
					application.wheels.engineAdapter = saved
					if (hadStaging) {
						application.$wheels = savedStaging
					} else {
						StructDelete(application, "$wheels")
					}
				}
				expect(probe.error).toBe("")
				expect(probe.isSimple).toBeTrue()
			})
		})
	}
}
