/**
 * Fetches a resolved package version, verifies sha256, extracts to
 * vendor/<name>/.
 *
 * Flow:
 *   1. Refuse if vendor/<name>/ already exists, unless force=true.
 *   2. Download tarball URL from the version entry to a temp file.
 *   3. Compute SHA-256, compare to the manifest's sha256. Mismatch = hard abort.
 *   4. Extract via `tar -xzf` into vendor/. The tarball's top-level dir
 *      is the package name by construction (mirror-tarball.yml
 *      `mv src/ <name>/` before taring), so vendor/<name>/ appears naturally.
 *   5. Clean up the temp file.
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
		local.target = local.vendorDir & arguments.name;

		if (DirectoryExists(local.target)) {
			if (!arguments.force) {
				Throw(
					type = "Wheels.Packages.AlreadyInstalled",
					message = "Package '#arguments.name#' is already installed at #local.target#. "
						& "Use --force to overwrite."
				);
			}
			DirectoryDelete(local.target, true);
		}

		if (!DirectoryExists(local.vendorDir)) {
			DirectoryCreate(local.vendorDir, true);
		}

		// Download to a temp file.
		local.tmpFile = GetTempDirectory() & "wheels-pkg-" & CreateUUID() & ".tar.gz";
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

			// Extract.
			$extract(local.tmpFile, local.vendorDir);

			if (!DirectoryExists(local.target)) {
				Throw(
					type = "Wheels.Packages.ExtractionFailed",
					message = "Extraction completed but vendor/#arguments.name#/ was not produced. "
						& "The tarball layout does not match the expected '<name>/...' convention."
				);
			}
		} finally {
			if (FileExists(local.tmpFile)) {
				FileDelete(local.tmpFile);
			}
		}

		return local.target;
	}

	/**
	 * Deletes vendor/<name>/ after a safety check that it has a package.json.
	 * Throws if the dir doesn't exist or doesn't look like a Wheels package.
	 */
	public void function uninstall(required string name) {
		local.target = variables.projectRoot & "vendor/" & arguments.name;
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
		return DirectoryExists(variables.projectRoot & "vendor/" & arguments.name);
	}

	public string function installedVersion(required string name) {
		local.pkgJson = variables.projectRoot & "vendor/" & arguments.name & "/package.json";
		if (!FileExists(local.pkgJson)) return "";
		try {
			local.parsed = DeserializeJSON(FileRead(local.pkgJson));
			return local.parsed.version ?: "";
		} catch (any e) {
			return "";
		}
	}

	// ── Private ─────────────────────────────────────────────

	private string function $sha256File(required string path) {
		local.bin = FileReadBinary(arguments.path);
		return Hash(local.bin, "SHA-256");
	}

	private void function $extract(required string tarballPath, required string destDir) {
		// Wrap in a try so a missing `tar` produces a clear error message.
		local.result = {};
		try {
			cfexecute(
				name = "tar",
				arguments = "-xzf #arguments.tarballPath# -C #arguments.destDir#",
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
