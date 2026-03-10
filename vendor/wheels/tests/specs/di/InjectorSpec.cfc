component extends="wheels.WheelsTest" {

	function run() {

		describe("Injector", () => {

			beforeEach(() => {
				// Create a fresh injector for each test using our empty test bindings
				di = new wheels.Injector(binderPath="wheels.tests.specs.di._helpers.TestBindings");
			});

			// ===========================================================
			// Core API (backwards compatibility)
			// ===========================================================

			describe("Core API", () => {

				it("supports map().to().getInstance() fluent chain", () => {
					di.map("simpleService").to("wheels.tests.specs.di._helpers.SimpleService");
					var svc = di.getInstance("simpleService");
					expect(svc).toBeInstanceOf("wheels.tests.specs.di._helpers.SimpleService");
					expect(svc.isInitialized()).toBeTrue();
				});

				it("caches singletons across calls", () => {
					di.map("simpleService").to("wheels.tests.specs.di._helpers.SimpleService").asSingleton();
					var first = di.getInstance("simpleService");
					var second = di.getInstance("simpleService");
					expect(first).toBe(second);
				});

				it("creates new transient instances each call", () => {
					di.map("simpleService").to("wheels.tests.specs.di._helpers.SimpleService");
					var first = di.getInstance("simpleService");
					var second = di.getInstance("simpleService");
					// Both should be instances but NOT the same object reference
					expect(first.greet()).toBe("hello");
					expect(second.greet()).toBe("hello");
				});

				it("reports containsInstance correctly", () => {
					expect(di.containsInstance("simpleService")).toBeFalse();
					di.map("simpleService").to("wheels.tests.specs.di._helpers.SimpleService");
					expect(di.containsInstance("simpleService")).toBeTrue();
				});

				it("supports fluent chaining of multiple mappings", () => {
					di.map("svcA").to("wheels.tests.specs.di._helpers.SimpleService")
						.map("svcB").to("wheels.tests.specs.di._helpers.SimpleService");
					expect(di.containsInstance("svcA")).toBeTrue();
					expect(di.containsInstance("svcB")).toBeTrue();
				});

				it("throws when to() is called without map()", () => {
					expect(() => {
						di.to("wheels.tests.specs.di._helpers.SimpleService");
					}).toThrow("Wheels.Injector");
				});

			});

			// ===========================================================
			// asRequestScoped()
			// ===========================================================

			describe("asRequestScoped()", () => {

				it("marks a mapping as request-scoped", () => {
					di.map("simpleService").to("wheels.tests.specs.di._helpers.SimpleService").asRequestScoped();
					expect(di.isRequestScoped("simpleService")).toBeTrue();
					expect(di.isSingleton("simpleService")).toBeFalse();
				});

				it("caches instance in request scope", () => {
					di.map("simpleService").to("wheels.tests.specs.di._helpers.SimpleService").asRequestScoped();
					// Clear any existing request cache
					structDelete(request, "$wheelsDICache");
					var first = di.getInstance("simpleService");
					var second = di.getInstance("simpleService");
					expect(first).toBe(second);
				});

				it("uses request.$wheelsDICache for storage", () => {
					di.map("simpleService").to("wheels.tests.specs.di._helpers.SimpleService").asRequestScoped();
					structDelete(request, "$wheelsDICache");
					di.getInstance("simpleService");
					expect(structKeyExists(request, "$wheelsDICache")).toBeTrue();
					expect(structKeyExists(request["$wheelsDICache"], "simpleService")).toBeTrue();
				});

			});

			// ===========================================================
			// bind()
			// ===========================================================

			describe("bind()", () => {

				it("works as an alias for map()", () => {
					di.bind("IGreeter").to("wheels.tests.specs.di._helpers.SimpleService");
					expect(di.containsInstance("IGreeter")).toBeTrue();
					var svc = di.getInstance("IGreeter");
					expect(svc.greet()).toBe("hello");
				});

				it("supports full fluent chain with asSingleton()", () => {
					di.bind("IGreeter").to("wheels.tests.specs.di._helpers.SimpleService").asSingleton();
					expect(di.isSingleton("IGreeter")).toBeTrue();
				});

				it("supports full fluent chain with asRequestScoped()", () => {
					di.bind("IGreeter").to("wheels.tests.specs.di._helpers.SimpleService").asRequestScoped();
					expect(di.isRequestScoped("IGreeter")).toBeTrue();
				});

			});

			// ===========================================================
			// Auto-wiring
			// ===========================================================

			describe("Auto-wiring", () => {

				it("resolves init() parameters matching container mappings", () => {
					di.map("simpleService").to("wheels.tests.specs.di._helpers.SimpleService");
					di.map("dependentService").to("wheels.tests.specs.di._helpers.DependentService");
					var svc = di.getInstance("dependentService");
					expect(svc.delegateGreet()).toBe("hello");
				});

				it("auto-wired dependency is a valid instance", () => {
					di.map("simpleService").to("wheels.tests.specs.di._helpers.SimpleService");
					di.map("dependentService").to("wheels.tests.specs.di._helpers.DependentService");
					var svc = di.getInstance("dependentService");
					var inner = svc.getSimpleService();
					expect(inner).toBeInstanceOf("wheels.tests.specs.di._helpers.SimpleService");
					expect(inner.isInitialized()).toBeTrue();
				});

				it("explicit initArguments take precedence over auto-wiring", () => {
					di.map("simpleService").to("wheels.tests.specs.di._helpers.SimpleService");
					di.map("dependentService").to("wheels.tests.specs.di._helpers.DependentService");
					var manual = new wheels.tests.specs.di._helpers.SimpleService();
					var svc = di.getInstance(name="dependentService", initArguments={simpleService: manual});
					expect(svc.getSimpleService()).toBe(manual);
				});

				it("throws on circular dependency", () => {
					di.map("circularServiceA").to("wheels.tests.specs.di._helpers.CircularServiceA");
					di.map("circularServiceB").to("wheels.tests.specs.di._helpers.CircularServiceB");
					expect(() => {
						di.getInstance("circularServiceA");
					}).toThrow("Wheels.DI.CircularDependency");
				});

			});

			// ===========================================================
			// Introspection
			// ===========================================================

			describe("Introspection", () => {

				it("getMappings() returns all registered mappings", () => {
					di.map("svcA").to("wheels.tests.specs.di._helpers.SimpleService");
					di.map("svcB").to("wheels.tests.specs.di._helpers.DependentService");
					var mappings = di.getMappings();
					expect(structKeyExists(mappings, "svcA")).toBeTrue();
					expect(structKeyExists(mappings, "svcB")).toBeTrue();
				});

				it("isSingleton() returns correct state", () => {
					di.map("svcA").to("wheels.tests.specs.di._helpers.SimpleService").asSingleton();
					di.map("svcB").to("wheels.tests.specs.di._helpers.SimpleService");
					expect(di.isSingleton("svcA")).toBeTrue();
					expect(di.isSingleton("svcB")).toBeFalse();
				});

				it("isRequestScoped() returns correct state", () => {
					di.map("svcA").to("wheels.tests.specs.di._helpers.SimpleService").asRequestScoped();
					di.map("svcB").to("wheels.tests.specs.di._helpers.SimpleService");
					expect(di.isRequestScoped("svcA")).toBeTrue();
					expect(di.isRequestScoped("svcB")).toBeFalse();
				});

			});

			// ===========================================================
			// service() global helper
			// ===========================================================

			describe("service() global helper", () => {

				it("resolves a registered service", () => {
					di.map("simpleService").to("wheels.tests.specs.di._helpers.SimpleService");
					var svc = service("simpleService");
					expect(svc.greet()).toBe("hello");
				});

				it("throws ServiceNotFound for unregistered service", () => {
					expect(() => {
						service("nonExistent");
					}).toThrow("Wheels.DI.ServiceNotFound");
				});

			});

			// ===========================================================
			// inject() controller helper
			// ===========================================================

			describe("inject() controller helper", () => {

				it("stores service names in class data", () => {
					// Simulate what happens inside a controller's config()
					var classData = {services: []};
					variables.$class = classData;
					inject("myService");
					expect(variables.$class.services).toHaveLength(1);
					expect(variables.$class.services[1]).toBe("myService");
				});

				it("supports comma-delimited list", () => {
					var classData = {services: []};
					variables.$class = classData;
					inject("svcA, svcB, svcC");
					expect(variables.$class.services).toHaveLength(3);
					expect(variables.$class.services[1]).toBe("svcA");
					expect(variables.$class.services[2]).toBe("svcB");
					expect(variables.$class.services[3]).toBe("svcC");
				});

				it("deduplicates repeated names", () => {
					var classData = {services: []};
					variables.$class = classData;
					inject("myService");
					inject("myService");
					expect(variables.$class.services).toHaveLength(1);
				});

				it("injectedServices() returns declared names", () => {
					var classData = {services: ["svcA", "svcB"]};
					variables.$class = classData;
					var names = injectedServices();
					expect(names).toHaveLength(2);
				});

			});

		});

	}

}
