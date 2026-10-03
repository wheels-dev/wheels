/**
 * The redirect after a reload goes back to the request's app-relative path. A
 * leading run of slashes or backslashes in that path is collapsed to a single "/",
 * so the redirect always stays on this site's own paths; the subfolder prefix
 * (#3948) is applied after that.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("$reloadRedirectPath", () => {

			it("leaves an ordinary app path and its query string unchanged", () => {
				expect(g.$reloadRedirectPath(path = "/widgets", webPath = "/")).toBe("/widgets")
				expect(g.$reloadRedirectPath(path = "/widgets?page=2", webPath = "/")).toBe("/widgets?page=2")
				expect(g.$reloadRedirectPath(path = "/", webPath = "/")).toBe("/")
			})

			it("collapses a leading run of slashes to one", () => {
				expect(g.$reloadRedirectPath(path = "//example.com/x", webPath = "/")).toBe("/example.com/x")
				expect(g.$reloadRedirectPath(path = "///example.com/x?page=2", webPath = "/")).toBe("/example.com/x?page=2")
			})

			it("treats a backslash in the leading run like a slash", () => {
				expect(g.$reloadRedirectPath(path = "/\example.com/x", webPath = "/")).toBe("/example.com/x")
				expect(g.$reloadRedirectPath(path = "\\example.com/x", webPath = "/")).toBe("/example.com/x")
				expect(g.$reloadRedirectPath(path = "/\/example.com/x", webPath = "/")).toBe("/example.com/x")
			})

			it("also ignores spaces and control characters in the leading run", () => {
				var tab = Chr(9)
				var lf = Chr(10)
				var cr = Chr(13)
				expect(g.$reloadRedirectPath(path = "/" & tab & "/example.com", webPath = "/")).toBe("/example.com")
				expect(g.$reloadRedirectPath(path = "/" & lf & "//example.com", webPath = "/")).toBe("/example.com")
				expect(g.$reloadRedirectPath(path = "/" & cr & "/x", webPath = "/")).toBe("/x")
				expect(g.$reloadRedirectPath(path = "/ /example.com", webPath = "/")).toBe("/example.com")
				expect(g.$reloadRedirectPath(path = "/\" & tab & "/x", webPath = "/")).toBe("/x")
				expect(g.$reloadRedirectPath(path = "/" & Chr(127) & "/x", webPath = "/")).toBe("/x")
				expect(g.$reloadRedirectPath(path = "/" & tab & cr & lf & " ", webPath = "/")).toBe("/")
			})

			it("keeps spaces and control characters that come after the leading run", () => {
				expect(g.$reloadRedirectPath(path = "/a" & Chr(9) & "b", webPath = "/")).toBe("/a" & Chr(9) & "b")
			})

			it("only touches the leading run, not slashes later in the path", () => {
				expect(g.$reloadRedirectPath(path = "/a//b", webPath = "/")).toBe("/a//b")
			})

			it("puts the subfolder back after collapsing", () => {
				expect(g.$reloadRedirectPath(path = "/widgets", webPath = "/app1/")).toBe("/app1/widgets")
				expect(g.$reloadRedirectPath(path = "//example.com/x", webPath = "/app1/")).toBe("/app1/example.com/x")
				expect(g.$reloadRedirectPath(path = "/app1/widgets", webPath = "/app1/")).toBe("/app1/widgets")
			})

			it("differs from the plain subfolder prefix, which leaves a '//'-leading path as it is", () => {
				// Before this helper, the redirect target was $prefixWebPath(path) alone.
				expect(g.$prefixWebPath(path = "//example.com/x", webPath = "/")).toBe("//example.com/x")
				expect(g.$reloadRedirectPath(path = "//example.com/x", webPath = "/")).toBe("/example.com/x")
			})

			it("is what the reload redirect in onRequestStart uses", () => {
				var src = FileRead(ExpandPath("/wheels/events/EventMethods.cfc"))
				expect(src).toInclude("$reloadRedirectPath(path = request.wheels.redirectAfterReloadUrl)")
			})

		})
	}

}
