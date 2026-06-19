component extends="wheels.WheelsTest" {

	function run() {

		describe("MiddlewareOrderResolver", function() {

			beforeEach(function() {
				resolver = new wheels.middleware.MiddlewareOrderResolver();
			});

			describe("resolve()", function() {

				it("returns empty array for empty input", function() {
					var result = resolver.resolve([]);
					expect(result).toBeArray();
					expect(ArrayLen(result)).toBe(0);
				});

				it("returns single entry unchanged", function() {
					var entries = [$entry("A", "pluginA")];
					var result = resolver.resolve(entries);
					expect(ArrayLen(result)).toBe(1);
					expect(result[1].pluginName).toBe("pluginA");
				});

				it("sorts by priority (lower first)", function() {
					var entries = [
						$entry("C", "pluginC", {priority: 30}),
						$entry("A", "pluginA", {priority: 1}),
						$entry("B", "pluginB", {priority: 20})
					];
					var result = resolver.resolve(entries);
					expect(result[1].pluginName).toBe("pluginA");
					expect(result[2].pluginName).toBe("pluginB");
					expect(result[3].pluginName).toBe("pluginC");
				});

				it("uses default priority of 10 when not specified", function() {
					var entries = [
						$entry("High", "pluginHigh", {priority: 20}),
						$entry("Default", "pluginDefault"),
						$entry("Low", "pluginLow", {priority: 1})
					];
					var result = resolver.resolve(entries);
					expect(result[1].pluginName).toBe("pluginLow");
					expect(result[2].pluginName).toBe("pluginDefault");
					expect(result[3].pluginName).toBe("pluginHigh");
				});

				it("respects before constraint", function() {
					var entries = [
						$entry("Auth", "pluginAuth"),
						$entry("RequestId", "pluginRequestId", {before: "Auth"})
					];
					var result = resolver.resolve(entries);
					expect(result[1].pluginName).toBe("pluginRequestId");
					expect(result[2].pluginName).toBe("pluginAuth");
				});

				it("respects after constraint", function() {
					var entries = [
						$entry("Logger", "pluginLogger", {after: "Auth"}),
						$entry("Auth", "pluginAuth")
					];
					var result = resolver.resolve(entries);
					expect(result[1].pluginName).toBe("pluginAuth");
					expect(result[2].pluginName).toBe("pluginLogger");
				});

				it("handles before constraint as comma-delimited list", function() {
					var entries = [
						$entry("A", "pluginA"),
						$entry("B", "pluginB"),
						$entry("First", "pluginFirst", {before: "A,B"})
					];
					var result = resolver.resolve(entries);
					expect(result[1].pluginName).toBe("pluginFirst");
				});

				it("handles before constraint as array", function() {
					var entries = [
						$entry("A", "pluginA"),
						$entry("B", "pluginB"),
						$entry("First", "pluginFirst", {before: ["A", "B"]})
					];
					var result = resolver.resolve(entries);
					expect(result[1].pluginName).toBe("pluginFirst");
				});

				it("combines before/after with priority as tiebreaker", function() {
					var entries = [
						$entry("C", "pluginC", {priority: 5, after: "A"}),
						$entry("A", "pluginA", {priority: 10}),
						$entry("B", "pluginB", {priority: 1, after: "A"})
					];
					var result = resolver.resolve(entries);
					// A must run first (no dependencies). B and C both after A.
					// B has priority 1, C has priority 5 — B before C.
					expect(result[1].pluginName).toBe("pluginA");
					expect(result[2].pluginName).toBe("pluginB");
					expect(result[3].pluginName).toBe("pluginC");
				});

				it("handles chain of constraints (A before B before C)", function() {
					var entries = [
						$entry("C", "pluginC"),
						$entry("A", "pluginA", {before: "B"}),
						$entry("B", "pluginB", {before: "C"})
					];
					var result = resolver.resolve(entries);
					expect(result[1].pluginName).toBe("pluginA");
					expect(result[2].pluginName).toBe("pluginB");
					expect(result[3].pluginName).toBe("pluginC");
				});

				it("uses explicit name option over pluginName", function() {
					var entries = [
						$entry("auth-mw", "pluginAuth", {name: "auth-mw"}),
						$entry("logger-mw", "pluginLogger", {name: "logger-mw", after: "auth-mw"})
					];
					var result = resolver.resolve(entries);
					expect(result[1].pluginName).toBe("pluginAuth");
					expect(result[2].pluginName).toBe("pluginLogger");
				});

				it("falls back to priority sort on circular dependency", function() {
					var entries = [
						$entry("A", "pluginA", {priority: 1, before: "B"}),
						$entry("B", "pluginB", {priority: 2, before: "A"})
					];
					// Circular: A before B AND B before A — should warn and fallback.
					var result = resolver.resolve(entries);
					// Fallback is priority-only: A (1) before B (2).
					expect(ArrayLen(result)).toBe(2);
					expect(result[1].pluginName).toBe("pluginA");
					expect(result[2].pluginName).toBe("pluginB");
				});

				it("preserves ordering constraints when duplicate names are present", function() {
					// Regression: duplicate names collapsed into a single graph node,
					// so the visited count never reached the entry total, the resolver
					// fired the circular-dependency warning (a wrong diagnosis), and
					// fell back to priority-only ordering — discarding all
					// before/after constraints.
					var entries = [
						$entry("alpha", "pluginOne", {priority: 10}),
						$entry("alpha", "pluginTwo", {priority: 20}),
						$entry("gamma", "pluginThree", {priority: 1, after: "alpha"})
					];
					var result = resolver.resolve(entries);
					expect(ArrayLen(result)).toBe(3);
					// Priority-only fallback would put gamma (priority 1) first.
					// The after="alpha" constraint binds to the first registration.
					expect(result[1].pluginName).toBe("pluginOne");
					expect(result[2].pluginName).toBe("pluginThree");
					expect(result[3].pluginName).toBe("pluginTwo");
				});

				it("does not throw when duplicate-name entries lack a pluginName key", function() {
					// Regression: the duplicate-name warning dereferenced
					// entry.pluginName unguarded, so duplicates without a pluginName
					// threw inside the warning path itself.
					var entries = [
						{middleware = "test.middleware.DupOne", options = {name = "dup"}},
						{middleware = "test.middleware.DupTwo", options = {name = "dup"}}
					];
					var result = resolver.resolve(entries);
					expect(ArrayLen(result)).toBe(2);
				});

				it("retains all duplicate-name entries in the output", function() {
					var entries = [
						$entry("same", "pluginA", {priority: 30}),
						$entry("same", "pluginB", {priority: 10}),
						$entry("same", "pluginC", {priority: 20})
					];
					var result = resolver.resolve(entries);
					expect(ArrayLen(result)).toBe(3);
				});

				it("ignores unknown before target with warning", function() {
					var entries = [
						$entry("A", "pluginA", {before: "NonExistent"}),
						$entry("B", "pluginB")
					];
					// Should not crash; A's constraint on NonExistent is ignored.
					var result = resolver.resolve(entries);
					expect(ArrayLen(result)).toBe(2);
				});

				it("ignores unknown after target with warning", function() {
					var entries = [
						$entry("A", "pluginA", {after: "Ghost"}),
						$entry("B", "pluginB")
					];
					var result = resolver.resolve(entries);
					expect(ArrayLen(result)).toBe(2);
				});

				it("preserves original entry structs in output", function() {
					var entries = [
						$entry("A", "pluginA", {priority: 5}),
						$entry("B", "pluginB", {priority: 1})
					];
					var result = resolver.resolve(entries);
					// Each result element should still have middleware, options, pluginName.
					expect(StructKeyExists(result[1], "middleware")).toBeTrue();
					expect(StructKeyExists(result[1], "options")).toBeTrue();
					expect(StructKeyExists(result[1], "pluginName")).toBeTrue();
				});

				it("handles middleware with same priority stably", function() {
					var entries = [
						$entry("A", "pluginA", {priority: 10}),
						$entry("B", "pluginB", {priority: 10}),
						$entry("C", "pluginC", {priority: 10})
					];
					var result = resolver.resolve(entries);
					// All same priority, no constraints — should produce a valid ordering.
					expect(ArrayLen(result)).toBe(3);
				});

			});

		});

	}

	/**
	 * Helper to create a middleware entry struct matching the format from Plugins.cfc.
	 * The first-arg `name` is used as the ordering identifier so specs can reference
	 * before/after targets via the same name they create entries with.
	 */
	private struct function $entry(required string name, required string pluginName, struct options = {}) {
		var opts = Duplicate(arguments.options);
		if (!StructKeyExists(opts, "name")) {
			opts.name = arguments.name;
		}
		return {
			middleware = "test.middleware.#arguments.name#",
			options = opts,
			pluginName = arguments.pluginName
		};
	}

}
