/**
 * Local filesystem storage disk.
 *
 * Stores objects under a configured `root` directory and exposes them through
 * a `urlPrefix` (served by the application). Signed URLs carry an HMAC token
 * over the key + expiry — there is no native filesystem presigning, so, like
 * every framework that ships a local disk (Rails DiskController, Laravel
 * `serve`, AdonisJS `serveFiles`), the application is expected to verify the
 * token before streaming the file.
 *
 * [section: Storage]
 * [category: Driver]
 */
component implements="wheels.interfaces.StorageDiskInterface" output="false" {

	/**
	 * @config Disk config: { root (required), urlPrefix="", signingKey="", resolveSymlinks=false }.
	 *
	 * `resolveSymlinks` (default false) adds an opt-in, stricter containment layer
	 * on top of the always-on lexical guard (#3912): when true, `$resolve()` also
	 * canonicalises paths through the filesystem so a symlink planted under the
	 * root that targets outside is REJECTED rather than followed (#4020). It is
	 * off by default because the lexical guard already blocks traversal and a
	 * symlink under the root can only be created by someone with filesystem access.
	 */
	public LocalDisk function init(required struct config) {
		if (!StructKeyExists(arguments.config, "root") || !Len(arguments.config.root)) {
			throw(
				type = "Wheels.Storage.InvalidConfiguration",
				message = "Local disk requires a non-empty 'root' directory."
			);
		}
		variables.root = $normalizeDir(arguments.config.root);
		variables.urlPrefix = StructKeyExists(arguments.config, "urlPrefix") ? arguments.config.urlPrefix : "";
		variables.signingKey = StructKeyExists(arguments.config, "signingKey") ? arguments.config.signingKey : "";
		if (StructKeyExists(arguments.config, "resolveSymlinks")) {
			if (!IsBoolean(arguments.config.resolveSymlinks)) {
				throw(
					type = "Wheels.Storage.InvalidConfiguration",
					message = "Local disk 'resolveSymlinks' must be a boolean (true or false)."
				);
			}
			variables.resolveSymlinks = arguments.config.resolveSymlinks ? true : false;
		} else {
			variables.resolveSymlinks = false;
		}
		// Fail closed, at init (not per request): if the app opted into symlink
		// resolution but this runtime can't actually resolve symbolic links, refuse
		// to construct rather than silently run an ineffective strict mode.
		if (variables.resolveSymlinks) {
			$assertSymlinkResolutionAvailable();
		}
		return this;
	}

	public any function put(required string key, required any content, string contentType = "", string visibility = "") {
		local.path = $resolve(arguments.key);
		$ensureParentDir(local.path);
		// Write bytes, never a string. Adobe 2025's FileWrite() appends a
		// trailing LF (0x0A) when handed a simple value — storing "hello world"
		// put 12 bytes on disk, so `get()` no longer round-tripped what `put()`
		// was given, and any binary payload came back corrupted by one byte.
		// Lucee 6/7, BoxLang and Adobe 2023 write the string verbatim, so this
		// only ever surfaced on the adobe2025 matrix legs (#3302). The binary
		// overload has no line-ending behaviour on any engine.
		local.payload = IsBinary(arguments.content) ? arguments.content : CharsetDecode(arguments.content, "utf-8");
		FileWrite(local.path, local.payload);
		return arguments.key;
	}

	public any function get(required string key) {
		local.path = $resolve(arguments.key);
		if (!FileExists(local.path)) {
			throw(
				type = "Wheels.Storage.NotFound",
				message = "No object stored at key [#arguments.key#]."
			);
		}
		return FileReadBinary(local.path);
	}

	public boolean function exists(required string key) {
		return FileExists($resolve(arguments.key));
	}

	public boolean function delete(required string key) {
		local.path = $resolve(arguments.key);
		if (FileExists(local.path)) {
			FileDelete(local.path);
			return true;
		}
		return false;
	}

	public string function url(required string key) {
		return $joinUrl(variables.urlPrefix, arguments.key);
	}

	public string function signedUrl(required string key, numeric expiresIn = 300, string contentDisposition = "") {
		$assertExpiresIn(arguments.expiresIn);
		if (!Len(variables.signingKey)) {
			throw(
				type = "Wheels.Storage.MissingSigningKey",
				message = "Local disk signedUrl() requires a 'signingKey' in the disk config."
			);
		}
		local.expiresAt = $epochSeconds() + arguments.expiresIn;
		local.token = $sign($signaturePayload(arguments.key, local.expiresAt, arguments.contentDisposition));
		local.base = $joinUrl(variables.urlPrefix, arguments.key);
		local.qs = "expires=" & local.expiresAt & "&signature=" & local.token;
		if (Len(arguments.contentDisposition)) {
			local.qs &= "&disposition=" & $uriEncode(arguments.contentDisposition);
		}
		return local.base & "?" & local.qs;
	}

	/**
	 * Verify a signed-URL token for the application's serving route.
	 *
	 * @key The requested key.
	 * @expires The epoch-seconds expiry carried in the URL.
	 * @signature The token carried in the URL.
	 * @contentDisposition The disposition carried in the URL (bound into the token).
	 */
	public boolean function verifySignature(required string key, required numeric expires, required string signature, string contentDisposition = "") {
		if (!Len(variables.signingKey)) {
			return false;
		}
		if ($epochSeconds() > arguments.expires) {
			return false;
		}
		local.expected = $sign($signaturePayload(arguments.key, arguments.expires, arguments.contentDisposition));
		return $secureEquals(local.expected, arguments.signature);
	}

	// ---- internals --------------------------------------------------------

	private string function $sign(required string message) {
		return LCase(HMac(arguments.message, variables.signingKey, "HMACSHA256", "UTF-8"));
	}

	/**
	 * Canonical string the signed-URL HMAC covers. Binding the disposition in
	 * means a holder of a valid URL cannot alter the served Content-Disposition.
	 * Empty disposition reproduces the legacy "key|expires" payload, so URLs
	 * signed without one still verify.
	 */
	private string function $signaturePayload(required string key, required numeric expires, string contentDisposition = "") {
		local.payload = arguments.key & "|" & arguments.expires;
		if (Len(arguments.contentDisposition)) {
			local.payload &= "|" & arguments.contentDisposition;
		}
		return local.payload;
	}

	/**
	 * Length-independent equality for two hex tokens. Unlike CompareNoCase it
	 * does not short-circuit on the first differing character, so it does not
	 * leak how much of the token matched through timing. Both inputs are the
	 * fixed-width lowercase-hex output of $sign(), so a length mismatch can only
	 * be a forged/garbage token — comparing false there is correct.
	 */
	private boolean function $secureEquals(required string a, required string b) {
		local.x = LCase(arguments.a);
		local.y = LCase(arguments.b);
		if (Len(local.x) != Len(local.y)) {
			return false;
		}
		local.diff = 0;
		for (local.i = 1; local.i <= Len(local.x); local.i++) {
			local.diff = BitOr(local.diff, BitXor(Asc(Mid(local.x, local.i, 1)), Asc(Mid(local.y, local.i, 1))));
		}
		return local.diff == 0;
	}

	/**
	 * Resolve a storage key to an absolute path inside the root, rejecting path
	 * traversal. A name that merely CONTAINS two dots inside a segment ("a..b.txt",
	 * "v1..2") is legitimate and allowed; only genuine traversal is rejected (#3912).
	 *
	 * The containment guard is LEXICAL (string) canonicalisation — it resolves "./",
	 * "../" and "//" syntactically and compares paths, which is uniform on every
	 * engine including the JVM-free RustCFML. It does NOT resolve symlinks: a symlink
	 * planted under the root that points outside is FOLLOWED and trusted, because it
	 * can only be created by someone who already has filesystem access to the root,
	 * never through the storage API. (A symlink's target is pinned by StorageSpec's
	 * "follows a symlink under root" test; an opt-in symlink-resolving check for JVM
	 * engines is tracked in #4020.)
	 */
	public string function $resolve(required string key) {
		// 1. Normalise separators (\ -> /) so a Windows or mixed-separator key is one form.
		local.clean = Replace(arguments.key, "\", "/", "all");

		// 2. Every key is relative to the root, so slash runs carry no meaning: a
		// leading "/", a trailing "/", "//" runs and a UNC/network prefix
		// ("//server/share", "\\server\share") are NORMALISED away by dropping empty
		// segments — the remainder is appended under the root. We do NOT url-decode, so
		// "%2e%2e%2f" stays a literal segment and can never turn into "../".
		local.segments = ListToArray(local.clean, "/", false);
		if (!ArrayLen(local.segments)) {
			throw(
				type = "Wheels.Storage.InvalidKey",
				message = "Storage key [#arguments.key#] must not be empty or slash-only."
			);
		}
		// Reject any surviving segment that, after trimming whitespace and removing
		// every dot, is empty: ".", "..", "...", ". .", and — because Windows strips a
		// segment's trailing dots and spaces — ".. ". An exact "==" check for ".." is
		// not enough. A drive-letter prefix (C:, C:foo) must never resolve outside root.
		for (local.segment in local.segments) {
			if (Len(Trim(Replace(Trim(local.segment), ".", "", "all"))) == 0) {
				throw(
					type = "Wheels.Storage.InvalidKey",
					message = "Storage key [#arguments.key#] has a dot/space-only path segment."
				);
			}
			if (ReFind("^[A-Za-z]:", local.segment)) {
				throw(
					type = "Wheels.Storage.InvalidKey",
					message = "Storage key [#arguments.key#] must not contain a drive-letter prefix."
				);
			}
		}

		local.resolved = variables.root & "/" & ArrayToList(local.segments, "/");

		// 3. Defence in depth: lexically canonicalise the resolved path and confirm
		// it stays inside the root. After the segment guard there is no ".." left, so
		// this only ever fires if that guard is weakened; the trailing-separator
		// compare keeps "/root-evil" from passing as inside "/root".
		if (!$pathWithin(root = $lexicalCanonical(variables.root), candidate = $lexicalCanonical(local.resolved))) {
			throw(
				type = "Wheels.Storage.InvalidKey",
				message = "Storage key [#arguments.key#] resolves outside the storage root."
			);
		}

		// 4. Opt-in strict containment (#4020): additionally resolve the path through
		// the filesystem (symlinks included) and re-check. init() has already proven,
		// via a behavioural probe, that this runtime resolves symlinks — so a symlink
		// planted under the root that targets outside is now REJECTED, not followed.
		if (variables.resolveSymlinks) {
			$assertCanonicalWithin(key = arguments.key, resolved = local.resolved);
		}

		return local.resolved;
	}

	/**
	 * Strict containment re-check for the opt-in resolveSymlinks mode (#4020):
	 * canonicalise both the root and the resolved path through the filesystem and
	 * confirm the target stays inside the root. getCanonicalPath() resolves
	 * symlinks in the existing path prefix; a not-yet-created leaf (put()) is
	 * appended lexically, so a symlink DIRECTORY under the root is still caught.
	 */
	private void function $assertCanonicalWithin(required string key, required string resolved) {
		// Compare the two canonical paths EXACTLY (case-sensitively): getCanonicalPath()
		// reports each path in its real on-disk case, so an exact compare is right on
		// both case-sensitive and case-insensitive filesystems. $pathWithin's CFML `==`
		// is case-insensitive, which would treat a case-distinct sibling directory as
		// inside the root once a symlink redirects there.
		if (!$pathWithinExact(root = $canonicalPath(variables.root), candidate = $canonicalPath(arguments.resolved))) {
			throw(
				type = "Wheels.Storage.InvalidKey",
				message = "Storage key [#arguments.key#] resolves through a symlink outside the storage root."
			);
		}
	}

	/**
	 * Behavioural capability probe for the opt-in resolveSymlinks mode (#4020).
	 * Creates a throwaway symlink under GetTempDirectory() that points OUT of its
	 * own parent directory, canonicalises it, and requires the canonical path to
	 * land inside the target — i.e. the runtime genuinely resolved the symlink.
	 * It is a capability check, never an engine-name check: RustCFML exposes
	 * java.io.File.getCanonicalPath() but it is a lexical no-op that does not
	 * resolve symlinks, so a "does the call exist" probe would pass there and leave
	 * strict mode silently ineffective. Throws Wheels.Storage.InvalidConfiguration
	 * when the symlink can't be created (e.g. Windows without symlink privilege) or
	 * is not resolved (e.g. RustCFML). Runs once per disk instance, at init.
	 *
	 * `probe` is a bare `var` struct written without a `local.` prefix so the value
	 * set inside the catch survives on BoxLang (cross-engine invariant 11); the
	 * finally calls a helper rather than looping, since a loop in a finally block
	 * miscompiles on Lucee 7 (invariant 12).
	 */
	private void function $assertSymlinkResolutionAvailable() {
		var probe = {dir = "", resolved = false};
		probe.dir = $normalizeDir(GetTempDirectory()) & "/wheels-localdisk-symlinkprobe-" & CreateUUID();
		// Outer catch-free try/finally so the probe-dir cleanup runs on every exit — including an
		// abort — because BoxLang skips a finally whose try has a catch clause (invariant 22). The
		// inner try keeps the existing catch that turns a probe failure into resolved = false.
		try {
			try {
				local.insideDir = probe.dir & "/inside";
				local.outsideDir = probe.dir & "/outside";
				CreateObject("java", "java.io.File").init(local.insideDir).mkdirs();
				CreateObject("java", "java.io.File").init(local.outsideDir).mkdirs();
				local.linkFile = local.insideDir & "/lnk";
				$createProbeSymlink(target = local.outsideDir, link = local.linkFile);
				// Resolved iff canonicalising the link lands inside the (sibling) target.
				// Exact (case-sensitive) compare, like the strict check it gates.
				probe.resolved = $pathWithinExact(
					root = $canonicalPath(local.outsideDir),
					candidate = $canonicalPath(local.linkFile)
				);
			} catch (any e) {
				probe.resolved = false;
			}
		} finally {
			// Delete the probe's symlink BEFORE the recursive temp-dir delete: a recursive
			// DirectoryDelete over a directory that still contains a symlink errors on Adobe
			// (and is swallowed), which would leak the probe's temp dir on every init.
			$deleteSymlinkQuietly(probe.dir & "/inside/lnk");
			$deleteDirQuietly(probe.dir);
		}
		if (!probe.resolved) {
			throw(
				type = "Wheels.Storage.InvalidConfiguration",
				message = "Local disk resolveSymlinks=true requires a runtime that resolves symbolic links through the filesystem (java.io.File.getCanonicalPath). This runtime does not (e.g. RustCFML, or an OS/account without symlink support). Remove resolveSymlinks, or run on a JVM engine with symlink support."
			);
		}
	}

	/**
	 * Absolute, symlink-resolved path with forward separators, via
	 * java.io.File.getCanonicalPath(). Only ever called once init()'s probe has
	 * confirmed this runtime resolves symlinks, so it never runs where
	 * getCanonicalPath() would be a lexical no-op.
	 */
	private string function $canonicalPath(required string path) {
		return Replace(CreateObject("java", "java.io.File").init(arguments.path).getCanonicalPath(), "\", "/", "all");
	}

	/**
	 * Create a symbolic link for the probe. Prefers the platform-native NIO call
	 * (`java.nio.file.Files.createSymbolicLink`) so the probe works on JVM engines
	 * without a POSIX `ln` on PATH — notably Windows with symlink privilege. Falls
	 * back to `ln -s` where the NIO call is unavailable (RustCFML does not shim
	 * `createSymbolicLink`, and some sandboxes block it). If neither can create the
	 * link the error propagates, and the init probe fails closed.
	 */
	private void function $createProbeSymlink(required string target, required string link) {
		if ($tryCreateSymbolicLinkNio(target = arguments.target, link = arguments.link)) {
			return;
		}
		local.pb = CreateObject("java", "java.lang.ProcessBuilder").init(["ln", "-s", arguments.target, arguments.link]);
		local.proc = local.pb.start();
		local.proc.waitFor();
		if (local.proc.exitValue() != 0) {
			throw(type = "Wheels.Storage.SymlinkProbeFailed", message = "Probe could not create a symbolic link (neither NIO createSymbolicLink nor `ln -s` succeeded).");
		}
	}

	/**
	 * Try to create the symlink through java.nio. Returns true on success, false if
	 * the call is unavailable or fails, so the caller can fall back. `created` is a
	 * bare `var` struct field (no `local.` prefix) so the value set in the catch
	 * survives on BoxLang (cross-engine invariant 11).
	 *
	 * `createSymbolicLink(Path, Path, FileAttribute...)` is varargs; the two-argument
	 * form does NOT bind through CFML's Java interop ("No matching method ...") on
	 * Lucee, so it would always throw and fall back to `ln`, defeating the point on a
	 * host without `ln` on PATH (e.g. Windows with symlink privilege). Pass an
	 * explicit empty `FileAttribute[]` so the varargs method binds; the element type
	 * comes from `Class.forName` (#4070). Public with a `$` prefix (like `$resolve`)
	 * so the binding is covered by a spec.
	 */
	public boolean function $tryCreateSymbolicLinkNio(required string target, required string link) {
		var created = {ok = false};
		try {
			local.linkPath = CreateObject("java", "java.io.File").init(arguments.link).toPath();
			local.targetPath = CreateObject("java", "java.io.File").init(arguments.target).toPath();
			local.faType = CreateObject("java", "java.lang.Class").forName("java.nio.file.attribute.FileAttribute");
			local.noAttrs = CreateObject("java", "java.lang.reflect.Array").newInstance(local.faType, 0);
			CreateObject("java", "java.nio.file.Files").createSymbolicLink(local.linkPath, local.targetPath, local.noAttrs);
			created.ok = true;
		} catch (any e) {
			created.ok = false;
		}
		return created.ok;
	}

	/**
	 * Case-SENSITIVE containment, for comparing two already-canonicalised paths
	 * (#4020). getCanonicalPath() reports each path in its real on-disk case, so an
	 * exact compare is correct on both case-sensitive and case-insensitive
	 * filesystems — unlike $pathWithin's CFML `==`, which is case-insensitive and
	 * would treat a case-distinct sibling directory as inside the root once a
	 * symlink redirects there. `Compare() == 0` is case-sensitive string equality
	 * on every engine (cross-engine invariant 20).
	 */
	private boolean function $pathWithinExact(required string root, required string candidate) {
		local.base = REReplace(arguments.root, "/+$", "");
		if (Compare(arguments.candidate, local.base) == 0) {
			return true;
		}
		return Len(arguments.candidate) > Len(local.base)
			&& Compare(Left(arguments.candidate, Len(local.base) + 1), local.base & "/") == 0;
	}

	/**
	 * Best-effort delete of the probe's symbolic LINK (never its target) via NIO, run
	 * before the recursive temp-dir delete so the latter doesn't have to remove a dir
	 * that still holds a symlink (which errors on Adobe). deleteIfExists no-ops when the
	 * link is absent; errors are swallowed so cleanup never masks the probe result.
	 */
	private void function $deleteSymlinkQuietly(required string path) {
		try {
			CreateObject("java", "java.nio.file.Files").deleteIfExists(
				CreateObject("java", "java.io.File").init(arguments.path).toPath()
			);
		} catch (any e) {
			// best-effort
		}
	}

	/**
	 * Best-effort recursive delete of the probe's temp directory. The probe's
	 * symlink target lives INSIDE this directory, so the delete is self-contained
	 * and never reaches outside it. Swallows errors so cleanup never masks the
	 * probe result; contains no loop (invariant 12).
	 */
	private void function $deleteDirQuietly(required string dir) {
		try {
			if (Len(arguments.dir) && DirectoryExists(arguments.dir)) {
				DirectoryDelete(arguments.dir, true);
			}
		} catch (any e) {
			// ignore — cleanup is best-effort
		}
	}

	/**
	 * Lexically canonicalise a path: normalise separators, resolve "." and ".."
	 * segments and collapse "//", preserving a leading "/" or a "C:" drive prefix.
	 * Pure string work (no filesystem, no JVM) so it behaves identically on every
	 * engine; it does not resolve symlinks.
	 */
	private string function $lexicalCanonical(required string path) {
		local.p = Replace(arguments.path, "\", "/", "all");
		local.prefix = "";
		if (ReFind("^[A-Za-z]:/", local.p)) {
			local.prefix = Left(local.p, 2);
			local.p = Mid(local.p, 3, Len(local.p));
		}
		local.isAbsolute = Left(local.p, 1) == "/";
		local.out = [];
		for (local.seg in ListToArray(local.p, "/", false)) {
			if (local.seg == ".") {
				continue;
			}
			if (local.seg == "..") {
				if (ArrayLen(local.out)) {
					ArrayDeleteAt(local.out, ArrayLen(local.out));
				}
				continue;
			}
			ArrayAppend(local.out, local.seg);
		}
		local.result = ArrayToList(local.out, "/");
		if (local.isAbsolute) {
			local.result = "/" & local.result;
		}
		return local.prefix & local.result;
	}

	/**
	 * True when `candidate` is the root itself or lives inside it. Compares with a
	 * trailing separator so "/root-evil" does not pass as inside "/root".
	 */
	private boolean function $pathWithin(required string root, required string candidate) {
		local.base = REReplace(arguments.root, "/+$", "");
		if (arguments.candidate == local.base) {
			return true;
		}
		return Left(arguments.candidate, Len(local.base) + 1) == (local.base & "/");
	}

	private string function $normalizeDir(required string dir) {
		local.d = Replace(arguments.dir, "\", "/", "all");
		return REReplace(local.d, "/+$", "");
	}

	private void function $ensureParentDir(required string path) {
		local.parent = GetDirectoryFromPath(arguments.path);
		// Use java.io.File.mkdirs() rather than the Lucee-only DirectoryCreate
		// recurse flag so directory creation behaves on every engine.
		local.file = CreateObject("java", "java.io.File").init(local.parent);
		if (!local.file.exists()) {
			local.file.mkdirs();
		}
	}

	private string function $joinUrl(required string prefix, required string key) {
		local.p = REReplace(arguments.prefix, "/+$", "");
		local.k = REReplace(arguments.key, "^/+", "");
		return local.p & "/" & $uriEncodePath(local.k);
	}

	private string function $uriEncode(required string value) {
		// RFC3986 percent-encoding over UTF-8 bytes. Built on BinaryEncode/hex
		// instead of java.net.URLEncoder so it is byte-identical on engines
		// without a JVM (RustCFML): unreserved bytes (A-Z a-z 0-9 - _ . ~)
		// pass through, everything else becomes %XX with uppercase hex —
		// the canonical form AWS SigV4 and the public-url specs expect.
		// Byte extraction via base64 round-trip: CharsetEncode() returns a
		// Java byte[] (not a CFML binary) on some Lucee 7.0.0.x builds, which
		// BinaryEncode cannot consume. ToBase64 + BinaryDecode produces a
		// proper binary on every engine for the same UTF-8 bytes.
		local.bin = BinaryDecode(ToBase64(ToString(arguments.value), "utf-8"), "base64");
		local.hex = UCase(BinaryEncode(local.bin, "hex"));
		local.out = "";
		for (local.i = 1; local.i < Len(local.hex); local.i += 2) {
			local.byteVal = InputBaseN(Mid(local.hex, local.i, 2), 16);
			if (
				(local.byteVal >= 48 && local.byteVal <= 57)
				|| (local.byteVal >= 65 && local.byteVal <= 90)
				|| (local.byteVal >= 97 && local.byteVal <= 122)
				|| local.byteVal == 45 || local.byteVal == 46 || local.byteVal == 95 || local.byteVal == 126
			) {
				local.out &= Chr(local.byteVal);
			} else {
				local.out &= "%" & Mid(local.hex, local.i, 2);
			}
		}
		return local.out;
	}

	private string function $uriEncodePath(required string key) {
		return Replace($uriEncode(arguments.key), "%2F", "/", "all");
	}

	private void function $assertExpiresIn(required numeric expiresIn) {
		if (arguments.expiresIn < 1 || arguments.expiresIn > 604800) {
			throw(
				type = "Wheels.Storage.InvalidExpiresIn",
				message = "signedUrl expiresIn must be between 1 and 604800 seconds (got #arguments.expiresIn#)."
			);
		}
	}

	private numeric function $epochSeconds() {
		return Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
	}

}
