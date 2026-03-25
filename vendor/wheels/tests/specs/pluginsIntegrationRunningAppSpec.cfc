component extends="wheels.WheelsTest" {

	/**
	 * Integration test: plugin system in a running app.
	 *
	 * Unlike the unit tests (pluginsSpec, pluginsModernSpec, etc.) which test
	 * individual Plugins.cfc features with separate fixture directories, this
	 * spec loads ALL plugin types simultaneously from a single mixed directory
	 * and verifies they coexist correctly — then tests that mixins are actually
	 * callable on real controller and model instances via the application scope.
	 *
	 * Plugin fixture: /wheels/tests/_assets/plugins/integration/ contains:
	 *   IntFullManifest  — full plugin.json (version, author, deps, mixins=controller)
	 *   IntLegacyPlugin  — no plugin.json (tests graceful fallback + deprecation)
	 *   IntDirDiscovery  — CFC name (NonMatchingCfc) differs from directory name
	 *   IntDepProvider   — dependency provider with box.json version 2.5.0
	 *   TestSymlinkPlugin — symlink to _symlink_targets/ (created at test time)
	 */
	function run() {

		g = application.wo

		describe("Integration: mixed plugin types loaded together", function() {

			beforeEach(function() {
				variables._appKey = g.$appKey()
				variables._origPluginComponentPath = application[variables._appKey].pluginComponentPath

				var pluginPath = "/wheels/tests/_assets/plugins/integration"
				application[variables._appKey].pluginComponentPath = pluginPath

				// Set up symlink for TestSymlinkPlugin
				var intDir = ExpandPath(pluginPath)
				var symlinkPath = intDir & "/TestSymlinkPlugin"
				$cleanupSymlink(symlinkPath)
				var symlinkTarget = ExpandPath("/wheels/tests/_assets/plugins/_symlink_targets/TestSymlinkPlugin")
				$createTestSymlink(symlinkTarget, symlinkPath)

				// Construct the Plugins object with all integration fixtures
				variables._PluginObj = g.$createObjectFromRoot(
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = pluginPath,
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsEnvironment = "testing",
					wheelsVersion = application[variables._appKey].version
				)
			})

			afterEach(function() {
				application[variables._appKey].pluginComponentPath = variables._origPluginComponentPath
				var intDir = ExpandPath("/wheels/tests/_assets/plugins/integration")
				$cleanupSymlink(intDir & "/TestSymlinkPlugin")
			})

			it("discovers all five plugin types from a single directory", function() {
				if (StructKeyExists(server, "boxlang")) return
				var plugins = variables._PluginObj.getPlugins()
				expect(plugins).toHaveKey("IntFullManifest")
				expect(plugins).toHaveKey("IntLegacyPlugin")
				expect(plugins).toHaveKey("IntDepProvider")
				expect(plugins).toHaveKey("TestSymlinkPlugin")
				expect(plugins).toHaveKey("NonMatchingCfc")
			})

			it("parses plugin.json manifest and populates metadata", function() {
				if (StructKeyExists(server, "boxlang")) return
				var meta = variables._PluginObj.getPluginMeta()
				expect(meta).toHaveKey("IntFullManifest")
				expect(meta.IntFullManifest.manifest.name).toBe("IntFullManifest")
				expect(meta.IntFullManifest.manifest.version).toBe("1.2.0")
				expect(meta.IntFullManifest.manifest.author).toBe("Integration Test Suite")
				expect(meta.IntFullManifest.manifest.description).toBe("Full manifest plugin for integration testing")
			})

			it("resolves semver dependencies across coexisting plugins", function() {
				if (StructKeyExists(server, "boxlang")) return
				expect(variables._PluginObj.getVersionMismatchPlugins()).toBe("")
			})

			it("falls back gracefully for plugins without plugin.json", function() {
				if (StructKeyExists(server, "boxlang")) return
				var meta = variables._PluginObj.getPluginMeta()
				expect(meta).toHaveKey("IntLegacyPlugin")
				expect(StructIsEmpty(meta.IntLegacyPlugin.manifest)).toBeTrue()
				expect(variables._PluginObj.getPlugins()).toHaveKey("IntLegacyPlugin")
			})

			it("discovers directory-based plugin where CFC name differs from folder", function() {
				if (StructKeyExists(server, "boxlang")) return
				expect(variables._PluginObj.getPlugins()).toHaveKey("NonMatchingCfc")
			})

			it("loads symlinked plugin directory", function() {
				if (StructKeyExists(server, "boxlang")) return
				var plugins = variables._PluginObj.getPlugins()
				expect(plugins).toHaveKey("TestSymlinkPlugin")
				expect(plugins.TestSymlinkPlugin).toHaveKey("$SymlinkedPluginTestMethod")
			})

			it("surfaces box.json metadata for dependency provider", function() {
				if (StructKeyExists(server, "boxlang")) return
				var meta = variables._PluginObj.getPluginMeta()
				expect(meta).toHaveKey("IntDepProvider")
				expect(meta.IntDepProvider.version).toBe("2.5.0")
			})

			it("populates dependency constraints from plugin.json", function() {
				if (StructKeyExists(server, "boxlang")) return
				var meta = variables._PluginObj.getPluginMeta()
				expect(meta.IntFullManifest).toHaveKey("dependencies")
				expect(IsStruct(meta.IntFullManifest.dependencies)).toBeTrue()
				expect(meta.IntFullManifest.dependencies).toHaveKey("IntDepProvider")
			})

			it("reports no mixin collisions among diverse plugin types", function() {
				if (StructKeyExists(server, "boxlang")) return
				var collisions = variables._PluginObj.getMixinCollisions()
				expect(collisions).toBeArray()
				expect(ArrayLen(collisions)).toBe(0)
			})

		})

		describe("Integration: mixin injection into real app objects", function() {

			it("injects controller-scoped mixins from manifest plugin into real controllers", function() {
				if (StructKeyExists(server, "boxlang")) return
				var appKey = g.$appKey()
				var origMixins = Duplicate(application[appKey].mixins)
				var origPCP = application[appKey].pluginComponentPath
				var pluginPath = "/wheels/tests/_assets/plugins/integration"
				try {
					application[appKey].pluginComponentPath = pluginPath
					var PluginObj = g.$createObjectFromRoot(
						path = "wheels", fileName = "Plugins", method = "$init",
						pluginPath = pluginPath, deletePluginDirectories = false,
						overwritePlugins = false, loadIncompatiblePlugins = true
					)
					application[appKey].mixins = PluginObj.getMixins()
					var _params = {controller = "test", action = "index"}
					var c = g.controller("test", _params)
					expect(c).toHaveKey("$IntFullManifestMethod")
					expect(c.$IntFullManifestMethod()).toBe("full-manifest-works")
					expect(c).toHaveKey("$IntLegacyMethod")
					expect(c.$IntLegacyMethod()).toBe("legacy-plugin-works")
				} finally {
					application[appKey].mixins = origMixins
					application[appKey].pluginComponentPath = origPCP
				}
			})

			it("injects global mixins into real model instances but not controller-scoped", function() {
				if (StructKeyExists(server, "boxlang")) return
				var appKey = g.$appKey()
				var origMixins = Duplicate(application[appKey].mixins)
				var origPCP = application[appKey].pluginComponentPath
				var pluginPath = "/wheels/tests/_assets/plugins/integration"
				try {
					application[appKey].pluginComponentPath = pluginPath
					var PluginObj = g.$createObjectFromRoot(
						path = "wheels", fileName = "Plugins", method = "$init",
						pluginPath = pluginPath, deletePluginDirectories = false,
						overwritePlugins = false, loadIncompatiblePlugins = true
					)
					application[appKey].mixins = PluginObj.getMixins()
					var m = g.model("c_o_r_e_authors").new()
					expect(m).toHaveKey("$IntLegacyMethod")
					expect(m).notToHaveKey("$IntFullManifestMethod")
				} finally {
					application[appKey].mixins = origMixins
					application[appKey].pluginComponentPath = origPCP
				}
			})

		})

		describe("Integration: deprecation warnings with mixed plugin types", function() {

			it("warns about legacy plugins in development mode", function() {
				if (StructKeyExists(server, "boxlang")) return
				var appKey = g.$appKey()
				var origPCP = application[appKey].pluginComponentPath
				var pluginPath = "/wheels/tests/_assets/plugins/integration"
				try {
					application[appKey].pluginComponentPath = pluginPath
					var PluginObj = g.$createObjectFromRoot(
						path = "wheels", fileName = "Plugins", method = "$init",
						pluginPath = pluginPath, deletePluginDirectories = false,
						overwritePlugins = false, loadIncompatiblePlugins = true,
						wheelsEnvironment = "development"
					)
					var warnings = PluginObj.getDeprecationWarnings()
					expect(warnings).toBeArray()
					var foundLegacy = false
					for (var w in warnings) {
						if (w.plugin == "IntLegacyPlugin") {
							foundLegacy = true
							expect(w.message).toInclude("legacy mixin injection")
						}
					}
					expect(foundLegacy).toBeTrue()
					for (var w in warnings) {
						expect(w.plugin).notToBe("IntFullManifest")
					}
				} finally {
					application[appKey].pluginComponentPath = origPCP
				}
			})

			it("does not warn in production mode", function() {
				if (StructKeyExists(server, "boxlang")) return
				var appKey = g.$appKey()
				var origPCP = application[appKey].pluginComponentPath
				var pluginPath = "/wheels/tests/_assets/plugins/integration"
				try {
					application[appKey].pluginComponentPath = pluginPath
					var PluginObj = g.$createObjectFromRoot(
						path = "wheels", fileName = "Plugins", method = "$init",
						pluginPath = pluginPath, deletePluginDirectories = false,
						overwritePlugins = false, loadIncompatiblePlugins = true,
						wheelsEnvironment = "production"
					)
					var warnings = PluginObj.getDeprecationWarnings()
					for (var w in warnings) {
						expect(w.plugin).notToBe("IntLegacyPlugin")
					}
				} finally {
					application[appKey].pluginComponentPath = origPCP
				}
			})

		})

	}

	private void function $createTestSymlink(required string target, required string link) {
		$cleanupSymlink(arguments.link)
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
