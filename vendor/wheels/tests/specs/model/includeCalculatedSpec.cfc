component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("includeCalculated finder argument (issue ##3252)", () => {

			it("is additive in the generated SELECT — opts in a select=false calculated property without dropping base columns", () => {
				// `titleAlias` is declared `select=false` on Post, so it is absent by default.
				baseClause = g.model("post").$selectClause(
					select = "",
					include = "",
					returnAs = "query"
				);
				expect(baseClause).notToInclude("AS titleAlias");

				// Opting it in must ADD it on top of the default columns, not replace them.
				optedIn = g.model("post").$selectClause(
					select = "",
					include = "",
					returnAs = "query",
					includeCalculated = "titleAlias"
				);
				expect(optedIn).toInclude("AS titleAlias");
				// base columns are still present (additive, not replacing)
				expect(optedIn).toInclude("title");
			});

			it("supports a comma list of calculated property names", () => {
				clause = g.model("post").$selectClause(
					select = "",
					include = "",
					returnAs = "query",
					includeCalculated = "titleAlias,createdAtAlias"
				);
				expect(clause).toInclude("AS titleAlias");
				expect(clause).toInclude("AS createdAtAlias");
			});

			it("populates the opted-in property on a real finder while base columns remain", () => {
				post = g.model("post").findOne(includeCalculated = "titleAlias");
				expect(IsObject(post)).toBeTrue();
				// base property still present
				expect(StructKeyExists(post, "title")).toBeTrue();
				// the opted-in calculated property is now populated and mirrors `title`
				expect(StructKeyExists(post, "titleAlias")).toBeTrue();
				expect(post.titleAlias).toBe(post.title);
			});

			it("leaves the opted-in property off the default finder", () => {
				post = g.model("post").findOne();
				expect(IsObject(post)).toBeTrue();
				expect(StructKeyExists(post, "titleAlias")).toBeFalse();
			});

			it("throws Wheels.CalculatedPropertyNotFound for an unknown name in development/testing", () => {
				expect(() => {
					g.model("post").$selectClause(
						select = "",
						include = "",
						returnAs = "query",
						includeCalculated = "thisDoesNotExist"
					);
				}).toThrow(type = "Wheels.CalculatedPropertyNotFound");
			});

		});

	}

}
