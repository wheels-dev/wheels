component extends="wheels.WheelsTest" {

	function run() {

		describe("ServiceProvider lifecycle isolation", () => {

			beforeEach(() => {
				spFixturesPath = ExpandPath("/wheels/tests/_assets/packages_sp");
				spPrefix = "wheels.tests._assets.packages_sp";
			});

			it("isolates a register() failure and continues with remaining providers", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = spFixturesPath,
					componentPrefix = spPrefix
				);
				var fakeContainer = CreateObject(
					"component",
					"wheels.tests._assets.plugins.serviceprovider.FakeContainer"
				).init();

				// Must complete without throwing even though failregister's register() throws.
				loader.$invokeServiceProviderRegister(fakeContainer);

				// The healthy sibling provider still registered.
				var pkgs = loader.getPackages();
				expect(pkgs).toHaveKey("goodsp");
				expect(pkgs.goodsp.registerCalled).toBeTrue();
				expect(pkgs.goodsp.containerReceived).toBe(fakeContainer);

				// The failure is recorded with the standard {name, error, detail} shape.
				var failed = loader.getFailedPackages();
				var foundFailure = false;
				for (var f in failed) {
					if (f.name == "failregister") {
						foundFailure = true;
						expect(f.error).toInclude("register()");
						expect(f).toHaveKey("detail");
					}
				}
				expect(foundFailure).toBeTrue();

				// The failing provider is rolled back: dropped from both the
				// service-provider registry and the loaded-packages map.
				expect(ArrayFind(loader.getServiceProviders(), "failregister")).toBe(0);
				expect(loader.getPackages()).notToHaveKey("failregister");
			});

			it("skips boot() for a provider whose register() failed", () => {
				StructDelete(request, "$spFailregisterBootCalled");
				var loader = new wheels.PackageLoader(
					vendorPath = spFixturesPath,
					componentPrefix = spPrefix
				);
				var fakeContainer = CreateObject(
					"component",
					"wheels.tests._assets.plugins.serviceprovider.FakeContainer"
				).init();

				loader.$invokeServiceProviderRegister(fakeContainer);
				loader.$invokeServiceProviderBoot({});

				// failregister was rolled back at register time, so its boot() never ran.
				expect(StructKeyExists(request, "$spFailregisterBootCalled")).toBeFalse();
				// The healthy provider still booted.
				expect(loader.getPackages().goodsp.bootCalled).toBeTrue();
			});

			it("isolates a boot() failure and continues with remaining providers", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = spFixturesPath,
					componentPrefix = spPrefix
				);
				var fakeContainer = CreateObject(
					"component",
					"wheels.tests._assets.plugins.serviceprovider.FakeContainer"
				).init();

				loader.$invokeServiceProviderRegister(fakeContainer);

				// Must complete without throwing even though failboot's boot() throws.
				loader.$invokeServiceProviderBoot({});

				var failed = loader.getFailedPackages();
				var foundFailure = false;
				for (var f in failed) {
					if (f.name == "failboot") {
						foundFailure = true;
						expect(f.error).toInclude("boot()");
						expect(f).toHaveKey("detail");
					}
				}
				expect(foundFailure).toBeTrue();

				// The healthy provider still booted (presence asserted, not order —
				// ModuleGraph order for independent packages is not contractual).
				expect(loader.getPackages().goodsp.bootCalled).toBeTrue();
				// The boot-failing provider is rolled back from the registries.
				expect(ArrayFind(loader.getServiceProviders(), "failboot")).toBe(0);
				expect(loader.getPackages()).notToHaveKey("failboot");
			});

		});

	}

}
