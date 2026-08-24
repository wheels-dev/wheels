/**
 * Hardener BLOCKERs B4, B7, B8 (controller filters and action cache keys).
 *
 * Directory-scoped so `wheels test --core --ci --filter=hardener`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("B4 before-filter return false halts processAction", () => {

			beforeEach(() => {
				request.hardenerSecretRan = false
				request.hardenerDenyRan = false
				request.hardenerAllow = false
				params = {controller = "hardenerLifecycle", action = "secret"}
				_controller = g.controller("hardenerLifecycle", params)
			})

			it("does not run the action when a before filter returns false", () => {
				_controller.processAction()

				expect(request.hardenerDenyRan).toBeTrue()
				expect(request.hardenerSecretRan).toBeFalse()
			})

			it("still runs the action when the before filter does not return false", () => {
				request.hardenerAllow = true
				_controller.processAction()

				expect(request.hardenerDenyRan).toBeTrue()
				expect(request.hardenerSecretRan).toBeTrue()
			})

		})

		describe("B8 filter type comparison is case-insensitive", () => {

			beforeEach(() => {
				request.hardenerCasedRan = false
				request.hardenerCasedFilterRan = false
				params = {controller = "hardenerLifecycle", action = "casedAction"}
				_controller = g.controller("hardenerLifecycle", params)
			})

			it("stores type=Before as canonical before so filterChain(before) includes it", () => {
				var before = _controller.filterChain("before")
				var found = false
				for (var filter in before) {
					if (filter.through == "denyCased") {
						found = true
						expect(filter.type).toBeWithCase("before")
					}
				}
				expect(found).toBeTrue()
			})

			it("runs a type=Before filter during $runFilters(type=before)", () => {
				_controller.$runFilters(type = "before", action = "casedAction")
				expect(request.hardenerCasedFilterRan).toBeTrue()
			})

			it("does not run the action when a type=Before filter returns false", () => {
				_controller.processAction()

				expect(request.hardenerCasedFilterRan).toBeTrue()
				expect(request.hardenerCasedRan).toBeFalse()
			})

		})

		describe("B7 caches appendToKey does not collapse distinct keys", () => {

			beforeEach(() => {
				_hadCacheActions = StructKeyExists(application.wheels, "cacheActions")
				if (_hadCacheActions) {
					_priorCacheActions = application.wheels.cacheActions
				}
				application.wheels.cacheActions = true
				_originalForm = Duplicate(form)
				StructClear(form)
				if (StructKeyExists(session, "user")) {
					_priorSessionUser = Duplicate(session.user)
				}
				if (StructKeyExists(session, "hardenerTenantId")) {
					_priorTenantId = session.hardenerTenantId
				}
				_controller = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"})
				_controller.$clearCachableActions()
				g.$clearCache("action")
			})

			afterEach(() => {
				_controller.$clearCachableActions()
				g.$clearCache("action")
				StructClear(form)
				StructAppend(form, _originalForm, false)
				if (StructKeyExists(variables, "_priorSessionUser")) {
					session.user = _priorSessionUser
				} else {
					StructDelete(session, "user")
				}
				if (StructKeyExists(variables, "_priorTenantId")) {
					session.hardenerTenantId = _priorTenantId
				} else {
					StructDelete(session, "hardenerTenantId")
				}
				if (_hadCacheActions) {
					application.wheels.cacheActions = _priorCacheActions
				} else {
					StructDelete(application.wheels, "cacheActions")
				}
			})

			it("does not serve one user a cached response built for another when appendToKey is nested", () => {
				_controller.caches(action = "cachedShow", appendToKey = "session.user.id")

				session.user = {id = "alice"}
				request.hardenerCachePayload = "payload-alice"
				var alice = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"})
				alice.processAction()
				expect(alice.response()).toBe("payload-alice")

				session.user = {id = "bob"}
				request.hardenerCachePayload = "payload-bob"
				var bob = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"})
				bob.processAction()
				expect(bob.response()).toBe("payload-bob")
			})

			it("throws instead of silently omitting an undefined appendToKey item", () => {
				_controller.caches(action = "cachedShow", appendToKey = "session.hardenerTenantId")
				StructDelete(session, "hardenerTenantId")
				request.hardenerCachePayload = "secret-a"

				var thrown = {type = ""}
				try {
					var first = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"})
					first.processAction()
				} catch (any e) {
					thrown.type = e.type
				}
				expect(thrown.type).toBe("Wheels.KeyNotFound")
			})

		})

	}

}
