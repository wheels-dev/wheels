component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests that DateSelectTags", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.label = false
				g.set(functionName = "dateSelectTags", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "dateSelectTags", encode = true)
			})

			it("is working with multiple labels", () => {
				args.name = "today"
				args.startyear = "1973"
				args.endyear = "1973"
				args.selected = "09/14/1973"
				args.label = "The Month:,The Day:,The Year:"
				e = '<label for="today-month">The Month:<select id="today-month" name="today($month)"><option value="1">January</option><option value="2">February</option><option value="3">March</option><option value="4">April</option><option value="5">May</option><option value="6">June</option><option value="7">July</option><option value="8">August</option><option selected="selected" value="9">September</option><option value="10">October</option><option value="11">November</option><option value="12">December</option></select></label> <label for="today-day">The Day:<select id="today-day" name="today($day)"><option value="1">1</option><option value="2">2</option><option value="3">3</option><option value="4">4</option><option value="5">5</option><option value="6">6</option><option value="7">7</option><option value="8">8</option><option value="9">9</option><option value="10">10</option><option value="11">11</option><option value="12">12</option><option value="13">13</option><option selected="selected" value="14">14</option><option value="15">15</option><option value="16">16</option><option value="17">17</option><option value="18">18</option><option value="19">19</option><option value="20">20</option><option value="21">21</option><option value="22">22</option><option value="23">23</option><option value="24">24</option><option value="25">25</option><option value="26">26</option><option value="27">27</option><option value="28">28</option><option value="29">29</option><option value="30">30</option><option value="31">31</option></select></label> <label for="today-year">The Year:<select id="today-year" name="today($year)"><option selected="selected" value="1973">1973</option></select></label>'
				r = _controller.dateSelectTags(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works when startyear is greater than endyear", () => {
				args.name = "today"
				args.startyear = "2000"
				args.endyear = "1990"
				args.order = "year"
				e = '<select id="today-year" name="today($year)"><option value="2000">2000</option><option value="1999">1999</option><option value="1998">1998</option><option value="1997">1997</option><option value="1996">1996</option><option value="1995">1995</option><option value="1994">1994</option><option value="1993">1993</option><option value="1992">1992</option><option value="1991">1991</option><option value="1990">1990</option></select>'
				r = _controller.dateSelectTags(argumentcollection = args)
				
				expect(e).toBe(r)
			})

			it("works when endyear is greater than startyear", () => {
				args.name = "today"
				args.startyear = "1990"
				args.endyear = "2000"
				args.order = "year"
				e = '<select id="today-year" name="today($year)"><option value="1990">1990</option><option value="1991">1991</option><option value="1992">1992</option><option value="1993">1993</option><option value="1994">1994</option><option value="1995">1995</option><option value="1996">1996</option><option value="1997">1997</option><option value="1998">1998</option><option value="1999">1999</option><option value="2000">2000</option></select>'
				r = _controller.dateSelectTags(argumentcollection = args)
				
				expect(e).toBe(r)
			})
		})

		describe("Tests that DateTimeSelectTags", () => {

			beforeEach(() => {
				pkg.controller = g.controller("dummy")
				result = ""
				results = {}
				_controller = g.controller(name = "dummy")
				args = {}
				args.label = false
			})

			it("works with no labels", () => {
				result = pkg.controller.dateTimeSelectTags(name = "theName", label = false)

				expect(result).notToInclude("label")
			})

			it("works with same labels", () => {
				str = pkg.controller.dateTimeSelectTags(name = "theName", label = "lblText")
				sub = "lblText"
				result = (Len(str) - Len(Replace(str, sub, "", "all"))) / Len(sub)

				expect(result).toBe(6)
			})

			it("works with splitting labels", () => {
				result = pkg.controller.dateTimeSelectTags(
					name = "theName",
					label = "labelMonth,labelDay,labelYear,labelHour,labelMinute,labelSecond"
				)

				expect(result).toInclude("labelDay")
				expect(result).toInclude("labelSecond")
			})

			it("works with blank included boolean", () => {
				args.name = "dateselector"
				args.includeBlank = "true"
				args.selected = ""
				args.startyear = "2000"
				args.endyear = "1990"
				r = _controller.dateTimeSelectTags(argumentcollection = args)
				e = '<option selected="selected" value=""></option>'

				expect(r).toInclude(e)

				args.selected = "01/02/2000"
				r = _controller.dateTimeSelectTags(argumentcollection = args)
				e1 = '<option selected="selected" value="1">January</option>'
				e2 = '<option selected="selected" value="2">2</option>'
				e3 = '<option selected="selected" value="2000">2000</option>'

				expect(r).toInclude(e1)
				expect(r).toInclude(e2)
				expect(r).toInclude(e3)
			})

			it("works with blank included string", () => {
				args.name = "dateselector"
				args.includeBlank = "--Month--"
				args.selected = ""
				args.startyear = "2000"
				args.endyear = "1990"
				r = _controller.dateTimeSelectTags(argumentcollection = args)
				e = '<option selected="selected" value="">--Month--</option>'

				expect(r).toInclude(e)

				args.selected = "01/02/2000"
				r = _controller.dateTimeSelectTags(argumentcollection = args)
				e1 = '<option selected="selected" value="1">January</option>'
				e2 = '<option selected="selected" value="2">2</option>'
				e3 = '<option selected="selected" value="2000">2000</option>'

				expect(r).toInclude(e1)
				expect(r).toInclude(e2)
				expect(r).toInclude(e3)
			})

			it("works with blank not included", () => {
				args.name = "dateselector"
				args.includeBlank = "false"
				args.selected = ""
				args.startyear = "2000"
				args.endyear = "1990"
				r = _controller.dateTimeSelectTags(argumentcollection = args)
				e = '<option selected="selected" value=""></option>'

				expect(r).notToInclude(e)

				args.selected = "01/02/2000"
				r = _controller.dateTimeSelectTags(argumentcollection = args)
				e1 = '<option selected="selected" value="1">January</option>'
				e2 = '<option selected="selected" value="2">2</option>'
				e3 = '<option selected="selected" value="2000">2000</option>'

				expect(r).toInclude(e1)
				expect(r).toInclude(e2)
				expect(r).toInclude(e3)
			})

			it("works with twelve hours", () => {
				date = CreateDateTime(2014, 8, 4, 12, 30, 35)
				args.name = "x"
				args.twelveHour = true
				args.selected = date
				r = _controller.dateTimeSelectTags(argumentcollection = args)
				e = '<option selected="selected" value="30">30</option>'

				expect(r).toInclude(e)
			})
		})

		describe("Tests that DaySelectTag", () => {
			// There is only one test the original DaySelectTag.cfc but it is only asserting 1 to be 1 so it doesn't make sense to write here
		})

		describe("Tests that HourSelectTag", () => {
			
			it("works with twelve hour format", () => {
				_controller = g.controller(name = "dummy")
				g.set(functionName = "hourSelectTag", encode = false)

				args.name = "dateselector"
				args.twelveHour = "true"
				args.selected = "11"
				r = _controller.hourSelectTag(argumentcollection = args)
				e = '<select id="dateselector-hour" name="dateselector($hour)"><option value="1">1</option><option value="2">2</option><option value="3">3</option><option value="4">4</option><option value="5">5</option><option value="6">6</option><option value="7">7</option><option value="8">8</option><option value="9">9</option><option value="10">10</option><option selected="selected" value="11">11</option><option value="12">12</option></select>:<select id="dateselector-ampm" name="dateselector($ampm)"><option selected="selected" value="AM">AM</option><option value="PM">PM</option></select>'

				expect(e).toBe(r)

				args.selected = "23"
				r = _controller.hourSelectTag(argumentcollection = args)
				e = '<select id="dateselector-hour" name="dateselector($hour)"><option value="1">1</option><option value="2">2</option><option value="3">3</option><option value="4">4</option><option value="5">5</option><option value="6">6</option><option value="7">7</option><option value="8">8</option><option value="9">9</option><option value="10">10</option><option selected="selected" value="11">11</option><option value="12">12</option></select>:<select id="dateselector-ampm" name="dateselector($ampm)"><option value="AM">AM</option><option selected="selected" value="PM">PM</option></select>'

				expect(e).toBe(r)

				g.set(functionName = "hourSelectTag", encode = true)
			})
		})

		describe("Tests that MinuteSelectTag", () => {

			it("works with step argument", () => {
				_controller = g.controller(name = "dummy")
				args.name = "countdown"
				args.selected = 15
				args.minuteStep = 15
				r = _controller.minuteSelectTag(argumentcollection = args)
				e = '<option selected="selected" value="15">'

				expect(r).toInclude(e)

				matches = ReMatchNoCase("\<option", r)

				expect(matches).toHaveLength(4)
			})
		})

		describe("Tests that MonthSelectTag", () => {

			it("works with selected value", () => {
				_controller = g.controller(name = "dummy");
				args.name = "birthday"
				args.selected = 2
				args.$now = "01/31/2011"
				r = _controller.monthSelectTag(argumentcollection = args)
				e = '<option selected="selected" value="2">'

				expect(r).toInclude(e)
			})
		})

		describe("Tests that SecondSelectTag", () => {

			it("works with step argument", () => {
				_controller = g.controller(name = "dummy")
				args.name = "countdown";
				args.selected = 15;
				args.secondStep = 15;
				r = _controller.secondSelectTag(argumentcollection = args);
				e = '<option selected="selected" value="15">';

				expect(r).toInclude(e)
				
				matches = ReMatchNoCase("\<option", r);

				expect(matches).toHaveLength(4)
			})
		})

		describe("Tests that TimeSelectTag", () => {
			// There is only one test the original TimeSelectTag.cfc but it is only asserting 1 to be 1 so it doesn't make sense to write here
		})

		describe("Tests that YearSelectTag", () => {
			// There is only one test the original YearSelectTag.cfc but it is only asserting 1 to be 1 so it doesn't make sense to write here
		})
	}
}