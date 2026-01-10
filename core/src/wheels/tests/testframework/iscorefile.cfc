component extends="wheels.tests.Test" {

	// these tests don't pass on windows or when app is in a subfolder

	function _test_$isCoreFile_rewrite_cfm_is_true() {
		path = ExpandPath('index.cfm');
		debug("path", false);
		assert("$isCoreFile(path)", "path");
	}

	function _test_$isCoreFile_index_cfm_is_false() {
		path = ExpandPath('index.cfm');
		debug("path", false);
		assert("$isCoreFile(path)", "path");
	}

	function _test_$isCoreFile_Dispatch_cfc_is_false() {
		path = ExpandPath('/wheels/Dispatch.cfc');
		debug("path", false);
		assert("$isCoreFile(path)", "path");
	}

	function _test_$isCoreFile_config_settings_cfm_is_false() {
		path = ExpandPath('/config/settings.cfm');
		debug("path", false);
		assert("!$isCoreFile(path)", "path");
	}

}
