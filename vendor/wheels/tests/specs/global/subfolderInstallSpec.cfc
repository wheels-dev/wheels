/**
 * Subfolder installs (#3948): the app runs under /app1 (an IIS virtual directory
 * or Tomcat context pointing at public/), so cgi.script_name is
 * /app1/index.cfm. Each block pins one place the subfolder used to be lost.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Subfolder installs (##3948)", () => {

			describe("$cgiScope path_info fallback", () => {

				it("routes /app1/index.cfm with an empty PATH_INFO to the root", () => {
					var rv = g.$cgiScope(scope = fakeCgi(scriptName = "/app1/index.cfm", requestUri = "/app1/index.cfm"))
					expect(rv.path_info).toBe("/")
				})

				it("drops the subfolder and front controller from a request_uri path", () => {
					var rv = g.$cgiScope(scope = fakeCgi(scriptName = "/app1/index.cfm", requestUri = "/app1/index.cfm/widgets?page=2"))
					expect(rv.path_info).toBe("/widgets")
				})

				it("drops the subfolder from a rewritten request_uri path", () => {
					var rv = g.$cgiScope(scope = fakeCgi(scriptName = "/app1/index.cfm", requestUri = "/app1/widgets/3"))
					expect(rv.path_info).toBe("/widgets/3")
				})

				it("leaves a root install unchanged", () => {
					expect(g.$cgiScope(scope = fakeCgi(scriptName = "/index.cfm", requestUri = "/index.cfm")).path_info).toBe("/")
					expect(g.$cgiScope(scope = fakeCgi(scriptName = "/index.cfm", requestUri = "/widgets")).path_info).toBe("/widgets")
				})

				it("only strips a whole leading segment", () => {
					expect(g.$stripScriptDirectory(pathInfo = "/app10/widgets", scriptName = "/app1/index.cfm")).toBe("/app10/widgets")
					expect(g.$stripScriptDirectory(pathInfo = "/app1", scriptName = "/app1/index.cfm")).toBe("/")
					expect(g.$stripScriptDirectory(pathInfo = "/app1/", scriptName = "/app1/index.cfm")).toBe("/")
				})

			})

			describe("$prefixWebPath (redirect after reload)", () => {

				it("puts the subfolder back on an app-relative path", () => {
					expect(g.$prefixWebPath(path = "/widgets", webPath = "/app1/")).toBe("/app1/widgets")
					expect(g.$prefixWebPath(path = "/", webPath = "/app1/")).toBe("/app1/")
					expect(g.$prefixWebPath(path = "/widgets?page=2", webPath = "/app1/")).toBe("/app1/widgets?page=2")
				})

				it("leaves paths already under the subfolder, root installs and absolute URLs alone", () => {
					expect(g.$prefixWebPath(path = "/app1/index.cfm", webPath = "/app1/")).toBe("/app1/index.cfm")
					expect(g.$prefixWebPath(path = "/app1", webPath = "/app1/")).toBe("/app1")
					expect(g.$prefixWebPath(path = "/widgets", webPath = "/")).toBe("/widgets")
					expect(g.$prefixWebPath(path = "//cdn.example.com/x", webPath = "/app1/")).toBe("//cdn.example.com/x")
				})

			})

			describe("$resolveSubpathInclude when the subfolder maps to public/", () => {

				it("keeps the /wheels mapping path when the prefixed path does not exist", () => {
					var state = {original = application.wheels.webPath, rv = ""}
					application.wheels.webPath = "/app1nonexistent/"
					try {
						state.rv = g.$resolveSubpathInclude(template = "/wheels/tests/app-runner.cfm")
					} finally {
						application.wheels.webPath = state.original
					}
					expect(state.rv).toBe("/wheels/tests/app-runner.cfm")
				})

			})

			describe("$buildDebugReloadUrl in Partial URL rewriting", () => {

				it("keeps index.cfm so the environment-switch links route", () => {
					var rv = g.$buildDebugReloadUrl(
						scriptName = "/app1/index.cfm",
						pathInfo = "/widgets",
						queryString = "",
						webPath = "/app1/",
						rewriteFile = "index.cfm",
						urlRewriting = "Partial"
					)
					expect(rv).toBe("/app1/index.cfm/widgets?reload=")
				})

				it("still drops index.cfm when rewriting is on", () => {
					var rv = g.$buildDebugReloadUrl(
						scriptName = "/app1/index.cfm",
						pathInfo = "/widgets",
						queryString = "",
						webPath = "/app1/",
						rewriteFile = "index.cfm",
						urlRewriting = "On"
					)
					expect(rv).toBe("/app1/widgets?reload=")
				})

			})

			describe("$debugDocsUrl", () => {

				it("puts the docs bundle under the subfolder", () => {
					expect(g.$debugDocsUrl(path = "guides/", webPath = "/app1/", rewriteFile = "index.cfm", urlRewriting = "On")).toBe("/app1/wheels-docs/guides/")
				})

				it("goes through the front controller without full rewriting", () => {
					expect(g.$debugDocsUrl(path = "api/", webPath = "/app1/", rewriteFile = "index.cfm", urlRewriting = "Partial")).toBe("/app1/index.cfm/wheels-docs/api/")
				})

				it("is unchanged for a root install with rewriting on", () => {
					expect(g.$debugDocsUrl(path = "guides/", webPath = "/", rewriteFile = "index.cfm", urlRewriting = "On")).toBe("/wheels-docs/guides/")
				})

			})

		})

	}

	// A CGI-shaped struct carrying every key $cgiScope() copies, with an empty
	// PATH_INFO (the IIS / Tomcat shape that triggers the fallbacks).
	private struct function fakeCgi(required string scriptName, required string requestUri) {
		var keys = "request_method,http_x_requested_with,http_referer,server_name,path_info,script_name,query_string,remote_addr,server_port,server_port_secure,server_protocol,http_host,http_accept,content_type,http_x_rewrite_url,http_x_original_url,request_uri,redirect_url,http_x_forwarded_for,http_x_forwarded_proto"
		var rv = {}
		for (var key in ListToArray(keys)) {
			rv[key] = ""
		}
		rv.request_method = "GET"
		rv.script_name = arguments.scriptName
		rv.request_uri = arguments.requestUri
		return rv
	}

}
