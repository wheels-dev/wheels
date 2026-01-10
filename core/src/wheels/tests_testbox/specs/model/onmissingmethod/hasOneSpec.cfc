component extends="wheels.Testbox" {

	function beforeAll() {
		authorModel = g.model("author")
		userModel = g.model("user")
	}

	function run() {

		g = application.wo

		describe("Tests that createObject", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'James'")

				transaction action="begin" {
					profile = author.createProfile(dateOfBirth = "1/1/1970", bio = "Some profile.")

					expect(profile).toBeInstanceOf("profile")
					expect(profile.authorid).toBe(author.id)

					transaction action="rollback";
				}
			})
		})

		describe("Tests that deleteObject", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")

				transaction action="begin" {
					updated = author.deleteProfile()
					profile = author.profile()

					expect(updated).toBeTrue()
					expect(profile).toBeFalse()

					transaction action="rollback";
				}
			})
		})

		describe("Tests that hasObject", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")
				hasProfile = author.hasProfile()

				expect(hasProfile).toBeTrue()
			})

			it("is valid with combi key", () => {
				user = userModel.findByKey(key = 1)
				hasCombiKey = user.hasCombiKey()

				expect(hasCombiKey).toBeTrue()
			})

			it("returns false", () => {
				author = authorModel.findOne(where = "firstName = 'James'")
				hasProfile = author.hasProfile()

				expect(hasProfile).toBeFalse()
			})
		})

		describe("Tests that newObject", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'James'")
				profile = author.newProfile()

				expect(profile).toBeInstanceOf("profile")
				expect(profile.authorid).toBe(author.id)
			})
		})

		describe("Tests that object", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")
				profile = author.profile()

				expect(profile).toBeInstanceOf("profile")
			})

			it("is valid with combi key", () => {
				user = userModel.findByKey(key = 1)
				combiKey = user.combiKey()

				expect(combiKey).toBeInstanceOf("combiKey")
			})

			it("returns false", () => {
				author = authorModel.findOne(where = "firstName = 'James'")
				profile = author.profile()

				expect(profile).notToBeInstanceOf("profile")
			})
		})

		describe("Tests that removeObject", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'Per'")
				profile = author.profile()

				transaction action="begin" {
					updated = author.removeProfile()
					profile.reload()

					expect(updated).toBeTrue()
					expect(profile.authorid).toBeEmpty()

					transaction action="rollback";
				}
			})
		})

		describe("Tests that setObject", () => {

			it("is valid", () => {
				author = authorModel.findOne(where = "firstName = 'James'")
				profile = g.model("profile").findOne();

				transaction action="begin" {
					updated = author.setProfile(profile)

					expect(updated).toBeTrue()
					expect(profile.authorid).toBe(author.id)

					transaction action="rollback";
				}
			})
		})
	}
}