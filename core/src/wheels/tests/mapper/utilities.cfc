component extends="wheels.tests.Test" {

	public void function setup() {
		config = {path = "wheels", fileName = "Mapper", method = "$init"};
		_params = {controller = "test", action = "index"};
		_originalRoutes = Duplicate(application.wheels.routes);
	}

	public boolean function validateRegexPattern(required string pattern) {
		try {
			local.jPattern = CreateObject("java", "java.util.regex.Pattern").compile(arguments.pattern);
		} catch (any e) {
			return false;
		}

		return true;
	}

	public void function teardown() {
		application.wheels.routes = _originalRoutes;
	}

	public struct function $mapper() {
		local.args = Duplicate(config);
		StructAppend(local.args, arguments, true);
		return $createObjectFromRoot(argumentCollection = local.args);
	}

	public struct function $inspect() {
		return variables;
	}

	public void function $clearRoutes() {
		application.wheels.routes = [];
	}

	// compileRegex

	function test_regex_compiles_successfully() {
		mapper = $mapper();
		pattern = "[controller]/[action]/[key]";
		regex = mapper.$patternToRegex(pattern = pattern);
		output = mapper.$compileRegex(regex = regex, pattern = pattern);
		assert('!structKeyExists(variables, "output")');
	}

	function test_regex_compiles_with_error() {
		mapper = $mapper();
		pattern = "[controller]/[action]/[key]";
		e = raised('mapper.$compileRegex(regex="*", pattern="*")');
		assert('e eq "Wheels.InvalidRegex"');
	}

	// normalizePattern

	function test_normalizePattern_no_starting_slash() {
		mapper = $mapper();
		urlString = "controller/action";
		newString = mapper.$normalizePattern(urlString);
		assert('newString eq "/controller/action"');
	}

	function test_normalizePattern_double_slash_and_no_starting_slash() {
		mapper = $mapper();
		urlString = "controller//action";
		newString = mapper.$normalizePattern(urlString);
		assert('newString eq "/controller/action"');
	}

	function test_normalizePattern_ending_slash_no_starting_slash() {
		mapper = $mapper();
		urlString = "controller/action/";
		newString = mapper.$normalizePattern(urlString);
		assert('newString eq "/controller/action"');
	}

	function test_normalizePattern_slashes_everywhere_with_format() {
		mapper = $mapper();
		urlString = "////controller///action///.asdf/////";
		newString = mapper.$normalizePattern(urlString);
		assert('newString eq "/controller/action.asdf"');
	}

	function test_normalizePattern_with_single_quote_in_pattern() {
		mapper = $mapper();
		urlString = "////controller///action///.asdf'";
		newString = mapper.$normalizePattern(urlString);
		assert('newString eq "/controller/action.asdf''"');
	}

	// patternToRegex

	function test_patternToRegex_root() {
		mapper = $mapper();
		pattern = "/";
		regex = mapper.$patternToRegex(pattern);
		assert('regex eq "^\/?$"');
		assert('validateRegexPattern(regex)');
	}

	function test_patternToRegex_root_with_format() {
		mapper = $mapper();
		pattern = "/.[format]";
		regex = mapper.$patternToRegex(pattern);
		assert('regex eq "^\.(\w+)\/?$"');
		assert('validateRegexPattern(regex)');
	}

	function test_patternToRegex_with_basic_catch_all_pattern() {
		mapper = $mapper();
		pattern = "/[controller]/[action]/[key].[format]";
		regex = mapper.$patternToRegex(pattern);
		assert('regex eq "^([^\/]+)\/([^\.\/]+)\/([^\.\/]+)\.(\w+)\/?$"');
		assert('validateRegexPattern(regex)');
	}

	// stripRouteVariables

	function test_stripRouteVariables_no_variables() {
		mapper = $mapper();
		pattern = "/";
		varList = mapper.$stripRouteVariables(pattern);
		assert('varList eq ""');
	}

	function test_stripRouteVariables_root_with_format() {
		mapper = $mapper();
		pattern = "/.[format]";
		varList = mapper.$stripRouteVariables(pattern);
		assert('varList eq "format"');
	}

	function test_stripRouteVariables_with_basic_catch_all_pattern() {
		mapper = $mapper();
		pattern = "/[controller]/[action]/[key].[format]";
		varList = mapper.$stripRouteVariables(pattern);
		assert('varList eq "controller,action,key,format"');
	}

	function test_stripRouteVariables_with_nested_restful_route() {
		mapper = $mapper();
		pattern = "/posts(/[id](/comments(/[commentid](.[format]))))";
		varList = mapper.$stripRouteVariables(pattern);
		assert('varList eq "id,commentid,format"');
	}

}
