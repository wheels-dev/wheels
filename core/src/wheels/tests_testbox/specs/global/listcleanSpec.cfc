component extends="wheels.Testbox" {

	function run() {

		describe("Tests that $listclean", () => {

			it("cleans default delimeter", () => {
				mylist = "tony,    per   ,  james    ,,, chris   , raul ,,,,  peter"
				e = "tony,per,james,chris,raul,peter"

				expect(application.wo.$listClean(mylist)).toBe(e)
			})

			it("cleans provided delimeter", () => {
				mylist = "tony|    per   |  james    | chris   | raul |||  peter"
				e = "tony|per|james|chris|raul|peter"

				expect(application.wo.$listClean(mylist, "|")).toBe(e)
			})

			it("cleans and returns array", () => {
				mylist = "tony,    per   ,  james    ,,, chris   , raul ,,,,  peter"

				expect(application.wo.$listClean(list = mylist, returnAs = "array")).toBeArray()
				expect(application.wo.$listClean(list = mylist, returnAs = "array")).toHaveLength(6)
			})
		})
	}
}