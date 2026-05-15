component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Pagination Helpers", () => {

			beforeEach(() => {
				_params = {controller = "dummy", action = "dummy"}
				_controller = g.controller("dummy", _params)
				g.set(functionName = "linkTo", encode = false)
				g.set(functionName = "paginationInfo", encode = false)
				g.set(functionName = "previousPageLink", encode = false)
				g.set(functionName = "nextPageLink", encode = false)
				g.set(functionName = "firstPageLink", encode = false)
				g.set(functionName = "lastPageLink", encode = false)
				g.set(functionName = "pageNumberLinks", encode = false)
				g.set(functionName = "paginationNav", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "linkTo", encode = true)
				g.set(functionName = "paginationInfo", encode = true)
				g.set(functionName = "previousPageLink", encode = true)
				g.set(functionName = "nextPageLink", encode = true)
				g.set(functionName = "firstPageLink", encode = true)
				g.set(functionName = "lastPageLink", encode = true)
				g.set(functionName = "pageNumberLinks", encode = true)
				g.set(functionName = "paginationNav", encode = true)
			})

			/* ── paginationInfo ────────────────────────── */

			describe("paginationInfo", () => {

				it("shows default format with record range", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationInfo()
					expect(result).toInclude("Showing")
					expect(result).toInclude("of")
					expect(result).toInclude("records")
				})

				it("shows custom format with tokens", () => {
					g.model("author").findAll(page = 1, perPage = 3, order = "lastName")
					result = _controller.paginationInfo(format = "Page [currentPage] of [totalPages]")
					expect(result).toInclude("Page 1 of")
				})

				it("returns no records message for zero records", () => {
					g.setPagination(totalRecords = 0, currentPage = 1, perPage = 10)
					result = _controller.paginationInfo()
					expect(result).toBe("No records found")
				})

			})

			/* ── previousPageLink ──────────────────────── */

			describe("previousPageLink", () => {

				it("renders disabled span on first page", () => {
					g.model("author").findAll(page = 1, perPage = 3, order = "lastName")
					result = _controller.previousPageLink()
					expect(result).toInclude("<span")
					expect(result).toInclude("disabled")
					expect(result).toInclude("Previous")
					expect(result).notToInclude("<a")
				})

				it("renders link when not on first page", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.previousPageLink()
					expect(result).toInclude("<a")
					expect(result).toInclude("page=1")
					expect(result).toInclude("Previous")
				})

				it("returns empty string when disabled and showDisabled is false", () => {
					g.model("author").findAll(page = 1, perPage = 3, order = "lastName")
					result = _controller.previousPageLink(showDisabled = false)
					expect(result).toBe("")
				})

				it("uses custom text", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.previousPageLink(text = "Back")
					expect(result).toInclude("Back")
				})

			})

			/* ── nextPageLink ──────────────────────────── */

			describe("nextPageLink", () => {

				it("renders disabled span on last page", () => {
					g.model("author").findAll(page = 1, perPage = 100, order = "lastName")
					result = _controller.nextPageLink()
					expect(result).toInclude("<span")
					expect(result).toInclude("disabled")
					expect(result).toInclude("Next")
					expect(result).notToInclude("<a")
				})

				it("renders link when not on last page", () => {
					g.model("author").findAll(page = 1, perPage = 3, order = "lastName")
					result = _controller.nextPageLink()
					expect(result).toInclude("<a")
					expect(result).toInclude("page=2")
					expect(result).toInclude("Next")
				})

				it("returns empty string when disabled and showDisabled is false", () => {
					g.model("author").findAll(page = 1, perPage = 100, order = "lastName")
					result = _controller.nextPageLink(showDisabled = false)
					expect(result).toBe("")
				})

				it("uses custom text", () => {
					g.model("author").findAll(page = 1, perPage = 3, order = "lastName")
					result = _controller.nextPageLink(text = "Forward")
					expect(result).toInclude("Forward")
				})

			})

			/* ── firstPageLink ─────────────────────────── */

			describe("firstPageLink", () => {

				it("renders disabled span on first page", () => {
					g.model("author").findAll(page = 1, perPage = 3, order = "lastName")
					result = _controller.firstPageLink()
					expect(result).toInclude("<span")
					expect(result).toInclude("disabled")
					expect(result).toInclude("First")
				})

				it("renders link when not on first page", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.firstPageLink()
					expect(result).toInclude("<a")
					expect(result).toInclude("page=1")
					expect(result).toInclude("First")
				})

				it("returns empty string when disabled and showDisabled is false", () => {
					g.model("author").findAll(page = 1, perPage = 3, order = "lastName")
					result = _controller.firstPageLink(showDisabled = false)
					expect(result).toBe("")
				})

			})

			/* ── lastPageLink ──────────────────────────── */

			describe("lastPageLink", () => {

				it("renders disabled span on last page", () => {
					g.model("author").findAll(page = 1, perPage = 100, order = "lastName")
					result = _controller.lastPageLink()
					expect(result).toInclude("<span")
					expect(result).toInclude("disabled")
					expect(result).toInclude("Last")
				})

				it("renders link when not on last page", () => {
					g.model("author").findAll(page = 1, perPage = 3, order = "lastName")
					result = _controller.lastPageLink()
					expect(result).toInclude("<a")
					expect(result).toInclude("Last")
				})

				it("returns empty string when disabled and showDisabled is false", () => {
					g.model("author").findAll(page = 1, perPage = 100, order = "lastName")
					result = _controller.lastPageLink(showDisabled = false)
					expect(result).toBe("")
				})

			})

			/* ── pageNumberLinks ───────────────────────── */

			describe("pageNumberLinks", () => {

				it("renders page numbers within window", () => {
					g.model("author").findAll(page = 3, perPage = 1, order = "lastName")
					result = _controller.pageNumberLinks(windowSize = 2)
					expect(result).toInclude("1")
					expect(result).toInclude("2")
					expect(result).toInclude("3")
					expect(result).toInclude("4")
					expect(result).toInclude("5")
				})

				it("renders current page as span with classForCurrent", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.pageNumberLinks(classForCurrent = "active")
					expect(result).toInclude('<span class="active">')
					expect(result).toInclude("2</span>")
				})

				it("links current page when linkToCurrentPage is true", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.pageNumberLinks(linkToCurrentPage = true)
					expect(result).toInclude("page=2")
					expect(result).notToInclude("<span")
				})

				it("supports prependToPage and appendToPage", () => {
					g.model("author").findAll(page = 1, perPage = 3, order = "lastName")
					result = _controller.pageNumberLinks(prependToPage = "<li>", appendToPage = "</li>")
					expect(result).toInclude("<li>")
					expect(result).toInclude("</li>")
				})

				it("applies class to non-current links", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.pageNumberLinks(class = "page-link", classForCurrent = "current")
					expect(result).toInclude('class="page-link"')
					expect(result).toInclude('class="current"')
				})

			})

			/* ── paginationNav ─────────────────────────── */

			describe("paginationNav", () => {

				it("renders complete nav element", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav()
					expect(result).toInclude("<nav")
					expect(result).toInclude("</nav>")
					expect(result).toInclude("pagination")
				})

				it("includes all sections by default", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav()
					expect(result).toInclude("First")
					expect(result).toInclude("Previous")
					expect(result).toInclude("Next")
					expect(result).toInclude("Last")
				})

				it("hides sections when toggled off", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav(showFirst = false, showLast = false)
					expect(result).notToInclude("First")
					expect(result).notToInclude("Last")
					expect(result).toInclude("Previous")
					expect(result).toInclude("Next")
				})

				it("shows info when showInfo is true", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav(showInfo = true)
					expect(result).toInclude("Showing")
					expect(result).toInclude("records")
				})

				it("returns empty string for single page when showSinglePage is false", () => {
					g.model("author").findAll(page = 1, perPage = 100, order = "lastName")
					result = _controller.paginationNav()
					expect(result).toBe("")
				})

				it("renders nav for single page when showSinglePage is true", () => {
					g.model("author").findAll(page = 1, perPage = 100, order = "lastName")
					result = _controller.paginationNav(showSinglePage = true)
					expect(result).toInclude("<nav")
				})

				it("supports custom navClass", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav(navClass = "custom-pagination")
					expect(result).toInclude("custom-pagination")
				})

				it("throws when passed an unknown argument and showErrorInformation is on", () => {
					_origShowErr = application.wheels.showErrorInformation
					application.wheels.showErrorInformation = true
					try {
						g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
						expect(() => _controller.paginationNav(prependToList = "<ul>"))
							.toThrow(type = "Wheels.PaginationNav.InvalidArgument")
					} finally {
						application.wheels.showErrorInformation = _origShowErr
					}
				})

				it("does not throw for documented sub-helper args", () => {
					_origShowErr = application.wheels.showErrorInformation
					application.wheels.showErrorInformation = true
					try {
						g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
						expect(() => _controller.paginationNav(
							windowSize = 3,
							classForCurrent = "active",
							prependToPage = "<li>",
							appendToPage = "</li>",
							class = "page-link"
						)).notToThrow()
					} finally {
						application.wheels.showErrorInformation = _origShowErr
					}
				})

				it("does not throw on unknown arg when showErrorInformation is off", () => {
					_origShowErr = application.wheels.showErrorInformation
					application.wheels.showErrorInformation = false
					try {
						g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
						expect(() => _controller.paginationNav(prependToList = "<ul>"))
							.notToThrow()
					} finally {
						application.wheels.showErrorInformation = _origShowErr
					}
				})

				it("does not throw when passing a named-route segment variable", () => {
					// Regression test for the C1 false positive: paginationNav(route=..., <segmentVar>=...)
					// must not trip InvalidArgument, because $paginationLinkToArgs forwards the route's
					// foundvariables to linkTo() at link-build time.
					_origShowErr = application.wheels.showErrorInformation
					_origRoutes = Duplicate(application.wheels.routes)
					_origStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? StructCopy(application.wheels.staticRoutes) : {}
					_origNamedRoutePositions = StructKeyExists(application.wheels, "namedRoutePositions") ? StructCopy(application.wheels.namedRoutePositions) : {}
					_origRewrite = application.wheels.URLRewriting
					application.wheels.showErrorInformation = true
					try {
						$clearRoutes()
						g.mapper().$match(name = "userTimeline", pattern = "users/[userId]/timeline", to = "users##timeline").end()
						g.$setNamedRoutePositions()
						application.wheels.URLRewriting = "On"
						g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
						expect(() => _controller.paginationNav(route = "userTimeline", userId = 42))
							.notToThrow()
					} finally {
						application.wheels.showErrorInformation = _origShowErr
						application.wheels.routes = _origRoutes
						application.wheels.staticRoutes = _origStaticRoutes
						application.wheels.namedRoutePositions = _origNamedRoutePositions
						application.wheels.URLRewriting = _origRewrite
					}
				})

				// ── Bootstrap-style markup parity with legacy paginationLinks() (issue #2715) ──

				it("emits prepend HTML immediately inside the nav element", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav(prepend = '<ul class="pagination">', append = "</ul>")
					expect(result).toInclude('<ul class="pagination">')
					expect(result).toInclude("</ul>")
					// prepend must appear before the first anchor, append after the last
					expect(result).toMatch('<nav[^>]*><ul class="pagination">')
					expect(result).toMatch('</ul></nav>')
				})

				it("wraps every anchor (first/prev/page/next/last) with prependToPage and appendToPage", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav(
						prependToPage = '<li class="page-item">',
						appendToPage = '</li>',
						class = "page-link"
					)
					// One <li> for first, prev, each numbered page, next, last
					expect(ListLen(result, "<")).toBeGT(5)
					// All five navigation anchors must be wrapped, not just the numbered links
					expect(result).toMatch('<li class="page-item">[^<]*<[^>]*>First')
					expect(result).toMatch('<li class="page-item">[^<]*<[^>]*>Previous')
					expect(result).toMatch('<li class="page-item">[^<]*<[^>]*>Next')
					expect(result).toMatch('<li class="page-item">[^<]*<[^>]*>Last')
				})

				it("injects active into prependToPage class attribute on current page when addActiveClassToPrependedParent is true", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav(
						prependToPage = '<li class="page-item">',
						appendToPage = '</li>',
						classForCurrent = "active",
						addActiveClassToPrependedParent = true
					)
					expect(result).toInclude('<li class="active page-item">')
				})

				it("applies class to page-number anchors via the explicit class arg", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav(class = "page-link")
					expect(result).toInclude('class="page-link"')
				})

				it("uses anchorDivider between adjacent sub-helper output sections", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					// Use a sentinel that cannot incidentally appear inside a URL, page-number
					// text, attribute value, or tag name — otherwise the assertion can pass
					// even when anchorDivider is ignored.
					result = _controller.paginationNav(
						anchorDivider = "XDIVX",
						showFirst = true,
						showLast = true,
						showPrevious = true,
						showNext = true
					)
					expect(result).toInclude("XDIVX")
					// And it must sit *between* sections — never inside a tag, never inside
					// rendered text — i.e. between a closing tag and the next opening tag.
					expect(result).toMatch("</[^>]+>XDIVX<")
				})

			})

		})

	}

	public void function $clearRoutes() {
		application.wheels.routes = []
		application.wheels.staticRoutes = {}
		application.wheels.namedRoutePositions = {}
	}

}
