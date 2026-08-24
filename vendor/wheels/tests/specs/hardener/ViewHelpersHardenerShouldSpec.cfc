/**
 * Hardener SHOULDs S1–S20 (view helpers).
 *
 * Directory-scoped so `wheels test --core --ci --filter=hardener`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 *
 * encode defaults stay true. Escalations (no silent public default/API flips):
 *   S14 linkTo / URLFor stay fail-open for external hrefs (B3 sanitizeHref
 *       remains opt-in; redirectTo already gates open redirects).
 *   S20 formHelperDataAutoId stays true (do not flip the default).
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("CoS lock: encode defaults stay true", () => {

			it("keeps encode=true on the helpers these SHOULDs touch", () => {
				expect(application.wheels.functions.monthSelectTag.encode).toBeTrue()
				expect(application.wheels.functions.startFormTag.encode).toBeTrue()
				expect(application.wheels.functions.errorMessageOn.encode).toBeTrue()
				expect(application.wheels.functions.paginationNav.encode).toBeTrue()
				expect(application.wheels.functions.csrfMetaTags.encode).toBeTrue()
				expect(application.wheels.functions.stripTags.encode).toBeTrue()
				expect(application.wheels.functions.imageTag.encode).toBeTrue()
				expect(application.wheels.functions.linkTo.encode).toBeTrue()
			})

		})

		describe("S1 date option bodies honor encode", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("encodes a hostile month name when encode is true", () => {
				result = _controller.monthSelectTag(
					name = "m",
					selected = 2,
					monthDisplay = "names",
					monthNames = "January,<img src=x onerror=alert(1)>,March,April,May,June,July,August,September,October,November,December",
					includeBlank = false,
					label = "",
					encode = true
				)

				expect(result).notToInclude("<img")
				expect(result).toInclude("&lt;img")
			})

			it("still emits the raw month name when encode is explicitly false", () => {
				result = _controller.monthSelectTag(
					name = "m",
					selected = 2,
					monthDisplay = "names",
					monthNames = "January,<img src=x onerror=alert(1)>,March,April,May,June,July,August,September,October,November,December",
					includeBlank = false,
					label = "",
					encode = false
				)

				expect(result).toInclude("<img src=x onerror=alert(1)>")
			})

		})

		describe("S2 $tag drops attribute names that are not HTML names", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("does not emit a breakout attribute name", () => {
				var attrs = {}
				attrs.name = "n"
				attrs['"><img src=x onerror=alert(1)'] = "1"
				result = _controller.$tag(name = "input", attributes = attrs, encode = true)

				expect(result).notToInclude("<img")
				expect(result).notToInclude("onerror")
				expect(result).toInclude("<input")
			})

			it("still emits a normal class attribute", () => {
				result = _controller.$tag(
					name = "input",
					attributes = {name = "n", class = "ok"},
					encode = true
				)

				expect(result).toInclude('class="ok"')
			})

		})

		describe("S3 encode=attributes is coerced the same way on buttonTo as on select", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("encodes a breaking class on buttonTo when encode is attributes", () => {
				result = _controller.buttonTo(
					text = "go",
					controller = "dummy",
					action = "index",
					class = 'x" onclick="alert(1)',
					encode = "attributes"
				)

				expect(result).notToInclude('onclick="alert(1)"')
				expect(result).toInclude("<form")
			})

			it("leaves the class raw on buttonTo only when encode is false", () => {
				result = _controller.buttonTo(
					text = "go",
					controller = "dummy",
					action = "index",
					class = 'x" onclick="alert(1)',
					encode = false
				)

				expect(result).toInclude('onclick="alert(1)"')
			})

		})

		describe("S4 startFormTag does not leak CSRF to an external https action", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				_priorCsrf = StructKeyExists(request, "$wheelsProtectedFromForgery")
					? request.$wheelsProtectedFromForgery
					: false
				request.$wheelsProtectedFromForgery = true
			})

			afterEach(() => {
				request.$wheelsProtectedFromForgery = _priorCsrf
			})

			it("omits authenticityToken when action is an absolute external https URL", () => {
				result = _controller.startFormTag(action = "https://evil.example/steal", method = "post")

				expect(result).toInclude("evil.example")
				expect(result).notToInclude("authenticityToken")
			})

			it("still emits authenticityToken for a same-app post form", () => {
				result = _controller.startFormTag(controller = "dummy", action = "index", method = "post")

				expect(result).toInclude("authenticityToken")
			})

		})

		describe("S5 errorElement is restricted to a safe tag name", () => {

			it("falls back to span when errorElement is a breakout tag name", () => {
				_controller = g.controller(name = "ControllerWithModelErrors")
				result = _controller.textField(
					objectName = "user",
					property = "firstname",
					label = false,
					errorElement = 'img src=x onerror=alert(1)',
					encode = true
				)

				expect(result).notToInclude("<img")
				expect(result).notToInclude("onerror")
				expect(result).toInclude("<span")
				expect(result).toInclude("</span>")
			})

		})

		describe("S6 aroundRight / date / html5 stay encoded under encode=true", () => {

			it("encodes aroundRight on emailFieldTag", () => {
				_controller = g.controller(name = "dummy")
				result = _controller.emailFieldTag(
					name = "userEmail",
					label = "<img src=x onerror=alert(1)>",
					labelPlacement = "aroundRight",
					encode = true
				)

				expect(result).notToInclude("<img")
				expect(result).toInclude("&lt;img")
			})

			it("encodes aroundRight on yearSelectTag", () => {
				_controller = g.controller(name = "dummy")
				result = _controller.yearSelectTag(
					name = "y",
					selected = 2020,
					startYear = 2020,
					endYear = 2020,
					includeBlank = false,
					label = "<img src=x onerror=alert(1)>",
					labelPlacement = "aroundRight",
					encode = true
				)

				expect(result).notToInclude("<img")
				expect(result).toInclude("&lt;img")
			})

			it("encodes aroundRight on emailField bound to a model", () => {
				_controller = g.controller(name = "ControllerWithModel")
				result = _controller.emailField(
					objectName = "user",
					property = "firstname",
					label = "<img src=x onerror=alert(1)>",
					labelPlacement = "aroundRight",
					encode = true
				)

				expect(result).notToInclude("<img")
				expect(result).toInclude("&lt;img")
			})

		})

		describe("S7 hasManyRadioButton passes extra attributes through", () => {

			it("emits class on the generated radio input", () => {
				_controller = g.controller(name = "ControllerWithModel")
				result = _controller.hasManyRadioButton(
					objectName = "user",
					association = "galleries",
					property = "title",
					keys = "1",
					tagValue = "shown",
					label = false,
					class = "gallery-radio"
				)

				expect(result).toInclude('class="gallery-radio"')
			})

		})

		describe("S8 $paginationLinkToArgs does not double-encode params", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				g.set(functionName = "linkTo", encode = true)
				g.set(functionName = "pageNumberLinks", encode = true)
			})

			afterEach(() => {
				g.set(functionName = "linkTo", encode = true)
				g.set(functionName = "pageNumberLinks", encode = true)
			})

			it("does not percent-encode struct params before URLFor sees them", () => {
				qs = _controller.$paramsToQueryString({q = "hello world"}, false)
				expect(qs).toInclude("hello world")
				expect(qs).notToInclude("%20")
				expect(qs).notToInclude("%2520")

				linkArgs = _controller.$paginationLinkToArgs(
					page = 2,
					text = "2",
					name = "page",
					pageNumberAsParam = true,
					encode = true,
					args = {params = {q = "hello world"}}
				)
				expect(linkArgs.params).toInclude("hello world")
				expect(linkArgs.params).notToInclude("%20")
			})

		})

		describe("S9 paginationNav encodes the outer nav attributes", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("encodes a breaking navClass when encode is true", () => {
				g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				result = _controller.paginationNav(
					navClass = 'x" onmouseover="alert(1)',
					encode = true
				)

				expect(result).notToInclude('onmouseover="')
				expect(result).toInclude("<nav")
				expect(result).toInclude("class=")
			})

		})

		describe("S10 includeContent encode is opt-in under the existing default", () => {

			beforeEach(() => {
				_params = {controller = "dummy", action = "dummy"}
				_controller = g.controller("dummy", _params)
				_controller.contentFor(sidebar = "<script>alert(1)</script>")
			})

			it("still returns stored HTML when encode is omitted", () => {
				expect(_controller.includeContent("sidebar")).toInclude("<script>alert(1)</script>")
			})

			it("encodes stored HTML when encode is true", () => {
				result = _controller.includeContent(name = "sidebar", encode = true)

				expect(result).notToInclude("<script>")
				expect(result).toInclude("&lt;script")
			})

		})

		describe("S11 $paginationSanitizeWrapper strips style expression and data URIs", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("strips a style expression after entity decode", () => {
				result = _controller.$paginationSanitizeWrapper('<li style="expression(alert(1))">')

				expect(result).notToInclude("expression")
				expect(result).notToInclude("alert(1)")
			})

			it("strips a data URI href", () => {
				result = _controller.$paginationSanitizeWrapper('<a href="data:text/html,<script>alert(1)</script>">x</a>')

				expect(result).notToInclude("data:")
				expect(result).notToInclude("<script>")
			})

		})

		describe("S12 Vite interpolations are HTML-attribute encoded", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				_origDevMode = application.wheels.viteDevMode
				_origDevUrl = application.wheels.viteDevServerUrl
				_origStrict = application.wheels.viteStrictManifest
			})

			afterEach(() => {
				application.wheels.viteDevMode = _origDevMode
				application.wheels.viteDevServerUrl = _origDevUrl
				application.wheels.viteStrictManifest = _origStrict
				var appKey = application.wo.$appKey()
				StructDelete(application[appKey], "viteManifestCache")
			})

			it("encodes a hostile entrypoint in the dev script src", () => {
				application.wheels.viteDevMode = true
				application.wheels.viteDevServerUrl = "http://localhost:5173"
				result = _controller.viteScriptTag('foo"><script>alert(1)</script>')

				expect(result).notToInclude("<script>alert(1)</script>")
				expect(result).toInclude("script")
			})

			it("encodes a hostile manifest file name in production", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: 'assets/x"><script>alert(1)</script>',
						src: "src/main.js",
						isEntry: true
					}
				}
				result = _controller.viteScriptTag("src/main.js")

				expect(result).notToInclude("<script>alert(1)</script>")
				expect(result).toInclude("assets")
			})

		})

		describe("S13 imageTag does not expandPath a /wheels traversal", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("does not keep .. segments in a /wheels source", () => {
				result = _controller.imageTag(
					source = "/wheels/../../../etc/passwd",
					required = false,
					encode = true
				)

				expect(result).notToInclude("..")
				expect(result).toInclude("<img")
			})

		})

		describe("S14 ESCALATED: linkTo/URLFor stay fail-open vs redirectTo", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("keeps sanitizeHref false so javascript hrefs still emit by default", () => {
				expect(application.wheels.functions.linkTo.sanitizeHref).toBeFalse()
				result = _controller.linkTo(href = "javascript:alert(1)", text = "x")
				decoded = _controller.$decodeHtmlEntities(result)

				expect(decoded).toInclude("javascript:")
			})

			it("still emits an external https href from linkTo", () => {
				result = _controller.linkTo(href = "https://evil.example/phish", text = "x")

				expect(result).toInclude("evil.example")
				expect(_controller.$decodeHtmlEntities(result)).toInclude("https://evil.example/phish")
			})

			it("still lets URLFor build an absolute URL for another host", () => {
				result = g.uRLFor(
					controller = "dummy",
					action = "index",
					onlyPath = false,
					host = "evil.example",
					protocol = "https"
				)

				expect(result).toInclude("evil.example")
			})

			it("still rejects redirectTo url= to an external host", () => {
				expect(() => {
					_controller.redirectTo(url = "https://evil.example/phish")
				}).toThrow("Wheels.UnsafeRedirect")
			})

		})

		describe("S15 asset URLs drop .. and leave protocol-relative CDN hrefs", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("does not emit .. from a local stylesheet source", () => {
				result = _controller.styleSheetLinkTag(source = "../../secret", encode = true)

				expect(result).notToInclude("..")
				expect(result).toInclude("<link")
			})

			it("still accepts a protocol-relative CDN href", () => {
				result = _controller.styleSheetLinkTag(source = "//cdn.example.com/app.css")

				expect(_controller.$decodeHtmlEntities(result)).toInclude("//cdn.example.com/app.css")
			})

		})

		describe("S16 csrfMetaTags honors encode", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("passes encode through to $tag so encode=false is not a no-op", () => {
				var src = FileRead(ExpandPath("/wheels/view/csrf.cfc"))
				var start = FindNoCase("function csrfMetaTags", src)
				expect(start).toBeGT(0)
				var body = Mid(src, start, 800)

				expect(FindNoCase("encode", body) > 0).toBeTrue(
					"csrfMetaTags must pass encode into $tag; the argument is no longer ignored"
				)
			})

			it("still emits both meta tags under the encode=true default", () => {
				result = _controller.csrfMetaTags()

				expect(result).toInclude('name="csrf-param"')
				expect(result).toInclude('name="csrf-token"')
			})

		})

		describe("S17 stripTags removes comments and newline tags when encode is false", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("strips an HTML comment that the old letter-only regex left behind", () => {
				result = _controller.stripTags(
					html = "x<!-- <script>alert(1)</script> -->y",
					encode = false
				)

				expect(result).notToInclude("<!--")
				expect(result).notToInclude("<script>")
				expect(result).toInclude("xy")
			})

			it("strips a tag split across a newline when encode is false", () => {
				result = _controller.stripTags(
					html = "a<" & Chr(10) & "script>alert(1)</script>b",
					encode = false
				)

				expect(result).notToInclude("script")
				expect(result).toInclude("a")
				expect(result).toInclude("b")
			})

		})

		describe("S18 errorMessageOn prepend/append are encoded once", () => {

			it("does not turn a prepend less-than into &amp;lt;", () => {
				_controller = g.controller(name = "ControllerWithModelErrors")
				result = _controller.errorMessageOn(
					objectName = "user",
					property = "firstname",
					prependText = "<b>",
					appendText = "</b>",
					encode = true
				)

				expect(result).toInclude("&lt;b&gt;")
				expect(result).notToInclude("&amp;lt;")
			})

		})

		describe("S19 h() and hAttr() canonicalize before encode", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("matches EncodeForHTML of the canonicalized value", () => {
				var raw = "%3Cscript%3E"
				expect(_controller.h(raw)).toBe(EncodeForHTML(_controller.$canonicalize(raw)))
			})

			it("matches EncodeForHTMLAttribute of the canonicalized value", () => {
				var raw = "%3Cscript%3E"
				expect(_controller.hAttr(raw)).toBe(EncodeForHTMLAttribute(_controller.$canonicalize(raw)))
			})

		})

		describe("S20 ESCALATED: formHelperDataAutoId default stays true", () => {

			it("keeps the public default true", () => {
				expect(application.wheels.formHelperDataAutoId).toBeTrue()
			})

			it("still emits data-auto-id on a bound textField", () => {
				_controller = g.controller(name = "ControllerWithModel")
				result = _controller.textField(objectName = "user", property = "firstname", label = false)

				expect(result).toInclude('data-auto-id="user_firstname"')
			})

		})

	}

}
