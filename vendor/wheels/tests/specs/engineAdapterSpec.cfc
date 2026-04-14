component extends="wheels.WheelsTest" {

	function run() {

		describe("Engine Adapter", function() {

			it("is auto-detected at startup", function() {
				expect(application.wheels.engineAdapter).toBeComponent();
			});

			it("returns the correct engine name", function() {
				var name = application.wheels.engineAdapter.getName();
				expect(ListFind("Lucee,Adobe ColdFusion,BoxLang", name)).toBeGT(0);
			});

			it("returns a non-empty version string", function() {
				expect(Len(application.wheels.engineAdapter.getVersion())).toBeGT(0);
			});

			it("returns a valid major version", function() {
				expect(application.wheels.engineAdapter.getMajorVersion()).toBeGT(0);
			});

			it("matches the application serverName", function() {
				expect(application.wheels.engineAdapter.getName()).toBe(application.wheels.serverName);
			});

			it("matches the application serverVersion", function() {
				expect(application.wheels.engineAdapter.getVersion()).toBe(application.wheels.serverVersion);
			});

			it("returns a response object", function() {
				var resp = application.wheels.engineAdapter.getResponse();
				expect(resp).notToBeNull();
			});

			it("returns a status code as numeric", function() {
				var code = application.wheels.engineAdapter.getStatusCode();
				expect(code).toBeNumeric();
			});

			it("returns content type as string", function() {
				var ct = application.wheels.engineAdapter.getContentType();
				expect(IsSimpleValue(ct)).toBeTrue();
			});

			it("returns request timeout as numeric", function() {
				var timeout = application.wheels.engineAdapter.getRequestTimeout();
				expect(timeout).toBeNumeric();
			});

			it("is accessible via the convenience function", function() {
				var adapter = application.wo.$engineAdapter();
				expect(adapter.getName()).toBe(application.wheels.engineAdapter.getName());
			});

		});

		describe("Engine Adapter - Identity Helpers", function() {

			it("reports exactly one engine identity as true", function() {
				var adapter = application.wheels.engineAdapter;
				var count = 0;
				if (adapter.isLucee()) count++;
				if (adapter.isAdobe()) count++;
				if (adapter.isBoxLang()) count++;
				expect(count).toBe(1);
			});

			it("identity matches engine name for Lucee", function() {
				var adapter = application.wheels.engineAdapter;
				if (adapter.getName() == "Lucee") {
					expect(adapter.isLucee()).toBeTrue();
					expect(adapter.isAdobe()).toBeFalse();
					expect(adapter.isBoxLang()).toBeFalse();
				}
			});

			it("identity matches engine name for Adobe ColdFusion", function() {
				var adapter = application.wheels.engineAdapter;
				if (adapter.getName() == "Adobe ColdFusion") {
					expect(adapter.isAdobe()).toBeTrue();
					expect(adapter.isLucee()).toBeFalse();
					expect(adapter.isBoxLang()).toBeFalse();
				}
			});

			it("identity matches engine name for BoxLang", function() {
				var adapter = application.wheels.engineAdapter;
				if (adapter.getName() == "BoxLang") {
					expect(adapter.isBoxLang()).toBeTrue();
					expect(adapter.isLucee()).toBeFalse();
					expect(adapter.isAdobe()).toBeFalse();
				}
			});

		});

		describe("Engine Adapter - parseFormKey", function() {

			it("parses single-level bracket key", function() {
				var result = application.wheels.engineAdapter.parseFormKey("user[name]", "user");
				expect(result).toBeArray();
				expect(ArrayLen(result)).toBe(1);
				expect(result[1]).toBe("name");
			});

			it("parses deeply nested keys", function() {
				var result = application.wheels.engineAdapter.parseFormKey("user[address][city]", "user");
				expect(result).toBeArray();
				expect(ArrayLen(result)).toBe(2);
				expect(result[1]).toBe("address");
				expect(result[2]).toBe("city");
			});

			it("parses triple-nested keys", function() {
				var result = application.wheels.engineAdapter.parseFormKey("order[item][detail][color]", "order");
				expect(result).toBeArray();
				expect(ArrayLen(result)).toBe(3);
			});

		});

		describe("Engine Adapter - controllerNameToUpperCamelCase", function() {

			it("converts hyphenated names to UpperCamelCase", function() {
				var result = application.wheels.engineAdapter.controllerNameToUpperCamelCase("user-settings");
				expect(result).toBe("UserSettings");
			});

			it("converts simple lowercase to capitalized", function() {
				var result = application.wheels.engineAdapter.controllerNameToUpperCamelCase("users");
				expect(result).toBe("Users");
			});

			it("preserves dot-delimited namespacing", function() {
				var result = application.wheels.engineAdapter.controllerNameToUpperCamelCase("admin.users");
				expect(result).toBe("admin.Users");
			});

		});

		describe("Engine Adapter - Oracle JDBC Object Handling", function() {

			it("returns simple values unchanged from coerceOracleObject", function() {
				expect(application.wheels.engineAdapter.coerceOracleObject("hello")).toBe("hello");
			});

			it("returns numbers unchanged from coerceOracleObject", function() {
				expect(application.wheels.engineAdapter.coerceOracleObject(42)).toBe(42);
			});

			it("returns structs unchanged from coerceOracleObject", function() {
				var s = {foo: "bar"};
				var result = application.wheels.engineAdapter.coerceOracleObject(s);
				expect(result.foo).toBe("bar");
			});

			it("returns false for simple values from isOracleJdbcObject", function() {
				expect(application.wheels.engineAdapter.isOracleJdbcObject("test")).toBeFalse();
				expect(application.wheels.engineAdapter.isOracleJdbcObject(123)).toBeFalse();
			});

			it("returns false for structs from isOracleJdbcObject", function() {
				expect(application.wheels.engineAdapter.isOracleJdbcObject({a: 1})).toBeFalse();
			});

		});

		describe("Engine Adapter - Dynamic Finders", function() {

			it("parses findAllByTitle into single property", function() {
				var result = application.wheels.engineAdapter.dynamicFinderProperties("findAllByTitle", "findAllBy");
				expect(result).toBeArray();
				expect(ArrayLen(result)).toBe(1);
			});

			it("parses findOneByTitleAndStatus into two properties", function() {
				var result = application.wheels.engineAdapter.dynamicFinderProperties("findOneByTitleAndStatus", "findOneBy");
				expect(result).toBeArray();
				expect(ArrayLen(result)).toBe(2);
			});

			it("parses findAllByFirstNameAndLastNameAndEmail into three properties", function() {
				var result = application.wheels.engineAdapter.dynamicFinderProperties("findAllByFirstNameAndLastNameAndEmail", "findAllBy");
				expect(result).toBeArray();
				expect(ArrayLen(result)).toBe(3);
			});

		});

		describe("Engine Adapter - Hash Normalization", function() {

			it("normalizes JSON for consistent hashing", function() {
				var result = application.wheels.engineAdapter.normalizeForHash('{"b":"2","a":"1"}');
				expect(IsSimpleValue(result)).toBeTrue();
				expect(Len(result)).toBeGT(0);
			});

			it("produces deterministic output regardless of key order", function() {
				var r1 = application.wheels.engineAdapter.normalizeForHash('["a","b","c"]');
				var r2 = application.wheels.engineAdapter.normalizeForHash('["c","b","a"]');
				expect(r1).toBe(r2);
			});

		});

		describe("Engine Adapter - Struct Defaults", function() {

			it("appends missing keys from defaults", function() {
				var target = {a: 1};
				var defaults = {a: 99, b: 2, c: 3};
				application.wheels.engineAdapter.structAppendDefaults(target, defaults);
				expect(target.a).toBe(1);
				expect(target.b).toBe(2);
				expect(target.c).toBe(3);
			});

			it("does not overwrite existing keys", function() {
				var target = {name: "original"};
				var defaults = {name: "default", extra: "value"};
				application.wheels.engineAdapter.structAppendDefaults(target, defaults);
				expect(target.name).toBe("original");
				expect(target.extra).toBe("value");
			});

		});

		describe("Engine Adapter - Numeric Validation", function() {

			it("returns true for simple integers", function() {
				expect(application.wheels.engineAdapter.isNumericStrict(42)).toBeTrue();
			});

			it("returns true for decimals", function() {
				expect(application.wheels.engineAdapter.isNumericStrict(3.14)).toBeTrue();
			});

			it("returns true for negative numbers", function() {
				expect(application.wheels.engineAdapter.isNumericStrict(-7)).toBeTrue();
			});

			it("returns false for non-numeric strings", function() {
				expect(application.wheels.engineAdapter.isNumericStrict("abc")).toBeFalse();
			});

		});

		describe("Engine Adapter - Glob Pattern Matching", function() {

			it("returns a non-empty glob regex", function() {
				expect(Len(application.wheels.engineAdapter.globRegex())).toBeGT(0);
			});

			it("extracts variable name from glob on current engine", function() {
				var adapter = application.wheels.engineAdapter;
				if (adapter.isBoxLang()) {
					var result = adapter.extractGlobVariable("*[myVar]");
					expect(result).toBe("myVar");
				} else {
					var result = adapter.extractGlobVariable("*myVar");
					expect(result).toBe("myVar");
				}
			});

		});

		describe("Engine Adapter - Query Argument Mapping", function() {

			it("returns a valid argument name for key column", function() {
				var argName = application.wheels.engineAdapter.queryKeyColumnArgName();
				expect(ListFind("keyColumn,columnKey", argName)).toBeGT(0);
			});

		});

		describe("Engine Adapter - Port Detection", function() {

			it("returns a numeric default port", function() {
				expect(application.wheels.engineAdapter.getDefaultPort()).toBeNumeric();
			});

			it("returns a reasonable port number", function() {
				var port = application.wheels.engineAdapter.getDefaultPort();
				expect(port).toBeGT(0);
				expect(port).toBeLT(100000);
			});

		});

		describe("Engine Adapter - Date Parsing", function() {

			it("parses an ambiguous date where both values are valid months", function() {
				// Both d1 and d2 must be <= 12 (caller handles unambiguous cases)
				var result = application.wheels.engineAdapter.parseAmbiguousSlashDate(3, 5, 2024);
				expect(IsDate(result)).toBeTrue();
				expect(Year(result)).toBe(2024);
			});

			it("returns a date object", function() {
				var result = application.wheels.engineAdapter.parseAmbiguousSlashDate(5, 7, 2024);
				expect(IsDate(result)).toBeTrue();
			});

		});

		describe("Engine Adapter - Image Formats", function() {

			it("returns a non-empty image formats string", function() {
				var result = application.wheels.engineAdapter.getReadableImageFormatsString();
				expect(IsSimpleValue(result)).toBeTrue();
				expect(Len(result)).toBeGT(0);
			});

		});

		describe("Engine Adapter - DI Completion", function() {

			it("does not throw when called with empty struct", function() {
				var vars = {};
				var thisScope = {};
				application.wheels.engineAdapter.prepareDIComplete(vars, thisScope);
				// Should not throw - BoxLang sets vars.this, others no-op
				expect(true).toBeTrue();
			});

		});

		describe("Engine Adapter - Zip Args", function() {

			it("returns the args struct", function() {
				var args = {file: "test.zip", destination: "/tmp"};
				var result = application.wheels.engineAdapter.prepareZipArgs(args);
				expect(IsStruct(result)).toBeTrue();
				expect(StructKeyExists(result, "file")).toBeTrue();
			});

		});

	}

}
