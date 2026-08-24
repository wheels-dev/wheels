/**
 * B3: live $setCORSHeaders default is deny-all (allowOrigin=""), not Origin=*.
 *
 * Does not change CORS production defaults. Does not add B1 wildcard-matcher
 * cases (https://*.example.com vs evil.com). Those stay HELD.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("B3 $setCORSHeaders default is deny-all", function() {

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
				expect($headerValue("Access-Control-Allow-Origin")).notToBe("*");
			});

			it("pins the function default and the early return in source", function() {
				var src = $stripCfmlComments(FileRead(ExpandPath("/wheels/global/cors.cfm")));
				expect(Find("string allowOrigin = """"", src)).toBeGT(0);
				expect(Find("if (!Len(arguments.allowOrigin))", src)).toBeGT(0);
				expect(application.wheels.accessControlAllowOrigin).toBe("");
				expect(application.wheels.allowCorsRequests).toBeFalse();
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
