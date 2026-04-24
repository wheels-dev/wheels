component extends="wheels.WheelsTest" {

	function run() {
		describe("Public.$loadRegistryPackages", () => {

			var $newPublic = () => {
				return new wheels.Public();
			};

			// Minimal fake registry that returns canned data or throws.
			var $fakeRegistry = (packages = [], throwType = "", throwMessage = "") => {
				return CreateObject("component", "wheels.tests._assets.packages.FakeRegistry").init(
					packages = packages,
					throwType = throwType,
					throwMessage = throwMessage
				);
			};

			// Swap application.wheels.environment for the duration of a callback.
			var $withEnv = (env, fn) => {
				var prior = application.wheels.environment ?: "development";
				application.wheels.environment = env;
				try { fn(); }
				finally { application.wheels.environment = prior; }
			};

			it("returns empty packages and no error when environment is production", () => {
				$withEnv("production", () => {
					var pub = $newPublic();
					var result = pub.$loadRegistryPackages(
						registry = $fakeRegistry(packages = [{name: "should-not-appear"}])
					);
					expect(result.packages).toBe([]);
					expect(result.error).toBe("");
				});
			});

			it("returns packages from the registry in development", () => {
				$withEnv("development", () => {
					var pub = $newPublic();
					var result = pub.$loadRegistryPackages(
						registry = $fakeRegistry(packages = [
							{name: "wheels-sentry",  description: "x", tags: [], homepage: "", latestVersion: "1.0.0"}
						])
					);
					expect(ArrayLen(result.packages)).toBe(1);
					expect(result.packages[1].name).toBe("wheels-sentry");
					expect(result.error).toBe("");
				});
			});

			it("captures registry errors into the error field without throwing", () => {
				$withEnv("development", () => {
					var pub = $newPublic();
					var result = pub.$loadRegistryPackages(
						registry = $fakeRegistry(
							throwType = "Wheels.Packages.RegistryUnavailable",
							throwMessage = "GitHub returned 503"
						)
					);
					expect(result.packages).toBe([]);
					expect(result.error contains "GitHub returned 503").toBeTrue();
				});
			});

			it("lets non-Wheels.Packages errors bubble up as real bugs", () => {
				$withEnv("development", () => {
					var pub = $newPublic();
					var thrown = "";
					try {
						pub.$loadRegistryPackages(
							registry = $fakeRegistry(
								throwType = "java.lang.NullPointerException",
								throwMessage = "npe from listAll"
							)
						);
					} catch ("java.lang.NullPointerException" e) {
						thrown = e.message;
					}
					expect(thrown).toBe("npe from listAll");
				});
			});

			it("silently disables the browse section when the CLI registry class is not on the classpath", () => {
				$withEnv("development", () => {
					// Subclass that simulates a generated user app without cli/ on the classpath.
					var pub = new wheels.tests._assets.packages.PublicWithoutRegistry();
					var result = pub.$loadRegistryPackages();
					expect(result.packages).toBe([]);
					expect(result.error).toBe("");
				});
			});

		});
	}
}
