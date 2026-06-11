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
	 * Used to refuse swaps that would blow away an unrelated directory.
	 */
	public boolean function looksLikeWheelsFramework(required string dir) {
		if (!directoryExists(arguments.dir)) return false;
		if (fileExists(arguments.dir & "/wheels.json")) return true;
		if (fileExists(arguments.dir & "/box.json")) return true;
		return false;
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
		try {
			var data = deserializeJSON(fileRead(manifestPath));
			if (isStruct(data) && structKeyExists(data, "version")) {
				return data.version;
			}
		} catch (any e) {
			// Malformed JSON — treat as unknown version, callers can decide.
		}
		return "";
	}

	/**
	 * Replace `vendorDir` with the contents of `sourceDir`. Both must be
	 * Wheels framework directories (or vendorDir may be absent — fresh
	 * install). When `doBackup` is true the existing vendorDir is renamed
	 * to `<vendorDir>.bak-<timestamp>` before the copy.
	 *
	 * Returns a struct describing the outcome:
	 *   - success     : boolean — did the swap complete?
	 *   - backupDir   : string  — path of the backup directory, or "" if none
	 *   - error       : string  — human-readable error on failure, "" on success
	 *   - oldVersion  : string  — version read from vendorDir BEFORE the swap
	 *   - newVersion  : string  — version read from vendorDir AFTER the swap
	 */
	public struct function applyUpgrade(
		required string sourceDir,
		required string vendorDir,
		boolean doBackup = true
	) {
		var result = {
			success: false,
			backupDir: "",
			error: "",
			oldVersion: "",
			newVersion: ""
		};

		// 1. Validate the source.
		if (!directoryExists(arguments.sourceDir)) {
			result.error = "Source framework directory does not exist: " & arguments.sourceDir;
			return result;
		}
		if (!looksLikeWheelsFramework(arguments.sourceDir)) {
			result.error = "Source does not look like a Wheels framework directory (no wheels.json or box.json): " & arguments.sourceDir;
			return result;
		}

		// 2. Validate the target's parent. We never create the vendor/ parent
		//    ourselves — if vendor/ doesn't exist, the user is almost certainly
		//    pointed at the wrong directory.
		var File = createObject("java", "java.io.File");
		var parentPath = File.init(arguments.vendorDir).getParent();
		if (isNull(parentPath) || !directoryExists(parentPath)) {
			result.error = "Parent of target directory does not exist: " & arguments.vendorDir;
			return result;
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
			result.error = "Source and target are the same directory (" & dstCanonical & ") — refusing to swap a framework with itself. Are you running `wheels upgrade` inside the wheels repo checkout?";
			return result;
		}
		var separator = "/";
		if (find("\", srcCanonical & dstCanonical)) {
			separator = "\";
		}
		if (left(srcCanonical & separator, len(dstCanonical & separator)) == dstCanonical & separator
			|| left(dstCanonical & separator, len(srcCanonical & separator)) == srcCanonical & separator) {
			result.error = "Source and target directories contain one another (source: " & srcCanonical & ", target: " & dstCanonical & ") — refusing to swap.";
			return result;
		}

		// 4. If vendorDir already exists, sniff it before destroying anything.
		if (directoryExists(arguments.vendorDir)) {
			if (!looksLikeWheelsFramework(arguments.vendorDir)) {
				result.error = "Target directory exists but does not look like a Wheels framework (no wheels.json or box.json): " & arguments.vendorDir;
				return result;
			}
			result.oldVersion = readFrameworkVersion(arguments.vendorDir);

			if (arguments.doBackup) {
				result.backupDir = $reserveBackupPath(arguments.vendorDir);
				$renameDirectory(arguments.vendorDir, result.backupDir);
			} else {
				directoryDelete(arguments.vendorDir, true);
			}
		}

		// 5. Copy the source into the target. directoryCopy with recurse=true
		//    mirrors source's contents into vendorDir.
		directoryCreate(arguments.vendorDir, true);
		directoryCopy(arguments.sourceDir, arguments.vendorDir, true);

		result.newVersion = readFrameworkVersion(arguments.vendorDir);
		result.success = true;
		return result;
	}

	/**
	 * Build a unique backup path of the form <vendorDir>.bak-<yyyymmdd>-<HHmmss>,
	 * appending a counter if a collision exists (concurrent or rapid re-runs).
	 */
	private string function $reserveBackupPath(required string vendorDir) {
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
