component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that paginationlinks", () => {

			beforeEach(() => {
				_params = {controller = "dummy", action = "dummy"}
				_controller = g.controller("dummy", _params)
				_originalRoutes = Duplicate(application.wheels.routes)
				_originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? StructCopy(application.wheels.staticRoutes) : {}
				_originalRewrite = application.wheels.URLRewriting
				$clearRoutes()
				g.mapper().$match(name = "pagination", pattern = "pag/ina/tion/[special]", to = "pagi##nation").end()
				g.$setNamedRoutePositions()
				application.wheels.URLRewriting = "On"
				g.set(functionName = "linkTo", encode = false)
				g.set(functionName = "paginationLinks", encode = false)
			})

			afterEach(() => {
				application.wheels.routes = _originalRoutes
				application.wheels.staticRoutes = _originalStaticRoutes
				application.wheels.URLRewriting = _originalRewrite
				g.set(functionName = "linkTo", encode = true)
				g.set(functionName = "paginationLinks", encode = true)
			})

			it("current page works", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				link = _controller.linkTo(text = "2", params = "page=2")
				result = _controller.paginationLinks(linkToCurrentPage = true)

				expect(result).toInclude(link)

				result = _controller.paginationLinks(linkToCurrentPage = false)

				expect(result).notToInclude(link)
				expect(result).toInclude("2")
			})

			it("works with class and classForCurrent", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				defaultLink = _controller.linkTo(text = "1", params = "page=1", class = "default")
				currentLink = _controller.linkTo(text = "2", params = "page=2", class = "current")
				result = _controller.paginationLinks(linkToCurrentPage = true, class = "default", classForCurrent = "current")

				expect(result).toInclude(defaultLink)
				expect(result).toInclude(currentLink)
			})

			it("works with route", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				link = _controller.linkTo(route = "pagination", special = 99, text = "3", params = "page=3")
				result = _controller.paginationLinks(route = "pagination", special = 99)

				expect(result).toInclude(link)
				expect(result).toInclude("?page=")
			})

			it("works with no route", () => {
				$clearRoutes()
				g.mapper()
					.namespace("admin")
					.namespace("v1")
					.get(name = "pagination", controller = "pagination", action = "index")
					.end()
					.end()
					.end()
				g.$setNamedRoutePositions()
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				link = _controller.linkTo(route = "adminV1Pagination", text = "3", params = "page=3")
				result = _controller.paginationLinks(controller = "admin.v1.pagination", action = "index")

				expect(result).toInclude(link)
				expect(result).toInclude("?page=")
			})

			it("works with page as route param with route not containing page parameter in variables", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				result = _controller.paginationLinks(route = "pagination", special = 99)

				expect(result).toInclude("/pag/ina/tion/99?page=")

				result = _controller.paginationLinks(route = "pagination", special = 99, pageNumberAsParam = "false")

				expect(result).notToInclude("/pag/ina/tion/99?page=")
				expect(result).toInclude("/pag/ina/tion/99")
			})

			it("works with page as route param with route containing page parameter in variables", () => {
				$clearRoutes();
				g.mapper().$match(name = "pagination", pattern = "pag/ina/tion/[special]/[page]", to = "pagi##nation").end();
				g.$setNamedRoutePositions();
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName");
				result = _controller.paginationLinks(route = "pagination", special = 99);

				expect(result).toInclude("/pag/ina/tion/99/3")

				result = _controller.paginationLinks(route = "pagination", special = 99, pageNumberAsParam = "false");

				expect(result).toInclude("/pag/ina/tion/99/3")
			})

			it("adds active class to parent element", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				result = _controller.paginationLinks(
					prepend                         = "<ul class='pagination'>",
					append                          = "</ul>",
					prependToPage                   = "<li class='page-item'>",
					appendToPage                    = "</li>",
					addActiveClassToPrependedParent = true,
					linkToCurrentPage               = true,
					encode                          = "attributes",
					class                           = "page-link"
				)

				expect(result).toInclude("<li class='active page-item'>")
			})

			it("strips event handler XSS from prependToPage when adding active class", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				result = _controller.paginationLinks(
					prepend                         = "<ul>",
					append                          = "</ul>",
					prependToPage                   = '<li class="page-item" onmouseover="alert(1)">',
					appendToPage                    = "</li>",
					addActiveClassToPrependedParent = true,
					linkToCurrentPage               = true,
					encode                          = "attributes",
					class                           = "page-link"
				)

				expect(result).notToInclude("onmouseover")
				expect(result).notToInclude("alert(1)")
				expect(result).toInclude('class="active page-item"')
			})

			it("strips javascript URI XSS from prependToPage when adding active class", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				result = _controller.paginationLinks(
					prepend                         = "<ul>",
					append                          = "</ul>",
					prependToPage                   = '<li class="page-item" style="background:url(javascript:alert(1))">',
					appendToPage                    = "</li>",
					addActiveClassToPrependedParent = true,
					linkToCurrentPage               = true,
					encode                          = "attributes",
					class                           = "page-link"
				)

				expect(result).notToInclude("javascript:")
				expect(result).toInclude('class="active page-item"')
			})

			it("strips onclick XSS from prependToPage when adding active class", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				result = _controller.paginationLinks(
					prepend                         = "<ul>",
					append                          = "</ul>",
					prependToPage                   = "<li class='page-item' onclick='alert(document.cookie)'>",
					appendToPage                    = "</li>",
					addActiveClassToPrependedParent = true,
					linkToCurrentPage               = true,
					encode                          = "attributes",
					class                           = "page-link"
				)

				expect(result).notToInclude("onclick")
				expect(result).notToInclude("alert(document.cookie)")
				expect(result).toInclude("class='active page-item'")
			})

			it("encodes anchorDivider to prevent XSS", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				result = _controller.paginationLinks(
					windowSize       = 0,
					alwaysShowAnchors = true,
					anchorDivider    = '<script>alert(1)</script>',
					encode           = true
				)

				expect(result).notToInclude("<script>")
				expect(result).notToInclude("</script>")
				expect(result).notToInclude("alert(1)")
			})

			it("strips event handler XSS from appendToPage", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				result = _controller.paginationLinks(
					prependToPage                   = "<li>",
					appendToPage                    = '<span onmouseover="alert(1)">x</span></li>',
					addActiveClassToPrependedParent = false,
					linkToCurrentPage               = true,
					encode                          = "attributes"
				)

				expect(result).notToInclude("onmouseover")
				expect(result).notToInclude("alert(1)")
				expect(result).toInclude("<span")
			})
		})
	}

	public void function $clearRoutes() {
		application.wheels.routes = []
		application.wheels.staticRoutes = {}
		application.wheels.namedRoutePositions = {}
	}
}
