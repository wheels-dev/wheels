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
	 *         visibility="private", endpoint="", usePathStyle=false }.
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
		if (Val(local.result.statusCode) >= 300) {
			throw(type = "Wheels.Storage.RequestFailed", message = "S3 PUT failed for [#arguments.key#]: #local.result.statusCode#.");
		}
		return arguments.key;
	}

	public any function get(required string key) {
		local.headers = variables.signer.signedHeaders(method = "GET", key = arguments.key);
		local.result = $request(method = "GET", key = arguments.key, headers = local.headers, getAsBinary = true);
		if (Val(local.result.statusCode) == 404) {
			throw(type = "Wheels.Storage.NotFound", message = "No object stored at key [#arguments.key#].");
		}
		if (Val(local.result.statusCode) >= 300) {
			throw(type = "Wheels.Storage.RequestFailed", message = "S3 GET failed for [#arguments.key#]: #local.result.statusCode#.");
		}
		return local.result.fileContent;
	}

	public boolean function exists(required string key) {
		local.headers = variables.signer.signedHeaders(method = "HEAD", key = arguments.key);
		local.result = $request(method = "HEAD", key = arguments.key, headers = local.headers);
		return Val(local.result.statusCode) < 300;
	}

	public boolean function delete(required string key) {
		local.headers = variables.signer.signedHeaders(method = "DELETE", key = arguments.key);
		local.result = $request(method = "DELETE", key = arguments.key, headers = local.headers);
		// S3 DELETE is idempotent — 204 whether or not the object existed.
		return Val(local.result.statusCode) < 300;
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
		return variables.usePathStyle ? "/" & variables.bucket & "/" & local.k : "/" & local.k;
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
		cfhttp(method = arguments.method, url = local.targetUrl, result = "local.httpResult", getAsBinary = (arguments.getAsBinary ? "yes" : "auto"), timeout = 60) {
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
		return {
			statusCode = ListFirst(local.httpResult.statusCode ?: "0", " "),
			fileContent = local.httpResult.fileContent ?: ""
		};
	}

}
