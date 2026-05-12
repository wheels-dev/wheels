component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that dependant", () => {

			it("works", () => {
				// Store original values
				originalPluginComponentPath = application.wheels.pluginComponentPath
				
				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/standard",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}

				config.pluginPath = "/wheels/tests/_assets/plugins/dependant"
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/dependant"
				
				PluginObj = $pluginObj(config)
				iplugins = PluginObj.getDependantPlugins()

				expect(iplugins).toBe("TestPlugin1|TestPlugin2,TestPlugin1|TestPlugin3")
				
				// Restore original value
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})
		})

		describe("Tests that injection", () => {

			beforeEach(() => {
				// Store original values
				originalPluginComponentPath = application.wheels.pluginComponentPath
				originalMixins = Duplicate(application.wheels.mixins)
				
				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/standard",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/standard"
				
				PluginObj = $pluginObj(config)
				application.wheels.mixins = PluginObj.getMixins()
				m = g.model("c_o_r_e_authors").new()
				_params = {controller = "test", action = "index"}
				c = g.controller("test", _params)
				d = g.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init")
				t = g.$createObjectFromRoot(path = "wheels", fileName = "Test", method = "init")
			})

			afterEach(() => {
				// Restore original values
				application.wheels.mixins = originalMixins
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("works for Global method", () => {
				expect(m).toHaveKey("$GlobalTestMixin")
				expect(c).toHaveKey("$GlobalTestMixin")
				expect(d).toHaveKey("$GlobalTestMixin")
				expect(t).toHaveKey("$GlobalTestMixin")
			})

			it("works for Component specific", () => {
				expect(m).toHaveKey("$MixinForModels")
				expect(m).toHaveKey("$MixinForModelsAndContollers")
				expect(c).toHaveKey("$MixinForControllers")
				expect(c).toHaveKey("$MixinForModelsAndContollers")
				expect(d).toHaveKey("$MixinForDispatch")
			})
		})

		describe("Tests that overwriting", () => {

			beforeEach(() => {
				// Store original values
				originalPluginComponentPath = application.wheels.pluginComponentPath
				
				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/overwriting",
					deletePluginDirectories = false,
					overwritePlugins = true,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/overwriting"
				
				$writeTestFile()
			})
			
			afterEach(() => {
				// Restore original value
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("overwrites plugins", () => {
				fileContentBefore = $readTestFile()
				PluginObj = $pluginObj(config)
				fileContentAfter = $readTestFile()

				expect(fileContentBefore).toBe("overwritten")
				expect(fileContentAfter).notToBe("overwritten")
			})

			it("does not overwrite plugins", () => {
				config.overwritePlugins = false
				fileContentBefore = $readTestFile()
				PluginObj = $pluginObj(config)
				fileContentAfter = $readTestFile()

				expect(fileContentBefore).toBe("overwritten")
				expect(fileContentAfter).toBe("overwritten")
			})
		})

		describe("Tests that removing", () => {

			it("preserves directories without a matching zip file", () => {
				// Store original values
				originalPluginComponentPath = application.wheels.pluginComponentPath

				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/removing",
					deletePluginDirectories = true,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/removing"

				dir = ExpandPath(config.pluginPath)
				badDir = dir & "/testing"
				goodDir = dir & "/testglobalmixins"

				$deleteDirs()
				$createDir()

				expect(DirectoryExists(badDir)).toBeTrue()
				PluginObj = $pluginObj(config)
				expect(DirectoryExists(goodDir)).toBeTrue()
				// Directory without a matching zip should be preserved (GH#1978)
				// — it may be a git-cloned or symlinked plugin
				expect(DirectoryExists(badDir)).toBeTrue()

				$deleteDirs()

				// Restore original value
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})
		})

		describe("Tests that runner", () => {

			beforeEach(() => {
				// Store original values
				originalPluginComponentPath = application.wheels.pluginComponentPath
				previousMixins = Duplicate(application.wheels.mixins)
				
				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/runner",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/runner"
				
				_params = {controller = "test", action = "index"}
				PluginObj = $pluginObj(config)
				application.wheels.mixins = PluginObj.getMixins()

				c = g.controller("test", _params)
				m = g.model("c_o_r_e_authors").new()
				d = g.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init")
			})

			afterEach(() => {
				// Restore original values
				application.wheels.mixins = previousMixins
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("calls plugin methods from other methods", () => {
				result = c.$helper01()

				expect(result).toBe("$helper011Responding")
			})

			it("calls plugin methods via $invoke", () => {
				result = c.$invoke(method = "$helper01", invokeArgs = {})

				expect(result).toBe("$helper011Responding")
			})

			it("calls plugin methods via $simplelock", () => {
				result = c.$simpleLock(
					name = "$simpleLockHelper01",
					type = "exclusive",
					execute = "$helper01",
					executeArgs = {},
					timeout = 5
				)

				expect(result).toBe("$helper011Responding")
			})

			it("calls plugin methods via $doublecheckedlock", () => {
				result = c.$doubleCheckedLock(
					name = "$doubleCheckedLockHelper01",
					condition = "$helper01ConditionalCheck",
					conditionArgs = {},
					type = "exclusive",
					execute = "$helper01",
					executeArgs = {},
					timeout = 5
				)

				expect(result).toBe("$helper011Responding")
			})

			it("calls core method changing calling function name", () => {
				result = c.pluralize("book")

				expect(result).toBe("books")
			})

			it("overrides a framework method", () => {
				result = c.singularize(word = "hahahah")

				expect(result).toBe("$$completelyOverridden")
			})

			it("is running plugin only method", () => {
				result = c.$$pluginOnlyMethod()

				expect(result).toBe("$$returnValue")
			})

			it("call overwridden method with identical method nesting", () => {
				request.wheels.includePartialStack = []
				result = c.includePartial(partial = "testpartial")

				expect(trim(result)).toBe("<p>some content</p>")
			})
		})

		describe("Tests that standard", () => {

			beforeEach(() => {
				// Store original values
				originalPluginComponentPath = application.wheels.pluginComponentPath
				
				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/standard",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/standard"
			})
			
			afterEach(() => {
				// Restore original value
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("loads all plugins", () => {
				PluginObj = $pluginObj(config)
				plugins = PluginObj.getPlugins()

				expect(plugins).notToBeEmpty()
				expect(plugins).toHaveKey("TestAssignMixins")
			})

			it("notifies incompatible version", () => {
				config.wheelsVersion = "99.9.9"
				PluginObj = $pluginObj(config)
				iplugins = PluginObj.getIncompatiblePlugins()

				expect(iplugins).toBe("TestIncompatableVersion")
			})

			it("is not loading incompatible version", () => {
				config.loadIncompatiblePlugins = false
				config.wheelsVersion = "99.9.9"
				PluginObj = $pluginObj(config)
				plugins = PluginObj.getPlugins()

				expect(plugins).notToBeEmpty()
				expect(plugins).toHaveKey("TestAssignMixins")
				expect(plugins).notToHaveKey("TestIncompatablePlugin")
			})
		})

		describe("Tests that unpacking", () => {

			it("is unpacking plugins", () => {
				// Store original values
				originalPluginComponentPath = application.wheels.pluginComponentPath

				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/unpacking",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/unpacking"

				$deleteTestFolders()

				pluginObj = $pluginObj(config)
				q = DirectoryList(ExpandPath(config.pluginPath), false, "query")
				dirs = ValueList(q.name)

				expect(ListFind(dirs, "testdefaultassignmixins")).toBeTrue()
				expect(ListFind(dirs, "testglobalmixins")).toBeTrue()

				$deleteTestFolders()

				// Restore original value
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})
		})

		describe("Tests that directory-based plugin discovery", () => {

			beforeEach(() => {
				// Store original values
				originalPluginComponentPath = application.wheels.pluginComponentPath
				originalMixins = Duplicate(application.wheels.mixins)

				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/directory",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/directory"
			})

			afterEach(() => {
				// Restore original values
				application.wheels.mixins = originalMixins
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("discovers a directory plugin whose CFC name differs from folder name", () => {
				PluginObj = $pluginObj(config)
				plugins = PluginObj.getPlugins()

				expect(plugins).toHaveKey("DirPlugin")
			})

			it("discovers a conventional directory plugin alongside a non-matching one", () => {
				PluginObj = $pluginObj(config)
				plugins = PluginObj.getPlugins()

				expect(plugins).toHaveKey("ConventionalPlugin")
				expect(plugins).toHaveKey("DirPlugin")
			})

			it("injects mixins from directory-based plugins", () => {
				PluginObj = $pluginObj(config)
				application.wheels.mixins = PluginObj.getMixins()
				_params = {controller = "test", action = "index"}
				c = g.controller("test", _params)

				expect(c).toHaveKey("$DirPluginMixin")
				expect(c).toHaveKey("$ConventionalPluginMixin")
			})
		})

		describe("Tests that symlinked plugin directories", () => {

			it("discovers a symlinked plugin via absolute symlink", () => {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return;
				originalPluginComponentPath = application.wheels.pluginComponentPath

				symlinkDir = ExpandPath("/wheels/tests/_assets/plugins/symlinked")
				symlinkTargetDir = ExpandPath("/wheels/tests/_assets/plugins/_symlink_targets/TestSymlinkPlugin")
				symlinkLinkPath = symlinkDir & "/TestSymlinkPlugin"

				// Absolute symlink: TestSymlinkPlugin -> /abs/path/to/_symlink_targets/TestSymlinkPlugin
				$createSymlink(symlinkTargetDir, symlinkLinkPath)

				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/symlinked",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/symlinked"

				PluginObj = $pluginObj(config)
				plugins = PluginObj.getPlugins()

				// The symlinked directory should be discovered and loaded
				expect(plugins).toHaveKey("TestSymlinkPlugin")
				// Verify the plugin's method is callable
				expect(plugins.TestSymlinkPlugin).toHaveKey("$SymlinkedPluginTestMethod")

				$deleteSymlink(symlinkLinkPath)
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("discovers a symlinked plugin via relative symlink", () => {
				// BoxLang cannot resolve component paths through symlinks
				if (StructKeyExists(server, "boxlang")) return;
				originalPluginComponentPath = application.wheels.pluginComponentPath

				symlinkDir = ExpandPath("/wheels/tests/_assets/plugins/symlinked")
				symlinkLinkPath = symlinkDir & "/TestSymlinkPlugin"

				// Relative symlink: TestSymlinkPlugin -> ../_symlink_targets/TestSymlinkPlugin
				$createSymlink("../_symlink_targets/TestSymlinkPlugin", symlinkLinkPath)

				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/symlinked",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/symlinked"

				PluginObj = $pluginObj(config)
				plugins = PluginObj.getPlugins()

				expect(plugins).toHaveKey("TestSymlinkPlugin")
				expect(plugins.TestSymlinkPlugin).toHaveKey("$SymlinkedPluginTestMethod")

				$deleteSymlink(symlinkLinkPath)
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("preserves symlinked directories during plugin delete", () => {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				symlinkDir = ExpandPath("/wheels/tests/_assets/plugins/symlinked")
				symlinkTargetDir = ExpandPath("/wheels/tests/_assets/plugins/_symlink_targets/TestSymlinkPlugin")
				symlinkLinkPath = symlinkDir & "/TestSymlinkPlugin"

				$createSymlink(symlinkTargetDir, symlinkLinkPath)

				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/symlinked",
					deletePluginDirectories = true,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/symlinked"

				PluginObj = $pluginObj(config)

				// Symlink should still exist after $pluginDelete runs
				expect($symlinkExists(symlinkLinkPath)).toBeTrue()
				// Target directory should also be intact
				expect(DirectoryExists(symlinkTargetDir)).toBeTrue()

				$deleteSymlink(symlinkLinkPath)
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("does not extract zip into a symlinked directory", () => {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				// The unpacking fixture has TestGlobalMixins-0.0.2.zip which
				// extracts to a folder named "testglobalmixins". Create a symlink
				// with that name so it looks like the folder already exists.
				unpackDir = ExpandPath("/wheels/tests/_assets/plugins/unpacking")
				symlinkTargetDir = ExpandPath("/wheels/tests/_assets/plugins/_symlink_targets/TestSymlinkPlugin")
				symlinkLinkPath = unpackDir & "/testglobalmixins"

				$deleteTestFolders()
				$createSymlink(symlinkTargetDir, symlinkLinkPath)

				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/unpacking",
					deletePluginDirectories = false,
					overwritePlugins = true,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/unpacking"

				// $pluginObj runs the full init pipeline including $pluginsProcess()
				// which may fail to load the symlinked "plugin". That's expected —
				// we only care that $pluginsExtract() didn't unzip into the symlink.
				try { $pluginObj(config) } catch (any e) {}

				// The symlink should still be a symlink (not replaced by zip extraction)
				expect($isSymlinkCheck(symlinkLinkPath)).toBeTrue()
				// The target should not contain extracted zip artifacts (index.cfm)
				expect(FileExists(symlinkTargetDir & "/index.cfm")).toBeFalse()

				$deleteSymlink(symlinkLinkPath)
				$deleteTestFolders()
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})
		})
	}

	function $pluginObj(required struct config) {
		return g.$createObjectFromRoot(argumentCollection = arguments.config)
	}

	function $writeTestFile() {
		FileWrite($testFile(), "overwritten")
	}

	function $readTestFile() {
		return trim(FileRead($testFile()))
	}

	function $testFile() {
		var theFile = ""
		theFile = [config.pluginPath, "testglobalmixins", "index.cfm"]
		theFile = ExpandPath(ArrayToList(theFile, "/"))
		return theFile
	}

	function $createDir() {
		DirectoryCreate(badDir)
	}

	function $deleteDirs() {
		if (DirectoryExists(badDir)) {
			DirectoryDelete(badDir, true)
		}
		if (DirectoryExists(goodDir)) {
			DirectoryDelete(goodDir, true)
		}
	}

	function $deleteTestFolders() {
		var q = DirectoryList(ExpandPath('/wheels/tests/_assets/plugins/unpacking'), false, "query")
		var jFiles = CreateObject("java", "java.nio.file.Files")
		for (row in q) {
			dir = ListChangeDelims(ListAppend(row.directory, row.name, "/"), "/", "\")
			if (StructKeyExists(server, "boxlang") && !dir.startsWith("/")) {
				dir = "/" & dir;
			}
			// Remove symlinks via NIO (DirectoryDelete follows symlinks)
			if (jFiles.isSymbolicLink($toPath(dir))) {
				jFiles.delete($toPath(dir))
				continue;
			}
			if (DirectoryExists(dir)) {
				DirectoryDelete(dir, true)
			}
		}
	}

	function $toPath(required string filePath) {
		return CreateObject("java", "java.io.File").init(arguments.filePath).toPath()
	}

	function $createSymlink(required string target, required string link) {
		// Clean up stale symlink from a prior failed test run
		$deleteSymlink(arguments.link)
		// Use Java ProcessBuilder to create symlink (avoids varargs issues with
		// Files.createSymbolicLink on CFML). ProcessBuilder takes a List, not
		// varargs, so CFML resolves it correctly.
		var pb = CreateObject("java", "java.lang.ProcessBuilder")
			.init(["ln", "-s", arguments.target, arguments.link])
		var proc = pb.start()
		proc.waitFor()
		if (proc.exitValue() != 0) {
			throw(type="Wheels.Test.SymlinkError", message="Failed to create symlink: #arguments.link# -> #arguments.target#")
		}
	}

	function $deleteSymlink(required string link) {
		var jFiles = CreateObject("java", "java.nio.file.Files")
		var linkPath = $toPath(arguments.link)
		if (jFiles.isSymbolicLink(linkPath)) {
			jFiles.delete(linkPath)
		}
	}

	function $symlinkExists(required string link) {
		// Can't use Files.exists() (varargs). Use File.exists() instead.
		return CreateObject("java", "java.io.File").init(arguments.link).exists()
	}

	function $isSymlinkCheck(required string path) {
		var jFiles = CreateObject("java", "java.nio.file.Files")
		return jFiles.isSymbolicLink($toPath(arguments.path))
	}
}
