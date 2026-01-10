/*
  There are 4 ways to use plugin in wheels:

    1. add processing on top of a method,
       then call the framework method (aka onMissingMethod())
    2. completely override a method in wheels
    3. get the return value from a core method and add on to the return value
    4. add new functionality not currently in wheels

  We need to use recursion due to option three where we need need to be able
  to return a proper value from core.method()
 */
component extends="wheels.tests.Test" {

	include "helpers.cfm";

	function setup() {
		config = {
			path = "wheels",
			fileName = "Plugins",
			method = "$init",
			pluginPath = "/wheels/tests/_assets/plugins/runner",
			deletePluginDirectories = false,
			overwritePlugins = false,
			loadIncompatiblePlugins = true
		};
		_params = {controller = "test", action = "index"};
		PluginObj = $pluginObj(config);
		previousMixins = Duplicate(application.wheels.mixins);
		application.wheels.mixins = PluginObj.getMixins();
		_originalViewPath = get("viewPath");
		set(viewPath = "/wheels/tests/_assets/views");
		c = controller("test", _params);
		m = model("c_o_r_e_authors").new();
		d = $createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
	}

	function teardown() {
		set(viewPath = _originalViewPath);
		application.wheels.mixins = previousMixins;
	}

	function test_call_plugin_methods_from_other_methods() {
		result = c.$helper01();
		assert('result eq"$helper011Responding"');
	}

	function test_call_plugin_method_via_$invoke() {
		result = c.$invoke(method = "$helper01", invokeArgs = {});
		assert('result eq"$helper011Responding"');
	}

	function test_call_plugin_method_via_$simplelock() {
		result = c.$simpleLock(
			name = "$simpleLockHelper01",
			type = "exclusive",
			execute = "$helper01",
			executeArgs = {},
			timeout = 5
		);
		assert('result eq"$helper011Responding"');
	}

	function test_call_plugin_method_via_$doublecheckedlock() {
		result = c.$doubleCheckedLock(
			name = "$doubleCheckedLockHelper01",
			condition = "$helper01ConditionalCheck",
			conditionArgs = {},
			type = "exclusive",
			execute = "$helper01",
			executeArgs = {},
			timeout = 5
		);
		assert('result eq"$helper011Responding"');
	}

	function test_call_core_method_changing_calling_function_name() {
		result = c.pluralize("book");
		assert('result eq "books"');
	}
	function test_override_a_framework_method() {
		result = c.singularize(word = "hahahah");
		assert('result eq "$$completelyOverridden"');
	}

	/*
  function test_chain_return_values_from_multiple_plugin_overrides() {
    result = c.URLFor(controller="wheels", action="wheels");
    valid = findNoCase("urlfor01&urlfor02", result);
    assert('valid neq 0');
  }

  function test_chain_return_values_from_multiple_plugin_overrides_in_dispatch() {
    result = d.URLFor(controller="wheels", action="wheels");
    valid = findNoCase("urlfor01&urlfor02", result);
    assert('valid neq 0');
  }

  // our $pluginRunner will error out due to core.onMissingMethod() being called
  // too many times
  function test_raise_error_running_multiple_override_methods_without_core_method() {
    args = {missingMethodName="asdf", missingMethodArguments={ value="asdf"}};
    r = raised("c.onMissingMethod(args)");
    assert('r eq "Wheels.MethodNotFound"');
  }

  // we use the model onMissingMethod method to tell us that the asdf method
  // doesn't exist
  function test_raise_error_running_multiple_override_methods_with_core_method() {
    args = {missingMethodName="asdf", missingMethodArguments={ value="asdf"}};
    r = raised("m.onMissingMethod(argumentCollection=args)");
    assert('r eq "Wheels.MethodNotFound"');
  }
*/

	function test_running_plugin_only_method() {
		result = c.$$pluginOnlyMethod();
		assert('result eq "$$returnValue"');
	}

	function test_call_overridden_method_with_identical_method_nesting() {
		request.wheels.includePartialStack = [];
		result = c.includePartial(partial = "testpartial");
		assert('trim(result) eq "<p>some content</p>"');
	}

}
