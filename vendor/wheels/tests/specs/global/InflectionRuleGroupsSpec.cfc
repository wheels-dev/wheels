/**
 * The pluralize rules for -ix/-ex and -fe/-f words used to refer back to a regex group
 * that does not take part in the match ("vertex" matched `ex$`, leaving `\1` unset).
 * Lucee and Adobe replace an unset group with an empty string; BoxLang threw
 * "Index -1 out of bounds". These specs pin the output every engine must now produce,
 * which is the output Lucee and Adobe already gave.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Inflection rules that back-reference a regex group", () => {

			it("pluralizes -ix and -ex words", () => {
				var cases = [
					["matrix", "matrices"],
					["vertex", "vertices"],
					["index", "indices"],
					["Index", "Indices"],
					["pageIndex", "pageIndices"],
					["apex", "apices"]
				]
				for (var c in cases) {
					var result = g.pluralize(c[1])
					expect(Compare(result, c[2])).toBe(0, "pluralize(#c[1]#) returned #result#, expected #c[2]#")
				}
			})

			it("pluralizes -fe and -f words", () => {
				var cases = [
					["wife", "wives"],
					["knife", "knives"],
					["life", "lives"],
					["half", "halves"],
					["calf", "calves"],
					["wolf", "wolves"],
					["shelf", "shelves"],
					["chief", "chiefs"],
					["roof", "roofs"]
				]
				for (var c in cases) {
					var result = g.pluralize(c[1])
					expect(Compare(result, c[2])).toBe(0, "pluralize(#c[1]#) returned #result#, expected #c[2]#")
				}
			})

			it("singularizes the same words back", () => {
				var cases = [
					["matrices", "matrix"],
					["vertices", "vertex"],
					["indices", "index"],
					["pageIndices", "pageIndex"],
					["wives", "wife"],
					["knives", "knife"],
					["halves", "half"],
					["calves", "calf"],
					["wolves", "wolf"],
					["shelves", "shelf"]
				]
				for (var c in cases) {
					var result = g.singularize(c[1])
					expect(Compare(result, c[2])).toBe(0, "singularize(#c[1]#) returned #result#, expected #c[2]#")
				}
			})

		})

	}

}
