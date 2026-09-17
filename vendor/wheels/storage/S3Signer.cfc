/**
 * AWS Signature Version 4 signer for S3, implemented from scratch — no AWS SDK,
 * no JARs. Generates presigned GET URLs (query-string auth) and Authorization
 * headers (header auth) for arbitrary S3 requests issued via `cfhttp`.
 *
 * The crypto primitives are the same proven, cross-engine-green building blocks
 * `wheels.auth.JwtService` relies on (SHA-256 hex hashing + a chained HMAC-SHA256
 * key-derivation), driven through `javax.crypto.Mac` so binary signing keys work
 * identically on Lucee 5/6/7, Adobe CF 2018-2025, and BoxLang.
 *
 * Reference: AWS "Authenticating Requests: Using Query Parameters (AWS Signature
 * Version 4)" and "...Using the Authorization Header...".
 *
 * Usage:
 *   var signer = new wheels.storage.S3Signer(
 *       accessKeyId="AKIA…", secretAccessKey="…", region="us-east-1", bucket="my-bucket"
 *   );
 *   var url = signer.presignGetUrl(key="reports/q3.pdf", expiresIn=300);
 *
 * [section: Storage]
 * [category: Core]
 */
component output="false" {

	/**
	 * @accessKeyId AWS access key id.
	 * @secretAccessKey AWS secret access key.
	 * @region AWS region (e.g. "us-east-1").
	 * @bucket S3 bucket name.
	 * @endpoint Override the host (e.g. for S3-compatible stores). Empty => derive from bucket+region.
	 * @usePathStyle When true, addresses as host/bucket/key rather than bucket.host/key.
	 */
	public S3Signer function init(
		required string accessKeyId,
		required string secretAccessKey,
		required string region,
		required string bucket,
		string endpoint = "",
		boolean usePathStyle = false
	) {
		variables.accessKeyId = arguments.accessKeyId;
		variables.secretAccessKey = arguments.secretAccessKey;
		variables.region = arguments.region;
		variables.bucket = arguments.bucket;
		variables.usePathStyle = arguments.usePathStyle;
		variables.service = "s3";

		if (Len(arguments.endpoint)) {
			variables.host = arguments.endpoint;
		} else if (arguments.usePathStyle) {
			variables.host = "s3." & arguments.region & ".amazonaws.com";
		} else {
			variables.host = arguments.bucket & ".s3." & arguments.region & ".amazonaws.com";
		}

		variables.javaSystem = CreateObject("java", "java.lang.System");
		return this;
	}

	/**
	 * Build a presigned GET URL for an object key.
	 *
	 * @key Object key (path-like; slashes preserved).
	 * @expiresIn Seconds until the link expires (default 300, max 604800 per SigV4).
	 * @contentDisposition Optional response-content-disposition override S3 will echo.
	 * @amzDate Optional ISO8601 basic timestamp ("yyyymmddTHHnnssZ"). Defaults to now (UTC). Overridable for deterministic tests.
	 */
	public string function presignGetUrl(
		required string key,
		numeric expiresIn = 300,
		string contentDisposition = "",
		string amzDate = ""
	) {
		$assertExpiresIn(arguments.expiresIn);
		local.amzDate = Len(arguments.amzDate) ? arguments.amzDate : $amzNow();
		local.dateStamp = Left(local.amzDate, 8);
		local.credentialScope = local.dateStamp & "/" & variables.region & "/" & variables.service & "/aws4_request";

		// Canonical URI: path-style prefixes the bucket; virtual-hosted does not.
		local.canonicalUri = variables.usePathStyle
			? "/" & $uriEncodePath(variables.bucket & "/" & arguments.key)
			: "/" & $uriEncodePath(arguments.key);

		// Canonical query string — keys must be sorted by their encoded name.
		local.params = {
			"X-Amz-Algorithm" = "AWS4-HMAC-SHA256",
			"X-Amz-Credential" = variables.accessKeyId & "/" & local.credentialScope,
			"X-Amz-Date" = local.amzDate,
			"X-Amz-Expires" = arguments.expiresIn,
			"X-Amz-SignedHeaders" = "host"
		};
		if (Len(arguments.contentDisposition)) {
			local.params["response-content-disposition"] = arguments.contentDisposition;
		}
		local.canonicalQuery = $buildCanonicalQuery(local.params);

		local.canonicalHeaders = "host:" & variables.host & Chr(10);
		local.signedHeaders = "host";
		local.payloadHash = "UNSIGNED-PAYLOAD";

		local.canonicalRequest = "GET" & Chr(10)
			& local.canonicalUri & Chr(10)
			& local.canonicalQuery & Chr(10)
			& local.canonicalHeaders & Chr(10)
			& local.signedHeaders & Chr(10)
			& local.payloadHash;

		local.signature = $signString(local.canonicalRequest, local.amzDate, local.dateStamp, local.credentialScope);

		local.scheme = "https://";
		return local.scheme & variables.host & local.canonicalUri & "?" & local.canonicalQuery
			& "&X-Amz-Signature=" & local.signature;
	}

	/**
	 * Sign an arbitrary S3 request, returning the headers (incl. Authorization)
	 * a caller adds to a `cfhttp` invocation. Used for put/get/delete/exists.
	 *
	 * @method HTTP verb.
	 * @key Object key.
	 * @payload Request body (binary or string); empty for GET/DELETE/HEAD.
	 * @amzDate Optional deterministic timestamp override.
	 * @range Optional Range header value (e.g. "bytes=0-9"). Empty keeps the current signed header set.
	 * @acl Optional x-amz-acl value. Empty keeps the current signed header set (S8 vector).
	 * @return Struct of header name => value to attach to the request.
	 */
	public struct function signedHeaders(
		required string method,
		required string key,
		any payload = "",
		string amzDate = "",
		string range = "",
		string acl = ""
	) {
		local.amzDate = Len(arguments.amzDate) ? arguments.amzDate : $amzNow();
		local.dateStamp = Left(local.amzDate, 8);
		local.credentialScope = local.dateStamp & "/" & variables.region & "/" & variables.service & "/aws4_request";

		local.payloadHash = $sha256Hex(arguments.payload);

		local.canonicalUri = variables.usePathStyle
			? "/" & $uriEncodePath(variables.bucket & "/" & arguments.key)
			: "/" & $uriEncodePath(arguments.key);

		// Optional range / acl insert in code-point order so the S8 no-acl vector
		// stays byte-identical when both are empty.
		local.canonicalHeaders = "host:" & variables.host & Chr(10);
		local.signedHeaderList = "host";
		if (Len(arguments.range)) {
			local.canonicalHeaders &= "range:" & arguments.range & Chr(10);
			local.signedHeaderList &= ";range";
		}
		if (Len(arguments.acl)) {
			local.canonicalHeaders &= "x-amz-acl:" & arguments.acl & Chr(10);
			local.signedHeaderList &= ";x-amz-acl";
		}
		local.canonicalHeaders &= "x-amz-content-sha256:" & local.payloadHash & Chr(10)
			& "x-amz-date:" & local.amzDate & Chr(10);
		local.signedHeaderList &= ";x-amz-content-sha256;x-amz-date";

		local.canonicalRequest = UCase(arguments.method) & Chr(10)
			& local.canonicalUri & Chr(10)
			& "" & Chr(10)
			& local.canonicalHeaders & Chr(10)
			& local.signedHeaderList & Chr(10)
			& local.payloadHash;

		local.signature = $signString(local.canonicalRequest, local.amzDate, local.dateStamp, local.credentialScope);

		local.authorization = "AWS4-HMAC-SHA256 "
			& "Credential=" & variables.accessKeyId & "/" & local.credentialScope & ", "
			& "SignedHeaders=" & local.signedHeaderList & ", "
			& "Signature=" & local.signature;

		local.headers = {
			"Authorization" = local.authorization,
			"x-amz-content-sha256" = local.payloadHash,
			"x-amz-date" = local.amzDate,
			"Host" = variables.host
		};
		if (Len(arguments.range)) {
			local.headers["Range"] = arguments.range;
		}
		if (Len(arguments.acl)) {
			local.headers["x-amz-acl"] = arguments.acl;
		}
		return local.headers;
	}

	/**
	 * The resolved request host (virtual-hosted or path-style endpoint).
	 */
	public string function getHost() {
		return variables.host;
	}

	/**
	 * RFC3986-encode an object key for use as a request path (forward slashes
	 * preserved). The wire URL must use the same encoding the canonical request
	 * signs, or S3 returns SignatureDoesNotMatch for keys with spaces / reserved
	 * characters. Lets the disk build request/url paths that stay byte-identical
	 * to what was signed.
	 *
	 * @key Object key.
	 */
	public string function encodeKey(required string key) {
		return $uriEncodePath(arguments.key);
	}

	// ---- internals --------------------------------------------------------

	/**
	 * Produce the lowercase-hex SigV4 signature for a canonical request.
	 */
	private string function $signString(
		required string canonicalRequest,
		required string amzDate,
		required string dateStamp,
		required string credentialScope
	) {
		local.stringToSign = "AWS4-HMAC-SHA256" & Chr(10)
			& arguments.amzDate & Chr(10)
			& arguments.credentialScope & Chr(10)
			& $sha256Hex(arguments.canonicalRequest);

		local.signingKey = $signingKey(arguments.dateStamp);
		return LCase(BinaryEncode($hmac(local.signingKey, local.stringToSign), "hex"));
	}

	/**
	 * Derive the SigV4 signing key: HMAC chain seeded with "AWS4"+secret.
	 */
	private binary function $signingKey(required string dateStamp) {
		local.kSecret = CharsetDecode("AWS4" & variables.secretAccessKey, "UTF-8");
		local.kDate = $hmac(local.kSecret, arguments.dateStamp);
		local.kRegion = $hmac(local.kDate, variables.region);
		local.kService = $hmac(local.kRegion, variables.service);
		return $hmac(local.kService, "aws4_request");
	}

	/**
	 * HMAC-SHA256 with a binary key, returning raw bytes. Prefers
	 * javax.crypto.Mac so successive rounds can key off the previous round's
	 * binary output (the built-in Hmac() takes only string keys on JVM
	 * engines). Falls back to the engine's native hmac(), which hashes binary
	 * keys verbatim, when the Mac shim cannot produce binary output
	 * (RustCFML's shim returns signed-byte arrays). The IsBinary check keeps
	 * the fallback decision inside the function body: the binary return-type
	 * coercion runs outside the body on every engine, so returning the
	 * array directly would throw an uncatchable cast error on RustCFML.
	 */
	private binary function $hmac(required binary key, required string message) {
		try {
			local.mac = CreateObject("java", "javax.crypto.Mac").getInstance("HmacSHA256");
			local.keySpec = CreateObject("java", "javax.crypto.spec.SecretKeySpec").init(arguments.key, "HmacSHA256");
			local.mac.init(local.keySpec);
			local.raw = local.mac.doFinal(CharsetDecode(arguments.message, "UTF-8"));
		} catch (any e) {
			local.raw = "not-binary";
		}
		if (IsBinary(local.raw)) {
			return local.raw;
		}
		// JVM-free engine (RustCFML): native hmac() takes the binary key
		// verbatim and returns uppercase hex.
		local.hex = Hmac(arguments.message, arguments.key, "HMACSHA256");
		return BinaryDecode(local.hex, "hex");
	}

	/**
	 * Lowercase hex SHA-256 of a string or binary payload.
	 */
	private string function $sha256Hex(required any content) {
		if (IsBinary(arguments.content)) {
			return LCase(Hash(arguments.content, "SHA-256"));
		}
		return LCase(Hash(arguments.content, "SHA-256", "UTF-8"));
	}

	/**
	 * Build a sorted, RFC3986-encoded canonical query string from a struct.
	 */
	private string function $buildCanonicalQuery(required struct params) {
		local.keys = StructKeyArray(arguments.params);
		// SigV4 sorts by raw byte order of the encoded key name; for our fixed
		// ASCII parameter names a case-sensitive text sort is byte-identical.
		ArraySort(local.keys, "text");
		local.pairs = [];
		for (local.k in local.keys) {
			ArrayAppend(local.pairs, $uriEncodeSegment(local.k) & "=" & $uriEncodeSegment(arguments.params[local.k]));
		}
		return ArrayToList(local.pairs, "&");
	}

	/**
	 * RFC3986 encode a single value (slashes ARE encoded). Built on
	 * BinaryEncode/hex instead of java.net.URLEncoder so it is byte-identical
	 * across engines, including JVM-free RustCFML: unreserved bytes
	 * (A-Z a-z 0-9 - _ . ~) pass through, everything else becomes %XX with
	 * uppercase hex — the canonical form AWS SigV4 requires.
	 */
	private string function $uriEncodeSegment(required any value) {
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

	/**
	 * RFC3986 encode an object key path, preserving forward slashes.
	 */
	private string function $uriEncodePath(required string key) {
		return Replace($uriEncodeSegment(arguments.key), "%2F", "/", "all");
	}

	private void function $assertExpiresIn(required numeric expiresIn) {
		if (arguments.expiresIn < 1 || arguments.expiresIn > 604800) {
			throw(
				type = "Wheels.Storage.InvalidExpiresIn",
				message = "signedUrl expiresIn must be between 1 and 604800 seconds (got #arguments.expiresIn#)."
			);
		}
	}

	/**
	 * Current UTC time as an ISO8601 basic timestamp ("yyyymmddTHHnnssZ").
	 */
	private string function $amzNow() {
		local.utc = DateConvert("local2utc", Now());
		return DateFormat(local.utc, "yyyymmdd") & "T" & TimeFormat(local.utc, "HHmmss") & "Z";
	}

}
