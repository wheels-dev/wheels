/**
 * Picks a version from a manifest's versions[] array, filtering by
 * framework compatibility and an optional user pin.
 *
 * Reuses wheels.SemVer (shipped with #2231) so the CLI and PackageLoader
 * agree byte-for-byte on what "satisfies" means.
 *
 * Framework version comes from wheels.Global::$readFrameworkVersion() —
 * the caller passes it in so this component stays pure and testable
 * without needing an application scope.
 */
component {

	public VersionResolver function init(any semver = "") {
		variables.semver = IsObject(arguments.semver)
			? arguments.semver
			: new wheels.SemVer();
		return this;
	}

	/**
	 * @manifest  Parsed manifest struct (has `versions` array).
	 * @runtime   Current framework version string (e.g. "4.0.0").
	 * @pin       Optional user pin — either an exact version ("1.2.3")
	 *            or a SemVer constraint ("^1.0.0", ">=1.0 <2.0"), or "".
	 * @return    Chosen version entry struct (element of versions[]).
	 * @throws    Wheels.Packages.NoCompatibleVersion when nothing matches.
	 */
	public struct function pick(
		required struct manifest,
		required string runtime,
		string pin = ""
	) {
		if (!StructKeyExists(arguments.manifest, "versions")
			|| !IsArray(arguments.manifest.versions)
			|| !ArrayLen(arguments.manifest.versions)) {
			Throw(
				type = "Wheels.Packages.NoVersions",
				message = "Manifest has no versions to choose from."
			);
		}

		local.candidates = [];
		for (local.entry in arguments.manifest.versions) {
			if (!StructKeyExists(local.entry, "version") || !Len(local.entry.version)) {
				continue;
			}
			// Framework compatibility gate.
			local.constraint = StructKeyExists(local.entry, "wheelsVersion")
				? Trim(local.entry.wheelsVersion)
				: "";
			if (Len(local.constraint)
				&& !variables.semver.satisfiesAll(arguments.runtime, local.constraint)) {
				continue;
			}
			// User pin gate.
			if (Len(arguments.pin)
				&& !variables.semver.satisfiesAll(local.entry.version, arguments.pin)) {
				continue;
			}
			ArrayAppend(local.candidates, local.entry);
		}

		if (!ArrayLen(local.candidates)) {
			local.known = [];
			for (local.any in arguments.manifest.versions) {
				ArrayAppend(local.known, local.any.version ?: "?");
			}
			Throw(
				type = "Wheels.Packages.NoCompatibleVersion",
				message = "No version of '#(arguments.manifest.name ?: "package")#' "
					& "satisfies runtime '#arguments.runtime#'"
					& (Len(arguments.pin) ? " and pin '#arguments.pin#'" : "") & ".",
				extendedInfo = "Available versions: " & ArrayToList(local.known, ", ")
			);
		}

		// Highest SemVer wins.
		local.best = local.candidates[1];
		for (local.i = 2; local.i <= ArrayLen(local.candidates); local.i++) {
			if (variables.semver.compare(local.candidates[local.i].version, local.best.version) > 0) {
				local.best = local.candidates[local.i];
			}
		}
		return local.best;
	}

	/**
	 * Returns every version compatible with the runtime (no pin), ordered
	 * highest → lowest. Used by `wheels packages show` to display history.
	 */
	public array function compatibleVersions(
		required struct manifest,
		required string runtime
	) {
		local.compatible = [];
		if (!StructKeyExists(arguments.manifest, "versions")
			|| !IsArray(arguments.manifest.versions)) {
			return local.compatible;
		}
		for (local.entry in arguments.manifest.versions) {
			if (!StructKeyExists(local.entry, "version") || !Len(local.entry.version)) {
				continue;
			}
			local.constraint = StructKeyExists(local.entry, "wheelsVersion")
				? Trim(local.entry.wheelsVersion)
				: "";
			if (Len(local.constraint)
				&& !variables.semver.satisfiesAll(arguments.runtime, local.constraint)) {
				continue;
			}
			ArrayAppend(local.compatible, local.entry);
		}
		// Sort highest first. Simple insertion sort to sidestep ArraySort
		// callback quirks across Lucee/Adobe and avoid arrow-fn parsing pitfalls.
		for (local.i = 2; local.i <= ArrayLen(local.compatible); local.i++) {
			local.cur = local.compatible[local.i];
			local.j = local.i - 1;
			while (local.j >= 1
				&& variables.semver.compare(local.compatible[local.j].version, local.cur.version) < 0) {
				local.compatible[local.j + 1] = local.compatible[local.j];
				local.j--;
			}
			local.compatible[local.j + 1] = local.cur;
		}
		return local.compatible;
	}
}
