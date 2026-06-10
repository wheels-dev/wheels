component extends="wheels.WheelsTest" {

	function run() {

		describe("ModuleGraph", () => {

			beforeEach(() => {
				graph = new wheels.ModuleGraph();
			});

			describe("resolve() with no dependencies", () => {

				it("returns all packages in load order when no requires/replaces/suggests", () => {
					var manifests = {
						"pkgA": {name: "wheels-pkgA", version: "1.0.0"},
						"pkgB": {name: "wheels-pkgB", version: "2.0.0"},
						"pkgC": {name: "wheels-pkgC", version: "1.5.0"}
					};
					var result = graph.resolve(manifests);

					expect(ArrayLen(result.loadOrder)).toBe(3);
					expect(StructIsEmpty(result.excluded)).toBeTrue();
					expect(ArrayLen(result.errors)).toBe(0);
				});

				it("returns empty results for empty manifests", () => {
					var result = graph.resolve({});
					expect(ArrayLen(result.loadOrder)).toBe(0);
					expect(ArrayLen(result.errors)).toBe(0);
				});

			});

			describe("resolve() with requires", () => {

				it("orders dependencies before dependents", () => {
					var manifests = {
						"depA": {
							name: "wheels-depA", version: "1.0.0",
							requires: {"wheels-depB": ">=1.0.0"}
						},
						"depB": {name: "wheels-depB", version: "2.0.0"}
					};
					var result = graph.resolve(manifests);

					expect(ArrayLen(result.loadOrder)).toBe(2);
					// depB must come before depA
					var idxB = ArrayFind(result.loadOrder, "depB");
					var idxA = ArrayFind(result.loadOrder, "depA");
					expect(idxB).toBeLT(idxA);
				});

				it("reports error for missing required package", () => {
					var manifests = {
						"pkgA": {
							name: "wheels-pkgA", version: "1.0.0",
							requires: {"wheels-nonexistent": ">=1.0.0"}
						}
					};
					var result = graph.resolve(manifests);

					expect(ArrayLen(result.errors)).toBeGTE(1);
					// pkgA should not be in load order since its dependency is missing
					expect(ArrayFind(result.loadOrder, "pkgA")).toBe(0);
				});

				it("reports error for version mismatch", () => {
					var manifests = {
						"pkgA": {
							name: "wheels-pkgA", version: "1.0.0",
							requires: {"wheels-pkgB": ">=3.0.0"}
						},
						"pkgB": {name: "wheels-pkgB", version: "2.0.0"}
					};
					var result = graph.resolve(manifests);

					expect(ArrayLen(result.errors)).toBeGTE(1);
					var foundVersionError = false;
					for (var err in result.errors) {
						if (Find("does not satisfy", err.message)) {
							foundVersionError = true;
						}
					}
					expect(foundVersionError).toBeTrue();
				});

				it("handles transitive dependencies (A requires B requires C)", () => {
					var manifests = {
						"pkgA": {
							name: "wheels-pkgA", version: "1.0.0",
							requires: {"wheels-pkgB": ">=1.0.0"}
						},
						"pkgB": {
							name: "wheels-pkgB", version: "1.0.0",
							requires: {"wheels-pkgC": ">=1.0.0"}
						},
						"pkgC": {name: "wheels-pkgC", version: "1.0.0"}
					};
					var result = graph.resolve(manifests);

					expect(ArrayLen(result.loadOrder)).toBe(3);
					var idxC = ArrayFind(result.loadOrder, "pkgC");
					var idxB = ArrayFind(result.loadOrder, "pkgB");
					var idxA = ArrayFind(result.loadOrder, "pkgA");
					expect(idxC).toBeLT(idxB);
					expect(idxB).toBeLT(idxA);
				});

			});

			describe("resolve() with replaces", () => {

				it("excludes the replaced package from load order", () => {
					var manifests = {
						"original": {name: "wheels-original", version: "1.0.0"},
						"replacement": {
							name: "wheels-replacement", version: "2.0.0",
							replaces: {"wheels-original": "*"}
						}
					};
					var result = graph.resolve(manifests);

					expect(StructKeyExists(result.excluded, "original")).toBeTrue();
					expect(ArrayFind(result.loadOrder, "original")).toBe(0);
					expect(ArrayFind(result.loadOrder, "replacement")).toBeGT(0);
				});

				it("respects version constraint on replacement", () => {
					var manifests = {
						"original": {name: "wheels-original", version: "3.0.0"},
						"replacement": {
							name: "wheels-replacement", version: "2.0.0",
							replaces: {"wheels-original": "<2.0.0"}
						}
					};
					var result = graph.resolve(manifests);

					// original v3.0.0 does NOT match <2.0.0, so it should NOT be replaced
					expect(StructKeyExists(result.excluded, "original")).toBeFalse();
					expect(ArrayFind(result.loadOrder, "original")).toBeGT(0);
					expect(ArrayFind(result.loadOrder, "replacement")).toBeGT(0);
				});

			});

			describe("resolve() with suggests", () => {

				it("orders suggested package before the suggesting package", () => {
					var manifests = {
						"consumer": {
							name: "wheels-consumer", version: "1.0.0",
							suggests: {"wheels-provider": ">=1.0.0"}
						},
						"provider": {name: "wheels-provider", version: "1.0.0"}
					};
					var result = graph.resolve(manifests);

					expect(ArrayLen(result.loadOrder)).toBe(2);
					var idxProvider = ArrayFind(result.loadOrder, "provider");
					var idxConsumer = ArrayFind(result.loadOrder, "consumer");
					expect(idxProvider).toBeLT(idxConsumer);
				});

				it("does not fail when suggested package is absent", () => {
					var manifests = {
						"consumer": {
							name: "wheels-consumer", version: "1.0.0",
							suggests: {"wheels-optional": ">=1.0.0"}
						}
					};
					var result = graph.resolve(manifests);

					expect(ArrayLen(result.loadOrder)).toBe(1);
					expect(ArrayLen(result.errors)).toBe(0);
					expect(result.loadOrder[1]).toBe("consumer");
				});

			});

			describe("resolve() cycle detection", () => {

				it("detects two-node circular dependency", () => {
					var manifests = {
						"cycleA": {
							name: "wheels-cycleA", version: "1.0.0",
							requires: {"wheels-cycleB": ">=1.0.0"}
						},
						"cycleB": {
							name: "wheels-cycleB", version: "1.0.0",
							requires: {"wheels-cycleA": ">=1.0.0"}
						}
					};
					var result = graph.resolve(manifests);

					expect(ArrayLen(result.errors)).toBeGTE(1);
					var foundCycleError = false;
					for (var err in result.errors) {
						if (Find("Circular dependency", err.message)) {
							foundCycleError = true;
						}
					}
					expect(foundCycleError).toBeTrue();
				});

				it("does not include cycled packages in load order", () => {
					var manifests = {
						"cycleA": {
							name: "wheels-cycleA", version: "1.0.0",
							requires: {"wheels-cycleB": ">=1.0.0"}
						},
						"cycleB": {
							name: "wheels-cycleB", version: "1.0.0",
							requires: {"wheels-cycleA": ">=1.0.0"}
						},
						"standalone": {name: "wheels-standalone", version: "1.0.0"}
					};
					var result = graph.resolve(manifests);

					// standalone should still be in load order
					expect(ArrayFind(result.loadOrder, "standalone")).toBeGT(0);
					// cycled packages should not be in load order
					expect(ArrayFind(result.loadOrder, "cycleA")).toBe(0);
					expect(ArrayFind(result.loadOrder, "cycleB")).toBe(0);
				});

				it("does not label a downstream dependent of a cycle as circular itself", () => {
					var manifests = {
						"cycleA": {
							name: "wheels-cycleA", version: "1.0.0",
							requires: {"wheels-cycleB": ">=1.0.0"}
						},
						"cycleB": {
							name: "wheels-cycleB", version: "1.0.0",
							requires: {"wheels-cycleA": ">=1.0.0"}
						},
						"downstream": {
							name: "wheels-downstream", version: "1.0.0",
							requires: {"wheels-cycleA": ">=1.0.0"}
						}
					};
					var result = graph.resolve(manifests);

					// downstream cannot load (its dependency is cycled)...
					expect(ArrayFind(result.loadOrder, "downstream")).toBe(0);

					var downstreamMessage = "";
					var cycleMessages = [];
					for (var err in result.errors) {
						if (err.package == "downstream") {
							downstreamMessage = err.message;
						}
						if (err.package == "cycleA" || err.package == "cycleB") {
							ArrayAppend(cycleMessages, err.message);
						}
					}

					// ...but its error must say it depends on a cycle, not
					// that it IS one (previously it got the same fabricated
					// "Circular dependency detected" message).
					expect(Len(downstreamMessage)).toBeGT(0);
					expect(downstreamMessage).notToInclude("Circular dependency detected");
					expect(downstreamMessage).toInclude("circular dependency");
					expect(downstreamMessage).toInclude("cycleA");
					expect(downstreamMessage).toInclude("cycleB");

					// The true cycle members still get the circular error.
					expect(ArrayLen(cycleMessages)).toBe(2);
					for (var msg in cycleMessages) {
						expect(msg).toInclude("Circular dependency detected");
					}
				});

				it("reports an actual closed cycle path in the arrow chain", () => {
					var manifests = {
						"cycleA": {
							name: "wheels-cycleA", version: "1.0.0",
							requires: {"wheels-cycleB": ">=1.0.0"}
						},
						"cycleB": {
							name: "wheels-cycleB", version: "1.0.0",
							requires: {"wheels-cycleA": ">=1.0.0"}
						}
					};
					var result = graph.resolve(manifests);

					var chainMessage = "";
					for (var err in result.errors) {
						if (err.package == "cycleA") {
							chainMessage = err.message;
						}
					}
					expect(Len(chainMessage)).toBeGT(0);

					// The arrow chain must be a real closed loop (first node ==
					// last node), not just an unordered listing of leftover
					// nodes from the topological sort.
					var arrowChain = Trim(ListLast(chainMessage, ":"));
					var chainNodes = ListToArray(arrowChain, " ->");
					expect(ArrayLen(chainNodes)).toBeGTE(3);
					expect(chainNodes[1]).toBe(chainNodes[ArrayLen(chainNodes)]);
				});

			});

			describe("resolve() with mutual replaces", () => {

				it("keeps exactly one of two mutually-replacing packages", () => {
					var manifests = {
						"alpha": {
							name: "wheels-alpha", version: "1.0.0",
							replaces: {"wheels-beta": "*"}
						},
						"beta": {
							name: "wheels-beta", version: "1.0.0",
							replaces: {"wheels-alpha": "*"}
						}
					};
					var result = graph.resolve(manifests);

					// Previously BOTH packages were excluded with no error.
					// Now the first package in sorted order wins; the other is
					// excluded — exactly one survives, deterministically.
					expect(ArrayFind(result.loadOrder, "alpha")).toBeGT(0);
					expect(result.excluded).toHaveKey("beta");
					expect(result.excluded).notToHaveKey("alpha");
				});

				it("ignores replaces declared by an already-excluded package", () => {
					var manifests = {
						"aaa": {
							name: "wheels-aaa", version: "1.0.0",
							replaces: {"wheels-bbb": "*"}
						},
						"bbb": {
							name: "wheels-bbb", version: "1.0.0",
							replaces: {"wheels-ccc": "*"}
						},
						"ccc": {name: "wheels-ccc", version: "1.0.0"}
					};
					var result = graph.resolve(manifests);

					// aaa excludes bbb; bbb never loads, so its replaces
					// declaration against ccc must not apply.
					expect(result.excluded).toHaveKey("bbb");
					expect(result.excluded).notToHaveKey("ccc");
					expect(ArrayFind(result.loadOrder, "aaa")).toBeGT(0);
					expect(ArrayFind(result.loadOrder, "ccc")).toBeGT(0);
				});

			});

		});

	}

}
