/**
 * `wheels packages registry <verb>` surface.
 *
 * Verbs:
 *   refresh — bust the 24h cache so the next list/show hits the network.
 *   info    — print registry URL, branch, cache location, freshness.
 */
component {

	public PackagesRegistryCli function init(any registry = "") {
		variables.registry = IsObject(arguments.registry)
			? arguments.registry
			: new cli.lucli.services.packages.Registry();
		return this;
	}

	public string function refresh(struct opts = {}) {
		variables.registry.refresh();
		return "Cache cleared. Next `wheels packages list` will re-fetch from the registry." & Chr(10);
	}

	public string function info(struct opts = {}) {
		local.i = variables.registry.info();
		local.buf = [];
		ArrayAppend(local.buf, "Registry:       " & local.i.registryRepo);
		ArrayAppend(local.buf, "Branch:         " & local.i.branch);
		ArrayAppend(local.buf, "Browse:         " & local.i.indexUrl);
		ArrayAppend(local.buf, "Cache dir:      " & local.i.cache.root);
		ArrayAppend(local.buf, "Cache TTL:      " & local.i.cache.ttlSeconds & "s");
		ArrayAppend(local.buf, "Cache present:  " & (local.i.cache.exists ? "yes" : "no"));
		if (Len(local.i.cache.indexFetchedAt)) {
			ArrayAppend(local.buf, "Index fetched:  " & local.i.cache.indexFetchedAt);
		}
		return ArrayToList(local.buf, Chr(10)) & Chr(10);
	}
}
