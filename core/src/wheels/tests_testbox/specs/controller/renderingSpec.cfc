component extends="wheels.Testbox" {

	function run() {

		describe("Tests that $argumentsForPartial", () => {

			it("name is not a function", () => {
				params = {controller = "dummy", action = "dummy"}
				_controller = application.wo.controller("dummy", params)

				query = QueryNew("a,b,c,e")
				_controller.$injectIntoVariablesScope = this.$injectIntoVariablesScope
				_controller.$injectIntoVariablesScope(name = "query", data = query)
				actual = _controller.$argumentsForPartial($name = "query", $dataFunction = true)

				expect(actual).toBeStruct()
				expect(actual).toBeEmpty()
			})
		})

		describe("Tests that includecontent", () => {

			beforeEach(() => {
				params = {controller = "dummy", action = "dummy"}
				_controller = application.wo.controller("dummy", params)
			})

			it("contentFor and includeContent is assigning section", () => {
				a = ["head1", "head2", "head3"]
				for (i in a) {
					_controller.contentFor(head = i)
				}
				expected = ArrayToList(a, Chr(10))
				actual = _controller.includeContent("head")

				expect(actual).toBe(expected)
			})

			it("contentFor and includeContent is showing default section", () => {
				a = ["layout1", "layout2", "layout3"]
				for (i in a) {
					_controller.contentFor(body = i)
				}
				expected = ArrayToList(a, Chr(10))
				actual = _controller.includeContent()

				expect(actual).toBe(expected)
			})

			it("includeContent invalid section is returning blank", () => {
				actual = _controller.includeContent("somethingstupid")

				expect(actual).toBe("")
			})

			it("includeContent is returning default", () => {
				actual = _controller.includeContent("somethingstupid", "my default value")

				expect(actual).toBe("my default value")
			})
		})

		describe("Tests that layouts", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test"}
				_controller = application.wo.controller("test", params)
			})

			it("is rendering without layout", () => {
				_controller.renderView(layout = false)

				expect(trim(_controller.response())).toBe("view template content")
			})

			it("is rendering with default layout in controller folder", () => {
				tempFile = ExpandPath("/wheels/tests_testbox/_assets/views/test/layout.cfm")
				FileWrite(tempFile, "<cfoutput>start:controllerlayout##includeContent()##end:controllerlayout</cfoutput>")
				application.wheels.existingLayoutFiles = "test"
				_controller.renderView()
				r = _controller.response()

				expect(r).toInclude("view template content")
				expect(r).toInclude("start:controllerlayout")
				expect(r).toInclude("end:controllerlayout")

				application.wheels.existingLayoutFiles = ""
				FileDelete(tempFile)
			})

			it("is rendering with default layout in root", () => {
				_controller.renderView()
				r = _controller.response()

				expect(r).toInclude("view template content")
				expect(r).toInclude("start:defaultlayout")
				expect(r).toInclude("end:defaultlayout")
			})

			it("is removing cfm file extension when supplied", () => {
				_controller.renderView(layout = "specificLayout.cfm")
				r = _controller.response()

				expect(r).toInclude("view template content")
				expect(r).toInclude("start:specificlayout")
				expect(r).toInclude("end:specificlayout")
			})

			it("is rendering with specific layout", () => {
				_controller.renderView(layout = "specificLayout")
				r = _controller.response()

				expect(r).toInclude("view template content")
				expect(r).toInclude("start:specificlayout")
				expect(r).toInclude("end:specificlayout")
			})

			it("is rendering with specific layout in root", () => {
				_controller.renderView(layout = "/rootLayout")
				r = _controller.response()

				expect(r).toInclude("view template content")
				expect(r).toInclude("start:rootlayout")
				expect(r).toInclude("end:rootlayout")
			})

			it("is rendering with specific layout in sub folder", () => {
				_controller.renderView(layout = "sub/layout")
				r = _controller.response()

				expect(r).toInclude("view template content")
				expect(r).toInclude("start:sublayout")
				expect(r).toInclude("end:sublayout")
			})

			it("is rendering with specific layout from folder path", () => {
				_controller.renderView(layout = "/shared/layout")
				r = _controller.response()

				expect(r).toInclude("view template content")
				expect(r).toInclude("start:sharedlayout")
				expect(r).toInclude("end:sharedlayout")
			})

			it("has view variable available in layout file", () => {
				_controller.$callAction(action = "test")
				_controller.renderView()
				r = _controller.response()

				expect(r).toInclude("view template content")
				expect(r).toInclude("variableForLayoutContent")
				expect(r).toInclude("start:defaultlayout")
				expect(r).toInclude("end:defaultlayout")
			})

			it("is rendering partial with layout", () => {
				_controller.renderPartial(partial = "partialTemplate", layout = "partialLayout")
				r = _controller.response()

				expect(r).toInclude("partial template content")
				expect(r).toInclude("start:partiallayout")
				expect(r).toInclude("end:partiallayout")
			})

			it("is rendering partial with specific layout in root", () => {
				_controller.renderPartial(partial = "partialTemplate", layout = "/partialRootLayout")
				r = _controller.response()

				expect(r).toInclude("partial template content")
				expect(r).toInclude("start:partialrootlayout")
				expect(r).toInclude("end:partialrootlayout")
			})
		})

		describe("Tests that rendernothing", () => {

			beforeEach(() => {
				params = {controller = "dummy", action = "dummy"}
				_controller = application.wo.controller("dummy", params)
			})

			it("is rendering nothing", () => {
				_controller.renderNothing()

				expect(_controller.response()).toBe("")
			})

			it("is rendering nothing with status", () => {
				_controller.renderNothing(status = 418)

				expect(application.wo.$statusCode()).toBe(418)
			})
		})

		describe("Tests that renderpartial", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test"}
				_controller = application.wo.controller("test", params)
			})

			it("is rendering partial", () => {
				result = _controller.renderPartial(partial = "partialTemplate")

				expect(_controller.response()).toInclude("partial template content")
			})

			it("is rendering partial and returning as string", () => {
				result = _controller.renderPartial(partial = "partialTemplate", returnAs = "string")

				expect(request.wheels).notToHaveKey('response')
				expect(result).toInclude("partial template content")
			})

			it("is rendering partial with status", () => {
				result = _controller.renderPartial(partial = "partialTemplate", status = 418)

				expect(application.wo.$statusCode()).toBe(418)
			})
		})

		describe("Tests that rendertext", () => {

			beforeEach(() => {
				params = {controller = "dummy", action = "dummy"}
				_controller = application.wo.controller("dummy", params)
			})

			it("is rendering text", () => {
				_controller.renderText("OMG, look what I rendered!")
				expect(_controller.response()).toInclude("OMG, look what I rendered!")
			})

			it("is rendering text with status", () => {
				result = _controller.renderText(text = "OMG!", status = 418)

				expect(application.wo.$statusCode()).toBe(418)
			})

			it("is rendering text with doesnt hijack status", () => {
				cfheader(statuscode = 403)
				_controller.renderText(text = "OMG!")

				expect(application.wo.$statusCode()).toBe(403)
			})
		})

		describe("Tests that renderview", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test"}
				_controller = application.wo.controller("test", params)
			})

			it("is rendering current action", () => {
				result = _controller.renderView()

				expect(_controller.response()).toInclude("view template content")
			})

			it("is rendering view for another controller and action", () => {
				result = _controller.renderView(controller = "main", action = "template")

				expect(_controller.response()).toInclude("main controller template content")
			})

			it("is rendering view for another action", () => {
				result = _controller.renderView(action = "template")

				expect(_controller.response()).toInclude("specific template content")
			})

			it("is rendering specific template", () => {
				result = _controller.renderView(template = "template")

				expect(_controller.response()).toInclude("specific template content")
			})

			it("is rendering and returning as string", () => {
				result = _controller.renderView(returnAs = "string")

				expect(request.wheels).notToHaveKey('response')
				expect(result).toInclude("view template content")
			})

			it("is rendering view with status", () => {
				_controller.renderView(status = 418)

				expect(application.wo.$statusCode()).toBe(418)
			})
		})

		describe("Tests that renderwith", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test"}
				cfheader(statuscode = 200);
			})

			afterEach(() => {
				application.wo.$header(name = "content-type", value = "text/html", charset = "utf-8")
			})

			it("throws error without data argument", () => {
				_controller = application.wo.controller("test", params)

				expect(function() {
					result = _controller.renderWith()
				}).toThrow()
			})

			it("renders current action as xml with template returning string to controller", () => {
				params.format = "xml"
				_controller = application.wo.controller("test", params)
				_controller.provides("xml")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				data = _controller.renderWith(data = user, layout = false, returnAs = "string")

				expect(data).toInclude("xml template content")
			})

			it("renders current action as xml with template", () => {
				params.format = "xml"
				_controller = application.wo.controller("test", params)
				_controller.provides("xml")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				_controller.renderWith(data = user, layout = false)
				
				expect(_controller.response()).toInclude("xml template content")
			})

			it("renders current action as xml without template", () => {
				params.action = "test2"
				params.format = "xml"
				_controller = application.wo.controller("test", params)
				_controller.provides("xml")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				_controller.renderWith(data = user)

				expect(_controller.response()).toBeXML()
			})

			it("renders current action as xml without template returning string to controller", () => {
				params.action = "test2"
				params.format = "xml"
				_controller = application.wo.controller("test", params)
				_controller.provides("xml")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				data = _controller.renderWith(data = user, returnAs = "string")

				expect(data).toBeXML()
			})

			it("renders current action as json with template", () => {
				params.format = "json"
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				data = _controller.renderWith(data = user, layout = false)

				expect(_controller.response()).toInclude("json template content")
			})

			it("renders current action as json without template", () => {
				params.action = "test2"
				params.format = "json"
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				_controller.renderWith(data = user)

				expect(_controller.response()).toBeJSON()
			})

			it("renders current action as json without template returning string to controller", () => {
				params.action = "test2"
				params.format = "json"
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				data = _controller.renderWith(data = user, returnAs = "string")

				expect(data).toBeJSON()
			})

			it("throws error when rendering current action as pdf with template ", () => {
				params.format = "pdf"
				_controller = application.wo.controller("test", params)
				_controller.provides("pdf")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				
				expect(function() {
					_controller.renderWith(data = user, layout = false)
				}).toThrow()
			})

			it("throws error when template is not found for format", () => {
				params.format = "xls"
				params.action = "notfound"
				_controller = application.wo.controller("test", params)
				_controller.provides("xml")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				
				expect(function() {
					_controller.renderWith(data=user, layout=false, returnAs="string")
				}).toThrow("Wheels.RenderingError")
			})

			/* Custom Status Codes probably no need to test all 75 odd */
			it("returns custom status code when no argument is passed", () => {
				params.format = "json"
				params.action = "test2"
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				_controller.renderWith(data = user, layout = false, returnAs = "string")
				
				expect(application.wo.$statusCode()).toBe(200)
			})

			it("returns custom status code 403", () => {
				params.format = "json"
				params.action = "test2"
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				_controller.renderWith(data = user, layout = false, returnAs = "string", status = 403)
				
				expect(application.wo.$statusCode()).toBe(403)
			})

			it("returns custom status code 404", () => {
				params.format = "json"
				params.action = "test2"
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				_controller.renderWith(data = user, layout = false, returnAs = "string", status = 404)
				
				expect(application.wo.$statusCode()).toBe(404)
			})

			it("returns custom status codes with HTML", () => {
				params.format = "html"
				params.action = "test2"
				_controller = application.wo.controller("test", params)
				_controller.renderWith(data = "the rain in spain", layout = false, status = 403)
				
				expect(application.wo.$statusCode()).toBe(403)
			})

			it("returns custom status codes OK", () => {
				params.format = "json"
				params.action = "test2"
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				_controller.renderWith(data = user, layout = false, returnAs = "string", status = "OK")
				
				expect(application.wo.$statusCode()).toBe(200)
			})

			it("returns custom status codes Not Found", () => {
				GetPageContext().getResponse().setStatus("100")
				params.format = "json"
				params.action = "test2"
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				_controller.renderWith(data = user, layout = false, returnAs = "string", status = "Not Found")
				
				expect(application.wo.$statusCode()).toBe(404)
			})

			it("returns custom status codes Method Not Allowed", () => {
				GetPageContext().getResponse().setStatus("100")
				params.format = "json"
				params.action = "test2"
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				_controller.renderWith(data = user, layout = false, returnAs = "string", status = "Method Not Allowed")
				
				expect(application.wo.$statusCode()).toBe(405)
			})

			it("returns custom status codes Method Not Allowed case", () => {
				GetPageContext().getResponse().setStatus("100")
				params.format = "json"
				params.action = "test2"
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				_controller.renderWith(data = user, layout = false, returnAs = "string", status = "method not allowed")
				
				expect(application.wo.$statusCode()).toBe(405)
			})

			it("throws error when custom status codes bad numeric", () => {
				params.format = "json"
				params.action = "test2"
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				
				expect(function() {
					_controller.renderWith(data=user, layout=false, returnAs="string", status=987654321)
				}).toThrow("Wheels.RenderingError")
			})

			it("throws error when custom status codes bad text", () => {
				params.format = "json"
				params.action = "test2"
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				
				expect(function() {
					_controller.renderWith(data=user, layout=false, returnAs="string", status="THECAKEISALIE")
				}).toThrow("Wheels.RenderingError")
			})
		})
		
		describe("Tests that specified_layouts", () => {

			beforeEach(() => {
				request.cgi.http_x_requested_with = ""
				params = {controller = "dummy", action = "index"}
				_controller = application.wo.controller("dummy", params)
			})

			it("is using method match", () => {
				args = {template = "controller_layout_test"}
				_controller.controller_layout_test = controller_layout_test
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("index")).toBe("index_layout")
			})

			it("is using method match2", () => {
				args = {template = "controller_layout_test"}
				_controller.controller_layout_test = controller_layout_test
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("show")).toBe("show_layout")
			})

			it("is using method no match", () => {
				args = {template = "controller_layout_test"}
				_controller.controller_layout_test = controller_layout_test
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("list")).toBeTrue()
			})

			it("is using method no match no default", () => {
				args = {template = "controller_layout_test", usedefault = false}
				_controller.controller_layout_test = controller_layout_test
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("list")).toBeFalse()
			})

			it("should fallback to template for ajax request with no layout specified", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				args = {template = "controller_layout_test"}
				_controller.controller_layout_test = controller_layout_test
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("index")).toBe("index_layout")
			})

			it("is using method ajax match", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				args = {template = "controller_layout_test", ajax = "controller_layout_test_ajax"}
				_controller.controller_layout_test = controller_layout_test
				_controller.controller_layout_test_ajax = controller_layout_test_ajax
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("index")).toBe("index_layout_ajax")
			})

			it("is using method ajax match2", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				args = {template = "controller_layout_test", ajax = "controller_layout_test_ajax"}
				_controller.controller_layout_test = controller_layout_test
				_controller.controller_layout_test_ajax = controller_layout_test_ajax;
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("show")).toBe("show_layout_ajax")
			})

			it("is using method ajax no match", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				args = {template = "controller_layout_test", ajax = "controller_layout_test_ajax"}
				_controller.controller_layout_test = controller_layout_test
				_controller.controller_layout_test_ajax = controller_layout_test_ajax;
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("list")).toBeTrue()
			})

			it("is using method ajax no match no default", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				args = {template = "controller_layout_test", ajax = "controller_layout_test_ajax", usedefault = false}
				_controller.controller_layout_test = controller_layout_test
				_controller.controller_layout_test_ajax = controller_layout_test_ajax;
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("list")).toBeFalse()
			})

			it("should respect exceptions no match", () => {
				args = {template = "mylayout", except = "index"}
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("show")).toBe("mylayout")
			})

			it("should respect exceptions match", () => {
				args = {template = "mylayout", except = "index"}
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("index")).toBeTrue()
			})

			it("should respect exceptions match no default", () => {
				args = {template = "mylayout", except = "index", usedefault = false}
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("index")).toBeFalse()
			})

			it("should respect exceptions ajax no match", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				args = {template = "mylayout", ajax = "mylayout_ajax", except = "index"}
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("show")).toBe("mylayout_ajax")
			})

			it("should respect exceptions ajax match", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				args = {template = "mylayout", ajax = "mylayout_ajax", except = "index"}
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("index")).toBeTrue()
			})

			it("should respect exceptions ajax match no default", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				args = {template = "mylayout", ajax = "mylayout_ajax", except = "index", usedefault = false}
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("index")).toBeFalse()
			})

			it("should respect only no match", () => {
				args = {template = "mylayout", only = "index"}
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("show")).toBeTrue()
			})

			it("should respect only match", () => {
				args = {template = "mylayout", only = "index"}
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("index")).toBe("mylayout")
			})

			it("should respect only no match no default", () => {
				args = {template = "mylayout", only = "index", usedefault = false}
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("show")).toBeFalse()
			})
			
			it("should respect only ajax no match", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				args = {template = "mylayout", ajax = "mylayout_ajax", only = "index"}
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("show")).toBeTrue()
			})

			it("should respect only ajax match", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				args = {template = "mylayout", ajax = "mylayout_ajax", only = "index"}
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("index")).toBe("mylayout_ajax")
			})

			it("should respect only ajax no match no default", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				args = {template = "mylayout", ajax = "mylayout_ajax", only = "index", usedefault = false}
				_controller.usesLayout(argumentCollection = args)

				expect(_controller.$useLayout("show")).toBeFalse()
			})
		})
	}

	function $injectIntoVariablesScope(required string name, required any data) {
		variables[arguments.name] = arguments.data
	}

	function controller_layout_test() {
		if (arguments.action eq "index") {
			return "index_layout"
		}
		if (arguments.action eq "show") {
			return "show_layout"
		}
	}

	function controller_layout_test_ajax() {
		if (arguments.action eq "index") {
			return "index_layout_ajax"
		}
		if (arguments.action eq "show") {
			return "show_layout_ajax"
		}
	}
}