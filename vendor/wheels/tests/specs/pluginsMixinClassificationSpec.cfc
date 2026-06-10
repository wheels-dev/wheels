// di-packages:12 — $initializeMixins must classify components by dotted-path
// segment, not by unanchored substring. The old FindNoCase("controllers", ...)
// matched component NAMES like "ControllerStats" under app.models and handed
// them the controller mixin set.
component extends="wheels.WheelsTest" {

	function run() {

		describe("$initializeMixins component classification", () => {

			beforeEach(() => {
				originalMixins = application.wheels.mixins
				application.wheels.mixins = {
					controller = {"$wheelstestClassificationProbe" = "controller"},
					model = {"$wheelstestClassificationProbe" = "model"}
				}
			})

			afterEach(() => {
				application.wheels.mixins = originalMixins
			})

			it("classifies a model whose name contains 'Controller' as a model", () => {
				var target = CreateObject(
					"component",
					"wheels.tests._assets.mixins_classification.models.ControllerStats"
				)
				var scopeStruct = {}
				scopeStruct["this"] = target
				new wheels.Plugins().$initializeMixins(scopeStruct)
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
				new wheels.Plugins().$initializeMixins(scopeStruct)
				expect(scopeStruct).toHaveKey("$wheelstestClassificationProbe")
				expect(scopeStruct.$wheelstestClassificationProbe).toBe("controller")
			})

		})

	}

}
