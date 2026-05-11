/**
 * Non-blocking "is there a newer Wheels CLI available?" check, designed to
 * print at the end of `wheels new` so the user sees the hint right after
 * their new app finishes scaffolding (when they're about to `cd myapp`).
 *
 * Design constraints:
 *
 *   - **Never block app creation.** All errors swallow silently. A flaky
 *     network or rate-limited GitHub API must not delay or break `wheels new`.
 *   - **Hard timeout 5s.** Cap the HTTP wait independent of CFML defaults.
 *   - **24h cache** at $LUCLI_HOME/.update-check.json keyed by channel.
 *     One real HTTP request per channel per day. The cache stores the latest
 *     tag observed; comparisons against current happen client-side.
 *   - **Channel-aware** via services.ReleaseChannel — stable hits the main
 *     repo, bleeding-edge hits wheels-dev/wheels-snapshots, dev/rc skip.
 *   - **Snapshot vs stable comparison** differ:
 *       stable: SemVer.compare("4.0.0", "4.0.1") -> -1 (newer available)
 *       bleeding-edge: compare the snapshot.N suffix (4.0.0-snapshot.1789 vs
 *         4.0.0-snapshot.1790). Base SemVer part compared first; tie -> N.
 *
 * Public API:
 *
 *   var uc = new services.UpdateChecker();
 *   var result = uc.check(currentVersion="4.0.0-snapshot.1700");
 *   if (result.hasUpdate) {
 *     out("A newer wheels is available: " & result.latest);
 *     out("  Upgrade: " & result.upgradeCommand);
 *   }
 *
 * Result struct shape:
 *
 *   {
 *     hasUpdate:       boolean,
 *     skipped:         boolean,        // true when channel doesn't auto-check
 *                                       // (dev/rc) OR when cache TTL not expired
 *                                       // AND no newer version cached
 *     reason:          string,         // when skipped=true
 *     current:         string,
 *     latest:          string,         // "" when no check was made
 *     channel:         string,
 *     upgradeCommand:  string          // only set when hasUpdate=true
 *   }
 */
component {

	variables.CACHE_TTL_SECONDS = 86400; // 24h
	variables.HTTP_TIMEOUT_SECONDS = 5;

	public function init() {
		variables.releaseChannel = new ReleaseChannel();
		variables.semver = new SemVer();
		variables.cachePath = $resolveCachePath();
		return this;
	}

	/**
	 * Main entry. Returns a result struct (see component-level docstring).
	 * Never throws — swallows all errors, marks skipped=true with a reason.
	 */
	public struct function check(required string currentVersion) {
		var channel = variables.releaseChannel.classify(arguments.currentVersion);
		var repo = variables.releaseChannel.releaseRepo(channel);
		var result = {
			hasUpdate: false,
			skipped: false,
			reason: "",
			current: arguments.currentVersion,
			latest: "",
			channel: channel,
			upgradeCommand: ""
		};

		if (!len(repo)) {
			result.skipped = true;
			result.reason = "channel '" & channel & "' does not auto-check";
			return result;
		}

		try {
			var latest = $fetchLatestVersion(repo, channel);
			if (!len(latest)) {
				result.skipped = true;
				result.reason = "no release found on " & repo;
				return result;
			}
			result.latest = latest;

			if ($isNewer(arguments.currentVersion, latest, channel)) {
				result.hasUpdate = true;
				result.upgradeCommand = variables.releaseChannel.upgradeCommand(channel);
			}
		} catch (any e) {
			result.skipped = true;
			result.reason = "check failed: " & e.message;
		}

		return result;
	}

	/**
	 * Compare two version strings. Returns true if `latest` is strictly newer
	 * than `current`. For bleeding-edge, the snapshot.N suffix is compared
	 * after the base SemVer. For stable, plain SemVer.
	 */
	public boolean function $isNewer(required string current, required string latest, required string channel) {
		// SemVer.compare ignores pre-release labels by design (that's its
		// stable-channel behavior). For bleeding-edge we need to also look at
		// the trailing snapshot.N — so we compare base first, then N.
		var baseCmp = variables.semver.compare(arguments.current, arguments.latest);
		if (baseCmp != 0) {
			return baseCmp < 0; // current is older
		}

		// Base versions tied. For bleeding-edge, compare snapshot numbers.
		if (arguments.channel == "bleeding-edge") {
			return $snapshotNumber(arguments.latest) > $snapshotNumber(arguments.current);
		}

		// Same base, stable channel — nothing newer.
		return false;
	}

	/**
	 * Extract the trailing snapshot build number from a version string. Returns
	 * 0 if no snapshot suffix found (lets the comparison treat it as "older
	 * than any snapshot").
	 *
	 * Handles both formats:
	 *   post-fix:  4.0.0-snapshot.1789  -> 1789
	 *   legacy:    4.0.0-SNAPSHOT+1656  -> 1656
	 */
	public numeric function $snapshotNumber(required string version) {
		var m = reFindNoCase("snapshot[.+]([0-9]+)", arguments.version, 1, true);
		// reFindNoCase with returnsubexpressions=true returns ["", ...] on no
		// match, never a zero-length array — so checking len < 2 is enough.
		if (arrayLen(m.match) < 2) return 0;
		return val(m.match[2]);
	}

	/**
	 * Resolve where to store the cache file. Lives under LUCLI_HOME so it
	 * stays adjacent to the rest of the user's wheels runtime state.
	 *
	 * Falls back to ${user.home}/.wheels if LUCLI_HOME isn't exported (which
	 * happens when the user runs `wheels` outside the brew wrapper, e.g. from
	 * a dev checkout). That fallback matches LuCLI's own default.
	 */
	public string function $resolveCachePath() {
		try {
			var sys = createObject("java", "java.lang.System");
			var home = sys.getenv("LUCLI_HOME");
			if (isNull(home) || !len(trim(home))) {
				home = sys.getProperty("user.home") & "/.wheels";
			}
			return home & "/.update-check.json";
		} catch (any e) {
			return "/tmp/.wheels-update-check.json";
		}
	}

	/**
	 * Hit the GitHub API for the latest release on `repo`. Returns the
	 * version string with leading 'v' stripped, or "" on any failure.
	 *
	 * Uses a per-channel cache file (24h TTL) so we don't make a real network
	 * request every `wheels new`. The cache returns immediately if fresh.
	 */
	public string function $fetchLatestVersion(required string repo, required string channel) {
		var cached = $readCache(arguments.channel);
		if (structKeyExists(cached, "tag") && len(cached.tag)) {
			return cached.tag;
		}

		var tag = $httpFetchLatest(arguments.repo, arguments.channel);
		if (len(tag)) {
			$writeCache(arguments.channel, tag);
		}
		return tag;
	}

	/**
	 * Do the actual HTTP call. Stable channel uses /releases/latest (skips
	 * pre-releases). Bleeding-edge uses /releases?per_page=1 (highest tag is
	 * always a snapshot pre-release).
	 *
	 * Public for unit testability — tests can shadow this with a stub.
	 */
	public string function $httpFetchLatest(required string repo, required string channel) {
		var url = "https://api.github.com/repos/" & arguments.repo & "/";
		if (arguments.channel == "bleeding-edge") {
			url &= "releases?per_page=1";
		} else {
			url &= "releases/latest";
		}

		var httpResult = "";
		try {
			cfhttp(url=url, method="GET", timeout=variables.HTTP_TIMEOUT_SECONDS, throwOnError=false, result="httpResult") {
				cfhttpparam(type="header", name="Accept", value="application/vnd.github+json");
				cfhttpparam(type="header", name="User-Agent", value="wheels-cli-update-check");
			}
		} catch (any e) {
			return "";
		}

		if (!isStruct(httpResult) || !structKeyExists(httpResult, "statusCode") || left(httpResult.statusCode, 1) != "2") {
			return "";
		}
		if (!isJSON(httpResult.fileContent)) return "";
		var body = deserializeJSON(httpResult.fileContent);

		// For the per-page=1 path, body is an array. For releases/latest it's an object.
		var tagName = "";
		if (isArray(body) && arrayLen(body)) {
			tagName = structKeyExists(body[1], "tag_name") ? body[1].tag_name : "";
		} else if (isStruct(body)) {
			tagName = structKeyExists(body, "tag_name") ? body.tag_name : "";
		}

		// Strip leading 'v' so 'v4.0.0' compares cleanly with '4.0.0'.
		if (left(tagName, 1) == "v") tagName = mid(tagName, 2, len(tagName) - 1);
		return tagName;
	}

	/**
	 * Return cached entry for `channel` if not expired. Empty struct if missing,
	 * stale, or unreadable.
	 */
	public struct function $readCache(required string channel) {
		try {
			if (!fileExists(variables.cachePath)) return {};
			var raw = fileRead(variables.cachePath);
			if (!isJSON(raw)) return {};
			var cache = deserializeJSON(raw);
			if (!isStruct(cache) || !structKeyExists(cache, arguments.channel)) return {};
			var entry = cache[arguments.channel];
			if (!isStruct(entry) || !structKeyExists(entry, "tag") || !structKeyExists(entry, "checkedAt")) return {};

			var ageSeconds = dateDiff("s", parseDateTime(entry.checkedAt), now());
			if (ageSeconds > variables.CACHE_TTL_SECONDS) return {};

			return entry;
		} catch (any e) {
			return {};
		}
	}

	/**
	 * Persist a `channel -> {tag, checkedAt}` entry to the cache, preserving
	 * other channels' entries.
	 */
	public void function $writeCache(required string channel, required string tag) {
		try {
			var cache = {};
			if (fileExists(variables.cachePath)) {
				var raw = fileRead(variables.cachePath);
				if (isJSON(raw)) {
					var parsed = deserializeJSON(raw);
					if (isStruct(parsed)) cache = parsed;
				}
			}
			cache[arguments.channel] = {
				tag: arguments.tag,
				checkedAt: dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss")
			};
			var dir = getDirectoryFromPath(variables.cachePath);
			if (!directoryExists(dir)) directoryCreate(dir, true);
			fileWrite(variables.cachePath, serializeJSON(cache));
		} catch (any e) {
			// Cache write failure is non-fatal — the next check will just
			// do a fresh HTTP request. Silently swallow.
		}
	}

}
