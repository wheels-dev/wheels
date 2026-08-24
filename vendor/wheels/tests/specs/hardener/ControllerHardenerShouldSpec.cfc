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
				params = {controller = "hardenerLifecycle", action = "noView"}
				_controller = g.controller("hardenerLifecycle", params)
				_classData = _controller.$getControllerClassData()
				_priorLayouts = Duplicate(_classData.layouts)
			})

			afterEach(() => {
				_classData.layouts = _priorLayouts
			})

			it("still maps a genuine missing view to ViewNotFound", () => {
				var thrown = {type = ""}
				try {
					_controller.$callAction(action = "noView")
				} catch (any e) {
					thrown.type = e.type
				}
				expect(thrown.type).toBe("Wheels.ViewNotFound")
			})

			it("preserves a layout function error when the action view is missing", () => {
				_controller.usesLayout(template = "explodingLayout")

				var thrown = {type = ""}
				try {
					_controller.$callAction(action = "noView")
				} catch (any e) {
					thrown.type = e.type
				}
				expect(thrown.type).toBe("Wheels.HardenerLayoutError")
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
				_controller.$clearCachableActions()
				g.$clearCache("action")
				StructClear(form)
				StructAppend(form, _originalForm, false)
				if (_hadCacheActions) {
					application.wheels.cacheActions = _priorCacheActions
				} else {
					StructDelete(application.wheels, "cacheActions")
				}
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
				expect(_controller.getRedirect().url).toInclude("hello%20world")
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
