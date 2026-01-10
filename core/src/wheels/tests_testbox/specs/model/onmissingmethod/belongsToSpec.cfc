component extends="wheels.Testbox" {

	function beforeAll() {
		profileModel = g.model("profile")
		combiKeyModel = g.model("combiKey")
	}

	function run() {

		g = application.wo

		describe("Tests that hasObject", () => {

			it("is valid", () => {
				profile = profileModel.findByKey(key = 1)
				hasAuthor = profile.hasAuthor()

				expect(hasAuthor).toBeTrue()
			})

			it("is valid with combi key", () => {
				combikey = combiKeyModel.findByKey(key = "1,1")
				hasUser = combikey.hasUser()

				expect(hasUser).toBeTrue()
			})

			it("returns false", () => {
				profile = profileModel.findByKey(key = 2)
				hasAuthor = profile.hasAuthor()

				expect(hasAuthor).toBeFalse()
			})
		})

		describe("Tests that object", () => {

			it("is valid", () => {
				profile = profileModel.findByKey(key = 1)
				author = profile.author()

				expect(author).toBeInstanceOf("author")
			})

			it("is valid with combi key", () => {
				combikey = combiKeyModel.findByKey(key = "1,1")
				user = combikey.user()

				expect(user).toBeInstanceOf("user")
			})

			it("returns false", () => {
				profile = profileModel.findByKey(key = 2)
				author = profile.author()

				expect(author).notToBeInstanceOf("author")
			})
		})
	}
}