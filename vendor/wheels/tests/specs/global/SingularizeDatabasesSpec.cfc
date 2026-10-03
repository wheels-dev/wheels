/**
 * singularize("databases") used to return "databasis": the -ses rule for basis/bases also
 * matched the "bases" at the end of "databases". A dedicated rule now returns "database".
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Inflection of -bases and -ases words", () => {

			it("singularizes databases to database", () => {
				var cases = [
					["databases", "database"],
					["Databases", "Database"],
					["userDatabases", "userDatabase"]
				]
				for (var c in cases) {
					var result = g.singularize(c[1])
					expect(Compare(result, c[2])).toBe(0, "singularize(#c[1]#) returned #result#, expected #c[2]#")
				}
			})

			it("keeps the other -ases words unchanged", () => {
				// "bases" is also the plural of "basis", which the -ses rule has always returned.
				var cases = [
					["bases", "basis"],
					["cases", "case"],
					["phases", "phase"],
					["purchases", "purchase"],
					["vases", "vase"]
				]
				for (var c in cases) {
					var result = g.singularize(c[1])
					expect(Compare(result, c[2])).toBe(0, "singularize(#c[1]#) returned #result#, expected #c[2]#")
				}
			})

			it("pluralizes the same words", () => {
				var cases = [
					["database", "databases"],
					["base", "bases"],
					["case", "cases"],
					["phase", "phases"],
					["purchase", "purchases"],
					["vase", "vases"]
				]
				for (var c in cases) {
					var result = g.pluralize(c[1])
					expect(Compare(result, c[2])).toBe(0, "pluralize(#c[1]#) returned #result#, expected #c[2]#")
				}
			})

		})

	}

}
