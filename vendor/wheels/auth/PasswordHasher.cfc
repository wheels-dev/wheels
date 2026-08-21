/**
 * Cross-engine password hashing service using PBKDF2-HMAC-SHA256.
 *
 * Produces and verifies self-describing, modular-crypt-style hashes:
 *
 *   $pbkdf2-sha256$i=<iterations>$<base64(salt)>$<base64(derivedKey)>
 *
 * One algorithm, one storage format: derivation goes through the JVM's
 * javax.crypto.SecretKeyFactory ("PBKDF2WithHmacSHA256"), so the same
 * (password, salt, iterations) always yields the same bytes on Lucee,
 * Adobe CF, and BoxLang alike. Hashes are portable across engines and
 * engine migrations, and the embedded iteration count lets deployments
 * raise the work factor over time (see needsRehash()).
 *
 * Defaults: 600000 iterations (OWASP 2023+ recommendation for
 * PBKDF2-HMAC-SHA256), 16-byte SecureRandom salt, 256-bit derived key.
 *
 * Passwords are UTF-8 encoded before derivation, so unicode passwords
 * round-trip. Empty passwords hash and verify successfully by design —
 * minimum-length policy belongs in application-level validations
 * (e.g. validatesLengthOf() on the User model), not in the hasher.
 *
 * Usage:
 *   // Register during app init (config/services.cfm)
 *   injector().map("passwordHasher").to("wheels.auth.PasswordHasher").asSingleton();
 *
 *   // Hashing on signup / password change:
 *   user.passwordHash = service("passwordHasher").hash(params.password);
 *
 *   // Verifying on login:
 *   if (service("passwordHasher").verify(params.password, user.passwordHash)) { ... }
 *
 *   // Transparent work-factor upgrades after a successful verify:
 *   if (service("passwordHasher").needsRehash(user.passwordHash)) {
 *       user.passwordHash = service("passwordHasher").hash(params.password);
 *   }
 *
 * [section: Authentication]
 * [category: Core]
 */
component output="false" {

	/**
	 * Creates a new PasswordHasher.
	 *
	 * @iterations PBKDF2 iteration count used by hash() and as the needsRehash() threshold. Must be a positive integer; construction throws Wheels.PasswordHasher.InvalidConfiguration otherwise. Default 600000 (OWASP 2023+).
	 */
	public PasswordHasher function init(numeric iterations = 600000) {
		if (arguments.iterations <= 0 || arguments.iterations != Int(arguments.iterations)) {
			throw(
				type = "Wheels.PasswordHasher.InvalidConfiguration",
				message = "PasswordHasher iterations must be a positive integer.",
				extendedInfo = "Received `#arguments.iterations#`. Use the default (600000, the OWASP 2023+ recommendation for PBKDF2-HMAC-SHA256) unless you have measured a different work factor for your hardware."
			);
		}

		variables.iterations = arguments.iterations;
		variables.algorithmTag = "pbkdf2-sha256";
		variables.saltLengthBytes = 16;
		variables.keyLengthBits = 256;

		// Cached Java handles. SecureRandom is documented thread-safe;
		// MessageDigest is only used for its static isEqual(). SecretKeyFactory
		// is NOT documented thread-safe, so $deriveKey() creates one per call —
		// getInstance() cost is noise next to a 600k-iteration derivation.
		variables.secureRandom = CreateObject("java", "java.security.SecureRandom").init();
		variables.messageDigest = CreateObject("java", "java.security.MessageDigest");

		return this;
	}

	/**
	 * Hash a password with a fresh random salt.
	 *
	 * Every call generates a new 16-byte SecureRandom salt, so hashing the
	 * same password twice yields different strings. The empty password is
	 * accepted by design; enforce minimum-length policy in your model
	 * validations instead.
	 *
	 * @password The plaintext password to hash (UTF-8 encoded before derivation).
	 * @return Self-describing hash string: $pbkdf2-sha256$i=<iterations>$<base64(salt)>$<base64(derivedKey)>.
	 */
	public string function hash(required string password) {
		local.salt = $randomBytes(variables.saltLengthBytes);
		local.derivedKey = $deriveKey(
			password = arguments.password,
			salt = local.salt,
			iterations = variables.iterations,
			keyLengthBits = variables.keyLengthBits
		);

		return "$" & variables.algorithmTag
			& "$i=" & variables.iterations
			& "$" & BinaryEncode(local.salt, "base64")
			& "$" & BinaryEncode(local.derivedKey, "base64");
	}

	/**
	 * Verify a password against a stored hash.
	 *
	 * Re-derives the key using the salt and iteration count embedded in the
	 * stored hash (so hashes created under a different configured iteration
	 * count still verify) and compares the raw digest bytes in constant time
	 * via java.security.MessageDigest.isEqual().
	 *
	 * Never throws: malformed, empty, truncated, or unknown-format hashes
	 * return false.
	 *
	 * @password The plaintext password to check.
	 * @hash The stored hash string produced by hash().
	 * @return True if the password matches the stored hash.
	 */
	public boolean function verify(required string password, required string hash) {
		try {
			local.parsed = $parseHash(arguments.hash);
			if (!local.parsed.valid) {
				return false;
			}

			local.candidate = $deriveKey(
				password = arguments.password,
				salt = local.parsed.salt,
				iterations = local.parsed.iterations,
				keyLengthBits = Len(local.parsed.derivedKey) * 8
			);

			// Constant-time comparison of the raw digest bytes — never
			// compare password hashes with string operators (timing leaks).
			return variables.messageDigest.isEqual(local.candidate, local.parsed.derivedKey);
		} catch (any e) {
			// verify() is a boolean predicate on untrusted input: any parse or
			// derivation error means "does not match", never an exception.
			return false;
		}
	}

	/**
	 * Check whether a stored hash should be re-hashed under the current
	 * configuration.
	 *
	 * Returns true when the stored iteration count is below the configured
	 * one, or when the hash format/algorithm tag is unrecognized (including
	 * malformed hashes). Call after a successful verify() and re-hash the
	 * plaintext to transparently upgrade the work factor.
	 *
	 * @hash The stored hash string to inspect.
	 * @return True if the hash should be regenerated with hash().
	 */
	public boolean function needsRehash(required string hash) {
		local.parsed = $parseHash(arguments.hash);
		if (!local.parsed.valid) {
			return true;
		}
		return local.parsed.iterations < variables.iterations;
	}

	/**
	 * Return the configured iteration count.
	 */
	public numeric function getIterations() {
		return variables.iterations;
	}

	// ---------------------------------------------------------------------------
	// Private helpers
	// ---------------------------------------------------------------------------

	/**
	 * Parse a modular-crypt-style hash string into its components.
	 *
	 * Returns {valid, iterations, salt, derivedKey} where salt/derivedKey are
	 * byte arrays. Never throws: any structural problem (wrong segment count,
	 * unknown algorithm tag, non-numeric or non-positive iterations, invalid
	 * base64, empty salt/key) yields valid=false.
	 */
	private struct function $parseHash(required string hash) {
		local.parsed = {valid = false, iterations = 0, salt = "", derivedKey = ""};

		if (!Len(arguments.hash) || Left(arguments.hash, 1) != "$") {
			return local.parsed;
		}

		// Base64 never contains "$", so a well-formed hash splits into exactly
		// four segments (ListToArray drops the leading empty element).
		local.segments = ListToArray(arguments.hash, "$");
		if (ArrayLen(local.segments) != 4) {
			return local.parsed;
		}

		// Algorithm tag is lowercase by modular-crypt convention — compare
		// case-sensitively (CFML == is case-insensitive, hence Compare()).
		if (Compare(local.segments[1], variables.algorithmTag) != 0) {
			return local.parsed;
		}

		if (!REFind("^i=[1-9][0-9]*$", local.segments[2])) {
			return local.parsed;
		}
		local.parsed.iterations = Val(ListLast(local.segments[2], "="));

		try {
			local.parsed.salt = BinaryDecode(local.segments[3], "base64");
			local.parsed.derivedKey = BinaryDecode(local.segments[4], "base64");
		} catch (any e) {
			return local.parsed;
		}

		if (Len(local.parsed.salt) == 0 || Len(local.parsed.derivedKey) == 0) {
			return local.parsed;
		}

		local.parsed.valid = true;
		return local.parsed;
	}

	/**
	 * Derive a PBKDF2-HMAC-SHA256 key for the given password and salt.
	 *
	 * Uses javax.crypto.SecretKeyFactory ("PBKDF2WithHmacSHA256"), which the
	 * JVM converts password characters to UTF-8 bytes for — byte-identical on
	 * every engine by construction. A fresh factory per call keeps this safe
	 * under the DI container's singleton scope (SecretKeyFactory instances
	 * are not documented thread-safe).
	 */
	private any function $deriveKey(
		required string password,
		required any salt,
		required numeric iterations,
		required numeric keyLengthBits
	) {
		// Route through java.lang.String explicitly so toCharArray() resolves
		// on every engine regardless of how CFML strings are wrapped.
		local.passwordChars = CreateObject("java", "java.lang.String").init(arguments.password).toCharArray();

		local.keySpec = CreateObject("java", "javax.crypto.spec.PBEKeySpec").init(
			local.passwordChars,
			arguments.salt,
			JavaCast("int", arguments.iterations),
			JavaCast("int", arguments.keyLengthBits)
		);

		try {
			local.factory = CreateObject("java", "javax.crypto.SecretKeyFactory").getInstance("PBKDF2WithHmacSHA256");
			local.secretKey = local.factory.generateSecret(local.keySpec);

			// Do NOT call members on the returned key directly: it is a
			// com.sun.crypto.provider.PBKDF2KeyImpl, a JDK-internal class that
			// java.base does not open. Adobe 2025's JVM rejects the reflective
			// member access with InaccessibleObjectException (its reflection
			// layer makes the concrete class's methods accessible en masse).
			// Invoke getEncoded() through the exported javax.crypto.SecretKey
			// interface instead — public interface methods need no opens.
			local.getEncoded = CreateObject("java", "java.lang.Class")
				.forName("javax.crypto.SecretKey")
				.getMethod("getEncoded", JavaCast("null", ""));
			local.derivedKey = local.getEncoded.invoke(local.secretKey, JavaCast("null", ""));
		} finally {
			// Zero the internal password copy held by the spec.
			local.keySpec.clearPassword();
		}

		return local.derivedKey;
	}

	/**
	 * Generate cryptographically secure random bytes.
	 */
	private any function $randomBytes(required numeric byteCount) {
		// Allocate a zeroed byte[] of the right length, then fill it in place.
		local.randomBytes = BinaryDecode(RepeatString("00", arguments.byteCount), "hex");
		variables.secureRandom.nextBytes(local.randomBytes);
		return local.randomBytes;
	}

}
