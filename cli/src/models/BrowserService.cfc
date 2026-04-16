/**
 * Shared service for Playwright browser JAR management.
 * Used by both browser:install and browser:test CLI commands.
 */
component {

	public struct function getManifest(required string projectRoot) {
		var manifestPath = arguments.projectRoot & "/vendor/wheels/browser-manifest.json";
		if (!fileExists(manifestPath)) {
			throw(
				type="BrowserService.ManifestMissing",
				message="browser-manifest.json not found at: " & manifestPath
			);
		}
		return deserializeJSON(fileRead(manifestPath));
	}

	public string function resolveInstallDir() {
		var envHome = "";
		try {
			envHome = createObject("java", "java.lang.System")
				.getenv("WHEELS_BROWSER_HOME") ?: "";
		} catch (any e) {}
		if (len(trim(envHome))) return envHome;
		var home = createObject("java", "java.lang.System").getProperty("user.home");
		return home & "/.wheels/browser";
	}

	public struct function verifyInstall(
		required struct manifest,
		required string installDir
	) {
		var result = {installed: true, missing: [], mismatched: []};
		for (var entry in arguments.manifest.classpath) {
			var jarPath = arguments.installDir & "/lib/" & entry.filename;
			if (!fileExists(jarPath)) {
				result.installed = false;
				arrayAppend(result.missing, entry.filename);
			} else if (sha256(jarPath) != lCase(entry.sha256)) {
				result.installed = false;
				arrayAppend(result.mismatched, entry.filename);
			}
		}
		return result;
	}

	public void function downloadJar(
		required string url,
		required string targetPath
	) {
		var parentDir = getDirectoryFromPath(arguments.targetPath);
		if (!directoryExists(parentDir)) {
			directoryCreate(parentDir, true);
		}
		cfhttp(
			url=arguments.url,
			method="GET",
			getAsBinary="yes",
			timeout=300,
			result="local.response"
		);
		if (!findNoCase("200", local.response.statusCode)) {
			throw(
				type="BrowserService.DownloadFailed",
				message="HTTP " & local.response.statusCode & " downloading " & arguments.url
			);
		}
		fileWrite(arguments.targetPath, local.response.fileContent);
	}

	public string function sha256(required string filePath) {
		var md = createObject("java", "java.security.MessageDigest")
			.getInstance("SHA-256");
		var digest = md.digest(fileReadBinary(arguments.filePath));
		return lCase(
			createObject("java", "java.util.HexFormat").of().formatHex(digest)
		);
	}

}
