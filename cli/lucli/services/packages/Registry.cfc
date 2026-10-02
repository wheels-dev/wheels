/**
 * Reads the wheels-packages registry over HTTPS.
 *
 * Two data sources:
 *   - GitHub contents API for the list of package dirs (rate-limited,
 *     60 req/hr unauthenticated — cached 24h).
 *   - raw.githubusercontent.com for per-package manifests (also cached).
 *
 * Both are overridable via the `registryRepo` constructor arg or the
 * `WHEELS_PACKAGES_REGISTRY` env var (default "wheels-dev/wheels-packages").
 * Useful for forks, mirrors, and tests.
 */
component {

	variables.DEFAULT_REPO = "wheels-dev/wheels-packages";
	variables.DEFAULT_BRANCH = "main";

	public Registry function init(any httpClient = "", any cache = "", string registryRepo = "", string branch = "") {
		variables.http = IsObject(arguments.httpClient)
		 ? arguments.httpClient
		 : new modules.wheels.services.packages.HttpClient();
		variables.registryRepo = Len(arguments.registryRepo)
		 ? arguments.registryRepo
		 : $resolveRepo();
		variables.branch = Len(arguments.branch) ? arguments.branch : variables.DEFAULT_BRANCH;
		// Keyed by registry so a switched registry never serves the previous
		// one's cached data; the default registry keeps the shared root.
		variables.cache = IsObject(arguments.cache)
		 ? arguments.cache
		 : new modules.wheels.services.packages.ManifestCache(registryKey = $cacheKey());
		return this;
	}

	public string function registryRepo() {
		return variables.registryRepo;
	}
	public string function branch() {
		return variables.branch;
	}
	public any function cache() {
		return variables.cache;
	}


	/** "" for the default registry, else "<repo>@<branch>". */
	private string function $cacheKey() {
		if (variables.registryRepo == variables.DEFAULT_REPO && variables.branch == variables.DEFAULT_BRANCH) {
			return "";
		}
		return variables.registryRepo & "@" & variables.branch;
	}

	private boolean function $isOffline() {
		return request.$wheelsOffline ?: false;
	}

	/**
	 * Offline gate for network paths. `wheels packages` sets
	 * request.$wheelsOffline when --offline / WHEELS_OFFLINE=1 is active.
	 * Callers serve cached data first, even expired data; this runs only
	 * when nothing is cached, so it says so instead of hanging on a blocked
	 * request.
	 */
	private void function $rejectWhenOffline(required string verb) {
		if ($isOffline()) {
			Throw(
				type = "Wheels.Packages.Offline",
				message = "Offline mode is enabled (--offline / WHEELS_OFFLINE=1). No cached registry data exists for '#variables.registryRepo#' yet, so this command needs network access once; run it again without --offline."
			);
		}
	}

	/**
	 * Returns the list of package names in the registry. Serves cached
	 * data if fresh; otherwise hits the GitHub contents API.
	 */
	public array function listPackageNames() {
		if (variables.cache.hasFreshIndex() || ($isOffline() && variables.cache.hasIndex())) {
			return variables.cache.readIndex();
		}
		$rejectWhenOffline("list");
		local.url = "https://api.github.com/repos/#variables.registryRepo#/contents/packages?ref=#variables.branch#";
		local.resp = variables.http.get(local.url);
		if (local.resp.status != 200) {
			Throw(
				type = "Wheels.Packages.RegistryUnavailable",
				message = "Failed to list packages from registry (HTTP #local.resp.status#). URL: #local.url#"
			);
		}
		local.entries = DeserializeJSON(local.resp.body);
		if (!IsArray(local.entries)) {
			Throw(type = "Wheels.Packages.RegistryMalformed", message = "Registry contents endpoint did not return an array.");
		}
		local.names = [];
		for (local.entry in local.entries) {
			if ((local.entry.type ?: "") == "dir") {
				ArrayAppend(local.names, local.entry.name);
			}
		}
		ArraySort(local.names, "text");
		variables.cache.writeIndex(local.names);
		return local.names;
	}

	/**
	 * Fetches a package's manifest. Cached 24h per package.
	 *
	 * Both the cache-hit and fresh-fetch paths run $validateManifest()
	 * so a manifest written by an older Registry version that lacks
	 * the `versions` invariant (or any other required field added later)
	 * still throws RegistryMalformed instead of crashing listAll() with
	 * an Expression-level error.
	 */
	public struct function fetchManifest(required string name) {
		new modules.wheels.services.packages.PackageName().assert(arguments.name);
		if (variables.cache.hasFreshManifest(arguments.name)
			|| ($isOffline() && variables.cache.hasManifest(arguments.name))) {
			local.cached = variables.cache.readManifest(arguments.name);
			$validateManifest(arguments.name, local.cached);
			return local.cached;
		}
		$rejectWhenOffline("fetch");
		local.url = "https://raw.githubusercontent.com/#variables.registryRepo#/#variables.branch#/packages/#arguments.name#/manifest.json";
		local.resp = variables.http.get(local.url);
		if (local.resp.status == 404) {
			Throw(
				type = "Wheels.Packages.UnknownPackage",
				message = "Package '#arguments.name#' not found in registry '#variables.registryRepo#'."
			);
		}
		if (local.resp.status != 200) {
			Throw(
				type = "Wheels.Packages.RegistryUnavailable",
				message = "Failed to fetch manifest for '#arguments.name#' (HTTP #local.resp.status#)."
			);
		}
		local.manifest = DeserializeJSON(local.resp.body);
		$validateManifest(arguments.name, local.manifest);
		variables.cache.writeManifest(arguments.name, local.manifest);
		return local.manifest;
	}

	/**
	 * Asserts the listAll() consumption contract: must be a struct with
	 * `name` and a non-empty `versions` array. Throws RegistryMalformed
	 * on any violation. Called from both the cache-hit and fresh-fetch
	 * paths in fetchManifest so stale on-disk manifests written by an
	 * older Registry version surface as a typed throw instead of an
	 * Expression-level crash deeper in the call chain.
	 */
	private void function $validateManifest(required string name, required any manifest) {
		if (!IsStruct(arguments.manifest) || !StructKeyExists(arguments.manifest, "name")) {
			Throw(
				type = "Wheels.Packages.RegistryMalformed",
				message = "Manifest for '#arguments.name#' is not a valid manifest struct."
			);
		}
		if (
			!StructKeyExists(arguments.manifest, "versions")
			|| !IsArray(arguments.manifest.versions)
			|| !ArrayLen(arguments.manifest.versions)
		) {
			Throw(
				type = "Wheels.Packages.RegistryMalformed",
				message = "Manifest for '#arguments.name#' is missing a non-empty versions array."
			);
		}
	}

	/**
	 * Returns enriched summaries for every package in the registry.
	 * One HTTP call for the index, one per package for its manifest
	 * (all cached 24h). Skips packages whose manifest fails to parse;
	 * propagates a registry-wide unavailability error.
	 */
	public array function listAll() {
		local.names = listPackageNames();
		local.out = [];
		for (local.name in local.names) {
			try {
				local.m = fetchManifest(local.name);
			} catch (Wheels.Packages.RegistryMalformed e) {
				continue;
			}
			local.latest = local.m.versions[ArrayLen(local.m.versions)];
			ArrayAppend(
				local.out,
				{
					name = local.m.name,
					description = local.m.description ?: "",
					tags = IsArray(local.m.tags ?: "") ? local.m.tags : [],
					homepage = local.m.homepage ?: "",
					latestVersion = local.latest.version
				}
			);
		}
		return local.out;
	}

	public struct function info() {
		local.cacheInfo = variables.cache.info();
		return {
			registryRepo = variables.registryRepo,
			branch = variables.branch,
			indexUrl = "https://github.com/#variables.registryRepo#/tree/#variables.branch#/packages",
			cache = local.cacheInfo
		};
	}

	public void function refresh() {
		variables.cache.refresh();
	}

	// ── Private ─────────────────────────────────────────────

	private string function $resolveRepo() {
		local.env = CreateObject("java", "java.lang.System").getenv("WHEELS_PACKAGES_REGISTRY");
		if (!IsNull(local.env) && Len(local.env)) {
			return local.env;
		}
		return variables.DEFAULT_REPO;
	}

}
