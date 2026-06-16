component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		// The legacy plugins/ directory is deprecated (superseded by vendor/<name>/
		// packages) and apps are expected to remove it. The plugin loader must not
		// error when it is absent — Lucee/Adobe return empty for a missing dir, but
		// stricter engines (e.g. RustCFML) throw on directory listing of a missing
		// path, which previously failed onApplicationStart. $folders()/$files() now
		// short-circuit to an empty query when the directory does not exist.
		describe("plugin loader with an absent plugins/ directory", () => {

			missingPath = "/wheels/tests/_assets/plugins/__this_directory_does_not_exist__"

			it("initializes without throwing when the plugins directory is missing", () => {
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = missingPath,
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				var state = {thrown = false}
				try {
					pluginObj = $pluginObj(config)
				} catch (any e) {
					state.thrown = true
				}
				expect(state.thrown).toBeFalse()
			})

			it("$folders() returns an empty query for a missing directory", () => {
				var config = {
					path = "wheels", fileName = "Plugins", method = "$init", pluginPath = missingPath,
					deletePluginDirectories = false, overwritePlugins = false, loadIncompatiblePlugins = true
				}
				var pluginObj = $pluginObj(config)
				expect(pluginObj.$folders().recordCount).toBe(0)
			})

			it("$files() returns an empty query for a missing directory", () => {
				var config = {
					path = "wheels", fileName = "Plugins", method = "$init", pluginPath = missingPath,
					deletePluginDirectories = false, overwritePlugins = false, loadIncompatiblePlugins = true
				}
				var pluginObj = $pluginObj(config)
				expect(pluginObj.$files().recordCount).toBe(0)
			})
		})
	}

	// Mirror the sibling plugin specs (pluginsSpec.cfc:549, pluginsModernSpec,
	// pluginsSemverSpec, pluginsManifestIntegrationSpec): a component-level
	// helper that instantiates wheels.Plugins via $createObjectFromRoot and
	// dispatches $init with the full config — INCLUDING pluginPath. Without it,
	// $pluginObj(config) resolves to the parameterless Global.$pluginObj() that
	// WheelsTest auto-binds, which ignores config and returns the cached PluginObj
	// pointing at the real plugins/ dir — so the missing-path branch (the fix)
	// never runs and these specs pass for the wrong reason.
	function $pluginObj(required struct config) {
		return g.$createObjectFromRoot(argumentCollection = arguments.config)
	}
}
