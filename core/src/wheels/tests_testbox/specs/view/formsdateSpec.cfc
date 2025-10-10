component extends="wheels.Testbox" {

	function run() {

		describe("Tests that $yearMonthHourMinuteSecondSelectTagContent", () => {

			beforeEach(() => {
				pkg.controller = application.wo.controller("dummy")
				result = ""
				results = {}
			})

			it("works with basic", () => {
				result = pkg.controller.$yearMonthHourMinuteSecondSelectTagContent(
					counter = 5,
					value = "",
					$optionNames = "",
					$type = ""
				)

				expect(result).toBe("<option value=""5"">5</option>")
			})

			it("works with selected", () => {
				result = pkg.controller.$yearMonthHourMinuteSecondSelectTagContent(
					counter = 3,
					value = 3,
					$optionNames = "",
					$type = ""
				)

				expect(result).toBe("<option selected=""selected"" value=""3"">3</option>")
			})

			it("works with formatting", () => {
				result = pkg.controller.$yearMonthHourMinuteSecondSelectTagContent(
					counter = 1,
					value = "",
					$optionNames = "",
					$type = "minute"
				)

				expect(result).toBe("<option value=""1"">01</option>")

				result = pkg.controller.$yearMonthHourMinuteSecondSelectTagContent(
					counter = 59,
					value = "",
					$optionNames = "",
					$type = "second"
				)

				expect(result).toBe("<option value=""59"">59</option>")
			})

			it("works with option name", () => {
				result = pkg.controller.$yearMonthHourMinuteSecondSelectTagContent(
					counter = 1,
					value = "",
					$optionNames = "someName",
					$type = ""
				)
				
				expect(result).toBe("<option value=""1"">someName</option>")
			})
		})
	}
}