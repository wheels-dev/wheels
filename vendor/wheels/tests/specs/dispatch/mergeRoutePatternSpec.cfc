component extends="wheels.WheelsTest" {

	function run() {

		describe("Tests that $mergeRoutePattern", () => {

			beforeEach(() => {
				dispatch = CreateObject("component", "wheels.Dispatch")
			})

			it("extracts route variables by position", () => {
				route = {
					pattern = "/archive/[year]/[month]",
					regex = "^archive\/(\d{4})\/(\d{2})\/?$",
					foundVariables = "year,month"
				}
				result = dispatch.$mergeRoutePattern(params = {}, route = route, path = "archive/2024/05")

				expect(result.year).toBe("2024")
				expect(result.month).toBe("05")
			})

			it("ignores extra capturing groups beyond the route variable list", () => {
				// Constraint patterns are rewritten to non-capturing groups at draw time,
				// but if an extra capturing group slips into a route regex it must not
				// crash extraction (ListGetAt out-of-bounds) or assign values past the
				// route's variable list.
				route = {
					pattern = "/archive/[year]",
					regex = "^archive\/((20)\d{2})\/?$",
					foundVariables = "year"
				}
				result = dispatch.$mergeRoutePattern(params = {}, route = route, path = "archive/2024")

				expect(result.year).toBe("2024")
				expect(StructCount(result)).toBe(1)
			})
		})
	}
}
