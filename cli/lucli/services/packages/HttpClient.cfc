/**
 * Thin HTTP GET wrapper. Exists so Registry can be tested offline with
 * a fake that returns canned responses keyed by URL.
 *
 * Uses cfhttp (script syntax) for cross-engine portability — `new http()`
 * is Lucee-specific and the framework test matrix also runs these specs
 * against Adobe CF.
 */
component {

	public HttpClient function init(numeric timeoutSeconds = 30) {
		variables.timeout = arguments.timeoutSeconds;
		return this;
	}

	/**
	 * @return struct { status: numeric, body: string }
	 */
	public struct function get(required string url, struct headers = {}) {
		if (request.$wheelsOffline ?: false) {
			Throw(
				type = "Wheels.Packages.Offline",
				message = "Offline mode is enabled by --offline or WHEELS_OFFLINE=1; #arguments.url# needs network access."
			);
		}
		cfhttp(
			url = arguments.url,
			method = "GET",
			timeout = variables.timeout,
			result = "local.result"
		) {
			for (local.name in arguments.headers) {
				cfhttpparam(type = "header", name = local.name, value = arguments.headers[local.name]);
			}
			// GitHub's API prefers an explicit User-Agent on unauth requests.
			cfhttpparam(type = "header", name = "User-Agent", value = "wheels-cli");
		}
		return {
			status: Val(ListFirst(local.result.statusCode, " ")),
			body: local.result.fileContent ?: ""
		};
	}

	/**
	 * Downloads bytes to disk. Separate from get() because tarballs are
	 * large binary and `fileContent` as a string is the wrong abstraction.
	 * Returns the destination path on success, throws on non-200.
	 */
	public string function download(required string url, required string destPath) {
		// --offline / WHEELS_OFFLINE=1 keeps `wheels packages` off the network:
		// the registry index and manifests are gated in Registry, and package
		// tarballs are never cached, so a download is refused here too.
		if (request.$wheelsOffline ?: false) {
			Throw(
				type = "Wheels.Packages.Offline",
				message = "Offline mode is enabled (--offline / WHEELS_OFFLINE=1) — downloading the package tarball requires network access. Run again without --offline to install."
			);
		}
		cfhttp(
			url = arguments.url,
			method = "GET",
			timeout = variables.timeout,
			getAsBinary = "yes",
			result = "local.result"
		) {
			cfhttpparam(type = "header", name = "User-Agent", value = "wheels-cli");
		}
		local.status = Val(ListFirst(local.result.statusCode, " "));
		if (local.status != 200) {
			Throw(
				type = "Wheels.Packages.DownloadFailed",
				message = "Download failed: HTTP #local.status# for #arguments.url#"
			);
		}
		FileWrite(arguments.destPath, local.result.fileContent);
		return arguments.destPath;
	}
}
