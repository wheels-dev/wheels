component extends="wheels.tests.Test" {

	include "helpers.cfm";

	function setup() {
		config = {
			path = "wheels",
			fileName = "Plugins",
			method = "$init",
			pluginPath = "/wheels/tests/_assets/plugins/overwriting",
			deletePluginDirectories = false,
			overwritePlugins = true,
			loadIncompatiblePlugins = true
		};
		$writeTestFile();
	}

	function test_overwrite_plugins() {
		fileContentBefore = $readTestFile();
		PluginObj = $pluginObj(config);
		fileContentAfter = $readTestFile();
		assert('fileContentBefore eq "overwritten"');
		assert('fileContentAfter neq "overwritten"');
	}

	function test_do_not_overwrite_plugins() {
		config.overwritePlugins = false;
		fileContentBefore = $readTestFile();
		PluginObj = $pluginObj(config);
		fileContentAfter = $readTestFile();
		assert('fileContentBefore eq "overwritten"');
		assert('fileContentAfter eq "overwritten"');
	}

}
