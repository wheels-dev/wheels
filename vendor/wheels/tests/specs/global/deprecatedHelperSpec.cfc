// upgrade-docs:6 — shared $deprecated() helper: one policy for logging and
// registering deprecation warnings so they are visible to running apps
// (application[appKey].deprecationWarnings, rendered by the debug panel).
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("$deprecated shared helper", () => {

			beforeEach(() => {
				hadOriginalWarnings = StructKeyExists(application.wheels, "deprecationWarnings")
				if (hadOriginalWarnings) {
					originalWarnings = application.wheels.deprecationWarnings
				}
				application.wheels.deprecationWarnings = []
			})

			afterEach(() => {
				if (hadOriginalWarnings) {
					application.wheels.deprecationWarnings = originalWarnings
				} else {
					StructDelete(application.wheels, "deprecationWarnings")
				}
			})

			it("records feature, message and url in the application registry", () => {
				g.$deprecated(
					feature = "wheelstest-probe",
					message = "Probe message.",
					docUrl = "https://example.com/migrate"
				)
				expect(ArrayLen(application.wheels.deprecationWarnings)).toBe(1)
				var entry = application.wheels.deprecationWarnings[1]
				expect(entry.feature).toBe("wheelstest-probe")
				expect(entry.message).toBe("Probe message.")
				expect(entry.url).toBe("https://example.com/migrate")
			})

			it("registers a feature only once per application", () => {
				g.$deprecated(feature = "wheelstest-dedupe", message = "First.")
				g.$deprecated(feature = "wheelstest-dedupe", message = "Second.")
				expect(ArrayLen(application.wheels.deprecationWarnings)).toBe(1)
				expect(application.wheels.deprecationWarnings[1].message).toBe("First.")
			})

			it("registers distinct features separately", () => {
				g.$deprecated(feature = "wheelstest-a", message = "A.")
				g.$deprecated(feature = "wheelstest-b", message = "B.")
				expect(ArrayLen(application.wheels.deprecationWarnings)).toBe(2)
			})

			it("creates the registry lazily when it does not exist yet", () => {
				StructDelete(application.wheels, "deprecationWarnings")
				g.$deprecated(feature = "wheelstest-lazy", message = "Lazy.")
				expect(StructKeyExists(application.wheels, "deprecationWarnings")).toBeTrue()
				expect(ArrayLen(application.wheels.deprecationWarnings)).toBe(1)
			})

		})

	}

}
