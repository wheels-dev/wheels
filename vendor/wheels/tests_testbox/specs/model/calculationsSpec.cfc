component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests that average", () => {

			it("works with integer", () => {
				result = g.model("post").average(property = "views")

				expect(result).toBe(3)
			})

			it("works with integer with non matching where", () => {
				result = g.model("post").average(property = "views", where = "id=0")

				expect(result).toBe("")
			})

			it("works with integer with distinct", () => {
				result = g.model("post").average(property = "views", distinct = "true")

				expect(DecimalFormat(result)).toBe(DecimalFormat(2.50))
			})

			it("works with integer with ifnull", () => {
				result = g.model("post").average(property = "views", where = "id=0", ifNull = 0)

				expect(result).toBe(0)
			})

			it("works with group", () => {
				if (ListFindNoCase("MySQL,SQLServer", g.get("adaptername"))) {
					result = g.model("post").average(property = "averageRating", group = "authorId")
					expect(DecimalFormat(result['averageRatingAverage'][1])).toBe(DecimalFormat(3.40))
				} else {
					expect(true).toBeTrue()
				}
			})

			it("works with float", () => {
				result = g.model("post").average(property = "averageRating")

				expect(DecimalFormat(result)).toBe(DecimalFormat(3.50))
			})

			it("works with float with non matching where", () => {
				result = g.model("post").average(property = "averageRating", where = "id=0")

				expect(result).toBe("")
			})

			it("works with float with distinct", () => {
				result = g.model("post").average(property = "averageRating", distinct = "true")

				expect(DecimalFormat(result)).toBe(DecimalFormat(3.4))
			})

			it("works with float with ifnull", () => {
				result = g.model("post").average(property = "averageRating", where = "id=0", ifNull = 0)

				expect(result).toBe(0)
			})

			it("works with include soft deletes", () => {
				transaction action="begin" {
					post = g.model("Post").findOne(where = "views=0")
					post.delete(transaction = "none")
					average = g.model("Post").average(property = "views", includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(average).toBe(3)
			})
		})

		describe("Tests that count", () => {

			it("is counting", () => {
				result = g.model("author").count()

				expect(result).toBe(10)
			})

			it("is counting with group", () => {
				if (ListFindNoCase("MySQL,SQLServer", g.get("adaptername"))) {
					result = g.model("post").count(property = "views", group = "authorId")

					expect(result['count'][2]).toBe(2)
				} else {
					expect(true).toBeTrue()
				}
			})

			it("is counting with include", () => {
				result = g.model("author").count(include = "posts")
				expect(result).toBe(10)
			})

			it("is counting with where", () => {
				result = g.model("author").count(where = "lastName = 'Djurner'")
				expect(result).toBe(1)
			})

			it("is counting with non matching where", () => {
				result = g.model("author").count(where = "id=0")
				expect(result).toBe(0)
			})

			it("is counting with non matching where and include", () => {
				result = g.model("author").count(where = "id = 0", include = "posts")
				expect(result).toBe(0)
			})

			it("is counting with where and include", () => {
				result = g.model("author").count(where = "lastName = 'Djurner' OR lastName = 'Peters'", include = "posts")
				expect(result).toBe(2)
			})

			it("is counting with where on included association", () => {
				result = g.model("author").count(
					where = "title LIKE '%first%' OR title LIKE '%second%' OR title LIKE '%fourth%'",
					include = "posts"
				)

				expect(result).toBe(2)
			})

			it("is counting with dynamic count", () => {
				author = g.model("author").findOne(where = "lastName='Djurner'")
				result = author.postCount()

				expect(result).toBe(3)
			})

			it("is counting with dynamic count with where", () => {
				author = g.model("author").findOne(where = "lastName='Djurner'")
				result = author.postCount(where = "title LIKE '%first%' OR title LIKE '%second%'")

				expect(result).toBe(2)
			})

			it("is counting with include soft deletes", () => {
				transaction action="begin" {
					post = g.model("Post").findOne(where = "views=0")
					post.delete(transaction = "none")
					count = g.model("Post").count(property = "views", includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(count).toBe(5)
			})
		})

		describe("Tests that maximum", () => {

			it("works", () => {
				result = g.model("post").maximum(property = "views")

				expect(result).toBe(5)
			})

			it("works with group", () => {
				if (ListFindNoCase("MySQL,SQLServer", g.get("adaptername"))) {
					result = g.model("post").maximum(property = "views", group = "authorId")

					expect(result['viewsMaximum'][1]).toBe(5)
				} else {
					expect(true).toBe(true)
				}
			})

			it("works with where", () => {
				result = g.model("post").maximum(property = "views", where = "title LIKE 'Title%'")

				expect(result).toBe(5)
			})

			it("works with non matching where", () => {
				result = g.model("post").maximum(property = "views", where = "id=0")

				expect(result).toBe("")
			})

			it("works with ifnull", () => {
				result = g.model("post").maximum(property = "views", where = "id=0", ifNull = 0)

				expect(result).toBe(0)
			})

			it("works with include soft deletes", () => {
				transaction action="begin" {
					post = g.model("Post").deleteAll(where = "views=5", transaction = "none")
					maximum = g.model("Post").maximum(property = "views", includeSoftDeletes = true)
					transaction action="rollback";
				}
				

				expect(maximum).toBe(5)
			})
		})

		describe("Tests that minimum", () => {

			it("works", () => {
				result = g.model("post").minimum(property = "views")

				expect(result).toBe(0)
			})

			it("works with group", () => {
				if (ListFindNoCase("MySQL,SQLServer", g.get("adaptername"))) {
					result = g.model("post").minimum(property = "views", group = "authorId")

					expect(result['viewsMinimum'][2]).toBe(2)
				} else {
					expect(true).toBe(true)
				}
			})

			it("works with non matching where", () => {
				result = g.model("post").minimum(property = "views", where = "id=0")

				expect(result).toBe("")
			})

			it("works with ifnull", () => {
				result = g.model("post").minimum(property = "views", where = "id=0", ifNull = 0)

				expect(result).toBe(0)
			})

			it("works with include soft deletes", () => {
				transaction action="begin" {
					post = g.model("Post").deleteAll(where = "views=0", transaction = "none")
					minimum = g.model("Post").minimum(property = "views", includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(minimum).toBe(0)
			})
		})

		describe("Tests that sum", () => {

			it("works", () => {
				result = g.model("post").sum(property = "views")

				expect(result).toBe(15)
			})

			it("works with group", () => {
				if (ListFindNoCase("MySQL,SQLServer", g.get("adaptername"))) {
					result = g.model("post").sum(property = "views", group = "authorId")

					expect(result['viewsSum'][2]).toBe(5)
				} else {
					expect(true).toBe(true)
				}
			})

			it("works with group on associated model", () => {
				if (ListFindNoCase("MySQL,SQLServer", g.get("adaptername"))) {
					result = g.model("post").sum(property = "views", include = "author", group = "lastName")

					expect(result['viewsSum'][2]).toBe(5)
				} else {
					expect(true).toBe(true)
				}
			})

			it("works with group on calculated property", () => {
				if (ListFindNoCase("MySQL,SQLServer", g.get("adaptername"))) {
					result = g.model("photo").sum(property = "galleryId", group = "DESCRIPTION1")

					expect(result.recordcount).toBe(250)
				} else {
					expect(true).toBe(true)
				}
			})

			it("works with group on calculated property on associated model", () => {
				if (ListFindNoCase("MySQL,SQLServer", g.get("adaptername"))) {
					result = g.model("gallery").sum(property = "userId", include = "photos", group = "DESCRIPTION1")

					expect(result.recordcount).toBe(250)
				} else {
					expect(true).toBe(true)
				}
			})

			it("works with where", () => {
				author = g.model("author").findOne(where = "lastName='Djurner'")
				result = g.model("post").sum(property = "views", where = "authorid=#author.id#")

				expect(result).toBe(10)
			})

			it("works with non matching where", () => {
				result = g.model("post").sum(property = "views", where = "id=0")

				expect(result).toBe("")
			})

			it("works with distinct", () => {
				result = g.model("post").sum(property = "views", distinct = true)

				expect(result).toBe(10)
			})

			it("works with ifnull", () => {
				result = g.model("post").sum(property = "views", where = "id=0", ifNull = 0)

				expect(result).toBe(0)
			})

			it("works with include soft deletes", () => {
				transaction action="begin" {
					post = g.model("Post").deleteAll(transaction = "none")
					sum = g.model("Post").sum(property = "views", includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(sum).toBe(15)
			})
		})
	}
}