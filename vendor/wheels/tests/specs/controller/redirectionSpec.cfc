component extends="wheels.WheelsTest" {

	function run() {

		describe("Tests that redirectto", () => {

			beforeEach(() => {
				params = {controller = "test", action = "testRedirect"}
				_controller = application.wo.controller("test", params)
				copies.request.cgi = request.cgi
			})

			afterEach(() => {
				request.cgi = copies.request.cgi
			})

			it("throws error on double redirect", () => {
				_controller.redirectTo(action = "test")

				expect(function(){
					_controller.redirectTo(action = "test")
				}).toThrow("Wheels.RedirectToAlreadyCalled")
			})

			it("allows remaining action code to run", () => {
				_controller.$callAction(action = "testRedirect")
				r = _controller.getRedirect()

				expect(r).toHaveKey("url")
				expect(request).toHaveKey("setInActionAfterRedirect")
			})

			it("redirects to action", () => {
				_controller.redirectTo(action = "test")
				r = _controller.getRedirect()

				expect(_controller.$performedRedirect()).toBeTrue()
				expect(r).toHaveKey("url")
			})

			it("is passing through to urlfor", () => {
				args = {action = "test", onlyPath = false, protocol = "https", params = "test1=1&test2=2"}
				_controller.redirectTo(argumentCollection = args)
				r = _controller.getRedirect()

				expect(r.url).toInclude(args.protocol)
				expect(r.url).toInclude(args.params)
			})

			it("is setting cflocation attributes", () => {
				_controller.redirectTo(action = "test", addToken = true, statusCode = "301")
				r = _controller.getRedirect()

				expect(r.addToken).toBeTrue()
				expect(r.statusCode).toBe(301)
			})

			it("is redirecting to referrer", () => {
				path = "/test-controller/test-action"
				request.cgi.http_referer = "http://" & request.cgi.server_name & path
				_controller.redirectTo(back = true)
				r = _controller.getRedirect()

				expect(r.url).toInclude(path)
			})

			it("is appending params to referrer", () => {
				path = "/test-controller/test-action"
				request.cgi.http_referer = "http://" & request.cgi.server_name & path
				_controller.redirectTo(back = true, params = "x=1&y=2")
				r = _controller.getRedirect()

				expect(r.url).toInclude(path)
				expect(r.url).toInclude("?x=1&y=2")
			})

			it("is redirecting to action on blank referrer", () => {
				request.cgi.http_referer = ""
				_controller.redirectTo(back = true, action = "blankRef")
				r = _controller.getRedirect()

				expect(r.url).toBe(application.wo.URLFor(action = 'blankRef', controller = 'test'))
			})

			it("is redirecting to root on blank referrer", () => {
				request.cgi.http_referer = ""
				_controller.redirectTo(back = true)
				r = _controller.getRedirect()

				expect(r.url).toBe(application.wheels.webPath)
			})

			it("is redirecting to root on foreign referrer", () => {
				request.cgi.http_referer = "http://www.google.com"
				_controller.redirectTo(back = true)
				r = _controller.getRedirect()

				expect(r.url).toBe(application.wheels.webPath)
			})

			it("is redirecting to URL", () => {
				_controller.redirectTo(url = "http://" & request.cgi.server_name & "/some-page")
				r = _controller.getRedirect()

				expect(_controller.$performedRedirect()).toBeTrue()
				expect(r).toHaveKey("url")
			})

			it("is redirecting to relative URL", () => {
				_controller.redirectTo(url = "/some-page")
				r = _controller.getRedirect()

				expect(_controller.$performedRedirect()).toBeTrue()
				expect(r.url).toBe("/some-page")
			})

			it("is redirecting to URL with params", () => {
				_controller.redirectTo(url = "http://" & request.cgi.server_name & "/page", params = "foo=bar")
				actual = _controller.getRedirect().url
				expected = "http://" & request.cgi.server_name & "/page?foo=bar"

				expect(actual).toBe(expected)
			})

			it("is redirecting to URL with query string and with params", () => {
				_controller.redirectTo(url = "http://" & request.cgi.server_name & "/page?foo=bar", params = "baz=qux")
				actual = _controller.getRedirect().url
				expected = "http://" & request.cgi.server_name & "/page?foo=bar&baz=qux"

				expect(actual).toBe(expected)
			})
		})

		describe("Tests that redirectto prevents open redirect", () => {

			beforeEach(() => {
				params = {controller = "test", action = "testRedirect"}
				_controller = application.wo.controller("test", params)
				copies.request.cgi = request.cgi
			})

			afterEach(() => {
				request.cgi = copies.request.cgi
			})

			it("rejects referer with server name in query string", () => {
				request.cgi.http_referer = "http://attacker.com?url=http://" & request.cgi.server_name
				_controller.redirectTo(back = true)
				r = _controller.getRedirect()

				expect(r.url).toBe(application.wheels.webPath)
			})

			it("rejects referer with server name as subdomain of attacker", () => {
				request.cgi.http_referer = "http://" & request.cgi.server_name & ".attacker.com/page"
				_controller.redirectTo(back = true)
				r = _controller.getRedirect()

				expect(r.url).toBe(application.wheels.webPath)
			})

			it("accepts referer with exact server name match", () => {
				path = "/test-controller/test-action"
				request.cgi.http_referer = "http://" & request.cgi.server_name & path
				_controller.redirectTo(back = true)
				r = _controller.getRedirect()

				expect(r.url).toInclude(path)
			})

			it("accepts referer with exact server name and port", () => {
				path = "/test-controller/test-action"
				request.cgi.http_referer = "http://" & request.cgi.server_name & ":8080" & path
				_controller.redirectTo(back = true)
				r = _controller.getRedirect()

				expect(r.url).toInclude(path)
			})

			it("accepts referer with https scheme", () => {
				path = "/secure-page"
				request.cgi.http_referer = "https://" & request.cgi.server_name & path
				_controller.redirectTo(back = true)
				r = _controller.getRedirect()

				expect(r.url).toInclude(path)
			})

			it("rejects referer with server name in path", () => {
				request.cgi.http_referer = "http://evil.com/" & request.cgi.server_name
				_controller.redirectTo(back = true)
				r = _controller.getRedirect()

				expect(r.url).toBe(application.wheels.webPath)
			})

			it("throws on redirectTo url with external domain", () => {
				expect(function(){
					_controller.redirectTo(url = "http://evil.com/phish")
				}).toThrow("Wheels.UnsafeRedirect")
			})

			it("allows redirectTo url with relative path", () => {
				_controller.redirectTo(url = "/safe/path")
				r = _controller.getRedirect()

				expect(r.url).toBe("/safe/path")
			})

			it("allows redirectTo url matching current domain", () => {
				_controller.redirectTo(url = "http://" & request.cgi.server_name & "/page")
				r = _controller.getRedirect()

				expect(r.url).toBe("http://" & request.cgi.server_name & "/page")
			})

			it("throws on redirectTo url with protocol-relative external domain", () => {
				expect(function(){
					_controller.redirectTo(url = "//evil.com/phish")
				}).toThrow("Wheels.UnsafeRedirect")
			})

			it("allows redirectTo url with protocol-relative same domain", () => {
				_controller.redirectTo(url = "//" & request.cgi.server_name & "/page")
				r = _controller.getRedirect()

				expect(r.url).toBe("//" & request.cgi.server_name & "/page")
			})

			it("allows external redirect when allowExternalRedirects is true", () => {
				application.wheels.allowExternalRedirects = true;
				try {
					_controller.redirectTo(url = "http://external.com/page")
					r = _controller.getRedirect()

					expect(r.url).toBe("http://external.com/page")
				} finally {
					application.wheels.allowExternalRedirects = false;
				}
			})
		})
	}
}
