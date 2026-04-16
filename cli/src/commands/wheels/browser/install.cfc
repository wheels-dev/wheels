/**
 * Install Playwright browser binaries for E2E testing.
 *
 * Downloads 7 JARs from Maven Central (Playwright client + driver +
 * driver-bundle + transitive deps), verifies SHA-256 hashes, then
 * installs browser binaries via the Playwright CLI.
 *
 * Examples:
 *   wheels browser:install
 *   wheels browser:install --force
 *   wheels browser:install --browser=firefox
 */
component aliases="wheels browser:install, wheels browser install" extends="../../base" {

	property name="browserService" inject="BrowserService@wheels-cli";

	/**
	 * @force     Re-download JARs even if SHAs match
	 * @browser   Which browser to install (chromium, firefox, webkit)
	 */
	function run(
		boolean force = false,
		string browser = "chromium"
	) {
		var projectRoot = getCWD();
		var manifest = {};
		try {
			manifest = browserService.getManifest(projectRoot);
		} catch (any e) {
			print.redLine("Error: " & e.message);
			return;
		}

		var installDir = browserService.resolveInstallDir();
		print.line("Install directory: " & installDir);
		print.line("Playwright version: " & (manifest.playwrightJavaVersion ?: "unknown"));
		print.line("");

		var downloaded = 0;
		var skipped = 0;
		for (var entry in manifest.classpath) {
			var jarPath = installDir & "/lib/" & entry.filename;
			var needsDownload = arguments.force;

			if (!fileExists(jarPath)) {
				needsDownload = true;
			} else if (!arguments.force) {
				var currentSha = browserService.sha256(jarPath);
				if (currentSha != lCase(entry.sha256)) {
					print.yellowLine("  SHA mismatch: " & entry.filename & " - re-downloading");
					needsDownload = true;
				}
			}

			if (needsDownload) {
				print.text("  Downloading " & entry.filename & "...");
				try {
					browserService.downloadJar(url=entry.url, targetPath=jarPath);
					var sha = browserService.sha256(jarPath);
					if (sha != lCase(entry.sha256)) {
						print.redLine(" FAILED (SHA mismatch)");
						print.redLine("    Expected: " & lCase(entry.sha256));
						print.redLine("    Got:      " & sha);
						return;
					}
					print.greenLine(" OK");
					downloaded++;
				} catch (any e) {
					print.redLine(" FAILED: " & e.message);
					return;
				}
			} else {
				print.line("  " & chr(10003) & " " & entry.filename);
				skipped++;
			}
		}

		print.line("");
		print.line("JARs: " & downloaded & " downloaded, " & skipped & " up-to-date");

		print.line("");
		print.text("Installing " & arguments.browser & " browser binaries...");

		var classpath = "";
		for (var entry in manifest.classpath) {
			if (len(classpath)) classpath &= ":";
			classpath &= installDir & "/lib/" & entry.filename;
		}

		try {
			cfexecute(
				name="java",
				arguments="-cp " & classpath & " com.microsoft.playwright.CLI install " & arguments.browser,
				timeout=300,
				variable="local.stdout",
				errorVariable="local.stderr"
			);
			print.greenLine(" OK");
		} catch (any e) {
			print.redLine(" FAILED");
			print.redLine(local.stderr ?: e.message);
			return;
		}

		print.line("");
		print.greenLine("Browser testing ready. Run: wheels browser:test");
	}

}
