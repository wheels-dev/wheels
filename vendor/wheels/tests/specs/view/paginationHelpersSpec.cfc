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

			})

		})

	}

}
