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

				var fn = mixins.controller["$CollidingMethod"]
				var result = fn()
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

			it("keeps live application references intact after onPluginLoad", function() {
				var originalPluginComponentPath = application.wheels.pluginComponentPath
				StructDelete(application, "$wheelstestLifecycleLog")

				// A struct placed in the application scope before plugins load.
				// The onPluginLoad context must be a shallow copy: the old
				// Duplicate(application) implementation wrote a deep clone back
				// over this key, forking it from any variable still holding the
				// original reference (di-packages:10).
				var marker = {value = "original"}
				application.$wheelstestSharedRef = marker

				// try/finally so a failing assertion can't leak $wheelstestSharedRef
				// (or the mutated pluginComponentPath) into subsequent tests.
				try {
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

					var PluginObj = $pluginObj(config)

					// Mutating through the pre-load reference must be visible through
					// the application scope — they are the same struct.
					marker.value = "mutated"
					expect(application.$wheelstestSharedRef.value).toBe("mutated")
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath
					StructDelete(application, "$wheelstestSharedRef")
					StructDelete(application, "$wheelstestLifecycleLog")
				}
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

			it("isolates an onPluginLoad failure so sibling plugins still load", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath
				StructDelete(application, "$wheelstestLifecycleLog")

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/lifecyclefailing",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/lifecyclefailing"

				try {
					// Must complete without throwing even though
					// TestLifecycleFailingA's onPluginLoad throws (sorted order
					// runs the failing plugin's hook first).
					PluginObj = $pluginObj(config)

					expect(PluginObj.getPlugins()).toHaveKey("TestLifecycleFailingA")
					expect(PluginObj.getPlugins()).toHaveKey("TestLifecycleWorkingB")
					expect(ArrayFind(application.$wheelstestLifecycleLog, "B:onPluginLoad")).toBeGT(0)
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath
					StructDelete(application, "$wheelstestLifecycleLog")
				}
			})

			it("isolates an onPluginActivate failure so sibling plugins still activate", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath
				StructDelete(application, "$wheelstestLifecycleLog")

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/lifecyclefailing",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/lifecyclefailing"

				try {
					PluginObj = $pluginObj(config)
					// Reset the log so the assertion below can only be satisfied
					// by the activate phase, not the load phase above.
					StructDelete(application, "$wheelstestLifecycleLog")

					// Must complete without throwing even though
					// TestLifecycleFailingA's onPluginActivate throws first.
					PluginObj.$invokeOnPluginActivate()

					expect(ArrayFind(application.$wheelstestLifecycleLog, "B:onPluginActivate")).toBeGT(0)
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath
					StructDelete(application, "$wheelstestLifecycleLog")
				}
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

			it("isolates a register() failure so remaining providers still register and boot", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath
				StructDelete(request, "$spPluginFailingBootCalled")

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/serviceproviderfailing",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/serviceproviderfailing"

				PluginObj = $pluginObj(config)
				var fakeContainer = CreateObject("component",
					"wheels.tests._assets.plugins.serviceprovider.FakeContainer").init()

				// Must complete without throwing even though FailingProvider's
				// register() throws (sorted order loads FailingProvider first).
				PluginObj.$invokeServiceProviderRegister(fakeContainer)

				// The healthy provider after the failing one still registered.
				var plugin = PluginObj.getPlugins().WorkingProvider
				expect(plugin.registerCalled).toBeTrue()

				// The failing provider is dropped from the registry so boot() skips it.
				expect(ArrayFind(PluginObj.getServiceProviders(), "FailingProvider")).toBe(0)
				expect(ArrayFind(PluginObj.getServiceProviders(), "WorkingProvider")).toBeGT(0)

				PluginObj.$invokeServiceProviderBoot({environment = "testing"})

				expect(plugin.bootCalled).toBeTrue()
				expect(StructKeyExists(request, "$spPluginFailingBootCalled")).toBeFalse()

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})
		})

		describe("Tests that plugin.json manifest parsing", function() {

			it("parses a full plugin.json manifest and stores it on metadata", function() {
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

				expect(meta).toHaveKey("TestManifestPlugin")
				expect(meta.TestManifestPlugin).toHaveKey("manifest")

				var manifest = meta.TestManifestPlugin.manifest
				expect(manifest.name).toBe("TestManifestPlugin")
				expect(manifest.version).toBe("2.1.0")
				expect(manifest.author).toBe("Wheels Test Suite")
				expect(manifest.description).toBe("A full plugin.json manifest for testing")
				expect(manifest.dependencies).toBeArray()
				expect(manifest.dependencies[1]).toBe("SomeOtherPlugin")
				expect(manifest.mixins).toBe("controller")
				expect(manifest.wheelsVersion).toBe("3.0")
				expect(manifest.middleware).toBeArray()
				expect(manifest.middleware[1].component).toBe("TestMiddleware")

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("uses plugin.json version over box.json version", function() {
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

				// The CFC sets this.version = "99.9.9" but plugin.json has "2.1.0"
				// plugin.json should take precedence via $pluginMetaData
				expect(meta.TestManifestPlugin.version).toBe("2.1.0")

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("parses a minimal manifest with only required fields", function() {
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

				expect(meta.TestMinimalManifestPlugin.manifest.name).toBe("TestMinimalManifestPlugin")
				expect(meta.TestMinimalManifestPlugin.manifest.version).toBe("1.0.0")

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("rejects a manifest missing required fields", function() {
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

				// Bad manifest should result in empty manifest struct
				expect(StructIsEmpty(meta.TestBadManifestPlugin.manifest)).toBeTrue()

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("leaves manifest empty when no plugin.json exists", function() {
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

				expect(StructIsEmpty(meta.TestNoManifestPlugin.manifest)).toBeTrue()

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("validates required name and version fields", function() {
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

				var errors = PluginObj.$validatePluginManifest({})
				expect(ArrayLen(errors)).toBeGTE(2)

				var hasNameError = false
				var hasVersionError = false
				for (var e in errors) {
					if (FindNoCase("name", e)) hasNameError = true
					if (FindNoCase("version", e)) hasVersionError = true
				}
				expect(hasNameError).toBeTrue()
				expect(hasVersionError).toBeTrue()

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("validates that dependencies must be an array of strings", function() {
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

				var errors = PluginObj.$validatePluginManifest({
					name = "Test",
					version = "1.0.0",
					dependencies = "notAnArray"
				})
				expect(ArrayLen(errors)).toBeGTE(1)

				var foundError = false
				for (var e in errors) {
					if (FindNoCase("dependencies", e) && FindNoCase("array", e)) foundError = true
				}
				expect(foundError).toBeTrue()

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("validates that middleware entries must have a component field", function() {
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

				var errors = PluginObj.$validatePluginManifest({
					name = "Test",
					version = "1.0.0",
					middleware = [{"notComponent" = "bad"}]
				})
				expect(ArrayLen(errors)).toBeGTE(1)

				var foundError = false
				for (var e in errors) {
					if (FindNoCase("middleware", e) && FindNoCase("component", e)) foundError = true
				}
				expect(foundError).toBeTrue()

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("returns the schema definition with expected fields", function() {
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

				var schema = PluginObj.$pluginManifestSchema()
				expect(schema).toHaveKey("name")
				expect(schema).toHaveKey("version")
				expect(schema).toHaveKey("author")
				expect(schema).toHaveKey("description")
				expect(schema).toHaveKey("dependencies")
				expect(schema).toHaveKey("mixins")
				expect(schema).toHaveKey("middleware")
				expect(schema).toHaveKey("wheelsVersion")

				expect(schema.name.required).toBeTrue()
				expect(schema.version.required).toBeTrue()
				expect(schema.author.required).toBeFalse()

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("accepts valid manifest without errors", function() {
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

				var errors = PluginObj.$validatePluginManifest({
					name = "ValidPlugin",
					version = "1.0.0",
					author = "Test Author",
					description = "A test plugin",
					dependencies = ["dep1", "dep2"],
					mixins = "controller,model",
					middleware = [{"component" = "MyMiddleware"}],
					wheelsVersion = "3.0"
				})
				expect(ArrayLen(errors)).toBe(0)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})
		})

		describe("Tests that deprecation warnings for mixin-only plugins", function() {

			it("warns about legacy plugins without plugin.json or ServiceProvider in development mode", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/deprecation",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsEnvironment = "development"
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/deprecation"

				PluginObj = $pluginObj(config)
				var warnings = PluginObj.getDeprecationWarnings()

				expect(warnings).toBeArray()
				expect(ArrayLen(warnings)).toBe(1)
				expect(warnings[1].plugin).toBe("LegacyMixinPlugin")
				expect(warnings[1].message).toInclude("legacy mixin injection")
				expect(warnings[1].message).toInclude("plugin.json")

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("does not warn about plugins that have plugin.json", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/deprecation",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsEnvironment = "development"
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/deprecation"

				PluginObj = $pluginObj(config)
				var warnings = PluginObj.getDeprecationWarnings()

				for (var w in warnings) {
					expect(w.plugin).notToBe("ModernJsonPlugin")
				}

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("does not warn about ServiceProvider plugins", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/serviceprovider",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsEnvironment = "development"
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/serviceprovider"

				PluginObj = $pluginObj(config)
				var warnings = PluginObj.getDeprecationWarnings()

				expect(warnings).toBeArray()
				expect(ArrayLen(warnings)).toBe(0)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("does not warn in production mode", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/deprecation",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsEnvironment = "production"
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/deprecation"

				PluginObj = $pluginObj(config)
				var warnings = PluginObj.getDeprecationWarnings()

				expect(warnings).toBeArray()
				expect(ArrayLen(warnings)).toBe(0)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})

			it("does not warn in testing mode", function() {
				originalPluginComponentPath = application.wheels.pluginComponentPath

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/deprecation",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsEnvironment = "testing"
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/deprecation"

				PluginObj = $pluginObj(config)
				var warnings = PluginObj.getDeprecationWarnings()

				expect(warnings).toBeArray()
				expect(ArrayLen(warnings)).toBe(0)

				application.wheels.pluginComponentPath = originalPluginComponentPath
			})
		})

	}

	function $pluginObj(required struct config) {
		return g.$createObjectFromRoot(argumentCollection = arguments.config)
	}

}
