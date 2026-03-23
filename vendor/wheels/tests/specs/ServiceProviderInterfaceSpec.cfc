component extends="wheels.WheelsTest" {

	function run() {

		describe("ServiceProviderInterface", () => {

			it("can be implemented by a plugin component", () => {
				var provider = CreateObject("component", "wheels.tests._assets.plugins.serviceprovider.TestServiceProvider.TestServiceProvider").init()

				expect(provider).toHaveKey("register")
				expect(provider).toHaveKey("boot")
			})

			it("has a register method that accepts a container argument", () => {
				var provider = CreateObject("component", "wheels.tests._assets.plugins.serviceprovider.TestServiceProvider.TestServiceProvider").init()
				var fakeContainer = {map: true, bind: true}

				provider.register(container=fakeContainer)

				expect(provider.registerCalled).toBeTrue()
				expect(provider.containerReceived).toBe(fakeContainer)
			})

			it("has a boot method that accepts an app struct argument", () => {
				var provider = CreateObject("component", "wheels.tests._assets.plugins.serviceprovider.TestServiceProvider.TestServiceProvider").init()
				var fakeApp = {environment: "testing", version: "3.0.0"}

				provider.boot(app=fakeApp)

				expect(provider.bootCalled).toBeTrue()
				expect(provider.appReceived).toBe(fakeApp)
			})

			it("supports the full register-then-boot lifecycle", () => {
				var provider = CreateObject("component", "wheels.tests._assets.plugins.serviceprovider.TestServiceProvider.TestServiceProvider").init()
				var fakeContainer = {map: true}
				var fakeApp = {environment: "testing"}

				provider.register(container=fakeContainer)
				provider.boot(app=fakeApp)

				expect(provider.registerCalled).toBeTrue()
				expect(provider.bootCalled).toBeTrue()
			})

			it("can be detected via metadata on implementing components", () => {
				var provider = CreateObject("component", "wheels.tests._assets.plugins.serviceprovider.TestServiceProvider.TestServiceProvider").init()
				var meta = GetMetadata(provider)

				expect(meta).toHaveKey("implements")
				expect(meta.implements).toBeStruct()
				expect(meta.implements).toHaveKey("wheels.ServiceProviderInterface")
			})

		})

	}

}
