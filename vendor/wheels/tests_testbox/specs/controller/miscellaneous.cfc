component extends="testbox.system.BaseSpec" {

	function run() {

		describe("Tests that $callaction", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test"}
				_controller = application.wo.controller("test", params)
			})

			it("is setting variable for view", () => {
				_controller.$callAction(action = "test")
				expect(_controller.response()).toInclude("variableForViewContent")
			})

			it("is implicitly calling render page", () => {
				_controller.$callAction(action = "test")
				expect(_controller.response()).toInclude("view template content")
			})
		})

		describe("Tests that $performedRenderOrRedirect", () => {

			beforeEach(() => {
				params = {controller = "dummy", action = "dummy"}
				_controller = application.wo.controller("dummy", params)
			})

			it("does not perform redirect or render", () => {
				actual = _controller.$performedRedirect()
				expect(actual).toBeFalse()

				actual = _controller.$performedRender()
				expect(actual).toBeFalse()

				actual = _controller.$performedRenderOrRedirect()
				expect(actual).toBeFalse()
			})

			it("is performing redirect only", () => {
				_controller.redirectTo(controller = "wheels", action = "wheels")
				actual = _controller.$performedRedirect()
				expect(actual).toBeTrue()

				actual = _controller.$performedRenderOrRedirect()
				expect(actual).toBeTrue()

				actual = _controller.$performedRender()
				expect(actual).toBeFalse()
			})

			it("is performing render only", () => {
				_controller.renderNothing()
				actual = _controller.$performedRender()
				expect(actual).toBeTrue()

				actual = _controller.$performedRenderOrRedirect()
				expect(actual).toBeTrue()

				actual = _controller.$performedRedirect()
				expect(actual).toBeFalse()
			})
		})

		describe("Tests that helpers", () => {

			beforeEach(() => {
				if (StructKeyExists(request, "test")) {
					StructDelete(request, "test")
				}
				application.wheels.existingHelperFiles = "test"
				params = {controller = "test", action = "helperCaller"}
				_controller = application.wo.controller("test", params)
			})

			afterEach(() => {
				application.wheels.existingHelperFiles = ""
			})

			it("is including global helper file", () => {
				_controller.renderView()
				expect(request.test).toHaveKey("globalHelperFunctionWasCalled")
			})

			it("is including controller helper file", () => {
				_controller.renderView()
				expect(request.test).toHaveKey("controllerHelperFunctionWasCalled")
			})
		})

		describe("Tests that sendfile", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test"}
				_controller = application.wo.controller("dummy", params)
				args = {}
				args.deliver = false
			})

			it("only supplies file", () => {
				args.file = "/wheels/tests_testbox/_assets/files/cfwheels-logo.png"
				r = _controller.sendFile(argumentCollection = args)

				expect(r.file.right(17)).toBe("cfwheels-logo.png")
				expect(r.mime).toBe("image/png")
				expect(r.name.right(17)).toBe("cfwheels-logo.png")
			})

			it("gets test info", () => {
				args.file = "/wheels/tests_testbox/_assets/files/cfwheels-logo.png"
				args.name = "A Weird FileName.png"
				_controller.sendFile(argumentCollection = args)
				r = _controller.getFiles()

				expect(r[1].file.right(17)).toBe("cfwheels-logo.png")
				expect(r[1].mime).toBe("image/png")
				expect(r[1].name).toBe("A Weird FileName.png")
			})

			it("supplies file and name", () => {
				args.file = "/wheels/tests_testbox/_assets/files/cfwheels-logo.png"
				args.name = "A Weird FileName.png"
				r = _controller.sendFile(argumentCollection = args)

				expect(r.file.right(17)).toBe("cfwheels-logo.png")
				expect(r.mime).toBe("image/png")
				expect(r.name).toBe("A Weird FileName.png")
			})

			it("changes disposition", () => {
				args.file = "/wheels/tests_testbox/_assets/files/cfwheels-logo.png"
				args.disposition = "attachment"
				r = _controller.sendFile(argumentCollection = args)

				expect(r.file.right(17)).toBe("cfwheels-logo.png")
				expect(r.disposition).toBe("attachment")
				expect(r.mime).toBe("image/png")
				expect(r.name.right(17)).toBe("cfwheels-logo.png")
			})

			it("overloads mimetype", () => {
				args.file = "/wheels/tests_testbox/_assets/files/cfwheels-logo.png"
				args.type = "wheels/custom"
				r = _controller.sendFile(argumentCollection = args)

				expect(r.file.right(17)).toBe("cfwheels-logo.png")
				expect(r.disposition).toBe("attachment")
				expect(r.mime).toBe("wheels/custom")
				expect(r.name.right(17)).toBe("cfwheels-logo.png")
			})

			it("checks single file exists", () => {
				args.file = "/wheels/tests_testbox/_assets/files/sendFile.txt"
				r = _controller.sendFile(argumentCollection = args)

				expect(r.file.right(12)).toBe("sendFile.txt")
				expect(r.mime).toBe("text/plain")
				expect(r.name.right(12)).toBe("sendFile.txt")
			})

			it("checks no extension file does not exist", () => {
				args.file = "/wheels/tests_testbox/_assets/files/cfwheels-logo"

				expect(function() {
					_controller.sendFile(argumentCollection = args)
				}).toThrow("Wheels.FileNotFound")
			})

			it("is specifying a directory", () => {
				// Get the directory where the test assets are located
				local.currentDir = GetDirectoryFromPath(GetCurrentTemplatePath());
				// Navigate to the _assets directory
				args.directory = local.currentDir & "../../../_assets"
				args.file = "files/cfwheels-logo.png"
				r = _controller.sendFile(argumentCollection = args)

				expect(r.file.right(17)).toBe("cfwheels-logo.png")
				expect(r.mime).toBe("image/png")
				expect(r.name.right(17)).toBe("cfwheels-logo.png")
			})
		})

		describe("Tests that sendmail", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test"}
				_controller = application.wo.controller("dummy", params)
				args = StructNew()
				args.subject = "dummy subject"
				args.to = "to-dummy@dummy.com"
				args.from = "from-dummy@dummy.com"
				args.deliver = false
				oldFilePath = application.wheels.filePath
				application.wheels.filePath = "/wheels/tests_testbox/_assets/files"
				oldArgs = application.wheels.functions.sendEmail
				textBody = "dummy plain email body"
				HTMLBody = "<p>dummy html email body</p>"
				filePath = ExpandPath(application.wheels.filePath) & "/" & "emailcontent.txt"
			})

			afterEach(() => {
				application.wheels.filePath = oldFilePath
				application.wheels.functions.sendEmail = oldArgs
			})

			it("allows default for from,to and subject", () => {
				application.wheels.functions.sendEmail.from = "sender@example.com"
				application.wheels.functions.sendEmail.to = "recipient@example.com"
				application.wheels.functions.sendEmail.subject = "test email"

				r = default_args(template = "")
				expect(r.from).toBe("sender@example.com")
				expect(r.to).toBe("recipient@example.com")
				expect(r.subject).toBe("test email")

				r = default_args(
					template = "",
					from = "custom_sender@example.com",
					to = "custom_recipient@example.com",
					subject = "custom suject"
				)
				expect(r.from).toBe("custom_sender@example.com")
				expect(r.to).toBe("custom_recipient@example.com")
				expect(r.subject).toBe("custom suject")
			})

			it("sends plain email", () => {
				args.template = "plainEmailTemplate"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result).toHaveLength(6)
				expect(result).toHaveKey("to")
				expect(result).toHaveKey("from")
				expect(result).toHaveKey("subject")
				expect(result.type).toBe("text")
				expect(result.text).toBe(textBody)
				expect(result.html).toBe("")
			})

			it("sends html email", () => {
				args.template = "HTMLEmailTemplate"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.type).toBe("html")
				expect(result.text).toBe("")
				expect(result.html).toBe(HTMLBody)
			})

			it("detects mutlipart with html", () => {
				args.template = "HTMLEmailTemplate"
				args.detectMultipart = true
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.type).toBe("html")
			})

			it("detects mutlipart with plain", () => {
				args.template = "plainEmailTemplate"
				args.detectMultipart = true
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.type).toBe("text")
			})

			it("sends with type argument without detectmultipart", () => {
				args.template = "plainEmailTemplate"
				args.type = "html"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.type).toBe("html")
			})

			it("sends mail combined in correct order", () => {
				args.templates = "HTMLEmailTemplate,plainEmailTemplate"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.mailparts[1].type).toBe("text")
				expect(result.mailparts[2].tagContent).toBe(HTMLBody)
			})

			it("sends mail with layout", () => {
				args.template = "HTMLEmailTemplate"
				args.layout = "emailLayout"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.html).toInclude("<div>")
			})

			it("sends mail with attachment", () => {
				args.template = "plainEmailTemplate"
				args.file = "cfwheels-logo.png"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.mailparams[1].file).toInclude("_assets")
				expect(result.mailparams[1].file).toInclude("cfwheels-logo.png")
			})

			it("sends mail with external attachment", () => {
				args.template = "plainEmailTemplate"
				args.file = "cfwheels-logo.png,http://www.example.com/test.txt,c:\inetpub\wwwroot\cfwheels\something.pdf"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.mailparams[1].file).toInclude("_assets")
				expect(result.mailparams[1].file).toInclude("cfwheels-logo.png")
				expect(result.mailparams[2].file).toInclude("http://www.example.com/test.txt")
				expect(result.mailparams[3].file).toInclude("c:\inetpub\wwwroot\cfwheels\something.pdf")
			})

			it("sends mail with custom argument", () => {
				args.template = "plainEmailTemplate"
				args.customArgument = "IPassedInThisAsACustomArgument"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.text).toInclude("IPassedInThisAsACustomArgument")
			})

			it("sends mail from different path", () => {
				args.template = "/shared/anotherPlainEmailTemplate"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.text).toBe("another dummy plain email body")
			})

			it("sends mail from sub folder", () => {
				args.template = "sub/anotherHTMLEmailTemplate"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.html).toBe("<p>another dummy html email body</p>")
			})

			it("sends mail with writetofile", () => {
				args.templates = "HTMLEmailTemplate,plainEmailTemplate"
				args.writeToFile = filePath
				if (FileExists(filePath)) {
					FileDelete(filePath)
				}
				_controller.sendEmail(argumentCollection = args)
				fileContent = FileRead(filePath)
				FileDelete(filePath)

				expect(fileContent).toInclude(HTMLBody)
				expect(fileContent).toInclude(textBody)
			})
		})
	}

	function default_args() {
		application.wo.$args(args = arguments, name = "sendEmail", required = "template,from,to,subject")
		return arguments
	}
}
