/**
 * Hardener BLOCKERs B1–B3 (dispatch / request lifecycle).
 *
 * Directory-scoped so `wheels test --core --ci --filter=hardener`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("B1 $ensureControllerAndAction ignores untrusted retarget", () => {

			beforeEach(() => {
				dispatch = CreateObject("component", "wheels.Dispatch")
				args = {}
				args.path = "posts"
				args.format = ""
				args.route = {
					pattern = "/posts",
					controller = "posts",
					action = "index",
					regex = "^\/posts\/?$",
					variables = "",
					on = "",
					package = "",
					methods = "get",
					name = "posts"
				}
				args.formScope = {}
				args.urlScope = {}
				_hadHttpData = StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "httpRequestData")
				_priorHttpData = _hadHttpData ? request.wheels.httpRequestData : {}
			})

			afterEach(() => {
				if (_hadHttpData) {
					request.wheels.httpRequestData = _priorHttpData
				} else if (StructKeyExists(request, "wheels")) {
					StructDelete(request.wheels, "httpRequestData")
				}
			})

			it("does not let a query string retarget a routed controller and action", () => {
				args.urlScope.controller = "admin"
				args.urlScope.action = "delete"
				var params = dispatch.$createParams(argumentCollection = args)

				expect(params.controller).toBeWithCase("Posts")
				expect(params.action).toBe("index")
			})

			it("does not let a form field retarget a routed controller and action", () => {
				args.formScope.controller = "admin"
				args.formScope.action = "delete"
				var params = dispatch.$createParams(argumentCollection = args)

				expect(params.controller).toBeWithCase("Posts")
				expect(params.action).toBe("index")
			})

			it("does not let a JSON body retarget a routed controller and action", () => {
				request.wheels.httpRequestData = {
					headers = {"Content-Type" = "application/json"},
					content = '{"controller":"admin","action":"delete"}'
				}
				var params = dispatch.$createParams(argumentCollection = args)

				expect(params.controller).toBeWithCase("Posts")
				expect(params.action).toBe("index")
			})

			it("keeps path-derived controller and action on a wildcard route", () => {
				var wildcardRoute = {pattern = "/[controller]/[action]", action = "index"}
				var pathParams = {controller = "users", action = "show"}
				var params = dispatch.$ensureControllerAndAction(params = pathParams, route = wildcardRoute)

				expect(params.controller).toBeWithCase("Users")
				expect(params.action).toBe("show")
			})

		})

		describe("B2 $cgiScope does not trust rewrite headers unless opted in", () => {

			beforeEach(() => {
				_hadTrust = StructKeyExists(application.wheels, "trustProxyHeaders")
				if (_hadTrust) {
					_priorTrust = application.wheels.trustProxyHeaders
				}
				application.wheels.trustProxyHeaders = false
				cgiScope = {
					request_method = "",
					http_x_requested_with = "",
					http_referer = "",
					server_name = "",
					query_string = "",
					remote_addr = "",
					server_port = "",
					server_port_secure = "",
					server_protocol = "",
					http_host = "",
					http_accept = "",
					content_type = "",
					script_name = "/index.cfm",
					path_info = "",
					http_x_rewrite_url = "/admin/delete/http_x_rewrite_url/index.cfm?controller=admin&action=delete",
					http_x_original_url = "/admin/delete/http_x_original_url/index.cfm?controller=admin&action=delete",
					request_uri = "/users/list/request_uri/index.cfm",
					redirect_url = "/users/list/redirect_url/index.cfm",
					http_x_forwarded_for = "",
					http_x_forwarded_proto = ""
				}
			})

			afterEach(() => {
				if (_hadTrust) {
					application.wheels.trustProxyHeaders = _priorTrust
				} else {
					StructDelete(application.wheels, "trustProxyHeaders")
				}
			})

			it("ignores a client-supplied X-Rewrite-URL when trustProxyHeaders is off", () => {
				var resolved = g.$cgiScope(scope = cgiScope)

				expect(resolved.path_info).notToInclude("http_x_rewrite_url")
				expect(resolved.path_info).toBe("/users/list/request_uri")
			})

			it("ignores a client-supplied X-Original-URL when trustProxyHeaders is off", () => {
				cgiScope.http_x_rewrite_url = ""
				var resolved = g.$cgiScope(scope = cgiScope)

				expect(resolved.path_info).notToInclude("http_x_original_url")
				expect(resolved.path_info).toBe("/users/list/request_uri")
			})

			it("honors X-Rewrite-URL when trustProxyHeaders is on", () => {
				application.wheels.trustProxyHeaders = true
				var resolved = g.$cgiScope(scope = cgiScope)

				expect(resolved.path_info).toBe("/admin/delete/http_x_rewrite_url")
			})

			it("honors X-Original-URL when trustProxyHeaders is on and X-Rewrite-URL is empty", () => {
				application.wheels.trustProxyHeaders = true
				cgiScope.http_x_rewrite_url = ""
				var resolved = g.$cgiScope(scope = cgiScope)

				expect(resolved.path_info).toBe("/admin/delete/http_x_original_url")
			})

		})

		describe("B3 $getRequestMethod does not turn a safe verb into a state-changing one", () => {

			beforeEach(() => {
				_originalForm = Duplicate(form)
				_originalUrl = Duplicate(url)
				_originalCgiMethod = request.cgi.request_method
				StructClear(form)
				StructClear(url)
				dispatch = g.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init")
			})

			afterEach(() => {
				StructClear(form)
				StructClear(url)
				StructAppend(form, _originalForm, false)
				StructAppend(url, _originalUrl, false)
				request.cgi["request_method"] = _originalCgiMethod
			})

			it("does not honor form _method on GET", () => {
				request.cgi["request_method"] = "GET"
				form._method = "delete"
				expect(dispatch.$getRequestMethod()).toBe("GET")
			})

			it("does not honor form _method on HEAD", () => {
				request.cgi["request_method"] = "HEAD"
				form._method = "delete"
				expect(dispatch.$getRequestMethod()).toBe("HEAD")
			})

			it("does not let POST plus _method=GET become a CSRF-safe verb", () => {
				request.cgi["request_method"] = "POST"
				form._method = "GET"
				expect(dispatch.$getRequestMethod()).toBe("POST")
			})

			it("does not let POST plus _method=HEAD become a CSRF-safe verb", () => {
				request.cgi["request_method"] = "POST"
				form._method = "HEAD"
				expect(dispatch.$getRequestMethod()).toBe("POST")
			})

			it("still rewrites POST plus _method=PUT", () => {
				request.cgi["request_method"] = "POST"
				form._method = "PUT"
				expect(dispatch.$getRequestMethod()).toBe("PUT")
			})

			it("still rewrites POST plus _method=PATCH", () => {
				request.cgi["request_method"] = "POST"
				form._method = "PATCH"
				expect(dispatch.$getRequestMethod()).toBe("PATCH")
			})

			it("still rewrites POST plus _method=DELETE", () => {
				request.cgi["request_method"] = "POST"
				form._method = "delete"
				expect(dispatch.$getRequestMethod()).toBe("delete")
			})

			it("ignores an unknown _method value on POST", () => {
				request.cgi["request_method"] = "POST"
				form._method = "TRACE"
				expect(dispatch.$getRequestMethod()).toBe("POST")
			})

		})

	}

}
