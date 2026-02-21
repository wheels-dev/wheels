component extends="wheels.tests.Test" {

	include "helpers.cfm";

	function setup() {
		config = {
			path = "wheels",
			fileName = "Plugins",
			method = "$init",
			pluginPath = "/wheels/tests/_assets/plugins/unpacking",
			deletePluginDirectories = false,
			overwritePlugins = false,
			loadIncompatiblePlugins = true
		};
		$deleteTestFolders();
	}

	function teardown() {
		$deleteTestFolders();
	}

	function test_unpacking_plugin() {
		pluginObj = $pluginObj(config);
		q = DirectoryList(ExpandPath(config.pluginPath), false, "query");
		dirs = ValueList(q.name);
		assert('ListFind(dirs, "testdefaultassignmixins")');
		assert('ListFind(dirs, "testglobalmixins")');
	}

}
