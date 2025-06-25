component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that DateSelect", () => {

			beforeEach(() => {
				_controller = g.controller(name = "ControllerWithModel")
				args = {}
				args.objectName = "user"
				args.label = false
				g.set(functionName = "dateSelect", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "dateSelect", encode = true)
			})

			it("is parsing and passing month", () => {
				args.property = "birthday"
				args.order = "month"

				e = dateSelect_month_str(args.property)
				r = _controller.dateSelect(argumentcollection = args)

				expect(e).toBe(r)

				args.property = "birthdaymonth"
				e = dateSelect_month_str(args.property)
				r = _controller.dateSelect(argumentcollection = args)
				expect(e).toBe(r)
			})

			it("is parsing and passing year", () => {
				args.property = "birthday"
				args.order = "year"
				args.startyear = "1973"
				args.endyear = "1976"
				e = dateSelect_year_str(args.property)
				r = _controller.dateSelect(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("is working when year is less than startyear", () => {
				args.property = "birthday"
				args.order = "year"
				args.startyear = "1976"
				args.endyear = "1980"
				e = '<select id="user-birthday-year" name="user[birthday]($year)"><option selected="selected" value="1975">1975</option><option value="1976">1976</option><option value="1977">1977</option><option value="1978">1978</option><option value="1979">1979</option><option value="1980">1980</option></select>'
				r = _controller.dateSelect(argumentcollection = args)
				
				expect(e).toBe(r)
			})
		})

		describe("Tests that DateTimeSelect", () => {

			beforeEach(() => {
				_controller = g.controller(name = "ControllerWithModel")
				args = {}
				args.objectName = "user"
				args.label = false
				selected = {}
				selected.month = '<option selected="selected" value="11">November</option>'
				selected.day = '<option selected="selected" value="1">1</option>'
				selected.year = '<option selected="selected" value="1975">1975</option>'
				g.set(functionName = "dateTimeSelect", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "dateTimeSelect", encode = true)
			})

			it("is splitting labels", () => {
				result = _controller.dateTimeSelect(
					objectName = "user",
					property = "birthday",
					label = "labelMonth,labelDay,labelYear,labelHour,labelMinute,labelSecond"
				)

				expect(result).toInclude("labelDay")
				expect(result).toInclude("labelSecond")
			})

			it("is working", () => {
				args.property = "birthday"
				r = _controller.dateTimeSelect(argumentcollection = args)

				expect(r).toInclude(selected.month)
				expect(r).toInclude(selected.day)
				expect(r).toInclude(selected.year)
			})

			it("is working when not combined", () => {
				args.property = "birthday"
				args.combine = "false"
				r = _controller.dateTimeSelect(argumentcollection = args)

				expect(r).toInclude(selected.month)
				expect(r).toInclude(selected.day)
				expect(r).toInclude(selected.year)
			})

			it("is splitting label classes", () => {
				labelClass = "month,day,year"
				r = _controller.dateTimeSelect(
					objectName = "user",
					property = "birthday",
					label = "labelMonth,labelDay,labelYear",
					labelClass = "#labelClass#"
				)

				for (i in ListToArray(labelClass)) {
					e = 'label class="#i#"'

					expect(r).toInclude(e)
				}
			})

			it("ampm selecting coming is displayed twice", () => {
				r = _controller.dateTimeSelect(
					objectName = 'user',
					property = 'birthday',
					dateOrder = 'month,day,year',
					monthDisplay = 'abbreviations',
					twelveHour = 'true',
					label = ''
				)
				a = ReMatchNoCase("user\[birthday\]\(\$ampm\)", r)

				expect(a).toHaveLength(1)
			})
		})

		describe("Tests that TimeSelect", () => {
			// There is only one test the original TimeSelect.cfc but it is only asserting 1 to be 1 so it doesn't make sense to write here
		})
	}

	function dateSelect_month_str(required string property) {
		return '<select id="user-#arguments.property#-month" name="user[#arguments.property#]($month)"><option value="1">January</option><option value="2">February</option><option value="3">March</option><option value="4">April</option><option value="5">May</option><option value="6">June</option><option value="7">July</option><option value="8">August</option><option value="9">September</option><option value="10">October</option><option selected="selected" value="11">November</option><option value="12">December</option></select>'
	}

	function dateSelect_year_str(required string property) {
		return '<select id="user-#arguments.property#-year" name="user[#arguments.property#]($year)"><option value="1973">1973</option><option value="1974">1974</option><option selected="selected" value="1975">1975</option><option value="1976">1976</option></select>'
	}
}