component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that associatedErrors", () => {

			it("returns array including associated model errors", () => {
				user = g.model("user").findOne()
				user.addError("firstname", "firstname error1")
				user.author = g.model("author").findOne(include = "profile")
				user.author.addError("lastname", "lastname error1")
				errors = user.allErrors(includeAssociations = true)

				expect(errors).toHaveLength(2)
			})

			it("returns array including associated model errors deeply", () => {
				user = g.model("user").findOne()
				user.addError("firstname", "firstname error1")
				user.author = g.model("author").findOne(include = "profile")
				user.author.addError("lastname", "lastname error1")
				user.author.profile.addError("profiletype", "profiletype error1")
				errors = user.allErrors(includeAssociations = true)

				expect(errors).toHaveLength(3)
			})

			it("returns array including associated model errors and handles circular reference", () => {
				user = g.model("user").findOne()
				user.addError("firstname", "firstname error1")
				user.author = g.model("author").findOne(include = "profile")
				user.author.addError("lastname", "lastname error1")
				user.author.profile.addError("profiletype", "profiletype error1")
				user.author.profile.$classData().associations.author.nested.allow = true
				user.author.profile.$classData().associations.author.nested.autoSave = true
				user.author.profile.author = user.author
				errors = user.allErrors(includeAssociations = true)

				expect(errors).toHaveLength(3)
			})
		})

		describe("Tests that errors", () => {

			beforeEach(() => {
				user = g.model("user").findOne()
				user.addErrorToBase(message = "base error1")
				user.addErrorToBase(message = "base name error1", name = "base_errors")
				user.addErrorToBase(message = "base name error2", name = "base_errors")
				user.addError(property = "firstname", message = "firstname error1")
				user.addError(property = "firstname", message = "firstname error2")
				user.addError(property = "firstname", message = "firstname name error1", name = "firstname_errors")
				user.addError(property = "firstname", message = "firstname name error2", name = "firstname_errors")
				user.addError(property = "firstname", message = "firstname name error3", name = "firstname_errors")
				user.addError(property = "lastname", message = "lastname error1")
				user.addError(property = "lastname", message = "lastname error2")
				user.addError(property = "lastname", message = "lastname error3")
				user.addError(property = "lastname", message = "lastname name error1", name = "lastname_errors")
				user.addError(property = "lastname", message = "lastname name error2", name = "lastname_errors")
			})

			it("give error information for lastname property no name provided", () => {
				r = user.hasErrors(property = "lastname")

				expect(r).toBeTrue()

				r = user.errorCount(property = "lastname")

				expect(r).toBe(5)

				r = user.errorCount(property = "lastname", name = 'lastname_errors')

				expect(r).toBe(2)

				user.clearErrors(property = "lastname")
				r = user.errorCount(property = "lastname")

				expect(r).toBe(0)

				r = user.hasErrors()

				expect(r).toBeTrue()

				r = user.hasErrors(property = "lastname")

				expect(r).toBeFalse()

				r = user.hasErrors(property = "lastname", name = "lastname_errors")

				expect(r).toBeFalse()
			})

			it("give error information for lastname property name provided", () => {
				r = user.hasErrors(property = "lastname", name = "lastname_errors")

				expect(r).toBeTrue()

				r = user.errorCount(property = "lastname", name = "lastname_errors")

				expect(r).toBe(2)

				user.clearErrors(property = "lastname", name = "lastname_errors")
				r = user.errorCount(property = "lastname", name = "lastname_errors")

				expect(r).toBe(0)

				r = user.hasErrors()

				expect(r).toBeTrue()

				r = user.hasErrors(property = "lastname", name = "lastname_errors")

				expect(r).toBeFalse()

				r = user.hasErrors(property = "lastname")

				expect(r).toBeTrue()
			})

			it("give error information for firstname property no name provided", () => {
				r = user.hasErrors(property = "firstname")

				expect(r).toBeTrue()

				r = user.errorCount(property = "firstname")

				expect(r).toBe(5)

				user.clearErrors(property = "firstname")
				r = user.errorCount(property = "firstname")

				expect(r).toBe(0)

				r = user.hasErrors()

				expect(r).toBeTrue()

				r = user.hasErrors(property = "firstname")

				expect(r).toBeFalse()

				r = user.hasErrors(property = "firstname", name = "firstname_errors")

				expect(r).toBeFalse()
			})

			it("give error information for firstname property name provided", () => {
				r = user.hasErrors(property = "firstname", name = "firstname_errors")

				expect(r).toBeTrue()

				r = user.errorCount(property = "firstname", name = "firstname_errors")

				expect(r).toBe(3)

				user.clearErrors(property = "firstname", name = "firstname_errors")
				r = user.errorCount(property = "firstname", name = "firstname_errors")

				expect(r).toBe(0)

				r = user.hasErrors()

				expect(r).toBeTrue()

				r = user.hasErrors(property = "firstname", name = "firstname_errors")

				expect(r).toBeFalse()

				r = user.hasErrors(property = "firstname")

				expect(r).toBeTrue()
			})

			it("give error information for base no name provided", () => {
				r = user.hasErrors()

				expect(r).toBeTrue()

				r = user.errorCount()

				expect(r).toBe(13)

				user.clearErrors()
				r = user.errorCount()

				expect(r).toBe(0)

				r = user.hasErrors()

				expect(r).toBeFalse()

				r = user.hasErrors(property = "lastname")

				expect(r).toBeFalse()

				r = user.hasErrors(property = "lastname", name = "lastname_errors")

				expect(r).toBeFalse()

				r = user.hasErrors(property = "firstname")

				expect(r).toBeFalse()

				r = user.hasErrors(property = "firstname", name = "firstname_errors")

				expect(r).toBeFalse()
			})

			it("give error information for base name provided", () => {
				r = user.hasErrors(name = "base_errors")

				expect(r).toBeTrue()

				r = user.errorCount(name = "base_errors")

				expect(r).toBe(2)

				user.clearErrors(name = "base_errors")

				r = user.errorCount(name = "base_errors")

				expect(r).toBe(0)

				r = user.hasErrors(name = "base_errors")

				expect(r).toBeFalse()

				r = user.hasErrors(property = "lastname")

				expect(r).toBeTrue()

				r = user.hasErrors(property = "lastname", name = "lastname_errors")

				expect(r).toBeTrue()

				r = user.hasErrors(property = "firstname")

				expect(r).toBeTrue()

				r = user.hasErrors(property = "firstname", name = "firstname_errors")

				expect(r).toBeTrue()
			})

			it("give error information for incorrect property", () => {
				r = user.hasErrors(property = "firstnamex")

				expect(r).toBeFalse()

				r = user.errorCount(property = "firstnamex")

				expect(r).toBe(0)

				user.clearErrors(property = "firstnamex")
				r = user.hasErrors()

				expect(r).toBeTrue()

				r = user.hasErrors(property = "firstname")

				expect(r).toBeTrue()

				r = user.hasErrors(property = "firstname", name = "firstname_errors")

				expect(r).toBeTrue()
			})

			it("give error information for incorrect name on propery", () => {
				r = user.hasErrors(property = "firstname", name = "firstname_errorsx")

				expect(r).toBeFalse()

				r = user.errorCount(property = "firstname", name = "firstname_errorsx")

				expect(r).toBe(0)

				user.clearErrors(property = "firstname", name = "firstname_errorsx")
				r = user.hasErrors()

				expect(r).toBeTrue()

				r = user.hasErrors(property = "firstname", name = "firstname_errors")

				expect(r).toBeTrue()

				r = user.hasErrors(property = "firstname")

				expect(r).toBeTrue()
			})

			it("give error information for incorrect name on base", () => {
				r = user.hasErrors(name = "base_errorsx")

				expect(r).toBeFalse()

				r = user.errorCount(name = "base_errorsx")

				expect(r).toBe(0)

				user.clearErrors(name = "base_errorsx")
				r = user.hasErrors(name = "base_errors")

				expect(r).toBeTrue()

				r = user.hasErrors(property = "lastname")

				expect(r).toBeTrue()

				r = user.hasErrors(property = "lastname", name = "lastname_errors")

				expect(r).toBeTrue()

				r = user.hasErrors(property = "firstname")

				expect(r).toBeTrue()

				r = user.hasErrors(property = "firstname", name = "firstname_errors")

				expect(r).toBeTrue()

			})
		})
	}
}
