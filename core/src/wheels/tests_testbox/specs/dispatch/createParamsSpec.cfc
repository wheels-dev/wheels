component extends="wheels.Testbox" {

	function run() {

		describe("Tests that createParams", () => {

			beforeEach(() => {
				dispatch = CreateObject("component", "wheels.Dispatch")
				args = {}
				args.path = "home"
				args.format = ""
				args.route = {
					pattern = "/",
					controller = "wheels",
					action = "wheels",
					regex = "^\/?$",
					variables = "",
					on = "",
					package = "",
					methods = "get",
					name = "root"
				}
				args.formScope = {}
				args.urlScope = {}
			})

			it("defaults day to 1", () => {
				args.formScope["obj[published]($month)"] = 2
				args.formScope["obj[published]($year)"] = 2000
				_params = dispatch.$createParams(argumentCollection = args)
				e = _params.obj.published
				r = CreateDateTime(2000, 2, 1, 0, 0, 0)

				expect(datecompare(r, e)).toBe(0)
			})

			it("defaults month to 1", () => {
				args.formScope["obj[published]($day)"] = 30
				args.formScope["obj[published]($year)"] = 2000
				_params = dispatch.$createParams(argumentCollection = args)
				e = _params.obj.published
				r = CreateDateTime(2000, 1, 30, 0, 0, 0)

				expect(datecompare(r, e)).toBe(0)
			})

			it("defaults year to 1899", () => {
				args.formScope["obj[published]($year)"] = 1899
				_params = dispatch.$createParams(argumentCollection = args)
				e = _params.obj.published
				r = CreateDateTime(1899, 1, 1, 0, 0, 0)

				expect(datecompare(r, e)).toBe(0)
			})

			it("checks that URL and FORM scope map the same", () => {
				StructInsert(args.urlScope, "user[email]", "tpetruzzi@gmail.com", true)
				StructInsert(args.urlScope, "user[name]", "tony petruzzi", true)
				StructInsert(args.urlScope, "user[password]", "secret", true)
				args.formScope = {}
				url_params = dispatch.$createParams(argumentCollection = args)
				args.formScope = Duplicate(args.urlScope)
				args.urlScope = {}
				form_params = dispatch.$createParams(argumentCollection = args)

				expect(url_params.toString()).toBe(form_params.toString())
			})

			it("checks that URL overrides form", () => {
				StructInsert(args.urlScope, "user[email]", "per.djurner@gmail.com", true)
				StructInsert(args.formScope, "user[email]", "tpetruzzi@gmail.com", true)
				StructInsert(args.formScope, "user[name]", "tony petruzzi", true)
				StructInsert(args.formScope, "user[password]", "secret", true)
				_params = dispatch.$createParams(argumentCollection = args)
				e = {}
				e.email = "per.djurner@gmail.com"
				e.name = "tony petruzzi"
				e.password = "secret"

				for (i in _params.user) {
					actual = _params.user[i]
					expected = e[i]

					expect(e).toHaveKey(i)
					expect(_params.user[i]).toBe(e[i])
				}
			})

			it("does not overwrite FORM scope", () => {
				args.formScope["obj[published]($month)"] = 2
				_params = dispatch.$createParams(argumentCollection = args)
				exists = StructKeyExists(args.formScope, "obj[published]($month)")

				expect(exists).toBeTrue()
			})

			it("does not overwrite URL scope", () => {
				StructInsert(args.urlScope, "user[email]", "tpetruzzi@gmail.com", true)
				_params = dispatch.$createParams(argumentCollection = args)
				exists = StructKeyExists(args.urlScope, "user[email]")

				expect(exists).toBeTrue()
			})

			it("creates multiple objects with checkbox", () => {
				StructInsert(args.urlScope, "user[1][isActive]($checkbox)", "0", true)
				StructInsert(args.urlScope, "user[1][isActive]", "1", true)
				StructInsert(args.urlScope, "user[2][isActive]($checkbox)", "0", true)
				_params = dispatch.$createParams(argumentCollection = args)

				expect(_params.user["1"].isActive).toBe(1)
				expect(_params.user["2"].isActive).toBe(0)
			})

			it("creates multiple objects in objects", () => {
				args.formScope["user"]["1"]["config"]["1"]["isValid"] = true
				args.formScope["user"]["1"]["config"]["2"]["isValid"] = false
				_params = dispatch.$createParams(argumentCollection = args)

				expect(_params.user).toBeStruct()
				expect(_params.user[1]).toBeStruct()
				expect(_params.user[1].config).toBeStruct()
				expect(_params.user[1].config[1]).toBeStruct()
				expect(_params.user[1].config[2]).toBeStruct()
				expect(_params.user[1].config[1].isValid).toBeBoolean()
				expect(_params.user[1].config[2].isValid).toBeBoolean()
				expect(_params.user[1].config[1].isValid).toBeTrue()
				expect(_params.user[1].config[2].isValid).toBeFalse()
			})

			it("does not combine dates", () => {
				args.formScope["obj[published-day]"] = 30
				args.formScope["obj[published-year]"] = 2000
				_params = dispatch.$createParams(argumentCollection = args)

				expect(_params.obj).toHaveKey("published-day")
				expect(_params.obj).toHaveKey("published-year")
				expect(_params.obj["published-day"]).toBe(30)
				expect(_params.obj["published-year"]).toBe(2000)
			})

			it("sets controller in upper camel case", () => {
				args.formScope["controller"] = "wheels-test"
				_params = dispatch.$createParams(argumentCollection = args)

				expect(_params.controller).toBeWithCase("WheelsTest")

				args.formScope["controller"] = "wheels"
				_params = dispatch.$createParams(argumentCollection = args)
				
				expect(_params.controller).toBeWithCase("Wheels")
			})

			it("sanitizes controller and action params", () => {
				args.formScope["controller"] = "../../../wheels%00"
				args.formScope["action"] = "../../../test*^&%()%00"
				_params = dispatch.$createParams(argumentCollection = args)

				expect(_params.controller).toBe("......Wheels00")
				expect(_params.action).toBe("......test00")
			})
		})
	}
}