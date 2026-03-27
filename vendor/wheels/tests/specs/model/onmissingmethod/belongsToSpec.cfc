component extends="wheels.WheelsTest" {

	function beforeAll() {
		profileModel = g.model("profile")
		combiKeyModel = g.model("combiKey")
	}

	function run() {

		g = application.wo

		describe("Tests that hasObject", () => {

			it("is valid", () => {
				profile = profileModel.findOne(order = "id")
				hasAuthor = profile.hasAuthor()

				expect(hasAuthor).toBeTrue()
			})

			it("is valid with combi key", () => {
				combikey = combiKeyModel.findOne(order = "id1,id2")
				hasUser = combikey.hasUser()

				expect(hasUser).toBeTrue()
			})

			it("returns false", () => {
				profile = profileModel.findOne(where = "authorid IS NULL")
				hasAuthor = profile.hasAuthor()

				expect(hasAuthor).toBeFalse()
			})
		})

		describe("Tests that object", () => {

			it("is valid", () => {
				profile = profileModel.findOne(order = "id")
				author = profile.author()

				expect(author).toBeInstanceOf("author")
			})

			it("is valid with combi key", () => {
				combikey = combiKeyModel.findOne(order = "id1,id2")
				user = combikey.user()

				expect(user).toBeInstanceOf("user")
			})

			it("returns false", () => {
				profile = profileModel.findOne(where = "authorid IS NULL")
				author = profile.author()

				expect(author).notToBeInstanceOf("author")
			})
		})
	}
}