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

	public Registry function init(
		any httpClient = "",
		any cache = "",
		string registryRepo = "",
		string branch = ""
	) {
		variables.http = IsObject(arguments.httpClient)
			? arguments.httpClient
			: new modules.wheels.services.packages.HttpClient();
		variables.cache = IsObject(arguments.cache)
			? arguments.cache
			: new modules.wheels.services.packages.ManifestCache();
		variables.registryRepo = Len(arguments.registryRepo)
			? arguments.registryRepo
			: $resolveRepo();
		variables.branch = Len(arguments.branch) ? arguments.branch : variables.DEFAULT_BRANCH;
		return this;
	}

	public string function registryRepo() { return variables.registryRepo; }
	public string function branch()        { return variables.branch; }
	public any    function cache()         { return variables.cache; }

	/**
	 * Returns the list of package names in the registry. Serves cached
	 * data if fresh; otherwise hits the GitHub contents API.
	 */
	public array function listPackageNames() {
		if (variables.cache.hasFreshIndex()) {
			return variables.cache.readIndex();
		}
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
			Throw(
				type = "Wheels.Packages.RegistryMalformed",
				message = "Registry contents endpoint did not return an array."
			);
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
	 */
	public struct function fetchManifest(required string name) {
		if (variables.cache.hasFreshManifest(arguments.name)) {
			return variables.cache.readManifest(arguments.name);
		}
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
		if (!IsStruct(local.manifest) || !StructKeyExists(local.manifest, "name")) {
			Throw(
				type = "Wheels.Packages.RegistryMalformed",
				message = "Manifest for '#arguments.name#' is not a valid manifest struct."
			);
		}
		variables.cache.writeManifest(arguments.name, local.manifest);
		return local.manifest;
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
			ArrayAppend(local.out, {
				name:          local.m.name,
				description:   local.m.description ?: "",
				tags:          IsArray(local.m.tags ?: "") ? local.m.tags : [],
				homepage:      local.m.homepage ?: "",
				latestVersion: local.latest.version
			});
		}
		return local.out;
	}

	public struct function info() {
		local.cacheInfo = variables.cache.info();
		return {
			registryRepo: variables.registryRepo,
			branch: variables.branch,
			indexUrl: "https://github.com/#variables.registryRepo#/tree/#variables.branch#/packages",
			cache: local.cacheInfo
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
