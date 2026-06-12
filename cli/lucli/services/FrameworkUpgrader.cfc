/**
 * In-place framework swap that powers `wheels upgrade` (#3035).
 *
 * Replaces the contents of the app's vendor/wheels/ with a fresh copy
 * of the framework (typically the CLI's bundled vendor/wheels/). The
 * old vendor/wheels/ is renamed to vendor/wheels.bak-<timestamp> by
 * default so a mistake is recoverable with a single mv.
 *
 * Isolated from Module.cfc so tests can exercise the file-level
 * behavior without the LuCLI runtime (mirrors FrameworkInstaller.cfc).
 */
component {

	public function init() {
		return this;
	}

	/**
	 * Quick sniff test — does this look like a Wheels framework directory?
	 * Used to refuse swaps that would blow away an unrelated directory, on
	 * both sides: the source (don't vendor a random folder into the app)
	 * and the target (don't back up / delete something that isn't a
	 * framework).
	 *
	 * A bare box.json is not evidence enough (#3039 review) — every
	 * CommandBox-era CFML project has one. Require a wheels.json with a
	 * parseable non-empty `version`, or a box.json whose `version` is
	 * non-empty and whose `name`/`slug` (when present) identify a wheels
	 * artifact. A version-only box.json (no name/slug) is accepted — old
	 * framework drops shipped exactly that shape.
	 */
	public boolean function looksLikeWheelsFramework(required string dir) {
		if (!directoryExists(arguments.dir)) return false;
		var manifest = {};
		if (fileExists(arguments.dir & "/wheels.json")) {
			manifest = $readManifest(arguments.dir & "/wheels.json");
			if (structKeyExists(manifest, "version") && isSimpleValue(manifest.version) && len(trim(manifest.version))) {
				return true;
			}
		}
		if (fileExists(arguments.dir & "/box.json")) {
			manifest = $readManifest(arguments.dir & "/box.json");
			if (!structKeyExists(manifest, "version") || !isSimpleValue(manifest.version) || !len(trim(manifest.version))) {
				return false;
			}
			var identifiers = [];
			if (structKeyExists(manifest, "name") && isSimpleValue(manifest.name)) {
				arrayAppend(identifiers, manifest.name);
			}
			if (structKeyExists(manifest, "slug") && isSimpleValue(manifest.slug)) {
				arrayAppend(identifiers, manifest.slug);
			}
			if (arrayLen(identifiers) == 0) {
				return true;
			}
			for (var identifier in identifiers) {
				if (findNoCase("wheels", identifier)) {
					return true;
				}
			}
		}
		return false;
	}

	/**
	 * Read and parse a JSON manifest. Returns an empty struct when the file
	 * is unreadable, malformed, or not a JSON object.
	 */
	private struct function $readManifest(required string path) {
		try {
			var data = deserializeJSON(fileRead(arguments.path));
			if (isStruct(data)) {
				return data;
			}
		} catch (any e) {
			// Malformed JSON — callers treat an empty struct as "no evidence".
		}
		return {};
	}

	/**
	 * Read the `version` field from a framework dir's wheels.json (preferred)
	 * or box.json (legacy fallback). Returns "" if no manifest is present or
	 * the version field is missing/unparsable.
	 */
	public string function readFrameworkVersion(required string dir) {
		var manifestPath = arguments.dir & "/wheels.json";
		if (!fileExists(manifestPath)) {
			manifestPath = arguments.dir & "/box.json";
			if (!fileExists(manifestPath)) return "";
		}
		var data = $readManifest(manifestPath);
		if (structKeyExists(data, "version") && isSimpleValue(data.version)) {
			return data.version;
		}
		return "";
	}

	/**
	 * Run every pre-mutation refusal check for a sourceDir -> vendorDir
	 * swap. Returns "" when the swap may proceed, or the human-readable
	 * refusal otherwise. Pure reads — no file is created, renamed, or
	 * deleted — so callers can (and must) run it BEFORE announcing the
	 * swap plan: printing the backup destination and the `rm -rf … && mv …`
	 * restore one-liner ahead of a refusal would hand the user a recovery
	 * command for a backup that was never made (#3039 review).
	 * applyUpgrade() re-runs it first, so direct service callers keep the
	 * exact same refusal behavior.
	 */
	public string function validateSwap(required string sourceDir, required string vendorDir) {
		// 1. Validate the source.
		if (!directoryExists(arguments.sourceDir)) {
			return "Source framework directory does not exist: " & arguments.sourceDir;
		}
		if (!looksLikeWheelsFramework(arguments.sourceDir)) {
			return "Source does not look like a Wheels framework directory (need a wheels.json or box.json whose version and name identify a Wheels framework): " & arguments.sourceDir;
		}

		// 2. Validate the target's parent. We never create the vendor/ parent
		//    ourselves — if vendor/ doesn't exist, the user is almost certainly
		//    pointed at the wrong directory.
		var File = createObject("java", "java.io.File");
		var parentPath = File.init(arguments.vendorDir).getParent();
		if (isNull(parentPath) || !directoryExists(parentPath)) {
			return "Parent of target directory does not exist: " & arguments.vendorDir;
		}

		// 3. Identity / containment guard — BEFORE any destructive step.
		//    Running `wheels upgrade` inside the wheels repo checkout itself
		//    resolves the bundled source to the very vendor/wheels/ being
		//    replaced; the backup rename (or --nobackup delete) would destroy
		//    the source mid-swap. Containment in either direction is just as
		//    fatal: copying a parent into its own child recurses, and copying
		//    a child of the target reads from a directory we just renamed.
		var srcCanonical = File.init(arguments.sourceDir).getCanonicalPath();
		var dstCanonical = File.init(arguments.vendorDir).getCanonicalPath();
		if (srcCanonical == dstCanonical) {
			return "Source and target are the same directory (" & dstCanonical & ") — refusing to swap a framework with itself. Are you running `wheels upgrade` inside the wheels repo checkout?";
		}
		var separator = "/";
		if (find("\", srcCanonical & dstCanonical)) {
			separator = "\";
		}
		if (left(srcCanonical & separator, len(dstCanonical & separator)) == dstCanonical & separator
			|| left(dstCanonical & separator, len(srcCanonical & separator)) == srcCanonical & separator) {
			return "Source and target directories contain one another (source: " & srcCanonical & ", target: " & dstCanonical & ") — refusing to swap.";
		}

		// 4. If vendorDir already exists, sniff it before destroying anything.
		if (directoryExists(arguments.vendorDir) && !looksLikeWheelsFramework(arguments.vendorDir)) {
			return "Target directory exists but does not look like a Wheels framework (need a wheels.json or box.json whose version and name identify a Wheels framework): " & arguments.vendorDir;
		}

		return "";
	}

	/**
	 * Replace `vendorDir` with the contents of `sourceDir`. Both must be
	 * Wheels framework directories (or vendorDir may be absent — fresh
	 * install). When `doBackup` is true the existing vendorDir is renamed
	 * to `<vendorDir>.bak-<timestamp>` before the copy. Callers that want
	 * to announce the backup destination BEFORE invoking the swap can
	 * reserve it via reserveBackupPath() and pass it in as `backupPath` —
	 * the announced path and the actual backup are then guaranteed to
	 * agree. When `backupPath` is empty the path is reserved here.
	 *
	 * Returns a struct describing the outcome:
	 *   - success     : boolean — did the swap complete?
	 *   - backupDir   : string  — path of the backup directory, or "" if none
	 *   - error       : string  — human-readable error on failure, "" on success
	 *   - oldVersion  : string  — version read from vendorDir BEFORE the swap
	 *   - newVersion  : string  — version read from vendorDir AFTER the swap
	 *
	 * Throws Wheels.FrameworkUpgrader.CopyFailed when the copy step fails
	 * AFTER the destructive backup-rename/delete already ran — the message
	 * names the partial-state target and the backup to restore from (or,
	 * with no backup, says the old tree is gone and how to re-vendor).
	 * Validation refusals before any mutation come back as result.error.
	 */
	public struct function applyUpgrade(
		required string sourceDir,
		required string vendorDir,
		boolean doBackup = true,
		string backupPath = ""
	) {
		var result = {
			success: false,
			backupDir: "",
			error: "",
			oldVersion: "",
			newVersion: ""
		};

		// Pre-mutation refusal checks. Callers that announce the swap plan
		// (backup destination + restore one-liner) run validateSwap() first
		// so refusals never print recovery guidance for a backup that was
		// never made (#3039 review) — re-running it here keeps the service
		// safe for direct callers, and the checks are idempotent reads.
		result.error = validateSwap(arguments.sourceDir, arguments.vendorDir);
		if (len(result.error)) {
			return result;
		}

		// If vendorDir already exists (validateSwap confirmed it sniffs as a
		// framework), record its version and park or delete it.
		if (directoryExists(arguments.vendorDir)) {
			result.oldVersion = readFrameworkVersion(arguments.vendorDir);

			if (arguments.doBackup) {
				result.backupDir = len(trim(arguments.backupPath)) ? arguments.backupPath : reserveBackupPath(arguments.vendorDir);
				$renameDirectory(arguments.vendorDir, result.backupDir);
			} else {
				directoryDelete(arguments.vendorDir, true);
			}
		}

		// Copy the source into the target. directoryCopy with recurse=true
		//    mirrors source's contents into vendorDir. From here on the old
		//    tree is already renamed away (or deleted) — a failure must not
		//    surface as a bare stack trace over an unannounced partial state
		//    (#3039 review), so name the recovery path explicitly.
		try {
			directoryCreate(arguments.vendorDir, true);
			directoryCopy(arguments.sourceDir, arguments.vendorDir, true);
		} catch (any e) {
			if (len(result.backupDir)) {
				throw(
					type = "Wheels.FrameworkUpgrader.CopyFailed",
					message = "Copying the new framework failed partway (#e.message#). ""#arguments.vendorDir#"" is in a partial state — restore the backup with: rm -rf ""#arguments.vendorDir#"" && mv ""#result.backupDir#"" ""#arguments.vendorDir#"""
				);
			}
			throw(
				type = "Wheels.FrameworkUpgrader.CopyFailed",
				message = "Copying the new framework failed partway (#e.message#) and no backup exists (--nobackup) — the old ""#arguments.vendorDir#"" tree is gone. Fix the cause above, then re-run `wheels upgrade apply` to re-vendor the framework from the CLI bundle."
			);
		}

		result.newVersion = readFrameworkVersion(arguments.vendorDir);
		result.success = true;
		return result;
	}

	/**
	 * Build a unique backup path of the form <vendorDir>.bak-<yyyymmdd>-<HHmmss>,
	 * appending a counter if a collision exists (concurrent or rapid re-runs).
	 * Public so callers can announce the exact backup destination (and the
	 * recovery one-liner) before invoking applyUpgrade — pass the reserved
	 * path back in via `backupPath` so the plan and the swap can't disagree.
	 */
	public string function reserveBackupPath(required string vendorDir) {
		var ts = dateFormat(now(), "yyyymmdd") & "-" & timeFormat(now(), "HHmmss");
		var candidate = arguments.vendorDir & ".bak-" & ts;
		var counter = 1;
		while (directoryExists(candidate)) {
			candidate = arguments.vendorDir & ".bak-" & ts & "-" & counter;
			counter++;
		}
		return candidate;
	}

	/**
	 * Atomic-ish directory rename via Java's File.renameTo. CFML's
	 * directoryRename isn't available on every engine the CLI may host
	 * under, and the cross-filesystem semantics are inconsistent — falling
	 * through to copy+delete here would defeat the "single mv to recover"
	 * promise we want for backups, so we surface the rename failure.
	 */
	private void function $renameDirectory(required string fromPath, required string toPath) {
		var File = createObject("java", "java.io.File");
		var src = File.init(arguments.fromPath);
		var dst = File.init(arguments.toPath);
		if (!src.renameTo(dst)) {
			throw(
				type = "Wheels.FrameworkUpgrader.RenameFailed",
				message = "Failed to rename " & arguments.fromPath & " to " & arguments.toPath & ". The backup directory must live on the same filesystem as vendor/wheels/."
			);
		}
	}

}
