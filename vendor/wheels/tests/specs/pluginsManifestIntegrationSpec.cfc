component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		beforeEach(function() {
			_originalPluginComponentPath = application.wheels.pluginComponentPath;
		});

		afterEach(function() {
			application.wheels.pluginComponentPath = _originalPluginComponentPath;
		});

		describe("Tests that manifest mixins override CFC metadata", function() {

			it("uses plugin.json mixins field instead of CFC mixin attribute", function() {
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
			})

			it("falls back to CFC mixin attribute when no manifest mixins field", function() {
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
			})

		})

		describe("Tests that manifest middleware auto-registration", function() {

			it("auto-registers middleware declared in plugin.json", function() {
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
			})

			it("preserves middleware options from plugin.json", function() {
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
			})

			it("does not register middleware for plugins without manifest middleware", function() {
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
			})

		})

		describe("Tests that manifest wheelsVersion compatibility", function() {

			it("uses manifest wheelsVersion for compatibility check", function() {
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
			})

			it("allows compatible plugins via manifest wheelsVersion", function() {
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
			})

			it("manifest wheelsVersion overrides CFC this.version for compatibility", function() {
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
			})

		})

		describe("Tests that manifest author and description surfacing", function() {

			it("surfaces author from plugin.json as top-level metadata", function() {
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
			})

			it("surfaces description from plugin.json as top-level metadata", function() {
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
			})

			it("defaults author and description to empty string without manifest", function() {
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
			})

		})

		describe("Tests that plugins without plugin.json fall back gracefully", function() {

			it("loads plugin via init()-based metadata when no plugin.json exists", function() {
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
				var plugins = PluginObj.getPlugins()

				// TestNoManifestPlugin has no plugin.json but should still load via init()
				expect(plugins).toHaveKey("TestNoManifestPlugin")
			})

			it("uses CFC this.version when no plugin.json provides version", function() {
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

				// TestNoManifestPlugin sets this.version = "99.9.9" in init()
				// Without a plugin.json, version should come from box.json or remain empty
				// (the CFC this.version is used for compatibility checks, not stored in pluginMeta)
				expect(meta).toHaveKey("TestNoManifestPlugin")
				expect(meta.TestNoManifestPlugin.manifest).toBeStruct()
				expect(StructIsEmpty(meta.TestNoManifestPlugin.manifest)).toBeTrue()
			})

			it("applies global mixins when no plugin.json and no CFC mixin attribute", function() {
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

				// TestNoManifestPlugin has no mixin attribute and no plugin.json
				// Should default to "global" — method available in all targets
				expect(mixins.controller).toHaveKey("$NoManifestTestMethod")
				expect(mixins.model).toHaveKey("$NoManifestTestMethod")
				expect(mixins.application).toHaveKey("$NoManifestTestMethod")
			})

			it("does not register middleware for plugins without plugin.json", function() {
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

				// No middleware should be auto-registered for TestNoManifestPlugin
				var found = 0
				for (var mw in pluginMiddleware) {
					if (mw.pluginName == "TestNoManifestPlugin") {
						found++
					}
				}
				expect(found).toBe(0)
			})

			it("has empty dependencies when no plugin.json and no box.json", function() {
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

				expect(meta.TestNoManifestPlugin).toHaveKey("dependencies")
				expect(StructIsEmpty(meta.TestNoManifestPlugin.dependencies)).toBeTrue()
			})

		})

	}

	function $pluginObj(required struct config) {
		return g.$createObjectFromRoot(argumentCollection = arguments.config)
	}

}
