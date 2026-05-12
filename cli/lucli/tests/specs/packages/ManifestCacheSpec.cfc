component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("ManifestCache", () => {

			var $tmpRoot = () => {
				var dir = GetTempDirectory() & "wheels-cache-" & CreateUUID() & "/";
				return dir;
			};

			it("writes and reads the index round-trip", () => {
				var root = $tmpRoot();
				var cache = new cli.lucli.services.packages.ManifestCache(root = root);
				cache.writeIndex(["wheels-sentry", "wheels-hotwire"]);
				expect(cache.hasFreshIndex()).toBeTrue();
				var names = cache.readIndex();
				expect(names).toBe(["wheels-sentry", "wheels-hotwire"]);
				DirectoryDelete(root, true);
			});

			it("reports cache miss when index is absent", () => {
				var cache = new cli.lucli.services.packages.ManifestCache(root = $tmpRoot());
				expect(cache.hasFreshIndex()).toBeFalse();
			});

			it("writes and reads manifests round-trip", () => {
				var root = $tmpRoot();
				var cache = new cli.lucli.services.packages.ManifestCache(root = root);
				var m = {name: "wheels-sentry", versions: [{version: "1.0.0"}]};
				cache.writeManifest("wheels-sentry", m);
				expect(cache.hasFreshManifest("wheels-sentry")).toBeTrue();
				var round = cache.readManifest("wheels-sentry");
				expect(round.name).toBe("wheels-sentry");
				expect(round.versions[1].version).toBe("1.0.0");
				DirectoryDelete(root, true);
			});

			it("honours TTL — index stale after expiry", () => {
				var root = $tmpRoot();
				var cache = new cli.lucli.services.packages.ManifestCache(root = root, ttlSeconds = 1);
				cache.writeIndex(["x"]);
				expect(cache.hasFreshIndex()).toBeTrue();
				Sleep(1500);
				expect(cache.hasFreshIndex()).toBeFalse();
				DirectoryDelete(root, true);
			});

			it("refresh() wipes the cache directory", () => {
				var root = $tmpRoot();
				var cache = new cli.lucli.services.packages.ManifestCache(root = root);
				cache.writeIndex(["x"]);
				cache.writeManifest("x", {name: "x", versions: []});
				expect(DirectoryExists(root)).toBeTrue();
				cache.refresh();
				expect(DirectoryExists(root)).toBeFalse();
			});

			it("info() reports cache location and freshness", () => {
				var root = $tmpRoot();
				var cache = new cli.lucli.services.packages.ManifestCache(root = root);
				cache.writeIndex([]);
				var info = cache.info();
				expect(info.root).toBe(root);
				expect(info.exists).toBeTrue();
				expect(Len(info.indexFetchedAt)).toBeGT(0);
				DirectoryDelete(root, true);
			});

			// Regression for #2567: $ensureDir used DirectoryCreate(path, true).
			// The createPath flag is Lucee-only — Adobe CF rejects the second
			// argument and crashes the Tools → Packages page. The fix routes
			// through java.io.File.mkdirs() so multi-level parent creation works
			// on every engine.
			it("creates deeply nested cache directories whose parents do not yet exist", () => {
				var unique = "wheels-cli-cache-2567-" & CreateUUID();
				var nestedRoot = GetTempDirectory() & unique & "/level-a/level-b/level-c/";
				try {
					var cache = new cli.lucli.services.packages.ManifestCache(root = nestedRoot);
					cache.writeIndex(["wheels-sentry"]);
					expect(DirectoryExists(nestedRoot)).toBeTrue("expected $ensureDir to create the nested cache root");
					expect(cache.hasFreshIndex()).toBeTrue();
					expect(cache.readIndex()).toBe(["wheels-sentry"]);
				} finally {
					var sweep = GetTempDirectory() & unique;
					if (DirectoryExists(sweep)) {
						DirectoryDelete(sweep, true);
					}
				}
			});
		});
	}
}
