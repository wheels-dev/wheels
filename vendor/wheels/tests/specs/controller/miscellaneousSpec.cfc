component extends="wheels.WheelsTest" {

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
				application.wheels.helperFileCache["test"] = true
				params = {controller = "test", action = "helperCaller"}
				_controller = application.wo.controller("test", params)
			})

			afterEach(() => {
				StructDelete(application.wheels.helperFileCache, "test")
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
				args.file = "/wheels/tests/_assets/files/wheels-logo.png"
				r = _controller.sendFile(argumentCollection = args)

				expect(r.file.right(15)).toBe("wheels-logo.png")
				expect(r.mime).toBe("image/png")
				expect(r.name.right(15)).toBe("wheels-logo.png")
			})

			it("gets test info", () => {
				args.file = "/wheels/tests/_assets/files/wheels-logo.png"
				args.name = "A Weird FileName.png"
				_controller.sendFile(argumentCollection = args)
				r = _controller.getFiles()

				expect(r[1].file.right(15)).toBe("wheels-logo.png")
				expect(r[1].mime).toBe("image/png")
				expect(r[1].name).toBe("A Weird FileName.png")
			})

			it("supplies file and name", () => {
				args.file = "/wheels/tests/_assets/files/wheels-logo.png"
				args.name = "A Weird FileName.png"
				r = _controller.sendFile(argumentCollection = args)

				expect(r.file.right(15)).toBe("wheels-logo.png")
				expect(r.mime).toBe("image/png")
				expect(r.name).toBe("A Weird FileName.png")
			})

			it("changes disposition", () => {
				args.file = "/wheels/tests/_assets/files/wheels-logo.png"
				args.disposition = "attachment"
				r = _controller.sendFile(argumentCollection = args)

				expect(r.file.right(15)).toBe("wheels-logo.png")
				expect(r.disposition).toBe("attachment")
				expect(r.mime).toBe("image/png")
				expect(r.name.right(15)).toBe("wheels-logo.png")
			})

			it("overloads mimetype", () => {
				args.file = "/wheels/tests/_assets/files/wheels-logo.png"
				args.type = "wheels/custom"
				r = _controller.sendFile(argumentCollection = args)

				expect(r.file.right(15)).toBe("wheels-logo.png")
				expect(r.disposition).toBe("attachment")
				expect(r.mime).toBe("wheels/custom")
				expect(r.name.right(15)).toBe("wheels-logo.png")
			})

			it("checks single file exists", () => {
				args.file = "/wheels/tests/_assets/files/sendFile.txt"
				r = _controller.sendFile(argumentCollection = args)

				expect(r.file.right(12)).toBe("sendFile.txt")
				expect(r.mime).toBe("text/plain")
				expect(r.name.right(12)).toBe("sendFile.txt")
			})

			it("checks no extension file does not exist", () => {
				args.file = "/wheels/tests/_assets/files/wheels-logo"

				expect(function() {
					_controller.sendFile(argumentCollection = args)
				}).toThrow("Wheels.FileNotFound")
			})

			it("rejects path traversal in the file argument", () => {
				args.file = "../../../../config/settings.cfm"

				expect(function() {
					_controller.sendFile(argumentCollection = args)
				}).toThrow("Wheels.InvalidPath")
			})

			it("rejects url-encoded path traversal in the file argument", () => {
				args.file = "%2e%2e/%2e%2e/%2e%2e/config/settings.cfm"

				expect(function() {
					_controller.sendFile(argumentCollection = args)
				}).toThrow("Wheels.InvalidPath")
			})

			it("rejects backslash path traversal in the file argument", () => {
				args.file = ".." & Chr(92) & ".." & Chr(92) & ".." & Chr(92) & "config" & Chr(92) & "settings.cfm"

				expect(function() {
					_controller.sendFile(argumentCollection = args)
				}).toThrow("Wheels.InvalidPath")
			})

			it("rejects path traversal in the directory argument", () => {
				args.directory = "/wheels/tests/_assets/files/../../../../config"
				args.file = "settings.cfm"

				expect(function() {
					_controller.sendFile(argumentCollection = args)
				}).toThrow("Wheels.InvalidPath")
			})

			it("sanitizes the download display name", () => {
				args.file = "/wheels/tests/_assets/files/wheels-logo.png"
				args.name = 'we"ird' & Chr(13) & Chr(10) & 'name.png'
				r = _controller.sendFile(argumentCollection = args)

				expect(r.name).toBe("weirdname.png")
			})

			it("serves a file from an absolute directory outside the web root", () => {
				// https://github.com/wheels-dev/wheels/issues/3077 — an absolute `directory`
				// outside the web root must be used verbatim, not re-resolved via ExpandPath
				// (which web-root-prefixes the path on Adobe CF).
				local.outsideDir = GetTempDirectory() & "dlprobe3077_outside"
				if (!DirectoryExists(local.outsideDir)) {
					DirectoryCreate(local.outsideDir, true)
				}
				local.target = local.outsideDir & "/secret.txt"
				FileWrite(local.target, "secret payload")
				try {
					args.file = "secret.txt"
					args.directory = local.outsideDir
					r = _controller.sendFile(argumentCollection = args)

					expect(Replace(r.file, "\", "/", "all")).toInclude("dlprobe3077_outside/secret.txt")
					expect(r.name).toBe("secret.txt")
				} finally {
					if (FileExists(local.target)) {
						FileDelete(local.target)
					}
					if (DirectoryExists(local.outsideDir)) {
						DirectoryDelete(local.outsideDir, true)
					}
				}
			})

			it("does not rewrite an absolute directory containing the '/wheels' substring", () => {
				// https://github.com/wheels-dev/wheels/issues/3077 — the `/wheels` mapping
				// fallback substring-matched ANY absolute path containing "/wheels"
				// (e.g. /var/www/wheels/uploads), silently rewriting it.
				local.wheelsDir = GetTempDirectory() & "wheels3077-dl"
				if (!DirectoryExists(local.wheelsDir)) {
					DirectoryCreate(local.wheelsDir, true)
				}
				local.target = local.wheelsDir & "/secret.txt"
				FileWrite(local.target, "secret payload")
				try {
					args.file = "secret.txt"
					args.directory = local.wheelsDir
					r = _controller.sendFile(argumentCollection = args)

					expect(Replace(r.file, "\", "/", "all")).toInclude("wheels3077-dl/secret.txt")
				} finally {
					if (FileExists(local.target)) {
						FileDelete(local.target)
					}
					if (DirectoryExists(local.wheelsDir)) {
						DirectoryDelete(local.wheelsDir, true)
					}
				}
			})

			it("still resolves a leading-slash webroot-relative directory against the web root", () => {
				// Regression guard for the long-standing webroot-relative idiom
				// (`directory="/reports/"`): a root-anchored path that does NOT exist on
				// disk must fall through to the legacy `ExpandPath()` resolution instead
				// of being treated as a verbatim filesystem path (which would miss the
				// file and throw). On Adobe CF this idiom was historically the only
				// working form of `directory`, so it must keep working.
				local.relDir = "dlprobe3077_rel"
				local.absDir = ExpandPath("/" & local.relDir)
				if (!DirectoryExists(local.absDir)) {
					DirectoryCreate(local.absDir, true)
				}
				local.target = local.absDir & "/report.txt"
				FileWrite(local.target, "webroot-relative payload")
				try {
					args.file = "report.txt"
					args.directory = "/" & local.relDir & "/"
					r = _controller.sendFile(argumentCollection = args)

					expect(Replace(r.file, "\", "/", "all")).toInclude("dlprobe3077_rel/report.txt")
					expect(r.name).toBe("report.txt")
				} finally {
					if (FileExists(local.target)) {
						FileDelete(local.target)
					}
					if (DirectoryExists(local.absDir)) {
						DirectoryDelete(local.absDir, true)
					}
				}
			})

			it("is specifying a directory", () => {
				// Skip this test temporarily to debug in CI
				skip("Temporarily skipping to debug path issues in CI");
				
				// Get absolute path to test assets directory
				local.testFile = "/wheels/tests/_assets/files/wheels-logo.png";
				// Extract directory and filename parts
				local.dir = GetDirectoryFromPath(local.testFile);
				local.filename = GetFileFromPath(local.testFile);
				
				// Use ExpandPath to get the absolute directory path
				args.directory = ExpandPath(local.dir)
				args.file = local.filename
				r = _controller.sendFile(argumentCollection = args)

				expect(r.file.right(15)).toBe("wheels-logo.png")
				expect(r.mime).toBe("image/png")
				expect(r.name.right(15)).toBe("wheels-logo.png")
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
				application.wheels.filePath = "/wheels/tests/_assets/files"
				oldArgs = application.wheels.functions.sendEmail
				textBody = "dummy plain email body"
				HTMLBody = "<p>dummy html email body</p>"
				bracketsBody = "dummy code email body where a < b < c < d < e"
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
				args.file = "wheels-logo.png"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.mailparams[1].file).toInclude("_assets")
				expect(result.mailparams[1].file).toInclude("wheels-logo.png")
			})

			it("sends mail with external attachment", () => {
				args.template = "plainEmailTemplate"
				args.file = "wheels-logo.png,http://www.example.com/test.txt,c:\inetpub\wwwroot\cfwheels\something.pdf"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.mailparams[1].file).toInclude("_assets")
				expect(result.mailparams[1].file).toInclude("wheels-logo.png")
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

			it("separates text and html bodies with a blank line when using writetofile", () => {
				args.templates = "HTMLEmailTemplate,plainEmailTemplate"
				args.writeToFile = filePath
				if (FileExists(filePath)) {
					FileDelete(filePath)
				}
				_controller.sendEmail(argumentCollection = args)
				fileContent = FileRead(filePath)
				FileDelete(filePath)

				expect(fileContent).toInclude(textBody & Chr(13) & Chr(10) & Chr(13) & Chr(10) & HTMLBody)
			})

			it("sends single template email when layout is an empty string", () => {
				args.template = "plainEmailTemplate"
				args.layout = ""
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.type).toBe("text")
				expect(result.text).toBe(textBody)
			})

			it("throws a friendly error when more than two templates are passed in", () => {
				args.templates = "plainEmailTemplate,HTMLEmailTemplate,plainEmailTemplate"

				expect(function() {
					_controller.sendEmail(argumentCollection = args)
				}).toThrow("Wheels.IncorrectArguments")
			})

			it("defaults to text when multipart detection is off and no type is passed in", () => {
				args.template = "plainEmailTemplate"
				args.detectMultipart = false
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.type).toBe("text")
				expect(result.text).toBe(textBody)
			})

			it("preserves template order when multipart detection is off", () => {
				args.templates = "bracketsEmailTemplate,HTMLEmailTemplate"
				args.detectMultipart = false
				result = _controller.sendEmail(argumentCollection = args)

				expect(result.mailparts[1].type).toBe("text")
				expect(result.mailparts[1].tagContent).toBe(bracketsBody)
				expect(result.mailparts[2].type).toBe("html")
				expect(result.mailparts[2].tagContent).toBe(HTMLBody)
			})

			it("does not leak custom view arguments into the controller after sending", () => {
				args.template = "plainEmailTemplate"
				leakArgs = Duplicate(args)
				leakArgs.customArgument = "IShouldNotLeakIntoLaterRenders"
				_controller.sendEmail(argumentCollection = leakArgs)

				result = _controller.sendEmail(argumentCollection = args)
				expect(result.text).toBe(textBody)
			})

			it("does not leak custom view arguments into the controller when rendering throws", () => {
				args.template = "plainEmailTemplate"
				leakArgs = Duplicate(args)
				leakArgs.template = "aTemplateThatDoesNotExist"
				leakArgs.customArgument = "IShouldNotLeakWhenRenderingThrows"

				expect(function() {
					_controller.sendEmail(argumentCollection = leakArgs)
				}).toThrow()

				result = _controller.sendEmail(argumentCollection = args)
				expect(result.text).toBe(textBody)
			})

			it("passes smime signing attributes through to the mail tag", () => {
				args.template = "plainEmailTemplate"
				args.sign = true
				args.keystore = "/path/to/keystore"
				args.keystorepassword = "keystorepass"
				args.keyalias = "mailkey"
				args.keypassword = "keypass"
				result = _controller.sendEmail(argumentCollection = args)

				expect(result).toHaveKey("sign")
				expect(result).toHaveKey("keystore")
				expect(result).toHaveKey("keyalias")
				expect(result.keystorepassword).toBe("keystorepass")
				expect(result.keypassword).toBe("keypass")
			})
		})
	}

	function default_args() {
		application.wo.$args(args = arguments, name = "sendEmail", required = "template,from,to,subject")
		return arguments
	}
}
