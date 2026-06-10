component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Legacy plugin lifecycle isolation", function() {

			it("isolates an onPluginLoad failure and continues loading remaining plugins", function() {
				var originalPluginComponentPath = application.wheels.pluginComponentPath
				StructDelete(application, "$wheelstestLifecycleFailingLog")

				try {
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

					// Must complete without throwing even though FailingLifecyclePlugin's
					// onPluginLoad throws (sorted order loads it before WorkingLifecyclePlugin).
					var PluginObj = $pluginObj(config)

					// Both plugins are registered — the failure logs and skips, it
					// doesn't unregister the plugin.
					var plugins = PluginObj.getPlugins()
					expect(plugins).toHaveKey("FailingLifecyclePlugin")
					expect(plugins).toHaveKey("WorkingLifecyclePlugin")

					// The healthy sibling's onPluginLoad still ran.
					expect(application).toHaveKey("$wheelstestLifecycleFailingLog")
					expect(ArrayFind(application.$wheelstestLifecycleFailingLog, "Working:onPluginLoad")).toBeGT(0)
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath
					StructDelete(application, "$wheelstestLifecycleFailingLog")
				}
			})

			it("isolates an onPluginActivate failure and continues activating remaining plugins", function() {
				var originalPluginComponentPath = application.wheels.pluginComponentPath
				StructDelete(application, "$wheelstestLifecycleFailingLog")

				try {
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

					var PluginObj = $pluginObj(config)
					// Clear the log so we observe only onPluginActivate runs below.
					StructDelete(application, "$wheelstestLifecycleFailingLog")

					// Must complete without throwing even though FailingLifecyclePlugin's
					// onPluginActivate throws.
					PluginObj.$invokeOnPluginActivate()

					// The healthy sibling's onPluginActivate still ran.
					expect(application).toHaveKey("$wheelstestLifecycleFailingLog")
					expect(ArrayFind(application.$wheelstestLifecycleFailingLog, "Working:onPluginActivate")).toBeGT(0)
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath
					StructDelete(application, "$wheelstestLifecycleFailingLog")
				}
			})

		})

	}

	function $pluginObj(required struct config) {
		return g.$createObjectFromRoot(argumentCollection = arguments.config)
	}

}
