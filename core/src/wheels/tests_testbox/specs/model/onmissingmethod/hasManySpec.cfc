component extends="wheels.Testbox" {

	function beforeAll() {
		authorModel = g.model("author")
		userModel = g.model("user")
	}

	function run() {

		g = application.wo

		describe("Tests that addObject", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'James'")
				post = g.model("post").findOne()

				transaction action="begin" {
					updated = author.addPost(post)

					expect(updated).toBeTrue()
					expect(post.authorid).toBe(author.id)

					transaction action="rollback";
				}
			})
		})

		describe("Tests that createObject", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'James'")

				transaction action="begin" {
					post = author.createPost(title = "Title for first test post", body = "Text for first test post", views = 0)

					expect(post).toBeInstanceOf("post")
					expect(post.authorid).toBe(author.id)

					transaction action="rollback";
				}
			})
		})

		describe("Tests that deleteAllObjects", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")

				transaction action="begin" {
					updated = author.deleteAllPosts()
					posts = author.posts()

					expect(updated).toBeTypeOf("numeric")
					expect(updated).toBe(3)
					expect(posts).toBeTypeOf("query")
					expect(posts.recordcount).toBe(0)

					transaction action="rollback";
				}
			})
		})

		describe("Tests that deleteObject", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")
				post = author.findOnePost(order = "id")

				transaction action="begin" {
					updated = author.deletePost(post)
					post = g.model("post").findByKey(key = post.id)

					expect(updated).toBeTrue()
					expect(post).notToBeInstanceOf("post")
					expect(post).toBeFalse()

					transaction action="rollback";
				}
			})
		})

		describe("Tests that findOneObject", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")
				post = author.findOnePost(order = "id")

				expect(post).toBeInstanceOf("post")
			})
		})

		describe("Tests that hasObjects", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")
				hasPosts = author.hasPosts()

				expect(hasPosts).toBeTrue()
			})

			it("is valid with combi key", () => {
				user = userModel.findByKey(key = 1)
				hasCombiKeys = user.hasCombiKeys()

				expect(hasCombiKeys).toBeTrue()
			})

			it("returns false", () => {
				author = authorModel.findOne(where = "firstName = 'James'")
				hasPosts = author.hasPosts()

				expect(hasPosts).toBeFalse()
			})
		})

		describe("Tests that newObject", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'James'")
				post = author.newPost()

				expect(post).toBeInstanceOf("post")
				expect(post.authorid).toBe(author.id)
			})
		})

		describe("Tests that objectCount", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")
				postCount = author.postCount()

				expect(postCount).toBe(3)
			})

			it("is valid with combi key", () => {
				user = userModel.findByKey(key = 1)
				combiKeyCount = user.combiKeyCount()

				expect(combiKeyCount).toBe(5)
			})

			it("returns zero", () => {
				author = authorModel.findOne(where = "firstName = 'James'")
				postCount = author.postCount()

				expect(postCount).toBe(0)
			})
		})

		describe("Tests that objects", () => {

			it("returns query", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")
				posts = author.posts()

				expect(posts).toBeTypeOf("query")
				expect(posts.recordcount).toBeGT(0)
			})

			it("is valid with combi key", () => {
				user = userModel.findByKey(key = 1)
				combiKeys = user.combiKeys()

				expect(combiKeys).toBeTypeOf("query")
				expect(combiKeys.recordcount).toBeGT(0)
			})

			it("returns empty query", () => {
				author = authorModel.findOne(where = "firstName = 'James'")
				posts = author.posts()

				expect(posts).toBeTypeOf("query")
				expect(posts.recordcount).toBe(0)
			})

			it("returns pagination with blank where", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")
				posts = author.posts(where = "", page = 1, perPage = 2)

				expect(posts.recordcount).toBe(2)
			})
		})

		describe("Tests that removeAllObjects", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")

				transaction action="begin" {
					updated = author.removeAllPosts()
					posts = author.posts()

					expect(updated).toBeTypeOf("numeric")
					expect(updated).toBe(3)
					expect(posts).toBeTypeOf("query")
					expect(posts.recordcount).toBe(0)

					transaction action="rollback";
				}
			})
		})

		describe("Tests that removeObject", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")
				post = author.findOnePost(order = "id")

				transaction action="begin" {
					updated = author.removePost(post)
					post.reload()

					expect(updated).toBeTrue()
					expect(post.authorid).toBeEmpty()

					transaction action="rollback";
				}
			})
		})
	}
}