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

	}

}
