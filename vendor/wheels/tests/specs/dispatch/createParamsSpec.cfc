component extends="wheels.WheelsTest" {

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

			it("S1 HOLD: omits year when $year is absent and defaults to 1899", () => {
				// HOLD: do not flip the default year. The existing "defaults year
				// to 1899" case was a tautology ($year=1899, expect 1899). This
				// one omits $year and still expects 1899, matching
				// $translateDatePartSubmissions.
				args.formScope["obj[published]($month)"] = 3
				args.formScope["obj[published]($day)"] = 15
				_params = dispatch.$createParams(argumentCollection = args)
				e = _params.obj.published
				r = CreateDateTime(1899, 3, 15, 0, 0, 0)

				expect(datecompare(r, e)).toBe(0)
			})

			it("removes the ($ampm) part key after combining date parts", () => {
				args.formScope["published($year)"] = 2000
				args.formScope["published($month)"] = 2
				args.formScope["published($day)"] = 15
				args.formScope["published($hour)"] = 3
				args.formScope["published($minute)"] = 30
				args.formScope["published($ampm)"] = "PM"
				_params = dispatch.$createParams(argumentCollection = args)

				expect(_params).notToHaveKey("published($ampm)")
				expect(datecompare(CreateDateTime(2000, 2, 15, 15, 30, 0), _params.published)).toBe(0)
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

				expect(args.formScope).toHaveKey("obj[published]($month)")
				expect(args.formScope["obj[published]($month)"]).toBe(2)
			})

			it("does not overwrite URL scope", () => {
				StructInsert(args.urlScope, "user[email]", "tpetruzzi@gmail.com", true)
				_params = dispatch.$createParams(argumentCollection = args)

				expect(args.urlScope).toHaveKey("user[email]")
				expect(args.urlScope["user[email]"]).toBe("tpetruzzi@gmail.com")
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
				// Wildcard-style route: no fixed controller, so the incoming
				// name is the value that gets camelized (B1: a routed
				// controller name is no longer overridable from the form).
				args.route.pattern = "/[controller]"
				StructDelete(args.route, "controller")
				args.formScope["controller"] = "wheels-test"
				_params = dispatch.$createParams(argumentCollection = args)

				expect(_params.controller).toBeWithCase("WheelsTest")

				args.formScope["controller"] = "wheels"
				_params = dispatch.$createParams(argumentCollection = args)
				
				expect(_params.controller).toBeWithCase("Wheels")
			})

			it("sanitizes controller and action params", () => {
				args.route.pattern = "/[controller]/[action]"
				StructDelete(args.route, "controller")
				StructDelete(args.route, "action")
				args.formScope["controller"] = "../../../wheels%00"
				args.formScope["action"] = "../../../test*^&%()%00"
				_params = dispatch.$createParams(argumentCollection = args)

				expect(_params.controller).toBe("......Wheels00")
				expect(_params.action).toBe("......test00")
			})
		})
	}
}