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
			$viteMissingEntry(arguments.entrypoint, local.manifest);
			return arguments.entrypoint;
		}
		return $get("webPath") & $get("viteBuildPath") & "/" & local.manifest[arguments.entrypoint].file;
	}

	/**
	 * Returns 'script' tags for a Vite JS entrypoint. In development, also injects the Vite
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
			local.resolved = $viteResolveAssets(arguments.entrypoint);
			if (!ArrayLen(local.resolved.scripts)) {
				return "";
			}
			local.buildPath = $get("webPath") & $get("viteBuildPath");

			for (local.cssFile in local.resolved.styles) {
				local.rv &= '<link rel="stylesheet" href="#local.buildPath#/#local.cssFile#" />' & Chr(10);
			}

			local.rv &= '<script type="module" src="#local.buildPath#/#local.resolved.scripts[1]#"></script>' & Chr(10);

			// Modulepreload for transitive import chunks — always emitted into <head>
			// regardless of the `head` arg, since preloads placed in <body> are useless.
			for (local.chunkFile in local.resolved.preloads) {
				$viteHtmlHead(text='<link rel="modulepreload" href="#local.buildPath#/#local.chunkFile#" />' & Chr(10));
			}
		}

		if (arguments.head) {
			$viteHtmlHead(text=local.rv);
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

		local.resolved = $viteResolveAssets(arguments.entrypoint);
		if (!ArrayLen(local.resolved.scripts)) {
			return "";
		}
		local.buildPath = $get("webPath") & $get("viteBuildPath");
		local.rv = '<link rel="stylesheet" href="#local.buildPath#/#local.resolved.scripts[1]#" />' & Chr(10);
		for (local.cssFile in local.resolved.styles) {
			local.rv &= '<link rel="stylesheet" href="#local.buildPath#/#local.cssFile#" />' & Chr(10);
		}

		if (arguments.head) {
			$viteHtmlHead(text=local.rv);
			return "";
		}
		return local.rv;
	}

	/**
	 * Returns `<link rel="modulepreload">` tags for a Vite entrypoint and its transitive
	 * chunk imports. Useful for Turbo Drive hover-preload patterns or for explicitly warming
	 * assets a subsequent navigation will need.
	 *
	 * In development mode, returns an empty string — Vite handles module resolution
	 * dynamically and modulepreload is unnecessary.
	 *
	 * [section: View Helpers]
	 * [category: Asset Functions]
	 *
	 * @entrypoint The source entrypoint path (e.g. "src/main.js").
	 * @head Set to `false` to return the markup for inline placement; default `true`
	 *       emits via `$viteHtmlHead()` so tags land in `<head>`.
	 */
	public string function vitePreloadTag(required string entrypoint, boolean head = true) {
		if ($viteDevMode()) {
			return "";
		}

		local.resolved = $viteResolveAssets(arguments.entrypoint);
		if (!ArrayLen(local.resolved.scripts)) {
			return "";
		}

		local.buildPath = $get("webPath") & $get("viteBuildPath");
		local.rv = '<link rel="modulepreload" href="#local.buildPath#/#local.resolved.scripts[1]#" />' & Chr(10);
		for (local.chunkFile in local.resolved.preloads) {
			local.rv &= '<link rel="modulepreload" href="#local.buildPath#/#local.chunkFile#" />' & Chr(10);
		}

		if (arguments.head) {
			$viteHtmlHead(text=local.rv);
			return "";
		}
		return local.rv;
	}

	/**
	 * Reads and caches the Vite manifest.json file. The manifest is cached in the application
	 * scope for the lifetime of the application (cleared on reload).
	 */
	public struct function $viteManifest() {
		local.appKey = $appKey();
		if (
			StructKeyExists(application[local.appKey], "viteManifestCache")
			&& IsStruct(application[local.appKey].viteManifestCache)
		) {
			return application[local.appKey].viteManifestCache;
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
		application[local.appKey].viteManifestCache = local.manifest;

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
	 * Walks the Vite manifest for a single entrypoint and returns its resolved
	 * script, styles, and modulepreload chunks. Follows transitive imports
	 * depth-first, dedupes visited chunks, and terminates on cycles.
	 *
	 * Returns a struct with three array keys:
	 *   - scripts:  [entry.file]            (the main JS file)
	 *   - styles:   [entry.css..., chunk.css...]  (entry CSS + all transitive chunk CSS)
	 *   - preloads: [chunk.file, ...]        (each transitive import chunk)
	 *
	 * Behavior on missing entry is delegated to `$viteMissingEntry` (strict-mode
	 * gate). Returns an empty resolved set in non-strict mode.
	 */
	public struct function $viteResolveAssets(required string entrypoint) {
		local.manifest = $viteManifest();
		local.rv = {scripts: [], styles: [], preloads: []};

		if (!StructKeyExists(local.manifest, arguments.entrypoint)) {
			$viteMissingEntry(arguments.entrypoint, local.manifest);
			return local.rv;
		}

		local.entry = local.manifest[arguments.entrypoint];
		ArrayAppend(local.rv.scripts, local.entry.file);
		if (StructKeyExists(local.entry, "css") && IsArray(local.entry.css)) {
			for (local.cssFile in local.entry.css) {
				ArrayAppend(local.rv.styles, local.cssFile);
			}
		}

		local.visited = {};
		local.visited[arguments.entrypoint] = true;
		if (StructKeyExists(local.entry, "imports") && IsArray(local.entry.imports)) {
			$viteWalkImports(
				importKeys=local.entry.imports,
				manifest=local.manifest,
				visited=local.visited,
				rv=local.rv
			);
		}

		return local.rv;
	}

	/**
	 * Depth-first walks a list of chunk import keys, mutating the passed-in
	 * `rv` struct's preloads and styles arrays as it visits each chunk. The
	 * visited struct prevents cycles and dedupes diamond dependencies. Takes
	 * the parent struct rather than the inner arrays directly: Adobe CF
	 * copies arrays by value out of struct literals (Cross-Engine Invariant
	 * #6), so mutating `preloads` / `styles` references passed as separate
	 * arguments writes to copies, not the caller's `local.rv`.
	 */
	public void function $viteWalkImports(
		required array importKeys,
		required struct manifest,
		required struct visited,
		required struct rv
	) {
		for (local.key in arguments.importKeys) {
			if (StructKeyExists(arguments.visited, local.key)) {
				continue;
			}
			arguments.visited[local.key] = true;
			if (!StructKeyExists(arguments.manifest, local.key)) {
				continue;
			}
			local.chunk = arguments.manifest[local.key];
			ArrayAppend(arguments.rv.preloads, local.chunk.file);
			if (StructKeyExists(local.chunk, "css") && IsArray(local.chunk.css)) {
				for (local.cssFile in local.chunk.css) {
					ArrayAppend(arguments.rv.styles, local.cssFile);
				}
			}
			if (StructKeyExists(local.chunk, "imports") && IsArray(local.chunk.imports)) {
				$viteWalkImports(
					importKeys=local.chunk.imports,
					manifest=arguments.manifest,
					visited=arguments.visited,
					rv=arguments.rv
				);
			}
		}
	}

	/**
	 * Thin wrapper around `$htmlhead` that also records the text into a
	 * request-scoped capture array when one is present. Tests initialize
	 * `request.$viteHeadCapture = []` to inspect what was emitted to <head>;
	 * production code paths never set the capture and behavior is unchanged.
	 */
	public void function $viteHtmlHead(required string text) {
		if (StructKeyExists(request, "$viteHeadCapture") && IsArray(request.$viteHeadCapture)) {
			ArrayAppend(request.$viteHeadCapture, arguments.text);
		}
		$htmlhead(text=arguments.text);
	}

	/**
	 * Handles a missing manifest entry. Throws `Wheels.ViteAssetNotFound` when
	 * strict-manifest mode is enabled (default) or when `showErrorInformation`
	 * is true. Otherwise returns silently, preserving 3.x behavior for apps that
	 * opt out via `set(viteStrictManifest=false)`.
	 */
	public void function $viteMissingEntry(required string entrypoint, struct manifest = {}) {
		local.strict = $get("viteStrictManifest");
		if (local.strict || $get("showErrorInformation")) {
			Throw(
				type="Wheels.ViteAssetNotFound",
				message="Vite entrypoint '#arguments.entrypoint#' not found in manifest.",
				extendedInfo="Available entrypoints: #StructKeyList(arguments.manifest)#. Run your Vite build to generate the manifest, or set(viteStrictManifest=false) to silence this error."
			);
		}
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
