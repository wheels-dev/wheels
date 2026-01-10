component extends="wheels.tests.Test" {

	include "helpers.cfm";

	function setup() {
		config = {
			path = "wheels",
			fileName = "Plugins",
			method = "$init",
			pluginPath = "/wheels/tests/_assets/plugins/standard",
			deletePluginDirectories = false,
			overwritePlugins = false,
			loadIncompatiblePlugins = true
		};
	}

	function test_load_all_plugins() {
		PluginObj = $pluginObj(config);
		plugins = PluginObj.getPlugins();
		assert('not StructIsEmpty(plugins)');
		assert('StructKeyExists(plugins, "TestAssignMixins")');
	}

	function test_notify_incompatible_version() {
		config.wheelsVersion = "99.9.9";
		PluginObj = $pluginObj(config);
		iplugins = PluginObj.getIncompatiblePlugins();
		assert('iplugins eq "TestIncompatableVersion"');
	}

	function test_no_loading_of_incompatible_plugins() {
		config.loadIncompatiblePlugins = false;
		config.wheelsVersion = "99.9.9";
		PluginObj = $pluginObj(config);
		plugins = PluginObj.getPlugins();
		assert('not StructIsEmpty(plugins)');
		assert('StructKeyExists(plugins, "TestAssignMixins")');
		assert('not StructKeyExists(plugins, "TestIncompatablePlugin")');
	}

}
