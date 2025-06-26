component extends="testbox.system.BaseSpec" {

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
				_controller.redirectTo(url = "http://www.google.com")
				r = _controller.getRedirect()

				expect(_controller.$performedRedirect()).toBeTrue()
				expect(r).toHaveKey("url")
			})

			it("is redirecting to URL with params", () => {
				_controller.redirectTo(url = "http://www.google.com", params = "foo=bar")
				actual = _controller.getRedirect().url
				expected = "http://www.google.com?foo=bar"

				expect(actual).toBe(expected)
			})

			it("is redirecting to URL with query string and with params", () => {
				_controller.redirectTo(url = "http://www.google.com?foo=bar", params = "baz=qux")
				actual = _controller.getRedirect().url
				expected = "http://www.google.com?foo=bar&baz=qux"

				expect(actual).toBe(expected)
			})
		})
	}
}