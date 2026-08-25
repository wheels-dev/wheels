/**
 * Hardener proofs for Injector desk IDs S1–S10. Desk IDs stay locked.
 *
 * Flipped: S2 rebind reset, S3 fail-loud / flag the new key, S7 Duplicate copy.
 * Unchanged on develop: S1, S4, S5, S6, S8, S9, S10. S4 stays dotted-path fallback.
 *
 * Directory-scoped so `wheels test --core --ci --filter=injector` discovers
 * this folder (a single-file directory= scope finds 0 bundles).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Injector hardener S1–S10", () => {

			beforeEach(() => {
				di = new wheels.Injector(binderPath="wheels.tests._assets.di.TestBindings");
			});

			afterEach(() => {
				structDelete(request, "$wheelsDICache");
				structDelete(request, "$wheelsDIResolving");
				structDelete(request, "$wheelsDICompleteLog");
			});

			describe("S1 transient identity", () => {

				it("S1: two transient resolutions of the same mapping are distinct instances", () => {
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService");
					var first = di.getInstance("simpleService");
					first.setMarker("first");
					var second = di.getInstance("simpleService");
					expect(first.greet()).toBe("hello");
					expect(second.greet()).toBe("hello");
					expect(first.getMarker()).toBe("first");
					expect(second.getMarker()).toBe("");
				});

			});

			describe("S2 rebind resets flags and drops request cache", () => {

				it("S2: rebind overwrites the path and resets the singleton flag", () => {
					di.map("rebind").to("wheels.tests._assets.di.SimpleService").asSingleton();
					expect(di.isSingleton("rebind")).toBeTrue();
					di.map("rebind").to("wheels.tests._assets.di.OptionalDependentService");
					expect(di.getMappings()["rebind"]).toBe("wheels.tests._assets.di.OptionalDependentService");
					expect(di.isSingleton("rebind")).toBeFalse();
					expect(di.isRequestScoped("rebind")).toBeFalse();
					var after = di.getInstance("rebind");
					expect(after.hasDependency()).toBeFalse();
				});

				it("S2: rebind resets the request-scoped flag and drops request.$wheelsDICache", () => {
					di.map("rebindReq").to("wheels.tests._assets.di.SimpleService").asRequestScoped();
					structDelete(request, "$wheelsDICache");
					var first = di.getInstance("rebindReq");
					first.setMarker("cached");
					expect(structKeyExists(request, "$wheelsDICache")).toBeTrue();
					expect(structKeyExists(request["$wheelsDICache"], "rebindReq")).toBeTrue();
					di.map("rebindReq").to("wheels.tests._assets.di.OptionalDependentService");
					expect(di.isRequestScoped("rebindReq")).toBeFalse();
					expect(di.isSingleton("rebindReq")).toBeFalse();
					expect(di.getMappings()["rebindReq"]).toBe("wheels.tests._assets.di.OptionalDependentService");
					expect(structKeyExists(request, "$wheelsDICache")).toBeFalse();
				});

				it("S2: singleton rebind structDeletes request.$wheelsDICache including unrelated keys", () => {
					request["$wheelsDICache"] = {sentinel = true};
					di.map("rebindSolo").to("wheels.tests._assets.di.SimpleService").asSingleton();
					expect(structKeyExists(request, "$wheelsDICache")).toBeTrue();
					expect(request["$wheelsDICache"].sentinel).toBeTrue();
					di.getInstance("rebindSolo");
					di.map("rebindSolo").to("wheels.tests._assets.di.OptionalDependentService");
					expect(structKeyExists(request, "$wheelsDICache")).toBeFalse();
					expect(di.isSingleton("rebindSolo")).toBeFalse();
				});

				it("S2: first bind of a new name does not drop request.$wheelsDICache", () => {
					request["$wheelsDICache"] = {sentinel = true};
					di.map("firstBind").to("wheels.tests._assets.di.SimpleService");
					expect(structKeyExists(request, "$wheelsDICache")).toBeTrue();
					expect(request["$wheelsDICache"].sentinel).toBeTrue();
					expect(di.isSingleton("firstBind")).toBeFalse();
				});

				it("S2: rebind of one name does not reset an unrelated mapping's flags", () => {
					di.map("keepSolo").to("wheels.tests._assets.di.SimpleService").asSingleton();
					di.map("keepReq").to("wheels.tests._assets.di.SimpleService").asRequestScoped();
					di.map("rebindOther").to("wheels.tests._assets.di.SimpleService").asSingleton();
					expect(di.isSingleton("keepSolo")).toBeTrue();
					expect(di.isRequestScoped("keepReq")).toBeTrue();
					di.map("rebindOther").to("wheels.tests._assets.di.OptionalDependentService");
					expect(di.isSingleton("rebindOther")).toBeFalse();
					expect(di.isSingleton("keepSolo")).toBeTrue();
					expect(di.isRequestScoped("keepReq")).toBeTrue();
					expect(di.isSingleton("keepReq")).toBeFalse();
				});

				it("S2: same-path rebind still resets flags until asSingleton is called again", () => {
					di.map("samePath").to("wheels.tests._assets.di.SimpleService").asSingleton();
					var before = di.getInstance("samePath");
					before.setMarker("stable");
					di.map("samePath").to("wheels.tests._assets.di.SimpleService");
					expect(di.isSingleton("samePath")).toBeFalse();
					var mid = di.getInstance("samePath");
					expect(mid.getMarker()).toBe("");
					di.map("samePath").to("wheels.tests._assets.di.SimpleService").asSingleton();
					expect(di.isSingleton("samePath")).toBeTrue();
				});

			});

			describe("S3 asSingleton / asRequestScoped fail loud and flag the new key", () => {

				it("S3: asSingleton throws Wheels.Injector when lastMappedName is empty", () => {
					var state = {type = ""};
					try {
						di.asSingleton();
					} catch (any e) {
						state.type = e.type;
					}
					expect(state.type).toBe("Wheels.Injector");
					expect(di.isSingleton("anything")).toBeFalse();
					expect(structCount(di.getMappings())).toBe(0);
				});

				it("S3: asRequestScoped throws Wheels.Injector when lastMappedName is empty", () => {
					var state = {type = ""};
					try {
						di.asRequestScoped();
					} catch (any e) {
						state.type = e.type;
					}
					expect(state.type).toBe("Wheels.Injector");
					expect(di.isRequestScoped("anything")).toBeFalse();
					expect(structCount(di.getMappings())).toBe(0);
				});

				it("S3: empty lastMappedName throw type matches to() without map()", () => {
					var stateBare = {type = ""};
					try {
						di.to("wheels.tests._assets.di.SimpleService");
					} catch (any e) {
						stateBare.type = e.type;
					}
					var stateSolo = {type = ""};
					try {
						di.asSingleton();
					} catch (any e) {
						stateSolo.type = e.type;
					}
					var stateReq = {type = ""};
					try {
						di.asRequestScoped();
					} catch (any e) {
						stateReq.type = e.type;
					}
					expect(stateBare.type).toBe("Wheels.Injector");
					expect(stateSolo.type).toBe("Wheels.Injector");
					expect(stateReq.type).toBe("Wheels.Injector");
					expect(stateSolo.type).toBe(stateBare.type);
					expect(stateReq.type).toBe(stateBare.type);
				});

				it("S3: asSingleton after map() but before to() flags the in-progress name", () => {
					di.map("incomplete");
					di.asSingleton();
					expect(di.isSingleton("incomplete")).toBeTrue();
					di.to("wheels.tests._assets.di.SimpleService");
					expect(di.containsInstance("incomplete")).toBeTrue();
					expect(di.isSingleton("incomplete")).toBeTrue();
					var first = di.getInstance("incomplete");
					first.setMarker("incomplete");
					expect(di.getInstance("incomplete").getMarker()).toBe("incomplete");
				});

				it("S3: map(b).asSingleton().to(...) flags b, not the previous key", () => {
					di.map("previous").to("wheels.tests._assets.di.SimpleService");
					di.map("b").asSingleton().to("wheels.tests._assets.di.SimpleService");
					expect(di.isSingleton("previous")).toBeFalse();
					expect(di.isSingleton("b")).toBeTrue();
					var prev = di.getInstance("previous");
					prev.setMarker("prev");
					expect(di.getInstance("previous").getMarker()).toBe("");
					var bee = di.getInstance("b");
					bee.setMarker("bee");
					expect(di.getInstance("b").getMarker()).toBe("bee");
				});

				it("S3: map(b).asRequestScoped().to(...) flags b, not the previous key", () => {
					di.map("previousReq").to("wheels.tests._assets.di.SimpleService");
					di.map("bReq").asRequestScoped().to("wheels.tests._assets.di.SimpleService");
					expect(di.isRequestScoped("previousReq")).toBeFalse();
					expect(di.isRequestScoped("bReq")).toBeTrue();
					expect(di.isSingleton("previousReq")).toBeFalse();
					expect(di.isSingleton("bReq")).toBeFalse();
				});

				it("S3: map(b).asSingleton().to(...) on a fresh injector flags b when lastMappedName is empty", () => {
					di.map("bFresh").asSingleton().to("wheels.tests._assets.di.SimpleService");
					expect(di.isSingleton("bFresh")).toBeTrue();
					expect(di.isRequestScoped("bFresh")).toBeFalse();
					var first = di.getInstance("bFresh");
					first.setMarker("fresh");
					expect(di.getInstance("bFresh").getMarker()).toBe("fresh");
				});

			});

			describe("S4 unmapped getInstance is dotted-path fallback", () => {

				it("S4: unmapped getInstance treats the name as a dotted component path", () => {
					expect(di.containsInstance("wheels.tests._assets.di.SimpleService")).toBeFalse();
					var svc = di.getInstance("wheels.tests._assets.di.SimpleService");
					expect(svc).toBeInstanceOf("wheels.tests._assets.di.SimpleService");
					expect(svc.greet()).toBe("hello");
					expect(svc.isInitialized()).toBeTrue();
				});

				it("S4: unmapped getInstance does not throw Wheels.DI.ServiceNotFound", () => {
					var state = {type = ""};
					try {
						di.getInstance("wheels.tests._assets.di.SimpleService");
					} catch (any e) {
						state.type = e.type;
					}
					expect(state.type).toBe("");
				});

				it("S4: an unknown dotted path does not become Wheels.DI.ServiceNotFound", () => {
					var state = {type = ""};
					try {
						di.getInstance("wheels.tests._assets.di.DoesNotExistService");
					} catch (any e) {
						state.type = e.type;
					}
					expect(state.type).notToBe("");
					expect(state.type).notToBe("Wheels.DI.ServiceNotFound");
					expect(state.type).notToBe("Wheels.ServiceNotFound");
				});

			});

			describe("S5 circular-recovery catch asserts the circular throw", () => {

				it("S5: circular-recovery catch(any) records Wheels.DI.CircularDependency then recovers", () => {
					di.map("circularServiceA").to("wheels.tests._assets.di.CircularServiceA");
					di.map("circularServiceB").to("wheels.tests._assets.di.CircularServiceB");
					di.map("simpleService").to("wheels.tests._assets.di.SimpleService");
					var state = {type = ""};
					try {
						di.getInstance("circularServiceA");
					} catch (any e) {
						state.type = e.type;
					}
					expect(state.type).toBe("Wheels.DI.CircularDependency");
					expect(structKeyExists(request.$wheelsDIResolving, "circularServiceA")).toBeFalse();
					var svc = di.getInstance("simpleService");
					expect(svc.greet()).toBe("hello");
				});

			});

			describe("S6 interface resolve-all skips missing keys", () => {

				it("S6: resolve-all skips unmapped names and still resolves present ones", () => {
					di.map("presentBinding").to("wheels.tests._assets.di.SimpleService");
					var names = ["presentBinding", "missingBindingThatIsNotMapped"];
					var result = {resolved = 0, skipped = 0};
					for (var name in names) {
						if (di.containsInstance(name)) {
							di.getInstance(name);
							result.resolved = result.resolved + 1;
						} else {
							result.skipped = result.skipped + 1;
						}
					}
					expect(result.resolved).toBe(1);
					expect(result.skipped).toBe(1);
					expect(di.containsInstance("missingBindingThatIsNotMapped")).toBeFalse();
				});

				it("S6: production Bindings resolve-all skips a name that is not mapped", () => {
					var realDi = new wheels.Injector(binderPath="wheels.Bindings");
					var names = ["ModelFinderInterface", "InjectorInterfaceHardenerMissingKey"];
					var result = {resolved = 0, skipped = 0};
					for (var name in names) {
						if (realDi.containsInstance(name)) {
							realDi.getInstance(name);
							result.resolved = result.resolved + 1;
						} else {
							result.skipped = result.skipped + 1;
						}
					}
					expect(result.resolved).toBe(1);
					expect(result.skipped).toBe(1);
					expect(realDi.containsInstance("InjectorInterfaceHardenerMissingKey")).toBeFalse();
				});

			});

			describe("S7 getMappings returns a Duplicate copy", () => {

				it("S7: mutating the struct returned by getMappings() does not mutate the container", () => {
					di.map("live").to("wheels.tests._assets.di.SimpleService");
					var mappings = di.getMappings();
					mappings["injectedByTest"] = "should-not-mutate-live";
					expect(di.containsInstance("injectedByTest")).toBeFalse();
					expect(structKeyExists(di.getMappings(), "injectedByTest")).toBeFalse();
					expect(di.getMappings()["live"]).toBe("wheels.tests._assets.di.SimpleService");
				});

				it("S7: a later map().to() is not visible on a previously returned getMappings() struct", () => {
					var mappings = di.getMappings();
					expect(structCount(mappings)).toBe(0);
					di.map("later").to("wheels.tests._assets.di.SimpleService");
					expect(structKeyExists(mappings, "later")).toBeFalse();
					expect(structCount(mappings)).toBe(0);
					expect(di.containsInstance("later")).toBeTrue();
					expect(di.getMappings()["later"]).toBe("wheels.tests._assets.di.SimpleService");
				});

				it("S7: deleting or overwriting a key on the copy leaves the live mapping", () => {
					di.map("keep").to("wheels.tests._assets.di.SimpleService");
					var mappings = di.getMappings();
					mappings["keep"] = "overwritten-on-copy";
					structDelete(mappings, "keep");
					expect(di.containsInstance("keep")).toBeTrue();
					expect(di.getMappings()["keep"]).toBe("wheels.tests._assets.di.SimpleService");
					expect(structKeyExists(mappings, "keep")).toBeFalse();
				});

			});

			describe("S8 onDIcomplete hook", () => {

				it("S8: onDIcomplete is invoked exactly once on the constructed instance", () => {
					structDelete(request, "$wheelsDICompleteLog");
					di.map("hook").to("wheels.tests._assets.di.LifecycleHookService");
					var svc = di.getInstance("hook");
					expect(svc.isInitialized()).toBeTrue();
					expect(svc.getCompleteCount()).toBe(1);
					expect(arrayLen(request.$wheelsDICompleteLog)).toBe(1);
					expect(request.$wheelsDICompleteLog[1]).toBe(svc);
					expect(request.$wheelsDICompleteLog[1].getCompleteCount()).toBe(1);
				});

				it("S8: a singleton cache hit does not invoke onDIcomplete a second time", () => {
					structDelete(request, "$wheelsDICompleteLog");
					di.map("hook").to("wheels.tests._assets.di.LifecycleHookService").asSingleton();
					var first = di.getInstance("hook");
					var second = di.getInstance("hook");
					expect(first.getCompleteCount()).toBe(1);
					expect(second.getCompleteCount()).toBe(1);
					expect(arrayLen(request.$wheelsDICompleteLog)).toBe(1);
				});

				it("S8: each transient resolution invokes onDIcomplete once on that instance", () => {
					structDelete(request, "$wheelsDICompleteLog");
					di.map("hook").to("wheels.tests._assets.di.LifecycleHookService");
					var first = di.getInstance("hook");
					var second = di.getInstance("hook");
					expect(first.getCompleteCount()).toBe(1);
					expect(second.getCompleteCount()).toBe(1);
					expect(arrayLen(request.$wheelsDICompleteLog)).toBe(2);
				});

			});

			describe("S9 empty vs whitespace map() name", () => {

				it("S9: map empty string then to() throws Wheels.Injector, same type as to() without map()", () => {
					var stateBare = {type = ""};
					try {
						di.to("wheels.tests._assets.di.SimpleService");
					} catch (any e) {
						stateBare.type = e.type;
					}
					var stateEmpty = {type = ""};
					try {
						di.map("").to("wheels.tests._assets.di.SimpleService");
					} catch (any e) {
						stateEmpty.type = e.type;
					}
					expect(stateBare.type).toBe("Wheels.Injector");
					expect(stateEmpty.type).toBe("Wheels.Injector");
					expect(stateEmpty.type).toBe(stateBare.type);
				});

				it("S9: map of a single space accepts that whitespace name", () => {
					di.map(" ").to("wheels.tests._assets.di.SimpleService");
					expect(di.containsInstance(" ")).toBeTrue();
					var svc = di.getInstance(" ");
					expect(svc.greet()).toBe("hello");
				});

			});

			describe("S10 singleton wins when both flags are set", () => {

				it("S10: asSingleton().asRequestScoped() caches on the singleton, not request.$wheelsDICache", () => {
					structDelete(request, "$wheelsDICache");
					di.map("both").to("wheels.tests._assets.di.SimpleService").asSingleton().asRequestScoped();
					expect(di.isSingleton("both")).toBeTrue();
					expect(di.isRequestScoped("both")).toBeTrue();
					var first = di.getInstance("both");
					first.setMarker("singleton-wins");
					var second = di.getInstance("both");
					expect(second.getMarker()).toBe("singleton-wins");
					expect(
						structKeyExists(request, "$wheelsDICache") && structKeyExists(request["$wheelsDICache"], "both")
					).toBeFalse();
				});

				it("S10: asRequestScoped().asSingleton() still prefers the singleton cache", () => {
					structDelete(request, "$wheelsDICache");
					di.map("bothOrder").to("wheels.tests._assets.di.SimpleService").asRequestScoped().asSingleton();
					expect(di.isSingleton("bothOrder")).toBeTrue();
					expect(di.isRequestScoped("bothOrder")).toBeTrue();
					var first = di.getInstance("bothOrder");
					first.setMarker("order-independent");
					var second = di.getInstance("bothOrder");
					expect(second.getMarker()).toBe("order-independent");
					expect(
						structKeyExists(request, "$wheelsDICache") && structKeyExists(request["$wheelsDICache"], "bothOrder")
					).toBeFalse();
				});

			});

		});

	}

}
