/**
 * Fetches a resolved package version, verifies sha256, extracts to
 * vendor/<name>/.
 *
 * Flow:
 *   1. Refuse if vendor/<name>/ already exists, unless force=true.
 *   2. Download tarball URL from the version entry to a temp file.
 *   3. Compute SHA-256, compare to the manifest's sha256. Mismatch = hard abort.
 *   4. Extract via `tar -xzmf` into vendor/. The tarball's top-level dir
 *      is the package name by construction (mirror-tarball.yml
 *      `mv src/ <name>/` before taring), so vendor/<name>/ appears naturally.
 *      `-m` is required: source tarballs are built with `--mtime=@0` for
 *      reproducible sha256, but Lucee 7 cannot compile CFCs whose mtime is
 *      epoch-0. Without `-m` the package "extracts cleanly" but every helper
 *      call 500s with a misleading "invalid component definition" error.
 *   5. Swap the verified tree into vendor/<name>/. An existing copy is
 *      renamed aside first and restored if the move fails.
 *   6. Clean up the temp file and the staging dir.
 *
 * Tarball extraction shells out to `tar`. All target platforms (macOS,
 * Linux, Windows 10+) ship it. If Windows Server compat becomes a real
 * need, swap the $extract() body for a Commons Compress JAR-based impl
 * without changing the Installer surface.
 */
component {

	public Installer function init(
		any httpClient = "",
		string projectRoot = ""
	) {
		variables.http = IsObject(arguments.httpClient)
			? arguments.httpClient
			: new modules.wheels.services.packages.HttpClient();
		variables.projectRoot = Len(arguments.projectRoot)
			? arguments.projectRoot
			: ExpandPath("./");
		if (Right(variables.projectRoot, 1) != "/") {
			variables.projectRoot &= "/";
		}
		return this;
	}

	/**
	 * @name     Package name (becomes vendor/<name>/).
	 * @version  Version entry struct (must have tarball + sha256).
	 * @force    Overwrite vendor/<name>/ if it exists.
	 * @return   Absolute path of vendor/<name>/.
	 * @throws   Wheels.Packages.AlreadyInstalled
	 *           Wheels.Packages.ChecksumMismatch
	 *           Wheels.Packages.ExtractionFailed
	 */
	public string function install(
		required string name,
		required struct version,
		boolean force = false
	) {
		if (!StructKeyExists(arguments.version, "tarball") || !Len(arguments.version.tarball)) {
			Throw(
				type = "Wheels.Packages.ManifestIncomplete",
				message = "Version entry for '#arguments.name#' has no tarball URL. "
					& "The registry mirror may not have populated this version yet."
			);
		}
		if (!StructKeyExists(arguments.version, "sha256") || !Len(arguments.version.sha256)) {
			Throw(
				type = "Wheels.Packages.ManifestIncomplete",
				message = "Version entry for '#arguments.name#' has no sha256. Refusing to install unverified content."
			);
		}

		local.vendorDir = variables.projectRoot & "vendor/";
		// Validates the name and pins the target to a direct child of vendor/
		// before anything below deletes, downloads or extracts.
		local.target = new modules.wheels.services.packages.PackageName().childOf(local.vendorDir, arguments.name);

		if (DirectoryExists(local.target) && !arguments.force) {
			Throw(
				type = "Wheels.Packages.AlreadyInstalled",
				message = "Package '#arguments.name#' is already installed at #local.target#. "
					& "Use --force to overwrite."
			);
		}

		// Download to a temp file and extract into a private staging directory.
		// Normalize the separator: engines differ on whether GetTempDirectory()
		// carries a trailing slash (RustCFML does not), and a bare concatenation
		// would target the filesystem root.
		local.tmpDir = GetTempDirectory();
		if (Right(local.tmpDir, 1) != "/" && Right(local.tmpDir, 1) != "\") {
			local.tmpDir &= "/";
		}
		local.token = CreateUUID();
		local.tmpFile = local.tmpDir & "wheels-pkg-" & local.token & ".tar.gz";
		local.stageDir = local.tmpDir & "wheels-pkg-stage-" & local.token & "/";
		try {
			variables.http.download(arguments.version.tarball, local.tmpFile);

			// Verify sha256.
			local.actual = LCase($sha256File(local.tmpFile));
			local.expected = LCase(arguments.version.sha256);
			if (local.actual != local.expected) {
				Throw(
					type = "Wheels.Packages.ChecksumMismatch",
					message = "sha256 mismatch for '#arguments.name#@#arguments.version.version#'. "
						& "Expected #local.expected#, got #local.actual#. "
						& "Refusing to install — the tarball does not match the registry's record."
				);
			}

			// Extract into staging and check the layout before vendor/ is touched:
			// only a single <name>/ tree (with package.json, no links) is moved in.
			// Extraction itself stays inside stageDir because GNU tar and bsdtar
			// refuse absolute and ".." member names by default; the layout check
			// below then governs what may leave staging.
			DirectoryCreate(local.stageDir, true);
			$extract(local.tmpFile, local.stageDir);
			new modules.wheels.services.packages.PackageLayout().assertSingleTree(local.stageDir, arguments.name);

			if (!DirectoryExists(local.vendorDir)) {
				DirectoryCreate(local.vendorDir, true);
			}
			// The previous install is replaced only once the new one is verified,
			// and kept beside it until the new copy is in place. The leading dot
			// keeps PackageLoader from loading the backup.
			$swapInto(local.stageDir & arguments.name, local.target, local.vendorDir & ".wheels-pkg-previous-" & local.token);
		} finally {
			if (FileExists(local.tmpFile)) {
				FileDelete(local.tmpFile);
			}
			if (DirectoryExists(local.stageDir)) {
				DirectoryDelete(local.stageDir, true);
			}
		}

		return local.target;
	}

	/**
	 * Deletes vendor/<name>/ after a safety check that it has a package.json.
	 * Throws if the dir doesn't exist or doesn't look like a Wheels package.
	 */
	public void function uninstall(required string name) {
		local.target = new modules.wheels.services.packages.PackageName().childOf(variables.projectRoot & "vendor/", arguments.name);
		if (!DirectoryExists(local.target)) {
			Throw(
				type = "Wheels.Packages.NotInstalled",
				message = "Package '#arguments.name#' is not installed (no #local.target#)."
			);
		}
		if (!FileExists(local.target & "/package.json")) {
			Throw(
				type = "Wheels.Packages.NotAPackage",
				message = "vendor/#arguments.name# has no package.json — refusing to delete. "
					& "Remove it manually if you're sure."
			);
		}
		DirectoryDelete(local.target, true);
	}

	public boolean function isInstalled(required string name) {
		return DirectoryExists(new modules.wheels.services.packages.PackageName().childOf(variables.projectRoot & "vendor/", arguments.name));
	}

	public string function installedVersion(required string name) {
		local.pkgJson = new modules.wheels.services.packages.PackageName().childOf(variables.projectRoot & "vendor/", arguments.name) & "/package.json";
		if (!FileExists(local.pkgJson)) return "";
		try {
			local.parsed = DeserializeJSON(FileRead(local.pkgJson));
			return local.parsed.version ?: "";
		} catch (any e) {
			return "";
		}
	}

	// ── Private ─────────────────────────────────────────────

	/**
	 * Moves a verified staged tree to target. An existing target is renamed
	 * aside first (same directory, so a plain rename) and renamed back if the
	 * move fails, so a failed swap never leaves the app without the package.
	 */
	private void function $swapInto(required string src, required string target, required string backupDir) {
		local.hadOld = DirectoryExists(arguments.target);
		if (local.hadOld) {
			DirectoryRename(arguments.target, arguments.backupDir);
		}
		try {
			$moveInto(arguments.src, arguments.target);
		} catch (any e) {
			if (local.hadOld) {
				// A cross-volume copy can stop part way; drop what it wrote.
				if (DirectoryExists(arguments.target)) {
					DirectoryDelete(arguments.target, true);
				}
				DirectoryRename(arguments.backupDir, arguments.target);
			}
			rethrow;
		}
		if (local.hadOld) {
			// Best-effort: the new copy is in place; a leftover backup is only clutter.
			try {
				DirectoryDelete(arguments.backupDir, true);
			} catch (any e) {
			}
		}
	}

	/** Moves a staged tree into place; falls back to copy+delete across volumes. */
	private void function $moveInto(required string src, required string dest) {
		try {
			DirectoryRename(arguments.src, arguments.dest);
		} catch (any e) {
			DirectoryCopy(arguments.src, arguments.dest, true);
			DirectoryDelete(arguments.src, true);
		}
	}

	private string function $sha256File(required string path) {
		local.bin = FileReadBinary(arguments.path);
		return Hash(local.bin, "SHA-256");
	}

	private void function $extract(required string tarballPath, required string destDir) {
		// `-m` (--touch) discards the tarball's stored mtime and stamps each
		// extracted file with the current time. Critical because mirror-tarball
		// builds packages with `--mtime=@0` for reproducible sha256 — and
		// Lucee 7's class-resolver treats epoch-0 CFCs as unloadable, surfacing
		// the failure as the very generic "invalid component definition, can't
		// find component [vendor.NAME.CFC]" error. Using `-m` here avoids
		// the issue without giving up determinism in the source tarballs.
		// Both GNU tar (Linux) and BSD tar (macOS bundled) accept `-m` with the
		// same "extract with current mtime" semantics.
		local.result = {};
		try {
			cfexecute(
				name = "tar",
				arguments = "-xzmf #arguments.tarballPath# -C #arguments.destDir#",
				timeout = 120,
				variable = "local.stdout",
				errorVariable = "local.stderr",
				result = "local.result"
			);
		} catch (any e) {
			Throw(
				type = "Wheels.Packages.ExtractionFailed",
				message = "Failed to extract tarball. Is `tar` on PATH?",
				extendedInfo = e.message
			);
		}
		// Gate on exit code, not stderr presence. GNU tar on Linux prints
		// informational warnings ("Ignoring unknown extended header keyword
		// 'LIBARCHIVE.xattr.com.apple.provenance'") for macOS-authored
		// tarballs while still exiting 0 and extracting cleanly.
		var exitCode = StructKeyExists(local.result, "exitCode") ? local.result.exitCode : 0;
		if (exitCode != 0) {
			var stderr = StructKeyExists(local, "stderr") ? local.stderr : "";
			Throw(
				type = "Wheels.Packages.ExtractionFailed",
				message = "tar exited with code #exitCode# during extraction.",
				extendedInfo = stderr
			);
		}
	}
}
