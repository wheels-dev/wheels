component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests that $args", () => {

			it("throws error when declaring missing required arguments", () => {
				args = {}
				expected = "Wheels.IncorrectArguments"

				expect(function() {
					g.$args(args=args, name="sendEmail", combine="template/templates/!")
				}).toThrow(expected)

				expect(function() {
					g.$args(args=args, name="sendEmail", combine="template/templates", required="template")
				}).toThrow(expected)

				expect(function() {
					g.$args(args=args, name="sendEmail", required="template")
				}).toThrow(expected)

				args.template = ""

				expect(function() {
					g.$args(args=args, name="sendEmail", combine="template/templates", required="template")
				}).toThrow(expected)

				args.template = ""

				$assert.notThrows(function() {
					g.$args(args=args, name="sendEmail", combine="template/templates")
				})
			})

			it("should not raise error when not declaring missing required arguments", () => {
				args = {}
				expected = ""

				$assert.notThrows(function() {
					g.$args(args=args, name="sendEmail", combine="template/templates")
				})

				$assert.notThrows(function() {
					g.$args(args=args, name="sendEmail")
				})
			})

			it("is combining arguments", () => {
				expected = ""
				actual = combined_arguments(template = "tony", templates = "per")

				expect(actual.template).toBe("per")
				expect(actual).notToHaveKey('templates')

				actual = combined_arguments(templates = "per")

				expect(actual.template).toBe("per")
				expect(actual).notToHaveKey('templates')
			})
		})

		describe("Tests that $cgiscope", () => {

			beforeEach(() => {
				cgi_scope = {}
				cgi_scope.request_method = ""
				cgi_scope.http_x_requested_with = ""
				cgi_scope.http_referer = ""
				cgi_scope.server_name = ""
				cgi_scope.query_string = ""
				cgi_scope.remote_addr = ""
				cgi_scope.server_port = ""
				cgi_scope.server_port_secure = ""
				cgi_scope.server_protocol = ""
				cgi_scope.http_host = ""
				cgi_scope.http_accept = ""
				cgi_scope.content_type = ""
				cgi_scope.script_name = "/index.cfm"
				cgi_scope.path_info = "/users/list/index.cfm"
				cgi_scope.http_x_rewrite_url = "/users/list/http_x_rewrite_url/index.cfm?controller=wheels&action=wheels&view=test"
				cgi_scope.http_x_original_url = "/users/list/http_x_original_url/index.cfm?controller=wheels&action=wheels&view=test"
				cgi_scope.request_uri = "/users/list/request_uri/index.cfm?controller=wheels&action=wheels&view=test"
				cgi_scope.redirect_url = "/users/list/redirect_url/index.cfm?controller=wheels&action=wheels&view=test"
				cgi_scope.http_x_forwarded_for = ""
				cgi_scope.http_x_forwarded_proto = ""
			})

			it("checks path info is blank", () => {
				cgi_scope.path_info = ""
				_cgi = g.$cgiScope(scope = cgi_scope)

				expect(_cgi.path_info).toBe("/users/list/http_x_rewrite_url")

				cgi_scope.http_x_rewrite_url = ""
				_cgi = g.$cgiScope(scope = cgi_scope)

				expect(_cgi.path_info).toBe("/users/list/http_x_original_url")

				cgi_scope.http_x_original_url = ""
				_cgi = g.$cgiScope(scope = cgi_scope)

				expect(_cgi.path_info).toBe("/users/list/request_uri")

				cgi_scope.request_uri = ""
				_cgi = g.$cgiScope(scope = cgi_scope)

				expect(_cgi.path_info).toBe("/users/list/redirect_url")
			})

			it("checks path info should remove trailing slash", () => {
				cgi_scope.path_info = ""
				_cgi = g.$cgiScope(scope = cgi_scope)

				expect(_cgi.path_info).toBe("/users/list/http_x_rewrite_url")
			})

			it("checks path info is non ascii", () => {
				e = {
					script_name = "/index.cfm",
					path_info = "/wheels/wheels/%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81",
					unencoded_url = "/index.cfm/wheels/wheels/%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81?normal=1&chinese=%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81",
					query_string = "normal=1&chinese=%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81"
				}
				scope = {
					script_name = "/index.cfm",
					path_info = "/wheels/wheels/????",
					unencoded_url = "/index.cfm/wheels/wheels/%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81?normal=1&chinese=%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81",
					query_string = "normal=1&chinese=%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81"
				}
				r = g.$cgiScope(keys = "script_name,path_info,unencoded_url,query_string", scope = scope)

				expect(r.path_info).toBe(urlDecode(e.path_info))
			})
		})

		describe("Tests that $checkMinimumVersion", () => {

			it("checks railo invalid", () => {
				expect(len(g.$checkMinimumVersion(version="4.3.0.003", engine="Railo"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="4.2.1.008", engine="Railo"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="3.0.2", engine="Railo"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="4.2.1.000", engine="Railo"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="3.1.2", engine="Railo"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="3.1.2.020", engine="Railo"))).toBeGT(0)
			})

			it("checks lucee valid", () => {
				expect(len(g.$checkMinimumVersion(version="5.3.2.77", engine="Lucee"))).toBe(0)
				expect(len(g.$checkMinimumVersion(version="5.3.5.92", engine="Lucee"))).toBe(0)
			})

			it("checks lucee invalid", () => {
				expect(len(g.$checkMinimumVersion(version="5.3.1.103", engine="Lucee"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="4.5.5.006", engine="Lucee"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="4.5.1.021", engine="Lucee"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="4.4.0", engine="Lucee"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="4.5.0.023", engine="Lucee"))).toBeGT(0)
			})

			it("checks adobe valid", () => {
				expect(len(g.$checkMinimumVersion(version="11,0,18,314030", engine="Adobe ColdFusion"))).toBe(0)
				expect(len(g.$checkMinimumVersion(version="2016,0,10,314028", engine="Adobe ColdFusion"))).toBe(0)
				expect(len(g.$checkMinimumVersion(version="2018,0,03,314033", engine="Adobe ColdFusion"))).toBe(0)
			})

			it("checks adobe invalid", () => {
				expect(len(g.$checkMinimumVersion(version="7", engine="Adobe ColdFusion"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="8,0,1,0", engine="Adobe ColdFusion"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="8,0", engine="Adobe ColdFusion"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="8,0,0,0", engine="Adobe ColdFusion"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="8,0,0,195765", engine="Adobe ColdFusion"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="8,0,1,195765", engine="Adobe ColdFusion"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="9,0,0,251028", engine="Adobe ColdFusion"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="10,0,0,282462", engine="Adobe ColdFusion"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="10,0,3,282462", engine="Adobe ColdFusion"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="10,0,4,277803", engine="Adobe ColdFusion"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="10,0,23,302580", engine="Adobe ColdFusion"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="11,0,3,282462", engine="Adobe ColdFusion"))).toBeGT(0)
				expect(len(g.$checkMinimumVersion(version="11,0,12,302575", engine="Adobe ColdFusion"))).toBeGT(0)
			})
		})

		describe("Tests that $fullDomainString", () => {

			it("is returing protocol and port", () => {
				r = g.$fullDomainString("http://www.cfwheels.com")
				r2 = g.$fullDomainString("https://www.cfwheels.com")
				r3 = g.$fullDomainString("http://www.cfwheels.com:8080")
				r4 = g.$fullDomainString("https://www.cfwheels.com:8443")
				r5 = g.$fullDomainString("www.cfwheels.com")
				r6 = g.$fullDomainString("www.cfwheels.com:80")
				r7 = g.$fullDomainString("www.cfwheels.com:8888")
				r8 = g.$fullDomainString("www.cfwheels.com:443")

				expect(r).toBe("http://www.cfwheels.com:80")
				expect(r2).toBe("https://www.cfwheels.com:443")
				expect(r3).toBe("http://www.cfwheels.com:8080")
				expect(r4).toBe("https://www.cfwheels.com:8443")
				expect(r5).toBe("http://www.cfwheels.com:80")
				expect(r6).toBe("http://www.cfwheels.com:80")
				expect(r7).toBe("http://www.cfwheels.com:8888")
				expect(r8).toBe("https://www.cfwheels.com:443")
			})
		})

		describe("Tests that $fullCgiDomainString", () => {

			it("gets full domain string from cgi https", () => {
				r = g.$fullCgiDomainString({server_name = "www.cfwheels.com", server_port = 443, server_port_secure = 1})

				expect(r).toBe("https://www.cfwheels.com:443")
			})
			
			it("gets full domain string from cgi https non standard", () => {
				r = g.$fullCgiDomainString({server_name = "www.cfwheels.com", server_port = 8443, server_port_secure = 1})

				expect(r).toBe("https://www.cfwheels.com:8443")
			})

			it("gets full domain string from cgi http", () => {
				r = g.$fullCgiDomainString({server_name = "www.cfwheels.com", server_port = 80, server_port_secure = 0})

				expect(r).toBe("http://www.cfwheels.com:80")
			})

			it("gets full domain string from cgi http non standard", () => {
				r = g.$fullCgiDomainString({server_name = "www.cfwheels.com", server_port = 8080, server_port_secure = 0})

				expect(r).toBe("http://www.cfwheels.com:8080")
			})
		})

		describe("Tests that $getrequesttimeout", () => {

			it("is getting timeout", () => {
				if (application.wheels.ServerName == "Boxlang") return;
				setting requestTimeout=666;
				expect(g.$getRequestTimeout()).toBe(666)
				setting requesttimeout="10000";
			})
		})

		describe("Tests that $hashedkey", () => {

			it("accepts undefined value", () => {
				$assert.notThrows(function(string value1 = "foo", string value2) {
					/* value2 arg creates an undefined value to test $hashedKey() */
					g.$hashedKey(argumentCollection = arguments)
				})
			})

			it("accepts generated query", () => {
				$assert.notThrows(function(string a = "foo", query = QueryNew('a,b,c,e')) {
					/* query arg creates a query that does not have sql metadata */
					g.$hashedKey(argumentCollection = arguments)
				})
			})

			it("tests same output", () => {
				binaryData = FileReadBinary(ExpandPath('/wheels/tests_testbox/_assets/files/cfwheels-logo.png'));
				transaction action="begin" {
					photo = g.model("photo").findOne();
					photo.update(filename = "somefilename", fileData = binaryData);
					photo = g.model("photo").findAll(where = "id = #photo.id#");
					transaction action="rollback";
				}
				a = [];
				a[1] = "petruzzi";
				a[2] = "gibson";
				query = QueryNew('a,b,c,d,e');
				QueryAddRow(query, 1);
				QuerySetCell(query, "a", "tony");
				QuerySetCell(query, "b", "per");
				QuerySetCell(query, "c", "james");
				QuerySetCell(query, "d", "chris");
				QuerySetCell(query, "e", "raul");
				a[3] = query;
				a[4] = [1, 2, 3, 4, 5, 6];
				a[5] = {a = 1, b = 2, c = 3, d = 4};
				a[6] = photo;
				if (structKeyExists(server, "boxlang") && isObject(photo.filedata)) {
					local.className = GetMetadata(photo.filedata).getName();
					if (local.className == "oracle.sql.BLOB") {
						// Convert Oracle BLOB to binary using getBytes() method
						photo.filedata = photo.filedata.getBytes();
					}
				}
				args = {};
				args.a = a;
				e = g.$hashedKey(argumentCollection = args);
				ArraySwap(a, 1, 3);
				ArraySwap(a, 4, 5);
				r = g.$hashedKey(argumentCollection = args);

				expect(e).toBe(r)
			})
		})

		describe("Tests that $listToStruct", () => {
			
			it("is creating struct from list", () => {
				actual = g.$listToStruct("a,b,c")

				expect(actual.a).toBe(1)
				expect(actual.b).toBe(1)
				expect(actual.c).toBe(1)
				expect(actual).toHaveLength(3)
			})
		})

		describe("Tests that $wildcardDomainMatchCGI", () => {
			
			it("matches simple exact http", () => {
				r = g.$wildcardDomainMatchCGI(
					"http://www.domain.com",
					{server_name = "www.domain.com", server_port = 80, server_port_secure = 0}
				)

				expect(r).toBeTrue()
			})

			it("matches simple exact http non standard port", () => {
				r = g.$wildcardDomainMatchCGI(
					"http://www.domain.com:8080",
					{server_name = "www.domain.com", server_port = 8080, server_port_secure = 0}
				)

				expect(r).toBeTrue()
			})
			
			it("matches simple exact https", () => {
				r = g.$wildcardDomainMatchCGI(
					"https://www.domain.com",
					{server_name = "www.domain.com", server_port = 443, server_port_secure = 1}
				)

				expect(r).toBeTrue()
			})

			it("matches simple exact http non standard port", () => {
				r = g.$wildcardDomainMatchCGI(
					"https://www.domain.com:8443",
					{server_name = "www.domain.com", server_port = 8443, server_port_secure = 1}
				)

				expect(r).toBeTrue()
			})

			it("matches simple wildcard", () => {
				r = g.$wildcardDomainMatchCGI(
					"https://*.domain.com",
					{server_name = "anything.domain.com", server_port = 443, server_port_secure = 1}
				)

				expect(r).toBeTrue()
			})

			it("matches simple wildcard suffix", () => {
				r = g.$wildcardDomainMatchCGI(
					"https://www.domain.*",
					{server_name = "www.domain.net", server_port = 443, server_port_secure = 1}
				)

				expect(r).toBeTrue()
			})

			it("matches simple wildcard position", () => {
				r = g.$wildcardDomainMatchCGI(
					"https://api.*.domain.com",
					{server_name = "api.staging.domain.com", server_port = 443, server_port_secure = 1}
				)

				expect(r).toBeTrue()
			})
		})
	}

	function combined_arguments() {
		g.$args(args = arguments, name = "sendEmail", combine = "template/templates")
		return arguments
	}
}