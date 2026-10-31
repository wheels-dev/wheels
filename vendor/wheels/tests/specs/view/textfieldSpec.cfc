component extends="wheels.WheelsTest" {

	/**
	 * These specs assert the framework's default form-helper output. An app
	 * built with `wheels new` changes it in config/settings.cfm
	 * (includeFormErrorMessages=true, and labelPlacement="before" for the
	 * text-like helpers), and the core suite runs with the host app's
	 * settings. So pin the framework defaults for this bundle and put the
	 * app's values back afterwards.
	 */
	function beforeAll() {
		variables.pinnedFormSettings = {includeFormErrorMessages = application.wheels.includeFormErrorMessages, labelPlacement = {}};
		application.wheels.includeFormErrorMessages = false;
		for (var helperName in ListToArray("textField,textArea,passwordField,select,fileField,emailField,urlField,numberField,telField,dateField,searchField,colorField,rangeField")) {
			if (StructKeyExists(application.wheels.functions, helperName) && StructKeyExists(application.wheels.functions[helperName], "labelPlacement")) {
				variables.pinnedFormSettings.labelPlacement[helperName] = application.wheels.functions[helperName].labelPlacement;
				application.wheels.functions[helperName].labelPlacement = "around";
			}
		}
	}

	function afterAll() {
		application.wheels.includeFormErrorMessages = variables.pinnedFormSettings.includeFormErrorMessages;
		for (var helperName in variables.pinnedFormSettings.labelPlacement) {
			application.wheels.functions[helperName].labelPlacement = variables.pinnedFormSettings.labelPlacement[helperName];
		}
	}

	function run() {

		enc = new wheels.tests._assets.view.HtmlEncoding()

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
				expected = '<label for="user-firstname">lastname error with &lt;strong&gt;bold&lt;&##x2f;strong&gt;<input data-auto-id="user_firstname" id="user-firstname" maxlength="50" name="user&##x5b;firstname&##x5d;" type="text" value="Tony"></label>'

				expect(enc.normalize(textField)).toBe(enc.normalize(expected))
				expect(enc.textProblem(enc.innerText(textField, "label"), "lastname error with <strong>bold</strong>")).toBe("")
			})
			
			it("does not encode HTML in label when encode=false", () => {
				textField = _controller.textField(
					objectName = "user", 
					property = "firstname", 
					label = "lastname error with <strong>bold</strong>",
					encode = false
				)
				expected = '<label for="user-firstname">lastname error with <strong>bold</strong><input data-auto-id="user_firstname" id="user-firstname" maxlength="50" name="user[firstname]" type="text" value="Tony"></label>'

				expect(textField).toBe(expected)
			})
			
			it("encodes only attributes when encode=attributes", () => {
				textField = _controller.textField(
					objectName = "user", 
					property = "firstname", 
					label = "lastname error with <strong>bold</strong>",
					class = 'form-control" onclick="alert("xss")',
					encode = "attributes"
				)
				expected = '<label for="user-firstname">lastname error with <strong>bold</strong><input class="form-control&quot;&##x20;onclick&##x3d;&quot;alert&##x28;&quot;xss&quot;&##x29;" data-auto-id="user_firstname" id="user-firstname" maxlength="50" name="user&##x5b;firstname&##x5d;" type="text" value="Tony"></label>'

				expect(enc.normalize(textField)).toBe(enc.normalize(expected))
				expect(enc.attributeProblem(textField, "class", 'form-control" onclick="alert("xss")')).toBe("")
			})
			
			it("handles complex HTML content with encode=true", () => {
				textField = _controller.textField(
					objectName = "user", 
					property = "firstname", 
					label = 'Label with <strong>bold</strong> and <script>alert("XSS")</script>',
					encode = true
				)
				expected = '<label for="user-firstname">Label with &lt;strong&gt;bold&lt;&##x2f;strong&gt; and &lt;script&gt;alert&##x28;&quot;XSS&quot;&##x29;&lt;&##x2f;script&gt;<input data-auto-id="user_firstname" id="user-firstname" maxlength="50" name="user&##x5b;firstname&##x5d;" type="text" value="Tony"></label>'

				expect(enc.normalize(textField)).toBe(enc.normalize(expected))
				expect(enc.textProblem(enc.innerText(textField, "label"), 'Label with <strong>bold</strong> and <script>alert("XSS")</script>')).toBe("")
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

				expect(enc.normalize(result)).toBe(enc.normalize(expected))
				expect(enc.textProblem(enc.innerText(result, "label"), "lastname error with <strong>bold</strong>")).toBe("")
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
					class = 'form-control" onclick="alert("xss")',
					value = "Input with <strong>bold</strong> text",
					encode = "attributes"
				)
				expected = '<label for="firstname">lastname error with <strong>bold</strong><input class="form-control&quot;&##x20;onclick&##x3d;&quot;alert&##x28;&quot;xss&quot;&##x29;" id="firstname" name="firstname" type="text" value="Input&##x20;with&##x20;&lt;strong&gt;bold&lt;&##x2f;strong&gt;&##x20;text"></label>'

				expect(enc.normalize(result)).toBe(enc.normalize(expected))
				expect(enc.attributeProblem(result, "class", 'form-control" onclick="alert("xss")')).toBe("")
				expect(enc.attributeProblem(result, "value", "Input with <strong>bold</strong> text")).toBe("")
			})

			it("keeps a backslash before a quote inside the encoded attribute", () => {
				// ESAPI 2.x canonicalization drops the backslash in \", 3.x (Lucee 7.0.5+) keeps it.
				// Either way the quote must stay inside the value and inject nothing.
				var input = 'form-control" onclick="alert(\"xss\")'
				var withoutBackslashes = Replace(input, '\"', '"', "all")
				result = _controller.textFieldTag(name = "firstname", class = input, encode = "attributes")
				var raw = enc.attributeValue(result, "class")
				var decoded = enc.decode(raw)

				expect(enc.hasAttribute(result, "onclick")).toBeFalse(result)
				expect(enc.isSafeAttributeValue(raw)).toBeTrue(raw)
				expect(Compare(decoded, input) == 0 || Compare(decoded, withoutBackslashes) == 0).toBeTrue(
					"class decodes to [#decoded#]"
				)
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

				expect(enc.normalize(result)).toBe(enc.normalize(expected))
				expect(enc.textProblem(enc.innerText(result, "label"), htmlLabel)).toBe("")
				expect(enc.attributeProblem(result, "value", htmlValue)).toBe("")
			})
		})
	}
}