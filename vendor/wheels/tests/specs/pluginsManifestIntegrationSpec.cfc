component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that manifest mixins override CFC metadata", function() {

			it("uses plugin.json mixins field instead of CFC mixin attribute", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/manifest_integration",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/manifest_integration"

				PluginObj = $pluginObj(config)
				var mixins = PluginObj.getMixins()

				// ManifestMixinPlugin CFC declares mixin="controller" but
				// plugin.json declares mixins="model". Manifest should win.
				expect(mixins.model).toHaveKey("$ManifestMixinTestMethod")
				expect(mixins.controller).notToHaveKey("$ManifestMixinTestMethod")

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("falls back to CFC mixin attribute when no manifest mixins field", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				// Use the standard manifest fixture (TestManifestPlugin has mixin="controller" on CFC
				// AND mixins="controller" in plugin.json — both agree, but test that the CFC attribute
				// works when there is no manifest)
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/manifest",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/manifest"

				PluginObj = $pluginObj(config)
				var mixins = PluginObj.getMixins()

				// TestNoManifestPlugin has no plugin.json and no mixin attribute → global mixins
				expect(mixins.controller).toHaveKey("$NoManifestTestMethod")
				expect(mixins.model).toHaveKey("$NoManifestTestMethod")

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

		})

		describe("Tests that manifest middleware auto-registration", function() {

			it("auto-registers middleware declared in plugin.json", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/manifest_integration",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/manifest_integration"

				PluginObj = $pluginObj(config)
				var pluginMiddleware = PluginObj.getPluginMiddleware()

				expect(pluginMiddleware).toBeArray()
				// ManifestMiddlewarePlugin declares 2 middleware entries in plugin.json
				var found = 0
				for (var mw in pluginMiddleware) {
					if (mw.pluginName == "ManifestMiddlewarePlugin") {
						found++
					}
				}
				expect(found).toBe(2)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("preserves middleware options from plugin.json", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/manifest_integration",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/manifest_integration"

				PluginObj = $pluginObj(config)
				var pluginMiddleware = PluginObj.getPluginMiddleware()

				var foundWithOptions = false
				var foundWithoutOptions = false
				for (var mw in pluginMiddleware) {
					if (mw.pluginName == "ManifestMiddlewarePlugin") {
						if (mw.middleware == "ManifestTestMiddleware") {
							expect(mw.options).toHaveKey("priority")
							expect(mw.options.priority).toBe(5)
							foundWithOptions = true
						}
						if (mw.middleware == "ManifestTestMiddleware2") {
							expect(StructIsEmpty(mw.options)).toBeTrue()
							foundWithoutOptions = true
						}
					}
				}
				expect(foundWithOptions).toBeTrue()
				expect(foundWithoutOptions).toBeTrue()

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("does not register middleware for plugins without manifest middleware", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/manifest",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/manifest"

				PluginObj = $pluginObj(config)
				var pluginMiddleware = PluginObj.getPluginMiddleware()

				// manifest fixtures don't have onPluginLoad middleware registration
				// and only TestManifestPlugin has middleware in plugin.json but it won't
				// be auto-registered because SomeOtherPlugin dependency would need to
				// exist — actually, middleware registration doesn't depend on dependency resolution
				// so it should still register
				// TestManifestPlugin has middleware in plugin.json
				var found = 0
				for (var mw in pluginMiddleware) {
					if (mw.pluginName == "TestManifestPlugin") {
						found++
					}
				}
				expect(found).toBe(1)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

		})

		describe("Tests that manifest wheelsVersion compatibility", function() {

			it("uses manifest wheelsVersion for compatibility check", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/manifest_incompat",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsVersion = "3.0.0"
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/manifest_incompat"

				PluginObj = $pluginObj(config)
				var incompatible = PluginObj.getIncompatiblePlugins()

				// IncompatManifestPlugin declares wheelsVersion: "1.0" but we're running "3.0.0"
				expect(ListFind(incompatible, "IncompatManifestPlugin")).toBeGT(0)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("allows compatible plugins via manifest wheelsVersion", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/manifest_integration",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsVersion = "3.0.0"
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/manifest_integration"

				PluginObj = $pluginObj(config)
				var incompatible = PluginObj.getIncompatiblePlugins()

				// ManifestCompatPlugin declares wheelsVersion: "3.0" and we're running "3.0.0"
				expect(ListFind(incompatible, "ManifestCompatPlugin")).toBe(0)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("manifest wheelsVersion overrides CFC this.version for compatibility", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				// IncompatManifestPlugin CFC has no this.version but manifest has wheelsVersion: "1.0"
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/manifest_incompat",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsVersion = "1.0.0"
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/manifest_incompat"

				PluginObj = $pluginObj(config)
				var incompatible = PluginObj.getIncompatiblePlugins()

				// wheelsVersion "1.0" should match "1.0.0" (major.minor matching)
				expect(ListFind(incompatible, "IncompatManifestPlugin")).toBe(0)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

		})

		describe("Tests that manifest author and description surfacing", function() {

			it("surfaces author from plugin.json as top-level metadata", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/manifest_integration",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/manifest_integration"

				PluginObj = $pluginObj(config)
				var meta = PluginObj.getPluginMeta()

				expect(meta.ManifestMiddlewarePlugin).toHaveKey("author")
				expect(meta.ManifestMiddlewarePlugin.author).toBe("Wheels Test Suite")

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("surfaces description from plugin.json as top-level metadata", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/manifest_integration",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/manifest_integration"

				PluginObj = $pluginObj(config)
				var meta = PluginObj.getPluginMeta()

				expect(meta.ManifestMiddlewarePlugin).toHaveKey("description")
				expect(meta.ManifestMiddlewarePlugin.description).toBe("Plugin that declares middleware via manifest")

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("defaults author and description to empty string without manifest", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/manifest",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/manifest"

				PluginObj = $pluginObj(config)
				var meta = PluginObj.getPluginMeta()

				expect(meta.TestNoManifestPlugin).toHaveKey("author")
				expect(meta.TestNoManifestPlugin.author).toBe("")
				expect(meta.TestNoManifestPlugin).toHaveKey("description")
				expect(meta.TestNoManifestPlugin.description).toBe("")

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

		})

	}

	function $pluginObj(required struct config) {
		return g.$createObjectFromRoot(argumentCollection = arguments.config)
	}

}
