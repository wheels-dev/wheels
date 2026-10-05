// $initializeMixins must do nothing for a component whose class has no mixins.
// A plugin-free app still has one (empty) entry per class in application.wheels.mixins,
// so the outer "any mixins at all" guard passes; before this check every model and
// controller instance then copied its whole variables scope into variables.core for nothing.
component extends="wheels.WheelsTest" {

	function run() {

		// Shared carrier struct: sibling closures (beforeEach/afterEach) must not
		// share state through bare unscoped names (CLAUDE.md anti-pattern 10).
		var state = {originalMixins = {}}

		describe("$initializeMixins with no mixins for the component's class", () => {

			beforeEach(() => {
				state.originalMixins = application.wheels.mixins
				// The shape a plugin-free app has: per-class keys, all empty.
				application.wheels.mixins = {controller = {}, model = {}}
			})

			afterEach(() => {
				application.wheels.mixins = state.originalMixins
			})

			it("leaves a model's scope untouched", () => {
				var scopeStruct = {marker = "unchanged"}
				scopeStruct["this"] = CreateObject("component", "wheels.tests._assets.mixins_classification.models.ControllerStats")
				var keysBefore = ListSort(StructKeyList(scopeStruct), "textnocase")
				// CreateObject skips init() so the plugin-loading constructor side effects don't leak.
				CreateObject("component", "wheels.Plugins").$initializeMixins(scopeStruct)
				expect(scopeStruct).notToHaveKey("core")
				expect(ListSort(StructKeyList(scopeStruct), "textnocase")).toBe(keysBefore)
			})

			it("leaves a controller's scope untouched", () => {
				var scopeStruct = {marker = "unchanged"}
				scopeStruct["this"] = CreateObject("component", "wheels.tests._assets.mixins_classification.controllers.Visitors")
				CreateObject("component", "wheels.Plugins").$initializeMixins(scopeStruct)
				expect(scopeStruct).notToHaveKey("core")
			})

			it("still keeps the original scope in core and applies the mixin when the class has one", () => {
				application.wheels.mixins.model = {"$wheelstestEmptyMixinsProbe" = "applied"}
				var scopeStruct = {marker = "original"}
				scopeStruct["this"] = CreateObject("component", "wheels.tests._assets.mixins_classification.models.ControllerStats")
				CreateObject("component", "wheels.Plugins").$initializeMixins(scopeStruct)
				expect(scopeStruct).toHaveKey("core")
				expect(scopeStruct.core.marker).toBe("original")
				expect(scopeStruct.$wheelstestEmptyMixinsProbe).toBe("applied")
			})

		})

	}

}
