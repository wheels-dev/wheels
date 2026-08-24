/**
 * B3: live $setCORSHeaders default is deny-all (allowOrigin=""), not Origin=*.
 *
 * Does not change CORS production defaults. Does not add B1 wildcard-matcher
 * cases (https://*.example.com vs evil.com). Those stay HELD.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.$$oldCGIScope = Duplicate(request.cgi);
		variables.$$oldHeaders = Duplicate(request.wheels.httprequestdata.headers);
		variables.$$originalRoutes = Duplicate(application.wheels.routes);
		variables.$$originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? StructCopy(
			application.wheels.staticRoutes
		) : {};
		config = {path = "wheels", fileName = "Mapper", method = "$init"};
	}

	function afterAll() {
		request.cgi = variables.$$oldCGIScope;
		request.wheels.httprequestdata.headers = variables.$$oldHeaders;
		application.wheels.routes = variables.$$originalRoutes;
		application.wheels.staticRoutes = variables.$$originalStaticRoutes;
		application.wheels.allowCorsRequests = false;
	}

	function run() {

		g = application.wo

		describe("B3 $setCORSHeaders default is deny-all", function() {

			beforeEach(function() {
				if (!StructKeyExists(request.wheels.httprequestdata, "headers")) {
					request.wheels.httprequestdata.headers = {};
				}
			});

			it("does not emit Access-Control-Allow-Origin=* when allowOrigin is the empty default", function() {
				if (!StructKeyExists(server, "lucee")) {
					return;
				}
				cfheader(name = "Access-Control-Allow-Origin", value = "SENTINEL-UNSET");
				g.$setCORSHeaders();
				expect($headerValue("Access-Control-Allow-Origin")).toBe(
					"SENTINEL-UNSET",
					"live default allowOrigin="""" is deny-all; must not write Origin=*"
				);
			});

			it("pins the function default and the early return in source", function() {
				var src = $stripCfmlComments(FileRead(ExpandPath("/wheels/global/cors.cfm")));
				expect(Find("string allowOrigin = """"", src)).toBeGT(0);
				expect(Find("if (!Len(arguments.allowOrigin))", src)).toBeGT(0);
				expect(application.wheels.accessControlAllowOrigin).toBe("");
			});

			it("still emits * when allowOrigin is passed as wildcard", function() {
				if (!StructKeyExists(server, "lucee")) {
					return;
				}
				g.$setCORSHeaders(allowOrigin = "*");
				expect($headerValue("Access-Control-Allow-Origin")).toBe("*");
			});

			it("emits a matching simple origin", function() {
				if (!StructKeyExists(server, "lucee")) {
					return;
				}
				request.wheels.httprequestdata.headers["origin"] = "http://www.mydomain.com";
				g.$setCORSHeaders(allowOrigin = "http://www.mydomain.com");
				expect($headerValue("Access-Control-Allow-Origin")).toBe("http://www.mydomain.com");
			});

			it("does not emit a non-matching simple origin", function() {
				if (!StructKeyExists(server, "lucee")) {
					return;
				}
				cfheader(name = "Access-Control-Allow-Origin", value = "SENTINEL-UNSET");
				request.wheels.httprequestdata.headers["origin"] = "http://www.baddomain.com";
				g.$setCORSHeaders(allowOrigin = "http://www.mydomain.com");
				expect($headerValue("Access-Control-Allow-Origin")).toBe("SENTINEL-UNSET");
			});

			it("emits a matching origin from an allow list", function() {
				if (!StructKeyExists(server, "lucee")) {
					return;
				}
				request.wheels.httprequestdata.headers["origin"] = "https://domain.com";
				g.$setCORSHeaders(allowOrigin = "http://www.mydomain.com,https://domain.com");
				expect($headerValue("Access-Control-Allow-Origin")).toBe("https://domain.com");
			});

		});

	}

	public string function $stripCfmlComments(required string source) {
		var stripped = arguments.source;
		stripped = reReplace(stripped, "<!---[\s\S]*?--->", "", "all");
		stripped = reReplace(stripped, "/\*[\s\S]*?\*/", "", "all");
		stripped = reReplace(stripped, "(?m)//[^\n]*", "", "all");
		return stripped;
	}

	public string function $headerValue(required string name) {
		var raw = GetPageContext().getResponse().getHeader(arguments.name);
		return IsNull(raw) ? "" : ToString(raw);
	}

}
