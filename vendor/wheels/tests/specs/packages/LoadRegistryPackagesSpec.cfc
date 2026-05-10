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
				try {
					fn();
				} finally {
					application.wheels.environment = prior;
				}
			};

			it("returns empty packages and no error when environment is production", () => {
				$withEnv("production", () => {
					var pub = $newPublic();
					var result = pub.$loadRegistryPackages(registry = $fakeRegistry(packages = [{name = "should-not-appear"}]));
					expect(result.packages).toBe([]);
					expect(result.error).toBe("");
				});
			});

			it("returns packages from the registry in development", () => {
				$withEnv("development", () => {
					var pub = $newPublic();
					var result = pub.$loadRegistryPackages(
						registry = $fakeRegistry(
							packages = [
								{name = "wheels-sentry", description = "x", tags = [], homepage = "", latestVersion = "1.0.0"}
							]
						)
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
							registry = $fakeRegistry(throwType = "java.lang.NullPointerException", throwMessage = "npe from listAll")
						);
					} catch ("java.lang.NullPointerException" e) {
						thrown = e.message;
					}
					expect(thrown).toBe("npe from listAll");
				});
			});

			it("ships a Registry component the debug panel can use without the CLI on disk (##2530)", () => {
				// Regression: prior behavior gated $loadRegistryPackages on
				// FileExists("/cli/lucli/services/packages/Registry.cfc"),
				// which silently disabled the registry feature for fresh apps
				// generated with `wheels new` (they don't ship cli/). The
				// fix bundles a Registry component with the framework so the
				// debug panel works in plain user apps.
				expect(FileExists(ExpandPath("/wheels/services/packages/Registry.cfc"))).toBeTrue(
					"Expected vendor/wheels/services/packages/Registry.cfc to ship with "
					& "the framework so the debug panel can browse the registry without "
					& "depending on the CLI being present on disk. See issue ##2530."
				);
				expect(FileExists(ExpandPath("/wheels/services/packages/HttpClient.cfc"))).toBeTrue();
				expect(FileExists(ExpandPath("/wheels/services/packages/ManifestCache.cfc"))).toBeTrue();
				// Instantiable from a vanilla classpath.
				var reg = new wheels.services.packages.Registry();
				expect(IsObject(reg)).toBeTrue();
				expect(reg.registryRepo()).toBe("wheels-dev/wheels-packages");
			});
		});
	}

}
