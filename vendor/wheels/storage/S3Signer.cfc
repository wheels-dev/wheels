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
	 * @return Struct of header name => value to attach to the request.
	 */
	public struct function signedHeaders(
		required string method,
		required string key,
		any payload = "",
		string amzDate = ""
	) {
		local.amzDate = Len(arguments.amzDate) ? arguments.amzDate : $amzNow();
		local.dateStamp = Left(local.amzDate, 8);
		local.credentialScope = local.dateStamp & "/" & variables.region & "/" & variables.service & "/aws4_request";

		local.payloadHash = $sha256Hex(arguments.payload);

		local.canonicalUri = variables.usePathStyle
			? "/" & $uriEncodePath(variables.bucket & "/" & arguments.key)
			: "/" & $uriEncodePath(arguments.key);

		// Headers signed for header-auth: host, x-amz-content-sha256, x-amz-date (sorted).
		local.canonicalHeaders = "host:" & variables.host & Chr(10)
			& "x-amz-content-sha256:" & local.payloadHash & Chr(10)
			& "x-amz-date:" & local.amzDate & Chr(10);
		local.signedHeaderList = "host;x-amz-content-sha256;x-amz-date";

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

		return {
			"Authorization" = local.authorization,
			"x-amz-content-sha256" = local.payloadHash,
			"x-amz-date" = local.amzDate,
			"Host" = variables.host
		};
	}

	/**
	 * The resolved request host (virtual-hosted or path-style endpoint).
	 */
	public string function getHost() {
		return variables.host;
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
	 * HMAC-SHA256 with a binary key, returning raw bytes. Uses javax.crypto.Mac
	 * directly so successive rounds can key off the previous round's binary
	 * output — the built-in HMac() takes only string keys.
	 */
	private binary function $hmac(required binary key, required string message) {
		local.mac = CreateObject("java", "javax.crypto.Mac").getInstance("HmacSHA256");
		local.keySpec = CreateObject("java", "javax.crypto.spec.SecretKeySpec").init(arguments.key, "HmacSHA256");
		local.mac.init(local.keySpec);
		return local.mac.doFinal(CharsetDecode(arguments.message, "UTF-8"));
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
	 * java.net.URLEncoder with the AWS-required fix-ups so it is byte-identical
	 * across engines.
	 */
	private string function $uriEncodeSegment(required any value) {
		local.encoder = CreateObject("java", "java.net.URLEncoder");
		local.encoded = local.encoder.encode(ToString(arguments.value), "UTF-8");
		local.encoded = Replace(local.encoded, "+", "%20", "all");
		local.encoded = Replace(local.encoded, "*", "%2A", "all");
		local.encoded = Replace(local.encoded, "%7E", "~", "all");
		return local.encoded;
	}

	/**
	 * RFC3986 encode an object key path, preserving forward slashes.
	 */
	private string function $uriEncodePath(required string key) {
		return Replace($uriEncodeSegment(arguments.key), "%2F", "/", "all");
	}

	/**
	 * Current UTC time as an ISO8601 basic timestamp ("yyyymmddTHHnnssZ").
	 */
	private string function $amzNow() {
		local.utc = DateConvert("local2utc", Now());
		return DateFormat(local.utc, "yyyymmdd") & "T" & TimeFormat(local.utc, "HHmmss") & "Z";
	}

}
