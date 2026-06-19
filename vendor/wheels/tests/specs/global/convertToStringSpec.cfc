component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that $parseSlashDate", () => {

			it("treats a first component greater than 12 as the day (DD/MM/YYYY)", () => {
				result = g.$parseSlashDate(d1 = 25, d2 = 6, year = 2024)

				expect(DateFormat(result, "yyyy-mm-dd")).toBe("2024-06-25")
			})

			it("treats a second component greater than 12 as the day (MM/DD/YYYY)", () => {
				result = g.$parseSlashDate(d1 = 6, d2 = 25, year = 2024)

				expect(DateFormat(result, "yyyy-mm-dd")).toBe("2024-06-25")
			})

			it("delegates truly ambiguous dates to the engine adapter", () => {
				result = g.$parseSlashDate(d1 = 3, d2 = 5, year = 2024)
				adapterResult = application.wheels.engineAdapter.parseAmbiguousSlashDate(3, 5, 2024)

				expect(DateFormat(result, "yyyy-mm-dd")).toBe(DateFormat(adapterResult, "yyyy-mm-dd"))
			})
		})

		describe("Tests that $convertToString slash-date handling", () => {

			it("canonicalizes an unambiguous month-first US date with AM/PM", () => {
				// pre-fix this crashed on BoxLang: the inline parser treated the
				// date as DD/MM unconditionally, yielding CreateDateTime(2024, 25, 6, ...)
				result = g.$convertToString(value = "06/25/2024 10:30 AM", type = "datetime")

				expect(result).toBe("2024-06-25 10:30:00")
			})

			it("canonicalizes an unambiguous day-first date with AM/PM", () => {
				// time handling varies by engine (some parse 10:30 PM, some fall
				// back to midnight) but the date part must disambiguate to June 25
				result = g.$convertToString(value = "25/06/2024 10:30 PM", type = "datetime")

				expect(result).toMatch("^2024-06-25")
			})

			it("canonicalizes a date object unchanged", () => {
				result = g.$convertToString(value = CreateDateTime(2024, 6, 25, 10, 30, 0), type = "datetime")

				expect(result).toBe("2024-06-25 10:30:00")
			})
		})
	}
}
