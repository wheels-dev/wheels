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
	 * @config Disk config: { root (required), urlPrefix="", signingKey="" }.
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
		return this;
	}

	public any function put(required string key, required any content, string contentType = "", string visibility = "") {
		local.path = $resolve(arguments.key);
		$ensureParentDir(local.path);
		FileWrite(local.path, arguments.content);
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

	private string function $resolve(required string key) {
		// Reject traversal — a key must stay inside root.
		local.clean = Replace(arguments.key, "\", "/", "all");
		if (Find("..", local.clean)) {
			throw(
				type = "Wheels.Storage.InvalidKey",
				message = "Storage key [#arguments.key#] must not contain '..'."
			);
		}
		return variables.root & "/" & local.clean;
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
		return local.p & "/" & local.k;
	}

	private string function $uriEncode(required string value) {
		local.encoded = CreateObject("java", "java.net.URLEncoder").encode(arguments.value, "UTF-8");
		return Replace(local.encoded, "+", "%20", "all");
	}

	private numeric function $epochSeconds() {
		return Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
	}

}
