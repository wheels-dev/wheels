component extends="testbox.system.BaseSpec" {

	function run() {

		describe("Tests that ValidatesLengthOf", () => {

			beforeEach(() => {
				args = {
					property = "lastName",
					message = "[property] is the wrong length",
					exactly = 0,
					maximum = 0,
					minimum = 0,
					within = ""
				}
				object = application.wo.model("user").new()
			})

			it("validates maximum good", () => {
				object.lastName = "LessThan"
				object.$validatesLengthOf(argumentCollection = args, maximum = 10)

				expect(object.hasErrors()).toBeFalse()
			})

			it("validates maximum bad", () => {
				object.lastName = "SomethingMoreThanTenLetters"
				object.$validatesLengthOf(argumentCollection = args, maximum = 10)

				expect(object.hasErrors()).toBeTrue()
			})

			it("validates minimum good", () => {
				object.lastName = "SomethingMoreThanTenLetters"
				object.$validatesLengthOf(argumentCollection = args, minimum = 10)

				expect(object.hasErrors()).toBeFalse()
			})

			it("validates minimum bad", () => {
				object.lastName = "LessThan"
				object.$validatesLengthOf(argumentCollection = args, minimum = 10)

				expect(object.hasErrors()).toBeTrue()
			})

			it("validates within good", () => {
				object.lastName = "6Chars"
				within = [4, 8]
				object.$validatesLengthOf(argumentCollection = args, within = within)

				expect(object.hasErrors()).toBeFalse()
			})

			it("validates within bad", () => {
				object.lastName = "6Chars"
				within = [2, 5]
				object.$validatesLengthOf(argumentCollection = args, within = within)

				expect(object.hasErrors()).toBeTrue()
			})
			
			it("validates exactly good", () => {
				object.lastName = "Exactly14Chars"
				object.$validatesLengthOf(argumentCollection = args, exactly = 14)

				expect(object.hasErrors()).toBeFalse()
			})
			
			it("validates exactly bad", () => {
				object.lastName = "Exactly14Chars"
				object.$validatesLengthOf(argumentCollection = args, exactly = 99)

				expect(object.hasErrors()).toBeTrue()
			})
		})
	}
}