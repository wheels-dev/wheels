/**
 * Regression for #4646: Adobe CF 2023 update 26 / 2025 update 14 changed regex
 * REPLACEMENT parsing, so the case-escape used by Wheels emitted a literal "u"
 * (controller "main" resolved as "umain", "user-settings" as "uuserusettings",
 * /wheels/info setting labels as "udataSourceName"). Wheels now upper-cases by
 * walking characters instead, with no replacement-string escapes at all.
 *
 * The CI images are pre-patch, so the patched engine cannot run here; correctness is
 * pinned by case-sensitive expected output for the patch-26 shapes, a guarded
 * differential against the legacy regex on healthy engines, a simulation of the
 * patched output, and a source guard that the replacement escapes never come back.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Adobe u26/u14 regex replacement regression (##4646)", () => {

			describe("$upperCaseAfterDash()", () => {

				it("matches the previous replacement for controller-name shapes", () => {
					var expected = {
						"main" = "Main",
						"users" = "Users",
						"user-settings" = "UserSettings",
						"admin-user-settings" = "AdminUserSettings",
						"-main" = "Main",
						"a--b" = "A-B",
						"a-" = "A-",
						"A-B" = "A-B",
						"a-B" = "A-B",
						"a1-b2" = "A1B2",
						"main-2" = "Main-2",
						"café-über" = "Café-über",
						"" = ""
					}
					for (var input in expected) {
						expect(application.wheels.engineAdapter.$upperCaseAfterDash(input)).toBeWithCase(
							expected[input],
							"$upperCaseAfterDash('##input##')"
						)
					}
				})

				it("upper-cases after dashes without touching the first character when uppercaseFirst is false", () => {
					var expected = {
						"submit-form" = "submitForm",
						"admin-user-settings" = "adminUserSettings",
						"-main" = "Main",
						"submit--form" = "submit-Form",
						"a-" = "a-",
						"a-B" = "a-B",
						"a1-b2" = "a1B2",
						"main" = "main",
						"" = ""
					}
					for (var input in expected) {
						expect(application.wheels.engineAdapter.$upperCaseAfterDash(value = input, uppercaseFirst = false)).toBeWithCase(
							expected[input],
							"$upperCaseAfterDash('##input##', uppercaseFirst=false)"
						)
					}
				})

				it("matches the legacy regex replacement on engines where it still parses", () => {
					// Gate: on patched Adobe builds the legacy case escape emits a literal "u" (the
					// #4646 bug), so there is no legacy baseline to compare against there.
					if (ReReplace("a", "(^a)", "\u\1", "all") != "A") {
						return
					}
					var controllerCorpus = [
						"main", "users", "user-settings", "admin-user-settings", "-main", "a--b", "a-",
						"A-B", "a-B", "a1-b2", "main-2", "café-über", ""
					]
					for (var input in controllerCorpus) {
						expect(application.wheels.engineAdapter.$upperCaseAfterDash(input)).toBeWithCase(
							ReReplace(input, "(^|-)([a-z])", "\u\2", "all"),
							"controller differential for '##input##'"
						)
					}
					var actionCorpus = ["submit-form", "admin-user-settings", "-main", "submit--form", "a-", "a-B", "a1-b2", "main", ""]
					for (var input in actionCorpus) {
						expect(application.wheels.engineAdapter.$upperCaseAfterDash(value = input, uppercaseFirst = false)).toBeWithCase(
							ReReplace(input, "-([a-z])", "\u\1", "all"),
							"action differential for '##input##'"
						)
					}
				})

				it("does not depend on replacement-string parsing", () => {
					// On a patched engine the old replacement emitted a literal "u"; this mirrors
					// that output (literal "u" + the backreference) so the assertion below documents
					// the failure mode without needing a patched engine.
					var simulatedPatchedOutput = "u" & ReReplace("main", "(^|-)([a-z])", "\2", "all")
					expect(simulatedPatchedOutput).toBeWithCase("umain")
					expect(application.wheels.engineAdapter.$upperCaseAfterDash("main")).toBeWithCase("Main")
				})

			})

			describe("call sites", () => {

				it("converts controller names with the patch-26 shapes", () => {
					expect(application.wheels.engineAdapter.controllerNameToUpperCamelCase("main")).toBeWithCase("Main")
					expect(application.wheels.engineAdapter.controllerNameToUpperCamelCase("user-settings")).toBeWithCase("UserSettings")
					expect(application.wheels.engineAdapter.controllerNameToUpperCamelCase("admin.user-settings")).toBeWithCase("admin.UserSettings")
				})

				it("converts dot-prefixed names through both the base and BoxLang adapters", () => {
					var base = CreateObject("component", "wheels.engineAdapters.Base").init("")
					var boxlang = CreateObject("component", "wheels.engineAdapters.BoxLang.BoxLangAdapter").init("")
					// The base adapter keeps dot-delimited namespacing; the BoxLang override
					// deliberately works on the whole name (it preserves only leading dots).
					expect(base.controllerNameToUpperCamelCase("admin.user-settings")).toBeWithCase("admin.UserSettings")
					for (var adapter in [base, boxlang]) {
						expect(adapter.controllerNameToUpperCamelCase(".user")).toBeWithCase(".User")
						expect(adapter.controllerNameToUpperCamelCase("..user")).toBeWithCase("..User")
					}
				})

				it("camel-cases route actions through the same helper", () => {
					var dispatch = CreateObject("component", "wheels.Dispatch")
					var params = dispatch.$ensureControllerAndAction(
						params = {},
						route = {controller = "admin.user-settings", action = "submit-form"}
					)
					expect(params.controller).toBeWithCase("admin.UserSettings")
					expect(params.action).toBeWithCase("submitForm")
				})

				it("renders /wheels/info setting labels without a literal-u prefix", () => {
					var publicCfc = createObject("component", "wheels.Public").$init()
					var rows = publicCfc.outputSetting(setting = ["dataSourceName", "environment"])
					expect(Find(" Data Source Name", rows)).toBeGT(0, "label spacing should be preserved, got [##rows##]")
					expect(Find(" Environment", rows)).toBeGT(0, "label spacing should be preserved, got [##rows##]")
					expect(FindNoCase("udataSourceName", rows)).toBe(0, "the patched-engine literal-u prefix must not appear")
				})

			})

			describe("source guard", () => {

				it("keeps the removed replacement case-escapes out of the four affected files", () => {
					var sources = [
						"/wheels/engineAdapters/Base.cfc",
						"/wheels/engineAdapters/BoxLang/BoxLangAdapter.cfc",
						"/wheels/Dispatch.cfc",
						"/wheels/public/helpers.cfm"
					]
					for (var path in sources) {
						var source = FileRead(ExpandPath(path))
						expect(Find("\u", source)).toBe(0, "##path## must not use the \\u replacement case escape (##4646)")
					}
					// The three casing sites use the shared helper; outputSetting no longer builds
					// its label with ReReplace.
					expect(Find("$upperCaseAfterDash(local.cName)", FileRead(ExpandPath("/wheels/engineAdapters/Base.cfc")))).toBeGT(0)
					expect(Find("$upperCaseAfterDash(local.cleanName)", FileRead(ExpandPath("/wheels/engineAdapters/BoxLang/BoxLangAdapter.cfc")))).toBeGT(0)
					expect(Find("$upperCaseAfterDash(value = local.rv.action", FileRead(ExpandPath("/wheels/Dispatch.cfc")))).toBeGT(0)
					var helpers = FileRead(ExpandPath("/wheels/public/helpers.cfm"))
					expect(Find("ReReplace(ReReplace(arguments.setting[i]", helpers)).toBe(
						0,
						"outputSetting() must not build labels with the removed replacement pair (##4646)"
					)
					expect(Find("local.label", helpers)).toBeGT(0, "outputSetting() should build its label by hand")
				})

			})

		})

	}

}
