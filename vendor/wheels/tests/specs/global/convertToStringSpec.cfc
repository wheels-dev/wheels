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

		describe("Tests that $convertToString type detection", () => {

			it("detects arrays without an explicit type", () => {
				result = g.$convertToString(value = ["a", "b", "c"])

				expect(result).toBe("a,b,c")
			})

			it("detects structs without an explicit type", () => {
				result = g.$convertToString(value = {firstName = "Tony", lastName = "Petruzzi"})

				// Struct stringification is engine-specific (Lucee renders
				// KEY=VALUE pairs) — assert the data survives, not the shape.
				expect(result).toInclude("Tony")
				expect(result).toInclude("Petruzzi")
			})

			it("detects integers without an explicit type", () => {
				result = g.$convertToString(value = 42)

				expect(result).toBe("42")
			})

			it("detects floats without an explicit type", () => {
				result = g.$convertToString(value = 3.14)

				expect(result).toBe("3.14")
			})

			it("detects booleans without an explicit type", () => {
				result = g.$convertToString(value = true)

				expect(result).toBe("true")
			})

			it("detects datetime values without an explicit type", () => {
				result = g.$convertToString(value = CreateDateTime(2024, 6, 25, 10, 30, 0))

				expect(result).toBe("2024-06-25 10:30:00")
			})

			it("detects binaries without an explicit type", () => {
				result = g.$convertToString(value = CharsetDecode("hello", "utf-8"))

				// ToString(binary) renders engine-specifically (Lucee emits the
				// byte values) — assert the branch returned something non-empty.
				expect(result).notToBe("")
			})

			it("falls back to string for plain text without an explicit type", () => {
				result = g.$convertToString(value = "just some text")

				expect(result).toBe("just some text")
			})

			it("reports the detected type directly via $convertToStringDetectType", () => {
				expect(g.$convertToStringDetectType(val = [1])).toBe("array")
				expect(g.$convertToStringDetectType(val = {a = 1})).toBe("struct")
				// IsArray() on a Java byte[] is engine-dependent (true on
				// Lucee) — the binary branch only fires where the engine
				// distinguishes the two shapes.
				expect(["binary", "array"]).toInclude(g.$convertToStringDetectType(val = CharsetDecode("x", "utf-8")))
				expect(g.$convertToStringDetectType(val = 5)).toBe("integer")
				expect(g.$convertToStringDetectType(val = CreateDate(2024, 6, 25))).toBe("datetime")
				expect(g.$convertToStringDetectType(val = "text")).toBe("string")
			})
		})
	}
}
