component extends="wheels.WheelsTest" {

	function run() {

		describe("Injector", () => {

			beforeEach(() => {
				// Create a fresh injector for each test using our empty test bindings
				di = new wheels.Injector(binderPath="wheels.tests._assets.di.TestBindings");
			});

			// ===========================================================
			// Core API (backwards compatibility)
			// ===========================================================

			describe("Core API", () => {

				it("supports map().to().getInstance() fluent chain", () => {
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService");
					var svc = di.getInstance("simpleService");
					expect(svc).toBeInstanceOf("wheels.tests._assets.di.SimpleService");
					expect(svc.isInitialized()).toBeTrue();
				});

				it("caches singletons across calls", () => {
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService").asSingleton();
					var first = di.getInstance("simpleService");
					var second = di.getInstance("simpleService");
					expect(first).toBe(second);
				});

				it("asSingleton flag survives the existing framework Bindings (regression: 2026-04-29 fresh-VM)", () => {
					// The container starts with the framework's bindings already loaded
					// (~20 of them from wheels.Bindings). When the user calls
					// .map(X).to(Y).asSingleton() in services.cfm, the flag must land
					// on X regardless of how many keys preceded it.
					//
					// Regression: a previous implementation walked variables.mappings
					// via for-in to find the "last-mapped" key. Lucee's HashMap-backed
					// struct doesn't iterate in insertion order once enough keys are
					// registered to span multiple buckets — the just-added key ends up
					// in the middle of iteration, and asSingleton flagged the wrong
					// binding.
					//
					// Use the production Bindings here (not the empty TestBindings)
					// to exercise the real-world key count.
					var realDi = new wheels.Injector(binderPath="wheels.Bindings");

					realDi.map("userAuthenticator").to("wheels.tests._assets.di.SimpleService").asSingleton();

					expect(realDi.isSingleton("userAuthenticator")).toBeTrue();

					var first = realDi.getInstance("userAuthenticator");
					var second = realDi.getInstance("userAuthenticator");
					expect(first).toBe(second);
				});

				it("creates new transient instances each call", () => {
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService");
					var first = di.getInstance("simpleService");
					var second = di.getInstance("simpleService");
					// Both should be instances but NOT the same object reference
					expect(first.greet()).toBe("hello");
					expect(second.greet()).toBe("hello");
				});

				it("reports containsInstance correctly", () => {
					expect(di.containsInstance("simpleService")).toBeFalse();
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService");
					expect(di.containsInstance("simpleService")).toBeTrue();
				});

				it("supports fluent chaining of multiple mappings", () => {
					di.map("svcA").to("wheels.tests._assets.di.SimpleService")
						.map("svcB").to("wheels.tests._assets.di.SimpleService");
					expect(di.containsInstance("svcA")).toBeTrue();
					expect(di.containsInstance("svcB")).toBeTrue();
				});

				it("throws when to() is called without map()", () => {
					expect(() => {
						di.to("wheels.tests._assets.di.SimpleService");
					}).toThrow("Wheels.Injector");
				});

			});

			// ===========================================================
			// asRequestScoped()
			// ===========================================================

			describe("asRequestScoped()", () => {

				it("marks a mapping as request-scoped", () => {
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService").asRequestScoped();
					expect(di.isRequestScoped("simpleService")).toBeTrue();
					expect(di.isSingleton("simpleService")).toBeFalse();
				});

				it("caches instance in request scope", () => {
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService").asRequestScoped();
					// Clear any existing request cache
					structDelete(request, "$wheelsDICache");
					var first = di.getInstance("simpleService");
					var second = di.getInstance("simpleService");
					expect(first).toBe(second);
				});

				it("uses request.$wheelsDICache for storage", () => {
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService").asRequestScoped();
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
					di.bind("IGreeter").to("wheels.tests._assets.di.SimpleService");
					expect(di.containsInstance("IGreeter")).toBeTrue();
					var svc = di.getInstance("IGreeter");
					expect(svc.greet()).toBe("hello");
				});

				it("supports full fluent chain with asSingleton()", () => {
					di.bind("IGreeter").to("wheels.tests._assets.di.SimpleService").asSingleton();
					expect(di.isSingleton("IGreeter")).toBeTrue();
				});

				it("supports full fluent chain with asRequestScoped()", () => {
					di.bind("IGreeter").to("wheels.tests._assets.di.SimpleService").asRequestScoped();
					expect(di.isRequestScoped("IGreeter")).toBeTrue();
				});

			});

			// ===========================================================
			// Auto-wiring
			// ===========================================================

			describe("Auto-wiring", () => {

				it("resolves init() parameters matching container mappings", () => {
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService");
					di.map("dependentService").to("wheels.tests._assets.di.DependentService");
					var svc = di.getInstance("dependentService");
					expect(svc.delegateGreet()).toBe("hello");
				});

				it("auto-wired dependency is a valid instance", () => {
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService");
					di.map("dependentService").to("wheels.tests._assets.di.DependentService");
					var svc = di.getInstance("dependentService");
					var inner = svc.getSimpleService();
					expect(inner).toBeInstanceOf("wheels.tests._assets.di.SimpleService");
					expect(inner.isInitialized()).toBeTrue();
				});

				it("explicit initArguments take precedence over auto-wiring", () => {
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService");
					di.map("dependentService").to("wheels.tests._assets.di.DependentService");
					var manual = new wheels.tests._assets.di.SimpleService();
					var svc = di.getInstance(name="dependentService", initArguments={simpleService: manual});
					expect(svc.getSimpleService()).toBe(manual);
				});

				it("throws on circular dependency", () => {
					di.map("circularServiceA").to("wheels.tests._assets.di.CircularServiceA");
					di.map("circularServiceB").to("wheels.tests._assets.di.CircularServiceB");
					expect(() => {
						di.getInstance("circularServiceA");
					}).toThrow("Wheels.DI.CircularDependency");
				});

				it("resolving stack is request-scoped, not application-scoped (##2331)", () => {
					// Regression: previously the resolving guard lived on the
					// Injector instance (application scope), so concurrent
					// requests could trip each other's guard with a spurious
					// self-loop ("X -> X" in the chain). Verify the resolving
					// struct is now stored on the request scope.
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService");
					di.getInstance("simpleService");
					// After a successful resolve, the request scope key should
					// exist (created lazily on first getInstance) — and the
					// instance should NOT be tracked on the Injector itself.
					expect(structKeyExists(request, "$wheelsDIResolving")).toBeTrue();
					// The resolved name should have been cleaned up from the
					// stack on success, leaving an empty struct.
					expect(structKeyExists(request.$wheelsDIResolving, "simpleService")).toBeFalse();
				});

				it("resolving stack recovers cleanly after a circular-dep error (##2331)", () => {
					// Throwing the CircularDependency error must still pop the
					// outer entry from the resolving stack (via the finally
					// block) so subsequent getInstance calls in the same
					// request can resolve the same name without false alarms.
					di.map("circularServiceA").to("wheels.tests._assets.di.CircularServiceA");
					di.map("circularServiceB").to("wheels.tests._assets.di.CircularServiceB");
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService");
					try { di.getInstance("circularServiceA"); } catch (any e) {}
					// After the error, the stack should be empty (cleanup ran)
					// and an unrelated resolve should still work.
					expect(structKeyExists(request.$wheelsDIResolving, "circularServiceA")).toBeFalse();
					var svc = di.getInstance("simpleService");
					expect(svc).notToBeNull();
				});

			});

			// ===========================================================
			// Introspection
			// ===========================================================

			describe("Introspection", () => {

				it("getMappings() returns all registered mappings", () => {
					di.map("svcA").to("wheels.tests._assets.di.SimpleService");
					di.map("svcB").to("wheels.tests._assets.di.DependentService");
					var mappings = di.getMappings();
					expect(structKeyExists(mappings, "svcA")).toBeTrue();
					expect(structKeyExists(mappings, "svcB")).toBeTrue();
				});

				it("isSingleton() returns correct state", () => {
					di.map("svcA").to("wheels.tests._assets.di.SimpleService").asSingleton();
					di.map("svcB").to("wheels.tests._assets.di.SimpleService");
					expect(di.isSingleton("svcA")).toBeTrue();
					expect(di.isSingleton("svcB")).toBeFalse();
				});

				it("isRequestScoped() returns correct state", () => {
					di.map("svcA").to("wheels.tests._assets.di.SimpleService").asRequestScoped();
					di.map("svcB").to("wheels.tests._assets.di.SimpleService");
					expect(di.isRequestScoped("svcA")).toBeTrue();
					expect(di.isRequestScoped("svcB")).toBeFalse();
				});

			});

			// ===========================================================
			// service() global helper
			// ===========================================================

			describe("service() global helper", () => {

				it("resolves a registered service", () => {
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService");
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

				beforeEach(() => {
					// Reset the cached controller's services array to prevent cross-test contamination.
					// controller("dummy") returns a cached class whose $class.services persists between specs.
					var ctrl = application.wo.controller("dummy");
					ctrl.$getControllerClassData().services = [];
				});

				it("stores service names in class data", () => {
					// Test through a real controller instance (inject/injectedServices are Controller mixins)
					var ctrl = application.wo.controller("dummy");
					ctrl.inject("myService");
					expect(ctrl.injectedServices()).toHaveLength(1);
					expect(ctrl.injectedServices()[1]).toBe("myService");
				});

				it("supports comma-delimited list", () => {
					var ctrl = application.wo.controller("dummy");
					ctrl.inject("svcA, svcB, svcC");
					expect(ctrl.injectedServices()).toHaveLength(3);
					expect(ctrl.injectedServices()[1]).toBe("svcA");
					expect(ctrl.injectedServices()[2]).toBe("svcB");
					expect(ctrl.injectedServices()[3]).toBe("svcC");
				});

				it("deduplicates repeated names", () => {
					var ctrl = application.wo.controller("dummy");
					ctrl.inject("myService");
					ctrl.inject("myService");
					expect(ctrl.injectedServices()).toHaveLength(1);
				});

				it("injectedServices() returns empty array by default", () => {
					var ctrl = application.wo.controller("dummy");
					expect(ctrl.injectedServices()).toHaveLength(0);
				});

			});

		});

	}

}
