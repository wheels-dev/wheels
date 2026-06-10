/**
 * Lazy ServiceProvider lifecycle coverage.
 *
 * A "service-only" lazy package (the documented lazy use case) previously
 * never had register()/boot() invoked: variables.serviceProviders was only
 * populated by eager instantiation, and late instantiation appended to the
 * array without ever running the lifecycle — so the package's services were
 * silently missing, surfacing later as Wheels.DI.ServiceNotFound with no
 * failedPackages entry.
 *
 * Fixtures live in /wheels/tests/_assets/packages_lazy_sp:
 * - lazysvc:  lazy + provides.services hint — must join the lifecycle at boot.
 * - lazylate: lazy, no services hint — stays lazy through boot; register()/
 *             boot() must run when getPackage() instantiates it afterwards.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Lazy ServiceProvider packages", () => {

			beforeEach(() => {
				lazyFixturesPath = ExpandPath("/wheels/tests/_assets/packages_lazy_sp");
				lazyFixturesPrefix = "wheels.tests._assets.packages_lazy_sp";
			});

			it("reports lifecycle work when only lazy packages are present", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = lazyFixturesPath,
					componentPrefix = lazyFixturesPrefix
				);

				// Nothing is instantiated at discovery time...
				expect(loader.getPackages()).notToHaveKey("lazysvc");
				expect(loader.getPackages()).notToHaveKey("lazylate");
				expect(ArrayLen(loader.getServiceProviders())).toBe(0);

				// ...but the loader knows the lifecycle still has work to do,
				// so Global.cfc's gate invokes register()/boot().
				expect(loader.$hasServiceProviderWork()).toBeTrue();
			});

			it("invokes register() and boot() on a lazy package that hints services", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = lazyFixturesPath,
					componentPrefix = lazyFixturesPrefix
				);
				var fakeContainer = CreateObject(
					"component",
					"wheels.tests._assets.plugins.serviceprovider.FakeContainer"
				).init();

				loader.$invokeServiceProviderRegister(fakeContainer);
				loader.$invokeServiceProviderBoot({});

				var pkgs = loader.getPackages();
				expect(pkgs).toHaveKey("lazysvc");
				expect(pkgs.lazysvc.registerCalled).toBeTrue();
				expect(pkgs.lazysvc.bootCalled).toBeTrue();
			});

			it("leaves a lazy provider without a services hint un-instantiated through boot", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = lazyFixturesPath,
					componentPrefix = lazyFixturesPrefix
				);
				var fakeContainer = CreateObject(
					"component",
					"wheels.tests._assets.plugins.serviceprovider.FakeContainer"
				).init();

				loader.$invokeServiceProviderRegister(fakeContainer);
				loader.$invokeServiceProviderBoot({});

				// Unhinted lazy packages keep their laziness.
				expect(loader.getPackages()).notToHaveKey("lazylate");
				expect(loader.isPackageLoaded("lazylate")).toBeTrue();
			});

			it("invokes register()/boot() when an unhinted lazy provider is instantiated after boot", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = lazyFixturesPath,
					componentPrefix = lazyFixturesPrefix
				);
				var fakeContainer = CreateObject(
					"component",
					"wheels.tests._assets.plugins.serviceprovider.FakeContainer"
				).init();

				loader.$invokeServiceProviderRegister(fakeContainer);
				loader.$invokeServiceProviderBoot({});

				var pkg = loader.getPackage("lazylate");
				expect(pkg.registerCalled).toBeTrue();
				expect(pkg.bootCalled).toBeTrue();
			});

		});

	}

}
