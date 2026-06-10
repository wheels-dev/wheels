// di-packages:12 — $initializeMixins must classify components by dotted-path
// segment, not by unanchored substring. The old FindNoCase("controllers", ...)
// matched component NAMES like "ControllerStats" under app.models and handed
// them the controller mixin set.
component extends="wheels.WheelsTest" {

	function run() {

		// Shared carrier struct: sibling closures (beforeEach/afterEach) must not
		// share state through bare unscoped names (CLAUDE.md anti-pattern 10) —
		// they read the outer struct reference and mutate its fields instead.
		var state = {originalMixins = {}}

		describe("$initializeMixins component classification", () => {

			beforeEach(() => {
				state.originalMixins = application.wheels.mixins
				application.wheels.mixins = {
					controller = {"$wheelstestClassificationProbe" = "controller"},
					model = {"$wheelstestClassificationProbe" = "model"}
				}
			})

			afterEach(() => {
				application.wheels.mixins = state.originalMixins
			})

			it("classifies a model whose name contains 'Controller' as a model", () => {
				var target = CreateObject(
					"component",
					"wheels.tests._assets.mixins_classification.models.ControllerStats"
				)
				var scopeStruct = {}
				scopeStruct["this"] = target
				// CreateObject skips init() so the plugin-loading constructor side effects
				// (e.g. $checkPluginsDeprecation appending to application.wheels.deprecationWarnings)
				// do not leak across this spec.
				CreateObject("component", "wheels.Plugins").$initializeMixins(scopeStruct)
				expect(scopeStruct).toHaveKey("$wheelstestClassificationProbe")
				expect(scopeStruct.$wheelstestClassificationProbe).toBe("model")
			})

			it("still classifies components under a controllers segment as controllers", () => {
				var target = CreateObject(
					"component",
					"wheels.tests._assets.mixins_classification.controllers.Visitors"
				)
				var scopeStruct = {}
				scopeStruct["this"] = target
				CreateObject("component", "wheels.Plugins").$initializeMixins(scopeStruct)
				expect(scopeStruct).toHaveKey("$wheelstestClassificationProbe")
				expect(scopeStruct.$wheelstestClassificationProbe).toBe("controller")
			})

		})

	}

}
