// Issue #2897 (Stage 3) — the cached application[appKey].PluginObj is shared
// across every request-lifecycle call site (controller/model/dispatch
// onDIcomplete + $runOnRequestStart), so $initializeMixins must keep its
// scratch state ($wheels.appKey/.metaData/.className) strictly local-scoped.
// Unscoped writes land in the shared instance's variables scope and race
// across concurrent requests ($wheels.className is the field that would
// cross-contaminate classification).
component extends="wheels.WheelsTest" {

	function run() {

		// Shared carrier struct: sibling closures (beforeEach/afterEach) must not
		// share state through bare unscoped names (CLAUDE.md anti-pattern 10) —
		// they read the outer struct reference and mutate its fields instead.
		var state = {originalMixins = {}}

		describe("$initializeMixins on a shared Plugins instance", () => {

			beforeEach(() => {
				state.originalMixins = application.wheels.mixins
				application.wheels.mixins = {
					controller = {"$wheelstestSharedInstanceProbe" = "controller"},
					model = {"$wheelstestSharedInstanceProbe" = "model"}
				}
			})

			afterEach(() => {
				application.wheels.mixins = state.originalMixins
			})

			it("keeps scratch writes out of the instance's own variables scope", () => {
				var probe = CreateObject("component", "wheels.tests._assets.plugins.scratch_probe.ScratchProbe")
				var target = CreateObject(
					"component",
					"wheels.tests._assets.mixins_classification.models.ControllerStats"
				)
				var scopeStruct = {}
				scopeStruct["this"] = target
				probe.$initializeMixins(scopeStruct)
				// With unscoped `$wheels.*` writes this is true and a second request
				// running through the same shared instance can read the other
				// request's classification mid-flight.
				expect(probe.$hasScratchState()).toBeFalse()
			})

			it("classifies two differently-shaped targets through one shared instance without cross-contamination", () => {
				var shared = CreateObject("component", "wheels.Plugins")

				var modelTarget = CreateObject(
					"component",
					"wheels.tests._assets.mixins_classification.models.ControllerStats"
				)
				var modelScope = {}
				modelScope["this"] = modelTarget

				var controllerTarget = CreateObject(
					"component",
					"wheels.tests._assets.mixins_classification.controllers.Visitors"
				)
				var controllerScope = {}
				controllerScope["this"] = controllerTarget

				shared.$initializeMixins(modelScope)
				shared.$initializeMixins(controllerScope)

				expect(modelScope).toHaveKey("$wheelstestSharedInstanceProbe")
				expect(modelScope.$wheelstestSharedInstanceProbe).toBe("model")
				expect(controllerScope).toHaveKey("$wheelstestSharedInstanceProbe")
				expect(controllerScope.$wheelstestSharedInstanceProbe).toBe("controller")
			})

		})

		describe("$pluginObj()", () => {

			it("returns the application-cached PluginObj when present", () => {
				var hadOriginal = StructKeyExists(application.wheels, "PluginObj")
				var original = hadOriginal ? application.wheels.PluginObj : ""
				var sentinel = {}
				sentinel["$wheelstestPluginObjSentinel"] = true
				application.wheels.PluginObj = sentinel
				try {
					var got = application.wo.$pluginObj()
					expect(IsStruct(got)).toBeTrue()
					expect(got).toHaveKey("$wheelstestPluginObjSentinel")
				} finally {
					if (hadOriginal) {
						application.wheels.PluginObj = original
					} else {
						StructDelete(application.wheels, "PluginObj")
					}
				}
			})

			it("falls back to a fresh Plugins instance when the cache is absent", () => {
				var hadOriginal = StructKeyExists(application.wheels, "PluginObj")
				var original = hadOriginal ? application.wheels.PluginObj : ""
				StructDelete(application.wheels, "PluginObj")
				try {
					var got = application.wo.$pluginObj()
					expect(IsObject(got)).toBeTrue()
					expect(StructKeyExists(got, "$initializeMixins")).toBeTrue()
				} finally {
					if (hadOriginal) {
						application.wheels.PluginObj = original
					}
				}
			})

		})

	}

}
