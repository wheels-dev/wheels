component {

	/**
	 * Returns the resolved URL for a Vite entrypoint. In production, reads the Vite manifest
	 * to return the fingerprinted asset path. In development, returns the Vite dev server URL.
	 *
	 * [section: View Helpers]
	 * [category: Asset Functions]
	 *
	 * @entrypoint The source entrypoint path as defined in your Vite config (e.g. "src/main.js").
	 */
	public string function viteAsset(required string entrypoint) {
		if ($viteDevMode()) {
			return $viteDevUrl(arguments.entrypoint);
		}
		local.manifest = $viteManifest();
		if (!StructKeyExists(local.manifest, arguments.entrypoint)) {
			if ($get("showErrorInformation")) {
				Throw(
					type="Wheels.ViteAssetNotFound",
					message="Vite entrypoint '#arguments.entrypoint#' not found in manifest.",
					extendedInfo="Available entrypoints: #StructKeyList(local.manifest)#. Run your Vite build to generate the manifest."
				);
			}
			return arguments.entrypoint;
		}
		return $get("webPath") & $get("viteBuildPath") & "/" & local.manifest[arguments.entrypoint].file;
	}

	/**
	 * Returns `<script>` tags for a Vite JS entrypoint. In development, also injects the Vite
	 * client for Hot Module Replacement (HMR). In production, includes any associated CSS files
	 * from the manifest as `<link>` tags.
	 *
	 * [section: View Helpers]
	 * [category: Asset Functions]
	 *
	 * @entrypoint The source entrypoint path (e.g. "src/main.js").
	 * @head Set to `true` to place output in the `<head>` area instead of inline.
	 */
	public string function viteScriptTag(required string entrypoint, boolean head = false) {
		local.rv = "";

		if ($viteDevMode()) {
			local.devUrl = $get("viteDevServerUrl");
			local.rv = '<script type="module" src="#local.devUrl#/@vite/client"></script>' & Chr(10);
			local.rv &= '<script type="module" src="#$viteDevUrl(arguments.entrypoint)#"></script>' & Chr(10);
		} else {
			local.manifest = $viteManifest();
			if (!StructKeyExists(local.manifest, arguments.entrypoint)) {
				if ($get("showErrorInformation")) {
					Throw(
						type="Wheels.ViteAssetNotFound",
						message="Vite entrypoint '#arguments.entrypoint#' not found in manifest.",
						extendedInfo="Available entrypoints: #StructKeyList(local.manifest)#. Run your Vite build to generate the manifest."
					);
				}
				return "";
			}
			local.entry = local.manifest[arguments.entrypoint];
			local.buildPath = $get("webPath") & $get("viteBuildPath");

			// Emit <link> tags for associated CSS files
			if (StructKeyExists(local.entry, "css") && IsArray(local.entry.css)) {
				for (local.cssFile in local.entry.css) {
					local.rv &= '<link rel="stylesheet" href="#local.buildPath#/#local.cssFile#" />' & Chr(10);
				}
			}

			local.rv &= '<script type="module" src="#local.buildPath#/#local.entry.file#"></script>' & Chr(10);
		}

		if (arguments.head) {
			$htmlhead(text=local.rv);
			return "";
		}
		return local.rv;
	}

	/**
	 * Returns a `<link>` tag for a Vite CSS entrypoint. In development, Vite injects CSS via
	 * the JS client so this returns an empty string. In production, resolves the fingerprinted path.
	 *
	 * [section: View Helpers]
	 * [category: Asset Functions]
	 *
	 * @entrypoint The source CSS entrypoint path (e.g. "src/main.css").
	 * @head Set to `true` to place output in the `<head>` area instead of inline.
	 */
	public string function viteStyleTag(required string entrypoint, boolean head = false) {
		if ($viteDevMode()) {
			// In dev mode, Vite injects CSS through the JS client via HMR
			return "";
		}

		local.manifest = $viteManifest();
		if (!StructKeyExists(local.manifest, arguments.entrypoint)) {
			if ($get("showErrorInformation")) {
				Throw(
					type="Wheels.ViteAssetNotFound",
					message="Vite entrypoint '#arguments.entrypoint#' not found in manifest.",
					extendedInfo="Available entrypoints: #StructKeyList(local.manifest)#. Run your Vite build to generate the manifest."
				);
			}
			return "";
		}

		local.entry = local.manifest[arguments.entrypoint];
		local.buildPath = $get("webPath") & $get("viteBuildPath");
		local.rv = '<link rel="stylesheet" href="#local.buildPath#/#local.entry.file#" />' & Chr(10);

		if (arguments.head) {
			$htmlhead(text=local.rv);
			return "";
		}
		return local.rv;
	}

	/**
	 * Reads and caches the Vite manifest.json file. The manifest is cached in the application
	 * scope for the lifetime of the application (cleared on reload).
	 */
	public struct function $viteManifest() {
		if (
			StructKeyExists(application, "$wheels")
			&& StructKeyExists(application.$wheels, "viteManifestCache")
			&& IsStruct(application.$wheels.viteManifestCache)
		) {
			return application.$wheels.viteManifestCache;
		}

		local.manifestPath = $viteManifestPath();
		if (!FileExists(local.manifestPath)) {
			if ($get("showErrorInformation")) {
				Throw(
					type="Wheels.ViteManifestNotFound",
					message="Vite manifest not found at '#local.manifestPath#'.",
					extendedInfo="Run your Vite build (e.g. `npx vite build`) to generate the manifest, or check the `viteBuildPath` and `viteManifestFile` settings."
				);
			}
			return {};
		}

		local.manifestContent = FileRead(local.manifestPath);
		local.manifest = DeserializeJSON(local.manifestContent);

		// Cache in application scope
		application.$wheels.viteManifestCache = local.manifest;

		return local.manifest;
	}

	/**
	 * Returns the absolute filesystem path to the Vite manifest file.
	 */
	public string function $viteManifestPath() {
		return GetDirectoryFromPath(GetBaseTemplatePath())
			& $get("viteBuildPath") & "/"
			& $get("viteManifestFile");
	}

	/**
	 * Returns whether Vite dev mode is active. In development environment, checks the
	 * `viteDevMode` setting (defaults to true in development, false otherwise).
	 */
	public boolean function $viteDevMode() {
		return $get("viteDevMode");
	}

	/**
	 * Returns the full dev server URL for an entrypoint.
	 */
	public string function $viteDevUrl(required string entrypoint) {
		local.devUrl = $get("viteDevServerUrl");
		// Ensure no double slash between dev URL and entrypoint
		if (Right(local.devUrl, 1) == "/" && Left(arguments.entrypoint, 1) == "/") {
			return local.devUrl & Right(arguments.entrypoint, Len(arguments.entrypoint) - 1);
		}
		if (Right(local.devUrl, 1) != "/" && Left(arguments.entrypoint, 1) != "/") {
			return local.devUrl & "/" & arguments.entrypoint;
		}
		return local.devUrl & arguments.entrypoint;
	}

}
