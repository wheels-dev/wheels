component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that dateSelect with encoding options", () => {

			beforeEach(() => {
				_controller = g.controller(name = "ControllerWithModel")
				args = {}
				args.objectName = "user"
				args.property = "birthday"
				args.includeblank = false
				args.order = "month,day,year"
				g.set(functionName = "dateSelect", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "dateSelect", encode = true)
			})

			it("encodes HTML in label when encode=true", () => {
				args.label = "lastname error with <strong>bold</strong>"
				args.encode = true
				
				actual = _controller.dateSelect(argumentcollection = args)
				expected = '<label for="user-birthday-month">lastname error with &lt;strong&gt;bold&lt;&##x2f;strong&gt;<select id="user-birthday-month" name="user&##x5b;birthday&##x5d;&##x28;&##x24;month&##x29;"><option value="1">January</option><option value="2">February</option><option value="3">March</option><option value="4">April</option><option value="5">May</option><option value="6">June</option><option value="7">July</option><option value="8">August</option><option value="9">September</option><option value="10">October</option><option selected="selected" value="11">November</option><option value="12">December</option>'
				
				expect(actual).toInclude(expected.left(expected.len() - 10))
			})
			
			it("does not encode HTML in label when encode=false", () => {
				args.label = "lastname error with <strong>bold</strong>"
				args.encode = false
				
				actual = _controller.dateSelect(argumentcollection = args)
				expected = '<label for="user-birthday-month">lastname error with <strong>bold</strong><select id="user-birthday-month" name="user[birthday]($month)">'

				expect(actual).toInclude(expected.left(expected.len() - 1))
			})
			
			it("encodes only attributes when encode=attributes", () => {
				args.label = "lastname error with <strong>bold</strong>"
				args.class = 'date-select" onclick="alert(\"xss\")'
				args.encode = "attributes"
				
				actual = _controller.dateSelect(argumentcollection = args)

				expect(actual).toInclude('<label for="user-birthday-month">lastname error with <strong>bold</strong>')
			})
			
			it("handles complex HTML content with encode=true", () => {
				args.label = 'Label with <strong>bold</strong> and <script>alert("XSS")</script>'
				args.encode = true
				
				actual = _controller.dateSelect(argumentcollection = args)
				expected = '<label for="user-birthday-month">Label with &lt;strong&gt;bold&lt;&##x2f;strong&gt; and &lt;script&gt;alert&##x28;&quot;XSS&quot;&##x29;&lt;&##x2f;script&gt;'

				expect(actual).toInclude(expected)
			})
			
			it("works with different label placements with encode=true", () => {
				args.label = "lastname error with <strong>bold</strong>"
				args.labelPlacement = "after"
				args.encode = true
				
				actual = _controller.dateSelect(argumentcollection = args)
				
				expect(actual).toInclude('<label for="user-birthday-year">lastname error with &lt;strong&gt;bold&lt;&##x2f;strong&gt;</label>')
			})
		})
		
		describe("Tests that dateSelectTags with encoding options", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.name = "date"
				args.includeblank = false
				g.set(functionName = "dateSelectTags", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "dateSelectTags", encode = true)
			})

			it("encodes HTML in label when encode=true", () => {
				args.label = "lastname error with <strong>bold</strong>"
				args.encode = true
				
				actual = _controller.dateSelectTags(argumentcollection = args)
				expected = '<label for="date-month">lastname error with &lt;strong&gt;bold&lt;&##x2f;strong&gt;'
				
				expect(actual).toInclude(expected)
			})
			
			it("does not encode HTML in label when encode=false", () => {
				args.label = "lastname error with <strong>bold</strong>"
				args.encode = false
				
				actual = _controller.dateSelectTags(argumentcollection = args)
				expected = '<label for="date-month">lastname error with <strong>bold</strong>'

				expect(actual).toInclude(expected)
			})
			
			it("encodes only attributes when encode=attributes", () => {
				args.label = "lastname error with <strong>bold</strong>"
				args.class = 'date-select" onclick="alert(\"xss\")'
				args.encode = "attributes"
				
				actual = _controller.dateSelectTags(argumentcollection = args)

				expect(actual).toInclude('<label for="date-month">lastname error with <strong>bold</strong>')
			})
			
			it("handles complex HTML content with encode=true", () => {
				args.label = 'Label with <strong>bold</strong> and <script>alert("XSS")</script>'
				args.encode = true
				
				actual = _controller.dateSelectTags(argumentcollection = args)
				expected = '<label for="date-month">Label with &lt;strong&gt;bold&lt;&##x2f;strong&gt; and &lt;script&gt;alert&##x28;&quot;XSS&quot;&##x29;&lt;&##x2f;script&gt;'

				expect(actual).toInclude(expected)
			})
		})
	}
}