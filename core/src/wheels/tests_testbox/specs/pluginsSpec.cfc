component extends="wheels.Testbox" {

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
					pluginPath = "/wheels/tests_testbox/_assets/plugins/standard",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}

				config.pluginPath = "/wheels/tests_testbox/_assets/plugins/dependant"
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests_testbox/_assets/plugins/dependant"
				
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
					pluginPath = "/wheels/tests_testbox/_assets/plugins/standard",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests_testbox/_assets/plugins/standard"
				
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
					pluginPath = "/wheels/tests_testbox/_assets/plugins/overwriting",
					deletePluginDirectories = false,
					overwritePlugins = true,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests_testbox/_assets/plugins/overwriting"
				
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

			it("removes unused plugin directories", () => {
				// Store original values
				originalPluginComponentPath = application.wheels.pluginComponentPath
				
				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests_testbox/_assets/plugins/removing",
					deletePluginDirectories = true,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests_testbox/_assets/plugins/removing"
				
				dir = ExpandPath(config.pluginPath)
				badDir = dir & "/testing"
				goodDir = dir & "/testglobalmixins"

				$deleteDirs()
				$createDir()

				expect(DirectoryExists(badDir)).toBeTrue()
				PluginObj = $pluginObj(config)
				expect(DirectoryExists(goodDir)).toBeTrue()
				expect(DirectoryExists(badDir)).notToBeTrue()

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
					pluginPath = "/wheels/tests_testbox/_assets/plugins/runner",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests_testbox/_assets/plugins/runner"
				
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
					pluginPath = "/wheels/tests_testbox/_assets/plugins/standard",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests_testbox/_assets/plugins/standard"
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
					pluginPath = "/wheels/tests_testbox/_assets/plugins/unpacking",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				// Set pluginComponentPath to match the test plugin path
				application.wheels.pluginComponentPath = "/wheels/tests_testbox/_assets/plugins/unpacking"

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
	}

	function $pluginObj(required struct config) {
		return g.$createObjectFromRoot(argumentCollection = arguments.config)
	}

	function $writeTestFile() {
		FileWrite($testFile(), "overwritten")
	}

	function $readTestFile() {
		return FileRead($testFile())
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
		var q = DirectoryList(ExpandPath('/wheels/tests_testbox/_assets/plugins/unpacking'), false, "query")
		for (row in q) {
			dir = ListChangeDelims(ListAppend(row.directory, row.name, "/"), "/", "\")
			if (StructKeyExists(server, "boxlang") && !dir.startsWith("/")) {
				dir = "/" & dir;
			}
			if (DirectoryExists(dir)) {
				DirectoryDelete(dir, true)
			}
		}
	}
}
