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

	function test_dependant_plugin() {
		config.pluginPath = "/wheels/tests/_assets/plugins/dependant";
		PluginObj = $pluginObj(config);
		iplugins = PluginObj.getDependantPlugins();
		assert('iplugins eq "TestPlugin1|TestPlugin2,TestPlugin1|TestPlugin3"');
	}

}
