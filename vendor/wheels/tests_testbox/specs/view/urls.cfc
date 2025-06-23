component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that buttonTo", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				oldURLRewriting = application.wheels.URLRewriting
				application.wheels.URLRewriting = "On"
				oldScriptName = request.cgi.script_name
				request.cgi.script_name = "/index.cfm"
				g.set(functionName = "buttonTo", encode = false)
				if (StructKeyExists(request, "$wheelsProtectedFromForgery")) {
					$oldrequestfromforgery = request.$wheelsProtectedFromForgery
				}
				request.$wheelsProtectedFromForgery = true
			})

			afterEach(() => {
				application.wheels.URLRewriting = oldURLRewriting
				request.cgi.script_name = oldScriptName
				g.set(functionName = "buttonTo", encode = true)
				if (StructKeyExists(variables, "$oldrequestfromforgery")) {
					request.$wheelsProtectedFromForgery = $oldrequestfromforgery
				}
			})

			it("works with inner encoding", () => {
				actual = _controller.buttonTo(
					text = "<Click>",
					class = "form-class",
					inputClass = "input class",
					confirm = "confirm-value",
					disable = "disable-value",
					encode = true
				)
				expected = '<form action="#application.wheels.webpath#" class="form-class" confirm="confirm-value" disable="disable-value" method="post"><button class="input&##x20;class" type="submit" value="save">' & '&lt;Click&gt;' & '</button>' & _controller.authenticityTokenField() & '</form>';
				
				expect(actual).toBe(expected)
			})

			it("works with inner icon", () => {
				actual = _controller.buttonTo(
					text = "<i class='fa fa-icon' /> Edit",
					class = "form-class",
					inputClass = "input class",
					confirm = "confirm-value",
					disable = "disable-value",
					encode = 'attributes',
					value = "customvalue"
				)
				expected = '<form action="#application.wheels.webpath#" class="form-class" confirm="confirm-value" disable="disable-value" method="post" value="customvalue"><button class="input&##x20;class" type="submit" value="save">' & '<i class=''fa fa-icon'' /> Edit' & '</button>' & _controller.authenticityTokenField() & '</form>'
				
				expect(actual).toBe(expected)
			})

			it("works with attributes", () => {
				actual = _controller.buttonTo(
					class = "form-class",
					inputClass = "input-class",
					confirm = "confirm-value",
					disable = "disable-value"
				)
				expected = '<form action="#application.wheels.webpath#" class="form-class" confirm="confirm-value" disable="disable-value" method="post"><button class="input-class" type="submit" value="save">' & '</button>' & _controller.authenticityTokenField() & '</form>'

				expect(actual).toBe(expected)
			})

			it("works with delete method arguments", () => {
				actual = _controller.buttonTo(method = "delete")
				expected = '<form action="#application.wheels.webpath#" method="post"><input id="_method" name="_method" type="hidden" value="delete"><button type="submit" value="save">' & '</button>' & _controller.authenticityTokenField() & '</form>'
				
				expect(actual).toBe(expected)
			})

			it("works with put method arguments", () => {
				actual = _controller.buttonTo(method = "put")
				expected = '<form action="#application.wheels.webpath#" method="post"><input id="_method" name="_method" type="hidden" value="put"><button type="submit" value="save">' & '</button>' & _controller.authenticityTokenField() & '</form>'
				
				expect(actual).toBe(expected)
			})

			it("works with get method arguments", () => {
				actual = _controller.buttonTo(method = "get")
				expected = '<form action="#application.wheels.webpath#" method="get"><button type="submit" value="save"></button></form>'
				
				expect(actual).toBe(expected)
			})
		})

		describe("Tests that linkTo", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				oldURLRewriting = application.wheels.URLRewriting
				application.wheels.URLRewriting = "On"
				oldScriptName = request.cgi.script_name
				request.cgi.script_name = "/index.cfm"
				g.set(functionName = "linkTo", encode = false)
			})

			afterEach(() => {
				application.wheels.URLRewriting = oldURLRewriting
				request.cgi.script_name = oldScriptName
				g.set(functionName = "linkTo", encode = true)
			})

			it("ampersand and equals sign encoding", () => {
				e = '<a href="#application.wheels.webpath#x/x?a=cats%26dogs%3Dtrouble&b=1">x</a>'
				r = _controller.linkTo(text = "x", controller = "x", action = "x", params = "a=cats%26dogs%3Dtrouble&b=1")

				expect(e).toBe(r)
			})

			it("does not attribute encode href", () => {
				e = '<a class="we&##x27;re" href="/we&##x25;27re/x?x=1&y=2&##x2b;3">x</a>'
				g.set(functionName = "linkTo", encode = true)
				r = _controller.linkTo(class = "we're", text = "x", controller = "we're", action = "x", params = "x=1&y=2 3")
				g.set(functionName = "linkTo", encode = false)

				expect(e).toBe(r)
			})

			it("does not encode dash", () => {
				e = 'ca-ts">x</a>'
				g.set(functionName = "linkTo", encode = true)
				r = Right(_controller.linkTo(text = "x", controller = "x", action = "x", params = "cats=ca-ts"), 12)
				g.set(functionName = "linkTo", encode = false)

				expect(e).toBe(r)
			})

			it("works with controller action only", () => {
				e = '<a href="#application.wheels.webpath#account/logout">Log Out</a>'
				r = _controller.linkTo(text = "Log Out", controller = "account", action = "logout")

				expect(e).toBe(r)
			})

			it("works with external links", () => {
				e = '<a href="http://www.cfwheels.com">CFWheels</a>'
				r = _controller.linkTo(href = "http://www.cfwheels.com", text = "CFWheels")
		
				expect(e).toBe(r)
			})

			it("works with linkto arguments", () => {
				e = '<a confirm="confirm-value" disabled="disabled-value" href="/">CFWheels</a>'
				r = _controller.linkTo(href = "/", text = "CFWheels", confirm = "confirm-value", disabled = "disabled-value")
		
				expect(e).toBe(r)
			})
		})

		describe("Tests that mailTo", () => {

			it("is valid", () => {
				_controller = g.controller(name = "dummy")
				_controller.mailTo(emailAddress = "webmaster@yourdomain.com", name = "Contact our Webmaster")
			})
		})

		describe("Tests that pagination", () => {

			it("is valid", () => {
				_controller = g.controller(name = "dummy")
				user = g.model("_c_o_r_e_users")
				e = user.findAll(
					where = "firstname = 'somemoron'",
					perpage = "2",
					page = "1",
					handle = "pagination_test_1",
					order = "id"
				)

				_controller.pagination("pagination_test_1")
			})
		})

		describe("Tests that URLFor", () => {

			beforeEach(() => {
				params.controller = "blog"
				params.action = "edit"
				params.key = "1"
				_controller = g.controller(params.controller, params)
				args = {}
				args.controller = "blog"
				args.action = "edit"
				args.key = "1"
				args.params = "param1=foo&param2=bar"
				args.$URLRewriting = "On"
				oldScriptName = request.cgi.script_name
			})

			afterEach(() => {
				request.cgi.script_name = oldScriptName
			})

			it("works with ampersand in params with URL rewriting", () => {
				request.cgi.script_name = "/index.cfm"
				e = '#application.wheels.webpath#x/x?a=c+ats%26dogs&b=a+c'
				r = _controller.URLFor(controller = "x", action = "x", params = "a=c ats%26dogs&b=a c", encode = true)

				expect(e).toBe(r)
			})

			it("works with all arguments with URL rewriting", () => {
				request.cgi.script_name = "/index.cfm"
				e = "#application.wheels.webpath#blog/edit/1?param1=foo&param2=bar"
				r = _controller.urlFor(argumentcollection = args)
				
				expect(e).toBe(r)
			})

			it("works with missing controller with URL rewriting", () => {
				request.cgi.script_name = "/index.cfm"
				StructDelete(args, "controller")
				e = "#application.wheels.webpath#blog/edit/1?param1=foo&param2=bar"
				r = _controller.urlFor(argumentcollection = args)
				
				expect(e).toBe(r)
			})

			it("works with missing action with URL rewriting", () => {
				request.cgi.script_name = "/index.cfm"
				StructDelete(args, "action")
				e = "#application.wheels.webpath#blog/index/1?param1=foo&param2=bar"
				r = _controller.urlFor(argumentcollection = args)
				
				expect(e).toBe(r)
			})

			it("works with missing controller and action with URL rewriting", () => {
				request.cgi.script_name = "/index.cfm"
				StructDelete(args, "controller")
				StructDelete(args, "action")
				e = "#application.wheels.webpath#blog/edit/1?param1=foo&param2=bar"
				r = _controller.urlFor(argumentcollection = args)
				
				expect(e).toBe(r)
			})

			it("works with missing controller, action and key with URL rewriting", () => {
				request.cgi.script_name = "/index.cfm"
				StructDelete(args, "controller")
				StructDelete(args, "action")
				StructDelete(args, "key")
				e = "#application.wheels.webpath#blog/edit?param1=foo&param2=bar"
				r = _controller.urlFor(argumentcollection = args)
				
				expect(e).toBe(r)
			})

			it("works with missing controller, action, key and params with URL rewriting", () => {
				request.cgi.script_name = "/index.cfm"
				StructDelete(args, "controller")
				StructDelete(args, "action")
				StructDelete(args, "key")
				StructDelete(args, "params")
				e = "#application.wheels.webpath#blog/edit"
				r = _controller.urlFor(argumentcollection = args)
				
				expect(e).toBe(r)
			})

			it("works with all arguments without URL rewriting", () => {
				request.cgi.script_name = "/index.cfm"
				args.$URLRewriting = "Off"
				webRoot = Replace("#application.wheels.webpath##ListLast(request.cgi.script_name, '/')#", "//", "/")
				e = "#webRoot#?controller=blog&action=edit&key=1&param1=foo&param2=bar"
				r = _controller.urlFor(argumentcollection = args)
				
				expect(e).toBe(r)
			})

			it("works with ampersand in params without URL rewriting", () => {
				request.cgi.script_name = "/index.cfm"
				webRoot = Replace("#application.wheels.webpath##ListLast(request.cgi.script_name, '/')#", "//", "/")
				e = "#webRoot#?controller=x&action=x&a=c+ats%26dogs&b=a+c"
				r = _controller.urlFor(
					controller = "x",
					action = "x",
					params = "a=c ats%26dogs&b=a c",
					encode = true,
					$URLRewriting = "Off"
				)

				expect(e).toBe(r)
			})

			it("works with missing controller without URL rewriting", () => {
				request.cgi.script_name = "/index.cfm"
				args.$URLRewriting = "Off"
				StructDelete(args, "controller")
				webRoot = Replace("#application.wheels.webpath##ListLast(request.cgi.script_name, '/')#", "//", "/")
				e = "#webRoot#?controller=blog&action=edit&key=1&param1=foo&param2=bar"
				r = _controller.urlFor(argumentcollection = args)
				
				expect(e).toBe(r)
			})

			it("works with missing action without URL rewriting", () => {
				request.cgi.script_name = "/index.cfm"
				args.$URLRewriting = "Off"
				StructDelete(args, "action")
				webRoot = Replace("#application.wheels.webpath##ListLast(request.cgi.script_name, '/')#", "//", "/")
				e = "#webRoot#?controller=blog&action=index&key=1&param1=foo&param2=bar"
				r = _controller.urlFor(argumentcollection = args)
				
				expect(e).toBe(r)
			})

			it("works with missing controller and action without URL rewriting", () => {
				request.cgi.script_name = "/index.cfm"
				args.$URLRewriting = "Off"
				StructDelete(args, "controller")
				StructDelete(args, "action")
				webRoot = Replace("#application.wheels.webpath##ListLast(request.cgi.script_name, '/')#", "//", "/")
				e = "#webRoot#?controller=blog&action=edit&key=1&param1=foo&param2=bar"
				r = _controller.urlFor(argumentcollection = args)
				
				expect(e).toBe(r)
			})
		})
	}
}