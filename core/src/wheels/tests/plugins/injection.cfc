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
		PluginObj = $pluginObj(config);
		application.wheels.mixins = PluginObj.getMixins();
		m = model("_c_o_r_e_authors").new();
		_params = {controller = "test", action = "index"};
		c = controller("test", _params);
		d = $createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
		t = application.wirebox.getInstance("wheels.Test");
	}

	function teardown() {
		application.wheels.mixins = {};
	}

	function test_global_method() {
		assert('StructKeyExists(m, "$GlobalTestMixin")');
		assert('StructKeyExists(c, "$GlobalTestMixin")');
		assert('StructKeyExists(d, "$GlobalTestMixin")');
		assert('StructKeyExists(t, "$GlobalTestMixin")');
	}

	function test_component_specific() {
		assert('StructKeyExists(m, "$MixinForModels")');
		assert('StructKeyExists(m, "$MixinForModelsAndContollers")');
		assert('StructKeyExists(c, "$MixinForControllers")');
		assert('StructKeyExists(c, "$MixinForModelsAndContollers")');
		assert('StructKeyExists(d, "$MixinForDispatch")');
	}

}
