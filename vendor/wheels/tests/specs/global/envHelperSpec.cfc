component extends="wheels.WheelsTest" {

	function run() {

		describe("env()", () => {

			beforeEach(() => {
				// Save original application.env so we can restore it
				_savedEnv = StructKeyExists(application, "env") ? Duplicate(application.env) : "__missing__";
			})

			afterEach(() => {
				// Restore original application.env
				if (IsSimpleValue(_savedEnv) && _savedEnv == "__missing__") {
					StructDelete(application, "env");
				} else {
					application.env = _savedEnv;
				}
			})

			it("returns value from application.env when present", () => {
				application.env = {TEST_KEY: "from_dotenv"};
				expect(env("TEST_KEY")).toBe("from_dotenv");
			})

			it("returns default when key is not found anywhere", () => {
				application.env = {};
				expect(env("NONEXISTENT_KEY_12345")).toBe("");
			})

			it("returns custom default when key is not found", () => {
				application.env = {};
				expect(env("NONEXISTENT_KEY_12345", "custom_default")).toBe("custom_default");
			})

			// Back-compat: the parameter was renamed from `default` to
			// `defaultValue` because Adobe CF 2023/2025 refuses to bind a
			// parameter named with the CFML reserved word `default`. The
			// function still accepts the legacy named-arg form via the
			// `StructKeyExists(arguments, "default")` guard in Global.cfc —
			// named arguments land in the arguments scope under their literal
			// key regardless of the declared parameter list. This spec is the
			// regression catch: if the guard is ever removed or a future
			// engine rejects `default` as a named-arg key at the call site,
			// this assertion will fail.
			it("accepts the legacy 'default' named arg for back-compat", () => {
				application.env = {};
				expect(env(name = "NONEXISTENT_KEY_12345", default = "legacy_default")).toBe("legacy_default");
			})

			it("prefers application.env over system environment", () => {
				// If a key exists in both, application.env should win
				application.env = {PATH: "app_path_override"};
				expect(env("PATH")).toBe("app_path_override");
			})

			it("falls back to server.system.environment", () => {
				// PATH should exist in system environment on all platforms
				application.env = {};
				local.result = env("PATH");
				expect(local.result).notToBe("");
			})

		})

		describe("application.env population", () => {

			it("application.env is populated from Application.cfc this.env", () => {
				expect(StructKeyExists(application, "env")).toBeTrue();
				expect(IsStruct(application.env)).toBeTrue();
			})

		})

	}
}
