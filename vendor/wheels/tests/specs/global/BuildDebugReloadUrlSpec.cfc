component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that $buildDebugReloadUrl", () => {

			// ---------------------------------------------------------------
			// Root installs (webPath = "/") — these expectations are pinned
			// byte-for-byte to the output of the previous inline composition in
			// vendor/wheels/events/onrequestend/debug.cfm (raw cgi.script_name
			// + path_info + query string, then the rewriteFile strip and the
			// reload-param scrub). They must never change.
			// ---------------------------------------------------------------

			it("builds the reload URL for a root install with URL rewriting on", () => {
				rv = g.$buildDebugReloadUrl(
					scriptName = "/index.cfm",
					pathInfo = "/posts",
					queryString = "",
					webPath = "/",
					rewriteFile = "index.cfm"
				)

				expect(rv).toBe("/posts?reload=")
			})

			it("preserves the query string on a root install", () => {
				rv = g.$buildDebugReloadUrl(
					scriptName = "/index.cfm",
					pathInfo = "/posts",
					queryString = "page=2&sort=title",
					webPath = "/",
					rewriteFile = "index.cfm"
				)

				expect(rv).toBe("/posts?page=2&sort=title&reload=")
			})

			it("scrubs a leading ?reload= parameter from the query string", () => {
				rv = g.$buildDebugReloadUrl(
					scriptName = "/index.cfm",
					pathInfo = "/posts",
					queryString = "reload=true",
					webPath = "/",
					rewriteFile = "index.cfm"
				)

				expect(rv).toBe("/posts?reload=")
			})

			it("scrubs an &reload=<environment> parameter while keeping the rest of the query string", () => {
				rv = g.$buildDebugReloadUrl(
					scriptName = "/index.cfm",
					pathInfo = "/posts",
					queryString = "page=2&reload=development",
					webPath = "/",
					rewriteFile = "index.cfm"
				)

				expect(rv).toBe("/posts?page=2&reload=")
			})

			it("keeps rewriting-off root installs byte-identical to the previous inline composition", () => {
				// With URL rewriting off, path_info equals script_name (Lucee) so
				// nothing is appended; the rewriteFile strip leaves the bare query.
				rv = g.$buildDebugReloadUrl(
					scriptName = "/index.cfm",
					pathInfo = "/index.cfm",
					queryString = "controller=posts&action=index",
					webPath = "/",
					rewriteFile = "index.cfm"
				)

				expect(rv).toBe("?controller=posts&action=index&reload=")
			})

			it("handles an empty path_info (Adobe engines with rewriting off)", () => {
				rv = g.$buildDebugReloadUrl(
					scriptName = "/index.cfm",
					pathInfo = "",
					queryString = "controller=posts&action=index",
					webPath = "/",
					rewriteFile = "index.cfm"
				)

				expect(rv).toBe("?controller=posts&action=index&reload=")
			})

			// ---------------------------------------------------------------
			// Subfolder (subpath) installs — issue #3344. The base must come
			// from webPath, not raw cgi.script_name, so the emitted link never
			// contains the on-disk /public/ segment or the front controller.
			// ---------------------------------------------------------------

			it("honors webPath on a subfolder install (no /public/, no index.cfm)", () => {
				rv = g.$buildDebugReloadUrl(
					scriptName = "/wheelsproject1/public/index.cfm",
					pathInfo = "/posts",
					queryString = "",
					webPath = "/wheelsproject1/",
					rewriteFile = "index.cfm"
				)

				expect(rv).toBe("/wheelsproject1/posts?reload=")
				expect(rv).notToInclude("/public/")
				expect(rv).notToInclude("index.cfm")
			})

			it("honors a nested subpath webPath", () => {
				rv = g.$buildDebugReloadUrl(
					scriptName = "/team/site/public/index.cfm",
					pathInfo = "/posts/1",
					queryString = "page=2",
					webPath = "/team/site/",
					rewriteFile = "index.cfm"
				)

				expect(rv).toBe("/team/site/posts/1?page=2&reload=")
			})

			it("scrubs reload params on a subfolder install", () => {
				rv = g.$buildDebugReloadUrl(
					scriptName = "/wheelsproject1/public/index.cfm",
					pathInfo = "/posts",
					queryString = "reload=true",
					webPath = "/wheelsproject1/",
					rewriteFile = "index.cfm"
				)

				expect(rv).toBe("/wheelsproject1/posts?reload=")
			})

			// ---------------------------------------------------------------
			// Defensive fallbacks (early boot / error paths).
			// ---------------------------------------------------------------

			it("falls back to the raw script name when webPath is empty", () => {
				rv = g.$buildDebugReloadUrl(
					scriptName = "/wheelsproject1/public/index.cfm",
					pathInfo = "/posts",
					queryString = "",
					webPath = "",
					rewriteFile = "index.cfm"
				)

				// Exactly what the previous inline composition produced.
				expect(rv).toBe("/wheelsproject1/public/posts?reload=")
			})

			it("skips the rewriteFile strip when rewriteFile is empty", () => {
				rv = g.$buildDebugReloadUrl(
					scriptName = "/index.cfm",
					pathInfo = "/posts",
					queryString = "",
					webPath = "/",
					rewriteFile = ""
				)

				expect(rv).toBe("/index.cfm/posts?reload=")
			})

			it("defaults webPath and rewriteFile from application scope when omitted", () => {
				// The running test app is a root install: webPath "/" and
				// rewriteFile "index.cfm", so this must match the explicit
				// root-install case above.
				rv = g.$buildDebugReloadUrl(
					scriptName = "/index.cfm",
					pathInfo = "/posts",
					queryString = ""
				)

				expect(rv).toBe("/posts?reload=")
			})

		})
	}
}
