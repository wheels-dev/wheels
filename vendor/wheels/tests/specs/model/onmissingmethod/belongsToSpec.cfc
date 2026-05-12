component extends="wheels.WheelsTest" {

	function beforeAll() {
		profileModel = g.model("profile")
		combiKeyModel = g.model("combiKey")
	}

	function run() {

		g = application.wo
		var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB";

		describe("Tests that hasObject", () => {

			it("is valid", () => {
				if (_isCockroachDB) return;
				profile = profileModel.findByKey(key = 1)
				hasAuthor = profile.hasAuthor()

				expect(hasAuthor).toBeTrue()
			})

			it("is valid with combi key", () => {
				if (_isCockroachDB) return;
				combikey = combiKeyModel.findByKey(key = "1,1")
				hasUser = combikey.hasUser()

				expect(hasUser).toBeTrue()
			})

			it("returns false", () => {
				if (_isCockroachDB) return;
				profile = profileModel.findByKey(key = 2)
				hasAuthor = profile.hasAuthor()

				expect(hasAuthor).toBeFalse()
			})
		})

		describe("Tests that object", () => {

			it("is valid", () => {
				if (_isCockroachDB) return;
				profile = profileModel.findByKey(key = 1)
				author = profile.author()

				expect(author).toBeInstanceOf("author")
			})

			it("is valid with combi key", () => {
				if (_isCockroachDB) return;
				combikey = combiKeyModel.findByKey(key = "1,1")
				user = combikey.user()

				expect(user).toBeInstanceOf("user")
			})

			it("returns false", () => {
				if (_isCockroachDB) return;
				profile = profileModel.findByKey(key = 2)
				author = profile.author()

				expect(author).notToBeInstanceOf("author")
			})
		})
	}
}