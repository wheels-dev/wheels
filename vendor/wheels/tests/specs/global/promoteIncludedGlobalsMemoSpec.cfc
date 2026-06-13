component extends="wheels.WheelsTest" {

	function run() {

		// Shared struct so nested beforeEach / afterEach / it closures can all
		// reach the same state on Adobe CF (cross-engine invariant ##3: closures
		// cannot reach an enclosing function's `local` scope).
		var ctx = {
			g: application.wo,
			fixturePath: "wheels.tests._assets.global.PromoteMemoFixture",
			appKey: "",
			hadCache: false,
			savedCache: ""
		};

		// NOTE on the cache key: the memo is keyed by `GetMetadata(this).name`
		// evaluated DURING Global's pseudo-constructor. What that resolves to
		// for a subclass instantiation is engine-dependent — on Lucee the
		// parent body executes against the parent's own `this` view (so every
		// subclass keys to "wheels.Global", which is correct there because
		// subclass methods are not yet registered in `variables` either),
		// while engines that expose the concrete instance key per class. The
		// key therefore self-consistently identifies the scanned surface, and
		// these specs never assert a fixed key name — they assert behavioral
		// equivalence between the memoized and fresh-scan paths.

		describe("$promoteIncludedGlobalsToThis memoization (issue ##2897 PR C)", () => {

			beforeEach(() => {
				ctx.appKey = ctx.g.$appKey();
				ctx.hadCache = StructKeyExists(application[ctx.appKey], "promotedGlobalKeys");
				if (ctx.hadCache) {
					ctx.savedCache = application[ctx.appKey].promotedGlobalKeys;
				}
				StructDelete(application[ctx.appKey], "promotedGlobalKeys");
			});

			afterEach(() => {
				StructDelete(application[ctx.appKey], "promotedGlobalKeys");
				if (ctx.hadCache) {
					application[ctx.appKey].promotedGlobalKeys = ctx.savedCache;
				}
			});

			it("records the promote-key list in application scope on first instantiation", () => {
				var fixture = new wheels.tests._assets.global.PromoteMemoFixture();
				expect(StructKeyExists(application[ctx.appKey], "promotedGlobalKeys")).toBeTrue(
					"expected instantiating a Global-derived component to create the promotedGlobalKeys cache"
				);
				var cache = application[ctx.appKey].promotedGlobalKeys;
				var cacheKeys = StructKeyArray(cache);
				expect(ArrayLen(cacheKeys)).toBe(1);
				// The key is a class dot path in the fixture's inheritance chain —
				// which one is engine-dependent (see the NOTE above).
				expect(
					CompareNoCase(cacheKeys[1], ctx.fixturePath) == 0 || CompareNoCase(cacheKeys[1], "wheels.Global") == 0
				).toBeTrue("expected a class dot path from the fixture's inheritance chain, got [#cacheKeys[1]#]");
				expect(IsArray(cache[cacheKeys[1]])).toBeTrue();
			});

			it("produces an identical promoted surface from the memoized path as from a fresh scan", () => {
				// First instantiation: cache is empty (wiped in beforeEach), so this
				// takes the fresh-scan path and records the promote-key list.
				var first = new wheels.tests._assets.global.PromoteMemoFixture();
				var actualCacheKey = StructKeyArray(application[ctx.appKey].promotedGlobalKeys)[1];
				var cachedKeys = Duplicate(application[ctx.appKey].promotedGlobalKeys[actualCacheKey]);

				// Second instantiation: the cache entry exists, so this takes the
				// memoized path (the gate is the cached key itself — ##2800 lesson).
				var second = new wheels.tests._assets.global.PromoteMemoFixture();

				// The open design point from the ##2897 design comment: whether the
				// subclass's private `privateProbe` is in `variables` when Global's
				// pseudo-constructor scan runs is engine-dependent. The invariant is
				// that the memoized path agrees with the fresh-scan path, whatever
				// the engine does.
				expect(second.$hasThisKey("privateProbe")).toBe(first.$hasThisKey("privateProbe"));

				// Every cached key must be promoted on the memoized instance too.
				var keyCount = ArrayLen(cachedKeys);
				for (var i = 1; i <= keyCount; i++) {
					expect(second.$hasThisKey(cachedKeys[i])).toBeTrue(
						"expected memoized instantiation to promote cached key [#cachedKeys[i]#]"
					);
				}
			});

			it("re-scans and repopulates after the cache is cleared (reload recreates application[appKey])", () => {
				// On ?reload=true, onapplicationstart.cfc rebuilds application.$wheels
				// as a fresh struct, so the cache is invalidated structurally. Deleting
				// the cache key here simulates exactly that.
				var first = new wheels.tests._assets.global.PromoteMemoFixture();
				var firstCacheKey = StructKeyArray(application[ctx.appKey].promotedGlobalKeys)[1];
				var firstKeys = Duplicate(application[ctx.appKey].promotedGlobalKeys[firstCacheKey]);
				StructDelete(application[ctx.appKey], "promotedGlobalKeys");

				var second = new wheels.tests._assets.global.PromoteMemoFixture();
				expect(StructKeyExists(application[ctx.appKey], "promotedGlobalKeys")).toBeTrue(
					"expected the cache to be repopulated after a wipe"
				);
				var secondCacheKey = StructKeyArray(application[ctx.appKey].promotedGlobalKeys)[1];
				expect(CompareNoCase(secondCacheKey, firstCacheKey)).toBe(0);
				var secondKeys = Duplicate(application[ctx.appKey].promotedGlobalKeys[secondCacheKey]);
				ArraySort(firstKeys, "textnocase");
				ArraySort(secondKeys, "textnocase");
				expect(SerializeJSON(secondKeys)).toBe(SerializeJSON(firstKeys));
			});

			it("a memo populated by a base-class instantiation never distorts a subclass surface", () => {
				// Reference: fresh-scan fixture surface with an empty cache.
				var reference = new wheels.tests._assets.global.PromoteMemoFixture();
				var referenceHasProbe = reference.$hasThisKey("privateProbe");
				StructDelete(application[ctx.appKey], "promotedGlobalKeys");

				// Populate the cache via a bare wheels.Global first, then build the
				// fixture through whatever path (memoized or per-class fresh scan)
				// the engine's keying produces. The surfaces must match the
				// reference either way — this is the cross-contamination guard the
				// per-surface keying exists for.
				var baseInstance = new wheels.Global();
				var fixture = new wheels.tests._assets.global.PromoteMemoFixture();
				expect(fixture.$hasThisKey("privateProbe")).toBe(referenceHasProbe);
				expect(fixture.$hasThisKey("$injectVariablesFunction")).toBeTrue();
			});

			it("takes the memoized path without re-scanning when the cache entry exists", () => {
				// Seed adversarial cache entries for every key the engine might use
				// BEFORE first instantiation. If the memoized path is taken, the
				// seeded entry survives untouched; a fresh scan would overwrite it
				// with the real promote-key list.
				var seeded = ["noSuchVariablesKey", "$hasThisKey"];
				application[ctx.appKey].promotedGlobalKeys = {};
				application[ctx.appKey].promotedGlobalKeys[ctx.fixturePath] = Duplicate(seeded);
				application[ctx.appKey].promotedGlobalKeys["wheels.Global"] = Duplicate(seeded);

				var fixture = new wheels.tests._assets.global.PromoteMemoFixture();

				// Keys missing from `variables` are skipped, keys already on `this`
				// are left alone (same guards as the fresh scan).
				expect(fixture.$hasThisKey("noSuchVariablesKey")).toBeFalse();
				expect(fixture.$hasThisKey("$hasThisKey")).toBeTrue();

				// Neither seeded entry was overwritten — proves no re-scan ran.
				var cache = application[ctx.appKey].promotedGlobalKeys;
				expect(StructCount(cache)).toBe(2);
				expect(ArrayLen(cache[ctx.fixturePath])).toBe(2);
				expect(cache[ctx.fixturePath][1]).toBe("noSuchVariablesKey");
				expect(ArrayLen(cache["wheels.Global"])).toBe(2);
				expect(cache["wheels.Global"][1]).toBe("noSuchVariablesKey");
			});

			it("the live-scan helper promotes variables-scope custom functions onto this (cache-unavailable fallback path)", () => {
				var fixture = new wheels.tests._assets.global.PromoteMemoFixture();
				// Hoisted closure — never inline a function literal as a constructor
				// named arg (cross-engine invariant ##5); method-call args are safe
				// but hoisting keeps the shape uniform.
				var injectedFn = function() {
					return "injected";
				};
				fixture.$injectVariablesFunction(functionName = "memoProbeInjected", fn = injectedFn);
				expect(fixture.$hasVariablesKey("memoProbeInjected")).toBeTrue();
				// Whether a UDF assigned to `variables` is already visible via `this`
				// is engine-dependent (Lucee auto-exposes it; Adobe does not — that
				// asymmetry is the whole reason the promote loop exists, see ##2790).
				var hadThisKeyBefore = fixture.$hasThisKey("memoProbeInjected");

				// $scanAndPromoteIncludedGlobals is the same code path the memo wrapper
				// falls back to when `application` (or the cache host) is unavailable.
				var promotedKeys = fixture.$scanAndPromoteIncludedGlobals();
				expect(IsArray(promotedKeys)).toBeTrue();
				expect(fixture.$hasThisKey("memoProbeInjected")).toBeTrue();
				expect(fixture.memoProbeInjected()).toBe("injected");
				if (!hadThisKeyBefore) {
					expect(ArrayFindNoCase(promotedKeys, "memoProbeInjected")).toBeGT(0);
				}
			});

		});
	}

}
