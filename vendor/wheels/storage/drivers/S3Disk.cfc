/**
 * Amazon S3 (and S3-compatible) storage disk.
 *
 * Talks to S3 over plain `cfhttp` with from-scratch SigV4 request signing —
 * no AWS SDK, no JARs (see `wheels.storage.S3Signer`). `url()` returns the
 * object's public URL; `signedUrl()` returns a presigned, expiring GET URL.
 *
 * [section: Storage]
 * [category: Driver]
 */
component implements="wheels.interfaces.StorageDiskInterface" output="false" {

	/**
	 * @config Disk config: { bucket, region, accessKeyId, secretAccessKey,
	 *         visibility="private", endpoint="", usePathStyle=false, timeout=60 }.
	 */
	public S3Disk function init(required struct config) {
		for (local.required in ["bucket", "region", "accessKeyId", "secretAccessKey"]) {
			if (!StructKeyExists(arguments.config, local.required) || !Len(arguments.config[local.required])) {
				throw(
					type = "Wheels.Storage.InvalidConfiguration",
					message = "S3 disk requires a non-empty '#local.required#'."
				);
			}
		}
		variables.bucket = arguments.config.bucket;
		variables.region = arguments.config.region;
		variables.visibility = StructKeyExists(arguments.config, "visibility") ? arguments.config.visibility : "private";
		variables.usePathStyle = StructKeyExists(arguments.config, "usePathStyle") ? arguments.config.usePathStyle : false;
		variables.endpoint = StructKeyExists(arguments.config, "endpoint") ? arguments.config.endpoint : "";
		variables.timeout = StructKeyExists(arguments.config, "timeout") ? arguments.config.timeout : 60;

		variables.signer = new wheels.storage.S3Signer(
			accessKeyId = arguments.config.accessKeyId,
			secretAccessKey = arguments.config.secretAccessKey,
			region = arguments.config.region,
			bucket = arguments.config.bucket,
			endpoint = variables.endpoint,
			usePathStyle = variables.usePathStyle
		);
		return this;
	}

	public any function put(required string key, required any content, string contentType = "application/octet-stream", string visibility = "") {
		local.headers = variables.signer.signedHeaders(method = "PUT", key = arguments.key, payload = arguments.content);
		local.result = $request(method = "PUT", key = arguments.key, headers = local.headers, body = arguments.content, contentType = arguments.contentType);
		$assertSuccess(result = local.result, method = "PUT", key = arguments.key);
		return arguments.key;
	}

	public any function get(required string key) {
		local.headers = variables.signer.signedHeaders(method = "GET", key = arguments.key);
		local.result = $request(method = "GET", key = arguments.key, headers = local.headers, getAsBinary = true);
		if (Val(local.result.statusCode) == 404) {
			throw(type = "Wheels.Storage.NotFound", message = "No object stored at key [#arguments.key#].");
		}
		$assertSuccess(result = local.result, method = "GET", key = arguments.key);
		return local.result.fileContent;
	}

	public boolean function exists(required string key) {
		local.headers = variables.signer.signedHeaders(method = "HEAD", key = arguments.key);
		local.result = $request(method = "HEAD", key = arguments.key, headers = local.headers);
		local.code = Val(local.result.statusCode);
		if (local.code >= 200 && local.code < 300) {
			return true;
		}
		if (local.code == 404) {
			return false;
		}
		// A connection failure or 5xx is NOT "the object is absent" — reporting
		// false there would be a silent failure, so surface it instead.
		throw(
			type = "Wheels.Storage.RequestFailed",
			message = "S3 HEAD failed for [#arguments.key#]: #$statusDetail(local.result)#."
		);
	}

	public boolean function delete(required string key) {
		local.headers = variables.signer.signedHeaders(method = "DELETE", key = arguments.key);
		local.result = $request(method = "DELETE", key = arguments.key, headers = local.headers);
		// S3 DELETE is idempotent — 2xx whether or not the object existed — but a
		// connection failure or 5xx must not masquerade as a successful delete.
		$assertSuccess(result = local.result, method = "DELETE", key = arguments.key);
		return true;
	}

	public string function url(required string key) {
		return "https://" & variables.signer.getHost() & $objectPath(arguments.key);
	}

	public string function signedUrl(required string key, numeric expiresIn = 300, string contentDisposition = "") {
		return variables.signer.presignGetUrl(
			key = arguments.key,
			expiresIn = arguments.expiresIn,
			contentDisposition = arguments.contentDisposition
		);
	}

	// ---- internals --------------------------------------------------------

	private string function $objectPath(required string key) {
		local.k = REReplace(arguments.key, "^/+", "");
		// Encode through the signer so the wire path is byte-identical to the
		// canonical path the SigV4 signature covers — otherwise S3 rejects keys
		// containing spaces / reserved characters with SignatureDoesNotMatch.
		// Mirrors the signer's canonicalUri (path-style prefixes the bucket).
		return variables.usePathStyle
			? "/" & variables.signer.encodeKey(variables.bucket & "/" & local.k)
			: "/" & variables.signer.encodeKey(local.k);
	}

	/**
	 * Throw `Wheels.Storage.RequestFailed` unless the request returned a 2xx
	 * status. `cfhttp` does not set `throwOnError`, so a DNS/connection failure
	 * does not throw — it returns a non-numeric status (e.g. "Connection
	 * Failure") whose `Val()` is 0. The `< 200` guard catches that path too;
	 * without it a failed request would read as success and silently lose data.
	 */
	private void function $assertSuccess(required struct result, required string method, required string key) {
		local.code = Val(arguments.result.statusCode);
		if (local.code < 200 || local.code >= 300) {
			throw(
				type = "Wheels.Storage.RequestFailed",
				message = "S3 #arguments.method# failed for [#arguments.key#]: #$statusDetail(arguments.result)#."
			);
		}
	}

	/**
	 * Human-readable status for error messages — the raw status line, or an
	 * explicit note when the request produced none (connection failure).
	 */
	private string function $statusDetail(required struct result) {
		return Len(arguments.result.statusCode) ? arguments.result.statusCode : "no response (connection failure)";
	}

	/**
	 * Issue a signed cfhttp request. Headers are copied into a plain struct
	 * before being attached one-by-one — never `attributeCollection=arguments`,
	 * which Adobe CF 2023/2025 reject on built-in tags.
	 */
	private struct function $request(
		required string method,
		required string key,
		required struct headers,
		any body = "",
		string contentType = "",
		boolean getAsBinary = false
	) {
		local.targetUrl = "https://" & variables.signer.getHost() & $objectPath(arguments.key);
		local.hdrs = {};
		for (local.name in arguments.headers) {
			local.hdrs[local.name] = arguments.headers[local.name];
		}

		local.httpResult = "";
		cfhttp(method = arguments.method, url = local.targetUrl, result = "local.httpResult", getAsBinary = (arguments.getAsBinary ? "yes" : "auto"), timeout = variables.timeout) {
			for (local.name in local.hdrs) {
				cfhttpparam(type = "header", name = local.name, value = local.hdrs[local.name]);
			}
			if (Len(arguments.contentType)) {
				cfhttpparam(type = "header", name = "Content-Type", value = arguments.contentType);
			}
			if (!IsSimpleValue(arguments.body) || Len(arguments.body)) {
				cfhttpparam(type = "body", value = arguments.body);
			}
		}
		// Preserve the raw status line — callers extract the numeric code with
		// Val() (0 for a non-numeric connection-failure status) and use the full
		// string for diagnostics.
		return {
			statusCode = local.httpResult.statusCode ?: "",
			fileContent = local.httpResult.fileContent ?: ""
		};
	}

}
