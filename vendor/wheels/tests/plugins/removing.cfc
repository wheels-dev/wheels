component extends="wheels.tests.Test" {

	include "helpers.cfm";

	function setup() {
		config = {
			path = "wheels",
			fileName = "Plugins",
			method = "$init",
			pluginPath = "/wheels/tests/_assets/plugins/removing",
			deletePluginDirectories = true,
			overwritePlugins = false,
			loadIncompatiblePlugins = true
		};
		dir = ExpandPath(config.pluginPath);
		dir = ListChangeDelims(dir, "/", "\");

		badDir = ListAppend(dir, "testing", "/");
		goodDir = ListAppend(dir, "testglobalmixins", "/");
		$deleteDirs();
		$createDir();
	}

	function teardown() {
		$deleteDirs();
	}

	function test_remove_unused_plugin_directories() {
		assert('DirectoryExists(badDir)');
		PluginObj = $pluginObj(config);
		assert('DirectoryExists(goodDir)');
		assert('not DirectoryExists(badDir)');
	}

}
