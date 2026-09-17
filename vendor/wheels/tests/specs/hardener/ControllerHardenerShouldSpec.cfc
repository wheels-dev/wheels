/**
 * Hardener BLOCKERs B5–B6 and controller-lifecycle SHOULDs.
 *
 * Directory-scoped so `wheels test --core --ci --filter=hardener`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("B5 $callAction does not remap real render errors to ViewNotFound", () => {

			beforeEach(() => {
				// Full-suite leftover request.cgi.http_accept (providesSpec
				// writes application/json / pdf onto the shared cgi struct)
				// makes $requestContentType() non-html, so $callAction skips
				// auto-render and both B5 its finish without throwing.
				// Pin HTML on params AND Accept so the missing-view path runs.
				_priorAccept = StructKeyExists(request, "cgi") && StructKeyExists(request.cgi, "http_accept")
					? request.cgi.http_accept
					: ""
				if (!StructKeyExists(request, "cgi")) {
					request.cgi = {}
				}
				request.cgi.http_accept = "text/html"
				// Prove the production Throw, not the $throwErrorOrShow404Page
				// showErrorInformation=true path. $get reads $appKey() so set()
				// writes the key $callAction's siblings would consult.
				_priorShowError = g.$get("showErrorInformation")
				g.set(showErrorInformation = false)
				params = {controller = "hardenerLifecycle", action = "noView", format = "html"}
				_controller = g.controller("hardenerLifecycle", params)
				_classData = _controller.$getControllerClassData()
				_priorLayouts = Duplicate(_classData.layouts)
			})

			afterEach(() => {
				_classData.layouts = _priorLayouts
				g.set(showErrorInformation = _priorShowError)
				if (StructKeyExists(request, "cgi")) {
					request.cgi.http_accept = _priorAccept
				}
			})

			it("still maps a genuine missing view to ViewNotFound", () => {
				expect(() => {
					_controller.$callAction(action = "noView")
				}).toThrow("Wheels.ViewNotFound")
			})

			it("preserves a layout function error when the action view is missing", () => {
				// Bind the layout fn on this instance so usesLayout / $useLayout
				// resolve it as a function (same pattern as renderingSpec).
				var boom = function() {
					Throw(type = "Wheels.HardenerLayoutError", message = "layout exploded on purpose");
				};
				_controller.explodingLayout = boom
				_controller.usesLayout(template = "explodingLayout")

				expect(() => {
					_controller.$callAction(action = "noView")
				}).toThrow("Wheels.HardenerLayoutError")
			})

		})

		describe("B6 $useLayout later non-match does not wipe a prior match", () => {

			beforeEach(() => {
				params = {controller = "hardenerLifecycle", action = "secret"}
				_controller = g.controller("hardenerLifecycle", params)
				_classData = _controller.$getControllerClassData()
				_priorLayouts = Duplicate(_classData.layouts)
			})

			afterEach(() => {
				_classData.layouts = _priorLayouts
			})

			it("keeps the first matching usesLayout when a later only= does not apply", () => {
				_controller.usesLayout(template = "admin", only = "secret")
				_controller.usesLayout(template = "public", only = "index")

				expect(_controller.$useLayout("secret")).toBe("admin")
			})

			it("lets a later matching usesLayout override an earlier match", () => {
				_controller.usesLayout(template = "admin")
				_controller.usesLayout(template = "special", only = "secret")

				expect(_controller.$useLayout("secret")).toBe("special")
				expect(_controller.$useLayout("index")).toBe("admin")
			})

			it("still uses useDefault when no usesLayout matches", () => {
				_controller.usesLayout(template = "admin", only = "secret", useDefault = false)
				_controller.usesLayout(template = "public", only = "index")

				expect(_controller.$useLayout("list")).toBeTrue()
			})

		})

		describe("SHOULD $callActionAndAddToCache does not cache a redirect-only response", () => {

			beforeEach(() => {
				_hadCacheActions = StructKeyExists(application.wheels, "cacheActions")
				if (_hadCacheActions) {
					_priorCacheActions = application.wheels.cacheActions
				}
				application.wheels.cacheActions = true
				_originalForm = Duplicate(form)
				StructClear(form)
				_controller = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedRedirect"})
				_controller.$clearCachableActions()
				g.$clearCache("action")
			})

			afterEach(() => {
				// g.$clearCache() first: a closure whose first two statements are
				// a zero-arg $-member call followed by an argumented $-member call
				// crashes Adobe 2025's compiler (MissingNameException).
				g.$clearCache("action")
				_controller.$clearCachableActions()
				StructClear(form)
				StructAppend(form, _originalForm, false)
				if (_hadCacheActions) {
					application.wheels.cacheActions = _priorCacheActions
				} else {
					StructDelete(application.wheels, "cacheActions")
				}
			})

			it("does not store a cache entry for a redirect-only action", () => {
				var probeKey = "hardener-redirect-probe-key"
				_controller.$callActionAndAddToCache(
					action = "cachedRedirect",
					time = 60,
					key = probeKey,
					category = "action"
				)
				expect(_controller.$performedRedirect()).toBeTrue()
				expect(StructKeyExists(application.wheels.cache.action, probeKey)).toBeFalse()
			})

			it("re-runs the redirect on a second request instead of serving a blank 200", () => {
				_controller.caches(action = "cachedRedirect")

				var first = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedRedirect"})
				first.processAction()
				expect(first.$performedRedirect()).toBeTrue()

				var second = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedRedirect"})
				second.processAction()
				expect(second.$performedRedirect()).toBeTrue()
				expect(second.getRedirect().url).toInclude("/hardener-redirect-target")
			})

		})

		describe("SHOULD filterChain(all) returns a copy", () => {

			beforeEach(() => {
				params = {controller = "hardenerLifecycle", action = "secret"}
				_controller = g.controller("hardenerLifecycle", params)
				_classData = _controller.$getControllerClassData()
				_priorFilters = Duplicate(_classData.filters)
			})

			afterEach(() => {
				_classData.filters = _priorFilters
			})

			it("does not let callers mutate the live $class.filters array", () => {
				var chain = _controller.filterChain("all")
				var originalLen = ArrayLen(chain)
				ArrayAppend(chain, {through = "hardenerMutated"})

				expect(ArrayLen(_controller.filterChain("all"))).toBe(originalLen)
			})

		})

		describe("SHOULD processAction returns false when a before filter halts", () => {

			beforeEach(() => {
				request.hardenerSecretRan = false
				request.hardenerDenyRan = false
				request.hardenerAllow = false
				params = {controller = "hardenerLifecycle", action = "secret"}
				_controller = g.controller("hardenerLifecycle", params)
			})

			it("returns false when a before filter returns false", () => {
				expect(_controller.processAction()).toBeFalse()
				expect(request.hardenerSecretRan).toBeFalse()
			})

			it("returns true when the action is allowed to run", () => {
				request.hardenerAllow = true
				expect(_controller.processAction()).toBeTrue()
				expect(request.hardenerSecretRan).toBeTrue()
			})

		})

		describe("SHOULD filters prepend keeps through order", () => {

			beforeEach(() => {
				params = {controller = "hardenerLifecycle", action = "secret"}
				_controller = g.controller("hardenerLifecycle", params)
				_classData = _controller.$getControllerClassData()
				_priorFilters = Duplicate(_classData.filters)
				_controller.setFilterChain([])
			})

			afterEach(() => {
				_classData.filters = _priorFilters
			})

			it("prepends a multi-through list without reversing it", () => {
				_controller.filters(through = "existing")
				_controller.filters(through = "alpha,bravo,charlie", placement = "prepend")
				var chain = _controller.filterChain("all")

				expect(chain[1].through).toBe("alpha")
				expect(chain[2].through).toBe("bravo")
				expect(chain[3].through).toBe("charlie")
				expect(chain[4].through).toBe("existing")
			})

		})

		describe("SHOULD redirectTo(url=) encodes params like back=", () => {

			beforeEach(() => {
				params = {controller = "hardenerLifecycle", action = "secret"}
				_controller = g.controller("hardenerLifecycle", params)
			})

			it("percent-encodes query values appended to url=", () => {
				_controller.redirectTo(url = "/hardener-target", params = "q=hello world", delay = true)
				var dest = _controller.getRedirect().url
				expect(dest).notToInclude("hello world")
				expect(ReFindNoCase("hello(%20|[+])world", dest) > 0).toBeTrue()
			})

		})

		describe("SHOULD blank layout function return uses the default layout", () => {

			beforeEach(() => {
				params = {controller = "hardenerLifecycle", action = "noView"}
				_controller = g.controller("hardenerLifecycle", params)
				_classData = _controller.$getControllerClassData()
				_priorLayouts = Duplicate(_classData.layouts)
			})

			afterEach(() => {
				_classData.layouts = _priorLayouts
			})

			it("treats a blank string return as useDefault instead of no layout", () => {
				_controller.usesLayout(template = "blankLayout")
				expect(_controller.$useLayout("noView")).toBeTrue()
			})

		})

	}

}
