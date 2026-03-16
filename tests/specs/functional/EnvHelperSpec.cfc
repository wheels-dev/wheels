component extends="wheels.WheelsTest" {

	function run() {

		describe("env()", () => {

			afterEach(() => {
				// Clean up any test keys we added
				StructDelete(application, "env");
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
