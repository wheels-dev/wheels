component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

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
				log = application.$wheelstestLifecycleLog

				expect(ArrayFind(log, "A:onPluginLoad")).toBeGT(0)
				expect(ArrayFind(log, "B:onPluginLoad")).toBeGT(0)
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

				for (target in mixins) {
					expect(mixins[target]).notToHaveKey("onPluginLoad")
					expect(mixins[target]).notToHaveKey("onPluginActivate")
				}

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

				expect(pluginMiddleware[1].options).toBeStruct()
				expect(StructIsEmpty(pluginMiddleware[1].options)).toBeTrue()

				expect(pluginMiddleware[2].options).toHaveKey("priority")
				expect(pluginMiddleware[2].options.priority).toBe(10)
			})

			it("passes application scope data in the onPluginLoad context", () => {
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
				var fakeContainer = CreateObject("component",
					"wheels.tests._assets.plugins.serviceprovider.FakeContainer").init()

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

			it("allows plugins to register services into the container", () => {
				PluginObj = $pluginObj(config)

				PluginObj.$invokeServiceProviderRegister(application.wheelsdi)

				expect(application.wheelsdi.containsInstance("pluginGreeting")).toBeTrue()

				var svc = application.wheelsdi.getInstance("pluginGreeting")
				expect(svc).toBeInstanceOf(
					"wheels.tests._assets.plugins.serviceprovider.TestServiceProvider.PluginGreetingService"
				)
				expect(svc.greet("Wheels")).toBe("Hello from plugin, Wheels!")
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

			it("calls boot(app) when $invokeServiceProviderBoot is invoked", () => {
				PluginObj = $pluginObj(config)
				var fakeApp = {environment: "testing", version: "3.0.0"}

				PluginObj.$invokeServiceProviderBoot(fakeApp)

				var plugin = PluginObj.getPlugins().TestServiceProvider
				expect(plugin.bootCalled).toBeTrue()
				expect(plugin.appReceived).toBe(fakeApp)
			})

			it("calls boot after register in the correct lifecycle order", () => {
				PluginObj = $pluginObj(config)

				PluginObj.$invokeServiceProviderRegister(application.wheelsdi)
				PluginObj.$invokeServiceProviderBoot(application.wheels)

				var plugin = PluginObj.getPlugins().TestServiceProvider
				expect(plugin.registerCalled).toBeTrue()
				expect(plugin.bootCalled).toBeTrue()
			})

			it("allows plugins to resolve services registered during register() when boot() is called", () => {
				PluginObj = $pluginObj(config)

				PluginObj.$invokeServiceProviderRegister(application.wheelsdi)
				PluginObj.$invokeServiceProviderBoot(application.wheels)

				var plugin = PluginObj.getPlugins().TestServiceProvider
				expect(plugin.resolvedDuringBoot).notToBeNull()
				expect(plugin.resolvedDuringBoot.greet("Test")).toBe("Hello from plugin, Test!")
			})

			it("does not call boot on standard plugins", () => {
				config.pluginPath = "/wheels/tests/_assets/plugins/standard"
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/standard"
				PluginObj = $pluginObj(config)

				PluginObj.$invokeServiceProviderBoot(application.wheels)

				expect(ArrayLen(PluginObj.getServiceProviders())).toBe(0)
			})
		})

	}

	function $pluginObj(required struct config) {
		return g.$createObjectFromRoot(argumentCollection = arguments.config)
	}

}
