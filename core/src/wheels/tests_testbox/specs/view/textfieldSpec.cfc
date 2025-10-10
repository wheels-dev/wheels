component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests that textField with encoding options", () => {

			beforeEach(() => {
				_controller = g.controller(name = "ControllerWithModel")
				g.set(functionName = "textField", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "textField", encode = true)
			})

			it("encodes HTML in label when encode=true", () => {
				textField = _controller.textField(
					objectName = "user", 
					property = "firstname", 
					label = "lastname error with <strong>bold</strong>",
					encode = true
				)
				expected = '<label for="user-firstname">lastname error with &lt;strong&gt;bold&lt;&##x2f;strong&gt;<input id="user-firstname" maxlength="50" name="user&##x5b;firstname&##x5d;" type="text" value="Tony"></label>'

				expect(textField).toBe(expected)
			})
			
			it("does not encode HTML in label when encode=false", () => {
				textField = _controller.textField(
					objectName = "user", 
					property = "firstname", 
					label = "lastname error with <strong>bold</strong>",
					encode = false
				)
				expected = '<label for="user-firstname">lastname error with <strong>bold</strong><input id="user-firstname" maxlength="50" name="user[firstname]" type="text" value="Tony"></label>'

				expect(textField).toBe(expected)
			})
			
			it("encodes only attributes when encode=attributes", () => {
				textField = _controller.textField(
					objectName = "user", 
					property = "firstname", 
					label = "lastname error with <strong>bold</strong>",
					class = 'form-control" onclick="alert(\"xss\")',
					encode = "attributes"
				)
				expected = '<label for="user-firstname">lastname error with <strong>bold</strong><input class="form-control&quot;&##x20;onclick&##x3d;&quot;alert&##x28;&quot;xss&quot;&##x29;" id="user-firstname" maxlength="50" name="user&##x5b;firstname&##x5d;" type="text" value="Tony"></label>'

				expect(textField).toBe(expected)
			})
			
			it("handles complex HTML content with encode=true", () => {
				textField = _controller.textField(
					objectName = "user", 
					property = "firstname", 
					label = 'Label with <strong>bold</strong> and <script>alert("XSS")</script>',
					encode = true
				)
				expected = '<label for="user-firstname">Label with &lt;strong&gt;bold&lt;&##x2f;strong&gt; and &lt;script&gt;alert&##x28;&quot;XSS&quot;&##x29;&lt;&##x2f;script&gt;<input id="user-firstname" maxlength="50" name="user&##x5b;firstname&##x5d;" type="text" value="Tony"></label>'

				expect(textField).toBe(expected)
			})
		})
		
		describe("Tests that textFieldTag with encoding options", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				g.set(functionName = "textFieldTag", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "textFieldTag", encode = true)
			})

			it("encodes HTML in label when encode=true", () => {
				result = _controller.textFieldTag(
					name = "firstname", 
					label = "lastname error with <strong>bold</strong>",
					encode = true
				)
				expected = '<label for="firstname">lastname error with &lt;strong&gt;bold&lt;&##x2f;strong&gt;<input id="firstname" name="firstname" type="text" value=""></label>'

				expect(result).toBe(expected)
			})
			
			it("does not encode HTML in label when encode=false", () => {
				result = _controller.textFieldTag(
					name = "firstname", 
					label = "lastname error with <strong>bold</strong>",
					encode = false
				)
				expected = '<label for="firstname">lastname error with <strong>bold</strong><input id="firstname" name="firstname" type="text" value=""></label>'
				
				expect(result).toBe(expected)
			})
			
			it("encodes only attributes when encode=attributes", () => {
				result = _controller.textFieldTag(
					name = "firstname", 
					label = "lastname error with <strong>bold</strong>",
					class = 'form-control" onclick="alert(\"xss\")',
					value = "Input with <strong>bold</strong> text",
					encode = "attributes"
				)
				expected = '<label for="firstname">lastname error with <strong>bold</strong><input class="form-control&quot;&##x20;onclick&##x3d;&quot;alert&##x28;&quot;xss&quot;&##x29;" id="firstname" name="firstname" type="text" value="Input&##x20;with&##x20;&lt;strong&gt;bold&lt;&##x2f;strong&gt;&##x20;text"></label>'

				expect(result).toBe(expected)
			})
			
			it("handles complex HTML content with encode=true", () => {
				htmlLabel = 'Label with <strong>bold</strong> and <script>alert("XSS")</script>'
				htmlValue = 'Value with <strong>bold</strong> and <script>alert("XSS")</script>'
				result = _controller.textFieldTag(
					name = "firstname", 
					label = htmlLabel,
					value = htmlValue,
					encode = true
				)
				expected = '<label for="firstname">Label with &lt;strong&gt;bold&lt;&##x2f;strong&gt; and &lt;script&gt;alert&##x28;&quot;XSS&quot;&##x29;&lt;&##x2f;script&gt;<input id="firstname" name="firstname" type="text" value="Value&##x20;with&##x20;&lt;strong&gt;bold&lt;&##x2f;strong&gt;&##x20;and&##x20;&lt;script&gt;alert&##x28;&quot;XSS&quot;&##x29;&lt;&##x2f;script&gt;"></label>'

				expect(result).toBe(expected)
			})
		})
	}
}