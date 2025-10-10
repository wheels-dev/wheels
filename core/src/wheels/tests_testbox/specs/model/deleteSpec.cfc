component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests that delete", () => {

			it("works", () => {
				transaction action="begin" {
					local.author = g.model("author").findOne()
					local.author.delete()
					allAuthors = g.model("author").findAll()
					transaction action="rollback";
				}

				expect(allAuthors.recordcount).toBe(9)
			})

			it("soft works", () => {
				transaction action="begin" {
					local.post = g.model("post").findOne()
					local.post.delete()
					postsWithoutSoftDeletes = g.model("post").findAll()
					postsWithSoftDeletes = g.model("post").findAll(includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(postsWithoutSoftDeletes.recordcount).toBe(4)
				expect(postsWithSoftDeletes.recordcount).toBe(5)
			})

			it("permanent works", () => {
				transaction action="begin" {
					local.post = g.model("post").findOne()
					local.post.delete()
					postsWithoutSoftDeletes = g.model("post").findAll()
					postsWithSoftDeletes = g.model("post").findAll(includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(postsWithoutSoftDeletes.recordcount).toBe(4)
				expect(postsWithSoftDeletes.recordcount).toBe(5)
			})

			it("permanent of soft deleted records work", () => {
				transaction action="begin" {
					local.post = g.model("post").findOne()
					local.post.delete()
					local.softDeletedPost = g.model("post").findByKey(key = local.post.id, includeSoftDeletes = true)
					local.softDeletedPost.delete(includeSoftDeletes = true, softDelete = false)
					postsWithoutSoftDeletes = g.model("post").findAll()
					postsWithSoftDeletes = g.model("post").findAll(includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(postsWithoutSoftDeletes.recordcount).toBe(4)
				expect(postsWithSoftDeletes.recordcount).toBe(4)
			})
		})

		describe("Tests that deleteAll", () => {

			it("works", () => {
				transaction action="begin" {
					g.model("author").deleteAll();
					allAuthors = g.model("author").findAll()
					transaction action="rollback";
				}

				expect(allAuthors.recordcount).toBe(0)
			})

			it("soft works", () => {
				transaction action="begin" {
					g.model("post").deleteAll()
					postsWithoutSoftDeletes = g.model("Post").findAll()
					postsWithSoftDeletes = g.model("Post").findAll(includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(postsWithoutSoftDeletes.recordcount).toBe(0)
				expect(postsWithSoftDeletes.recordcount).toBe(5)
			})

			it("permanent works", () => {
				transaction action="begin" {
					g.model("post").deleteAll(softDelete = false)
					postsWithoutSoftDeletes = g.model("Post").findAll()
					postsWithSoftDeletes = g.model("Post").findAll(includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(postsWithoutSoftDeletes.recordcount).toBe(0)
				expect(postsWithSoftDeletes.recordcount).toBe(0)
			})

			it("permanent deletes all of soft deleted records", () => {
				transaction action="begin" {
					g.model("post").deleteAll();
					g.model("post").deleteAll(includeSoftDeletes = true, softDelete = false)
					postsWithoutSoftDeletes = g.model("post").findAll()
					postsWithSoftDeletes = g.model("post").findAll(includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(postsWithoutSoftDeletes.recordcount).toBe(0)
				expect(postsWithSoftDeletes.recordcount).toBe(0)
			})
		})

		describe("Tests that deleteByKey", () => {

			it("works", () => {
				transaction action="begin" {
					local.author = g.model("author").findOne();
					g.model("author").deleteByKey(local.author.id)
					allAuthors = g.model("author").findAll()
					transaction action="rollback";
				}

				expect(allAuthors.recordcount).toBe(9)
			})

			it("soft works", () => {
				transaction action="begin" {
					local.post = g.model("post").findOne();
					g.model("post").deleteByKey(local.post.id)
					postsWithoutSoftDeletes = g.model("post").findAll(includeSoftDeletes = false)
					postsWithSoftDeletes = g.model("post").findAll(includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(postsWithoutSoftDeletes.recordcount).toBe(4)
				expect(postsWithSoftDeletes.recordcount).toBe(5)
			})

			it("permanent works", () => {
				transaction action="begin" {
					local.post = g.model("post").findOne();
					g.model("post").deleteByKey(key = local.post.id, softDelete = false)
					postsWithoutSoftDeletes = g.model("post").findAll()
					postsWithSoftDeletes = g.model("post").findAll(includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(postsWithoutSoftDeletes.recordcount).toBe(4)
				expect(postsWithSoftDeletes.recordcount).toBe(4)
			})
		})

		describe("Tests that deleteOne", () => {

			it("works", () => {
				transaction action="begin" {
					g.model("author").deleteOne();
					allAuthors = g.model("author").findAll()
					transaction action="rollback";
				}

				expect(allAuthors.recordcount).toBe(9)
			})

			it("soft works", () => {
				transaction action="begin" {
					g.model("post").deleteOne();
					postsWithoutSoftDeletes = g.model("post").findAll()
					postsWithSoftDeletes = g.model("post").findAll(includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(postsWithoutSoftDeletes.recordcount).toBe(4)
				expect(postsWithSoftDeletes.recordcount).toBe(5)
			})

			it("permanent works", () => {
				transaction action="begin" {
					g.model("post").deleteOne(softDelete = false);
					postsWithoutSoftDeletes = g.model("post").findAll()
					postsWithSoftDeletes = g.model("post").findAll(includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(postsWithoutSoftDeletes.recordcount).toBe(4)
				expect(postsWithSoftDeletes.recordcount).toBe(4)
			})

			it("permanent deletes one of soft deleted records", () => {
				transaction action="begin" {
					local.post = g.model("post").findOne();
					g.model("post").deleteOne(where = "id = #local.post.id#")
					g.model("post").deleteOne(where = "id = #local.post.id#", includeSoftDeletes = true, softDelete = false)
					postsWithoutSoftDeletes = g.model("post").findAll()
					postsWithSoftDeletes = g.model("post").findAll(includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(postsWithoutSoftDeletes.recordcount).toBe(4)
				expect(postsWithSoftDeletes.recordcount).toBe(4)
			})
		})
	}
}