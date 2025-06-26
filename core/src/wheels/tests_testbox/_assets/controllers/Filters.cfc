component extends="Controller" {

	function config() {
		aStr.testArg1 = 1;
		aStr.testArg2 = 2;
		filters(through = "dir", testArg = 1, except = "doNotRun");
		filters(through = "str", strArguments = Duplicate(aStr));
		filters(through = "both", bothArguments = Duplicate(aStr), testArg = 1);
		filters(through = "pub,priv", only = "index,actOne,actTwo");
		filters(through = "typeBefore", only = "noView", type = "before");
		filters(through = "typeAfter", only = "noView", type = "after");
	}

	function typeBefore() {
		request.filterTestTypes = ["before"];
	}

	function typeAfter() {
		if (NOT IsDefined("request.filterTestTypes")) {
			request.filterTestTypes = [];
		}
		ArrayAppend(request.filterTestTypes, "after");
	}

	function dir() {
		request.filterTests.dirTest = arguments.testArg;
	}

	function str() {
		request.filterTests.strTest = StructCount(arguments) & arguments.testArg1;
	}

	function both() {
		request.filterTests.bothTest = StructCount(arguments) & arguments.testArg;
		if (NOT IsDefined("request.filterTests.test") OR request.filterTests.test IS "bothpubpriv") {
			request.filterTests.test = "";
		}
		request.filterTests.test = request.filterTests.test & "both";
	}

	function pub() {
		request.filterTests.pubTest = true;
		if (NOT IsDefined("request.filterTests.test") OR request.filterTests.test IS "bothpubpriv") {
			request.filterTests.test = "";
		}
		request.filterTests.test = request.filterTests.test & "pub";
		request.filterTests.pubTest = true;
	}

	private void function priv() {
		request.filterTests.privTest = true;
		if (NOT IsDefined("request.filterTests.test") OR request.filterTests.test IS "bothpubpriv") {
			request.filterTests.test = "";
		}
		request.filterTests.test = request.filterTests.test & "priv";
	}

	function noView() {
		renderText(text = "#params.controller####params.action#");
	}

}
