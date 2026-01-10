component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests that strings", () => {

			it("processes irregular strings", () => {
				local.oldIrregulars = application.wheels.irregulars
				local.irregulars = local.oldIrregulars
				StructAppend(local.irregulars, {pac = "tupac"})
				application.wheels.irregulars = local.irregulars
				result1 = g.pluralize("pac")
				result2 = g.singularize("tupac")
				application.wheels.irregulars = local.oldIrregulars

				expect(result1).toBeWithCase("tupac")
				expect(result2).toBeWithCase("pac")
			})

			it("singularizes", () => {
				expect(g.singularize("statuses")).toBeWithCase("status")
			})

			it("singularizes starting with upper case", () => {
				expect(g.singularize("Instances")).toBeWithCase("Instance")
			})

			it("singularizes two words", () => {
				expect(g.singularize("statusUpdates")).toBeWithCase("statusUpdate")
			})

			it("singularizes multiple words", () => {
				expect(g.singularize("fancyChristmasTrees")).toBeWithCase("fancyChristmasTree")
			})

			it("singularizes already singularized camel case", () => {
				expect(g.singularize("camelCasedFailure")).toBeWithCase("camelCasedFailure")
			})

			it("pluralizes", () => {
				expect(g.pluralize("status")).toBeWithCase("statuses")
			})

			it("pluralizes with count", () => {
				expect(g.pluralize("statusUpdate", 0)).toBeWithCase("0 statusUpdates")
				expect(g.pluralize("statusUpdate", 1)).toBeWithCase("1 statusUpdate")
				expect(g.pluralize("statusUpdate", 2)).toBeWithCase("2 statusUpdates")
			})

			it("pluralizes starting with upper case", () => {
				expect(g.pluralize("Instance")).toBeWithCase("Instances")
			})

			it("pluralizes two words", () => {
				expect(g.pluralize("statusUpdate")).toBeWithCase("statusUpdates")
			})

			it("pluralize issue 450", () => {
				expect(g.pluralize("statuscode")).toBeWithCase("statuscodes")
			})

			it("pluralize multiple words", () => {
				expect(g.pluralize("fancyChristmasTree")).toBeWithCase("fancyChristmasTrees")
			})

			it("hyphenizes normal variable", () => {
				expect(g.hyphenize("wheelsIsAFramework")).toBeWithCase("wheels-is-a-framework")
			})

			it("hyphenizes variable starting with upper case", () => {
				expect(g.hyphenize("WheelsIsAFramework")).toBeWithCase("wheels-is-a-framework")
			})

			it("hyphenizes variable with abbreviation", () => {
				expect(g.hyphenize("aURLVariable")).toBeWithCase("a-url-variable")
			})

			it("hyphenizes variable with abbreviation starting with upper case", () => {
				expect(g.hyphenize("URLVariable")).toBeWithCase("url-variable")
			})

			it("hyphenize should only insert hyphens in mixed case", () => {
				expect(g.hyphenize("ERRORMESSAGE")).toBeWithCase("errormessage")
				expect(g.hyphenize("errormessage")).toBeWithCase("errormessage")
			})

			it("singularizes address", () => {
				expect(g.hyphenize("address")).toBeWithCase("address")
			})
		})
	}
}