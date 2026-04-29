/**
 * Compiled-class cache purge helper for `wheels reload`.
 *
 * Lucee's default `inspectTemplate=once` setting compiles each CFC once,
 * caches the .class on disk under `<server>/lucee-server/context/cfclasses/`,
 * and never rechecks the source timestamp. Wheels' `?reload=true` resets
 * framework state via `applicationStop()` but does not invalidate Lucee's
 * template cache — so source edits to models, controllers, and config
 * silently miss until cfclasses is wiped. See onboarding finding F5.
 *
 * Isolated from Module.cfc so the deletion logic can be exercised against
 * temp directories without touching a live Lucee server.
 */
component {

	public function init() {
		return this;
	}

	/**
	 * Delete the contents of the given cfclasses directory, preserving the
	 * directory itself so Lucee can repopulate it on the next compile.
	 *
	 * Best-effort: per-entry failures (file locked by an active compile, OS
	 * permission issue) are recorded but don't abort the purge — better to
	 * clear what we can than to bail entirely.
	 *
	 * Returns a struct documenting what happened, useful for tests and
	 * diagnostic logging:
	 *   { purged: [list of paths deleted],
	 *     failed: [list of paths that couldn't be deleted] }
	 *
	 * @cfclassesDir Absolute path to a server's cfclasses directory (e.g.
	 *               LUCLI_HOME/servers/<server>/lucee-server/context/cfclasses).
	 *               If the path doesn't exist, returns empty result without
	 *               error — a pristine server has no cache to purge.
	 */
	public struct function purge(required string cfclassesDir) {
		var result = { purged: [], failed: [] };
		if (!len(arguments.cfclassesDir)) return result;
		if (!directoryExists(arguments.cfclassesDir)) return result;

		var entries = directoryList(arguments.cfclassesDir, false, "name");
		for (var entry in entries) {
			var path = arguments.cfclassesDir & "/" & entry;
			try {
				if (directoryExists(path)) {
					directoryDelete(path, true);
				} else {
					fileDelete(path);
				}
				arrayAppend(result.purged, path);
			} catch (any e) {
				arrayAppend(result.failed, path);
			}
		}
		return result;
	}

}
