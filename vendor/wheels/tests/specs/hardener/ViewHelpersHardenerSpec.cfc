/**
 * Hardener BLOCKERs B1–B5 (view helpers: form labels, date select encode,
 * linkTo href schemes, paginationLinks anchors, $element assertion).
 *
 * Directory-scoped so `wheels test --core --ci --filter=hardener`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 *
 * encode defaults stay true. B3 default deny of javascript:/data: is
 * ESCALATED — this spec proves an opt-in fail-closed path only.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("CoS lock: encode defaults stay true", () => {

			it("keeps encode=true on textFieldTag, dateSelect, linkTo, and paginationLinks", () => {
				expect(application.wheels.functions.textFieldTag.encode).toBeTrue()
				expect(application.wheels.functions.dateSelect.encode).toBeTrue()
				expect(application.wheels.functions.linkTo.encode).toBeTrue()
				expect(application.wheels.functions.paginationLinks.encode).toBeTrue()
			})

		})

		describe("B1 aroundRight encodes the label under encode=true", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				g.set(functionName = "textFieldTag", encode = true)
			})

			afterEach(() => {
				g.set(functionName = "textFieldTag", encode = true)
			})

			it("does not emit a raw XSS label when labelPlacement is aroundRight", () => {
				result = _controller.textFieldTag(
					name = "username",
					label = "<img src=x onerror=alert(1)>",
					labelPlacement = "aroundRight",
					encode = true
				)

				expect(result).notToInclude("<img")
				expect(result).notToInclude("onerror")
				expect(result).toInclude("&lt;img")
			})

			it("still encodes aroundLeft labels so the placements stay aligned", () => {
				result = _controller.textFieldTag(
					name = "username",
					label = "<img src=x onerror=alert(1)>",
					labelPlacement = "aroundLeft",
					encode = true
				)

				expect(result).notToInclude("<img")
				expect(result).toInclude("&lt;img")
			})

			it("leaves the label raw only when encode is explicitly false", () => {
				result = _controller.textFieldTag(
					name = "username",
					label = "<img src=x onerror=alert(1)>",
					labelPlacement = "aroundRight",
					encode = false
				)

				expect(result).toInclude("<img src=x onerror=alert(1)>")
			})

		})

		describe("B2 date select honors encode=attributes like select()", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("encodes a breaking class on yearSelectTag when encode is attributes", () => {
				result = _controller.yearSelectTag(
					name = "y",
					selected = 2020,
					startYear = 2020,
					endYear = 2020,
					includeBlank = false,
					label = "",
					encode = "attributes",
					class = 'x" onclick="alert(1)'
				)

				expect(result).notToInclude('onclick="alert(1)"')
				expect(result).toInclude("select")
			})

			it("does not coerce encode=attributes to false on the date select helper", () => {
				result = _controller.$yearMonthHourMinuteSecondSelectTag(
					name = "y",
					value = "2020",
					includeBlank = false,
					label = "",
					labelPlacement = "around",
					prepend = "",
					append = "",
					prependToLabel = "",
					appendToLabel = "",
					$type = "year",
					$loopFrom = 2020,
					$loopTo = 2020,
					$id = "y",
					$step = 1,
					encode = "attributes",
					class = 'x" onclick="alert(1)',
					objectName = {},
					property = "y"
				)

				expect(result).notToInclude('onclick="alert(1)"')
			})

		})

		describe("B3 linkTo href javascript:/data: gate is opt-in", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				g.set(functionName = "linkTo", encode = true)
			})

			afterEach(() => {
				g.set(functionName = "linkTo", encode = true)
			})

			it("keeps sanitizeHref false so default public href behavior is unchanged", () => {
				expect(application.wheels.functions.linkTo.sanitizeHref).toBeFalse()
			})

			it("still emits javascript: hrefs under the default sanitizeHref=false", () => {
				result = _controller.linkTo(href = "javascript:alert(1)", text = "x")
				decoded = _controller.$decodeHtmlEntities(result)

				expect(decoded).toInclude("javascript:")
			})

			it("strips javascript: hrefs when sanitizeHref is true", () => {
				result = _controller.linkTo(href = "javascript:alert(1)", text = "x", sanitizeHref = true)
				decoded = _controller.$decodeHtmlEntities(result)

				expect(decoded).notToInclude("javascript:")
				expect(result).notToInclude("sanitizehref")
				expect(result).toInclude("<a")
			})

			it("strips DATA: hrefs when sanitizeHref is true", () => {
				result = _controller.linkTo(
					href = "DATA:text/html,<script>alert(1)</script>",
					text = "x",
					sanitizeHref = true
				)
				decoded = _controller.$decodeHtmlEntities(result)

				expect(decoded).notToInclude("data:")
				expect(result).notToInclude("<script>")
			})

			it("leaves https hrefs intact when sanitizeHref is true", () => {
				result = _controller.linkTo(href = "https://example.com/ok", text = "x", sanitizeHref = true)
				decoded = _controller.$decodeHtmlEntities(result)

				expect(decoded).toInclude("https://example.com/ok")
			})

		})

		describe("B4 paginationLinks sanitizes prependToPage on first/last anchors", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				g.set(functionName = "linkTo", encode = false)
				g.set(functionName = "paginationLinks", encode = "attributes")
			})

			afterEach(() => {
				g.set(functionName = "linkTo", encode = true)
				g.set(functionName = "paginationLinks", encode = true)
			})

			it("does not emit onmouseover from prependToPage on alwaysShowAnchors", () => {
				authors = g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				result = _controller.paginationLinks(
					windowSize = 0,
					alwaysShowAnchors = true,
					prependOnAnchor = true,
					prependToPage = '<li class="page-item" onmouseover="alert(1)">',
					appendToPage = "</li>",
					encode = "attributes"
				)

				expect(result).notToInclude("onmouseover")
				expect(result).notToInclude("alert(1)")
				expect(result).toInclude("page-item")
			})

		})

		describe("B5 $element assertion is not a tautology", () => {

			it("renders a textarea with the supplied attributes and content", () => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.name = "textarea"
				args.attributes = {}
				args.attributes.rows = 10
				args.attributes.cols = 40
				args.attributes.name = "textareatest"
				args.content = "this is a test to see if textarea renders"

				e = _controller.$element(argumentCollection = args)
				r = '<textarea cols="40" name="textareatest" rows="10">this is a test to see if textarea renders</textarea>'

				expect(e).toBe(r)
			})

		})

	}

}
