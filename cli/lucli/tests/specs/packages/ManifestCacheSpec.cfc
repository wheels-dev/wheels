component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("ManifestCache", () => {

			var $tmpRoot = () => {
				var dir = GetTempDirectory() & "wheels-cache-" & CreateUUID() & "/";
				return dir;
			};

			it("writes and reads the index round-trip", () => {
				var root = $tmpRoot();
				var cache = new modules.wheels.services.packages.ManifestCache(root = root);
				cache.writeIndex(["wheels-sentry", "wheels-hotwire"]);
				expect(cache.hasFreshIndex()).toBeTrue();
				var names = cache.readIndex();
				expect(names).toBe(["wheels-sentry", "wheels-hotwire"]);
				DirectoryDelete(root, true);
			});

			it("reports cache miss when index is absent", () => {
				var cache = new modules.wheels.services.packages.ManifestCache(root = $tmpRoot());
				expect(cache.hasFreshIndex()).toBeFalse();
			});

			it("writes and reads manifests round-trip", () => {
				var root = $tmpRoot();
				var cache = new modules.wheels.services.packages.ManifestCache(root = root);
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
				var cache = new modules.wheels.services.packages.ManifestCache(root = root, ttlSeconds = 1);
				cache.writeIndex(["x"]);
				expect(cache.hasFreshIndex()).toBeTrue();
				Sleep(1500);
				expect(cache.hasFreshIndex()).toBeFalse();
				DirectoryDelete(root, true);
			});

			it("refresh() wipes the cache directory", () => {
				var root = $tmpRoot();
				var cache = new modules.wheels.services.packages.ManifestCache(root = root);
				cache.writeIndex(["x"]);
				cache.writeManifest("x", {name: "x", versions: []});
				expect(DirectoryExists(root)).toBeTrue();
				cache.refresh();
				expect(DirectoryExists(root)).toBeFalse();
			});

			it("info() reports cache location and freshness", () => {
				var root = $tmpRoot();
				var cache = new modules.wheels.services.packages.ManifestCache(root = root);
				cache.writeIndex([]);
				var info = cache.info();
				expect(info.root).toBe(root);
				expect(info.exists).toBeTrue();
				expect(Len(info.indexFetchedAt)).toBeGT(0);
				DirectoryDelete(root, true);
			});
		});
	}
}
