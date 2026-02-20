component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests that checkBox with encoding options", () => {

			beforeEach(() => {
				_controller = g.controller(name = "ControllerWithModel")
				args = {}
				args.objectName = "user"
			})

			it("encodes HTML in label when encode=true", () => {
				args.property = "firstname"
				args.label = "lastname error with <strong>bold</strong>"
				args.encode = true
				
				actual = _controller.checkBox(argumentcollection = args)
				expected = '<label for="user-firstname">lastname error with &lt;strong&gt;bold&lt;&##x2f;strong&gt;<input id="user-firstname" name="user&##x5b;firstname&##x5d;" type="checkbox" value="1"><input id="user-firstname-checkbox" name="user&##x5b;firstname&##x5d;&##x28;&##x24;checkbox&##x29;" type="hidden" value="0"></label>'
				
				expect(actual).toBe(expected)
			})
			
			it("does not encode HTML in label when encode=false", () => {
				args.property = "firstname"
				args.label = "lastname error with <strong>bold</strong>"
				args.encode = false
				
				actual = _controller.checkBox(argumentcollection = args)
				expected = '<label for="user-firstname">lastname error with <strong>bold</strong><input id="user-firstname" name="user[firstname]" type="checkbox" value="1"><input id="user-firstname-checkbox" name="user[firstname]($checkbox)" type="hidden" value="0"></label>'
				
				expect(actual).toBe(expected)
			})
			
			it("encodes only attributes when encode=attributes", () => {
				args.property = "firstname"
				args.label = "lastname error with <strong>bold</strong>"
				args.class = 'form-check" onclick="alert("xss")'
				args.encode = "attributes"
				
				actual = _controller.checkBox(argumentcollection = args)
				expected = '<label for="user-firstname">lastname error with <strong>bold</strong><input class="form-check&quot;&##x20;onclick&##x3d;&quot;alert&##x28;&quot;xss&quot;&##x29;" id="user-firstname" name="user&##x5b;firstname&##x5d;" type="checkbox" value="1"><input id="user-firstname-checkbox" name="user&##x5b;firstname&##x5d;&##x28;&##x24;checkbox&##x29;" type="hidden" value="0"></label>'
					
				expect(actual).toBe(expected)
			})
			
			it("handles complex HTML content with encode=true", () => {
				args.property = "firstname"
				args.label = 'Label with <strong>bold</strong> and <script>alert("XSS")</script>'
				args.encode = true
				
				actual = _controller.checkBox(argumentcollection = args)
				expected = '<label for="user-firstname">Label with &lt;strong&gt;bold&lt;&##x2f;strong&gt; and &lt;script&gt;alert&##x28;&quot;XSS&quot;&##x29;&lt;&##x2f;script&gt;<input id="user-firstname" name="user&##x5b;firstname&##x5d;" type="checkbox" value="1"><input id="user-firstname-checkbox" name="user&##x5b;firstname&##x5d;&##x28;&##x24;checkbox&##x29;" type="hidden" value="0"></label>'
				
				expect(actual).toBe(expected)
			})
		})
		
		describe("Tests that checkBoxTag with encoding options", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("encodes HTML in label when encode=true", () => {
				r = _controller.checkBoxTag(
					name = "subscribe", 
					value = "1", 
					label = "lastname error with <strong>bold</strong>",
					encode = true
				)
				e = '<label for="subscribe-1">lastname error with &lt;strong&gt;bold&lt;&##x2f;strong&gt;<input id="subscribe-1" name="subscribe" type="checkbox" value="1"></label>'
				
				expect(e).toBe(r)
			})
			
			it("does not encode HTML in label when encode=false", () => {
				r = _controller.checkBoxTag(
					name = "subscribe", 
					value = "1", 
					label = "lastname error with <strong>bold</strong>",
					encode = false
				)
				e = '<label for="subscribe-1">lastname error with <strong>bold</strong><input id="subscribe-1" name="subscribe" type="checkbox" value="1"></label>'

				expect(e).toBe(r)
			})
			
			it("encodes only attributes when encode=attributes", () => {
				r = _controller.checkBoxTag(
					name = "subscribe", 
					value = "1", 
					label = "lastname error with <strong>bold</strong>",
					class = 'form-check" onclick="alert("xss")',
					encode = "attributes"
				)
				e = '<label for="subscribe-1">lastname error with <strong>bold</strong><input class="form-check&quot;&##x20;onclick&##x3d;&quot;alert&##x28;&quot;xss&quot;&##x29;" id="subscribe-1" name="subscribe" type="checkbox" value="1"></label>'
				
				expect(e).toBe(r)
			})
			
			it("encodes HTML in uncheckedvalue when encode=true", () => {
				r = _controller.checkBoxTag(
					name = "subscribe", 
					value = "1", 
					label = "Subscribe",
					uncheckedvalue = "<script>alert('xss')</script>",
					encode = true
				)
				e = '<label for="subscribe-1">Subscribe<input id="subscribe-1" name="subscribe" type="checkbox" value="1"><input id="subscribe-1-checkbox" name="subscribe&##x28;&##x24;checkbox&##x29;" type="hidden" value="&lt;script&gt;alert&##x28;&##x27;xss&##x27;&##x29;&lt;&##x2f;script&gt;"></label>'
				
				expect(e).toBe(r)
			})
			
			it("handles complex HTML content with encode=true", () => {
				htmlLabel = 'Label with <strong>bold</strong> and <script>alert("XSS")</script>'
				r = _controller.checkBoxTag(
					name = "subscribe", 
					value = "1", 
					label = htmlLabel,
					encode = true
				)
				e = '<label for="subscribe-1">Label with &lt;strong&gt;bold&lt;&##x2f;strong&gt; and &lt;script&gt;alert&##x28;&quot;XSS&quot;&##x29;&lt;&##x2f;script&gt;<input id="subscribe-1" name="subscribe" type="checkbox" value="1"></label>'
				
				expect(e).toBe(r)
			})
		})
	}
}