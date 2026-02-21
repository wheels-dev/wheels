component extends="wheels.Testbox" {
	
	function run() {

		describe("Tests that $addCachableAction", () => {

			it("is adding cachable action", () => {
				_controller = application.wo.controller(name = "dummy")
				_controller.$clearCachableActions()
				_controller.caches("dummy1")
				str = {}
				str.action = "dummy2"
				str.time = 10
				str.static = true
				_controller.$addCachableAction(str)
				r = _controller.$cachableActions()

				expect(r).toHaveLength(2)
				expect(r[2].action).toBe("dummy2")
			})
		})

		describe("Tests that $cachableActions", () => {

			it("is getting cachable actions", () => {
				_controller = application.wo.controller(name = "dummy")
				_controller.$clearCachableActions()
				_controller.caches(actions = "dummy1,dummy2")
				r = _controller.$cachableActions()

				expect(r).toHaveLength(2)
				expect(r[1].static).toBeFalse()
			})
		})

		describe("Tests that $cacheSettingsForAction", () => {

			it("is getting cache settings for action", () => {
				_controller = application.wo.controller(name = "dummy")
				_controller.caches(action = "dummy1", time = 100)
				r = _controller.$cacheSettingsForAction("dummy1")

				expect(r.time).toBe(100)
			})
		})

		describe("Tests that $clearCachableActions", () => {

			it("is clearing cachable actions", () => {
				_controller = application.wo.controller(name = "dummy")
				_controller.caches(action = "dummy")
				_controller.$clearCachableActions()
				r = _controller.$cachableActions()

				expect(r).toHaveLength(0)
			})
		})

		describe("Tests that $hasCachableActions", () => {

			it("is checking cachable action", () => {
				_controller = application.wo.controller(name = "dummy")
				_controller.$clearCachableActions()
				result = _controller.$hasCachableActions()

				expect(result).toBeFalse()

				_controller.caches("dummy1")
				result = _controller.$hasCachableActions()

				expect(result).toBeTrue()
			})
		})

		describe("Tests that $setCachableActions", () => {

			it("is setting cachable actions", () => {
				_controller = application.wo.controller(name = "dummy")
				arr = []
				arr[1] = {}
				arr[1].action = "dummy1"
				arr[1].time = 10
				arr[1].static = true
				arr[2] = {}
				arr[2].action = "dummy2"
				arr[2].time = 10
				arr[2].static = true
				_controller.$setCachableActions(arr)
				r = _controller.$cachableActions()

				expect(r).toHaveLength(2)
				expect(r[2].action).toBe('dummy2')
			})
		})

		describe("Tests that caches", () => {
			
			beforeEach(() => {
				params = {controller = "test", action = "test"}
				_controller = application.wo.controller("test", params)
				_controller.$clearCachableActions()
			})

			it("is specifying one action to cache", () => {
				_controller.caches(action = "dummy")
				r = _controller.$cacheSettingsForAction("dummy")

				expect(r.time).toBe(60)
			})

			it("is specifying one action to cache and running it", () => {
				_controller.caches(action = "test")
				result = _controller.processAction("test", params)

				expect(result).toBeTrue()
			})

			it("is specifying multiple actions to cache", () => {
				_controller.caches(actions = "dummy1,dummy2")
				r = _controller.$cachableActions()

				expect(r).toHaveLength(2)
				expect(r[2].time).toBe(60)
			})

			it("is specifying actions to cache with options", () => {
				_controller.caches(actions = "dummy1,dummy2", time = 5, static = true)
				r = _controller.$cachableActions()

				expect(r).toHaveLength(2)
				expect(r[2].time).toBe(5)
				expect(r[2].static).toBeTrue()
			})

			it("is specifying actions to cache with options", () => {
				_controller.caches(static = true)
				r = _controller.$cacheSettingsForAction("dummy")

				expect(r.static).toBeTrue()
			})
		})

		describe("Tests for clearCachableActions(action)", () => {

			beforeEach(() => {
				_controller = application.wo.controller(name = "dummy")
				_controller.$clearCachableActions()
			})

			it("clears a specific cached action when only one is matched", () => {
				_controller.caches(actions = "dummy1,dummy2", time = 10, static = true)
				_controller.clearCachableActions("dummy1")
				r = _controller.$cachableActions()

				expect(r).toHaveLength(1)
				expect(r[1].action).toBe("dummy2")
			})

			it("clears multiple specified cached actions", () => {
				_controller.caches(actions = "dummy1,dummy2,dummy3", time = 5)
				_controller.clearCachableActions("dummy1,dummy3")
				r = _controller.$cachableActions()

				expect(r).toHaveLength(1)
				expect(r[1].action).toBe("dummy2")
			})

			it("clears nothing if specified action is not cached", () => {
				_controller.caches(actions = "dummy1,dummy2")

				_controller.clearCachableActions("doesNotExist")

				r = _controller.$cachableActions()

				expect(r).toHaveLength(2)
				expect(r[1].action).toBe("dummy1")
				expect(r[2].action).toBe("dummy2")
			})

			it("is case-insensitive when matching actions", () => {
				_controller.caches(actions = "Dummy1,Dummy2")
				_controller.clearCachableActions("dummy1")
				r = _controller.$cachableActions()

				expect(r).toHaveLength(1)
				expect(r[1].action).toBe("Dummy2")
			})

			it("clears all when no action is passed (backward compatibility)", () => {
				_controller.caches(actions = "dummy1,dummy2")
				_controller.clearCachableActions()
				r = _controller.$cachableActions()

				expect(r).toHaveLength(0)
			})
		})

	}
}