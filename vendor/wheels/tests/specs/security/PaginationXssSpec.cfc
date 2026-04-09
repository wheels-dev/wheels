component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("Pagination XSS entity-encoding bypass prevention", () => {

			beforeEach(() => {
				_params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", _params);
				_originalRoutes = Duplicate(application.wheels.routes);
				_originalRewrite = application.wheels.URLRewriting;
				$clearRoutes();
				g.mapper().$match(name = "pagination", pattern = "pag/ina/tion/[special]", to = "pagi##nation").end();
				g.$setNamedRoutePositions();
				application.wheels.URLRewriting = "On";
				g.set(functionName = "linkTo", encode = false);
				g.set(functionName = "paginationLinks", encode = false);
			});

			afterEach(() => {
				application.wheels.routes = _originalRoutes;
				application.wheels.URLRewriting = _originalRewrite;
				g.set(functionName = "linkTo", encode = true);
				g.set(functionName = "paginationLinks", encode = true);
			});

			it("strips decimal entity-encoded onmouseover handler", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName");
				// &#111; = 'o', so this decodes to <li onmouseover="alert(1)">
				var result = _controller.paginationLinks(
					prependToPage = '<li &##111;nmouseover="alert(1)">'
				);
				expect(result).notToInclude("onmouseover");
				expect(result).notToInclude("alert");
			});

			it("strips hex entity-encoded onmouseover handler", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName");
				// &#x6F; = 'o', so this decodes to <li onmouseover="alert(1)">
				var result = _controller.paginationLinks(
					prependToPage = '<li &##x6F;nmouseover="alert(1)">'
				);
				expect(result).notToInclude("onmouseover");
				expect(result).notToInclude("alert");
			});

			it("strips entity-encoded javascript URI", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName");
				// &#106; = 'j', so this decodes to javascript:alert(1)
				var result = _controller.paginationLinks(
					prependToPage = '<li><a href="&##106;avascript:alert(1)">'
				);
				expect(result).notToInclude("javascript");
				expect(result).notToInclude("alert");
			});

			it("preserves normal HTML with class and id attributes", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName");
				var result = _controller.paginationLinks(
					prependToPage = '<li class="page-item" id="nav">'
				);
				expect(result).toInclude('class="page-item"');
				expect(result).toInclude('id="nav"');
			});

			it("still strips plain onmouseover without entity encoding", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName");
				var result = _controller.paginationLinks(
					prependToPage = '<li onmouseover="alert(1)">'
				);
				expect(result).notToInclude("onmouseover");
				expect(result).notToInclude("alert");
			});

			it("decodes mixed decimal and hex entities in $decodeHtmlEntities", () => {
				// &#111; = 'o' (decimal), &#x6E; = 'n' (hex)
				var input = "&##111;&##x6E;mouseover";
				var result = _controller.$decodeHtmlEntities(input);
				expect(result).toBe("onmouseover");
			});

		});

	}

}
