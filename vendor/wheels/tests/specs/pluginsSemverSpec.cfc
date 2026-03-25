component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		beforeEach(function() {
			_originalPluginComponentPath = application.wheels.pluginComponentPath;
		});

		afterEach(function() {
			application.wheels.pluginComponentPath = _originalPluginComponentPath;
		});

		describe("Tests that semver-aware dependency resolution", function() {

			it("reports no version mismatches when constraint is satisfied", function() {

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/semver",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/semver"

				PluginObj = $pluginObj(config)
				var mismatches = PluginObj.getVersionMismatchPlugins()

				expect(mismatches).toBe("")
			})

			it("reports version mismatch when constraint is not satisfied", function() {
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/semver_mismatch",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsEnvironment = "production"
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/semver_mismatch"

				PluginObj = $pluginObj(config)
				var mismatches = PluginObj.getVersionMismatchPlugins()

				expect(Len(mismatches)).toBeGT(0)
				expect(mismatches).toInclude("NeedyPlugin")
				expect(mismatches).toInclude("OldDep")
			})

			it("throws in non-production environment on version mismatch", function() {
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/semver_mismatch",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsEnvironment = "development"
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/semver_mismatch"

				expect(function() {
					$pluginObj(config)
				}).toThrow("Wheels.PluginVersionMismatch")
			})

			it("reads dependencies from plugin.json over box.json", function() {
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/semver_pluginjson",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/semver_pluginjson"

				PluginObj = $pluginObj(config)
				var mismatches = PluginObj.getVersionMismatchPlugins()

				// plugin.json says >=2.0.0 <3.0.0 (satisfied by 2.1.0)
				// box.json says >=9.0.0 (would NOT be satisfied)
				// If plugin.json takes precedence, no mismatch
				expect(mismatches).toBe("")
			})

			it("populates pluginMeta dependencies struct from box.json", function() {
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/semver",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/semver"

				PluginObj = $pluginObj(config)
				var meta = PluginObj.getPluginMeta()

				expect(meta).toHaveKey("PluginWithDeps")
				expect(meta.PluginWithDeps).toHaveKey("dependencies")
				expect(IsStruct(meta.PluginWithDeps.dependencies)).toBeTrue()
				expect(meta.PluginWithDeps.dependencies).toHaveKey("DepPlugin")
			})

			it("reads version from box.json into pluginMeta", function() {
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/semver",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/semver"

				PluginObj = $pluginObj(config)
				var meta = PluginObj.getPluginMeta()

				expect(meta).toHaveKey("DepPlugin")
				expect(meta.DepPlugin.version).toBe("2.1.0")
			})

		})

	}

	function $pluginObj(required struct config) {
		return g.$createObjectFromRoot(argumentCollection = arguments.config)
	}

}
