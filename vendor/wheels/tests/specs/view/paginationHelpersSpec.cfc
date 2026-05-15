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

			/* ── pageNumberLinks viewStyle presets ─────── */

			describe("pageNumberLinks with viewStyle presets", () => {

				it("emits Bootstrap 5 markup with active class on <li> wrapper and <span> for current page", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.pageNumberLinks(viewStyle = "bootstrap5")
					expect(result).toInclude('<li class="page-item active" aria-current="page">')
					expect(result).toInclude('<span class="page-link">2</span>')
					expect(result).toInclude('<li class="page-item">')
					expect(result).toInclude('class="page-link"')
				})

				it("emits Bootstrap 4 markup with active class on <li> wrapper but no aria-current", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.pageNumberLinks(viewStyle = "bootstrap4")
					expect(result).toInclude('<li class="page-item active">')
					expect(result).notToInclude('aria-current')
					expect(result).toInclude('<span class="page-link">2</span>')
				})

				it("emits Tailwind markup with pagination-current/pagination-link wrappers", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.pageNumberLinks(viewStyle = "tailwind")
					expect(result).toInclude('<span class="pagination-current" aria-current="page">')
					expect(result).toInclude('class="pagination-link"')
					expect(result).toInclude("2</span>")
					expect(result).notToInclude('<li class="page-item')
				})

				it("preserves default (plain) behavior when viewStyle is plain", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					resultDefault = _controller.pageNumberLinks()
					resultPlain = _controller.pageNumberLinks(viewStyle = "plain")
					expect(resultPlain).toBe(resultDefault)
				})

				it("preserves default (plain) behavior — active class stays on anchor, not <li>", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.pageNumberLinks(classForCurrent = "active")
					expect(result).notToInclude('<li class="page-item active">')
				})

			})

			/* ── paginationNav viewStyle presets ───────── */

			describe("paginationNav with viewStyle presets", () => {

				it("wraps Bootstrap 5 markup in <ul class='pagination'> inside <nav>", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav(viewStyle = "bootstrap5")
					expect(result).toInclude('<nav')
					expect(result).toInclude('<ul class="pagination">')
					expect(result).toInclude('</ul>')
					expect(result).toInclude('</nav>')
					expect(result).toInclude('<li class="page-item active" aria-current="page">')
					expect(result).toInclude('<span class="page-link">2</span>')
				})

				it("wraps first/previous/next/last in <li class='page-item'> for Bootstrap 5", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav(viewStyle = "bootstrap5")
					expect(result).toInclude('<li class="page-item">')
					expect(result).toInclude('First')
					expect(result).toInclude('Previous')
					expect(result).toInclude('Next')
					expect(result).toInclude('Last')
				})

				it("marks first/previous as disabled <li> when on first page in Bootstrap 5", () => {
					g.model("author").findAll(page = 1, perPage = 3, order = "lastName")
					result = _controller.paginationNav(viewStyle = "bootstrap5")
					expect(result).toInclude('<li class="page-item disabled">')
				})

				it("wraps Bootstrap 4 markup in <ul class='pagination'> without aria-current on current page", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav(viewStyle = "bootstrap4")
					expect(result).toInclude('<nav')
					expect(result).toInclude('<ul class="pagination">')
					expect(result).toInclude('<li class="page-item active">')
					expect(result).toInclude('<span class="page-link">2</span>')
					// BS4 omits aria-current on the active page
					expect(result).notToInclude('aria-current="page"')
				})

				it("marks first/previous as disabled <li> when on first page in Bootstrap 4", () => {
					g.model("author").findAll(page = 1, perPage = 3, order = "lastName")
					result = _controller.paginationNav(viewStyle = "bootstrap4")
					expect(result).toInclude('<li class="page-item disabled">')
				})

				it("wraps Tailwind markup in a flat <nav class='pagination'> with no <ul>", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav(viewStyle = "tailwind")
					expect(result).toInclude('<nav aria-label="Pagination" class="pagination">')
					expect(result).toInclude('<span class="pagination-current" aria-current="page">')
					expect(result).toInclude('class="pagination-link"')
					expect(result).notToInclude('<ul')
					expect(result).notToInclude('<li class="page-item')
				})

				it("emits Tailwind pagination-disabled span for first/previous when on first page", () => {
					g.model("author").findAll(page = 1, perPage = 3, order = "lastName")
					result = _controller.paginationNav(viewStyle = "tailwind")
					expect(result).toInclude('<span class="pagination-disabled">')
					expect(result).toInclude('First')
					expect(result).toInclude('Previous')
				})

				it("places paginationInfo between <nav> and <ul> for Bootstrap 5 with showInfo=true", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					result = _controller.paginationNav(viewStyle = "bootstrap5", showInfo = true)
					expect(result).toInclude('<nav aria-label="Pagination">')
					expect(result).toInclude('Showing')
					expect(result).toInclude('<ul class="pagination">')
					// Info text must appear before the <ul>
					infoPos = FindNoCase("Showing", result)
					ulPos = FindNoCase("<ul", result)
					expect(infoPos).toBeGT(0)
					expect(ulPos).toBeGT(0)
					expect(infoPos).toBeLT(ulPos)
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
