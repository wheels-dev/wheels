/**
 * pluralize() / singularize() serve results from an application-scoped cache (#4150).
 * These specs pin that a cached result equals the uncached inflection, and that the
 * cache follows the inflection settings, case, tenants and its size limit.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		// "vertex", "index" and "half" are left out: their plural rules refer back to a regex group
		// that does not take part in the match, which errors on BoxLang with or without the cache.
		corpus = [
			"item", "items", "product", "category", "categories", "person", "people", "man", "men",
			"child", "children", "sex", "move", "moves", "cow", "zombie", "quiz", "quizzes", "ox", "oxen",
			"mouse", "mice", "matrix", "matrices", "box", "boxes", "church", "class",
			"wish", "fly", "flies", "query", "queries", "hive", "wife", "wives", "halves", "analysis",
			"analyses", "datum", "data", "buffalo", "tomato", "potato", "hero", "bus", "buses", "alias",
			"status", "statuses", "octopus", "virus", "axis", "testis", "crisis", "news", "series", "species",
			"fish", "sheep", "rice", "equipment", "information", "software", "feedback", "address", "shoe",
			"movie", "movies", "tag", "post", "comment", "user", "account", "invoice", "order", "line",
			"Person", "PERSON", "People", "Item", "ITEM", "websiteStatusUpdate", "blogPost", "userAccount",
			"orderLineItem", "pageCategory", "mainCategories", "xBox", "AB", "a", "s", "", "ss", "glass"
		]

		describe("Inflection cache (##4150)", () => {

			beforeEach(() => {
				settings = application[StructKeyExists(application, "$wheels") ? "$wheels" : "wheels"]
				StructDelete(settings, "inflectionCache")
			})

			it("returns the uncached inflection for every word in the corpus, on a miss and on a hit", () => {
				for (var which in ["pluralize", "singularize"]) {
					for (var word in corpus) {
						var expected = g.$inflect(text = word, which = which)
						var miss = which == "pluralize" ? g.pluralize(word) : g.singularize(word)
						var hit = which == "pluralize" ? g.pluralize(word) : g.singularize(word)
						expect(Compare(miss, expected)).toBe(0, "#which#(#word#) miss: #miss# vs #expected#")
						expect(Compare(hit, expected)).toBe(0, "#which#(#word#) hit: #hit# vs #expected#")
					}
				}
			})

			it("keeps count and returnCount formatting outside the cache", () => {
				expect(g.pluralize("item")).toBe("items")
				expect(g.pluralize(word = "item", count = 5)).toBe("5 items")
				expect(g.pluralize(word = "item", count = 1)).toBe("1 item")
				expect(g.pluralize(word = "item", count = 5, returnCount = false)).toBe("items")
				expect(g.pluralize(word = "item", count = 1, returnCount = false)).toBe("item")
			})

			it("doesn't serve one spelling's result to a case variant", () => {
				var lower = g.pluralize("person")
				var title = g.pluralize("Person")
				var upper = g.pluralize("PERSON")
				expect(Compare(lower, g.$inflect(text = "person", which = "pluralize"))).toBe(0)
				expect(Compare(title, g.$inflect(text = "Person", which = "pluralize"))).toBe(0)
				expect(Compare(upper, g.$inflect(text = "PERSON", which = "pluralize"))).toBe(0)
			})

			it("follows a set() of uncountables or irregulars", () => {
				var saved = {uncountables = settings.uncountables, irregulars = Duplicate(settings.irregulars)}
				try {
					expect(g.pluralize("zork4150")).toBe("zork4150s")
					g.set(uncountables = saved.uncountables & ",zork4150")
					expect(g.pluralize("zork4150")).toBe("zork4150")
					var irregulars = Duplicate(saved.irregulars)
					irregulars["blarg4150"] = "blargen4150"
					g.set(irregulars = irregulars)
					expect(g.pluralize("blarg4150")).toBe("blargen4150")
				} finally {
					g.set(uncountables = saved.uncountables)
					g.set(irregulars = saved.irregulars)
				}
				expect(g.pluralize("zork4150")).toBe("zork4150s")
			})

			it("follows a change made to the irregulars struct directly", () => {
				var probe = g.pluralize("glorp4150")
				expect(probe).toBe("glorp4150s")
				var state = {added = false}
				try {
					settings.irregulars["glorp4150"] = "glorpi4150"
					state.added = true
					expect(g.pluralize("glorp4150")).toBe("glorpi4150")
				} finally {
					StructDelete(settings.irregulars, "glorp4150")
				}
				expect(state.added).toBeTrue()
				expect(g.pluralize("glorp4150")).toBe("glorp4150s")
			})

			it("bypasses the cache when the tenant overrides the inflection settings", () => {
				var cached = g.pluralize("snorf4150")
				expect(cached).toBe("snorf4150s")
				var hadWheels = StructKeyExists(request, "wheels")
				if (!hadWheels) {
					request.wheels = {}
				}
				var hadTenant = StructKeyExists(request.wheels, "tenant")
				var savedTenant = hadTenant ? request.wheels.tenant : ""
				try {
					request.wheels.tenant = {config = {uncountables = settings.uncountables & ",snorf4150"}}
					expect(g.pluralize("snorf4150")).toBe("snorf4150")
				} finally {
					if (hadTenant) {
						request.wheels.tenant = savedTenant
					} else {
						StructDelete(request.wheels, "tenant")
					}
				}
				expect(g.pluralize("snorf4150")).toBe("snorf4150s")
			})

			it("stays bounded and doesn't cache long text", () => {
				for (var i = 1; i <= 2050; i++) {
					var w = g.pluralize("word#i#x")
				}
				expect(StructCount(settings.inflectionCache.entries)).toBeLTE(2000)
				var longText = RepeatString("a", 120) & "item"
				var before = StructCount(settings.inflectionCache.entries)
				var plural = g.pluralize(longText)
				expect(plural).toBe(g.$inflect(text = longText, which = "pluralize"))
				expect(StructCount(settings.inflectionCache.entries)).toBe(before)
			})

		})

	}

}
