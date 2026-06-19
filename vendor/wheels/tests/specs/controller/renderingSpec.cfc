component extends="wheels.WheelsTest" {

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
				tempFile = ExpandPath("/wheels/tests/_assets/views/test/layout.cfm")
				FileWrite(tempFile, "<cfoutput>start:controllerlayout##includeContent()##end:controllerlayout</cfoutput>")
				application.wheels.layoutFileCache["test"] = true
				_controller.renderView()
				r = _controller.response()

				expect(r).toInclude("view template content")
				expect(r).toInclude("start:controllerlayout")
				expect(r).toInclude("end:controllerlayout")

				StructDelete(application.wheels.layoutFileCache, "test")
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

			it("falls back to html when onlyProvides excludes the requested format", () => {
				params.format = "xml"
				_controller = application.wo.controller("test", params)
				_controller.provides("xml")
				_controller.onlyProvides(formats = "json", action = "test")
				user = application.wo.model("user").findOne(where = "username = 'tonyp'")
				data = _controller.renderWith(data = user, layout = false, returnAs = "string")

				// Clean up before asserting: controller class data is cached in the
				// application scope and shared by reference across specs.
				StructDelete(_controller.$getControllerClassData().formats.actions, "test")

				expect(data).notToInclude("xml template content")
				expect(data).toInclude("view template content")
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

		describe("Tests that renderwith json type coercion", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test2", format = "json"}
				cfheader(statuscode = 200);
				_controller = application.wo.controller("test", params)
				_controller.provides("json")
			})

			afterEach(() => {
				application.wo.$header(name = "content-type", value = "text/html", charset = "utf-8")
			})

			it("forces extra named args marked string to serialize as JSON strings", () => {
				row1 = {}
				row1["zip"] = "01234"
				row2 = {}
				row2["zip"] = "99999"
				rows = [row1, row2]
				data = _controller.renderWith(data = rows, layout = false, returnAs = "string", zip = "string")

				expect(data).toInclude('"zip":"01234"')
				expect(data).toInclude('"zip":"99999"')
				// No marker bytes (raw or JSON-escaped) may leak into the payload.
				expect(Find(Chr(7), data)).toBe(0)
				expect(data).notToInclude("\u0007")
			})

			it("preserves BEL bytes in data values when no coercion is requested", () => {
				row1 = {}
				row1["note"] = "alert" & Chr(7) & "bell"
				rows = [row1]
				data = _controller.renderWith(data = rows, layout = false, returnAs = "string")
				parsed = DeserializeJSON(data)

				expect(Find(Chr(7), parsed[1]["note"])).toBeGT(0)
			})

			it("preserves BEL bytes elsewhere in the payload when string coercion is requested", () => {
				row1 = {}
				row1["zip"] = "01234"
				row1["note"] = "a" & Chr(7) & "b"
				rows = [row1]
				data = _controller.renderWith(data = rows, layout = false, returnAs = "string", zip = "string")
				parsed = DeserializeJSON(data)

				expect(data).toInclude('"zip":"01234"')
				expect(Find(Chr(7), parsed[1]["note"])).toBeGT(0)
			})

			it("forces extra named args marked integer to serialize without decimal point", () => {
				row1 = {}
				row1["total"] = JavaCast("double", 5)
				rows = [row1]
				data = _controller.renderWith(data = rows, layout = false, returnAs = "string", total = "integer")

				expect(data).toInclude('"total":5')
				expect(data).notToInclude('"total":5.0')
			})

			it("does not rewrite nested same-named keys when coercing integers", () => {
				row1 = {}
				row1["total"] = JavaCast("double", 5)
				child = {}
				child["total"] = JavaCast("double", 7)
				row1["child"] = child
				rows = [row1]
				data = _controller.renderWith(data = rows, layout = false, returnAs = "string", total = "integer")
				parsed = DeserializeJSON(data)

				expect(data).notToInclude('"total":5.0')
				// The nested same-named key must serialize exactly as the engine does
				// natively (the legacy per-key regex also rewrote nested keys, e.g. 7.0 -> 7
				// on engines that emit a .0 suffix for doubles).
				probeChild = {}
				probeChild["total"] = JavaCast("double", 7)
				expect(data).toInclude(SerializeJSON(probeChild))
				expect(parsed[1]["child"]["total"]).toBe(7)
			})

			it("coerces top-level struct data keys marked integer", () => {
				payload = {}
				payload["total"] = JavaCast("double", 5)
				data = _controller.renderWith(data = payload, layout = false, returnAs = "string", total = "integer")

				expect(data).toInclude('"total":5')
				expect(data).notToInclude('"total":5.0')
			})

			it("coerces top-level struct data keys marked string", () => {
				payload = {}
				payload["zip"] = "01234"
				payload["note"] = "a" & Chr(7) & "b"
				data = _controller.renderWith(data = payload, layout = false, returnAs = "string", zip = "string")
				parsed = DeserializeJSON(data)

				expect(data).toInclude('"zip":"01234"')
				// No marker residue may remain in the coerced value. Whether a surviving
				// BEL byte serializes as a raw byte or as a backslash-u escape is a
				// Lucee-build detail, so assert on the round-tripped values rather than
				// the payload text (text checks would contradict BEL survival below).
				expect(Find(Chr(7), parsed["zip"])).toBe(0)
				expect(parsed["zip"]).toBe("01234")
				// Legitimate BEL bytes inside other string values must survive the strip.
				expect(Find(Chr(7), parsed["note"])).toBeGT(0)
			})

			it("skips rows that do not contain the coerced key", () => {
				row1 = {}
				row1["zip"] = "01234"
				row2 = {}
				row2["other"] = "x"
				rows = [row1, row2]
				data = _controller.renderWith(data = rows, layout = false, returnAs = "string", zip = "string")

				expect(data).toInclude('"zip":"01234"')
				expect(data).toInclude('"other":"x"')
			})

			it("does not treat the status argument as a coercion directive", () => {
				row1 = {}
				row1["zip"] = "01234"
				rows = [row1]
				data = _controller.renderWith(data = rows, layout = false, returnAs = "string", status = 201, zip = "string")

				expect(application.wo.$statusCode()).toBe(201)
				expect(data).toInclude('"zip":"01234"')
			})

			it("leaves non-integral numeric values untouched under integer coercion", () => {
				row1 = {}
				row1["total"] = JavaCast("double", 5.25)
				rows = [row1]
				data = _controller.renderWith(data = rows, layout = false, returnAs = "string", total = "integer")

				expect(data).toInclude('"total":5.25')
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

		describe("Tests that $callAction respects explicit rendering", () => {

			it("does not trigger view lookup when renderText is called in an action", () => {
				// Use the dummy controller which has no view files.
				// Inject an action that calls renderText().
				params = {controller = "dummy", action = "renderTextAction"}
				_controller = application.wo.controller("dummy", params)
				var ctx = {ctrl: _controller}
				_controller.renderTextAction = function() {
				ctx.ctrl.renderText("hello from renderText");
				}

				// $callAction should NOT throw ViewNotFound because
				// renderText sets the response before the auto-render block.
				_controller.$callAction(action = "renderTextAction")

				expect(_controller.response()).toBe("hello from renderText")
			})

			it("does not trigger view lookup when renderNothing is called in an action", () => {
				params = {controller = "dummy", action = "renderNothingAction"}
				_controller = application.wo.controller("dummy", params)
				var ctx = {ctrl: _controller}
				_controller.renderNothingAction = function() {
				ctx.ctrl.renderNothing();
				}

				_controller.$callAction(action = "renderNothingAction")

				expect(_controller.response()).toBe("")
			})

			it("re-throws action errors instead of producing ViewNotFound", () => {
				params = {controller = "dummy", action = "brokenAction"}
				_controller = application.wo.controller("dummy", params)
				_controller.brokenAction = function() {
					Throw(type = "CustomAppError", message = "Something broke in the action");
				}

				expect(function() {
					_controller.$callAction(action = "brokenAction")
				}).toThrow("CustomAppError")
			})

			it("skips view lookup when renderWith was attempted but failed", () => {
				// Simulate renderWith being called by setting the flag directly.
				params = {controller = "dummy", action = "noViewAction"}
				_controller = application.wo.controller("dummy", params)

				// Manually mark renderWith as attempted (simulates renderWith()
				// entering and then failing before it could call renderText).
				_controller.$injectIntoVariablesScope = this.$injectInstanceFlag
				_controller.$injectIntoVariablesScope()

				// The auto-render block should skip view lookup because
				// renderWith was attempted.
				expect(_controller.$renderWithAttempted()).toBeTrue()
			})

			it("skips view rendering when onlyProvides excludes the requested non-html format", () => {
				// Closes the gap on processing.cfc:165 — the $callAction auto-render
				// branch that becomes reachable now that $acceptableFormats reads
				// the .actions sub-struct. Requesting xml against an action whose
				// onlyProvides allows only json must NOT fall through to renderView
				// (and therefore not throw ViewNotFound) — shouldRenderView is set
				// to false and the response stays empty.
				params = {controller = "dummy", action = "noViewAction", format = "xml"}
				_controller = application.wo.controller("dummy", params)
				_controller.noViewAction = function() {
					// no-op action; exercises the auto-render path
				}
				_controller.onlyProvides(formats = "json", action = "noViewAction")

				captured = ""
				try {
					_controller.$callAction(action = "noViewAction")
					captured = _controller.response()
				} finally {
					// Controller class data is cached in the application scope and
					// shared by reference across specs — clean up either way.
					StructDelete(_controller.$getControllerClassData().formats.actions, "noViewAction")
				}

				expect(captured).toBe("")
			})
		})

		describe("Tests that $getStatusCodes is memoized", () => {

			beforeEach(() => {
				params = {controller = "dummy", action = "dummy"}
				_controller = application.wo.controller("dummy", params)
				appKey = StructKeyExists(application, "$wheels") ? "$wheels" : "wheels"
			})

			it("memoizes the status code map and its reverse lookup in the application scope", () => {
				StructDelete(application[appKey], "statusCodes")
				StructDelete(application[appKey], "statusCodeLookup")

				codes = _controller.$getStatusCodes()

				expect(codes["404"]).toBe("Not Found")
				expect(StructKeyExists(application[appKey], "statusCodes")).toBeTrue()
				expect(StructKeyExists(application[appKey], "statusCodeLookup")).toBeTrue()
			})

			it("returns the memoized struct on subsequent calls instead of rebuilding it", () => {
				_controller.$getStatusCodes()
				application[appKey].statusCodes["999"] = "Memo Marker"
				try {
					codes = _controller.$getStatusCodes()
					expect(StructKeyExists(codes, "999")).toBeTrue()
				} finally {
					StructDelete(application[appKey].statusCodes, "999")
					StructDelete(application[appKey], "statusCodeLookup")
					StructDelete(application[appKey], "statusCodes")
				}
			})

			it("resolves status text to a code and code to text", () => {
				expect(_controller.$returnStatusCode("Not Found")).toBe(404)
				expect(_controller.$returnStatusText(404)).toBe("Not Found")
			})

			it("resolves a duplicated status text to the lowest matching code", () => {
				// 427, 430, and 509 all carry the text "Unassigned"
				expect(_controller.$returnStatusCode("Unassigned")).toBe(427)
			})

			it("still throws on unknown codes and texts", () => {
				expect(() => {
					_controller.$returnStatusText(999)
				}).toThrow("Wheels.RenderingError")
				expect(() => {
					_controller.$returnStatusCode("No Such Status")
				}).toThrow("Wheels.RenderingError")
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

	function $injectInstanceFlag() {
		variables.$instance.renderWithAttempted = true;
	}
}