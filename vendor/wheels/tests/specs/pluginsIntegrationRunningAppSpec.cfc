component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Integration: plugin system in a running app", function() {

			beforeEach(function() {
				// Snapshot all application-scope values that $loadPlugins reads/writes
				var appKey = g.$appKey()
				variables._saved = {
					appKey = appKey,
					webPath = application[appKey].webPath,
					pluginPath = application[appKey].pluginPath,
					pluginComponentPath = application[appKey].pluginComponentPath,
					PluginObj = application[appKey].PluginObj,
					plugins = Duplicate(application[appKey].plugins),
					pluginMeta = Duplicate(application[appKey].pluginMeta),
					incompatiblePlugins = application[appKey].incompatiblePlugins,
					dependantPlugins = application[appKey].dependantPlugins,
					versionMismatchPlugins = application[appKey].versionMismatchPlugins,
					mixinCollisions = Duplicate(application[appKey].mixinCollisions),
					mixins = Duplicate(application[appKey].mixins),
					pluginMiddleware = Duplicate(application[appKey].pluginMiddleware),
					environment = application[appKey].environment,
					deletePluginDirectories = application[appKey].deletePluginDirectories,
					overwritePlugins = application[appKey].overwritePlugins,
					loadIncompatiblePlugins = application[appKey].loadIncompatiblePlugins
				}

				// Clean up any stale symlink from a prior run
				var intDir = ExpandPath("/wheels/tests/_assets/plugins/integration")
				var symlinkPath = intDir & "/TestSymlinkPlugin"
				$cleanupSymlink(symlinkPath)

				// Create symlink for symlinked-plugin test
				var symlinkTarget = ExpandPath("/wheels/tests/_assets/plugins/_symlink_targets/TestSymlinkPlugin")
				$createTestSymlink(symlinkTarget, symlinkPath)
			})

			afterEach(function() {
				// Restore all saved application-scope values
				var appKey = variables._saved.appKey
				application[appKey].webPath = variables._saved.webPath
				application[appKey].pluginPath = variables._saved.pluginPath
				application[appKey].pluginComponentPath = variables._saved.pluginComponentPath
				application[appKey].PluginObj = variables._saved.PluginObj
				application[appKey].plugins = variables._saved.plugins
				application[appKey].pluginMeta = variables._saved.pluginMeta
				application[appKey].incompatiblePlugins = variables._saved.incompatiblePlugins
				application[appKey].dependantPlugins = variables._saved.dependantPlugins
				application[appKey].versionMismatchPlugins = variables._saved.versionMismatchPlugins
				application[appKey].mixinCollisions = variables._saved.mixinCollisions
				application[appKey].mixins = variables._saved.mixins
				application[appKey].pluginMiddleware = variables._saved.pluginMiddleware
				application[appKey].environment = variables._saved.environment
				application[appKey].deletePluginDirectories = variables._saved.deletePluginDirectories
				application[appKey].overwritePlugins = variables._saved.overwritePlugins
				application[appKey].loadIncompatiblePlugins = variables._saved.loadIncompatiblePlugins

				// Remove the symlink
				var intDir = ExpandPath("/wheels/tests/_assets/plugins/integration")
				$cleanupSymlink(intDir & "/TestSymlinkPlugin")
			})

			it("loads all plugin types via $loadPlugins pipeline", function() {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return

				$configureIntegrationPlugins()
				g.$loadPlugins()

				var appKey = variables._saved.appKey
				var plugins = application[appKey].plugins

				// All five plugins should be discovered
				expect(plugins).toHaveKey("IntFullManifest")
				expect(plugins).toHaveKey("IntLegacyPlugin")
				expect(plugins).toHaveKey("IntDepProvider")
				expect(plugins).toHaveKey("TestSymlinkPlugin")
				// Directory-based discovery: CFC name is NonMatchingCfc, not IntDirDiscovery
				expect(plugins).toHaveKey("NonMatchingCfc")
			})

			it("populates pluginMeta from plugin.json manifest via $loadPlugins", function() {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return

				$configureIntegrationPlugins()
				g.$loadPlugins()

				var appKey = variables._saved.appKey
				var meta = application[appKey].pluginMeta

				expect(meta).toHaveKey("IntFullManifest")
				expect(meta.IntFullManifest).toHaveKey("manifest")
				expect(meta.IntFullManifest.manifest.name).toBe("IntFullManifest")
				expect(meta.IntFullManifest.manifest.version).toBe("1.2.0")
				expect(meta.IntFullManifest.manifest.author).toBe("Integration Test Suite")
				expect(meta.IntFullManifest.manifest.description).toBe("Full manifest plugin for integration testing")
			})

			it("resolves semver dependencies through the full $loadPlugins pipeline", function() {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return

				$configureIntegrationPlugins()
				g.$loadPlugins()

				var appKey = variables._saved.appKey

				// IntFullManifest requires IntDepProvider >=2.0.0 <4.0.0
				// IntDepProvider declares version 2.5.0 via box.json — should satisfy
				expect(application[appKey].versionMismatchPlugins).toBe("")
			})

			it("falls back gracefully for plugins without plugin.json", function() {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return

				$configureIntegrationPlugins()
				g.$loadPlugins()

				var appKey = variables._saved.appKey
				var meta = application[appKey].pluginMeta

				// IntLegacyPlugin has no plugin.json — manifest should be empty struct
				expect(meta).toHaveKey("IntLegacyPlugin")
				expect(meta.IntLegacyPlugin).toHaveKey("manifest")
				expect(StructIsEmpty(meta.IntLegacyPlugin.manifest)).toBeTrue()

				// But the plugin itself should still be loaded and functional
				expect(application[appKey].plugins).toHaveKey("IntLegacyPlugin")
			})

			it("discovers directory-based plugins via $loadPlugins", function() {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return

				$configureIntegrationPlugins()
				g.$loadPlugins()

				var appKey = variables._saved.appKey

				// IntDirDiscovery directory contains NonMatchingCfc.cfc — should be discovered
				expect(application[appKey].plugins).toHaveKey("NonMatchingCfc")
			})

			it("loads symlinked plugins via $loadPlugins", function() {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return

				$configureIntegrationPlugins()
				g.$loadPlugins()

				var appKey = variables._saved.appKey
				expect(application[appKey].plugins).toHaveKey("TestSymlinkPlugin")
			})

			it("injects manifest-controlled mixins into controllers after $loadPlugins", function() {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return

				$configureIntegrationPlugins()
				g.$loadPlugins()

				var appKey = variables._saved.appKey

				// IntFullManifest declares mixins="controller" in plugin.json
				// (overrides the CFC mixin="global" attribute)
				var _params = {controller = "test", action = "index"}
				var c = g.controller("test", _params)
				expect(c).toHaveKey("$IntFullManifestMethod")

				// Legacy plugin has no mixin attribute — defaults to global (all targets)
				expect(c).toHaveKey("$IntLegacyMethod")
			})

			it("injects global mixins into models after $loadPlugins", function() {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return

				$configureIntegrationPlugins()
				g.$loadPlugins()

				// IntLegacyPlugin has no mixin attribute → global (injected everywhere)
				var m = g.model("c_o_r_e_authors").new()
				expect(m).toHaveKey("$IntLegacyMethod")

				// IntFullManifest specifies mixins="controller" → NOT on models
				expect(m).notToHaveKey("$IntFullManifestMethod")
			})

			it("emits deprecation warnings for legacy plugins in development mode", function() {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return

				var appKey = variables._saved.appKey
				application[appKey].environment = "development"

				$configureIntegrationPlugins()
				g.$loadPlugins()

				var warnings = application[appKey].PluginObj.getDeprecationWarnings()
				expect(warnings).toBeArray()

				// IntLegacyPlugin has no plugin.json and is not a ServiceProvider
				var foundLegacy = false
				for (var w in warnings) {
					if (w.plugin == "IntLegacyPlugin") {
						foundLegacy = true
						expect(w.message).toInclude("legacy mixin injection")
					}
				}
				expect(foundLegacy).toBeTrue()

				// IntFullManifest HAS plugin.json — should NOT trigger deprecation
				for (var w in warnings) {
					expect(w.plugin).notToBe("IntFullManifest")
				}
			})

			it("does not emit deprecation warnings in production mode", function() {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return

				var appKey = variables._saved.appKey
				application[appKey].environment = "production"

				$configureIntegrationPlugins()
				g.$loadPlugins()

				var warnings = application[appKey].PluginObj.getDeprecationWarnings()
				expect(warnings).toBeArray()

				var foundLegacy = false
				for (var w in warnings) {
					if (w.plugin == "IntLegacyPlugin") foundLegacy = true
				}
				expect(foundLegacy).toBeFalse()
			})

			it("reports no mixin collisions for the integration plugins", function() {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return

				$configureIntegrationPlugins()
				g.$loadPlugins()

				var appKey = variables._saved.appKey
				expect(application[appKey].mixinCollisions).toBeArray()
				expect(ArrayLen(application[appKey].mixinCollisions)).toBe(0)
			})

			it("surfaces metadata for dependency provider via box.json", function() {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return

				$configureIntegrationPlugins()
				g.$loadPlugins()

				var appKey = variables._saved.appKey
				var meta = application[appKey].pluginMeta

				expect(meta).toHaveKey("IntDepProvider")
				expect(meta.IntDepProvider.version).toBe("2.5.0")
			})

		})

	}

	/**
	 * Configure the application to load plugins from the integration fixture directory.
	 */
	private void function $configureIntegrationPlugins() {
		var appKey = variables._saved.appKey
		// $loadPlugins computes: webPath & pluginPath
		// Set webPath="" so pluginPath is the full CFML mapping path
		application[appKey].webPath = ""
		application[appKey].pluginPath = "/wheels/tests/_assets/plugins/integration"
		application[appKey].pluginComponentPath = "/wheels/tests/_assets/plugins/integration"
		application[appKey].deletePluginDirectories = false
		application[appKey].overwritePlugins = false
		application[appKey].loadIncompatiblePlugins = true
	}

	private void function $createTestSymlink(required string target, required string link) {
		var pb = CreateObject("java", "java.lang.ProcessBuilder")
			.init(["ln", "-s", arguments.target, arguments.link])
		var proc = pb.start()
		proc.waitFor()
	}

	private void function $cleanupSymlink(required string link) {
		var jFiles = CreateObject("java", "java.nio.file.Files")
		var linkPath = CreateObject("java", "java.io.File").init(arguments.link).toPath()
		if (jFiles.isSymbolicLink(linkPath)) {
			jFiles.delete(linkPath)
		}
	}

}
