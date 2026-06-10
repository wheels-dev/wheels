/**
 * JWT token generation, validation, and claim extraction using HMAC-SHA256.
 *
 * Provides encode/decode/verify/refresh operations for JSON Web Tokens.
 * Used standalone or by JwtStrategy for request authentication.
 *
 * Usage:
 *   var jwt = new wheels.auth.JwtService(secretKey="a-random-secret-of-at-least-32-bytes");
 *   var token = jwt.encode({sub=42, role="admin"});
 *   var claims = jwt.decode(token);
 *   var refreshed = jwt.refresh(token);
 *
 * [section: Authentication]
 * [category: Core]
 */
component output="false" {

	/**
	 * Creates a new JwtService instance.
	 *
	 * @secretKey The HMAC-SHA256 signing key. Must be at least 32 bytes (256 bits) per RFC 7518 Section 3.2; construction throws otherwise.
	 * @defaultExpiry Default token lifetime in seconds (default 3600 = 1 hour).
	 * @issuer Default issuer claim (iss). Empty string means no iss claim added and no iss validation on decode.
	 * @allowedClockSkew Seconds of clock skew tolerance for expiry checks (default 0).
	 */
	public JwtService function init(
		required string secretKey,
		numeric defaultExpiry = 3600,
		string issuer = "",
		numeric allowedClockSkew = 0
	) {
		// Fail fast on missing or weak secrets — a short HMAC key makes every issued token brute-forceable
		if (!Len(arguments.secretKey)) {
			Throw(
				type = "Wheels.Auth.JWT.InvalidSecretKey",
				message = "JWT secret key cannot be empty.",
				extendedInfo = "Provide a random secret of at least 32 bytes (256 bits) as required for HMAC-SHA256 by RFC 7518 Section 3.2."
			);
		}
		if (Len(CharsetDecode(arguments.secretKey, "UTF-8")) < 32) {
			Throw(
				type = "Wheels.Auth.JWT.WeakSecretKey",
				message = "JWT secret key is too short.",
				extendedInfo = "HMAC-SHA256 requires a secret of at least 32 bytes (256 bits) per RFC 7518 Section 3.2. Generate a random secret of 32 or more bytes and store it outside source control."
			);
		}

		variables.secretKey = arguments.secretKey;
		variables.defaultExpiry = arguments.defaultExpiry;
		variables.issuer = arguments.issuer;
		variables.allowedClockSkew = arguments.allowedClockSkew;

		// Cache the Java class handles used on the per-request encode/decode paths
		variables.messageDigest = CreateObject("java", "java.security.MessageDigest");
		variables.javaSystem = CreateObject("java", "java.lang.System");

		return this;
	}

	/**
	 * Encode a claims struct into a signed JWT token string.
	 *
	 * Standard claims (iat, exp) are added automatically if not present.
	 * If an issuer was configured, the iss claim is added if not present.
	 *
	 * @claims Struct of claims to encode. Custom claims are passed through as-is.
	 * @expiry Token lifetime in seconds. Overrides defaultExpiry if provided.
	 * @return Signed JWT token string (header.payload.signature).
	 */
	public string function encode(struct claims = {}, numeric expiry = 0) {
		local.payload = Duplicate(arguments.claims);
		local.now = $epochSeconds();

		// Set standard time claims if not explicitly provided
		if (!StructKeyExists(local.payload, "iat")) {
			local.payload["iat"] = local.now;
		}

		local.ttl = arguments.expiry > 0 ? arguments.expiry : variables.defaultExpiry;
		if (!StructKeyExists(local.payload, "exp")) {
			local.payload["exp"] = local.now + local.ttl;
		}

		// Add issuer if configured and not already set
		if (Len(variables.issuer) && !StructKeyExists(local.payload, "iss")) {
			local.payload["iss"] = variables.issuer;
		}

		// Build JWT: header.payload.signature
		local.headerEncoded = $base64UrlEncode('{"alg":"HS256","typ":"JWT"}');
		local.payloadEncoded = $base64UrlEncode($toJson(local.payload));
		local.signingInput = local.headerEncoded & "." & local.payloadEncoded;
		local.signature = $sign(local.signingInput);

		return local.signingInput & "." & local.signature;
	}

	/**
	 * Decode and validate a JWT token, returning the claims struct.
	 *
	 * Verifies the signature and checks expiry/nbf claims. When an issuer was
	 * configured, the iss claim must be present and match it (case-sensitive).
	 * Throws on invalid token, bad signature, wrong issuer, or expired token.
	 *
	 * @token The JWT token string to decode.
	 * @ignoreExpiry If true, skip expiry validation (used for refresh). Default false.
	 * @return Struct of decoded claims.
	 */
	public struct function decode(required string token, boolean ignoreExpiry = false) {
		local.parts = ListToArray(arguments.token, ".");

		if (ArrayLen(local.parts) != 3) {
			throw(
				type = "Wheels.Auth.JWT.InvalidToken",
				message = "Invalid JWT format: expected 3 dot-separated parts"
			);
		}

		// Decode and validate header algorithm — prevent algorithm substitution attacks
		local.headerJson = $base64UrlDecode(local.parts[1]);
		local.header = DeserializeJSON(local.headerJson);
		if (!StructKeyExists(local.header, "alg") || local.header.alg != "HS256") {
			local.claimedAlg = StructKeyExists(local.header, "alg") ? local.header.alg : "none";
			Throw(
				type = "Wheels.Auth.JWT.InvalidAlgorithm",
				message = "JWT algorithm mismatch.",
				extendedInfo = "Expected algorithm HS256 but token header specifies '#EncodeForHTML(local.claimedAlg)#'. This may indicate an algorithm substitution attack."
			);
		}

		// Verify signature
		local.signingInput = local.parts[1] & "." & local.parts[2];
		local.expectedSig = $sign(local.signingInput);

		if (!variables.messageDigest.isEqual(
			local.expectedSig.getBytes("UTF-8"),
			local.parts[3].getBytes("UTF-8")
		)) {
			throw(
				type = "Wheels.Auth.JWT.InvalidSignature",
				message = "JWT signature verification failed"
			);
		}

		// Decode payload
		local.payloadJson = $base64UrlDecode(local.parts[2]);
		local.claims = DeserializeJSON(local.payloadJson);

		// Validate issuer when one was configured (case-sensitive, hence Compare instead of EQ)
		if (Len(variables.issuer)) {
			if (
				!StructKeyExists(local.claims, "iss")
				|| Compare(ToString(local.claims.iss), variables.issuer) != 0
			) {
				throw(
					type = "Wheels.Auth.JWT.InvalidIssuer",
					message = "JWT issuer validation failed"
				);
			}
		}

		// Validate time-based claims
		if (!arguments.ignoreExpiry) {
			local.now = $epochSeconds();

			if (StructKeyExists(local.claims, "exp")) {
				if (local.claims.exp + variables.allowedClockSkew < local.now) {
					throw(
						type = "Wheels.Auth.JWT.TokenExpired",
						message = "JWT token has expired"
					);
				}
			}

			if (StructKeyExists(local.claims, "nbf")) {
				if (local.claims.nbf - variables.allowedClockSkew > local.now) {
					throw(
						type = "Wheels.Auth.JWT.TokenNotYetValid",
						message = "JWT token is not yet valid"
					);
				}
			}
		}

		return local.claims;
	}

	/**
	 * Verify a JWT token without throwing. Returns true if valid.
	 *
	 * @token The JWT token string to verify.
	 * @return True if the token has a valid signature and is not expired.
	 */
	public boolean function verify(required string token) {
		try {
			decode(arguments.token);
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Refresh a JWT token by generating a new one with updated timestamps.
	 *
	 * Accepts expired tokens (signature must still be valid). Preserves all
	 * existing claims but updates iat and exp. The jti claim is removed
	 * so callers can assign a new one if needed.
	 *
	 * @token The existing JWT token to refresh.
	 * @expiry New token lifetime in seconds. Uses defaultExpiry if not provided.
	 * @return New signed JWT token string.
	 */
	public string function refresh(required string token, numeric expiry = 0) {
		// Decode with ignoreExpiry=true to allow refreshing expired tokens
		local.claims = decode(token = arguments.token, ignoreExpiry = true);

		// Remove time-based claims so encode() regenerates them
		StructDelete(local.claims, "iat");
		StructDelete(local.claims, "exp");
		StructDelete(local.claims, "jti");

		return encode(claims = local.claims, expiry = arguments.expiry);
	}

	/**
	 * Extract claims from a token WITHOUT validation. Use for debugging only.
	 *
	 * @token The JWT token string.
	 * @return Struct of decoded claims (unvalidated).
	 */
	public struct function extractClaims(required string token) {
		local.parts = ListToArray(arguments.token, ".");
		if (ArrayLen(local.parts) < 2) {
			throw(
				type = "Wheels.Auth.JWT.InvalidToken",
				message = "Invalid JWT format: expected at least 2 dot-separated parts"
			);
		}
		return DeserializeJSON($base64UrlDecode(local.parts[2]));
	}

	// ---------------------------------------------------------------------------
	// Private helpers
	// ---------------------------------------------------------------------------

	/**
	 * Base64url-encode a UTF-8 string.
	 */
	private string function $base64UrlEncode(required string value) {
		local.base64 = ToBase64(arguments.value);
		local.base64 = Replace(local.base64, "+", "-", "all");
		local.base64 = Replace(local.base64, "/", "_", "all");
		local.base64 = REReplace(local.base64, "=+$", "");
		return local.base64;
	}

	/**
	 * Base64url-decode to a UTF-8 string.
	 */
	private string function $base64UrlDecode(required string value) {
		local.base64 = Replace(arguments.value, "-", "+", "all");
		local.base64 = Replace(local.base64, "_", "/", "all");
		local.padLen = 4 - (Len(local.base64) % 4);
		if (local.padLen < 4) {
			local.base64 = local.base64 & RepeatString("=", local.padLen);
		}
		return ToString(ToBinary(local.base64));
	}

	/**
	 * HMAC-SHA256 sign a message and return the base64url-encoded signature.
	 */
	private string function $sign(required string message) {
		local.hmacHex = HMac(arguments.message, variables.secretKey, "HMACSHA256", "UTF-8");
		local.hmacBinary = BinaryDecode(local.hmacHex, "hex");
		local.base64 = BinaryEncode(local.hmacBinary, "base64");
		local.base64 = Replace(local.base64, "+", "-", "all");
		local.base64 = Replace(local.base64, "/", "_", "all");
		local.base64 = REReplace(local.base64, "=+$", "");
		return local.base64;
	}

	/**
	 * Serialize a struct to JSON with lowercase keys for JWT interoperability.
	 *
	 * Uses a Java LinkedHashMap to guarantee lowercase key output regardless
	 * of CFML engine (Adobe CF uppercases struct keys by default).
	 */
	private string function $toJson(required struct data) {
		local.map = CreateObject("java", "java.util.LinkedHashMap").init();
		// Standard claims first in conventional order
		local.standardClaims = ["iss", "sub", "aud", "exp", "nbf", "iat", "jti"];
		for (local.claim in local.standardClaims) {
			if (StructKeyExists(arguments.data, local.claim)) {
				local.map.put(local.claim, arguments.data[local.claim]);
			}
		}
		// Custom claims after standard ones
		for (local.key in arguments.data) {
			local.lcKey = LCase(local.key);
			if (!local.map.containsKey(local.lcKey)) {
				local.map.put(local.lcKey, arguments.data[local.key]);
			}
		}
		return SerializeJSON(local.map);
	}

	/**
	 * Get current time as Unix epoch seconds (UTC).
	 *
	 * Uses the cached java.lang.System handle: currentTimeMillis() is guaranteed wall-clock
	 * epoch time on every engine, unlike GetTickCount(), whose contract only promises a
	 * relative millisecond clock (JVM uptime on some engines) — unusable for RFC 7519
	 * iat/exp/nbf claims.
	 */
	private numeric function $epochSeconds() {
		return Int(variables.javaSystem.currentTimeMillis() / 1000);
	}

}
