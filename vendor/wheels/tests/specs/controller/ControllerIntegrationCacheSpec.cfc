/**
 * Controller construction applies a per-class cached integration result (#4149)
 * instead of mixing the controller and view methods in one at a time. These specs
 * pin that the cached path writes exactly what the loop writes, including the
 * super<name> aliases an override delegates through (#3325 / #3933).
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Controller integration cache (##4149)", () => {

			beforeEach(() => {
				state = {saved = application.wheels.cacheControllerIntegration}
			})

			afterEach(() => {
				application.wheels.cacheControllerIntegration = state.saved
			})

			it("gives an instance the same public keys with the cache on and off", () => {
				for (var name in ["superOverride", "superLinkDot", "test"]) {
					var off = $build(name, false)
					var on = $build(name, true)
					expect($sortedKeys(on)).toBe($sortedKeys(off), name)
				}
			})

			it("keeps an override and its super<name> delegation identical with the cache on and off", () => {
				var off = $build("superOverride", false).linkTo(text = "Home", route = "root")
				var on = $build("superOverride", true).linkTo(text = "Home", route = "root")
				expect(on).toBe(off)
				expect(on).toStartWith("wrapped:")
				expect(on).notToInclude("wrapped:wrapped:")
			})

			it("keeps super.<name>() from an override identical with the cache on and off", () => {
				var off = $outcome($build("superLinkDot", false))
				var on = $outcome($build("superLinkDot", true))
				expect(on.threw).toBe(off.threw)
				expect(on.result).toBe(off.result)
			})

			it("builds one result per class and reuses it", () => {
				var first = $build("superOverride", true)
				var key = $classKey(first)
				expect(StructKeyExists(application.wheels.controllerIntegration, key)).toBeTrue()
				var result = application.wheels.controllerIntegration[key]
				expect(ArrayFindNoCase(result.collisions, "linkTo")).toBeGT(0, "linkTo is an override")
				expect(StructKeyExists(result.supers, "superLinkTo")).toBeTrue()
				expect(StructKeyExists(result.adds, "linkTo")).toBeFalse()
				$build("superOverride", true)
				expect(application.wheels.controllerIntegration[key].key).toBe(key)
				var other = $build("test", true)
				expect($classKey(other)).notToBe(key)
				expect(StructKeyExists(application.wheels.controllerIntegration, $classKey(other))).toBeTrue()
			})

			it("falls back to the loop and rebuilds when an override the result expects is missing", () => {
				var first = $build("superOverride", true)
				var key = $classKey(first)
				ArrayAppend(application.wheels.controllerIntegration[key].collisions, "zzNoSuchMethod4149")
				var c = $build("superOverride", true)
				expect(c.linkTo(text = "Home", route = "root")).toStartWith("wrapped:")
				expect(StructKeyExists(application.wheels.controllerIntegration, key)).toBeFalse("the stale result is dropped")
				$build("superOverride", true)
				expect(ArrayFindNoCase(application.wheels.controllerIntegration[key].collisions, "zzNoSuchMethod4149")).toBe(0)
			})

			it("doesn't build a result when the cache is off", () => {
				var c = $build("test", false)
				expect(StructKeyExists(application.wheels.controllerIntegration, $classKey(c))).toBeFalse()
				expect(IsCustomFunction(c.linkTo)).toBeTrue()
			})

		})

	}

	// A controller instance built with the cache switched on or off. The class's cached
	// result is cleared first, so each call builds or reuses as the spec intends.
	private any function $build(required string name, required boolean cached) {
		application.wheels.cacheControllerIntegration = arguments.cached
		if (!arguments.cached) {
			StructClear(application.wheels.controllerIntegration)
		}
		// Params make controller() build a new instance rather than return the cached class.
		return g.controller(name = arguments.name, params = {controller = arguments.name, action = "index"})
	}

	private string function $classKey(required any controller) {
		var meta = GetMetaData(arguments.controller)
		return StructKeyExists(meta, "fullName") && Len(meta.fullName) ? meta.fullName : meta.name
	}

	private string function $sortedKeys(required any controller) {
		var keys = StructKeyArray(arguments.controller)
		ArraySort(keys, "textnocase")
		return ArrayToList(keys)
	}

	private struct function $outcome(required any controller) {
		var outcome = {threw = false, result = ""}
		try {
			outcome.result = arguments.controller.linkTo(text = "Home", route = "root")
		} catch (any e) {
			outcome.threw = true
		}
		return outcome
	}

}
