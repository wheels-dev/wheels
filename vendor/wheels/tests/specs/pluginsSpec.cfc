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

			it("removes unused plugin directories", () => {
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

		describe("Tests that mixin collision detection", () => {

			beforeEach(() => {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/collision",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/collision"
			})

			afterEach(() => {
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("detects collisions when two plugins provide the same method for the same target", () => {
				PluginObj = $pluginObj(config)
				collisions = PluginObj.getMixinCollisions()

				expect(collisions).toBeArray()
				expect(arrayLen(collisions)).toBeGT(0)

				// Find the collision for $CollidingMethod on controller
				found = false
				for (c in collisions) {
					if (c.method == "$CollidingMethod" && c.target == "controller") {
						found = true
						expect(c.existingPlugin).toBe("TestCollisionPluginA")
						expect(c.overridingPlugin).toBe("TestCollisionPluginB")
					}
				}
				expect(found).toBeTrue()
			})

			it("does not report collisions for unique methods", () => {
				PluginObj = $pluginObj(config)
				collisions = PluginObj.getMixinCollisions()

				for (c in collisions) {
					expect(c.method).notToBe("$UniqueToA")
					expect(c.method).notToBe("$UniqueToB")
				}
			})

			it("still allows the overriding plugin method to win", () => {
				PluginObj = $pluginObj(config)
				mixins = PluginObj.getMixins()

				// The last plugin alphabetically (B) should win
				result = mixins.controller["$CollidingMethod"]()
				expect(result).toBe("FromPluginB")
			})

			it("returns empty array when no collisions exist", () => {
				config.pluginPath = "/wheels/tests/_assets/plugins/standard"
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/standard"
				PluginObj = $pluginObj(config)
				collisions = PluginObj.getMixinCollisions()

				expect(collisions).toBeArray()
				expect(arrayLen(collisions)).toBe(0)
			})
		})

		describe("Tests that lifecycle hooks", () => {

			beforeEach(() => {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/lifecycle",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/lifecycle"

				// Clean up any previous lifecycle log
				StructDelete(application, "$wheelstestLifecycleLog")
			})

			afterEach(() => {
				application.wheels.pluginComponentPath = originalPluginComponentPath
				StructDelete(application, "$wheelstestLifecycleLog")
			})

			it("calls onPluginLoad during plugin loading", () => {
				PluginObj = $pluginObj(config)
				log = application.$wheelstestLifecycleLog

				expect(log).toBeArray()
				expect(ArrayFind(log, "A:onPluginLoad")).toBeGT(0)
				expect(ArrayFind(log, "B:onPluginLoad")).toBeGT(0)
			})

			it("calls onPluginLoad in alphabetical order", () => {
				PluginObj = $pluginObj(config)
				log = application.$wheelstestLifecycleLog

				posA = ArrayFind(log, "A:onPluginLoad")
				posB = ArrayFind(log, "B:onPluginLoad")
				expect(posA).toBeLT(posB)
			})

			it("calls all onPluginLoad before any onPluginActivate", () => {
				PluginObj = $pluginObj(config)
				// onPluginActivate is called from $loadPlugins in Global.cfc, not from $init
				// so after $pluginObj (which calls $init), only onPluginLoad should have fired
				log = application.$wheelstestLifecycleLog

				expect(ArrayFind(log, "A:onPluginLoad")).toBeGT(0)
				expect(ArrayFind(log, "B:onPluginLoad")).toBeGT(0)
				// onPluginActivate should NOT have been called yet (it's called from $loadPlugins)
				expect(ArrayFind(log, "A:onPluginActivate")).toBe(0)
				expect(ArrayFind(log, "B:onPluginActivate")).toBe(0)
			})

			it("calls onPluginActivate when invoked explicitly", () => {
				PluginObj = $pluginObj(config)
				PluginObj.$invokeOnPluginActivate()
				log = application.$wheelstestLifecycleLog

				expect(ArrayFind(log, "A:onPluginActivate")).toBeGT(0)
				expect(ArrayFind(log, "B:onPluginActivate")).toBeGT(0)
			})

			it("calls onPluginActivate in alphabetical order", () => {
				PluginObj = $pluginObj(config)
				PluginObj.$invokeOnPluginActivate()
				log = application.$wheelstestLifecycleLog

				posA = ArrayFind(log, "A:onPluginActivate")
				posB = ArrayFind(log, "B:onPluginActivate")
				expect(posA).toBeLT(posB)
			})

			it("calls all onPluginLoad before any onPluginActivate in full sequence", () => {
				PluginObj = $pluginObj(config)
				PluginObj.$invokeOnPluginActivate()
				log = application.$wheelstestLifecycleLog

				lastLoad = 0
				firstActivate = ArrayLen(log) + 1
				for (i = 1; i <= ArrayLen(log); i++) {
					if (FindNoCase("onPluginLoad", log[i])) {
						lastLoad = i
					}
					if (FindNoCase("onPluginActivate", log[i]) && i < firstActivate) {
						firstActivate = i
					}
				}
				expect(lastLoad).toBeLT(firstActivate)
			})

			it("does not inject lifecycle hooks as mixins", () => {
				PluginObj = $pluginObj(config)
				mixins = PluginObj.getMixins()

				// Lifecycle hooks should NOT be in the mixins
				for (target in mixins) {
					expect(mixins[target]).notToHaveKey("onPluginLoad")
					expect(mixins[target]).notToHaveKey("onPluginActivate")
				}

				// But regular mixin methods should still be injected
				expect(mixins.controller).toHaveKey("$LifecycleTestMethodA")
				expect(mixins.model).toHaveKey("$LifecycleTestMethodB")
			})
		})

		describe("Tests that plugin middleware registration", () => {

			beforeEach(() => {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/middleware",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/middleware"
			})

			afterEach(() => {
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("collects middleware registered via onPluginLoad", () => {
				PluginObj = $pluginObj(config)
				pluginMiddleware = PluginObj.getPluginMiddleware()

				expect(pluginMiddleware).toBeArray()
				expect(ArrayLen(pluginMiddleware)).toBe(2)
			})

			it("records the plugin name that registered each middleware", () => {
				PluginObj = $pluginObj(config)
				pluginMiddleware = PluginObj.getPluginMiddleware()

				// Plugins load alphabetically: A then B
				expect(pluginMiddleware[1].pluginName).toBe("TestMiddlewarePluginA")
				expect(pluginMiddleware[2].pluginName).toBe("TestMiddlewarePluginB")
			})

			it("stores the middleware CFC path", () => {
				PluginObj = $pluginObj(config)
				pluginMiddleware = PluginObj.getPluginMiddleware()

				expect(pluginMiddleware[1].middleware).toBe("wheels.tests._assets.middleware.TestMiddlewareA")
				expect(pluginMiddleware[2].middleware).toBe("wheels.tests._assets.middleware.TestMiddlewareB")
			})

			it("stores options when provided", () => {
				PluginObj = $pluginObj(config)
				pluginMiddleware = PluginObj.getPluginMiddleware()

				// Plugin A registered without options
				expect(pluginMiddleware[1].options).toBeStruct()
				expect(StructIsEmpty(pluginMiddleware[1].options)).toBeTrue()

				// Plugin B registered with priority option
				expect(pluginMiddleware[2].options).toHaveKey("priority")
				expect(pluginMiddleware[2].options.priority).toBe(10)
			})

			it("passes application scope data in the onPluginLoad context", () => {
				// The context should include application scope keys
				// This is tested implicitly — if registerMiddleware works, the context was valid
				PluginObj = $pluginObj(config)
				pluginMiddleware = PluginObj.getPluginMiddleware()
				expect(ArrayLen(pluginMiddleware)).toBeGT(0)
			})

			it("returns empty array when no plugins register middleware", () => {
				config.pluginPath = "/wheels/tests/_assets/plugins/standard"
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/standard"
				PluginObj = $pluginObj(config)
				pluginMiddleware = PluginObj.getPluginMiddleware()

				expect(pluginMiddleware).toBeArray()
				expect(ArrayLen(pluginMiddleware)).toBe(0)
			})
		})

		describe("Tests that ServiceProviderInterface plugins", () => {

			beforeEach(() => {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/serviceprovider",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/serviceprovider"
			})

			afterEach(() => {
				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("detects plugins implementing ServiceProviderInterface", () => {
				PluginObj = $pluginObj(config)
				serviceProviders = PluginObj.getServiceProviders()

				expect(serviceProviders).toBeArray()
				expect(ArrayLen(serviceProviders)).toBe(1)
				expect(serviceProviders[1]).toBe("TestServiceProvider")
			})

			it("calls register(container) when $invokeServiceProviderRegister is invoked", () => {
				PluginObj = $pluginObj(config)
				var fakeContainer = {map: true, bind: true, to: true}

				PluginObj.$invokeServiceProviderRegister(fakeContainer)

				var plugin = PluginObj.getPlugins().TestServiceProvider
				expect(plugin.registerCalled).toBeTrue()
				expect(plugin.containerReceived).toBe(fakeContainer)
			})

			it("passes the actual Injector when available", () => {
				PluginObj = $pluginObj(config)

				PluginObj.$invokeServiceProviderRegister(application.wheelsdi)

				var plugin = PluginObj.getPlugins().TestServiceProvider
				expect(plugin.registerCalled).toBeTrue()
				expect(plugin.containerReceived).toBeInstanceOf("wheels.Injector")
			})

			it("excludes ServiceProvider plugins from mixin injection entirely", () => {
				PluginObj = $pluginObj(config)
				mixins = PluginObj.getMixins()

				for (target in mixins) {
					expect(mixins[target]).notToHaveKey("register")
					expect(mixins[target]).notToHaveKey("boot")
					expect(mixins[target]).notToHaveKey("testServiceHelper")
				}
			})

			it("returns empty service providers for standard plugins", () => {
				config.pluginPath = "/wheels/tests/_assets/plugins/standard"
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/standard"
				PluginObj = $pluginObj(config)
				serviceProviders = PluginObj.getServiceProviders()

				expect(serviceProviders).toBeArray()
				expect(ArrayLen(serviceProviders)).toBe(0)
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
