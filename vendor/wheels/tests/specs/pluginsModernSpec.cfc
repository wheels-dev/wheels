component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that mixin collision detection", function() {

			it("detects collisions when two plugins provide the same method for the same target", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/collision",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/collision"

				PluginObj = $pluginObj(config)
				collisions = PluginObj.getMixinCollisions()

				expect(collisions).toBeArray()
				expect(arrayLen(collisions)).toBeGT(0)

				var found = false
				for (var c in collisions) {
					if (c.method == "$CollidingMethod" && c.target == "controller") {
						found = true
						expect(c.existingPlugin).toBe("TestCollisionPluginA")
						expect(c.overridingPlugin).toBe("TestCollisionPluginB")
					}
				}
				expect(found).toBeTrue()

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("does not report collisions for unique methods", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/collision",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/collision"

				PluginObj = $pluginObj(config)
				collisions = PluginObj.getMixinCollisions()

				for (var c in collisions) {
					expect(c.method).notToBe("$UniqueToA")
					expect(c.method).notToBe("$UniqueToB")
				}

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("still allows the overriding plugin method to win", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/collision",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/collision"

				PluginObj = $pluginObj(config)
				var mixins = PluginObj.getMixins()

				var result = mixins.controller["$CollidingMethod"]()
				expect(result).toBe("FromPluginB")

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("returns empty array when no collisions exist", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/standard",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/standard"

				PluginObj = $pluginObj(config)
				collisions = PluginObj.getMixinCollisions()

				expect(collisions).toBeArray()
				expect(arrayLen(collisions)).toBe(0)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})
		})

		describe("Tests that lifecycle hooks", function() {

			it("calls onPluginLoad during plugin loading", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath
				StructDelete(application, "$wheelstestLifecycleLog")

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/lifecycle",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/lifecycle"

				PluginObj = $pluginObj(config)
				var log = application.$wheelstestLifecycleLog

				expect(log).toBeArray()
				expect(ArrayFind(log, "A:onPluginLoad")).toBeGT(0)
				expect(ArrayFind(log, "B:onPluginLoad")).toBeGT(0)

				application.wheels.pluginComponentPath = originalPluginComponentPath
				StructDelete(application, "$wheelstestLifecycleLog")
			})

			it("calls onPluginLoad in alphabetical order", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath
				StructDelete(application, "$wheelstestLifecycleLog")

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/lifecycle",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/lifecycle"

				PluginObj = $pluginObj(config)
				var log = application.$wheelstestLifecycleLog

				var posA = ArrayFind(log, "A:onPluginLoad")
				var posB = ArrayFind(log, "B:onPluginLoad")
				expect(posA).toBeLT(posB)

				application.wheels.pluginComponentPath = originalPluginComponentPath
				StructDelete(application, "$wheelstestLifecycleLog")
			})

			it("does not inject lifecycle hooks as mixins", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath
				StructDelete(application, "$wheelstestLifecycleLog")

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/lifecycle",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/lifecycle"

				PluginObj = $pluginObj(config)
				var mixins = PluginObj.getMixins()

				for (var target in mixins) {
					expect(mixins[target]).notToHaveKey("onPluginLoad")
					expect(mixins[target]).notToHaveKey("onPluginActivate")
				}

				expect(mixins.controller).toHaveKey("$LifecycleTestMethodA")
				expect(mixins.model).toHaveKey("$LifecycleTestMethodB")

				application.wheels.pluginComponentPath = originalPluginComponentPath
				StructDelete(application, "$wheelstestLifecycleLog")
			})
		})

		describe("Tests that plugin middleware registration", function() {

			it("collects middleware registered via onPluginLoad", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/middleware",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/middleware"

				PluginObj = $pluginObj(config)
				var pluginMiddleware = PluginObj.getPluginMiddleware()

				expect(pluginMiddleware).toBeArray()
				expect(ArrayLen(pluginMiddleware)).toBe(2)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("records the plugin name that registered each middleware", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/middleware",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/middleware"

				PluginObj = $pluginObj(config)
				var pluginMiddleware = PluginObj.getPluginMiddleware()

				expect(pluginMiddleware[1].pluginName).toBe("TestMiddlewarePluginA")
				expect(pluginMiddleware[2].pluginName).toBe("TestMiddlewarePluginB")

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("returns empty array when no plugins register middleware", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/standard",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/standard"

				PluginObj = $pluginObj(config)
				var pluginMiddleware = PluginObj.getPluginMiddleware()

				expect(pluginMiddleware).toBeArray()
				expect(ArrayLen(pluginMiddleware)).toBe(0)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})
		})

		describe("Tests that ServiceProviderInterface plugins", function() {

			it("detects plugins implementing ServiceProviderInterface", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/serviceprovider",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/serviceprovider"

				PluginObj = $pluginObj(config)
				var serviceProviders = PluginObj.getServiceProviders()

				expect(serviceProviders).toBeArray()
				expect(ArrayLen(serviceProviders)).toBe(1)
				expect(serviceProviders[1]).toBe("TestServiceProvider")

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("calls register(container) when $invokeServiceProviderRegister is invoked", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/serviceprovider",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/serviceprovider"

				PluginObj = $pluginObj(config)
				var fakeContainer = CreateObject("component",
					"wheels.tests._assets.plugins.serviceprovider.FakeContainer").init()

				PluginObj.$invokeServiceProviderRegister(fakeContainer)

				var plugin = PluginObj.getPlugins().TestServiceProvider
				expect(plugin.registerCalled).toBeTrue()
				expect(plugin.containerReceived).toBe(fakeContainer)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("excludes ServiceProvider plugins from mixin injection entirely", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/serviceprovider",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/serviceprovider"

				PluginObj = $pluginObj(config)
				var mixins = PluginObj.getMixins()

				for (var target in mixins) {
					expect(mixins[target]).notToHaveKey("register")
					expect(mixins[target]).notToHaveKey("boot")
					expect(mixins[target]).notToHaveKey("testServiceHelper")
				}

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("returns empty service providers for standard plugins", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/standard",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/standard"

				PluginObj = $pluginObj(config)
				var serviceProviders = PluginObj.getServiceProviders()

				expect(serviceProviders).toBeArray()
				expect(ArrayLen(serviceProviders)).toBe(0)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("calls boot(app) when $invokeServiceProviderBoot is invoked", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/serviceprovider",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/serviceprovider"

				PluginObj = $pluginObj(config)
				var fakeApp = {environment = "testing", version = "3.0.0"}

				PluginObj.$invokeServiceProviderBoot(fakeApp)

				var plugin = PluginObj.getPlugins().TestServiceProvider
				expect(plugin.bootCalled).toBeTrue()
				expect(plugin.appReceived).toBe(fakeApp)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("does not call boot on standard plugins", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/standard",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/standard"

				PluginObj = $pluginObj(config)

				PluginObj.$invokeServiceProviderBoot(application.wheels)

				expect(ArrayLen(PluginObj.getServiceProviders())).toBe(0)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})
		})

	}

	function $pluginObj(required struct config) {
		return g.$createObjectFromRoot(argumentCollection = arguments.config)
	}

}
