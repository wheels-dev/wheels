/**
 * The singularize rule for -ses words (analyses, bases, theses, ...) used `\1\2sis`, where
 * group 2 was the leading "a" of the "analy" alternative. A word that ends in "analyses" but
 * doesn't start with it (psychoanalyses) came back as "psychoanalyasis".
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("singularize() for -ses words", () => {

			it("singularizes a prefixed -analyses word", () => {
				var cases = [
					["psychoanalyses", "psychoanalysis"],
					["Psychoanalyses", "Psychoanalysis"],
					["metaAnalyses", "metaAnalysis"]
				]
				for (var c in cases) {
					var result = g.singularize(c[1])
					expect(Compare(result, c[2])).toBe(0, "singularize(#c[1]#) returned #result#, expected #c[2]#")
				}
			})

			it("keeps the other -ses words unchanged", () => {
				var cases = [
					["analyses", "analysis"],
					["Analyses", "Analysis"],
					["bases", "basis"],
					["diagnoses", "diagnosis"],
					["parentheses", "parenthesis"],
					["prognoses", "prognosis"],
					["synopses", "synopsis"],
					["theses", "thesis"],
					["hypotheses", "hypothesis"]
				]
				for (var c in cases) {
					var result = g.singularize(c[1])
					expect(Compare(result, c[2])).toBe(0, "singularize(#c[1]#) returned #result#, expected #c[2]#")
				}
			})

		})

	}

}
