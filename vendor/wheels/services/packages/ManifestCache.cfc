/**
 * 24h FS cache for registry data — the package index and per-package
 * manifests. Keeps the debug panel's "browse registry" section fast and
 * respects GitHub's 60 req/hr unauthenticated rate limit.
 *
 * Layout:
 *   <root>/
 *     index.json           — { fetchedAt, names: ["wheels-sentry", ...] }
 *     manifests/
 *       <name>.json        — { fetchedAt, manifest: {...} }
 *
 * `refresh()` nukes the whole dir. Explicit, no partial invalidation —
 * keeps the mental model simple.
 *
 * Mirrors cli/lucli/services/packages/ManifestCache.cfc — the framework
 * and the CLI deliberately share the same on-disk cache root
 * (~/.wheels/cache/packages) so a `wheels packages list` warm-up also
 * benefits the debug panel and vice versa.
 */
component {

	variables.DEFAULT_TTL_SECONDS = 86400; // 24h

	public ManifestCache function init(string root = "", numeric ttlSeconds = 0) {
		variables.root = Len(arguments.root) ? arguments.root : $defaultRoot();
		variables.ttl = arguments.ttlSeconds > 0 ? arguments.ttlSeconds : variables.DEFAULT_TTL_SECONDS;
		return this;
	}

	public string function root() {
		return variables.root;
	}

	public numeric function ttlSeconds() {
		return variables.ttl;
	}

	// ── Index ───────────────────────────────────────────────

	public boolean function hasFreshIndex() {
		return $freshFile($indexPath());
	}

	public array function readIndex() {
		if (!FileExists($indexPath())) return [];
		local.data = DeserializeJSON(FileRead($indexPath()));
		return IsArray(local.data.names ?: "") ? local.data.names : [];
	}

	public void function writeIndex(required array names) {
		$ensureDir(variables.root);
		FileWrite($indexPath(), SerializeJSON({fetchedAt = DateTimeFormat(Now(), "iso"), names = arguments.names}));
	}

	// ── Manifests ───────────────────────────────────────────

	public boolean function hasFreshManifest(required string name) {
		return $freshFile($manifestPath(arguments.name));
	}

	public struct function readManifest(required string name) {
		local.path = $manifestPath(arguments.name);
		if (!FileExists(local.path)) {
			Throw(type = "Wheels.Packages.CacheMiss", message = "No cached manifest for '#arguments.name#'.");
		}
		local.data = DeserializeJSON(FileRead(local.path));
		return local.data.manifest ?: {};
	}

	public void function writeManifest(required string name, required struct manifest) {
		$ensureDir($manifestsDir());
		FileWrite(
			$manifestPath(arguments.name),
			SerializeJSON({fetchedAt = DateTimeFormat(Now(), "iso"), manifest = arguments.manifest})
		);
	}

	// ── Maintenance ─────────────────────────────────────────

	public struct function info() {
		local.indexFreshness = "";
		if (FileExists($indexPath())) {
			local.info = GetFileInfo($indexPath());
			local.indexFreshness = DateTimeFormat(local.info.lastmodified, "iso");
		}
		return {
			root = variables.root,
			ttlSeconds = variables.ttl,
			indexFetchedAt = local.indexFreshness,
			exists = DirectoryExists(variables.root)
		};
	}

	public void function refresh() {
		if (DirectoryExists(variables.root)) {
			DirectoryDelete(variables.root, true);
		}
	}

	// ── Private ─────────────────────────────────────────────

	private string function $indexPath() {
		return variables.root & "/index.json";
	}

	private string function $manifestsDir() {
		return variables.root & "/manifests";
	}

	private string function $manifestPath(required string name) {
		return $manifestsDir() & "/" & arguments.name & ".json";
	}

	private boolean function $freshFile(required string path) {
		if (!FileExists(arguments.path)) return false;
		local.info = GetFileInfo(arguments.path);
		local.ageSeconds = DateDiff("s", local.info.lastmodified, Now());
		return local.ageSeconds < variables.ttl;
	}

	private void function $ensureDir(required string path) {
		if (DirectoryExists(arguments.path)) {
			return;
		}
		// Adobe CF's DirectoryCreate accepts only a single argument — passing
		// the Lucee-only createPath flag crashes the Tools → Packages page on
		// fresh ACF installs (#2567). Java's File.mkdirs() recurses parents
		// uniformly on every engine. mkdirs() returns false when the directory
		// already exists OR when creation fails (e.g. permission denied);
		// re-check DirectoryExists so a benign concurrent-creation race
		// doesn't masquerade as a real failure.
		local.created = CreateObject("java", "java.io.File").init(arguments.path).mkdirs();
		if (!local.created && !DirectoryExists(arguments.path)) {
			Throw(
				type = "Wheels.Packages.CacheDir",
				message = "Could not create cache directory '#arguments.path#'."
			);
		}
	}

	private string function $defaultRoot() {
		local.sys = CreateObject("java", "java.lang.System");
		local.home = local.sys.getProperty("user.home");
		return local.home & "/.wheels/cache/packages";
	}

}
