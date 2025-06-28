component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that $objectFileName", () => {

			it("returns model class name in same case as file wo expandpath", () => {
				actual = g.$objectFileName(name = "PhotoGallery", objectPath = "/wheels/core_tests/_assets/models/", type = "model")

				expect(actual).toBe("PhotoGallery")
			})

			it("$fileExistsNoCase returns filename", () => {
				actual = g.$fileExistsNoCase(ExpandPath("/wheels/core_tests/_assets/models/") & "PhotoGallery.cfc")

				expect(actual).toBe("PhotoGallery.cfc")
			})
		})


		describe("Tests that composite", () => {

			it("associates with a single key", () => {
				shops = g.model("shop").findone(include = "city")

				expect(shops).toBeInstanceOf("shop")
			})
		})

		describe("Tests that objectid", () => {

			it("should be sequential and norepeating", () => {
				photos = []
				s = {}
				for (i = 1; i lte 30; i++) {
					ArrayAppend(photos, g.model("photo").new())
				}
				gallery = g.model("gallery").new(photos = photos)
				for (i in gallery.photos) {
					s[i.$objectid()] = ""
				}

				expect(s).toHaveLength(30)
			})
		})

		describe("Tests that primaryKeys", () => {

			it("returns key", () => {
				author = g.model("author")
				e = author.$classData().keys
				r = "id"

				expect(e).toBe(r)

				r = author.primaryKey()

				expect(e).toBe(r)

				r = author.primaryKeys()

				expect(e).toBe(r)
			})

			it("function setPrimaryKey appends keys", () => {
				author = g.model("author")
				author = Duplicate(author)
				e = author.$classData().keys
				r = "id"

				expect(e).toBe(r)

				author.setprimaryKeys("id2,id3")
				e = "id,id2,id3"
				r = author.primaryKeys()

				expect(e).toBe(r)
			})

			it("function setPrimaryKey does not append duplicate keys", () => {
				author = g.model("author")
				author = Duplicate(author)
				e = author.$classData().keys
				r = "id"

				expect(e).toBe(r)

				author.setprimaryKeys("id2")
				author.setprimaryKeys("id2")
				e = "id,id2"
				r = author.primaryKeys()

				expect(e).toBe(r)
			})

			it("retrieve primary key by position", () => {
				author = g.model("author")
				author = Duplicate(author)
				author.setprimaryKeys("id2,id3")
				e = author.primaryKeys(1)

				expect(e).toBe("id")

				e = author.primaryKeys(2)

				expect(e).toBe("id2")
			})
		})

		describe("Tests that setPagination", () => {

			beforeEach(() => {
				user = g.model("user")
			})

			it("works with totalRecords", () => {
				g.setPagination(100)
				assert_pagination(handle = "query", totalRecords = 100)
			})

			it("works with all arguments", () => {
				g.setPagination(1000, 4, 50, "pageTest")
				assert_pagination(handle = "pageTest", totalRecords = 1000, currentPage = 4, perPage = 50)
			})

			it("works with totalRecords less than zero", () => {
				g.setPagination(-5, 4, 50, "pageTest")
				assert_pagination(handle = "pageTest", totalRecords = 0, currentPage = 1, perPage = 50)
			})

			it("works with currentPage less than zero", () => {
				g.setPagination(1000, -4, 50, "pageTest")
				assert_pagination(handle = "pageTest", totalRecords = 1000, currentPage = 1, perPage = 50)
			})

			it("numeric arguments must be integers", () => {
				g.setPagination(1000.9998, 5.876, 50.847, "pageTest")
				assert_pagination(handle = "pageTest", totalRecords = 1000, currentPage = 5, perPage = 50)
			})
		})

		describe("Tests that tableName", () => {

			it("works", () => {
				user = g.model("user2")
				expect(user.tableName()).toBe("_c_o_r_e_tblusers")
			})

			it("works in finders - fixes issue 667", () => {
				users = g.model("user2").findAll(select = "id")
				expect(users.recordcount).toBe(3)
			})
		})
	}

	function assert_pagination(required string handle) {
		args = arguments

		expect(request.wheels).toHaveKey(args.handle)

		p = request.wheels[args.handle]
		StructDelete(args, "handle", false)

		for (i in args) {
			expect(p[i]).toBe(args[i])
		}
	}
}
