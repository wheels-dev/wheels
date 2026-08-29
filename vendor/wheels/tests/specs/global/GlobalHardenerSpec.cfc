/**
 * Global helper Hardener: B1 wildcard matcher, B2 $get denylist,
 * B3 deny-all CORS default, S2 proxy proto, S5 $dbinfo table,
 * S8 cacheFileChecking file list.
 *
 * S1/S3/S4/S6/S7/S9/S10 stay HELD.
 *
 * Directory-scoped so `wheels test --core --ci --filter=global` discovers it.
 *
 * CoS lock: allowCorsRequests=false, accessControlAllowOrigin="",
 * credentials=false, trustProxyHeaders=false, cacheFileChecking=true.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("CoS lock: global security defaults stay conservative", function() {

			it("keeps allowCorsRequests false and accessControlAllowOrigin empty", function() {
				expect(application.wheels.allowCorsRequests).toBeFalse();
				expect(application.wheels.accessControlAllowOrigin).toBe("");
			});

			it("keeps trustProxyHeaders false", function() {
				expect(application.wheels.trustProxyHeaders).toBeFalse();
			});

			it("keeps cacheFileChecking true", function() {
				expect(application.wheels.cacheFileChecking).toBeTrue();
			});

		});

		describe("B1 $wildcardDomainMatch does not treat TLD+port as enough", function() {

			it("does not match https://evil.com against https://*.example.com", function() {
				expect(g.$wildcardDomainMatch("https://*.example.com", "https://evil.com")).toBeFalse(
					"Reverse+SpanExcluding only compared TLD+port so evil.com matched *.example.com"
				);
			});

			it("does not match https://notexample.com against https://*.example.com", function() {
				expect(g.$wildcardDomainMatch("https://*.example.com", "https://notexample.com")).toBeFalse();
			});

			it("still matches a single-label subdomain of example.com", function() {
				expect(g.$wildcardDomainMatch("https://*.example.com", "https://foo.example.com")).toBeTrue();
			});

		});

		describe("B2 $get denylist covers live security keys", function() {

			afterEach(function() {
				if (StructKeyExists(request, "wheels")) {
					StructDelete(request.wheels, "tenant");
				}
			});

			it("does not let tenant config override live csrf, proxy, CORS, error, or datasource keys", function() {
				request.wheels.tenant = {
					id = "evil",
					dataSource = "ds1",
					config = {
						csrfCookieEncryptionAlgorithm = "HACK-ALG",
						csrfCookieEncryptionSecretKey = "HACK-KEY",
						csrfCookieEncryptionEncoding = "HACK-ENC",
						trustProxyHeaders = true,
						allowCorsRequests = true,
						accessControlAllowOrigin = "*",
						accessControlAllowMethods = "HACK",
						accessControlAllowMethodsByRoute = true,
						accessControlAllowCredentials = true,
						accessControlAllowHeaders = "HACK",
						showErrorInformation = "HACK-ERR",
						dataSourceName = "hacked_ds"
					}
				};
				expect(g.$get("csrfCookieEncryptionAlgorithm")).notToBe("HACK-ALG");
				expect(g.$get("csrfCookieEncryptionSecretKey")).notToBe("HACK-KEY");
				expect(g.$get("csrfCookieEncryptionEncoding")).notToBe("HACK-ENC");
				expect(g.$get("trustProxyHeaders")).toBeFalse();
				expect(g.$get("allowCorsRequests")).toBeFalse();
				expect(g.$get("accessControlAllowOrigin")).toBe("");
				expect(g.$get("accessControlAllowMethods")).notToBe("HACK");
				expect(g.$get("accessControlAllowMethodsByRoute")).toBeFalse();
				expect(g.$get("accessControlAllowCredentials")).toBeFalse();
				expect(g.$get("accessControlAllowHeaders")).notToBe("HACK");
				expect(g.$get("showErrorInformation")).notToBe("HACK-ERR");
				expect(g.$get("dataSourceName")).toBe(application.wheels.dataSourceName);
			});

		});

		describe("B3 $setCORSHeaders default allowOrigin is deny-all, not Origin=*", function() {

			it("declares allowOrigin empty and returns before emitting CORS headers", function() {
				var src = $stripCfmlComments(FileRead(ExpandPath("/wheels/global/cors.cfm")));
				expect(Find("string allowOrigin = """"", src)).toBeGT(
					0,
					"$setCORSHeaders must default allowOrigin to empty (deny-all)"
				);
				expect(Find("if (!Len(arguments.allowOrigin))", src)).toBeGT(
					0,
					"empty allowOrigin must return before writing Access-Control-Allow-Origin"
				);
				expect(Find("value = ""*""", src)).toBe(0);
			});

			it("does not emit Access-Control-Allow-Origin=* on the default call", function() {
				if (!g.$engineAdapter().isLucee()) { // RustCFML emulates server.lucee — the engine adapter is authoritative
					return;
				}
				cfheader(name = "Access-Control-Allow-Origin", value = "SENTINEL-UNSET");
				g.$setCORSHeaders();
				expect($headerValue("Access-Control-Allow-Origin")).toBe(
					"SENTINEL-UNSET",
					"default $setCORSHeaders() must not write Origin=* (deny-all)"
				);
				expect($headerValue("Access-Control-Allow-Origin")).notToBe("*");
			});

		});

		describe("S2 $fullCgiDomainString honors $trustProxyHeaders()", function() {

			afterEach(function() {
				application.wheels.trustProxyHeaders = false;
			});

			it("ignores X-Forwarded-Proto https when trustProxyHeaders is off", function() {
				application.wheels.trustProxyHeaders = false;
				var r = g.$fullCgiDomainString({
					server_name = "www.wheels.dev",
					server_port = 80,
					server_port_secure = 0,
					http_x_forwarded_proto = "https"
				});
				expect(r).toBe("http://www.wheels.dev:80");
			});

			it("honors X-Forwarded-Proto https when trustProxyHeaders is on", function() {
				application.wheels.trustProxyHeaders = true;
				var r = g.$fullCgiDomainString({
					server_name = "www.wheels.dev",
					server_port = 80,
					server_port_secure = 0,
					http_x_forwarded_proto = "https"
				});
				expect(r).toBe("https://www.wheels.dev:80");
			});

			it("still uses server_port_secure when trust is off", function() {
				application.wheels.trustProxyHeaders = false;
				var r = g.$fullCgiDomainString({
					server_name = "www.wheels.dev",
					server_port = 443,
					server_port_secure = 1,
					http_x_forwarded_proto = ""
				});
				expect(r).toBe("https://www.wheels.dev:443");
			});

		});

		describe("S5 $dbinfo does not interpolate arguments.table into SQL", function() {

			it("source has no ##arguments.table## interpolation in tags.cfm", function() {
				var src = $stripCfmlComments(FileRead(ExpandPath("/wheels/global/tags.cfm")));
				expect(FindNoCase("##arguments.table##", src)).toBe(
					0,
					"$dbinfo must not interpolate arguments.table into SQL"
				);
			});

			it("rejects a table name that is not a SQL identifier", function() {
				expect(function() {
					g.$dbinfo(
						datasource = application.wheels.dataSourceName,
						type = "index",
						table = "users'; DROP TABLE wheels--"
					);
				}).toThrow("Wheels.InvalidArgument");
			});

		});

		describe("S8 $fileExistsNoCase does not cache when cacheFileChecking is false", function() {

			it("does not write directoryFiles when cacheFileChecking is false", function() {
				var appKey = g.$appKey();
				var priorCache = application[appKey].cacheFileChecking;
				var priorFiles = Duplicate(application[appKey].directoryFiles);
				application[appKey].cacheFileChecking = false;
				application[appKey].directoryFiles = {};
				var state = {found = false, cacheCount = -1};
				try {
					state.found = g.$fileExistsNoCase(
						ExpandPath("/wheels/tests/_assets/models/") & "PhotoGallery.cfc"
					);
					state.cacheCount = StructCount(application[appKey].directoryFiles);
				} finally {
					application[appKey].cacheFileChecking = priorCache;
					application[appKey].directoryFiles = priorFiles;
				}
				expect(state.found).toBe("PhotoGallery.cfc");
				expect(state.cacheCount).toBe(
					0,
					"$fileExistsNoCase must not write directoryFiles when cacheFileChecking is false"
				);
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
